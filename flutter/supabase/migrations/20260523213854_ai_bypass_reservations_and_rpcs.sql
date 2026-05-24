-- 2026-05-23: AI bypass via token spend — server-side enforcement (PR 1 of 5).
--
-- Plan: docs/superpowers/plans/2026-05-23-ai-bypass-token-spend.md
-- Spec amendment: docs/superpowers/specs/2026-05-09-free-premium-tier-redesign-design.md
--
-- Adds a bounded token-spend bypass for free users post-warmup. Free + capped
-- users can spend 25 tokens for one extra Reflect / Built Dua / Discover Name
-- use, up to 2 bypasses per feature per day. Premium users never reach this
-- path (their cap is the silent 30/day fair-use ceiling).
--
-- Schema additions (all additive, no backfill needed):
--   user_daily_usage:
--     reflect_bypasses_used        INT DEFAULT 0
--     built_dua_bypasses_used      INT DEFAULT 0
--     discover_name_bypasses_used  INT DEFAULT 0
--   user_profiles:
--     first_bypass_consumed             BOOLEAN DEFAULT FALSE  (EXP-2 Day-1 freebie)
--     lifetime_bypasses_purchased       INT DEFAULT 0          (EXP-3 IAP→sub upsell)
--     last_winback_grant_at             TIMESTAMPTZ            (EXP-4 win-back cap)
--     iap_upsell_banner_dismissed_at    TIMESTAMPTZ            (EXP-3 banner suppression)
--
-- New tables:
--   app_config                  — server-driven config (EXP-1 dynamic pricing)
--   ai_bypass_reservations      — reserve-then-commit ledger for AI-failure resilience
--
-- RPCs (all SECURITY DEFINER, pinned search_path):
--   reserve_ai_bypass(p_feature text)        — atomic debit + reservation insert
--   commit_ai_bypass(p_reservation_id uuid)  — finalize, increment lifetime_bypasses_purchased
--   cancel_ai_bypass(p_reservation_id uuid)  — rollback, refund tokens, decrement counter
--   claim_first_bypass(p_feature text)       — EXP-2: Day-1 one-shot freebie
--   grant_winback_tokens(p_user_id uuid, p_amount int) — EXP-4: atomic grant + timestamp
--
-- Note on column naming:
--   The plan refers to `user_profiles.tokens` / `total_tokens_spent` and a
--   `signup_at` column. The actual schema uses `user_tokens.balance` /
--   `user_tokens.total_spent` for the balance, and `user_profiles.created_at`
--   as the signup timestamp. This migration uses the real schema.

-- ---------------------------------------------------------------------------
-- 1. Counter columns on user_daily_usage
-- ---------------------------------------------------------------------------

alter table public.user_daily_usage
  add column if not exists reflect_bypasses_used int not null default 0;

alter table public.user_daily_usage
  add column if not exists built_dua_bypasses_used int not null default 0;

alter table public.user_daily_usage
  add column if not exists discover_name_bypasses_used int not null default 0;

-- ---------------------------------------------------------------------------
-- 2. State columns on user_profiles
-- ---------------------------------------------------------------------------

alter table public.user_profiles
  add column if not exists first_bypass_consumed boolean not null default false;

alter table public.user_profiles
  add column if not exists lifetime_bypasses_purchased int not null default 0;

alter table public.user_profiles
  add column if not exists last_winback_grant_at timestamptz;

alter table public.user_profiles
  add column if not exists iap_upsell_banner_dismissed_at timestamptz;

-- Non-negative guards on the integer counter so a buggy RPC can't drive
-- lifetime_bypasses_purchased below zero.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'lifetime_bypasses_purchased_non_negative'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint lifetime_bypasses_purchased_non_negative
      check (lifetime_bypasses_purchased >= 0);
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3. app_config table (EXP-1 — server-driven bypass pricing)
-- ---------------------------------------------------------------------------

create table if not exists public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

create trigger app_config_updated_at before update on public.app_config
  for each row execute function public.handle_updated_at();

-- Seed default values matching the locked plan (25 tokens / 2 bypasses / day).
insert into public.app_config (key, value) values
  ('bypass_token_cost', to_jsonb(25)),
  ('max_bypasses_per_day', to_jsonb(2))
on conflict (key) do nothing;

-- RLS: authenticated SELECT, no client mutation. Service-role (admin) writes.
alter table public.app_config enable row level security;

