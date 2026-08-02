-- Regression tests for §16 (Backend RPCs) and §17 (RLS) — runnable via
-- mcp__supabase__execute_sql (no supabase CLI / no pgTAP required).
--
-- Pattern: one transaction. Setup → assertions inside a single DO block
-- collecting failures into an array → raise exception if non-empty → rollback
-- so no state persists. Stdout shows either "ALL PASS (N tests)" or
-- "FAILURES: ..." in the error.
--
-- Coverage:
--   §16.1 sync_all_user_data() — payload key contract + auth gate
--   §16.2 delete_own_account() — FK CASCADE wipes scoped tables
--   §16.3 grant_premium_monthly() — premium grant, monthly idempotency,
--          non-premium reject, auth gate
--   §17.1 public catalog anon read — 5 catalog tables
--   §17.2 cross-user RLS — user A cannot see user B's rows
--   §17.3 RLS audit — every scoped table has RLS on with at least one policy
--
-- Run via:
--   mcp__supabase__execute_sql query=$(cat supabase/checks/backend_rls_audit.sql)
-- or paste inline. The whole script is one statement-level batch.

begin;

-- expect(cond, name): records each assertion. `pg_temp.*` lives until rollback.
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

-- Local helper: same shape as the one in rpc_eligibility_test.sql.
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

-- Test users (UUIDs fixed but namespaced; rollback at end ensures clean exit).
select pg_temp.test_insert_auth_user('00000000-0000-0000-0000-000000000201', 'rls-a@test.sakina.local');
select pg_temp.test_insert_auth_user('00000000-0000-0000-0000-000000000202', 'rls-b@test.sakina.local');
select pg_temp.test_insert_auth_user('00000000-0000-0000-0000-000000000203', 'rls-del@test.sakina.local');

-- Forge premium for user B.
insert into public.user_subscriptions (
  user_id, entitlement, product_id,
  expires_at, last_event_type, last_event_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000202', 'premium', 'sakina_sub_annual',
  now() + interval '30 days', 'INITIAL_PURCHASE', now(), now()
);

-- Cascade-canary rows on user_del.
insert into public.user_reflections (user_id, user_text, name, name_arabic, saved_at)
values ('00000000-0000-0000-0000-000000000203', 'cascade-canary', 'Ar-Rahman', 'الرحمن', now());
insert into public.user_built_duas (user_id, need, arabic, transliteration, translation, saved_at)
values ('00000000-0000-0000-0000-000000000203', 'cascade', 'x', 'x', 'x', now());
insert into public.user_checkin_history (user_id, q1, q2, q3, q4, name_returned, name_arabic, checked_in_at)
values ('00000000-0000-0000-0000-000000000203', 'feel', '', '', '', 'Ar-Rahman', 'الرحمن', now());

-- Canary on user A for §17.2.
insert into public.user_reflections (user_id, user_text, name, name_arabic, saved_at)
values ('00000000-0000-0000-0000-000000000201', 'rls-canary', 'Ar-Rahman', 'الرحمن', now());

