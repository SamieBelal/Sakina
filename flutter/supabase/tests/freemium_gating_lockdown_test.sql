-- Regression test for:
--   * 20260510010000_lock_freemium_gating_fields.sql
--   * 20260510030000_close_freemium_delete_recreate_bypass.sql
--
-- Verifies freemium gating fields cannot be tampered with by direct client
-- UPDATE or DELETE, while legitimate app/backend paths still work.
--
-- Pattern matches backend_rls_audit.sql: one transaction, assertions inside a
-- DO block, rollback at end. Run via:
--   mcp__supabase__execute_sql query=$(cat freemium_gating_lockdown_test.sql)
--
-- Coverage:
--   1. authenticated CANNOT refill warmup_reflect_remaining
--   2. authenticated CANNOT refill warmup_built_dua_remaining
--   3. authenticated CANNOT refill warmup_discover_name_remaining
--   4. authenticated CANNOT flip had_trial true→false
--   5. authenticated CANNOT reset reflect_uses / built_dua_uses / discover_name_uses
--   6. authenticated CAN decrement warmup (10→9) — legitimate write
--   7. authenticated CAN flip had_trial false→true — legitimate latch-on
--   8. authenticated CAN increment *_uses — legitimate write
--   9. authenticated CAN UPDATE unrelated columns (display_name) — guard is
--      column-scoped and doesn't interfere with normal profile edits
--  10. service_role bypass: can reset warmup + flip had_trial → false
--      (admin tools, daily rollover scripts must keep working)
--  11. authenticated CANNOT DELETE user_profiles / user_daily_usage through
--      production RLS (no DELETE policy)
--  12. authenticated CANNOT DELETE those rows even if a DELETE policy is
--      accidentally reintroduced (BEFORE DELETE trigger defense-in-depth)
--  13. authenticated CAN still delete their account via delete_own_account(),
--      and FK CASCADE removes the guarded rows

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

select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000401',
  'gating-lockdown@test.sakina.local'
);

-- Seed user_profiles row with non-default values so we can detect both
-- forbidden refill (NEW > OLD) and forbidden reset (had_trial true → false).
-- handle_new_user() trigger may have already created a default row from
-- auth.users insert; UPDATE rather than INSERT to be safe.
update public.user_profiles
set warmup_reflect_remaining = 7,
    warmup_built_dua_remaining = 6,
    warmup_discover_name_remaining = 3,
    had_trial = true
where id = '00000000-0000-0000-0000-000000000401';

-- Seed user_daily_usage row with non-zero usage so we can detect forbidden
-- resets to 0.
insert into public.user_daily_usage (
  user_id, usage_date, reflect_uses, built_dua_uses, discover_name_uses
) values (
  '00000000-0000-0000-0000-000000000401', current_date, 5, 4, 1
);

