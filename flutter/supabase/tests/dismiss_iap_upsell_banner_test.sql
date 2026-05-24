-- Regression test for:
--   * 20260525010000_iap_to_sub_upsell_pr5.sql
--
-- Covers the PR 5 server surfaces:
--   1. sync_all_user_data() profile now exposes lifetime_bypasses_purchased
--      and iap_upsell_banner_dismissed_at (PR 5 EXP-3 hydration contract).
--   2. dismiss_iap_upsell_banner() writes the timestamp for the authed user.
--   3. anon cannot execute the dismiss RPC.
--   4. Dismissal is idempotent — second call overwrites the timestamp
--      (resets the 14-day suppression window).
--
-- Pattern matches ai_bypass_rpc_test.sql: single transaction, assertions
-- via pg_temp.expect, rollback at end.
--
--   psql ... -f supabase/tests/dismiss_iap_upsell_banner_test.sql

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

select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000c01',
  'pr5-iap@test.sakina.local'
);

-- Seed a non-zero lifetime so the hydration field shows a real value.
update public.user_profiles
  set lifetime_bypasses_purchased = 7
  where id = '00000000-0000-0000-0000-000000000c01';

do $body$
declare
  uid_a constant uuid := '00000000-0000-0000-0000-000000000c01';
  total int := 0;
  err text;
  v_payload jsonb;
  v_result jsonb;
  v_first_dismissed timestamptz;
  v_second_dismissed timestamptz;
  raised boolean;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- =========================================================================
  -- 1. sync_all_user_data exposes both PR 5 fields
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);
  v_payload := public.sync_all_user_data();

  perform pg_temp.expect(
    v_payload->'profile' ? 'lifetime_bypasses_purchased',
    '1a. profile section includes lifetime_bypasses_purchased key'
  );
  perform pg_temp.expect(
    (v_payload->'profile'->>'lifetime_bypasses_purchased')::int = 7,
    '1b. lifetime_bypasses_purchased reflects the seeded value'
  );
  perform pg_temp.expect(
    v_payload->'profile' ? 'iap_upsell_banner_dismissed_at',
    '1c. profile section includes iap_upsell_banner_dismissed_at key'
  );
  perform pg_temp.expect(
    v_payload->'profile'->>'iap_upsell_banner_dismissed_at' is null,
    '1d. iap_upsell_banner_dismissed_at is null before dismissal'
  );

  -- =========================================================================
  -- 2. dismiss_iap_upsell_banner writes the timestamp
  -- =========================================================================
  v_result := public.dismiss_iap_upsell_banner();
  perform pg_temp.expect(
    (v_result->>'ok')::boolean = true,
    '2a. dismiss returns ok=true'
  );
  perform pg_temp.expect(
    (v_result->>'dismissed_at') is not null,
    '2b. dismiss returns the new timestamp'
  );
  v_first_dismissed := (v_result->>'dismissed_at')::timestamptz;

  -- Verify the column was actually written and surfaces through sync.
  v_payload := public.sync_all_user_data();
  perform pg_temp.expect(
    v_payload->'profile'->>'iap_upsell_banner_dismissed_at' is not null,
    '2c. sync now reflects the dismissed_at timestamp'
  );

  -- =========================================================================
  -- 3. Idempotent re-dismissal succeeds (across HTTP calls / separate
  --    transactions, now() advances and overwrites — that's the production
  --    behavior used to reset the 14-day suppression window. Within a single
  --    test transaction now() is frozen, so we only assert the second call
  --    still succeeds and returns a non-null timestamp.)
  -- =========================================================================
  v_result := public.dismiss_iap_upsell_banner();
  v_second_dismissed := (v_result->>'dismissed_at')::timestamptz;
  perform pg_temp.expect(
    (v_result->>'ok')::boolean = true,
    '3a. second dismissal still returns ok=true (idempotent)'
  );
  perform pg_temp.expect(
    v_second_dismissed is not null,
    '3b. second dismissal still returns a non-null timestamp'
  );

  -- =========================================================================
  -- 4. anon cannot execute dismiss_iap_upsell_banner
  -- =========================================================================
  perform pg_temp.reset_auth();
  execute 'set local role anon';

  raised := false;
  begin
    perform public.dismiss_iap_upsell_banner();
  exception when insufficient_privilege then
    raised := true;
  when others then
    raised := sqlerrm like '%permission denied%';
  end;

  perform pg_temp.expect(
    raised,
    '4a. anon role cannot execute dismiss_iap_upsell_banner'
  );

  perform pg_temp.reset_auth();

  -- =========================================================================
  -- Report
  -- =========================================================================
  total := current_setting('test.total', true)::int;
  err := current_setting('test.failed', true);
  if err <> '' then
    raise exception 'FAILED (% of % checks failed): %',
      (length(err) - length(replace(err, '|', ''))), total, err;
  else
    raise notice 'PASSED: % of % checks', total, total;
  end if;
end $body$;

rollback;