do $body$
declare
  uid_a constant uuid := '00000000-0000-0000-0000-000000000201';
  uid_b constant uuid := '00000000-0000-0000-0000-000000000202';
  uid_d constant uuid := '00000000-0000-0000-0000-000000000203';
  failures text[] := array[]::text[];
  total int := 0;
  payload jsonb;
  reflections_n int;
  user_b_balance_before int;
  user_b_balance_after int;
  scrolls_after int;
  last_grant text;
  err text;
  scoped_tables text[] := array[
    'user_profiles','user_streaks','user_xp','user_tokens','user_daily_rewards',
    'user_notification_preferences','user_reflections','user_built_duas',
    'user_checkin_history','user_card_collection','user_subscriptions',
    'user_achievements','user_discovery_results','user_quest_progress',
    'user_activity_log','user_daily_usage','user_daily_answers','reflect_classifier_log'
  ];
  t text;
  rls_off text[] := array[]::text[];
  no_policy text[] := array[]::text[];
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- =========================================================================
  -- §16.1 sync_all_user_data()
  -- =========================================================================

  -- Impersonate user A.
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid_a::text, 'role', 'authenticated')::text, true);

  payload := public.sync_all_user_data();

  perform pg_temp.expect(jsonb_typeof(payload) = 'object',
    '§16.1 sync_all_user_data returns a jsonb object');

  -- Exact key contract: 11 documented keys, no extras.
  perform pg_temp.expect(
    (select array_agg(k order by k) from jsonb_object_keys(payload) k)
      = array['achievements','built_duas','card_collection','checkin_history',
              'daily_rewards','discovery_results','profile','reflections',
              'streak','tokens','xp']::text[],
    '§16.1 payload has exactly the documented 11 keys');

  perform pg_temp.expect(jsonb_typeof(payload->'xp')             = 'object', '§16.1 xp is object');
  perform pg_temp.expect(jsonb_typeof(payload->'tokens')         = 'object', '§16.1 tokens is object');
  perform pg_temp.expect(jsonb_typeof(payload->'streak')         = 'object', '§16.1 streak is object');
  perform pg_temp.expect(jsonb_typeof(payload->'daily_rewards')  = 'object', '§16.1 daily_rewards is object');
  perform pg_temp.expect(jsonb_typeof(payload->'profile')        = 'object', '§16.1 profile is object');

  perform pg_temp.expect(jsonb_typeof(payload->'reflections')      = 'array', '§16.1 reflections is array');
  perform pg_temp.expect(jsonb_typeof(payload->'built_duas')       = 'array', '§16.1 built_duas is array');
  perform pg_temp.expect(jsonb_typeof(payload->'card_collection')  = 'array', '§16.1 card_collection is array');
  perform pg_temp.expect(jsonb_typeof(payload->'achievements')     = 'array', '§16.1 achievements is array');
  perform pg_temp.expect(jsonb_typeof(payload->'checkin_history')  = 'array', '§16.1 checkin_history is array');

  reflections_n := jsonb_array_length(payload->'reflections');
  perform pg_temp.expect(reflections_n =
    (select count(*)::int from public.user_reflections where user_id = uid_a),
    '§16.1 reflections length matches direct user_reflections count');

  -- Drop impersonation.
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  -- §16.1 unauthenticated case: must raise P0001 'Not authenticated'.
  begin
    payload := public.sync_all_user_data();
    perform pg_temp.expect(false,
      '§16.1 unauthenticated should raise but returned a payload');
  exception when sqlstate 'P0001' then
    err := SQLERRM;
    perform pg_temp.expect(err = 'Not authenticated',
      '§16.1 raises Not authenticated when auth.uid() is null');
  end;

  -- =========================================================================
  -- §16.3 grant_premium_monthly() — run BEFORE §16.2 (delete destroys user_d)
  -- =========================================================================

  select balance into user_b_balance_before
  from public.user_tokens where user_id = uid_b;

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid_b::text, 'role', 'authenticated')::text, true);

  -- First call this month grants.
  payload := public.grant_premium_monthly();
  perform pg_temp.expect((payload->>'granted')::boolean = true,
    '§16.3 first call this month grants for premium user');
  perform pg_temp.expect((payload->>'tokens_granted')::int = 50,
    '§16.3 first call grants exactly 50 tokens');
  perform pg_temp.expect((payload->>'scrolls_granted')::int = 15,
    '§16.3 first call grants exactly 15 scrolls');

  -- Second call same month no-ops.
  payload := public.grant_premium_monthly();
  perform pg_temp.expect((payload->>'granted')::boolean = false,
    '§16.3 second call same month does not grant (idempotent)');
  perform pg_temp.expect((payload->>'tokens_granted')::int = 0,
    '§16.3 second call grants zero tokens');

  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  -- Tokens delta = +50 exactly, scrolls now = 15 exactly.
  select balance, tier_up_scrolls
  into user_b_balance_after, scrolls_after
  from public.user_tokens where user_id = uid_b;

  perform pg_temp.expect(user_b_balance_after - user_b_balance_before = 50,
    '§16.3 tokens balance increased by exactly 50');
  perform pg_temp.expect(scrolls_after = 15,
    '§16.3 tier_up_scrolls is exactly 15');

  select last_premium_grant_month into last_grant
  from public.user_daily_rewards where user_id = uid_b;
  perform pg_temp.expect(last_grant = to_char(date_trunc('month', timezone('utc', now())), 'YYYY-MM'),
    '§16.3 last_premium_grant_month set to current YYYY-MM');

  -- Non-premium caller rejected.
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid_a::text, 'role', 'authenticated')::text, true);
  payload := public.grant_premium_monthly();
  perform pg_temp.expect((payload->>'granted')::boolean = false,
    '§16.3 non-premium caller does not grant');
  perform pg_temp.expect(payload->>'reason' = 'not_premium',
    '§16.3 non-premium caller reason=not_premium');
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  -- Unauthenticated raises.
  begin
    payload := public.grant_premium_monthly();
    perform pg_temp.expect(false,
      '§16.3 unauthenticated should raise but returned a payload');
  exception when sqlstate 'P0001' then
    err := SQLERRM;
    perform pg_temp.expect(err = 'Not authenticated',
      '§16.3 raises Not authenticated when auth.uid() is null');
  end;

  -- =========================================================================
  -- §16.2 delete_own_account() — destroys user_del + cascades
  -- =========================================================================

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid_d::text, 'role', 'authenticated')::text, true);
  perform public.delete_own_account();
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  perform pg_temp.expect((select count(*) from auth.users                where id      = uid_d) = 0, '§16.2 auth.users gone');
  perform pg_temp.expect((select count(*) from public.user_profiles      where id      = uid_d) = 0, '§16.2 user_profiles cascaded');
  perform pg_temp.expect((select count(*) from public.user_reflections   where user_id = uid_d) = 0, '§16.2 user_reflections cascaded');
  perform pg_temp.expect((select count(*) from public.user_built_duas    where user_id = uid_d) = 0, '§16.2 user_built_duas cascaded');
  perform pg_temp.expect((select count(*) from public.user_checkin_history where user_id = uid_d) = 0, '§16.2 user_checkin_history cascaded');
  perform pg_temp.expect((select count(*) from public.user_tokens        where user_id = uid_d) = 0, '§16.2 user_tokens cascaded');
  perform pg_temp.expect((select count(*) from public.user_xp            where user_id = uid_d) = 0, '§16.2 user_xp cascaded');
  perform pg_temp.expect((select count(*) from public.user_streaks       where user_id = uid_d) = 0, '§16.2 user_streaks cascaded');
  perform pg_temp.expect((select count(*) from public.user_daily_rewards where user_id = uid_d) = 0, '§16.2 user_daily_rewards cascaded');
  perform pg_temp.expect((select count(*) from public.user_notification_preferences where user_id = uid_d) = 0, '§16.2 user_notification_preferences cascaded');

  -- =========================================================================
  -- §17.1 public catalog anon read
  -- =========================================================================

  execute 'set local role anon';
  perform pg_temp.expect((select count(*) from public.daily_questions) > 0,         '§17.1 daily_questions anon-readable');
  perform pg_temp.expect((select count(*) from public.browse_duas) > 0,             '§17.1 browse_duas anon-readable');
  perform pg_temp.expect((select count(*) from public.discovery_quiz_questions) > 0,'§17.1 discovery_quiz_questions anon-readable');
  perform pg_temp.expect((select count(*) from public.name_anchors) > 0,            '§17.1 name_anchors anon-readable');
  perform pg_temp.expect((select count(*) from public.collectible_names) > 0,       '§17.1 collectible_names anon-readable');
  execute 'reset role';

  -- =========================================================================
  -- §17.2 cross-user RLS isolation
  -- =========================================================================

  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid_b::text, 'role', 'authenticated')::text, true);
  perform pg_temp.expect((select count(*) from public.user_reflections where user_id = uid_a) = 0,
    '§17.2 user B reads zero of user A user_reflections');
  perform pg_temp.expect((select count(*) from public.user_tokens where user_id = uid_a) = 0,
    '§17.2 user B reads zero of user A user_tokens');
  perform pg_temp.expect((select count(*) from public.user_profiles where id = uid_a) = 0,
    '§17.2 user B reads zero of user A user_profiles');
  perform pg_temp.expect((select count(*) from public.user_streaks where user_id = uid_a) = 0,
    '§17.2 user B reads zero of user A user_streaks');
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  -- Positive sanity: user A can read own canary.
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', uid_a::text, 'role', 'authenticated')::text, true);
  perform pg_temp.expect((select count(*) from public.user_reflections where user_id = uid_a) >= 1,
    '§17.2 user A reads own canary (RLS not over-blocking)');
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);

  -- =========================================================================
  -- §16.4 webhook upsert: INITIAL → CANCEL → EXPIRE preserves canceled_at.
  -- Regression for the 2026-04-26 P3 (fixed in
  -- 20260426000000_preserve_canceled_at_on_absent_key.sql). Calls the RPC
  -- directly with payloads matching what handler.ts emits; uses a fresh UID.
  -- =========================================================================
  declare
    rc_uid uuid := '00000000-0000-0000-0000-000000000301';
    rc_t1 bigint := (extract(epoch from now())*1000)::bigint;
    rc_t2 bigint;
    rc_t3 bigint;
    rc_exp_future text;
    rc_exp_past text;
    rc_ts1 text; rc_ts2 text; rc_ts3 text;
    cancel_after_b timestamptz;
    cancel_after_c timestamptz;
    cancel_after_d timestamptz;
    rc_ret jsonb;
  begin
    rc_t2 := rc_t1 + 1000;
    rc_t3 := rc_t2 + 1000;
    rc_exp_future := to_char(now() + interval '30 days', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
    rc_exp_past   := to_char(now() - interval '1 minute',  'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
    rc_ts1 := to_char(to_timestamp(rc_t1/1000.0) at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
    rc_ts2 := to_char(to_timestamp(rc_t2/1000.0) at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
    rc_ts3 := to_char(to_timestamp(rc_t3/1000.0) at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');

    perform pg_temp.test_insert_auth_user(rc_uid, 'rc-cancel@test.sakina.local');

    -- (b) INITIAL_PURCHASE — handler nulls canceled_at explicitly (active lifecycle).
    select public.upsert_user_subscription_if_newer(jsonb_build_object(
      'user_id', rc_uid::text, 'entitlement', 'premium', 'product_id', 'test.sku.annual',
      'store', 'APP_STORE', 'environment', 'SANDBOX',
      'revenuecat_app_user_id', rc_uid::text, 'revenuecat_original_app_user_id', rc_uid::text,
      'aliases', '[]'::jsonb,
      'expires_at', rc_exp_future, 'canceled_at', null, 'billing_issue_detected_at', null,
      'last_event_type', 'INITIAL_PURCHASE', 'last_event_at', rc_ts1, 'updated_at', rc_ts1
    )) into rc_ret;
    select canceled_at into cancel_after_b from public.user_subscriptions where user_id=rc_uid;
    perform pg_temp.expect(cancel_after_b is null, '§16.4 INITIAL_PURCHASE nulls canceled_at');
    perform pg_temp.expect((rc_ret->>'written')::bool, '§16.4 INITIAL_PURCHASE writes the row');
    perform pg_temp.expect(not (rc_ret->>'cancellation_started')::bool,
      '§16.4 INITIAL_PURCHASE does not report a cancellation');

    -- (c) CANCELLATION — sets canceled_at; omits billing_issue_detected_at.
    -- The null->set transition must report cancellation_started=true (fires the
    -- survey push exactly once). This is the load-bearing invariant of the RPC.
    select public.upsert_user_subscription_if_newer(jsonb_build_object(
      'user_id', rc_uid::text, 'entitlement', 'premium', 'product_id', 'test.sku.annual',
      'store', 'APP_STORE', 'environment', 'SANDBOX',
      'revenuecat_app_user_id', rc_uid::text, 'revenuecat_original_app_user_id', rc_uid::text,
      'aliases', '[]'::jsonb,
      'expires_at', rc_exp_future, 'canceled_at', rc_ts2,
      'last_event_type', 'CANCELLATION', 'last_event_at', rc_ts2, 'updated_at', rc_ts2
    )) into rc_ret;
    select canceled_at into cancel_after_c from public.user_subscriptions where user_id=rc_uid;
    perform pg_temp.expect(cancel_after_c is not null, '§16.4 CANCELLATION sets canceled_at');
    perform pg_temp.expect((rc_ret->>'cancellation_started')::bool,
      '§16.4 first CANCELLATION reports cancellation_started=true (null->set)');

    -- (c2) CANCELLATION redelivery (set->set) — already cancelled, so the push
    -- must NOT fire again. >= freshness re-writes the row, but old_canceled_at
    -- is non-null so cancellation_started is false.
    select public.upsert_user_subscription_if_newer(jsonb_build_object(
      'user_id', rc_uid::text, 'entitlement', 'premium', 'product_id', 'test.sku.annual',
      'store', 'APP_STORE', 'environment', 'SANDBOX',
      'revenuecat_app_user_id', rc_uid::text, 'revenuecat_original_app_user_id', rc_uid::text,
      'aliases', '[]'::jsonb,
      'expires_at', rc_exp_future, 'canceled_at', rc_ts2,
      'last_event_type', 'CANCELLATION', 'last_event_at', rc_ts2, 'updated_at', rc_ts2
    )) into rc_ret;
    perform pg_temp.expect(not (rc_ret->>'cancellation_started')::bool,
      '§16.4 CANCELLATION redelivery (set->set) does not re-report cancellation_started');

    -- (d) EXPIRATION — handler OMITS canceled_at + billing_issue_detected_at.
    -- Pre-fix: clobbered canceled_at to null. Post-fix: preserved.
    select public.upsert_user_subscription_if_newer(jsonb_build_object(
      'user_id', rc_uid::text, 'entitlement', 'premium', 'product_id', 'test.sku.annual',
      'store', 'APP_STORE', 'environment', 'SANDBOX',
      'revenuecat_app_user_id', rc_uid::text, 'revenuecat_original_app_user_id', rc_uid::text,
      'aliases', '[]'::jsonb,
      'expires_at', rc_exp_past,
      'last_event_type', 'EXPIRATION', 'last_event_at', rc_ts3, 'updated_at', rc_ts3
    )) into rc_ret;
    perform pg_temp.expect(not (rc_ret->>'cancellation_started')::bool,
      '§16.4 EXPIRATION (omitted canceled_at) does not report cancellation_started');
    select canceled_at into cancel_after_d from public.user_subscriptions where user_id=rc_uid;
    perform pg_temp.expect(cancel_after_d is not null and cancel_after_d = cancel_after_c,
      '§16.4 EXPIRATION preserves canceled_at from prior CANCELLATION');
    perform pg_temp.expect(not public.has_active_premium_entitlement(rc_uid),
      '§16.4 has_active_premium_entitlement is false after EXPIRATION');
  end;

  -- =========================================================================
  -- §17.3 RLS audit — every scoped table has RLS on + at least one policy.
  -- =========================================================================

  foreach t in array scoped_tables loop
    if not exists (
      select 1 from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = t and c.relrowsecurity = true
    ) then
      rls_off := rls_off || t;
    end if;
    if (select count(*) from pg_policies where schemaname='public' and tablename=t) = 0 then
      no_policy := no_policy || t;
    end if;
  end loop;
  perform pg_temp.expect(coalesce(array_length(rls_off, 1), 0) = 0,
    '§17.3 every scoped table has RLS enabled (offenders: '
      || coalesce(array_to_string(rls_off, ','), '') || ')');
  perform pg_temp.expect(coalesce(array_length(no_policy, 1), 0) = 0,
    '§17.3 every scoped table has at least one policy (missing: '
      || coalesce(array_to_string(no_policy, ','), '') || ')');

  -- =========================================================================
  -- Final tally
  -- =========================================================================

  total := current_setting('test.total', true)::int;
  err := current_setting('test.failed', true);

  if length(err) > 0 then
    raise exception 'BACKEND/RLS REGRESSION FAILED (% tests run): %', total, err;
  else
    raise notice 'ALL PASS (% tests)', total;
  end if;
end
$body$;

rollback;
