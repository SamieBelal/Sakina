-- supabase/tests/sync_all_user_data_trial_roundtrip_test.sql
--
-- CRITICAL G6 (ADR Eng-review hardening #5,
-- docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md).
--
-- Pins that sync_all_user_data() READS trial_premium_until back and does NOT
-- trip the freemium guard. The collision risk: if sync ever WROTE
-- trial_premium_until from a client payload, the freemium guard would raise
-- check_violation and silently fail the WHOLE UPDATE (sync_all_user_data is a
-- single RPC, so a guard raise aborts everything). This test proves:
--   1. activate_trial(3) stamps the window (honest writer).
--   2. sync_all_user_data() returns profile.trial_premium_until matching the
--      stamped value (read-back works).
--   3. sync_all_user_data() does NOT raise (no guard collision — it never
--      writes the column).
--   4. profile.had_trial round-trips as true.
--
-- Mirrors freemium_guard_gift_premium_until_test.sql.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/sync_all_user_data_trial_roundtrip_test.sql

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

-- Self-seed an auth.users row + matching user_profiles row.
do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'sync-trial-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Impersonate the authenticated session.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- Activate the trial via the honest definer path, then round-trip through sync.
do $$
declare
  r_act    jsonb;
  r_sync   jsonb;
  v_stamp  timestamptz;
  v_sync   timestamptz;
  v_raised boolean := false;
begin
  r_act := public.activate_trial(3);

  select trial_premium_until into v_stamp from public.user_profiles
    where id = current_setting('test.uid')::uuid;

  -- TEST 1: sync returns WITHOUT raising (no guard collision).
  begin
    r_sync := public.sync_all_user_data();
  exception when others then
    v_raised := true;
  end;
  perform pg_temp.expect(not v_raised,
    'sync_all_user_data() does NOT trip the freemium guard (no raise)');

  -- TEST 2: profile.trial_premium_until is present and matches the stamp.
  v_sync := (r_sync #>> '{profile,trial_premium_until}')::timestamptz;
  perform pg_temp.expect(v_sync is not null,
    'sync_all_user_data() returns profile.trial_premium_until');
  perform pg_temp.expect(v_sync = v_stamp,
    'sync_all_user_data() round-trips trial_premium_until = stamped value');

  -- TEST 3: had_trial round-trips as true.
  perform pg_temp.expect(
    (r_sync #>> '{profile,had_trial}')::boolean = true,
    'sync_all_user_data() round-trips had_trial = true');
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
  raise notice 'sync_all_user_data_trial_roundtrip_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
end $$;

rollback;
