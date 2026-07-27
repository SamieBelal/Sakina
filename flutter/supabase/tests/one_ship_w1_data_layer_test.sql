-- Regression test for the One Ship W1 data layer:
--   * 20260726200000_tz_validation.sql
--   * 20260726200100_user_name_queue.sql
--   * 20260726200200_free_tier_cohort_weekly_pool.sql
--   * 20260726200300_sync_one_ship_profile_keys.sql
--
-- Pattern matches ai_bypass_rpc_test.sql: one transaction, pg_temp harness,
-- assertions in a DO block, rollback at end.
--
-- NOTE ON TIME: now() is frozen for the whole transaction, so "later" states
-- are simulated by backdating stored timestamps as postgres (guard-exempt),
-- never by waiting. Every assertion is deterministic regardless of the
-- wall-clock time or local zone the test runs at.
--
-- Coverage:
--   TZ HARDENING (1-4)     write-time validation + safe_user_tz coalesce
--   SEEDS (5)              app_config dials
--   QUEUE RLS/GRANTS (6-9) select-only RLS, no direct DML, anon denied
--   SEED RPC (10-14)       happy path, empty, dup, junk id, reseed refusal
--   UNSEAL RPC (15-19)     per-day idempotency, 20h floor vs tz-hop, order,
--                          exhaustion
--   WEEKLY POOL (20-25)    3-then-block, legit rollover, F1 anchor pin,
--                          monotonic pin, invalid feature
--   GUARD (26-31)          RPC-only columns, freeze-after-completion
--   COHORT (32-33)         handle_new_user server assignment, both arms

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

-- Catalog fixtures: collectible_names is content-seeded in prod (client
-- catalog push), NOT by migrations — a fresh CI database has zero rows, so
-- the FK fixtures the queue tests need are inserted here (rolled back).
insert into public.collectible_names (id, arabic, transliteration, english)
select i, 'اسم', 'Test-Name-' || i, 'Test Name ' || i
from unnest(array[5, 6, 10, 11, 12, 13, 14, 15, 16, 20, 21, 30, 31, 42, 43, 44]) as i
on conflict (id) do nothing;

-- Seed two users under the default ('legacy') cohort config.
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000b01', 'oneship-a@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000b02', 'oneship-b@test.sakina.local');

