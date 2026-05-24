-- supabase/tests/ai_bypass_p1_security_test.sql
--
-- Pins the AI-bypass P1 security hotfix bundle from migration
-- 20260525000000_ai_bypass_p1_security_bundle.sql.
--
-- 15 assertions covering:
--   * P1-1 cancel_ai_bypass owner auth check (tests 1-4)
--   * P1-2 reserve_ai_bypass replay-status branching (tests 5-8)
--   * P1-3 freemium guards on 2 new user_profiles fields (tests 9-12)
--     NOTE: gift_premium_until guard is deferred to a follow-up because the
--     Ramadan-gifts migration that defines the column is in a separate open
--     PR. See findings doc for the residual P1 entry.
--   * P2-3 app_config CHECK constraints (tests 13-15)
--
-- Wrapped in BEGIN / ROLLBACK — no live state persisted.
--
-- Run: psql "$DATABASE_URL" -f supabase/tests/ai_bypass_p1_security_test.sql
-- Or:  via Supabase MCP execute_sql.

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

-- ---------------------------------------------------------------------------
-- Seed two auth.users (victim + attacker). handle_new_user fires to create
-- user_profiles / user_tokens etc.
-- ---------------------------------------------------------------------------
do $$
declare
  v_victim uuid := gen_random_uuid();
  v_attacker uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                          email_confirmed_at, created_at, updated_at)
  values
    (v_victim, '00000000-0000-0000-0000-000000000000', 'authenticated',
     'authenticated', 'p1-victim-' || v_victim::text || '@example.com',
     '', now(), now(), now()),
    (v_attacker, '00000000-0000-0000-0000-000000000000', 'authenticated',
     'authenticated', 'p1-attacker-' || v_attacker::text || '@example.com',
     '', now(), now(), now());
  perform set_config('test.victim', v_victim::text, false);
  perform set_config('test.attacker', v_attacker::text, false);
end $$;

-- Give victim enough tokens for several reserve attempts (default 100 may not
-- be enough across many tests; bump to 500 via postgres-owner UPDATE which
-- bypasses freemium guards).
update public.user_tokens
  set balance = 500
  where user_id = current_setting('test.victim')::uuid;

-- =============================================================================
-- P1-1: cancel_ai_bypass owner auth check
-- =============================================================================

-- TEST 1: cross-user cancel rejected with `not_pending`
-- Victim reserves; attacker (via JWT) tries to cancel.
do $$
declare v_resv_id uuid; r jsonb; v_caught boolean := false;
begin
  -- Victim's JWT
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.reserve_ai_bypass('reflect', 'test1-victim-key-aaaaaaaa');
  reset role;

  if (r->>'ok')::boolean is not true then
    -- couldn't even reserve — fail the test
    perform pg_temp.expect(false, 'TEST1 SETUP: victim reserve failed: ' || r::text);
    return;
  end if;
  v_resv_id := (r->>'reservation_id')::uuid;

  -- Switch to attacker's JWT
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.attacker'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.cancel_ai_bypass(v_resv_id);
  reset role;

  perform pg_temp.expect(
    (r->>'ok')::boolean = false
      and r->>'reason' = 'not_pending'
      and (select status from public.ai_bypass_reservations where id = v_resv_id) = 'pending',
    'TEST1: cross-user cancel rejected with not_pending and reservation unmutated'
  );

  perform set_config('test.resv_for_test5', v_resv_id::text, false);
end $$;

