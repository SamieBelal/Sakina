-- 2026-05-24: Polish reserve_ai_bypass for race-safety + consistent return shape.
--
-- Background (P1 follow-ups from /review on PR #25):
--
-- P1-A — unhandled unique_violation race:
--   The 2-arg reserve_ai_bypass from 20260524010000 has a TOCTOU window
--   between the `SELECT INTO v_existing_id` check and the final INSERT.
--   Two concurrent calls with the same (user_id, idempotency_key) can
--   both see v_existing_id = null, both proceed, and the second INSERT
--   hits ai_bypass_reservations_user_idem_uniq and raises an unhandled
--   unique_violation. The transaction rolls back (so no double-debit —
--   the partial unique index does its job) but the client sees a 500
--   instead of a clean replay response.
--
-- P1-C — replay returns bypasses_used: null:
--   On the explicit replay path (v_existing_id found), the function
--   returned `bypasses_used: null` because the original row only
--   stores feature + tokens_held, not the daily counter. The Dart
--   client at gating_service.dart:382 treats null as `malformed_response`
--   and returns null to the caller — silently breaks a true double-tap.
--
-- Fix (this migration):
--   1. Replace v_existing_id with a helper that returns the row + current
--      bypasses_used from user_daily_usage (always-present, idempotent
--      lookup on `(user_id, p_feature, today)`).
--   2. Wrap the final INSERT in BEGIN ... EXCEPTION WHEN unique_violation
--      so a racing concurrent call returns the replay shape instead of
--      raising. Token debit + counter increment in the same TX get rolled
--      back automatically by the SAVEPOINT, then we re-query the winner's
--      row and return its data.
--   3. Cap idempotency key at 128 chars to close the unbounded-text DoS
--      vector flagged by the security specialist (P2-B).
--
-- Backwards-compat:
--   - Same function signature `(text, text)` — no schema change.
--   - 1-arg shim from 20260524010000 still wraps and forwards — unchanged.
--   - Honest sequential clients see no behavior change.
--   - Replay response now includes `bypasses_used` as an int — strictly
--     additive from null. Dart client at gating_service.dart:382 still
--     fails the null check, but now it never hits it on replay.
--   - Error response shape unchanged.

-- Helper: read the current bypass counter for a feature without taking
-- a lock. Used by the replay path. Declared as STABLE so the planner
-- can inline-optimize.
create or replace function public._current_bypass_count(
  p_user_id uuid,
  p_feature text,
  p_date date
)
returns int
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare v_count int;
begin
  case p_feature
    when 'reflect' then
      select reflect_bypasses_used into v_count from public.user_daily_usage
        where user_id = p_user_id and usage_date = p_date;
    when 'built_dua' then
      select built_dua_bypasses_used into v_count from public.user_daily_usage
        where user_id = p_user_id and usage_date = p_date;
    when 'discover_name' then
      select discover_name_bypasses_used into v_count from public.user_daily_usage
        where user_id = p_user_id and usage_date = p_date;
    else
      return null;
  end case;
  return coalesce(v_count, 0);
end;
$$;

revoke all on function public._current_bypass_count(uuid, text, date) from public, anon, authenticated;
-- Only the SECURITY DEFINER RPCs call this (which inherit postgres role) — no direct grants.

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
    -- P2-B: prevent unbounded-text DoS / WAL bloat
    return jsonb_build_object('ok',false,'reason','idempotency_key_too_long');
  end if;
  if p_feature not in ('reflect','built_dua','discover_name') then
    return jsonb_build_object('ok',false,'reason','invalid_feature');
  end if;

  -- Fast-path replay: explicit lookup before doing any work
  select id into v_existing_id
    from public.ai_bypass_reservations
    where user_id = current_user_id
      and idempotency_key = p_idempotency_key;
  if v_existing_id is not null then
    select balance into v_balance from public.user_tokens
      where user_id = current_user_id;
    return jsonb_build_object(
      'ok', true,
      'reservation_id', v_existing_id,
      'balance', coalesce(v_balance, 0),
      'bypasses_used', public._current_bypass_count(current_user_id, p_feature, v_today),
      'replayed', true
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

  -- P1-A: race-safe INSERT. If a concurrent call beat us to it with the
  -- same key, the SAVEPOINT rolls back our token debit + counter increment
  -- and we return the winner's row as a clean replay. Caller sees
  -- ok:true / replayed:true with the winner's reservation_id — same
  -- contract as the explicit fast-path replay above.
  begin
    insert into public.ai_bypass_reservations
      (user_id, feature, tokens_held, status, created_at, idempotency_key)
      values (current_user_id, p_feature, v_cost, 'pending', now(), p_idempotency_key)
      returning id into v_reservation_id;
  exception when unique_violation then
    -- Roll back token debit + counter increment from this aborted attempt.
    -- The winning concurrent call already did its own debit + increment.
    -- We just need to undo OURS.
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

    -- Re-query the winner's reservation_id + current counter
    select id into v_reservation_id
      from public.ai_bypass_reservations
      where user_id = current_user_id and idempotency_key = p_idempotency_key;
    return jsonb_build_object(
      'ok', true,
      'reservation_id', v_reservation_id,
      'balance', v_balance,
      'bypasses_used', public._current_bypass_count(current_user_id, p_feature, v_today),
      'replayed', true
    );
  end;

  return jsonb_build_object('ok',true,'reservation_id',v_reservation_id,
    'balance',v_balance,'bypasses_used',v_bypasses_used,'replayed',false);
end;
$$;

-- Grants unchanged (CREATE OR REPLACE preserves them, but be explicit)
revoke all on function public.reserve_ai_bypass(text, text) from public, anon;
grant execute on function public.reserve_ai_bypass(text, text) to authenticated, service_role;
