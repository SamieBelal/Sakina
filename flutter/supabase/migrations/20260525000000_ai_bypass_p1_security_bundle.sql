-- 2026-05-25: AI-bypass P1 security hotfix bundle.
--
-- Findings doc: docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md
-- Test plan:    ~/.gstack/projects/SamieBelal-Sakina/appleuser-master-eng-review-test-plan-20260524-094734.md
--
-- This migration closes four server-side gaps in the AI-bypass feature
-- (PRs #20-#24, merged as commit `2c9a183`). All four were live-verified
-- exploitable on prod 2026-05-24 against scratch test users. Same shape as
-- the PR #26 P0 hotfix bundle.
--
--   P1-1  cancel_ai_bypass lacked owner auth check  →  attacker could cancel
--         any reservation given its UUID (cross-user grief, self-cancel
--         after AI delivery → free bypasses).
--
--   P1-2  reserve_ai_bypass replay path didn't read row status → replaying
--         a cancelled key returned ok:true with no debit, letting the
--         client fire AI calls for free. Affects BOTH the fast-path
--         lookup AND the unique_violation exception handler.
--
--   P1-3  Two user_profiles columns (`last_winback_grant_at`,
--         `iap_upsell_banner_dismissed_at`) were freely UPDATEable by
--         authenticated clients. Exploits: re-trigger winback grants by
--         NULLing the timestamp; permanently suppress the EXP-3 banner
--         by pushing dismissed_at to 2999. Same class as the P0-1 fix
--         that missed these two columns.
--
--         A third column (gift_premium_until) is also exploitable on prod
--         but its guard is deferred to a follow-up because the column is
--         defined by the Ramadan-gifts migration which lives in a separate
--         open PR. Pulling that migration into this hotfix would mix
--         unrelated feature code with a security PR.
--
--   P2-3  app_config had only a PK — no CHECKs on the bounded fields.
--         A service-role accidental UPDATE (or compromised key) setting
--         bypass_token_cost=0 lets every authenticated user reserve
--         bypasses for free. CHECK constraints clamp the surface area.
--
-- All changes are idempotent (`create or replace`, `drop if exists`,
-- `add constraint if not exists` via guarded do-blocks). Grants/revokes
-- on the recreated functions are re-applied at the bottom.

-- ---------------------------------------------------------------------------
-- Helper: _replay_reservation_response — DRY the replay shape (P1-2)
--
-- Called from BOTH replay paths in reserve_ai_bypass (fast-path lookup and
-- unique_violation exception handler) to ensure they branch identically
-- on the existing row's status. Returns the jsonb the RPC should return.
--
-- Must be SECURITY DEFINER so it inherits the calling RPC's privilege
-- level (the RPC itself bypasses RLS via SECURITY DEFINER).
-- ---------------------------------------------------------------------------

create or replace function public._replay_reservation_response(
  p_reservation_id uuid,
  p_user_id uuid,
  p_feature text,
  p_today date
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
  v_balance int;
begin
  select status into v_status
    from public.ai_bypass_reservations
    where id = p_reservation_id;

  if v_status = 'pending' then
    select balance into v_balance from public.user_tokens
      where user_id = p_user_id;
    return jsonb_build_object(
      'ok', true,
      'reservation_id', p_reservation_id,
      'balance', coalesce(v_balance, 0),
      'bypasses_used', public._current_bypass_count(p_user_id, p_feature, p_today),
      'replayed', true
    );
  elsif v_status = 'committed' then
    return jsonb_build_object('ok', false, 'reason', 'already_committed');
  elsif v_status = 'cancelled' then
    return jsonb_build_object('ok', false, 'reason', 'replay_after_cancel');
  else
    -- Unknown status (shouldn't happen given the table CHECK) — fail closed.
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;
end;
$$;

revoke all on function public._replay_reservation_response(uuid, uuid, text, date)
  from public, anon, authenticated;
-- Only the SECURITY DEFINER RPC reserve_ai_bypass calls this. No direct grants.

-- ---------------------------------------------------------------------------
-- P1-1: cancel_ai_bypass v2 — add owner auth check.
--
-- Existing behavior preserved verbatim from 20260523213854 except for the
-- new check between the `select ... into v_owner` lock and the cancel
-- UPDATE. The cron orphan rescue (runs as service_role without a JWT) is
-- unaffected: it presents auth.uid() = NULL and skips the owner check.
--
-- Note: the findings doc proposed `current_user not in ('service_role',
-- 'postgres', 'supabase_admin')` as the bypass. That doesn't work inside
-- a SECURITY DEFINER function owned by `postgres` — current_user is
-- ALWAYS `postgres` there, so the bypass list always trips and the
-- owner check never fires. The corrected gate is `auth.uid() is not null
-- and v_owner <> auth.uid()` — JWT presence indicates an authenticated
-- end user; absence indicates a cron/service_role call.
-- ---------------------------------------------------------------------------

create or replace function public.cancel_ai_bypass(p_reservation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
  v_owner uuid;
  v_feature text;
  v_cost int;
  v_balance int;
  v_today date := timezone('utc', now())::date;
  v_reservation_date date;
begin
  -- NOTE: this RPC is callable both by the owner (via authenticated REST)
  -- and by the cleanup cron (via service_role). The owner check below
  -- enforces that authenticated callers can only cancel their OWN rows,
  -- while service_role / postgres / supabase_admin still rescue any
  -- orphan. The pre-2026-05-25 implementation skipped this check and was
  -- live-exploited (see findings doc P1-1).

  select user_id, status, feature, tokens_held,
         timezone('utc', created_at)::date
    into v_owner, v_status, v_feature, v_cost, v_reservation_date
    from public.ai_bypass_reservations
    where id = p_reservation_id
    for update;

  if v_owner is null then
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;

  -- P1-1 fix: reject cross-user cancels from authenticated callers.
  --
  -- Why auth.uid() not current_user: inside a SECURITY DEFINER function
  -- owned by `postgres`, current_user is always `postgres`, so a
  -- `current_user not in (...)` check would always pass and the owner
  -- check would never trip. auth.uid() reads from the JWT and reflects
  -- the actual caller. Non-null auth.uid() = an authenticated end user
  -- (PostgREST set the JWT); null auth.uid() = service_role / cron
  -- (no JWT in scope) — which is allowed to cancel any orphan.
  if auth.uid() is not null and v_owner <> auth.uid() then
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;

  if v_status <> 'pending' then
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;

  update public.ai_bypass_reservations
    set status = 'cancelled',
        finalized_at = now()
    where id = p_reservation_id;

  -- Refund tokens to the reservation's owner.
  update public.user_tokens
    set balance = balance + v_cost,
        total_spent = greatest(total_spent - v_cost, 0)
    where user_id = v_owner
    returning balance into v_balance;

  -- Decrement the daily counter on the date the reservation was created.
  -- If the reservation crossed a UTC date boundary, the counter on that
  -- date is decremented (not today's). This preserves the per-day cap
  -- semantics even when the cleanup cron rescues an orphan across midnight.
  case v_feature
    when 'reflect' then
      update public.user_daily_usage
        set reflect_bypasses_used = greatest(reflect_bypasses_used - 1, 0)
        where user_id = v_owner and usage_date = v_reservation_date;
    when 'built_dua' then
      update public.user_daily_usage
        set built_dua_bypasses_used = greatest(built_dua_bypasses_used - 1, 0)
        where user_id = v_owner and usage_date = v_reservation_date;
    when 'discover_name' then
      update public.user_daily_usage
        set discover_name_bypasses_used = greatest(discover_name_bypasses_used - 1, 0)
        where user_id = v_owner and usage_date = v_reservation_date;
  end case;

  return jsonb_build_object(
    'ok', true,
    'refunded_tokens', v_cost,
    'balance', coalesce(v_balance, 0)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- P1-2: reserve_ai_bypass v2 — route BOTH replay paths through the
-- _replay_reservation_response helper so cancelled/committed keys can't
-- be replayed for free AI calls.
--
-- Existing function from 20260524111803 preserved verbatim except:
--   * Fast-path lookup (was line ~108) → delegates to helper.
--   * unique_violation exception handler (was line ~204) → first rolls
--     back the just-attempted debit + counter increment (we WON the lock
--     long enough to do that work, but a concurrent call won the unique
--     index), THEN delegates to helper. If the helper returns ok:false,
--     the rollback still has to happen — otherwise we'd permanently
--     debit on a committed/cancelled-replay attempt.
-- ---------------------------------------------------------------------------

create or replace function public.reserve_ai_bypass(
  p_feature text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  v_cost int; v_cap int; v_balance int; v_bypasses_used int;
  v_reservation_id uuid;
  v_existing_id uuid;
  v_today date := timezone('utc', now())::date;
begin
  if current_user_id is null then raise exception 'Not authenticated'; end if;
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then
    return jsonb_build_object('ok',false,'reason','missing_idempotency_key');
  end if;
  if length(p_idempotency_key) > 128 then
    return jsonb_build_object('ok',false,'reason','idempotency_key_too_long');
  end if;
  if p_feature not in ('reflect','built_dua','discover_name') then
    return jsonb_build_object('ok',false,'reason','invalid_feature');
  end if;

  -- Fast-path replay (P1-2 fix): route through status-aware helper.
  -- Pending → ok:true / replayed:true. Committed → ok:false / already_committed.
  -- Cancelled → ok:false / replay_after_cancel.
  select id into v_existing_id
    from public.ai_bypass_reservations
    where user_id = current_user_id
      and idempotency_key = p_idempotency_key;
  if v_existing_id is not null then
    return public._replay_reservation_response(
      v_existing_id, current_user_id, p_feature, v_today
    );
  end if;

  select (value::text)::int into v_cost from public.app_config where key='bypass_token_cost';
  v_cost := coalesce(v_cost, 25);
  select (value::text)::int into v_cap from public.app_config where key='max_bypasses_per_day';
  v_cap := coalesce(v_cap, 2);

  insert into public.user_tokens (user_id) values (current_user_id) on conflict (user_id) do nothing;
  insert into public.user_daily_usage (user_id, usage_date) values (current_user_id, v_today)
    on conflict (user_id, usage_date) do nothing;

  select balance into v_balance from public.user_tokens
    where user_id = current_user_id for update;
  if v_balance < v_cost then
    return jsonb_build_object('ok',false,'reason','no_tokens','balance',v_balance);
  end if;

  case p_feature
    when 'reflect' then
      select reflect_bypasses_used into v_bypasses_used from public.user_daily_usage
        where user_id=current_user_id and usage_date=v_today for update;
    when 'built_dua' then
      select built_dua_bypasses_used into v_bypasses_used from public.user_daily_usage
        where user_id=current_user_id and usage_date=v_today for update;
    when 'discover_name' then
      select discover_name_bypasses_used into v_bypasses_used from public.user_daily_usage
        where user_id=current_user_id and usage_date=v_today for update;
  end case;
  if v_bypasses_used >= v_cap then
    return jsonb_build_object('ok',false,'reason','bypass_cap','bypasses_used',v_bypasses_used);
  end if;

  update public.user_tokens set balance=balance-v_cost, total_spent=total_spent+v_cost
    where user_id=current_user_id returning balance into v_balance;

  case p_feature
    when 'reflect' then
      update public.user_daily_usage set reflect_bypasses_used=reflect_bypasses_used+1
        where user_id=current_user_id and usage_date=v_today
        returning reflect_bypasses_used into v_bypasses_used;
    when 'built_dua' then
      update public.user_daily_usage set built_dua_bypasses_used=built_dua_bypasses_used+1
        where user_id=current_user_id and usage_date=v_today
        returning built_dua_bypasses_used into v_bypasses_used;
    when 'discover_name' then
      update public.user_daily_usage set discover_name_bypasses_used=discover_name_bypasses_used+1
        where user_id=current_user_id and usage_date=v_today
        returning discover_name_bypasses_used into v_bypasses_used;
  end case;

  -- Race-safe INSERT (P1-A from PR #26 preserved). If a concurrent call beat
  -- us with the same key, we MUST roll back our token debit + counter
  -- increment before delegating to the replay helper — otherwise a replay
  -- attempt on a non-pending key would permanently leak tokens.
  begin
    insert into public.ai_bypass_reservations
      (user_id, feature, tokens_held, status, created_at, idempotency_key)
      values (current_user_id, p_feature, v_cost, 'pending', now(), p_idempotency_key)
      returning id into v_reservation_id;
  exception when unique_violation then
    -- Always roll back our partial work — needed regardless of helper outcome.
    update public.user_tokens set balance=balance+v_cost, total_spent=greatest(total_spent-v_cost,0)
      where user_id=current_user_id returning balance into v_balance;
    case p_feature
      when 'reflect' then
        update public.user_daily_usage
          set reflect_bypasses_used=greatest(reflect_bypasses_used-1,0)
          where user_id=current_user_id and usage_date=v_today;
      when 'built_dua' then
        update public.user_daily_usage
          set built_dua_bypasses_used=greatest(built_dua_bypasses_used-1,0)
          where user_id=current_user_id and usage_date=v_today;
      when 'discover_name' then
        update public.user_daily_usage
          set discover_name_bypasses_used=greatest(discover_name_bypasses_used-1,0)
          where user_id=current_user_id and usage_date=v_today;
    end case;

    -- Look up the winner's reservation_id and route through the same
    -- status-aware helper as the fast-path. P1-2 fix: a cancelled or
    -- committed key concurrent-insert returns ok:false now.
    select id into v_existing_id
      from public.ai_bypass_reservations
      where user_id = current_user_id and idempotency_key = p_idempotency_key;
    return public._replay_reservation_response(
      v_existing_id, current_user_id, p_feature, v_today
    );
  end;

  return jsonb_build_object('ok',true,'reservation_id',v_reservation_id,
    'balance',v_balance,'bypasses_used',v_bypasses_used,'replayed',false);
end;
$$;

-- ---------------------------------------------------------------------------
-- P1-3: extend guard_user_profiles_freemium_fields to cover two more cols.
--
-- Existing rules from 20260524050655 preserved verbatim. Two new
-- distinct-from rules appended: last_winback_grant_at and
-- iap_upsell_banner_dismissed_at. (A third column, gift_premium_until,
-- is deferred — see the file-level header.)
--
-- Honest paths (grant_winback_tokens, dismiss_iap_upsell_banner) are
-- both SECURITY DEFINER owned by `postgres`, which is in the current_user
-- bypass list at the top of this trigger. They continue to work.
-- ---------------------------------------------------------------------------

create or replace function public.guard_user_profiles_freemium_fields()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('service_role', 'postgres', 'supabase_admin') then
    return new;
  end if;

  -- Existing rules (verbatim from 20260510200915 + 20260514175600 + 20260524050655)
  if new.warmup_reflect_remaining > old.warmup_reflect_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_reflect_remaining (% -> %)',
      old.warmup_reflect_remaining, new.warmup_reflect_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_built_dua_remaining > old.warmup_built_dua_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_built_dua_remaining (% -> %)',
      old.warmup_built_dua_remaining, new.warmup_built_dua_remaining using errcode = 'check_violation';
  end if;
  if new.warmup_discover_name_remaining > old.warmup_discover_name_remaining then
    raise exception 'cannot reset/refill freemium gating field: warmup_discover_name_remaining (% -> %)',
      old.warmup_discover_name_remaining, new.warmup_discover_name_remaining using errcode = 'check_violation';
  end if;
  if old.had_trial = true and new.had_trial = false then
    raise exception 'cannot reset/refill freemium gating field: had_trial (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;
  if old.referral_code is not null and new.referral_code is distinct from old.referral_code then
    raise exception 'cannot modify referral_code after initial assignment (% -> %)',
      old.referral_code, new.referral_code using errcode = 'check_violation';
  end if;
  if new.referral_premium_until is distinct from old.referral_premium_until then
    raise exception 'cannot modify referral_premium_until directly; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  -- P0-1 rules (verbatim from 20260524050655)
  if old.first_bypass_consumed = true and new.first_bypass_consumed = false then
    raise exception
      'cannot reset/refill freemium gating field: first_bypass_consumed (true -> false is forbidden)'
      using errcode = 'check_violation';
  end if;

  if new.lifetime_bypasses_purchased < old.lifetime_bypasses_purchased then
    raise exception
      'cannot reset/refill freemium gating field: lifetime_bypasses_purchased (% -> %)',
      old.lifetime_bypasses_purchased, new.lifetime_bypasses_purchased
      using errcode = 'check_violation';
  end if;

  -- P1-3 NEW rules (2026-05-25 — this migration)
  -- NOTE: gift_premium_until is exploitable on prod (same risk shape) but its
  -- guard rule is deferred to a follow-up. The column is defined by the
  -- Ramadan-gifts migration which lives in a separate open PR — guarding it
  -- here would require pulling that migration into this hotfix, mixing scopes.
  -- Tracked as a P1 follow-up in docs/qa/findings/.
  if new.last_winback_grant_at is distinct from old.last_winback_grant_at then
    raise exception 'cannot modify freemium gating field: last_winback_grant_at; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;
  if new.iap_upsell_banner_dismissed_at is distinct from old.iap_upsell_banner_dismissed_at then
    raise exception 'cannot modify freemium gating field: iap_upsell_banner_dismissed_at; must go through SECURITY DEFINER RPC'
      using errcode = 'check_violation';
  end if;

  return new;
end
$$;

-- ---------------------------------------------------------------------------
-- P2-3: app_config CHECK constraints — bound the sensitive integer values.
--
-- Current values (live 2026-05-24): bypass_token_cost=25, max_bypasses_per_day=2.
-- Both pass the new constraints. The CHECKs only matter on UPDATE — they
-- prevent an accidental ops mistake (or compromised service_role key) from
-- setting bypass_token_cost=0 (every user reserves bypasses for free) or
-- max_bypasses_per_day to an absurd value.
-- ---------------------------------------------------------------------------

alter table public.app_config drop constraint if exists app_config_bypass_cost_positive;
alter table public.app_config add constraint app_config_bypass_cost_positive
  check (key <> 'bypass_token_cost' or (value::text)::int between 1 and 1000);

alter table public.app_config drop constraint if exists app_config_max_bypasses_sane;
alter table public.app_config add constraint app_config_max_bypasses_sane
  check (key <> 'max_bypasses_per_day' or (value::text)::int between 0 and 10);

-- ---------------------------------------------------------------------------
-- GRANTs — re-apply existing grants on the recreated functions to be
-- explicit (CREATE OR REPLACE preserves them but defense-in-depth).
-- ---------------------------------------------------------------------------

revoke execute on function public.cancel_ai_bypass(uuid) from public, anon;
grant  execute on function public.cancel_ai_bypass(uuid) to authenticated, service_role;

revoke all on function public.reserve_ai_bypass(text, text) from public, anon;
grant execute on function public.reserve_ai_bypass(text, text) to authenticated, service_role;