create policy "Authenticated can read app_config"
  on public.app_config
  for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- 4. ai_bypass_reservations table (reserve-then-commit ledger)
-- ---------------------------------------------------------------------------

create table if not exists public.ai_bypass_reservations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  feature text not null,
  tokens_held int not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  finalized_at timestamptz,
  constraint ai_bypass_reservations_status_check
    check (status in ('pending', 'committed', 'cancelled')),
  constraint ai_bypass_reservations_feature_check
    check (feature in ('reflect', 'built_dua', 'discover_name'))
);

-- Owning index for cleanup cron (hot query: pending older than 15 min).
create index if not exists ai_bypass_reservations_pending_idx
  on public.ai_bypass_reservations (status, created_at)
  where status = 'pending';

-- Lookup by user for SELECT-via-RLS.
create index if not exists ai_bypass_reservations_user_idx
  on public.ai_bypass_reservations (user_id, created_at desc);

-- RLS: users can SELECT their own rows. INSERT/UPDATE/DELETE blocked at the
-- RLS layer — only SECURITY DEFINER RPCs (running as the function owner) may
-- write. SECURITY DEFINER bypasses RLS, so no INSERT policy is needed for the
-- RPCs to work.
alter table public.ai_bypass_reservations enable row level security;

create policy "Users can view own bypass reservations"
  on public.ai_bypass_reservations
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- 5. reserve_ai_bypass — atomic debit + reservation insert
-- ---------------------------------------------------------------------------

