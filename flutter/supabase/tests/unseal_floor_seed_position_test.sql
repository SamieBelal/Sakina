-- Regression test for:
--   * 20260727130000_unseal_floor_excludes_seed_position.sql
--
-- The defect: the 20-hour floor in `unseal_next_name` measured
-- `max(unsealed_at)` across ALL positions, including position 1 — which
-- `seed_name_queue` marks unsealed at ONBOARDING time. So the clock on the
-- user's first real unseal started at onboarding rather than at local midnight,
-- and anyone onboarding after roughly midday could not reach D1 the next
-- morning. Test 3 below is that regression; it fails on the old function.
--
-- Pattern matches one_ship_w1_data_layer_test.sql: one transaction, pg_temp
-- harness, assertions in a DO block, rollback at end.
--
-- NOTE ON TIME: now() is frozen for the whole transaction, so "later" states
-- are simulated by backdating stored timestamps as postgres (RLS/guard-exempt),
-- never by waiting. "The next local day, <20h later" is simulated by pinning the
-- user's zone so their local clock has just passed midnight — then a 10-11h-old
-- timestamp is yesterday-local while still inside the wall-clock floor, which is
-- exactly the state that separates the two branches. Deterministic at any run
-- time (same device as one_ship_w1_data_layer_test.sql test 17).
--
-- Coverage:
--   1     same local evening as onboarding → position 1, nothing advances
--   2     the seed alone does not arm the floor
--   3     next local day, <20h after onboarding → ADVANCES to position 2  ← fix
--   4-5   an RPC-driven unseal DOES arm the floor: <20h later holds
--   6     a user with no queue rows → empty result
--   7     exhausted queue → empty result

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

create or replace function pg_temp.test_insert_auth_user(
  p_id uuid,
  p_email text
) returns void
language sql
as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id, 'authenticated', 'authenticated', p_email, '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
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

-- The zone whose local clock has just passed midnight right now, so that a
-- timestamp N hours old (N < 20) reads as "yesterday, local".
-- POSIX sign convention: Etc/GMT+N is UTC-N.
create or replace function pg_temp.just_past_midnight_tz() returns text
language sql as $$
  select case
    when extract(hour from now() at time zone 'UTC')::int = 0 then 'UTC'
    when extract(hour from now() at time zone 'UTC')::int <= 12
      then 'Etc/GMT+' || extract(hour from now() at time zone 'UTC')::int
    else 'Etc/GMT-' || (24 - extract(hour from now() at time zone 'UTC')::int)
  end;
$$;

-- Catalog fixtures: collectible_names is content-seeded in prod (client catalog
-- push), NOT by migrations — a fresh CI database has zero rows, so the FK
-- fixtures the queue needs are inserted here (rolled back).
insert into public.collectible_names (id, arabic, transliteration, english)
select i, 'اسم', 'Test-Name-' || i, 'Test Name ' || i
from unnest(array[61, 62, 63, 71, 72]) as i
on conflict (id) do nothing;

select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000c01', 'unseal-a@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000c02', 'unseal-b@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000c03', 'unseal-c@test.sakina.local');

