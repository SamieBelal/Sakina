-- supabase/tests/freemium_guards_bypass_fields_test.sql
--
-- Pins the freemium-guard extension from migration
-- 20260524000000_extend_freemium_guards_for_bypass_fields.sql.
--
-- Each test impersonates an authenticated session for a fixed UUID and
-- asserts that the protected UPDATE is rejected. Wrapped in a single
-- BEGIN/ROLLBACK so no live state is persisted.
--
-- Run via: psql "$DATABASE_URL" -f supabase/tests/freemium_guards_bypass_fields_test.sql
-- Or via Supabase MCP execute_sql.

begin;

-- Re-use the helper convention from ai_bypass_rpc_test.sql
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

-- Pick a known user. If none exists in dev, the test errors clearly.
do $$
declare v_uid uuid;
begin
  select id into v_uid from auth.users order by created_at limit 1;
  if v_uid is null then
    raise exception 'No auth.users to test against — seed at least one user first';
  end if;
  perform set_config('test.uid', v_uid::text, false);
end $$;

-- Seed today's row at the cap as postgres (bypasses guards). All three
-- bypass counters seeded to 2 so the reset-to-0 tests are genuine
-- decrements rather than NEW=OLD no-ops.
insert into public.user_daily_usage
  (user_id, usage_date, reflect_uses, reflect_bypasses_used,
   built_dua_bypasses_used, discover_name_bypasses_used)
values (current_setting('test.uid')::uuid, (timezone('utc',now()))::date,
        3, 2, 2, 2)
on conflict (user_id, usage_date) do update
set reflect_uses=3, reflect_bypasses_used=2,
    built_dua_bypasses_used=2, discover_name_bypasses_used=2;

update public.user_profiles
set first_bypass_consumed=true, lifetime_bypasses_purchased=50
where id=current_setting('test.uid')::uuid;

-- Impersonate authenticated
select set_config('request.jwt.claims',
  json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
set local role authenticated;

-- TEST 1: reset reflect_bypasses_used -> should now be blocked
do $$
declare v_caught boolean := false;
begin
  begin
    update public.user_daily_usage set reflect_bypasses_used=0
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
  exception when others then v_caught := true;
  end;
  perform pg_temp.expect(v_caught, 'reset reflect_bypasses_used is blocked');
end $$;

-- TEST 2: reset built_dua_bypasses_used
do $$ declare v boolean := false; begin
  begin
    update public.user_daily_usage set built_dua_bypasses_used=0
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'reset built_dua_bypasses_used is blocked');
end $$;

-- TEST 3: reset discover_name_bypasses_used
do $$ declare v boolean := false; begin
  begin
    update public.user_daily_usage set discover_name_bypasses_used=0
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'reset discover_name_bypasses_used is blocked');
end $$;

-- TEST 4: flip first_bypass_consumed true -> false
do $$ declare v boolean := false; begin
  begin
    update public.user_profiles set first_bypass_consumed=false
      where id=current_setting('test.uid')::uuid;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'flip first_bypass_consumed true->false is blocked');
end $$;

-- TEST 5: decrement lifetime_bypasses_purchased
do $$ declare v boolean := false; begin
  begin
    update public.user_profiles set lifetime_bypasses_purchased=0
      where id=current_setting('test.uid')::uuid;
  exception when others then v := true; end;
  perform pg_temp.expect(v, 'decrement lifetime_bypasses_purchased is blocked');
end $$;

-- TEST 6: monotonic increment still allowed (honest happy path)
do $$ declare v boolean := false; begin
  begin
    update public.user_daily_usage set reflect_bypasses_used=2
      where user_id=current_setting('test.uid')::uuid
        and usage_date=(timezone('utc',now()))::date;
    v := true;
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'incrementing reflect_bypasses_used to same value still works');
end $$;

-- TEST 7: incrementing lifetime is still allowed
do $$ declare v boolean := false; begin
  begin
    update public.user_profiles set lifetime_bypasses_purchased=51
      where id=current_setting('test.uid')::uuid;
    v := true;
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'incrementing lifetime_bypasses_purchased still works');
end $$;

-- TEST 8 (HONEST PATH): cancel_ai_bypass MUST still be able to decrement
-- reflect_bypasses_used. The function is SECURITY DEFINER owned by `postgres`
-- (verified live via pg_proc.proowner). Inside the function body
-- current_user = postgres, which is in the bypass list of the guard, so
-- the decrement passes. This test pins that assumption — if the function
-- were ever recreated under a non-postgres owner, this test fails and the
-- refund path silently breaks.
reset role;
do $$
declare v_resv_id uuid; v_before int; v_after int; r jsonb;
begin
  update public.user_daily_usage set reflect_bypasses_used=1
    where user_id=current_setting('test.uid')::uuid
      and usage_date=(timezone('utc',now()))::date;
  insert into public.ai_bypass_reservations (user_id, feature, status, tokens_held)
    values (current_setting('test.uid')::uuid, 'reflect', 'pending', 25)
    returning id into v_resv_id;
  select reflect_bypasses_used into v_before from public.user_daily_usage
    where user_id=current_setting('test.uid')::uuid
      and usage_date=(timezone('utc',now()))::date;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.uid'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.cancel_ai_bypass(v_resv_id);
  reset role;

  select reflect_bypasses_used into v_after from public.user_daily_usage
    where user_id=current_setting('test.uid')::uuid
      and usage_date=(timezone('utc',now()))::date;
  perform pg_temp.expect(v_after = v_before - 1,
    'HONEST PATH: cancel_ai_bypass decrements bypass counter through guard');
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
  raise notice 'freemium_guards_bypass_fields_test: % / % passed', passed, total;
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
end $$;

rollback;
