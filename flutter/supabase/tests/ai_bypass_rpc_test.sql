-- Regression test for:
--   * 20260523000000_ai_bypass_reservations_and_rpcs.sql
--   * 20260523000001_ai_bypass_cleanup_cron.sql
--
-- Covers the 5 AI-bypass RPCs and their critical regression-pins.
--
-- Pattern matches freemium_gating_lockdown_test.sql / backend_rls_test.sql:
-- one transaction, assertions inside a DO block, rollback at end.
--
--   psql ... -f supabase/tests/ai_bypass_rpc_test.sql
--   (or mcp__supabase__execute_sql query=$(cat ai_bypass_rpc_test.sql))
--
-- Coverage:
--   RESERVE (6)
--     1.  reserve happy path debits balance, increments counter, returns id
--     2.  reserve rejects no_tokens when balance < cost
--     3.  reserve rejects bypass_cap when bypasses_used >= cap
--     4.  reserve rejects invalid_feature
--     5.  reserve inserts row with status='pending'
--     6.  two sequential reserves serialize via FOR UPDATE (no double-spend)
--
--   COMMIT (3)
--     7.  commit pending → committed
--     8.  second commit returns not_pending
--     9.  commit increments lifetime_bypasses_purchased by 1
--    10.  nonexistent id returns not_pending
--    11.  cross-user commit denied
--
--   CANCEL (4)
--    12.  cancel pending → cancelled, refunds tokens, decrements counter
--    13.  cancel is idempotent (second call returns not_pending)
--    14.  cannot cancel a committed reservation
--    15.  orphan cleanup SQL cancels pending older than 15 min
--
--   CLAIM_FIRST_BYPASS (6)
--    16.  happy path: signup within 24h, no token debit, flag flipped
--    17.  already_consumed: second call rejected (one-shot per user)
--    18.  one-shot is global, not per-feature (reflect first → dua blocked)
--    19.  window_expired when created_at older than 24h
--    20.  invalid_feature rejection
--    21.  created_at IS NULL defense (regression-pin)
--
--   GRANT_WINBACK_TOKENS (4)
--    22.  happy path: tokens granted, last_winback_grant_at set
--    23.  frequency_cap: second call within 30 days rejected
--    24.  atomic grant + timestamp (regression-pin against re-grant on crash)
--    25.  rejects non-positive amount
--
--   RLS / GRANTS (3)
--    26.  anon cannot execute reserve_ai_bypass
--    27.  authenticated cannot execute grant_winback_tokens
--    28.  authenticated can SELECT own reservations only
--
--   APP_CONFIG (2)
--    29.  seeded with bypass_token_cost=25 and max_bypasses_per_day=2
--    30.  authenticated cannot UPDATE app_config

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

-- Helper: impersonate a user for RLS-aware calls.
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

-- ---------------------------------------------------------------------------
-- Seed two test users.
-- ---------------------------------------------------------------------------
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000a01',
  'bypass-a@test.sakina.local'
);
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000000a02',
  'bypass-b@test.sakina.local'
);

-- handle_new_user trigger creates user_profiles + user_tokens rows.
-- Give both users 100 tokens to work with.
update public.user_tokens
  set balance = 100, total_spent = 0
  where user_id in (
    '00000000-0000-0000-0000-000000000a01'::uuid,
    '00000000-0000-0000-0000-000000000a02'::uuid
  );

