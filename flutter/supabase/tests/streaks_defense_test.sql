-- Regression test for 20260719000000_streaks_defense.sql
--
-- Covers repair_streak_paid (atomicity, server-priced tiers, window,
-- rate-limit, premium-free meter, RLS) and add_excused_date (cap, dedup, RLS).
-- Pattern matches ai_bypass_rpc_test.sql: one txn, DO-block assertions, rollback.
--
--   psql ... -f supabase/tests/streaks_defense_test.sql
--
-- Coverage:
--   repair_streak_paid (1-11)
--     1.  paid happy path: 30-day pre-lapse → 250 tokens, restores 31, clears lapse
--     2.  tier price: 7-29 → 100 tokens
--     3.  tier price: 90+ → 500 tokens
--     4.  refused when pre_lapse_streak < 7
--     5.  refused when pre_lapse_streak <= current (nothing to restore)
--     6.  refused when buy-back window passed (> 30d since lapse)
--     7.  insufficient tokens → raises, NO debit, NO restore (atomicity)
--     8.  rate-limit: second paid within 30d rejected
--     9.  premium-free path: no debit, restores, meters premium_free_repair_at
--    10.  premium-free metered: second within 30d falls back to paid charge
--    11.  longest_streak never decreases; = greatest(old, restored)
--   add_excused_date (12-14)
--    12.  happy path inserts, returns count_in_window
--    13.  cap enforced at 8 per rolling 30d (9th rejected)
--    14.  duplicate date is idempotent (no error)
--   RLS / grants (15-16)
--    15.  anon cannot execute repair_streak_paid
--    16.  user sees only own excused dates

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

-- Seed two users.
select pg_temp.test_insert_auth_user('00000000-0000-0000-0000-0000000005a1', 'streak-a@test.sakina.local');
select pg_temp.test_insert_auth_user('00000000-0000-0000-0000-0000000005a2', 'streak-b@test.sakina.local');

update public.user_tokens set balance = 1000, total_spent = 0
  where user_id in ('00000000-0000-0000-0000-0000000005a1'::uuid,
                    '00000000-0000-0000-0000-0000000005a2'::uuid);

do $body$
declare
  uid_a constant uuid := '00000000-0000-0000-0000-0000000005a1';
  uid_b constant uuid := '00000000-0000-0000-0000-0000000005a2';
  v_result jsonb;
  v_balance int;
  v_cur int;
  v_longest int;
  v_pre int;
  v_cnt int;
  err text;