create or replace function public.reserve_ai_bypass(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  v_cost int;
  v_cap int;
  v_balance int;
  v_bypasses_used int;
  v_reservation_id uuid;
  v_today date := timezone('utc', now())::date;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_feature not in ('reflect', 'built_dua', 'discover_name') then
    return jsonb_build_object('ok', false, 'reason', 'invalid_feature');
  end if;

  -- Read server-driven config with hardcoded fallback if app_config row
  -- missing (defensive — keeps the feature working if seeding fails).
  -- jsonb → int requires going through text: `(value::text)::int`.
  select (value::text)::int into v_cost
    from public.app_config where key = 'bypass_token_cost';
  v_cost := coalesce(v_cost, 25);

  select (value::text)::int into v_cap
    from public.app_config where key = 'max_bypasses_per_day';
  v_cap := coalesce(v_cap, 2);

  -- Ensure token + daily_usage rows exist so the FOR UPDATE locks have
  -- something to grab.
  insert into public.user_tokens (user_id)
    values (current_user_id)
    on conflict (user_id) do nothing;

  insert into public.user_daily_usage (user_id, usage_date)
    values (current_user_id, v_today)
    on conflict (user_id, usage_date) do nothing;

  -- Lock the token row for the duration of the transaction. Concurrent
  -- reserve calls from the same user serialize here.
  select balance into v_balance
    from public.user_tokens
    where user_id = current_user_id
    for update;

  if v_balance < v_cost then
    return jsonb_build_object('ok', false, 'reason', 'no_tokens', 'balance', v_balance);
  end if;

  -- Lock daily_usage row + read the relevant counter.
  case p_feature
    when 'reflect' then
      select reflect_bypasses_used into v_bypasses_used
        from public.user_daily_usage
        where user_id = current_user_id and usage_date = v_today
        for update;
    when 'built_dua' then
      select built_dua_bypasses_used into v_bypasses_used
        from public.user_daily_usage
        where user_id = current_user_id and usage_date = v_today
        for update;
    when 'discover_name' then
      select discover_name_bypasses_used into v_bypasses_used
        from public.user_daily_usage
        where user_id = current_user_id and usage_date = v_today
        for update;
  end case;

  if v_bypasses_used >= v_cap then
    return jsonb_build_object('ok', false, 'reason', 'bypass_cap', 'bypasses_used', v_bypasses_used);
  end if;

  -- Debit balance, increment counter, insert reservation. All within the
  -- same transaction so a failure rolls everything back.
  update public.user_tokens
    set balance = balance - v_cost,
        total_spent = total_spent + v_cost
    where user_id = current_user_id
    returning balance into v_balance;

  case p_feature
    when 'reflect' then
      update public.user_daily_usage
        set reflect_bypasses_used = reflect_bypasses_used + 1
        where user_id = current_user_id and usage_date = v_today
        returning reflect_bypasses_used into v_bypasses_used;
    when 'built_dua' then
      update public.user_daily_usage
        set built_dua_bypasses_used = built_dua_bypasses_used + 1
        where user_id = current_user_id and usage_date = v_today
        returning built_dua_bypasses_used into v_bypasses_used;
    when 'discover_name' then
      update public.user_daily_usage
        set discover_name_bypasses_used = discover_name_bypasses_used + 1
        where user_id = current_user_id and usage_date = v_today
        returning discover_name_bypasses_used into v_bypasses_used;
  end case;

  insert into public.ai_bypass_reservations (
    user_id, feature, tokens_held, status, created_at
  ) values (
    current_user_id, p_feature, v_cost, 'pending', now()
  ) returning id into v_reservation_id;

  return jsonb_build_object(
    'ok', true,
    'reservation_id', v_reservation_id,
    'balance', v_balance,
    'bypasses_used', v_bypasses_used
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. commit_ai_bypass — finalize reservation + increment lifetime counter
--
-- Two responsibilities, atomicity-driven (R2 eng review):
--   (a) Flip reservation status pending → committed.
--   (b) Increment user_profiles.lifetime_bypasses_purchased (powers EXP-3
--       IAP→sub upsell banner). Only committed reservations count.
-- ---------------------------------------------------------------------------

create or replace function public.commit_ai_bypass(p_reservation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  v_status text;
  v_owner uuid;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Lock the reservation row. Ensures concurrent commit/cancel serialize.
  select user_id, status into v_owner, v_status
    from public.ai_bypass_reservations
    where id = p_reservation_id
    for update;

  if v_owner is null then
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;

  -- Defense-in-depth: callers should only commit their own reservations.
  -- (RLS doesn't gate UPDATE here — we're in SECURITY DEFINER context.)
  if v_owner <> current_user_id then
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;

  if v_status <> 'pending' then
    return jsonb_build_object('ok', false, 'reason', 'not_pending');
  end if;

  update public.ai_bypass_reservations
    set status = 'committed',
        finalized_at = now()
    where id = p_reservation_id;

  -- (b) Increment lifetime counter — only committed reservations count
  -- toward the IAP→sub upsell threshold.
  update public.user_profiles
    set lifetime_bypasses_purchased = lifetime_bypasses_purchased + 1
    where id = current_user_id;

  return jsonb_build_object('ok', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- 7. cancel_ai_bypass — rollback: refund tokens, decrement counter
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
  -- NOTE: this RPC is callable both by the user (via authenticated REST) and
  -- by the cleanup cron (via service_role). We do NOT check auth.uid()
  -- against owner, so the cron can rescue any orphan. Defense is at the
  -- "must be pending" check — anyone canceling a committed reservation gets
  -- a no-op.

  select user_id, status, feature, tokens_held,
         timezone('utc', created_at)::date
    into v_owner, v_status, v_feature, v_cost, v_reservation_date
    from public.ai_bypass_reservations
    where id = p_reservation_id
    for update;

  if v_owner is null then
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
-- 8. claim_first_bypass — EXP-2 Day-1 freebie (one-shot per user, all features)
--
-- Eligibility (all required):
--   * first_bypass_consumed = false
--   * created_at IS NOT NULL                — defense against profile corruption
--   * created_at >= now() - interval '24h'  — Day-1 window only
--
-- Different shape from reserve_ai_bypass: no token debit. Atomically
-- increments the per-feature bypass counter and flips the global
-- first_bypass_consumed latch. Does NOT write to ai_bypass_reservations —
-- nothing to "cancel" since no tokens were spent and the AI call's failure
-- mode is just "retry the freebie", not "refund money".
-- ---------------------------------------------------------------------------

create or replace function public.claim_first_bypass(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_user_id uuid := auth.uid();
  v_consumed boolean;
  v_created_at timestamptz;
  v_bypasses_used int;
  v_today date := timezone('utc', now())::date;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_feature not in ('reflect', 'built_dua', 'discover_name') then
    return jsonb_build_object('ok', false, 'reason', 'invalid_feature');
  end if;

  -- Lock profile row + read eligibility.
  select first_bypass_consumed, created_at
    into v_consumed, v_created_at
    from public.user_profiles
    where id = current_user_id
    for update;

  -- created_at IS NULL defense (R2 eng review regression-pin) — prevents
  -- a corrupted-profile user from accidentally qualifying for the freebie
  -- forever. The column is declared NOT NULL but defensive checks are cheap.
  if v_created_at is null then
    return jsonb_build_object('ok', false, 'reason', 'no_signup_at');
  end if;

  if v_consumed then
    return jsonb_build_object('ok', false, 'reason', 'already_consumed');
  end if;

  if v_created_at < now() - interval '24 hours' then
    return jsonb_build_object('ok', false, 'reason', 'window_expired');
  end if;

  insert into public.user_daily_usage (user_id, usage_date)
    values (current_user_id, v_today)
    on conflict (user_id, usage_date) do nothing;

  -- Increment the per-feature counter. NO token debit.
  case p_feature
    when 'reflect' then
      update public.user_daily_usage
        set reflect_bypasses_used = reflect_bypasses_used + 1
        where user_id = current_user_id and usage_date = v_today
        returning reflect_bypasses_used into v_bypasses_used;
    when 'built_dua' then
      update public.user_daily_usage
        set built_dua_bypasses_used = built_dua_bypasses_used + 1
        where user_id = current_user_id and usage_date = v_today
        returning built_dua_bypasses_used into v_bypasses_used;
    when 'discover_name' then
      update public.user_daily_usage
        set discover_name_bypasses_used = discover_name_bypasses_used + 1
        where user_id = current_user_id and usage_date = v_today
        returning discover_name_bypasses_used into v_bypasses_used;
  end case;

  -- Flip the one-shot latch.
  update public.user_profiles
    set first_bypass_consumed = true
    where id = current_user_id;

  return jsonb_build_object(
    'ok', true,
    'bypasses_used', v_bypasses_used
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 9. grant_winback_tokens — EXP-4 atomic grant + timestamp update
--
-- Called by the win-back Scheduled Edge Function (PR 6) via service_role.
-- Wraps the token grant + last_winback_grant_at write in a single
-- transaction so a crash between grant-success and timestamp-write does
-- NOT trigger a re-grant on the next cron run (R2 eng review regression-pin).
-- ---------------------------------------------------------------------------

create or replace function public.grant_winback_tokens(p_user_id uuid, p_amount int)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_balance int;
  v_last_grant timestamptz;
begin
  if p_user_id is null then
    raise exception 'p_user_id required';
  end if;

  if p_amount <= 0 then
    raise exception 'Win-back amount must be positive';
  end if;

  -- Lock the profile row first so concurrent grants serialize.
  select last_winback_grant_at into v_last_grant
    from public.user_profiles
    where id = p_user_id
    for update;

  -- 30-day frequency cap. The next eligibility query in the scheduled
  -- function should ALSO enforce this — defense-in-depth at the RPC.
  if v_last_grant is not null and v_last_grant > now() - interval '30 days' then
    return jsonb_build_object('ok', false, 'reason', 'frequency_cap');
  end if;

  -- Ensure token row exists.
  insert into public.user_tokens (user_id)
    values (p_user_id)
    on conflict (user_id) do nothing;

  -- Grant tokens + write timestamp in same transaction.
  update public.user_tokens
    set balance = balance + p_amount
    where user_id = p_user_id
    returning balance into v_balance;

  update public.user_profiles
    set last_winback_grant_at = now()
    where id = p_user_id;

  return jsonb_build_object(
    'ok', true,
    'balance', v_balance,
    'granted', p_amount
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- 10. GRANTs — authenticated for user-callable RPCs, service_role only
--     for cron + edge-function callers.
-- ---------------------------------------------------------------------------

revoke execute on function public.reserve_ai_bypass(text)        from public, anon, authenticated;
grant  execute on function public.reserve_ai_bypass(text)        to authenticated;

revoke execute on function public.commit_ai_bypass(uuid)         from public, anon, authenticated;
grant  execute on function public.commit_ai_bypass(uuid)         to authenticated;

-- cancel_ai_bypass is callable by both authenticated (user-initiated
-- rollback) and service_role (cron orphan cleanup).
revoke execute on function public.cancel_ai_bypass(uuid)         from public, anon, authenticated;
grant  execute on function public.cancel_ai_bypass(uuid)         to authenticated;

revoke execute on function public.claim_first_bypass(text)       from public, anon, authenticated;
grant  execute on function public.claim_first_bypass(text)       to authenticated;

-- grant_winback_tokens is server-only (scheduled edge function via
-- service_role). No GRANT to authenticated — users cannot self-grant.
revoke execute on function public.grant_winback_tokens(uuid, int) from public, anon, authenticated;