-- TEST 2: self-cancel on own pending reservation succeeds (honest path).
-- We use the reservation from TEST1 (still pending after attacker's failed cancel).
do $$
declare v_resv_id uuid; r jsonb;
begin
  v_resv_id := current_setting('test.resv_for_test5')::uuid;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.cancel_ai_bypass(v_resv_id);
  reset role;

  perform pg_temp.expect(
    (r->>'ok')::boolean = true,
    'TEST2: self-cancel succeeds (honest path)'
  );
end $$;

-- TEST 3: service_role can cancel any pending reservation (cron rescue path).
do $$
declare v_resv_id uuid; r jsonb;
begin
  -- Make a new pending reservation for victim
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.reserve_ai_bypass('reflect', 'test3-victim-key-bbbbbbbb');
  reset role;
  v_resv_id := (r->>'reservation_id')::uuid;

  -- service_role impersonation — auth.uid() returns NULL but current_user='service_role'
  set local role service_role;
  -- Clear JWT so auth.uid() is null in service_role context (matches cron behavior).
  perform set_config('request.jwt.claims', '', true);
  r := public.cancel_ai_bypass(v_resv_id);
  reset role;

  perform pg_temp.expect(
    (r->>'ok')::boolean = true,
    'TEST3: service_role can cancel any pending reservation'
  );
end $$;

-- TEST 4: postgres role can cancel any pending reservation.
do $$
declare v_resv_id uuid; r jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.reserve_ai_bypass('reflect', 'test4-victim-key-cccccccc');
  reset role;
  v_resv_id := (r->>'reservation_id')::uuid;

  -- postgres (test harness's default role) — current_user='postgres'
  reset role;
  perform set_config('request.jwt.claims', '', true);
  r := public.cancel_ai_bypass(v_resv_id);

  perform pg_temp.expect(
    (r->>'ok')::boolean = true,
    'TEST4: postgres role can cancel any pending reservation'
  );
end $$;

-- =============================================================================
-- P1-2: reserve_ai_bypass replay-status branching
-- =============================================================================

-- TEST 5: replay on cancelled reservation_id → ok:false, reason:replay_after_cancel
-- The TEST1/TEST2 reservation was cancelled by self at TEST2. Replay the same key.
do $$
declare r jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  -- Same key as TEST1
  r := public.reserve_ai_bypass('reflect', 'test1-victim-key-aaaaaaaa');
  reset role;

  perform pg_temp.expect(
    (r->>'ok')::boolean = false and r->>'reason' = 'replay_after_cancel',
    'TEST5: replay on cancelled key returns replay_after_cancel'
  );
end $$;

-- TEST 6: replay on committed reservation_id → ok:false, reason:already_committed
do $$
declare v_resv_id uuid; r jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.reserve_ai_bypass('reflect', 'test6-victim-key-dddddddd');
  v_resv_id := (r->>'reservation_id')::uuid;
  -- Commit it
  r := public.commit_ai_bypass(v_resv_id);
  -- Now replay the same key
  r := public.reserve_ai_bypass('reflect', 'test6-victim-key-dddddddd');
  reset role;

  perform pg_temp.expect(
    (r->>'ok')::boolean = false and r->>'reason' = 'already_committed',
    'TEST6: replay on committed key returns already_committed'
  );
end $$;

-- TEST 7: replay on pending reservation_id → ok:true, replayed:true (true double-tap)
do $$
declare v_first_id uuid; v_second_id uuid; r jsonb;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.reserve_ai_bypass('reflect', 'test7-victim-key-eeeeeeee');
  v_first_id := (r->>'reservation_id')::uuid;
  -- Replay same key while still pending
  r := public.reserve_ai_bypass('reflect', 'test7-victim-key-eeeeeeee');
  v_second_id := (r->>'reservation_id')::uuid;
  reset role;

  perform pg_temp.expect(
    (r->>'ok')::boolean = true and (r->>'replayed')::boolean = true
      and v_second_id = v_first_id,
    'TEST7: replay on pending key returns ok:true, replayed:true, same reservation_id'
  );

  -- Clean up — cancel so TEST8 setup is unambiguous
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  perform public.cancel_ai_bypass(v_first_id);
  reset role;
end $$;

-- TEST 8: unique_violation exception handler hits the same status branch.
-- Hard to provoke a true concurrent insert from a single SQL session — but
-- we can functionally exercise the same branch by:
--   (a) creating a pending reservation with key K,
--   (b) calling reserve again with same key → must return ok:true / replayed
--       (this goes through the fast-path, but the helper IS the unified
--       branch logic, so it pins the helper for the unique_violation path),
--   (c) committing it, then re-calling → must return ok:false.
-- Steps (a)-(c) prove the helper handles both pending and committed states.
do $$
declare v_resv_id uuid; r jsonb;
        v_pending_ok boolean; v_committed_rejected boolean;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;

  -- (a) initial reserve
  r := public.reserve_ai_bypass('reflect', 'test8-victim-key-ffffffff');
  v_resv_id := (r->>'reservation_id')::uuid;

  -- (b) replay same key while pending — must succeed
  r := public.reserve_ai_bypass('reflect', 'test8-victim-key-ffffffff');
  v_pending_ok := (r->>'ok')::boolean = true and (r->>'replayed')::boolean = true;

  -- (c) commit, then replay → must reject
  perform public.commit_ai_bypass(v_resv_id);
  r := public.reserve_ai_bypass('reflect', 'test8-victim-key-ffffffff');
  v_committed_rejected := (r->>'ok')::boolean = false
    and r->>'reason' = 'already_committed';

  reset role;

  perform pg_temp.expect(
    v_pending_ok and v_committed_rejected,
    'TEST8: helper branches identically for pending (ok) vs committed (rejected)'
  );
end $$;

-- =============================================================================
-- P1-3: freemium guards on 3 new user_profiles fields
-- =============================================================================

-- Seed: postgres-owner write so we have an OLD value to test "distinct from"
update public.user_profiles
  set last_winback_grant_at = now() - interval '7 days',
      iap_upsell_banner_dismissed_at = now() - interval '7 days'
  where id = current_setting('test.victim')::uuid;

-- TEST 9: authenticated UPDATE last_winback_grant_at rejected
do $$
declare v boolean := false;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  begin
    update public.user_profiles set last_winback_grant_at = null
      where id = current_setting('test.victim')::uuid;
  exception when others then v := true; end;
  reset role;
  perform pg_temp.expect(v, 'TEST9: authenticated UPDATE last_winback_grant_at rejected');
end $$;

-- TEST 10: authenticated UPDATE iap_upsell_banner_dismissed_at rejected
do $$
declare v boolean := false;
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  begin
    update public.user_profiles set iap_upsell_banner_dismissed_at = '2999-01-01'
      where id = current_setting('test.victim')::uuid;
  exception when others then v := true; end;
  reset role;
  perform pg_temp.expect(v, 'TEST10: authenticated UPDATE iap_upsell_banner_dismissed_at rejected');
end $$;

-- TEST 11: grant_winback_tokens (SECURITY DEFINER) still writes last_winback_grant_at.
-- Call as service_role; the function is SECURITY DEFINER owned by postgres, so
-- inside the function current_user='postgres' which is in the guard bypass list.
do $$
declare v_before timestamptz; v_after timestamptz; r jsonb;
begin
  -- Reset last_winback_grant_at to >30d ago so the 30-day freq cap inside the RPC passes.
  -- Postgres bypasses the guard so we can do this directly.
  reset role;
  perform set_config('request.jwt.claims', '', true);
  update public.user_profiles set last_winback_grant_at = now() - interval '90 days'
    where id = current_setting('test.victim')::uuid;
  select last_winback_grant_at into v_before from public.user_profiles
    where id = current_setting('test.victim')::uuid;

  set local role service_role;
  r := public.grant_winback_tokens(current_setting('test.victim')::uuid, 25);
  reset role;

  select last_winback_grant_at into v_after from public.user_profiles
    where id = current_setting('test.victim')::uuid;

  perform pg_temp.expect(
    (r->>'ok')::boolean = true and v_after > v_before,
    'TEST11 HONEST PATH: grant_winback_tokens writes last_winback_grant_at through guard'
  );
end $$;

-- TEST 12: dismiss_iap_upsell_banner (SECURITY DEFINER) still writes
-- iap_upsell_banner_dismissed_at. Call as authenticated (the function grant
-- is to authenticated). SECURITY DEFINER means current_user='postgres' inside,
-- so the guard's bypass list lets the write through.
do $$
declare v_before timestamptz; v_after timestamptz; r jsonb;
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
  update public.user_profiles set iap_upsell_banner_dismissed_at = now() - interval '90 days'
    where id = current_setting('test.victim')::uuid;
  select iap_upsell_banner_dismissed_at into v_before from public.user_profiles
    where id = current_setting('test.victim')::uuid;

  perform set_config('request.jwt.claims',
    json_build_object('sub', current_setting('test.victim'), 'role','authenticated')::text, true);
  set local role authenticated;
  r := public.dismiss_iap_upsell_banner();
  reset role;

  select iap_upsell_banner_dismissed_at into v_after from public.user_profiles
    where id = current_setting('test.victim')::uuid;

  perform pg_temp.expect(
    (r->>'ok')::boolean = true and v_after > v_before,
    'TEST12 HONEST PATH: dismiss_iap_upsell_banner writes through guard'
  );
end $$;

-- =============================================================================
-- P2-3: app_config CHECK constraints
-- =============================================================================

-- TEST 13: UPDATE bypass_token_cost=0 fails the CHECK
do $$
declare v boolean := false;
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
  begin
    update public.app_config set value = to_jsonb(0) where key = 'bypass_token_cost';
  exception when check_violation then v := true; end;
  perform pg_temp.expect(v, 'TEST13: UPDATE bypass_token_cost=0 fails CHECK');
end $$;

-- TEST 14: UPDATE max_bypasses_per_day=99 fails the CHECK
do $$
declare v boolean := false;
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
  begin
    update public.app_config set value = to_jsonb(99) where key = 'max_bypasses_per_day';
  exception when check_violation then v := true; end;
  perform pg_temp.expect(v, 'TEST14: UPDATE max_bypasses_per_day=99 fails CHECK');
end $$;

-- TEST 15: UPDATE bypass_token_cost=30 succeeds (in-range)
do $$
declare v boolean := false;
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
  begin
    update public.app_config set value = to_jsonb(30) where key = 'bypass_token_cost';
    v := true;
  exception when others then v := false; end;
  perform pg_temp.expect(v, 'TEST15: UPDATE bypass_token_cost=30 succeeds (in-range)');
end $$;

-- ---------------------------------------------------------------------------
-- Final report
-- ---------------------------------------------------------------------------

reset role;

do $$
declare total int; passed int; failed_names text;
begin
  total  := current_setting('test.total')::int;
  passed := current_setting('test.passed')::int;
  failed_names := current_setting('test.failed_names');
  raise notice E'\n========================';
  raise notice 'ai_bypass_p1_security_test: PASSED: % of %', passed, total;
  raise notice '========================';
  if failed_names <> '' then
    raise exception 'FAILURES: %', failed_names;
  end if;
  if passed <> 15 then
    raise exception 'Expected 15 assertions, got % passed (% total)', passed, total;
  end if;
end $$;

rollback;