do $body$
declare
  uid constant uuid := '00000000-0000-0000-0000-000000000401';
  failures text[] := array[]::text[];
  total int := 0;
  err text;
  raised boolean;
  affected int;
  current_warmup int;
  current_had_trial boolean;
  current_reflect_uses int;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- =========================================================================
  -- Impersonate the user (authenticated role).
  -- =========================================================================
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid::text, 'role', 'authenticated')::text, true);

  -- -------------------------------------------------------------------------
  -- 1. Cannot refill warmup_reflect_remaining (7 → 10)
  -- -------------------------------------------------------------------------
  raised := false;
  begin
    update public.user_profiles set warmup_reflect_remaining = 10 where id = uid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '1. refill warmup_reflect_remaining (7→10) blocked by trigger');

  -- -------------------------------------------------------------------------
  -- 2. Cannot refill warmup_built_dua_remaining (6 → 10)
  -- -------------------------------------------------------------------------
  raised := false;
  begin
    update public.user_profiles set warmup_built_dua_remaining = 10 where id = uid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '2. refill warmup_built_dua_remaining (6→10) blocked by trigger');

  -- -------------------------------------------------------------------------
  -- 3. Cannot refill warmup_discover_name_remaining (3 → 5)
  -- -------------------------------------------------------------------------
  raised := false;
  begin
    update public.user_profiles set warmup_discover_name_remaining = 5 where id = uid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '3. refill warmup_discover_name_remaining (3→5) blocked by trigger');

  -- -------------------------------------------------------------------------
  -- 4. Cannot flip had_trial true→false (free-trial replay attempt)
  -- -------------------------------------------------------------------------
  raised := false;
  begin
    update public.user_profiles set had_trial = false where id = uid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '4. flip had_trial true→false blocked by trigger (one-way latch)');

  -- -------------------------------------------------------------------------
  -- 5. Cannot reset reflect_uses 5 → 0 (daily-cap evasion attempt)
  -- -------------------------------------------------------------------------
  raised := false;
  begin
    update public.user_daily_usage
       set reflect_uses = 0
     where user_id = uid and usage_date = current_date;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '5a. reset reflect_uses (5→0) blocked by trigger');

  raised := false;
  begin
    update public.user_daily_usage
       set built_dua_uses = 0
     where user_id = uid and usage_date = current_date;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '5b. reset built_dua_uses (4→0) blocked by trigger');

  raised := false;
  begin
    update public.user_daily_usage
       set discover_name_uses = 0
     where user_id = uid and usage_date = current_date;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '5c. reset discover_name_uses (1→0) blocked by trigger');

  -- Confirm none of the above writes leaked through (state unchanged).
  select warmup_reflect_remaining into current_warmup
    from public.user_profiles where id = uid;
  perform pg_temp.expect(current_warmup = 7,
    'warmup_reflect_remaining still 7 after all rejected refills');

  select had_trial into current_had_trial
    from public.user_profiles where id = uid;
  perform pg_temp.expect(current_had_trial = true,
    'had_trial still true after rejected reset');

  select reflect_uses into current_reflect_uses
    from public.user_daily_usage where user_id = uid and usage_date = current_date;
  perform pg_temp.expect(current_reflect_uses = 5,
    'reflect_uses still 5 after rejected reset');

  -- =========================================================================
  -- Legitimate writes still work.
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- 6. Decrement warmup_reflect_remaining 7 → 6 (the gating_service path)
  -- -------------------------------------------------------------------------
  begin
    update public.user_profiles set warmup_reflect_remaining = 6 where id = uid;
    perform pg_temp.expect(true,
      '6. decrement warmup_reflect_remaining (7→6) succeeds');
  exception when others then
    perform pg_temp.expect(false,
      '6. decrement warmup_reflect_remaining (7→6) failed: ' || SQLERRM);
  end;

  -- -------------------------------------------------------------------------
  -- 7. Latch had_trial false → true (the purchase_service path).
  --    Need to first reset to false via service_role, then verify
  --    authenticated can flip it on.
  -- -------------------------------------------------------------------------
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
  update public.user_profiles set had_trial = false where id = uid;

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid::text, 'role', 'authenticated')::text, true);

  begin
    update public.user_profiles set had_trial = true where id = uid;
    perform pg_temp.expect(true,
      '7. latch had_trial false→true succeeds');
  exception when others then
    perform pg_temp.expect(false,
      '7. latch had_trial false→true failed: ' || SQLERRM);
  end;

  -- -------------------------------------------------------------------------
  -- 8. Increment reflect_uses 5 → 6 (the daily_usage_service path)
  -- -------------------------------------------------------------------------
  begin
    update public.user_daily_usage
       set reflect_uses = 6
     where user_id = uid and usage_date = current_date;
    perform pg_temp.expect(true,
      '8. increment reflect_uses (5→6) succeeds');
  exception when others then
    perform pg_temp.expect(false,
      '8. increment reflect_uses (5→6) failed: ' || SQLERRM);
  end;

  -- -------------------------------------------------------------------------
  -- 9. Unrelated UPDATE on user_profiles (display_name) still works.
  --    Guard must be column-scoped — must not block normal profile edits.
  -- -------------------------------------------------------------------------
  begin
    update public.user_profiles set display_name = 'New Name' where id = uid;
    perform pg_temp.expect(true,
      '9. unrelated display_name update succeeds (guard is column-scoped)');
  exception when others then
    perform pg_temp.expect(false,
      '9. unrelated display_name update failed: ' || SQLERRM);
  end;

  -- =========================================================================
  -- 10. service_role bypass — admin tools / backend functions must NOT be
  --     blocked by the trigger.
  -- =========================================================================
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
  execute 'set local role service_role';

  begin
    update public.user_profiles
       set warmup_reflect_remaining = 10,
           had_trial = false
     where id = uid;
    perform pg_temp.expect(true,
      '10a. service_role can refill warmup + reset had_trial (bypass)');
  exception when others then
    perform pg_temp.expect(false,
      '10a. service_role write failed unexpectedly: ' || SQLERRM);
  end;

  begin
    update public.user_daily_usage
       set reflect_uses = 0, built_dua_uses = 0, discover_name_uses = 0
     where user_id = uid and usage_date = current_date;
    perform pg_temp.expect(true,
      '10b. service_role can reset *_uses (bypass for daily rollover)');
  exception when others then
    perform pg_temp.expect(false,
      '10b. service_role *_uses reset failed unexpectedly: ' || SQLERRM);
  end;

  execute 'reset role';

  -- =========================================================================
  -- 11. Direct client DELETE is denied by production RLS.
  -- =========================================================================
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid::text, 'role', 'authenticated')::text, true);

  delete from public.user_profiles where id = uid;
  get diagnostics affected = row_count;
  perform pg_temp.expect(affected = 0,
    '11a. authenticated DELETE user_profiles affects 0 rows (no DELETE policy)');
  perform pg_temp.expect(
    (select count(*) from public.user_profiles where id = uid) = 1,
    '11b. user_profiles row remains after authenticated DELETE attempt');

  delete from public.user_daily_usage
   where user_id = uid and usage_date = current_date;
  get diagnostics affected = row_count;
  perform pg_temp.expect(affected = 0,
    '11c. authenticated DELETE user_daily_usage affects 0 rows (no DELETE policy)');
  perform pg_temp.expect(
    (select count(*) from public.user_daily_usage
      where user_id = uid and usage_date = current_date) = 1,
    '11d. user_daily_usage row remains after authenticated DELETE attempt');

  -- =========================================================================
  -- 12. DELETE trigger blocks the bypass even if a future migration
  --     accidentally re-adds client DELETE policies.
  -- =========================================================================
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
  execute 'drop policy if exists "__test_freemium_profile_delete_guard" on public.user_profiles';
  execute 'create policy "__test_freemium_profile_delete_guard" on public.user_profiles for delete to authenticated using ((select auth.uid()) = id)';
  execute 'drop policy if exists "__test_freemium_usage_delete_guard" on public.user_daily_usage';
  execute 'create policy "__test_freemium_usage_delete_guard" on public.user_daily_usage for delete to authenticated using ((select auth.uid()) = user_id)';

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid::text, 'role', 'authenticated')::text, true);

  raised := false;
  begin
    delete from public.user_profiles where id = uid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '12a. authenticated DELETE user_profiles blocked by guard trigger when policy exists');
  perform pg_temp.expect(
    (select count(*) from public.user_profiles where id = uid) = 1,
    '12b. user_profiles row remains after trigger-blocked DELETE');

  raised := false;
  begin
    delete from public.user_daily_usage
     where user_id = uid and usage_date = current_date;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '12c. authenticated DELETE user_daily_usage blocked by guard trigger when policy exists');
  perform pg_temp.expect(
    (select count(*) from public.user_daily_usage
      where user_id = uid and usage_date = current_date) = 1,
    '12d. user_daily_usage row remains after trigger-blocked DELETE');

  -- =========================================================================
  -- 13. Supported account deletion still works.
  -- =========================================================================
  begin
    perform public.delete_own_account();
    perform pg_temp.expect(true,
      '13a. delete_own_account succeeds with guarded freemium rows present');
  exception when others then
    perform pg_temp.expect(false,
      '13a. delete_own_account failed unexpectedly: ' || SQLERRM);
  end;

  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  perform pg_temp.expect(
    (select count(*) from auth.users where id = uid) = 0,
    '13b. auth.users row deleted by delete_own_account');
  perform pg_temp.expect(
    (select count(*) from public.user_profiles where id = uid) = 0,
    '13c. user_profiles cascades during delete_own_account despite guard');
  perform pg_temp.expect(
    (select count(*) from public.user_daily_usage where user_id = uid) = 0,
    '13d. user_daily_usage cascades during delete_own_account despite guard');

  -- =========================================================================
  -- Final tally
  -- =========================================================================
  total := current_setting('test.total', true)::int;
  err := current_setting('test.failed', true);

  if length(err) > 0 then
    raise exception 'FREEMIUM GATING LOCKDOWN FAILED (% tests run): %', total, err;
  else
    raise notice 'ALL PASS (% tests)', total;
  end if;
end
$body$;

rollback;
