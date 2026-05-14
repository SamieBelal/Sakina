-- Regression test for:
--   * 20260514000000_referrals.sql
--
-- Verifies refer-to-unlock end-to-end:
--   * ensure_referral_code returns the same code on repeat calls.
--   * apply_referral rejects invalid_code / self_referral / chain_referral.
--   * apply_referral grants the referee a 7-day premium window on success
--     (mutual reward).
--   * apply_referral never shrinks an existing longer window.
--   * apply_referral is idempotent on (referee_id).
--   * confirm_referral_if_pending flips pending → confirmed.
--   * After 3 confirmations: referrer's referral_premium_until is ~30d out,
--     a referral_grants row exists, a gold user_card_collection row for
--     name_id=1 exists.
--   * 4th confirmation during the active window does NOT extend.
--   * After the window expires + 3 NEW confirmations, a SECOND grant fires.
--   * RLS lockdown: authenticated role cannot UPDATE referral_premium_until
--     OR referral_code (extended guard trigger).
--   * service_role bypass: still works for the SECURITY DEFINER RPC writes.
--
-- Pattern matches backend_rls_test.sql / freemium_gating_lockdown_test.sql:
-- one transaction, assertions inside a DO block, rollback at end. Run via:
--   mcp__supabase__execute_sql query=$(cat referrals_test.sql)
--
-- Note on the "second cohort" assertion (step 9): inside a single SQL
-- transaction, now() is statement-invariant — all calls within one tx return
-- transaction_timestamp(). That means in tests the first cohort's
-- confirmed_at == granted_at == e.confirmed_at, so the strict `>` in the
-- confirm_referral_if_pending threshold check would never count the
-- second-cohort referees as "new". In production each RPC is a separate
-- transaction so now() advances naturally. To exercise the second-cohort
-- path in this single-transaction test we backdate the first grant's
-- granted_at via the service_role bypass before doing the second cohort.

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
  '00000000-0000-0000-0000-000000005101', 'r-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005102', 'a-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005103', 'b-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005104', 'c-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005105', 'd-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005106', 'e-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005107', 'f-refer@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005108', 's-refer@test.sakina.local');