begin
  -- Helper to (re)seed an EXPIRED streak state for uid_a.
  -- pre_lapse=<pre>, current=<cur>, lapsed_at=<days_ago> days ago.
  -- Inline via updates below.

  perform pg_temp.set_auth(uid_a);

  -- =========================================================================
  -- 1. Paid happy path (pre_lapse 30, current 1, lapsed 10d ago) → 250, →31
  -- =========================================================================
  insert into public.user_streaks (user_id, current_streak, longest_streak, last_active, pre_lapse_streak, lapsed_at)
    values (uid_a, 1, 30, timezone('utc', now())::date, 30, now() - interval '10 days')
    on conflict (user_id) do update set
      current_streak = 1, longest_streak = 30, pre_lapse_streak = 30,
      lapsed_at = now() - interval '10 days', last_paid_repair_at = null,
      premium_free_repair_at = null;
  update public.user_tokens set balance = 1000, total_spent = 0 where user_id = uid_a;

  v_result := public.repair_streak_paid();
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  select current_streak, longest_streak, pre_lapse_streak into v_cur, v_longest, v_pre
    from public.user_streaks where user_id = uid_a;
  perform pg_temp.expect((v_result->>'method') = 'paid', '1a. method=paid');
  perform pg_temp.expect((v_result->>'cost')::int = 250, '1b. cost=250 for 30-day band');
  perform pg_temp.expect(v_balance = 750, '1c. debited 250 tokens (1000→750)');
  perform pg_temp.expect(v_cur = 31, '1d. restored current = pre_lapse(30) + current(1)');
  perform pg_temp.expect(v_pre is null, '1e. pre_lapse cleared after repair');

  -- =========================================================================
  -- 2. Tier price 7-29 → 100
  -- =========================================================================
  update public.user_streaks set current_streak = 1, longest_streak = 15,
    pre_lapse_streak = 15, lapsed_at = now() - interval '5 days',
    last_paid_repair_at = null where user_id = uid_a;
  update public.user_tokens set balance = 1000 where user_id = uid_a;
  v_result := public.repair_streak_paid();
  perform pg_temp.expect((v_result->>'cost')::int = 100, '2. cost=100 for 7-29 band');

  -- =========================================================================
  -- 3. Tier price 90+ → 500
  -- =========================================================================
  update public.user_streaks set current_streak = 1, longest_streak = 120,
    pre_lapse_streak = 120, lapsed_at = now() - interval '3 days',
    last_paid_repair_at = null where user_id = uid_a;
  update public.user_tokens set balance = 1000 where user_id = uid_a;
  v_result := public.repair_streak_paid();
  perform pg_temp.expect((v_result->>'cost')::int = 500, '3. cost=500 for 90+ band');

  -- =========================================================================
  -- 4. Refused when pre_lapse < 7
  -- =========================================================================
  update public.user_streaks set current_streak = 1, pre_lapse_streak = 5,
    lapsed_at = now() - interval '2 days', last_paid_repair_at = null where user_id = uid_a;
  begin
    v_result := public.repair_streak_paid();
    perform pg_temp.expect(false, '4. pre_lapse<7 should raise');
  exception when others then
    perform pg_temp.expect(true, '4. pre_lapse<7 refused');
  end;

  -- =========================================================================
  -- 5. Refused when pre_lapse <= current (nothing to restore)
  -- =========================================================================
  update public.user_streaks set current_streak = 40, pre_lapse_streak = 30,
    lapsed_at = now() - interval '2 days', last_paid_repair_at = null where user_id = uid_a;
  begin
    v_result := public.repair_streak_paid();
    perform pg_temp.expect(false, '5. pre_lapse<=current should raise');
  exception when others then
    perform pg_temp.expect(true, '5. nothing-to-restore refused');
  end;

  -- =========================================================================
  -- 6. Refused when buy-back window passed (>30d)
  -- =========================================================================
  update public.user_streaks set current_streak = 1, pre_lapse_streak = 30,
    lapsed_at = now() - interval '40 days', last_paid_repair_at = null where user_id = uid_a;
  begin
    v_result := public.repair_streak_paid();
    perform pg_temp.expect(false, '6. window passed should raise');
  exception when others then
    perform pg_temp.expect(true, '6. expired window refused');
  end;

  -- =========================================================================
  -- 7. Insufficient tokens → raises, no debit, no restore (atomicity)
  -- =========================================================================
  update public.user_streaks set current_streak = 1, longest_streak = 30,
    pre_lapse_streak = 30, lapsed_at = now() - interval '5 days',
    last_paid_repair_at = null where user_id = uid_a;
  update public.user_tokens set balance = 10 where user_id = uid_a;  -- < 250
  begin
    v_result := public.repair_streak_paid();
    perform pg_temp.expect(false, '7a. insufficient tokens should raise');
  exception when others then
    perform pg_temp.expect(true, '7a. insufficient tokens refused');
  end;
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  select current_streak, pre_lapse_streak into v_cur, v_pre from public.user_streaks where user_id = uid_a;
  perform pg_temp.expect(v_balance = 10, '7b. balance untouched on failure');
  perform pg_temp.expect(v_cur = 1 and v_pre = 30, '7c. streak untouched on failure (atomic)');

  -- =========================================================================
  -- 8. Rate-limit: second paid within 30d rejected
  -- =========================================================================
  update public.user_streaks set current_streak = 1, longest_streak = 30,
    pre_lapse_streak = 30, lapsed_at = now() - interval '5 days',
    last_paid_repair_at = now() - interval '3 days' where user_id = uid_a;
  update public.user_tokens set balance = 1000 where user_id = uid_a;
  begin
    v_result := public.repair_streak_paid();
    perform pg_temp.expect(false, '8. rate-limit should raise');
  exception when others then
    perform pg_temp.expect(true, '8. paid rate-limited within 30d');
  end;

  -- =========================================================================
  -- 9. Premium-free path: no debit, restores, meters premium_free_repair_at
  --    Premium is SERVER-determined — seed an active RC entitlement row.
  -- =========================================================================
  insert into public.user_subscriptions
    (user_id, entitlement, product_id, expires_at, last_event_type, last_event_at)
    values (uid_a, 'premium', 'test_premium', now() + interval '30 days',
            'INITIAL_PURCHASE', now())
    on conflict (user_id, entitlement) do update set
      expires_at = now() + interval '30 days';
  perform pg_temp.expect(public.has_active_premium_entitlement(uid_a),
    '9-pre. server sees active premium entitlement');

  update public.user_streaks set current_streak = 1, longest_streak = 30,
    pre_lapse_streak = 30, lapsed_at = now() - interval '5 days',
    last_paid_repair_at = null, premium_free_repair_at = null where user_id = uid_a;
  update public.user_tokens set balance = 1000 where user_id = uid_a;
  v_result := public.repair_streak_paid();
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect((v_result->>'method') = 'premium_free', '9a. method=premium_free');
  perform pg_temp.expect((v_result->>'cost')::int = 0, '9b. premium free costs 0');
  perform pg_temp.expect(v_balance = 1000, '9c. no token debit on premium free');
  perform pg_temp.expect(
    (select premium_free_repair_at is not null from public.user_streaks where user_id = uid_a),
    '9d. premium_free_repair_at metered');

  -- =========================================================================
  -- 10. Premium-free metered: second within 30d falls back to paid charge
  -- =========================================================================
  update public.user_streaks set current_streak = 1, longest_streak = 30,
    pre_lapse_streak = 30, lapsed_at = now() - interval '5 days',
    last_paid_repair_at = null,
    premium_free_repair_at = now() - interval '2 days' where user_id = uid_a;
  update public.user_tokens set balance = 1000 where user_id = uid_a;
  v_result := public.repair_streak_paid();
  perform pg_temp.expect((v_result->>'method') = 'paid', '10a. premium free spent → falls to paid');
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect(v_balance = 750, '10b. paid path charged 250 after free spent');

  -- Revoke premium so the remaining tests exercise the non-premium (paid) path.
  delete from public.user_subscriptions where user_id = uid_a;
  perform pg_temp.expect(not public.has_active_premium_entitlement(uid_a),
    '10c. premium revoked for subsequent tests');

  -- =========================================================================
  -- 11. longest_streak = greatest(old, restored)
  -- =========================================================================
  update public.user_streaks set current_streak = 5, longest_streak = 200,
    pre_lapse_streak = 30, lapsed_at = now() - interval '5 days',
    last_paid_repair_at = null, premium_free_repair_at = null where user_id = uid_a;
  update public.user_tokens set balance = 1000 where user_id = uid_a;
  v_result := public.repair_streak_paid();
  select longest_streak into v_longest from public.user_streaks where user_id = uid_a;
  perform pg_temp.expect(v_longest = 200, '11. longest never decreases (restored 35 < old 200)');

  -- =========================================================================
  -- 12-14. add_excused_date
  -- =========================================================================
  v_result := public.add_excused_date((timezone('utc', now())::date));
  perform pg_temp.expect((v_result->>'ok')::boolean, '12a. excused add ok');
  perform pg_temp.expect((v_result->>'count_in_window')::int = 1, '12b. count_in_window=1');

  -- Fill to the cap (already 1; add 7 more distinct → 8 total), 9th rejected.
  for i in 1..7 loop
    perform public.add_excused_date((timezone('utc', now())::date - i));
  end loop;
  begin
    v_result := public.add_excused_date((timezone('utc', now())::date - 8));
    perform pg_temp.expect(false, '13. 9th excused within 30d should raise (cap 8)');
  exception when others then
    perform pg_temp.expect(true, '13. excused cap enforced at 8');
  end;

  -- Duplicate date is idempotent (no error).
  begin
    v_result := public.add_excused_date((timezone('utc', now())::date));
    perform pg_temp.expect(true, '14. duplicate excused date idempotent');
  exception when others then
    perform pg_temp.expect(false, '14. duplicate excused date should NOT raise');
  end;

  -- =========================================================================
  -- 17. claim_streak_milestone idempotency (server-authoritative claimed-set)
  -- =========================================================================
  v_result := public.claim_streak_milestone(7);
  perform pg_temp.expect((v_result->>'newly_claimed')::boolean,
    '17a. first milestone claim is newly_claimed=true');
  v_result := public.claim_streak_milestone(7);
  perform pg_temp.expect(not (v_result->>'newly_claimed')::boolean,
    '17b. second claim of same day is newly_claimed=false (no re-grant)');

  perform pg_temp.reset_auth();

  -- =========================================================================
  -- 15. anon cannot execute repair_streak_paid
  -- =========================================================================
  begin
    execute 'set local role anon';
    perform public.repair_streak_paid();
    perform pg_temp.expect(false, '15. anon repair should be denied');
  exception when others then
    perform pg_temp.expect(true, '15. anon cannot execute repair_streak_paid');
  end;
  execute 'reset role';

  -- =========================================================================
  -- 16. user sees only own excused dates (RLS)
  -- =========================================================================
  perform pg_temp.set_auth(uid_b);
  select count(*) into v_cnt from public.user_streak_excused_dates;
  perform pg_temp.expect(v_cnt = 0, '16. uid_b sees none of uid_a excused dates (RLS)');
  perform pg_temp.reset_auth();

  -- =========================================================================
  -- Final tally
  -- =========================================================================
  err := current_setting('test.failed', true);
  if length(coalesce(err, '')) > 0 then
    raise exception 'STREAKS DEFENSE TEST FAILED (% run): %',
      current_setting('test.total', true), err;
  else
    raise notice 'ALL PASS (% tests)', current_setting('test.total', true);
  end if;
end
$body$;

rollback;
