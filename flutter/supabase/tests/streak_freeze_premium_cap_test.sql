-- Verifies the streak-freeze premium differentiator
-- (20260722000000_streak_freeze_premium_tier.sql):
--   * free users cap their freeze HOLD at 1,
--   * premium users accumulate up to 3 via the day-4 grant,
--   * grant_premium_monthly tops a premium holder up to the cap,
--   * consume_streak_freeze decrements one at a time,
--   * a downgraded premium holder's surplus is never reduced by a free grant.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/streak_freeze_premium_cap_test.sql

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

create or replace function pg_temp.test_insert_auth_user(p_id uuid, p_email text)
returns void language sql as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  ) values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id, 'authenticated', 'authenticated', p_email, '',
    now(), '{"provider":"email","providers":["email"]}'::jsonb,
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

-- Force the next claim_daily_reward() to land on day 4 (the freeze day):
-- current_day = 3 with last_claim = yesterday advances to day 4.
create or replace function pg_temp.arm_day4(p_uid uuid) returns void
language sql as $$
  update public.user_daily_rewards
    set current_day = 3,
        last_claim_date = timezone('utc', now())::date - 1
    where user_id = p_uid;
$$;

select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-0000000f2eee',
  'freeze-cap-test@test.sakina.local'
);

do $body$
declare
  uid constant uuid := '00000000-0000-0000-0000-0000000f2eee';
  v jsonb;
  v_count int;
begin
  insert into public.user_daily_rewards (user_id) values (uid)
    on conflict (user_id) do nothing;
  insert into public.user_tokens (user_id) values (uid)
    on conflict (user_id) do nothing;

  perform pg_temp.set_auth(uid);

  -- =========================================================================
  -- 1. FREE user caps the freeze HOLD at 1
  -- =========================================================================
  update public.user_daily_rewards
    set streak_freeze_count = 0, streak_freeze_owned = false where user_id = uid;

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'earned_streak_freeze') = 'true',
    '1a. free day-4 grants a freeze');
  perform pg_temp.expect((v->>'streak_freeze_count') = '1',
    '1b. free freeze count = 1');

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'earned_streak_freeze') = 'false',
    '1c. free day-4 at cap earns nothing more');
  perform pg_temp.expect((v->>'streak_freeze_count') = '1',
    '1d. free freeze count stays capped at 1');

  -- =========================================================================
  -- 2. PREMIUM user accumulates up to 3
  -- =========================================================================
  insert into public.user_subscriptions
    (user_id, entitlement, product_id, expires_at, last_event_type, last_event_at)
    values (uid, 'premium', 'test_premium_freeze', now() + interval '30 days',
            'INITIAL_PURCHASE', now())
    on conflict (user_id, entitlement) do update set
      expires_at = now() + interval '30 days';
  perform pg_temp.expect(public.has_active_premium_entitlement(uid),
    '2pre. server sees premium');

  update public.user_daily_rewards
    set streak_freeze_count = 0, streak_freeze_owned = false where user_id = uid;

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'streak_freeze_count') = '1', '2a. premium → 1');

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'streak_freeze_count') = '2', '2b. premium → 2');

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'streak_freeze_count') = '3', '2c. premium → 3');

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'earned_streak_freeze') = 'false',
    '2d. premium day-4 at cap earns nothing more');
  perform pg_temp.expect((v->>'streak_freeze_count') = '3',
    '2e. premium freeze count caps at 3');

  -- =========================================================================
  -- 3. grant_premium_monthly tops a premium holder up to the cap
  -- =========================================================================
  update public.user_daily_rewards
    set streak_freeze_count = 1, streak_freeze_owned = true,
        last_premium_grant_month = null
    where user_id = uid;

  v := public.grant_premium_monthly();
  perform pg_temp.expect((v->>'granted') = 'true', '3a. monthly grant applied');
  perform pg_temp.expect((v->>'streak_freeze_count') = '3',
    '3b. monthly grant tops freeze buffer to premium cap');

  -- =========================================================================
  -- 4. consume_streak_freeze decrements one at a time
  -- =========================================================================
  update public.user_daily_rewards
    set streak_freeze_count = 3, streak_freeze_owned = true where user_id = uid;
  perform pg_temp.expect(public.consume_streak_freeze(), '4a. consume returns true');
  select streak_freeze_count into v_count
    from public.user_daily_rewards where user_id = uid;
  perform pg_temp.expect(v_count = 2, '4b. consume decrements 3 → 2');

  -- =========================================================================
  -- 5. Downgrade preserves a premium surplus (free grant never reduces it).
  --    Seed count=3 and revoke premium as the OWNER (reset_auth) so the seed
  --    itself isn't blocked by the new freeze guard.
  -- =========================================================================
  perform pg_temp.reset_auth();
  update public.user_daily_rewards
    set streak_freeze_count = 3, streak_freeze_owned = true where user_id = uid;
  delete from public.user_subscriptions where user_id = uid;
  perform pg_temp.set_auth(uid);
  perform pg_temp.expect(not public.has_active_premium_entitlement(uid),
    '5pre. premium revoked');

  perform pg_temp.arm_day4(uid);
  v := public.claim_daily_reward();
  perform pg_temp.expect((v->>'streak_freeze_count') = '3',
    '5. downgraded holder of 3 is not reduced by a free day-4');
  perform pg_temp.expect((v->>'earned_streak_freeze') = 'false',
    '5b. no freeze earned above the free cap');

  -- =========================================================================
  -- 6. Freemium guard blocks a direct client write above the tier cap
  --    (the RLS UPDATE policy has no WITH CHECK — the guard is the backstop).
  --    User is currently non-premium (cap 1); start from a clean 0 so the
  --    write is a genuine INCREASE.
  -- =========================================================================
  perform pg_temp.reset_auth();
  update public.user_daily_rewards
    set streak_freeze_count = 0, streak_freeze_owned = false where user_id = uid;
  perform pg_temp.set_auth(uid);
  begin
    update public.user_daily_rewards
      set streak_freeze_count = 99 where user_id = uid;
    perform pg_temp.expect(false,
      '6. direct over-cap client write should raise (guard failed to fire)');
  exception when others then
    perform pg_temp.expect(true, '6. guard blocked over-cap direct client write');
  end;
  select streak_freeze_count into v_count
    from public.user_daily_rewards where user_id = uid;
  perform pg_temp.expect(v_count = 0, '6b. count unchanged after blocked write');

  -- Tally
  perform pg_temp.reset_auth();
  if length(coalesce(current_setting('test.failed', true), '')) > 0 then
    raise exception 'STREAK FREEZE PREMIUM CAP TEST FAILED (% run): %',
      current_setting('test.total', true), current_setting('test.failed', true);
  else
    raise notice 'ALL PASS (% tests)', current_setting('test.total', true);
  end if;
end
$body$;

rollback;
