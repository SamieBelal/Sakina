-- supabase/tests/freemium_guard_gift_premium_until_test.sql
--
-- Pins the freemium-guard extension from migration
-- 20260525200000_extend_freemium_guard_for_gift_premium_until.sql.
--
-- Asserts (1) authenticated users CANNOT modify gift_premium_until directly
-- via PostgREST/RLS UPDATE (the live-reproduced exploit from
-- docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md), and (2) the
-- honest path through claim_sakina_gift() — SECURITY DEFINER owned by
-- postgres — still stamps the column.
--
-- Wrapped in a single BEGIN/ROLLBACK so no live state is persisted.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/freemium_guard_gift_premium_until_test.sql
-- Or via Supabase MCP execute_sql.

begin;

-- Helper convention from ai_bypass_rpc_test.sql + freemium_guards_bypass_fields_test.sql
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

-- Self-seed an auth.users row + the matching user_profiles row created by
-- the handle_new_user trigger.
do $$
declare v_uid uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values (v_uid, '00000000-0000-0000-0000-000000000000', 'authenticated',
          'authenticated', 'gift-guard-test-' || v_uid::text || '@example.com',
          '', now(), now(), now());
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Test occasion bracketing now()
insert into public.islamic_occasions(id, display_name, starts_at, ends_at)
values ('guard_test_active', 'Guard Test Active',
        now() - interval '1 day', now() + interval '6 days')
on conflict (id) do nothing;

-- Impersonate authenticated session for the EXPLOIT tests (TEST 1, TEST 2)
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- TEST 1: setting gift_premium_until to a far-future date via direct UPDATE
-- (the exact exploit shape from P1-3 in docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md).
-- Pre-guard: succeeded. Post-guard: must raise check_violation.
do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_profiles
       set gift_premium_until = '2999-01-01 00:00:00+00'
     where id = current_setting('test.uid')::uuid;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'direct UPDATE on gift_premium_until is blocked');
end $$;

-- TEST 2: setting it to ANY non-null value via direct UPDATE is blocked
-- (matches the `is distinct from` clause, not just far-future timestamps).
do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_profiles
       set gift_premium_until = now() + interval '1 day'
     where id = current_setting('test.uid')::uuid;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'direct UPDATE on gift_premium_until with any non-null value is blocked');
end $$;

-- TEST 3: clearing the column (setting to NULL when it was non-null) is also blocked.
-- First, seed a non-null value via the postgres role (bypasses guard), then
-- attempt to clear it as authenticated.
reset role;
update public.user_profiles
   set gift_premium_until = now() + interval '7 days'
 where id = current_setting('test.uid')::uuid;

select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_profiles set gift_premium_until = null
      where id = current_setting('test.uid')::uuid;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught,
    'clearing gift_premium_until (non-null -> null) is blocked');
end $$;

-- TEST 4 (HONEST PATH): claim_sakina_gift() — SECURITY DEFINER owned by
-- `postgres` — must still be able to stamp gift_premium_until. Inside the
-- RPC body, current_user = postgres, which is in the guard's bypass list,
-- so the UPDATE passes. This test pins that assumption — if claim_sakina_gift
-- were ever recreated under a non-postgres owner, this test fails and the
-- whole gift mechanic breaks.
--
-- Reset the column first via postgres, then call the RPC as the
-- authenticated user.
reset role;
update public.user_profiles set gift_premium_until = null
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
  select gift_premium_until into v_before from public.user_profiles
    where id = current_setting('test.uid')::uuid;

  r := public.claim_sakina_gift(
    current_setting('test.uid')::uuid,
    'guard_test_active'
  );

  select gift_premium_until into v_after from public.user_profiles
    where id = current_setting('test.uid')::uuid;

  perform pg_temp.expect(
    (r->>'granted')::boolean = true and v_before is null and v_after is not null,
    'HONEST PATH: claim_sakina_gift stamps gift_premium_until through guard'
  );
end $$;

reset role;

-- Cleanup the test occasion (the rollback below covers everything, but be
-- explicit about ownership of side effects.)
delete from public.islamic_occasions where id = 'guard_test_active';

-- Final report
do $$
declare total int; passed int; failed_names text;
begin
  total  := current_setting('test.total')::int;
  passed := current_setting('test.passed')::int;
  failed_names := current_setting('test.failed_names');
  raise notice E'\n========================';
  raise notice 'freemium_guard_gift_premium_until_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
end $$;

rollback;