do $body$
declare
  uid_a constant uuid := '00000000-0000-0000-0000-000000000c01';
  uid_b constant uuid := '00000000-0000-0000-0000-000000000c02';
  uid_c constant uuid := '00000000-0000-0000-0000-000000000c03';
  total int := 0;
  err text;
  v_pos int;
  v_name int;
  v_count int;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- Every user's local clock has just passed midnight, so a 10-11h-old
  -- timestamp is yesterday-local AND inside the 20h floor. Upserted rather
  -- than updated so the test does not silently degrade to safe_user_tz's UTC
  -- fallback if handle_new_user ever stops seeding the prefs row.
  insert into public.user_notification_preferences (user_id, timezone)
  select u, pg_temp.just_past_midnight_tz()
  from unnest(array[uid_a, uid_b, uid_c]) as u
  on conflict (user_id) do update set timezone = excluded.timezone;

  -- =========================================================================
  -- ONBOARDING DAY (1-2)
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);
  perform public.seed_name_queue(array[61, 62, 63]);

  -- 1. Same local evening as onboarding: the local-day idempotency branch
  --    returns position 1 and nothing advances. THIS is what enforces
  --    "tomorrow" — not the wall-clock floor.
  select q.position, q.name_id into v_pos, v_name
    from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 1 and v_name = 61,
    '1a. same local evening as onboarding returns position 1');
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 1,
    '1b. no same-local-day advance (idempotency branch, floor not needed)');

  -- 2. The seed did not arm the floor: position 1 is the only unsealed row and
  --    it contributes nothing to max(unsealed_at) over position > 1.
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and position > 1 and unsealed_at is not null;
  perform pg_temp.expect(v_count = 0,
    '2. the seed leaves every RPC-eligible position sealed');

  -- =========================================================================
  -- THE REGRESSION (3): next local day, still inside 20h
  -- =========================================================================

  -- 3. Onboard 21:00 Monday → open the app 08:00 Tuesday. 11 wall-clock hours,
  --    but a different local day. Before the fix the floor measured from the
  --    SEED's timestamp and returned position 1 — the promised D1 Name was
  --    unreachable for anyone who onboarded after roughly midday, while the
  --    copy on the seal says "Sealed until tomorrow".
  update public.user_name_queue
    set unsealed_at = now() - interval '11 hours'
    where user_id = uid_a and position = 1;
  perform pg_temp.set_auth(uid_a);
  select q.position, q.name_id into v_pos, v_name
    from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 2 and v_name = 62,
    '3a. next local day <20h after onboarding ADVANCES to position 2');
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 2,
    '3b. exactly one new position unsealed on the comeback morning');

  -- =========================================================================
  -- THE FLOOR STILL WORKS (4-5): an RPC-driven unseal DOES arm it
  -- =========================================================================

  -- 4. Position 2 unsealed 10h ago and yesterday-local: the idempotency branch
  --    misses, so only the wall-clock floor stands between the caller and
  --    position 3. It holds, and returns the row it last handed out.
  update public.user_name_queue
    set unsealed_at = now() - interval '10 hours'
    where user_id = uid_a and position = 2;
  perform pg_temp.set_auth(uid_a);
  select q.position into v_pos from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 2,
    '4a. yesterday-local but only 10h since an RPC unseal: floor holds');
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 2,
    '4b. the 20h floor alone blocked the advance (position 3 still sealed)');

  -- 5. A real day later, position 3 comes next — the floor is a delay, not a
  --    wall.
  update public.user_name_queue
    set unsealed_at = unsealed_at - interval '25 hours'
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.set_auth(uid_a);
  select q.position into v_pos from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 3,
    '5. once the floor clears the queue advances by position');

  -- =========================================================================
  -- EMPTY RESULTS (6-7)
  -- =========================================================================

  -- 6. A user with no queue rows at all (legacy / never seeded): empty, and
  --    nothing is created for them.
  perform pg_temp.set_auth(uid_c);
  select count(*) into v_count from public.unseal_next_name() as q;
  perform pg_temp.expect(v_count = 0,
    '6a. a user with no queue rows gets an empty result');
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue where user_id = uid_c;
  perform pg_temp.expect(v_count = 0,
    '6b. the empty call created no rows');

  -- 7. Exhaustion: B seeds a 2-Name queue, drains it, then gets empty.
  perform pg_temp.set_auth(uid_b);
  perform public.seed_name_queue(array[71, 72]);
  perform pg_temp.reset_auth();
  update public.user_name_queue
    set unsealed_at = now() - interval '11 hours'
    where user_id = uid_b and position = 1;
  perform pg_temp.set_auth(uid_b);
  select q.position into v_pos from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 2,
    '7a. B reaches position 2 the next local morning too');
  perform pg_temp.reset_auth();
  update public.user_name_queue
    set unsealed_at = now() - interval '25 hours'
    where user_id = uid_b;
  perform pg_temp.set_auth(uid_b);
  select count(*) into v_count from public.unseal_next_name() as q;
  perform pg_temp.expect(v_count = 0,
    '7b. exhausted queue returns empty result');
  perform pg_temp.reset_auth();

  -- =========================================================================
  -- Final tally
  -- =========================================================================
  total := current_setting('test.total', true)::int;
  err := current_setting('test.failed', true);

  if length(err) > 0 then
    raise exception 'UNSEAL FLOOR SEED POSITION TEST FAILED (% tests run): %', total, err;
  else
    raise notice 'ALL PASS (% tests)', total;
  end if;
end
$body$;

rollback;
