-- claim_streak_milestone hardening: the RPC must verify BOTH that p_day is a
-- recognized milestone day AND that the caller actually reached it, before it
-- writes a claim row. Without these guards any authenticated user can claim an
-- arbitrary day (an exploit we're about to hang valuable Noor/cosmetic grants off).
--
-- Recognized milestone days: 7,14,30,60,100,180,365.
--
-- Invariants under test:
--   1. Claiming a recognized + reached day (7, streak=7) succeeds (lives_ok).
--   2. Claiming an UNRECOGNIZED day (999) throws.
--   3. Claiming a recognized-but-NOT-reached day (30 while streak=7) throws.
--
-- auth.uid() is driven the same way cosmetics_award_noor_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_milestone_fix_test.sql

begin;
select plan(3);

-- Seed an auth user + a user_streaks row with current_streak = 7. The RPC also
-- writes to user_streak_milestones_claimed on the happy path; no seeding needed
-- there (the INSERT ... ON CONFLICT creates the row).
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000c1', 'milestonefix@test.local')
on conflict do nothing;
insert into public.user_streaks(user_id, current_streak)
values ('00000000-0000-0000-0000-0000000000c1', 7)
on conflict (user_id) do update set current_streak = excluded.current_streak;

-- Impersonate the seeded user so auth.uid() resolves inside the RPC.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c1',
    'role', 'authenticated')::text,
  true);

-- (1) Recognized (7) AND reached (streak=7) → succeeds.
select lives_ok(
  $$ select public.claim_streak_milestone(7) $$,
  'claim_streak_milestone(7) succeeds for a recognized+reached milestone');

-- (2) Unrecognized day (999) → throws. NULL expected-error = "any exception".
select throws_ok(
  $$ select public.claim_streak_milestone(999) $$,
  NULL,
  NULL,
  'claim_streak_milestone(999) throws for an unrecognized milestone day');

-- (3) Recognized (30) but NOT reached (streak is only 7) → throws.
select throws_ok(
  $$ select public.claim_streak_milestone(30) $$,
  NULL,
  NULL,
  'claim_streak_milestone(30) throws when the streak has not reached it');

select finish();
rollback;
