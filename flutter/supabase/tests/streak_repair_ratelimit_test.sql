-- Regression test: repair_streak_paid() rate-limit must block a PAID repair
-- that follows a PREMIUM-FREE repair within the same 30-day window.
--
-- Bug: 20260719000000_streaks_defense.sql line 167 sets
--   last_paid_repair_at = case when v_premium_free then last_paid_repair_at else now_ts end
-- so when the FREE path runs, last_paid_repair_at stays NULL.  The paid
-- rate-limit guard checks "last_paid_repair_at IS NOT NULL AND < 30d", so it
-- passes NULL through — allowing a second repair within the same 30-day
-- window.
--
-- Fix: 20260721000000_repair_streak_ratelimit_fix.sql replaces the function
-- so BOTH paths stamp last_paid_repair_at on success (shared 30-day meter).
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/streak_repair_ratelimit_test.sql

begin;

create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  perform set_config('test.total',
    (coalesce(current_setting('test.total', true)::int, 0) + 1)::text, true);
  if not cond then
    perform set_config('test.failed',
      coalesce(current_setting('test.failed', true), '') || ' | ' || name, true);
  end if;
end
$$;

create or replace function pg_temp.test_insert_auth_user(p_id uuid, p_email text)
returns void language sql as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id, 'authenticated', 'authenticated', p_email, '',
    now(), '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', split_part(p_email, '@', 1)),
    now(), now()
  );
$$;

create or replace function pg_temp.set_auth(p_uid uuid) returns void
language plpgsql as $$
begin
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
end $$;

create or replace function pg_temp.reset_auth() returns void
language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;

-- Seed test user
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-00000000eeaa',
  'ratelimit-test@test.sakina.local'
);
update public.user_tokens
  set balance = 2000, total_spent = 0
  where user_id = '00000000-0000-0000-0000-00000000eeaa'::uuid;

do $body$
declare
  uid constant uuid := '00000000-0000-0000-0000-00000000eeaa';
  v_result jsonb;
  v_last_paid_repair_at timestamptz;
  err text;
begin

  -- =========================================================================
  -- Grant premium so the first repair takes the FREE path
  -- =========================================================================
  insert into public.user_subscriptions
    (user_id, entitlement, product_id, expires_at, last_event_type, last_event_at)
    values (uid, 'premium', 'test_premium_rl', now() + interval '30 days',
            'INITIAL_PURCHASE', now())
    on conflict (user_id, entitlement) do update set
      expires_at = now() + interval '30 days';

  perform pg_temp.set_auth(uid);
  perform pg_temp.expect(public.has_active_premium_entitlement(uid),
    'pre. server sees active premium entitlement');

  -- =========================================================================
  -- 1. Premium-FREE repair succeeds (first repair in the window)
  -- =========================================================================
  update public.user_streaks
    set current_streak = 1, longest_streak = 30,
        pre_lapse_streak = 30, lapsed_at = now() - interval '5 days',
        last_paid_repair_at = null, premium_free_repair_at = null
    where user_id = uid;

  v_result := public.repair_streak_paid();
  perform pg_temp.expect(
    (v_result->>'method') = 'premium_free',
    '1a. first repair took premium_free path');
  perform pg_temp.expect(
    (v_result->>'restored') = 'true',
    '1b. streak was restored');

  -- =========================================================================
  -- 2. last_paid_repair_at must be stamped even on the free path
  --    (so the shared 30-day meter is set)
  -- =========================================================================
  select last_paid_repair_at
    into v_last_paid_repair_at
    from public.user_streaks
    where user_id = uid;
  perform pg_temp.expect(
    v_last_paid_repair_at is not null,
    '2. last_paid_repair_at is stamped after premium_free repair (shared meter)');

  -- =========================================================================
  -- 3. Now revoke premium — simulates user subscription lapsing
  -- =========================================================================
  perform pg_temp.reset_auth();
  delete from public.user_subscriptions where user_id = uid;
  perform pg_temp.set_auth(uid);
  perform pg_temp.expect(
    not public.has_active_premium_entitlement(uid),
    '3. premium revoked');

  -- =========================================================================
  -- 4. A NEW restorable lapse arises within the 30-day window.
  --    The PAID path should now be BLOCKED by the shared meter.
  --    With the bug: last_paid_repair_at is NULL → guard passes → second
  --    repair succeeds (WRONG).  With the fix: last_paid_repair_at is stamped
  --    → guard fires → 'Repair rate-limited' exception (CORRECT).
  -- =========================================================================
  update public.user_streaks
    set current_streak = 1, longest_streak = 30,
        pre_lapse_streak = 30, lapsed_at = now() - interval '2 days'
        -- do NOT touch last_paid_repair_at or premium_free_repair_at —
        -- they should still hold the values set by step 1.
    where user_id = uid;
  update public.user_tokens set balance = 2000 where user_id = uid;

  begin
    v_result := public.repair_streak_paid();
    -- If we reach here the bug is present: the second repair succeeded.
    perform pg_temp.expect(false,
      '4. second repair within 30d should raise Repair rate-limited (BUG: it succeeded)');
  exception when others then
    perform pg_temp.expect(true,
      '4. second repair correctly blocked: Repair rate-limited');
  end;

  -- =========================================================================
  -- Final tally
  -- =========================================================================
  perform pg_temp.reset_auth();
  err := current_setting('test.failed', true);
  if length(coalesce(err, '')) > 0 then
    raise exception 'STREAK REPAIR RATELIMIT TEST FAILED (% run): %',
      current_setting('test.total', true), err;
  else
    raise notice 'ALL PASS (% tests)', current_setting('test.total', true);
  end if;
end
$body$;

rollback;
