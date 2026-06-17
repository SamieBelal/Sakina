-- supabase/tests/activate_trial_test.sql
--
-- Pins the activate_trial RPC from migration
-- 20260616204630_reverse_trial_backend.sql.
--
-- Asserts:
--   1. activate_trial(3) sets trial_premium_until ~ now()+3d and had_trial=true.
--   2. IDEMPOTENCY: a second call at the SAME clock does NOT extend the window
--      (GREATEST(coalesce(existing, now()), now()+3d) is stable within a clock).
--   3. SHRINK-GUARD: activate_trial(1) over a longer existing window does NOT
--      shrink it (GREATEST keeps the longer existing operand — the other half).
--   4. no_profile: an authed user with NO user_profiles row gets the documented
--      {activated:false, reason:'no_profile'} no-op (does not crash).
--   5. anon CANNOT execute activate_trial (EXECUTE revoked).
--
-- Mirrors freemium_guard_gift_premium_until_test.sql structure
-- (BEGIN/ROLLBACK, pg_temp.expect, self-seeded auth.users, role impersonation).
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/activate_trial_test.sql

begin;

create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  if cond then
    perform set_config('test.passed',
      (coalesce(current_setting('test.passed', true), '0')::int + 1)::text, false);
  else
    perform set_config('test.failed_names',
      coalesce(current_setting('test.failed_names', true), '') || name || ';', false);
  end if;
  perform set_config('test.total',
    (coalesce(current_setting('test.total', true), '0')::int + 1)::text, false);
end;
$$;

select set_config('test.total','0',false),
       set_config('test.passed','0',false),
       set_config('test.failed_names','',false);

-- Self-seed an auth.users row + matching user_profiles row (handle_new_user
-- trigger creates the profile).
do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'activate-trial-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Impersonate the authenticated session.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- TEST 1: first activation grants ~3 days and stamps had_trial=true.
do $$
declare
  r          jsonb;
  v_until    timestamptz;
  v_had      boolean;
begin
  r := public.activate_trial(3);

  select trial_premium_until, had_trial into v_until, v_had
    from public.user_profiles where id = current_setting('test.uid')::uuid;

  perform pg_temp.expect((r->>'activated')::boolean = true,
    'activate_trial(3) returns activated=true');
  perform pg_temp.expect(v_until is not null,
    'activate_trial sets trial_premium_until');
  perform pg_temp.expect(
    v_until > now() + interval '2 days 12 hours'
      and v_until < now() + interval '3 days 12 hours',
    'trial_premium_until is ~now()+3 days');
  perform pg_temp.expect(v_had = true,
    'activate_trial sets had_trial=true');

  -- Stash the first window so TEST 2 can assert it did not move.
  perform set_config('test.first_until', v_until::text, false);
end $$;

-- TEST 2: IDEMPOTENCY — a second call at the same clock must NOT extend.
-- GREATEST(coalesce(existing, now()), now()+3d): with existing already at
-- now()+3d, the second call recomputes the same now()+3d, so the window is
-- unchanged (no extension).
do $$
declare
  r        jsonb;
  v_until  timestamptz;
  v_first  timestamptz := current_setting('test.first_until')::timestamptz;
begin
  r := public.activate_trial(3);

  select trial_premium_until into v_until
    from public.user_profiles where id = current_setting('test.uid')::uuid;

  perform pg_temp.expect((r->>'activated')::boolean = true,
    'second activate_trial(3) still returns activated=true');
  perform pg_temp.expect(v_until = v_first,
    'IDEMPOTENT: second activate_trial(3) at same clock does NOT extend the window');
end $$;

-- TEST 3: SHRINK-GUARD — the OTHER half of GREATEST(). With a 3-day window
-- already running, a shorter activate_trial(1) must NOT shrink it: GREATEST keeps
-- the longer existing window. (TEST 2 covered the equal-clock no-extend case;
-- this covers existing > now()+p_days, so GREATEST returns the *existing* operand
-- unchanged — the more interesting branch the suite didn't exercise.)
do $$
declare
  r        jsonb;
  v_until  timestamptz;
  v_first  timestamptz := current_setting('test.first_until')::timestamptz;
begin
  r := public.activate_trial(1);

  select trial_premium_until into v_until
    from public.user_profiles where id = current_setting('test.uid')::uuid;

  perform pg_temp.expect((r->>'activated')::boolean = true,
    'activate_trial(1) over a longer window still returns activated=true');
  perform pg_temp.expect(v_until = v_first,
    'SHRINK-GUARD: activate_trial(1) does NOT shrink the existing 3-day window '
    '(GREATEST keeps the longer existing operand)');
  perform pg_temp.expect(v_until > now() + interval '2 days 12 hours',
    'window remains ~3 days after the shorter call (not collapsed to ~1 day)');
end $$;

-- TEST 4: no_profile path — an authed user with NO user_profiles row. The RPC's
-- UPDATE ... RETURNING finds no row → `not found` → documented no-op result
-- {activated:false, reason:'no_profile'} (RPC body lines 73-75 of
-- 20260616204630_reverse_trial_backend.sql). Must NOT crash.
reset role;
do $$
declare v_uid uuid := gen_random_uuid();
begin
  -- Seed ONLY auth.users; suppress the handle_new_user trigger so NO
  -- user_profiles row is created (the whole point of this path).
  set local session_replication_role = replica;
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'activate-trial-noprofile-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  set local session_replication_role = origin;
  perform set_config('test.uid_noprofile', v_uid::text, false);
end $$;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid_noprofile'),
                    'role','authenticated')::text, true);
set local role authenticated;

do $$
declare
  r        jsonb;
  v_caught boolean := false;
begin
  begin
    r := public.activate_trial(3);
  exception when others then
    v_caught := true;
  end;

  perform pg_temp.expect(not v_caught,
    'no_profile: activate_trial(3) does NOT crash for a profile-less authed user');
  perform pg_temp.expect((r->>'activated')::boolean = false,
    'no_profile: returns activated=false');
  perform pg_temp.expect(r->>'reason' = 'no_profile',
    'no_profile: reason is the documented "no_profile"');
end $$;

-- TEST 5: anon cannot execute activate_trial (EXECUTE revoked from anon).
reset role;
select set_config('request.jwt.claims',
  json_build_object('role','anon')::text, true);
set local role anon;

do $$
declare v_caught boolean := false;
begin
  begin
    perform public.activate_trial(3);
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'anon CANNOT execute activate_trial (EXECUTE revoked)');
end $$;

reset role;

-- Final report
do $$
declare total int; passed int; failed_names text;
begin
  total  := current_setting('test.total')::int;
  passed := current_setting('test.passed')::int;
  failed_names := current_setting('test.failed_names');
  raise notice E'\n========================';
  raise notice 'activate_trial_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
end $$;

rollback;
