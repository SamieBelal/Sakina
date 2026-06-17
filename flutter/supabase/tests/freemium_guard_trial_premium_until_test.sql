-- supabase/tests/freemium_guard_trial_premium_until_test.sql
--
-- Pins the freemium-guard extension from migration
-- 20260616204630_reverse_trial_backend.sql.
--
-- Asserts (1) authenticated users CANNOT modify trial_premium_until directly
-- via a PostgREST/RLS UPDATE (self-grant of infinite premium), and (2) the
-- honest path through activate_trial() — SECURITY DEFINER owned by postgres —
-- still stamps the column.
--
-- Mirrors freemium_guard_gift_premium_until_test.sql.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/freemium_guard_trial_premium_until_test.sql

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
          'authenticated', 'trial-guard-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Impersonate authenticated session for the EXPLOIT tests.
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- TEST 1: far-future direct UPDATE (the self-grant-infinite-premium exploit)
-- must raise check_violation.
do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_profiles
       set trial_premium_until = '2999-01-01 00:00:00+00'
     where id = current_setting('test.uid')::uuid;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'direct UPDATE on trial_premium_until is blocked');
end $$;

-- TEST 2: any non-null value via direct UPDATE is blocked (matches the
-- `is distinct from` clause, not just far-future timestamps).
do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_profiles
       set trial_premium_until = now() + interval '1 day'
     where id = current_setting('test.uid')::uuid;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'direct UPDATE on trial_premium_until with any non-null value is blocked');
end $$;

-- TEST 3: clearing the column (non-null -> null) is also blocked. Seed a
-- non-null value via postgres (bypasses guard), then attempt to clear it
-- as authenticated.
reset role;
update public.user_profiles
   set trial_premium_until = now() + interval '3 days'
 where id = current_setting('test.uid')::uuid;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_profiles set trial_premium_until = null
      where id = current_setting('test.uid')::uuid;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'clearing trial_premium_until (non-null -> null) is blocked');
end $$;

-- TEST 4 (HONEST PATH): activate_trial() — SECURITY DEFINER owned by postgres —
-- must still stamp trial_premium_until. Inside the RPC body current_user =
-- postgres (in the guard's bypass list), so the UPDATE passes. Pins that
-- assumption: if activate_trial were recreated under a non-postgres owner this
-- test fails and the trial mechanic breaks.
reset role;
update public.user_profiles set trial_premium_until = null
 where id = current_setting('test.uid')::uuid;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

do $$
declare
  v_before timestamptz;
  v_after  timestamptz;
  r jsonb;
begin
  select trial_premium_until into v_before from public.user_profiles
    where id = current_setting('test.uid')::uuid;

  r := public.activate_trial(3);

  select trial_premium_until into v_after from public.user_profiles
    where id = current_setting('test.uid')::uuid;

  perform pg_temp.expect(
    (r->>'activated')::boolean = true and v_before is null and v_after is not null,
    'HONEST PATH: activate_trial stamps trial_premium_until through guard'
  );
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
  raise notice 'freemium_guard_trial_premium_until_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
end $$;

rollback;
