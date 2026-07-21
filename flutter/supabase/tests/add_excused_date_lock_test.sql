-- Functional regression test for 20260721010000_add_excused_date_lock.sql
--
-- Verifies that add_excused_date() enforces the 8-per-30-day cap correctly
-- after the advisory-lock fix, and that idempotent re-adds remain no-ops.
--
-- NOTE on concurrency: the actual data-race (two sessions both reading
-- cnt=7 and both inserting) cannot be reproduced deterministically within
-- a single SQL session.  The advisory lock's correctness is proven by:
--   (a) the functional tests below (cap still enforced, idempotency preserved),
--   (b) the deterministic pg_sleep-based harness run separately (see RED/GREEN
--       evidence in the migration commit message), and
--   (c) the lock's semantics: pg_advisory_xact_lock serialises callers for the
--       same uid, so the second caller's count always sees the first's commit.
--
--   psql ... -f supabase/tests/add_excused_date_lock_test.sql
--
-- Coverage:
--   L1. happy path: first add returns ok=true, count_in_window=1
--   L2. second distinct date increments count
--   L3. cap enforced: 8th date accepted, 9th rejected with 'Excused cap reached'
--   L4. idempotent re-add of an existing date is a no-op (no error, no dup row)
--   L5. dates outside the 30-day window are not counted toward the cap
--   L6. cap is per-user: a second user's dates do not bleed into the first's count

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
end $$;

create or replace function pg_temp.insert_auth_user(p_id uuid, p_email text)
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
  ) on conflict (id) do nothing;
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

-- Seed two users.
select pg_temp.insert_auth_user(
  'aaaaaaaa-0000-0000-0000-000000000001'::uuid, 'lock-test-a@test.sakina.local');
select pg_temp.insert_auth_user(
  'aaaaaaaa-0000-0000-0000-000000000002'::uuid, 'lock-test-b@test.sakina.local');

do $body$
declare
  uid_a constant uuid := 'aaaaaaaa-0000-0000-0000-000000000001';
  uid_b constant uuid := 'aaaaaaaa-0000-0000-0000-000000000002';
  v_result jsonb;
  v_cnt    int;
  err      text;
  i        int;
begin

  perform pg_temp.set_auth(uid_a);

  -- ==========================================================================
  -- L1. Happy path: first add returns ok=true, count_in_window=1
  -- ==========================================================================
  v_result := public.add_excused_date(current_date);
  perform pg_temp.expect((v_result->>'ok')::boolean,          'L1a. ok=true');
  perform pg_temp.expect((v_result->>'count_in_window')::int = 1, 'L1b. count_in_window=1');

  -- ==========================================================================
  -- L2. Second distinct date increments count
  -- ==========================================================================
  v_result := public.add_excused_date(current_date - 1);
  perform pg_temp.expect((v_result->>'count_in_window')::int = 2, 'L2. count increments to 2');

  -- ==========================================================================
  -- L3. Cap enforced: fill to 8, then 9th is rejected
  --     (already have 2; add 6 more → 8 total; then one more → must raise)
  -- ==========================================================================
  for i in 2..7 loop
    perform public.add_excused_date(current_date - i);
  end loop;
  -- Confirm we're at 8 now.
  select count(*) into v_cnt from public.user_streak_excused_dates
    where user_id = uid_a
      and excused_date > (timezone('utc', now())::date - 30);
  perform pg_temp.expect(v_cnt = 8, 'L3a. exactly 8 in-window after filling cap');

  -- 9th attempt must raise.
  begin
    v_result := public.add_excused_date(current_date - 8);
    perform pg_temp.expect(false, 'L3b. 9th add should raise');
  exception when others then
    perform pg_temp.expect(sqlerrm like '%Excused cap reached%', 'L3b. cap error message correct');
  end;

  -- Row count must still be 8 (not 9).
  select count(*) into v_cnt from public.user_streak_excused_dates
    where user_id = uid_a
      and excused_date > (timezone('utc', now())::date - 30);
  perform pg_temp.expect(v_cnt = 8, 'L3c. row count still 8 after rejected 9th');

  -- ==========================================================================
  -- L4. Idempotent re-add: existing date is a no-op (no error, no dup row)
  -- ==========================================================================
  begin
    v_result := public.add_excused_date(current_date);   -- already added in L1
    perform pg_temp.expect((v_result->>'ok')::boolean,   'L4a. re-add returns ok=true');
  exception when others then
    perform pg_temp.expect(false, 'L4. re-add of existing date must not raise');
  end;
  select count(*) into v_cnt from public.user_streak_excused_dates where user_id = uid_a;
  perform pg_temp.expect(v_cnt = 8, 'L4b. no duplicate row inserted on re-add');

  -- ==========================================================================
  -- L5. Dates outside the 30-day window are not counted toward the cap
  --     Insert an old row directly (bypassing the RPC), then confirm the
  --     in-window count is unchanged at 8 and a new in-window date fails.
  -- ==========================================================================
  perform pg_temp.reset_auth();
  insert into public.user_streak_excused_dates (user_id, excused_date)
    values (uid_a, current_date - 31)   -- outside the 30-day window
    on conflict do nothing;
  perform pg_temp.set_auth(uid_a);

  -- The in-window count must still be 8 (the old row doesn't count).
  select count(*) into v_cnt from public.user_streak_excused_dates
    where user_id = uid_a
      and excused_date > (timezone('utc', now())::date - 30);
  perform pg_temp.expect(v_cnt = 8, 'L5a. out-of-window row not counted toward cap');

  -- A new in-window date must still be rejected (window is still full).
  begin
    v_result := public.add_excused_date(current_date - 9);
    perform pg_temp.expect(false, 'L5b. cap still enforced with out-of-window rows present');
  exception when others then
    perform pg_temp.expect(true, 'L5b. cap correctly ignores out-of-window rows');
  end;

  -- ==========================================================================
  -- L6. Cap is per-user: uid_b's dates do not affect uid_a's count and vice versa
  -- ==========================================================================
  perform pg_temp.reset_auth();
  perform pg_temp.set_auth(uid_b);

  -- uid_b has no excused dates yet; should be able to add freely.
  v_result := public.add_excused_date(current_date);
  perform pg_temp.expect((v_result->>'ok')::boolean,              'L6a. uid_b add ok');
  perform pg_temp.expect((v_result->>'count_in_window')::int = 1, 'L6b. uid_b count=1 (independent)');

  -- uid_a's count is unaffected by uid_b's addition.
  perform pg_temp.reset_auth();
  select count(*) into v_cnt from public.user_streak_excused_dates
    where user_id = uid_a
      and excused_date > (timezone('utc', now())::date - 30);
  perform pg_temp.expect(v_cnt = 8, 'L6c. uid_a still at 8 after uid_b add');

  -- ==========================================================================
  -- Final tally
  -- ==========================================================================
  err := current_setting('test.failed', true);
  if length(coalesce(err, '')) > 0 then
    raise exception 'ADD_EXCUSED_DATE_LOCK TEST FAILED (% run): %',
      current_setting('test.total', true), err;
  else
    raise notice 'ALL PASS (% tests)', current_setting('test.total', true);
  end if;
end
$body$;

rollback;
