-- 2026-05-24: Add idempotency-key support to reserve_ai_bypass.
--
-- Background:
--   Plan doc 2026-05-23-ai-bypass-token-spend.md claims "idempotency keys
--   honored" but the table has no key column and the function has no key
--   parameter. Double-tap of the bypass CTA during network latency calls
--   reserve_ai_bypass twice, creating two pending reservations and debiting
--   50 tokens for what should be one user action (verified live 2026-05-24).
--
-- Fix:
--   1. Add ai_bypass_reservations.idempotency_key (nullable for historical
--      rows; will be NOT NULL on new rows enforced by the function via the
--      explicit input check).
--   2. Partial unique index on (user_id, idempotency_key) where
--      idempotency_key is not null. Partial so we don't break existing
--      pre-migration NULLs.
--   3. New 2-arg reserve_ai_bypass(text, text) that:
--        - looks up (current_user_id, p_idempotency_key) and returns the
--          existing reservation_id if found (regardless of status)
--        - otherwise behaves identically to the original
--   4. Backwards-compat: keep the 1-arg signature as a shim that auto-
--      generates a server-side UUID and forwards to the 2-arg.
--      Old IPAs in the wild (pre-PR-26) keep working but lose idempotency
--      (each call gets a fresh key, so double-tap still double-debits for
--      them — same as their pre-PR state, no NEW regression). New clients
--      get full protection.

alter table public.ai_bypass_reservations
  add column if not exists idempotency_key text;

create unique index if not exists ai_bypass_reservations_user_idem_uniq
  on public.ai_bypass_reservations (user_id, idempotency_key)
  where idempotency_key is not null;

-- New 2-arg function (the protected version)
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
  if p_feature not in ('reflect','built_dua','discover_name') then
    return jsonb_build_object('ok',false,'reason','invalid_feature');
  end if;

  -- Idempotency replay: if this user already submitted a row with this key,
  -- return the existing reservation_id. No tokens debited, no counter
  -- incremented. Status doesn't matter — if cancelled, the client is
  -- replaying a stale tap and gets the (now non-pending) id back.
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
      'bypasses_used', null,
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

  insert into public.ai_bypass_reservations
    (user_id, feature, tokens_held, status, created_at, idempotency_key)
    values (current_user_id, p_feature, v_cost, 'pending', now(), p_idempotency_key)
    returning id into v_reservation_id;

  return jsonb_build_object('ok',true,'reservation_id',v_reservation_id,
    'balance',v_balance,'bypasses_used',v_bypasses_used,'replayed',false);
end;
$$;

revoke all on function public.reserve_ai_bypass(text, text) from public, anon;
grant execute on function public.reserve_ai_bypass(text, text) to authenticated, service_role;

-- Backwards-compat: keep the 1-arg signature as a shim for pre-PR-26
-- mobile clients in the wild. Old clients lose idempotency (each call
-- generates a fresh server-side key) but the RPC keeps responding so the
-- bypass flow doesn't appear broken after deploy. New clients (PR-26+)
-- call the 2-arg version with a real UUID and get protection. The 1-arg
-- shim can be dropped in a future release after enough time has passed
-- for the old IPAs to drain.
create or replace function public.reserve_ai_bypass(p_feature text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return public.reserve_ai_bypass(p_feature, 'legacy-' || gen_random_uuid()::text);
end;
$$;

revoke all on function public.reserve_ai_bypass(text) from public, anon;
grant execute on function public.reserve_ai_bypass(text) to authenticated, service_role;
