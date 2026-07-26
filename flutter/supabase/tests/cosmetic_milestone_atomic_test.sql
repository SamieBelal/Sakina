-- claim_streak_milestone atomic Noor award (P1 follow-up).
--
-- The client used to call claim_streak_milestone(p_day) THEN award_noor() as
-- two separate RPCs. If the claim committed but award_noor then failed, the
-- retry saw newly_claimed=false and the (idempotent) Noor grant was never
-- re-attempted → a one-time milestone grant was lost. The ONLY robust fix is
-- to mint the milestone Noor INSIDE claim_streak_milestone, in the same
-- transaction (a single RPC call is one tx → commit-or-rollback together).
--
-- Invariants under test:
--   1. Claiming a mintable milestone (30, streak reached) → newly_claimed=true
--      AND noor_awarded = the server-derived amount (150) AND a noor_grants
--      row 'milestone:30' exists AND noor_balance increased by that amount.
--   2. Re-claiming the SAME day → newly_claimed=false, noor_awarded=0, balance
--      unchanged, exactly ONE noor_grants row (idempotent replay awards 0).
--   3. Claiming a recognized-but-NON-mintable day (180 — award_noor has no arm)
--      → newly_claimed=true, noor_awarded=0, and NO raise (the perform is
--      guarded to {7,14,30,60,90}).
--   4. An unreached / unrecognized day is still rejected exactly as before
--      (backward-compat with the hardening guards).
--
-- Backward-compat: existing callers that read only newly_claimed are unaffected
-- (that key is preserved); noor_awarded is a purely additive jsonb key.
--
-- auth.uid() is driven the same way cosmetics_award_noor_test.sql /
-- cosmetics_milestone_fix_test.sql do it: set local role authenticated +
-- request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetic_milestone_atomic_test.sql

begin;
select plan(15);

-- Seed an auth user, a profile row (so award_noor's noor_balance update lands),
-- and a user_streaks row with a high current_streak so every mintable day is
-- "reached".
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d1', 'milestoneatomic@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d1')
on conflict do nothing;
insert into public.user_streaks(user_id, current_streak)
values ('00000000-0000-0000-0000-0000000000d1', 400)
on conflict (user_id) do update set current_streak = excluded.current_streak;

-- Impersonate the seeded user so auth.uid() resolves inside the RPC.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d1',
    'role', 'authenticated')::text,
  true);

-- ── (1) First mintable claim: newly_claimed + noor_awarded + grant + balance ──
select is(
  (public.claim_streak_milestone(30) ->> 'newly_claimed')::boolean,
  true,
  '1a. first claim(30) → newly_claimed=true');

-- (noor_grants row assertions are deferred to the end of the file: noor_grants
--  has RLS with no SELECT policy, so an authenticated read returns nothing —
--  the grant-ledger rows are asserted after reset role, as superuser.)

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d1'),
  150,
  '1c. noor_balance increased by the minted amount (150)');

-- Fresh mintable claim on a DIFFERENT day to assert noor_awarded is returned.
select is(
  (public.claim_streak_milestone(7) ->> 'newly_claimed')::boolean,
  true,
  '1d. first claim(7) → newly_claimed=true');

select is(
  (public.claim_streak_milestone(14) -> 'noor_awarded')::int,
  75,
  '1e. claim(14) returns noor_awarded = server-derived amount (75)');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d1'),
  150 + 40 + 75,
  '1f. balance is the sum of the three mintable milestone grants (30+7+14)');

-- ── (2) Idempotent replay of a claimed day: no re-award, exactly one grant ────
select is(
  (public.claim_streak_milestone(30) ->> 'newly_claimed')::boolean,
  false,
  '2a. replay claim(30) → newly_claimed=false');

select is(
  (public.claim_streak_milestone(30) -> 'noor_awarded')::int,
  0,
  '2b. replay claim(30) → noor_awarded=0 (no re-mint)');

-- (2c grant-row-count assertion deferred to end — see RLS note above.)

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000d1'),
  150 + 40 + 75,
  '2d. balance unchanged by the idempotent replays');

-- ── (3) Recognized-but-non-mintable day (180): claim OK, no award, no raise ──
select lives_ok(
  $$ select public.claim_streak_milestone(180) $$,
  '3a. claim(180) does NOT raise (award_noor arm absent → guarded out)');

select is(
  (public.claim_streak_milestone(365) -> 'noor_awarded')::int,
  0,
  '3b. claim(365) → noor_awarded=0 (non-mintable, guarded)');

select is(
  (public.claim_streak_milestone(365) ->> 'newly_claimed')::boolean,
  false,
  '3c. second claim(365) → newly_claimed=false (idempotent, still no award)');

-- ── (4) Backward-compat: unrecognized / unreached days still rejected ────────
select throws_ok(
  $$ select public.claim_streak_milestone(999) $$,
  NULL,
  NULL,
  '4a. claim(999) throws for an unrecognized milestone day');

-- Lower the streak so 60 is no longer reached, then assert it is rejected.
reset role;
update public.user_streaks set current_streak = 40
  where user_id = '00000000-0000-0000-0000-0000000000d1';
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000d1',
    'role', 'authenticated')::text,
  true);

select throws_ok(
  $$ select public.claim_streak_milestone(60) $$,
  NULL,
  NULL,
  '4b. claim(60) throws when the streak (40) has not reached it');

reset role;
select set_config('request.jwt.claims', '', true);

-- ── Deferred grant-ledger assertions (superuser, RLS-bypassing) ──────────────
-- The milestone:30 grant landed with the server-derived amount, exactly once,
-- despite the two replay claims above (idempotent per user+reason_key).
select is(
  (select amount from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000d1'
       and reason_key = 'milestone:30'),
  150,
  '1b. noor_grants has the milestone:30 row with server-derived amount 150');

select is(
  (select count(*)::int from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000d1'
       and reason_key = 'milestone:30'),
  1,
  '2c. exactly ONE noor_grants row for milestone:30 after replays');

select * from finish();
rollback;