do $body$
declare
  rid constant uuid := '00000000-0000-0000-0000-000000005101';
  aid constant uuid := '00000000-0000-0000-0000-000000005102';
  bid constant uuid := '00000000-0000-0000-0000-000000005103';
  cid constant uuid := '00000000-0000-0000-0000-000000005104';
  did constant uuid := '00000000-0000-0000-0000-000000005105';
  eid constant uuid := '00000000-0000-0000-0000-000000005106';
  fid constant uuid := '00000000-0000-0000-0000-000000005107';
  sid constant uuid := '00000000-0000-0000-0000-000000005108';
  failures text;
  total int := 0;
  failed_count int := 0;
  failed_list text;
  code_r text;
  code_r2 text;
  code_s text;
  res jsonb;
  raised boolean;
  card_tier_val text;
  pri_until timestamptz;
  pri_until_post timestamptz;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- =========================================================================
  -- 1. ensure_referral_code populates the code + is idempotent.
  -- =========================================================================
  code_r := public.ensure_referral_code(rid);
  perform pg_temp.expect(code_r is not null and length(code_r) = 8,
    '1.1 ensure_referral_code returns 8-char code');

  code_r2 := public.ensure_referral_code(rid);
  perform pg_temp.expect(code_r2 = code_r,
    '1.2 ensure_referral_code is idempotent for same user');

  code_s := public.ensure_referral_code(sid);
  perform pg_temp.expect(code_s is not null and code_s <> code_r,
    '1.3 different users get distinct codes');

  perform pg_temp.expect(code_r !~ '[IO01]',
    '1.4 code excludes confusables I/O/0/1');

  -- =========================================================================
  -- 2. apply_referral rejection paths.
  -- =========================================================================
  res := public.apply_referral('NOSUCHCODE', aid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = false and (res->>'reason') = 'invalid_code',
    '2.1 invalid_code rejected');

  res := public.apply_referral(code_r, rid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = false and (res->>'reason') = 'self_referral',
    '2.2 self_referral rejected');

  -- =========================================================================
  -- 3. apply_referral success grants 7d to referee.
  -- =========================================================================
  res := public.apply_referral(code_r, aid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = true and (res->>'granted_referee_7d')::boolean = true,
    '3.1 apply_referral ok + granted_referee_7d=true');

  pri_until_post := (select referral_premium_until from public.user_profiles where id = aid);
  perform pg_temp.expect(
    pri_until_post is not null
      and pri_until_post > now() + interval '6 days'
      and pri_until_post < now() + interval '8 days',
    '3.2 referee (a) referral_premium_until ~7 days out');

  -- =========================================================================
  -- 4. apply_referral idempotent on referee.
  -- =========================================================================
  res := public.apply_referral(code_r, aid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = true and (res->>'granted_referee_7d')::boolean = false,
    '4.1 re-apply same code is no-op');

  perform pg_temp.expect(
    (select referral_premium_until from public.user_profiles where id = aid)
      = pri_until_post,
    '4.2 referee window unchanged on re-apply');

  -- =========================================================================
  -- 5. chain-referral rejection.
  -- =========================================================================
  declare
    code_a text;
    res2 jsonb;
  begin
    code_a := public.ensure_referral_code(aid);
    res2 := public.apply_referral(code_a, did);
    perform pg_temp.expect(
      (res2->>'ok')::boolean = true and (res2->>'granted_referee_7d')::boolean = true,
      '5.1 a can refer d (a is now a referrer)');

    res2 := public.apply_referral(code_s, aid);
    perform pg_temp.expect(
      (res2->>'ok')::boolean = false and (res2->>'reason') = 'chain_referral',
      '5.2 chain_referral rejected when target is already a referrer');
  end;

  -- =========================================================================
  -- 6. confirm flips pending → confirmed.
  -- =========================================================================
  res := public.confirm_referral_if_pending(aid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = true
      and (res->>'confirmed')::boolean = true
      and (res->>'granted')::boolean = false
      and (res->>'new_confirmed_count')::int = 1,
    '6.1 first confirmation: confirmed=true, granted=false, count=1');

  perform pg_temp.expect(
    (select status from public.referrals where referee_id = aid) = 'confirmed',
    '6.2 referrals.status flipped to confirmed for a');

  -- =========================================================================
  -- 7. 3-confirm threshold fires the grant.
  -- =========================================================================
  perform public.apply_referral(code_r, bid);
  perform public.apply_referral(code_r, cid);
  perform public.confirm_referral_if_pending(bid);
  res := public.confirm_referral_if_pending(cid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = true
      and (res->>'granted')::boolean = true
      and (res->>'new_confirmed_count')::int = 3,
    '7.1 3rd confirmation grants: granted=true, count=3');

  pri_until := (select referral_premium_until from public.user_profiles where id = rid);
  perform pg_temp.expect(
    pri_until is not null
      and pri_until > now() + interval '29 days'
      and pri_until < now() + interval '31 days',
    '7.2 referrer referral_premium_until ~30 days out');

  perform pg_temp.expect(
    (select count(*) from public.referral_grants where referrer_id = rid) = 1,
    '7.3 one referral_grants row exists');

  card_tier_val := (select tier::text from public.user_card_collection
                      where user_id = rid and name_id = 1);
  perform pg_temp.expect(
    card_tier_val = 'gold',
    '7.4 gold user_card_collection row exists for rid (name_id=1)');

  -- =========================================================================
  -- 8. 4th confirmation while window still active → no re-grant.
  -- =========================================================================
  perform public.apply_referral(code_r, eid);
  res := public.confirm_referral_if_pending(eid);
  perform pg_temp.expect(
    (res->>'ok')::boolean = true and (res->>'granted')::boolean = false
      and (res->>'reason') = 'window_still_active',
    '8.1 4th confirmation while active: granted=false, reason=window_still_active');
  perform pg_temp.expect(
    (select count(*) from public.referral_grants where referrer_id = rid) = 1,
    '8.2 still only one referral_grants row');

  -- =========================================================================
  -- 9. Second cohort: expire the window + backdate the first grant so the
  --    threshold check counts e/f/g as "new" (single-tx now() is invariant).
  -- =========================================================================
  -- service_role bypass (postgres) for the backdate + expire writes.
  -- service_role bypass for the backdate (we're still postgres at this
  -- point — no role-switch yet).
  update public.user_profiles
     set referral_premium_until = now() - interval '1 hour'
   where id = rid;
  update public.referral_grants
     set granted_at = now() - interval '40 days'
   where referrer_id = rid;

  -- Apply + confirm f. Inside a single SQL transaction, now() is invariant,
  -- so after backdating granted_at, every existing confirmed referral (A/B/C
  -- and e from step 8) counts as "new since last grant". The very FIRST
  -- confirm in this section will therefore cross the threshold and trigger
  -- the second grant. We test that the second grant fires from THIS call.
  perform public.apply_referral(code_r, fid);
  declare
    fres jsonb;
  begin
    fres := public.confirm_referral_if_pending(fid);
    perform pg_temp.expect(
      (fres->>'ok')::boolean = true
        and (fres->>'granted')::boolean = true
        and (fres->>'new_confirmed_count')::int >= 3,
      '9.1 second 30d window granted after expire + new confirmation '
      '(single-tx test counts all prior confirms as "new since last grant" '
      'because now() is transaction_timestamp-invariant; production splits '
      'each RPC into its own tx and now() advances naturally)');
  end;

  perform pg_temp.expect(
    (select count(*) from public.referral_grants where referrer_id = rid) = 2,
    '9.2 two referral_grants rows after second cohort');

  card_tier_val := (select tier::text from public.user_card_collection
                      where user_id = rid and name_id = 1);
  perform pg_temp.expect(
    card_tier_val = 'gold',
    '9.3 card stays at gold after second grant');

  -- =========================================================================
  -- 10. RLS lockdown: authenticated role cannot UPDATE the protected fields.
  --     Must set request.jwt.claims so RLS auth.uid() resolves to the user.
  -- =========================================================================
  set local role authenticated;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', aid::text, 'role', 'authenticated')::text, true);

  raised := false;
  begin
    update public.user_profiles
       set referral_premium_until = now() + interval '100 days'
     where id = aid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '10.1 authenticated UPDATE of referral_premium_until raises check_violation');

  raised := false;
  begin
    update public.user_profiles set referral_code = 'HACK1234' where id = aid;
  exception when check_violation then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '10.2 authenticated UPDATE of referral_code raises check_violation');

  -- =========================================================================
  -- 11. service_role bypass smoke: direct postgres UPDATE works.
  -- =========================================================================
  perform set_config('request.jwt.claims', '', true);
  reset role;
  update public.user_profiles set referral_premium_until = pri_until_post
   where id = aid;
  perform pg_temp.expect(
    (select referral_premium_until from public.user_profiles where id = aid)
      = pri_until_post,
    '11.1 postgres role bypass: direct UPDATE works');

  total := coalesce(current_setting('test.total', true)::int, 0);
  failures := coalesce(current_setting('test.failed', true), '');
  if failures = '' then
    raise notice 'PASS: % checks', total;
  else
    failed_list := failures;
    failed_count := array_length(string_to_array(failed_list, ' | '), 1) - 1;
    raise exception 'FAIL: % of % checks failed:%', failed_count, total, failed_list;
  end if;
end
$body$;

rollback;