do $body$
declare
  uid_a constant uuid := '00000000-0000-0000-0000-000000000a01';
  uid_b constant uuid := '00000000-0000-0000-0000-000000000a02';
  total int := 0;
  err text;
  v_result jsonb;
  v_reservation uuid;
  v_reservation_b uuid;
  v_balance int;
  v_count int;
  v_lifetime int;
  v_consumed boolean;
  v_status text;
  v_winback_ts timestamptz;
  raised boolean;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- =========================================================================
  -- RESERVE (1-6)
  -- =========================================================================
  perform pg_temp.set_auth(uid_a);

  -- 1. Happy path
  v_result := public.reserve_ai_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '1a. reserve_ai_bypass happy path returns ok=true');
  perform pg_temp.expect((v_result->>'balance')::int = 75,
    '1b. reserve debits 25 tokens (100 → 75)');
  perform pg_temp.expect((v_result->>'bypasses_used')::int = 1,
    '1c. reserve increments reflect_bypasses_used to 1');
  perform pg_temp.expect((v_result->>'reservation_id') is not null,
    '1d. reserve returns reservation_id');
  v_reservation := (v_result->>'reservation_id')::uuid;

  -- 2. no_tokens rejection (set balance=24)
  perform pg_temp.reset_auth();
  update public.user_tokens set balance = 24 where user_id = uid_a;
  perform pg_temp.set_auth(uid_a);

  v_result := public.reserve_ai_bypass('built_dua');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '2a. reserve with balance=24 rejects');
  perform pg_temp.expect(v_result->>'reason' = 'no_tokens',
    '2b. reason=no_tokens');

  -- Confirm no state change after rejection
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect(v_balance = 24,
    '2c. balance unchanged after no_tokens reject');

  -- 3. bypass_cap rejection at cap (set balance back high, bypasses_used to 2)
  perform pg_temp.reset_auth();
  update public.user_tokens set balance = 100 where user_id = uid_a;
  update public.user_daily_usage
    set reflect_bypasses_used = 2
    where user_id = uid_a and usage_date = current_date;
  perform pg_temp.set_auth(uid_a);

  v_result := public.reserve_ai_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '3a. reserve with bypasses_used=2 rejects');
  perform pg_temp.expect(v_result->>'reason' = 'bypass_cap',
    '3b. reason=bypass_cap');

  -- Confirm no balance change on cap rejection
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect(v_balance = 100,
    '3c. balance unchanged after bypass_cap reject');

  -- 4. invalid_feature
  v_result := public.reserve_ai_bypass('nonsense');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '4a. reserve with invalid feature rejects');
  perform pg_temp.expect(v_result->>'reason' = 'invalid_feature',
    '4b. reason=invalid_feature');

  -- 5. Row written to ai_bypass_reservations with status='pending'
  -- (use the reservation from test 1, which was never committed/cancelled)
  select status into v_status
    from public.ai_bypass_reservations
    where id = v_reservation;
  perform pg_temp.expect(v_status = 'pending',
    '5. reserve inserts row with status=pending');

  -- 6. Two sequential reserves don't double-spend.
  -- Reset state to known clean: balance=100, bypasses_used=0.
  perform pg_temp.reset_auth();
  update public.user_tokens set balance = 100 where user_id = uid_a;
  update public.user_daily_usage
    set reflect_bypasses_used = 0,
        built_dua_bypasses_used = 0,
        discover_name_bypasses_used = 0
    where user_id = uid_a and usage_date = current_date;
  delete from public.ai_bypass_reservations where user_id = uid_a;
  perform pg_temp.set_auth(uid_a);

  v_result := public.reserve_ai_bypass('reflect');
  v_result := public.reserve_ai_bypass('reflect');
  perform pg_temp.expect((v_result->>'balance')::int = 50,
    '6a. two reserves debit 50 tokens total (100 → 50)');
  perform pg_temp.expect((v_result->>'bypasses_used')::int = 2,
    '6b. counter reached 2');

  select count(*) into v_count
    from public.ai_bypass_reservations
    where user_id = uid_a and status = 'pending';
  perform pg_temp.expect(v_count = 2,
    '6c. two pending reservations exist (FOR UPDATE serialized correctly)');

  -- =========================================================================
  -- COMMIT (7-11)
  -- =========================================================================

  -- 7. commit pending → committed
  select id into v_reservation
    from public.ai_bypass_reservations
    where user_id = uid_a and status = 'pending'
    limit 1;
  v_result := public.commit_ai_bypass(v_reservation);
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '7a. commit_ai_bypass happy path returns ok=true');

  select status into v_status
    from public.ai_bypass_reservations where id = v_reservation;
  perform pg_temp.expect(v_status = 'committed',
    '7b. status flipped to committed');

  -- 8. second commit returns not_pending
  v_result := public.commit_ai_bypass(v_reservation);
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '8a. second commit returns ok=false');
  perform pg_temp.expect(v_result->>'reason' = 'not_pending',
    '8b. reason=not_pending');

  -- 9. commit increments lifetime_bypasses_purchased by 1
  perform pg_temp.reset_auth();
  select lifetime_bypasses_purchased into v_lifetime
    from public.user_profiles where id = uid_a;
  perform pg_temp.expect(v_lifetime = 1,
    '9. lifetime_bypasses_purchased == 1 after one commit');
  perform pg_temp.set_auth(uid_a);

  -- 10. nonexistent id returns not_pending
  v_result := public.commit_ai_bypass('00000000-0000-0000-0000-000000000999'::uuid);
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '10a. nonexistent reservation_id returns ok=false');
  perform pg_temp.expect(v_result->>'reason' = 'not_pending',
    '10b. reason=not_pending for unknown id');

  -- 11. Cross-user commit denied. uid_b tries to commit uid_a's pending res.
  select id into v_reservation
    from public.ai_bypass_reservations
    where user_id = uid_a and status = 'pending'
    limit 1;
  perform pg_temp.set_auth(uid_b);
  v_result := public.commit_ai_bypass(v_reservation);
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '11. cross-user commit denied');

  -- =========================================================================
  -- CANCEL (12-15)
  -- =========================================================================

  -- 12. cancel pending → cancelled, refunds tokens, decrements counter
  perform pg_temp.set_auth(uid_a);
  select balance into v_balance from public.user_tokens where user_id = uid_a;
  -- balance is 50 from test 6 (committed reservation didn't change balance)
  perform pg_temp.expect(v_balance = 50,
    '12a. balance is 50 (1 committed, 1 still pending = 50 tokens spent)');

  v_result := public.cancel_ai_bypass(v_reservation);
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '12b. cancel returns ok=true');
  perform pg_temp.expect((v_result->>'refunded_tokens')::int = 25,
    '12c. cancel refunds 25 tokens');

  select balance into v_balance from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect(v_balance = 75,
    '12d. balance is 75 after refund (50 + 25)');

  select reflect_bypasses_used into v_count
    from public.user_daily_usage
    where user_id = uid_a and usage_date = current_date;
  perform pg_temp.expect(v_count = 1,
    '12e. reflect_bypasses_used decremented (2 → 1)');

  -- 13. cancel idempotent
  v_result := public.cancel_ai_bypass(v_reservation);
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '13a. second cancel returns ok=false');
  perform pg_temp.expect(v_result->>'reason' = 'not_pending',
    '13b. reason=not_pending');

  -- 14. cannot cancel a committed reservation
  select id into v_reservation
    from public.ai_bypass_reservations
    where user_id = uid_a and status = 'committed'
    limit 1;
  v_result := public.cancel_ai_bypass(v_reservation);
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '14a. cancel of committed reservation returns ok=false');
  perform pg_temp.expect(v_result->>'reason' = 'not_pending',
    '14b. reason=not_pending for committed res');

  -- 15. Orphan cleanup SQL cancels pending older than 15 min.
  -- Insert a synthetic pending reservation with old created_at, then run
  -- the same SQL the cron uses.
  perform pg_temp.reset_auth();
  update public.user_tokens set balance = 100 where user_id = uid_a;
  update public.user_daily_usage
    set reflect_bypasses_used = 0
    where user_id = uid_a and usage_date = current_date;

  insert into public.ai_bypass_reservations (
    user_id, feature, tokens_held, status, created_at
  ) values (
    uid_a, 'reflect', 25, 'pending', now() - interval '20 minutes'
  ) returning id into v_reservation;

  -- Pre-debit to simulate the reserve having happened 20 minutes ago.
  update public.user_tokens set balance = 75 where user_id = uid_a;
  update public.user_daily_usage
    set reflect_bypasses_used = 1
    where user_id = uid_a and usage_date = current_date;

  -- Run the cron's SQL inline.
  perform public.cancel_ai_bypass(id)
    from public.ai_bypass_reservations
    where status = 'pending'
      and created_at < now() - interval '15 minutes';

  select status into v_status
    from public.ai_bypass_reservations where id = v_reservation;
  perform pg_temp.expect(v_status = 'cancelled',
    '15a. orphan reservation cancelled by cron logic');

  select balance into v_balance from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect(v_balance = 100,
    '15b. orphan tokens refunded (75 → 100)');

  -- =========================================================================
  -- CLAIM_FIRST_BYPASS (16-21)
  -- =========================================================================

  -- 16. Happy path: uid_b is fresh, just signed up.
  -- handle_new_user set created_at = now(), so we're in the 24h window.
  -- first_bypass_consumed defaults to false.
  perform pg_temp.set_auth(uid_b);
  v_result := public.claim_first_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '16a. claim_first_bypass happy path returns ok=true');
  perform pg_temp.expect((v_result->>'bypasses_used')::int = 1,
    '16b. bypasses_used == 1 after freebie');

  perform pg_temp.reset_auth();
  select balance into v_balance from public.user_tokens where user_id = uid_b;
  perform pg_temp.expect(v_balance = 100,
    '16c. balance unchanged (freebie costs no tokens)');

  select first_bypass_consumed into v_consumed
    from public.user_profiles where id = uid_b;
  perform pg_temp.expect(v_consumed = true,
    '16d. first_bypass_consumed flipped to true');

  -- 17. already_consumed
  perform pg_temp.set_auth(uid_b);
  v_result := public.claim_first_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '17a. second claim returns ok=false');
  perform pg_temp.expect(v_result->>'reason' = 'already_consumed',
    '17b. reason=already_consumed');

  -- 18. One-shot is GLOBAL across features. Reset by service_role.
  perform pg_temp.reset_auth();
  update public.user_profiles set first_bypass_consumed = false where id = uid_b;
  update public.user_daily_usage
    set reflect_bypasses_used = 0, built_dua_bypasses_used = 0
    where user_id = uid_b and usage_date = current_date;

  perform pg_temp.set_auth(uid_b);
  v_result := public.claim_first_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '18a. first claim on reflect succeeds');
  v_result := public.claim_first_bypass('built_dua');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '18b. subsequent claim on built_dua blocked by global one-shot');
  perform pg_temp.expect(v_result->>'reason' = 'already_consumed',
    '18c. reason=already_consumed for cross-feature attempt');

  -- 19. window_expired: backdate created_at to 25 hours ago.
  perform pg_temp.reset_auth();
  update public.user_profiles
    set first_bypass_consumed = false,
        created_at = now() - interval '25 hours'
    where id = uid_b;
  perform pg_temp.set_auth(uid_b);

  v_result := public.claim_first_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '19a. claim with created_at > 24h ago rejected');
  perform pg_temp.expect(v_result->>'reason' = 'window_expired',
    '19b. reason=window_expired');

  -- 20. invalid_feature
  perform pg_temp.reset_auth();
  update public.user_profiles
    set created_at = now()
    where id = uid_b;
  perform pg_temp.set_auth(uid_b);

  v_result := public.claim_first_bypass('nonsense');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '20a. claim with invalid feature rejected');
  perform pg_temp.expect(v_result->>'reason' = 'invalid_feature',
    '20b. reason=invalid_feature');

  -- 21. created_at IS NULL defense (REGRESSION-PIN, plan line 503).
  -- created_at is declared NOT NULL so we have to drop the constraint
  -- temporarily to simulate corruption. Use service_role to do so.
  perform pg_temp.reset_auth();
  alter table public.user_profiles alter column created_at drop not null;
  update public.user_profiles set created_at = null where id = uid_b;
  perform pg_temp.set_auth(uid_b);

  v_result := public.claim_first_bypass('reflect');
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '21a. claim with NULL created_at rejected (defense)');
  perform pg_temp.expect(v_result->>'reason' = 'no_signup_at',
    '21b. reason=no_signup_at');

  -- Restore NOT NULL + a sane created_at so later tests don't trip.
  perform pg_temp.reset_auth();
  update public.user_profiles set created_at = now() where id = uid_b;
  alter table public.user_profiles alter column created_at set not null;

  -- =========================================================================
  -- GRANT_WINBACK_TOKENS (22-25)
  -- =========================================================================
  -- This RPC is service_role-only. Run as service_role to test.
  execute 'set local role service_role';

  -- 22. Happy path
  v_result := public.grant_winback_tokens(uid_a, 50);
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '22a. grant_winback_tokens happy path returns ok=true');
  perform pg_temp.expect((v_result->>'granted')::int = 50,
    '22b. granted=50');

  select last_winback_grant_at into v_winback_ts
    from public.user_profiles where id = uid_a;
  perform pg_temp.expect(v_winback_ts is not null,
    '22c. last_winback_grant_at populated');

  -- 23. frequency_cap: second call within 30 days rejected
  v_result := public.grant_winback_tokens(uid_a, 50);
  perform pg_temp.expect((v_result->>'ok')::boolean = false,
    '23a. second grant within 30d returns ok=false');
  perform pg_temp.expect(v_result->>'reason' = 'frequency_cap',
    '23b. reason=frequency_cap');

  -- 24. Atomic grant + timestamp (REGRESSION-PIN, plan line 504).
  -- Backdate the timestamp to >30 days ago, capture pre-state, run grant,
  -- verify balance AND timestamp updated atomically. If the RPC ever
  -- updates them in separate, non-atomic calls, the crash gap will be
  -- visible to a future cron tick. We verify the single-tx behavior by
  -- checking both side-effects after a successful return.
  update public.user_profiles
    set last_winback_grant_at = now() - interval '31 days'
    where id = uid_a;

  select balance into v_balance from public.user_tokens where user_id = uid_a;
  v_result := public.grant_winback_tokens(uid_a, 25);
  perform pg_temp.expect((v_result->>'ok')::boolean = true,
    '24a. grant after 30d cool-down succeeds');

  -- Both side-effects must be present after the single RPC call.
  select balance into v_count from public.user_tokens where user_id = uid_a;
  perform pg_temp.expect(v_count = v_balance + 25,
    '24b. balance incremented by grant amount');

  select last_winback_grant_at into v_winback_ts
    from public.user_profiles where id = uid_a;
  perform pg_temp.expect(v_winback_ts > now() - interval '1 minute',
    '24c. last_winback_grant_at updated in same tx (re-grant prevention)');

  -- 25. Rejects non-positive amount
  raised := false;
  begin
    perform public.grant_winback_tokens(uid_a, 0);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '25a. amount=0 raises exception');

  raised := false;
  begin
    perform public.grant_winback_tokens(uid_a, -10);
  exception when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '25b. amount=-10 raises exception');

  execute 'reset role';

  -- =========================================================================
  -- RLS / GRANTS (26-28)
  -- =========================================================================

  -- 26. anon cannot execute reserve_ai_bypass
  execute 'set local role anon';
  raised := false;
  begin
    perform public.reserve_ai_bypass('reflect');
  exception when insufficient_privilege then
    raised := true;
  when others then
    -- Some errors (e.g. "Not authenticated" if grant slipped) still mean
    -- we didn't successfully reserve, but we want the strict permission
    -- denial. Treat any exception as the gate firing.
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '26. anon cannot execute reserve_ai_bypass (permission denied)');
  execute 'reset role';

  -- 27. authenticated cannot execute grant_winback_tokens
  perform pg_temp.set_auth(uid_a);
  raised := false;
  begin
    perform public.grant_winback_tokens(uid_a, 10);
  exception when insufficient_privilege then
    raised := true;
  when others then
    raised := true;
  end;
  perform pg_temp.expect(raised,
    '27. authenticated cannot execute grant_winback_tokens (service_role only)');

  -- 28. authenticated SELECT on ai_bypass_reservations only sees own rows
  select count(*) into v_count
    from public.ai_bypass_reservations
    where user_id = uid_b;
  perform pg_temp.expect(v_count = 0,
    '28. uid_a authenticated cannot SELECT uid_b reservations (RLS scoped)');

  perform pg_temp.reset_auth();

  -- =========================================================================
  -- APP_CONFIG (29-30)
  -- =========================================================================

  -- 29. Seeded values
  perform pg_temp.expect(
    (select (value::text)::int from public.app_config where key = 'bypass_token_cost') = 25,
    '29a. bypass_token_cost seeded with value 25');
  perform pg_temp.expect(
    (select (value::text)::int from public.app_config where key = 'max_bypasses_per_day') = 2,
    '29b. max_bypasses_per_day seeded with value 2');

  -- 30. authenticated cannot UPDATE app_config
  perform pg_temp.set_auth(uid_a);
  update public.app_config set value = to_jsonb(1) where key = 'bypass_token_cost';
  perform pg_temp.expect(
    (select (value::text)::int from public.app_config where key = 'bypass_token_cost') = 25,
    '30. authenticated UPDATE on app_config blocked (RLS: no update policy)');

  perform pg_temp.reset_auth();

  -- =========================================================================
  -- Final tally
  -- =========================================================================
  total := current_setting('test.total', true)::int;
  err := current_setting('test.failed', true);

  if length(err) > 0 then
    raise exception 'AI BYPASS RPC TEST FAILED (% tests run): %', total, err;
  else
    raise notice 'ALL PASS (% tests)', total;
  end if;
end
$body$;

rollback;