do $body$
declare
  uid_a constant uuid := '00000000-0000-0000-0000-000000000b01';
  uid_b constant uuid := '00000000-0000-0000-0000-000000000b02';
  uid_c constant uuid := '00000000-0000-0000-0000-000000000b03';
  total int := 0;
  err text;
  raised boolean;
  v_result jsonb;
  v_pos int;
  v_name int;
  v_unsealed timestamptz;
  v_count int;
  v_text text;
  v_int int;
  v_week date;
  v_utc_hour int;
  v_floor_tz text;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- =========================================================================
  -- TZ HARDENING (1-4)
  -- =========================================================================

  -- 1. Invalid timezone string is rejected at write time (trigger, all roles).
  raised := false;
  begin
    update public.user_notification_preferences
      set timezone = 'Not/AZone' where user_id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '1. invalid timezone write raises (validate_notification_timezone)');

  -- 2. Valid IANA zone passes.
  update public.user_notification_preferences
    set timezone = 'Asia/Karachi' where user_id = uid_a;
  perform pg_temp.expect(
    public.safe_user_tz(uid_a) = 'Asia/Karachi',
    '2. safe_user_tz returns the stored valid zone');

  -- 3. Missing prefs row coalesces to UTC.
  perform pg_temp.expect(
    public.safe_user_tz('00000000-0000-0000-0000-00000000dead') = 'UTC',
    '3. safe_user_tz falls back to UTC for unknown user');

  -- 4. Empty string coalesces to UTC (pre-trigger legacy rows).
  update public.user_notification_preferences
    set timezone = '' where user_id = uid_b;
  perform pg_temp.expect(
    public.safe_user_tz(uid_b) = 'UTC',
    '4. safe_user_tz coalesces empty timezone to UTC');

  -- 4b. Non-empty INVALID stored value falls back to UTC — the branch that
  --     justifies safe_user_tz's existence (review P2-4). The trigger now
  --     blocks writing junk, so disable it to plant a pre-trigger legacy row.
  alter table public.user_notification_preferences
    disable trigger validate_notification_timezone;
  update public.user_notification_preferences
    set timezone = 'Not/AZone' where user_id = uid_b;
  alter table public.user_notification_preferences
    enable trigger validate_notification_timezone;
  perform pg_temp.expect(
    public.safe_user_tz(uid_b) = 'UTC',
    '4b. safe_user_tz coalesces a stored INVALID zone to UTC');

  -- 4c. A row holding an invalid legacy value stays UPDATABLE on other
  --     columns (review P2-2: the trigger validates only actual tz changes —
  --     otherwise one poisoned row aborts the notification cron batch).
  raised := false;
  begin
    update public.user_notification_preferences
      set push_enabled = push_enabled where user_id = uid_b;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(not raised,
    '4c. non-timezone UPDATE on an invalid-tz row does not raise');
  update public.user_notification_preferences
    set timezone = 'UTC' where user_id = uid_b;

  -- =========================================================================
  -- APP_CONFIG SEEDS (5) — checked before the cohort test mutates the dial
  -- =========================================================================
  perform pg_temp.expect(
    (select (value::text)::int from public.app_config where key = 'weekly_pool_size') = 3
    and (select (value::text)::int from public.app_config where key = 'warmup_reflect_size') = 3
    and (select (value::text)::int from public.app_config where key = 'warmup_built_dua_size') = 3
    and (select value #>> '{}' from public.app_config where key = 'new_signup_cohort') = 'legacy'
    and (select (value::text)::boolean from public.app_config where key = 'reel_first_onboarding_enabled') = true,
    '5. all five app_config dials seeded with pinned values');

  -- =========================================================================
  -- QUEUE RLS / GRANTS (6-9)
  -- =========================================================================
  perform pg_temp.reset_auth();
  insert into public.user_name_queue (user_id, position, name_id)
    values (uid_b, 1, 42);  -- as postgres: fixture row for RLS checks

  -- 6. A cannot see B's queue; anon sees nothing at all.
  perform pg_temp.set_auth(uid_a);
  select count(*) into v_count from public.user_name_queue where user_id = uid_b;
  perform pg_temp.expect(v_count = 0,
    '6. RLS: user A sees zero rows of B''s queue');
  perform pg_temp.reset_auth();
  execute 'set local role anon';
  select count(*) into v_count from public.user_name_queue;
  perform pg_temp.expect(v_count = 0,
    '6b. RLS: anon sees zero queue rows (policy is to authenticated)');
  perform pg_temp.reset_auth();
  perform pg_temp.set_auth(uid_a);

  -- 7. Direct INSERT as authenticated raises (no insert policy).
  raised := false;
  begin
    insert into public.user_name_queue (user_id, position, name_id)
      values (uid_a, 1, 43);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '7. RLS: direct INSERT into user_name_queue raises');

  -- 8. Direct UPDATE/DELETE as authenticated affect zero rows (B's fixture
  --    row is invisible; and even own rows have no update/delete policy).
  perform pg_temp.reset_auth();
  insert into public.user_name_queue (user_id, position, name_id)
    values (uid_a, 7, 44);  -- fixture in A's own queue, high position
  perform pg_temp.set_auth(uid_a);
  update public.user_name_queue set unsealed_at = now() where user_id = uid_a;
  delete from public.user_name_queue where user_id = uid_a; -- as authenticated
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 0,
    '8a. RLS: direct UPDATE of own queue rows affects zero rows');
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a;
  perform pg_temp.expect(v_count = 1,
    '8b. RLS: direct DELETE of own queue rows affects zero rows');
  delete from public.user_name_queue where user_id = uid_a;  -- clean fixture
  delete from public.user_name_queue where user_id = uid_b;

  -- 9. anon cannot execute the RPCs.
  raised := false;
  begin
    execute 'set local role anon';
    perform public.seed_name_queue(array[1, 2]);
  exception when others then
    raised := true;
  end;
  perform pg_temp.reset_auth();
  perform pg_temp.expect(raised,
    '9a. grants: anon cannot execute seed_name_queue');
  raised := false;
  begin
    execute 'set local role anon';
    perform public.unseal_next_name();
  exception when others then
    raised := true;
  end;
  perform pg_temp.reset_auth();
  perform pg_temp.expect(raised,
    '9b. grants: anon cannot execute unseal_next_name');

  -- =========================================================================
  -- SEED RPC (10-14)
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);

  -- 10. Empty array raises (cardinality coalesce pin).
  raised := false;
  begin
    perform public.seed_name_queue('{}'::int[]);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised, '10. seed with empty array raises');

  -- 11. Duplicate ids raise.
  raised := false;
  begin
    perform public.seed_name_queue(array[5, 5, 6]);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised, '11. seed with duplicate ids raises');

  -- 12. Unknown name_id raises (collectible_names FK).
  raised := false;
  begin
    perform public.seed_name_queue(array[5, 9999]);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised, '12. seed with junk name_id raises (FK)');

  -- 12b. NULL array element raises (count(distinct) drops NULLs → mismatch).
  raised := false;
  begin
    perform public.seed_name_queue(array[5, null, 6]::int[]);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised, '12b. seed with NULL element raises');

  -- 13. Happy path: 7 Names, position 1 born unsealed, 2-7 sealed.
  perform public.seed_name_queue(array[10, 11, 12, 13, 14, 15, 16]);
  select count(*) into v_count from public.user_name_queue where user_id = uid_a;
  perform pg_temp.expect(v_count = 7, '13a. seed inserts 7 rows');
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 1, '13b. exactly one row born unsealed');
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and position = 1 and name_id = 10 and unsealed_at is not null;
  perform pg_temp.expect(v_count = 1,
    '13c. the unsealed row is position 1 with the first submitted id');

  -- 14. Re-seed refused.
  raised := false;
  begin
    perform public.seed_name_queue(array[20, 21]);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised, '14. re-seed raises (queue is set once)');

  -- =========================================================================
  -- UNSEAL RPC (15-19)
  -- =========================================================================

  -- 15. Same-local-day call returns the day's row, unseals nothing new.
  select q.position, q.name_id into v_pos, v_name
    from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 1 and v_name = 10,
    '15a. unseal on signup day returns position 1 (idempotent)');
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 1,
    '15b. no new row unsealed on the signup day');

  -- 16. Next local day (simulated: backdate the last unseal 25h) unseals #2.
  perform pg_temp.reset_auth();
  update public.user_name_queue
    set unsealed_at = now() - interval '25 hours'
    where user_id = uid_a and position = 1;
  perform pg_temp.set_auth(uid_a);
  select q.position, q.name_id into v_pos, v_name
    from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 2 and v_name = 11,
    '16. next local day unseals position 2');

  -- 17. 20h floor, DETERMINISTIC (review P2-6): the floor is only load-
  --     bearing when the local-day idempotency MISSES, so pick a zone whose
  --     local clock just passed midnight (local hour ≈ 0, works at any run
  --     time). The 10h-old unseal is then "yesterday local" — only the
  --     wall-clock floor stands between the caller and position 3.
  perform pg_temp.reset_auth();
  update public.user_name_queue
    set unsealed_at = now() - interval '10 hours'
    where user_id = uid_a and position = 2;
  v_utc_hour := extract(hour from now() at time zone 'UTC')::int;
  v_floor_tz := case when v_utc_hour <= 12
    then 'Etc/GMT+' || v_utc_hour          -- POSIX sign: GMT+N = UTC-N
    else 'Etc/GMT-' || (24 - v_utc_hour)
  end;
  update public.user_notification_preferences
    set timezone = v_floor_tz where user_id = uid_a;
  perform pg_temp.set_auth(uid_a);
  select q.position into v_pos from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 2,
    '17a. yesterday-local + only 10h wall-clock: floor returns the same row');
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 2,
    '17a2. the 20h floor alone blocked the unseal (F3 deterministic pin)');
  perform pg_temp.set_auth(uid_a);

  -- 17b/c. tz-hop attack (review F3): flip to +14 then -12 — still no unseal.
  perform pg_temp.reset_auth();
  update public.user_notification_preferences
    set timezone = 'Pacific/Kiritimati' where user_id = uid_a;
  perform pg_temp.set_auth(uid_a);
  perform public.unseal_next_name();
  perform pg_temp.reset_auth();
  update public.user_notification_preferences
    set timezone = 'Etc/GMT+12' where user_id = uid_a;
  perform pg_temp.set_auth(uid_a);
  perform public.unseal_next_name();
  perform pg_temp.reset_auth();
  select count(*) into v_count from public.user_name_queue
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.expect(v_count = 2,
    '17b. tz-hopping (+14 then -12) within 20h unseals nothing (F3 pin)');
  update public.user_notification_preferences
    set timezone = 'Asia/Karachi' where user_id = uid_a;

  -- 18. Sequential order: after another "day" passes, position 3 comes next.
  update public.user_name_queue
    set unsealed_at = unsealed_at - interval '25 hours'
    where user_id = uid_a and unsealed_at is not null;
  perform pg_temp.set_auth(uid_a);
  select q.position into v_pos from public.unseal_next_name() as q;
  perform pg_temp.expect(v_pos = 3,
    '18. unseal proceeds strictly by position (3 after 1 and 2)');

  -- 19. Exhaustion: user B seeds a 2-Name queue, drains it, then gets empty.
  perform pg_temp.set_auth(uid_b);
  perform public.seed_name_queue(array[30, 31]);
  perform pg_temp.reset_auth();
  update public.user_name_queue
    set unsealed_at = now() - interval '25 hours'
    where user_id = uid_b and position = 1;
  perform pg_temp.set_auth(uid_b);
  perform public.unseal_next_name();  -- unseals position 2
  perform pg_temp.reset_auth();
  update public.user_name_queue
    set unsealed_at = now() - interval '25 hours'
    where user_id = uid_b;
  perform pg_temp.set_auth(uid_b);
  select count(*) into v_count from public.unseal_next_name() as q;
  perform pg_temp.expect(v_count = 0,
    '19. exhausted queue returns empty result');

  -- =========================================================================
  -- WEEKLY POOL (20-25)
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);

  -- 20. Three consumes pass, the fourth blocks.
  v_result := public.consume_weekly_allowance('reflect');
  perform pg_temp.expect((v_result->>'allowed')::boolean
      and (v_result->>'remaining')::int = 2,
    '20a. first consume allowed, remaining 2');
  v_result := public.consume_weekly_allowance('built_dua');
  v_result := public.consume_weekly_allowance('reflect');
  perform pg_temp.expect((v_result->>'allowed')::boolean
      and (v_result->>'remaining')::int = 0,
    '20b. third consume allowed, remaining 0 (pool is combined)');
  v_result := public.consume_weekly_allowance('built_dua');
  perform pg_temp.expect((v_result->>'allowed')::boolean = false,
    '20c. fourth consume blocked');

  -- 21. Legitimate rollover: stored week 7 days back + anchor 7 days back.
  perform pg_temp.reset_auth();
  update public.user_profiles
    set weekly_pool_week_start = weekly_pool_week_start - 7,
        weekly_pool_reset_at   = now() - interval '7 days'
    where id = uid_a;
  perform pg_temp.set_auth(uid_a);
  v_result := public.consume_weekly_allowance('reflect');
  perform pg_temp.expect((v_result->>'allowed')::boolean
      and (v_result->>'remaining')::int = 2,
    '21. a real week later the pool resets (3 fresh, 1 consumed)');

  -- 22. F1 pin — wall-clock anchor: a "later Monday" (tz-manufactured or
  --     otherwise) does NOT reset when the last reset was <6 days ago.
  perform pg_temp.reset_auth();
  update public.user_profiles
    set weekly_pool_week_start = weekly_pool_week_start - 7
    -- weekly_pool_reset_at stays now() (stamped by test 21's reset)
    where id = uid_a;
  perform pg_temp.set_auth(uid_a);
  v_result := public.consume_weekly_allowance('reflect');
  perform pg_temp.expect((v_result->>'remaining')::int = 1,
    '22. later-Monday with fresh anchor does NOT reset (F1 ping-pong pin)');

  -- 23. Monotonic pin: a stored week AHEAD of local (hop-back) never resets.
  --     used is 3 at this point, so a reset would show as allowed=true.
  perform pg_temp.reset_auth();
  update public.user_profiles
    set weekly_pool_used        = 3,
        weekly_pool_week_start  = weekly_pool_week_start + 14,
        weekly_pool_reset_at    = now() - interval '30 days'
    where id = uid_a;
  perform pg_temp.set_auth(uid_a);
  v_result := public.consume_weekly_allowance('reflect');
  perform pg_temp.expect((v_result->>'allowed')::boolean = false,
    '23. hop-back (stored week ahead of local) never resets (monotonic pin)');

  -- 24. Invalid feature raises (discover_name is never pooled).
  raised := false;
  begin
    perform public.consume_weekly_allowance('discover_name');
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '24. consume_weekly_allowance(discover_name) raises');

  -- 25. anon denied.
  raised := false;
  begin
    execute 'set local role anon';
    perform public.consume_weekly_allowance('reflect');
  exception when others then
    raised := true;
  end;
  perform pg_temp.reset_auth();
  perform pg_temp.expect(raised,
    '25. grants: anon cannot execute consume_weekly_allowance');

  -- =========================================================================
  -- GUARD (26-31)
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);

  -- 26. Client cannot touch the pool columns.
  raised := false;
  begin
    update public.user_profiles set weekly_pool_used = 0 where id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '26. guard: client write to weekly_pool_used raises');

  -- 27. Client cannot change the cohort (even legacy→reel_v1).
  raised := false;
  begin
    update public.user_profiles set free_tier_cohort = 'reel_v1' where id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '27a. guard: client write to free_tier_cohort raises (F2 pin)');

  -- 27b. NULL→value is equally blocked (a pre-One-Ship account cannot
  --      self-assign a cohort either direction).
  perform pg_temp.reset_auth();
  update public.user_profiles set free_tier_cohort = null where id = uid_b;
  perform pg_temp.set_auth(uid_b);
  raised := false;
  begin
    update public.user_profiles set free_tier_cohort = 'legacy' where id = uid_b;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '27b. guard: client NULL→value cohort write raises');
  perform pg_temp.set_auth(uid_a);

  -- 27c. INSERT path is guarded too (review P2-3): an authenticated INSERT
  --      asserting server-owned columns raises even where no row exists.
  perform pg_temp.reset_auth();
  perform pg_temp.set_auth(uid_a);
  raised := false;
  begin
    insert into public.user_profiles (id, free_tier_cohort)
      values (uid_a, 'legacy');
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '27c. guard: INSERT asserting free_tier_cohort raises (PK or guard)');

  -- 28. Client cannot stamp the softener column.
  raised := false;
  begin
    update public.user_profiles
      set softener_notice_ends_at = now() where id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '28. guard: client write to softener_notice_ends_at raises');

  -- 29. acquisition_promise is writable during onboarding, re-send passes,
  --     back-nav change passes.
  update public.user_profiles
    set acquisition_promise = '{"contract":"problem","hook_type":"chip"}'::jsonb,
        onboarding_flow = 'reel_v1'
    where id = uid_a;
  update public.user_profiles
    set acquisition_promise = '{"contract":"problem","hook_type":"chip"}'::jsonb
    where id = uid_a;  -- identical re-send (persist #2)
  update public.user_profiles
    set acquisition_promise = '{"contract":"sign","hook_type":"chip"}'::jsonb
    where id = uid_a;  -- back-nav edit pre-completion
  select acquisition_promise->>'contract' into v_text
    from public.user_profiles where id = uid_a;
  perform pg_temp.expect(v_text = 'sign',
    '29. acquisition_promise freely writable until onboarding completes');

  -- 30. Check constraint: payload without `contract` key rejected.
  raised := false;
  begin
    update public.user_profiles
      set acquisition_promise = '{"hook_type":"chip"}'::jsonb where id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '30. acquisition_promise without contract key violates check');

  -- 31. Freeze after completion: once onboarding_completed, changes raise.
  update public.user_profiles set onboarding_completed = true where id = uid_a;
  raised := false;
  begin
    update public.user_profiles
      set acquisition_promise = '{"contract":"problem"}'::jsonb where id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '31a. acquisition_promise frozen after onboarding completion');
  raised := false;
  begin
    update public.user_profiles set onboarding_flow = 'legacy' where id = uid_a;
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '31b. onboarding_flow frozen after onboarding completion');

  -- =========================================================================
  -- COHORT ASSIGNMENT (32-33)
  -- =========================================================================
  perform pg_temp.reset_auth();

  -- 32. Default config ('legacy'): users A/B got legacy cohort, warmup 10/10.
  select free_tier_cohort into v_text from public.user_profiles where id = uid_a;
  select warmup_reflect_remaining into v_int from public.user_profiles where id = uid_a;
  perform pg_temp.expect(v_text = 'legacy' and v_int = 10,
    '32. new_signup_cohort=legacy → cohort legacy, warmups untouched (10)');

  -- 33. Flip the dial to reel_v1: next signup gets cohort + 3/3 at insert.
  update public.app_config set value = '"reel_v1"' where key = 'new_signup_cohort';
  perform pg_temp.test_insert_auth_user(uid_c, 'oneship-c@test.sakina.local');
  perform pg_temp.expect(
    (select free_tier_cohort from public.user_profiles where id = uid_c) = 'reel_v1'
    and (select warmup_reflect_remaining from public.user_profiles where id = uid_c) = 3
    and (select warmup_built_dua_remaining from public.user_profiles where id = uid_c) = 3,
    '33. new_signup_cohort=reel_v1 → cohort + warmups 3/3 stamped AT INSERT (F2 pin)');

  -- =========================================================================
  -- SYNC PAYLOAD (34-35) — Migration D union-body tripwire (review P1/P2-5)
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);
  v_result := public.sync_all_user_data();
  perform pg_temp.expect(
    (v_result->'profile') ? 'acquisition_promise'
    and (v_result->'profile') ? 'first_problem_text'
    and (v_result->'profile') ? 'onboarding_flow'
    and (v_result->'profile') ? 'free_tier_cohort'
    and (v_result->'profile') ? 'weekly_pool_used'
    and (v_result->'profile') ? 'weekly_pool_week_start',
    '34a. sync profile carries all six W1 keys');
  perform pg_temp.expect(
    v_result->'profile'->>'free_tier_cohort' = 'legacy'
    and (v_result->'profile'->>'weekly_pool_used')::int >= 1,
    '34b. sync mirrors the real cohort + pool counter values');
  -- The cosmetics sections are the OTHER half of the union body: if a later
  -- re-emit of sync_all_user_data drops either side (the W1 keys above or
  -- these), this test fails loudly instead of prod/CI silently diverging.
  perform pg_temp.expect(
    (v_result ? 'noor') and (v_result ? 'equipped') and (v_result ? 'cosmetics'),
    '35. sync carries the cosmetics sections (union-body tripwire)');
  perform pg_temp.reset_auth();

  -- =========================================================================
  -- Final tally
  -- =========================================================================
  total := current_setting('test.total', true)::int;
  err := current_setting('test.failed', true);

  if length(err) > 0 then
    raise exception 'ONE SHIP W1 DATA LAYER TEST FAILED (% tests run): %', total, err;
  else
    raise notice 'ALL PASS (% tests)', total;
  end if;
end
$body$;

rollback;
