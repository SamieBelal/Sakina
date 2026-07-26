-- Milestone day alignment: 90, not 100.
--
-- Three sources used to disagree on the streak-milestone day set:
--   * lib/services/streak_service.dart streakMilestones = {7,14,30,60,90,180,365}
--   * claim_streak_milestone recognized set                = {7,14,30,60,100,180,365}
--   * award_noor case arms                                 = {7,14,30,60,100}
-- The client is canonical (it is the ONLY caller and it only ever sends a day
-- from streakMilestones), so a real 90-day streak claim raised 'unrecognized
-- milestone day 90' — callRpc swallowed it and the claim was never recorded
-- server-side. 100 was unreachable dead code: no client can ever send it.
--
-- Invariants under test:
--   1. Claiming day 90 with the streak reached → newly_claimed=true, Noor minted
--      atomically (400, the amount the old 100 arm carried), noor_grants row
--      'milestone:90', balance credited.
--   2. Replaying claim(90) → newly_claimed=false, noor_awarded=0, balance flat,
--      exactly ONE ledger row (idempotent per user+reason_key).
--   3. The OTHER mintable arms are untouched (60 still mints 250) and the
--      recognized-but-non-mintable days still claim without raising (180 → 0).
--   4. Day 100 is FULLY REMOVED: unrecognized by claim_streak_milestone AND has
--      no award_noor arm. (Chosen over keeping it as a legacy no-op because no
--      client has ever been able to send 100 — see the migration's comment.)
--   5. The security guards are intact: an UNREACHED day 90 is still rejected.
--
-- auth.uid() is driven the same way cosmetic_milestone_atomic_test.sql does it:
-- set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/milestone_day_90_test.sql

begin;
select plan(13);

-- User D1: streak 400 → every milestone day is "reached".
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000e1', 'milestone90@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000e1')
on conflict do nothing;
insert into public.user_streaks(user_id, current_streak)
values ('00000000-0000-0000-0000-0000000000e1', 400)
on conflict (user_id) do update set current_streak = excluded.current_streak;

-- User D2: streak 50 → 90 is recognized but NOT reached.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000e2', 'milestone90b@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000e2')
on conflict do nothing;
insert into public.user_streaks(user_id, current_streak)
values ('00000000-0000-0000-0000-0000000000e2', 50)
on conflict (user_id) do update set current_streak = excluded.current_streak;

-- ── D1: impersonate ──────────────────────────────────────────────────────────
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000e1',
    'role', 'authenticated')::text,
  true);

-- ── (1) Day 90 is claimable and mints atomically ─────────────────────────────
select is(
  (public.claim_streak_milestone(90) ->> 'newly_claimed')::boolean,
  true,
  '1a. claim(90) → newly_claimed=true (90 is a recognized milestone day)');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000e1'),
  400,
  '1b. noor_balance credited by the milestone:90 mint (400)');

-- ── (2) Idempotent replay ────────────────────────────────────────────────────
select is(
  (public.claim_streak_milestone(90) ->> 'newly_claimed')::boolean,
  false,
  '2a. replay claim(90) → newly_claimed=false');

select is(
  (public.claim_streak_milestone(90) -> 'noor_awarded')::int,
  0,
  '2b. replay claim(90) → noor_awarded=0 (no re-mint)');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000e1'),
  400,
  '2c. balance unchanged by the idempotent replays');

-- ── (3) Other arms untouched ─────────────────────────────────────────────────
select is(
  (public.claim_streak_milestone(60) -> 'noor_awarded')::int,
  250,
  '3a. claim(60) still mints 250 (other award_noor arms preserved)');

select is(
  (public.claim_streak_milestone(180) -> 'noor_awarded')::int,
  0,
  '3b. claim(180) still claims without raising, noor_awarded=0 (non-mintable)');

-- ── (4) Day 100 is fully removed from the recognized set ─────────────────────
select throws_ok(
  $$ select public.claim_streak_milestone(100) $$,
  NULL,
  NULL,
  '4a. claim(100) throws — 100 is no longer a recognized milestone day');

select throws_ok(
  $$ select public.award_noor('milestone:100', 'milestone:100') $$,
  NULL,
  NULL,
  '4b. award_noor(milestone:100) throws — the 100 arm is gone');

-- ── D2: impersonate (streak 50) ──────────────────────────────────────────────
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000e2',
    'role', 'authenticated')::text,
  true);

-- ── (5) Security guard intact: recognized but UNREACHED still rejected ───────
select throws_ok(
  $$ select public.claim_streak_milestone(90) $$,
  NULL,
  NULL,
  '5a. claim(90) throws when the streak (50) has not reached it');

select is(
  public.award_noor('milestone:90', 'milestone:90'),
  400,
  '5b. award_noor has a milestone:90 arm worth 400');

-- ── Deferred ledger assertions (superuser, RLS-bypassing) ────────────────────
reset role;
select set_config('request.jwt.claims', '', true);

select is(
  (select amount from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000e1'
       and reason_key = 'milestone:90'),
  400,
  '1c. noor_grants has the milestone:90 row with server-derived amount 400');

select is(
  (select count(*)::int from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000e1'
       and reason_key = 'milestone:90'),
  1,
  '2d. exactly ONE noor_grants row for milestone:90 after replays');

select * from finish();
rollback;
