-- claim_streak_milestone: the "reached" check must not rest on a column the
-- client can write.
--
-- ── THE EXPLOIT THIS FILE PINS SHUT ────────────────────────────────────────
-- `user_streaks` grants `authenticated` direct INSERT/UPDATE, and the UPDATE
-- policy has no WITH CHECK. So the caller can simply write its own
-- `current_streak`, which is the ONLY thing the old reached-check read:
--
--     update user_streaks set current_streak = 365 where user_id = me;
--     claim_streak_milestone(7|14|30|60|90) → 40+75+150+250+400 = 915 Noor
--
-- 915 Noor clears most of `cosmetic_catalog`, including à-la-carte skins that
-- carry an `iap_product_id` (real-money SKUs) — revenue loss, and repeatable on
-- every throwaway account at zero cost.
--
-- ── WHAT THE FIX ADDS ──────────────────────────────────────────────────────
-- A second, server-authoritative guard: `auth.users.created_at`. `authenticated`
-- holds no privilege of any kind on `auth.users` (verified: has_table_privilege
-- select AND update both false) and PostgREST does not expose the `auth`
-- schema, so signup time is the one fact in this transaction the caller cannot
-- author. An N-day streak is physically impossible on an account that has not
-- existed for N distinct UTC dates, so gating on it can never deny a milestone
-- a real user earned. See the migration header for why per-day check-in
-- evidence was rejected as the signal (it produces FALSE DENIALS under this
-- app's own streak semantics) .
--
-- Invariants under test:
--   1. Forged streak on a fresh account → 'milestone % not reached', 0 Noor.
--   2. A genuinely aged account still claims and receives the right amount.
--   3. Idempotent replay → newly_claimed=false, noor_awarded=0.
--   4. Unrecognized day still raises.
--   5. 180/365 still claim without raising and mint 0.
--   6. The age boundary is placed so a real day-7 user cannot be denied.
--   7. NULL created_at is treated as "unknown, not proof of forgery" → allowed.
--
-- auth.uid() is driven the same way cosmetic_milestone_atomic_test.sql does it:
-- set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/milestone_server_verified_test.sql

begin;
select plan(23);

-- ── Seeds ───────────────────────────────────────────────────────────────────
-- f1 ATTACKER  : account created RIGHT NOW, no history, streak forged to 365.
-- f2 LEGITIMATE: account 400 days old, streak 400 — the honest 90-day streaker.
-- f3 BOUNDARY+ : account 5 UTC dates old — the tightest a real day-7 claim can
--                be (day 1 lands on the signup date, so day 7 needs only 6 date
--                boundaries; 5 leaves a full day of slack for clock skew).
-- f4 BOUNDARY- : account 4 UTC dates old — inside the grace, must still fail.
-- f5 NULL AGE  : created_at IS NULL (how every other pgTAP file in this repo
--                seeds auth.users) — must not be denied.
insert into auth.users(id, email, created_at) values
  ('00000000-0000-0000-0000-0000000000f1','msv-attacker@test.local', now()),
  ('00000000-0000-0000-0000-0000000000f2','msv-legit@test.local',    now() - interval '400 days'),
  ('00000000-0000-0000-0000-0000000000f3','msv-edge-pass@test.local',now() - interval '5 days'),
  ('00000000-0000-0000-0000-0000000000f4','msv-edge-fail@test.local',now() - interval '4 days')
on conflict (id) do update set created_at = excluded.created_at;

insert into auth.users(id, email) values
  ('00000000-0000-0000-0000-0000000000f5','msv-nullage@test.local')
on conflict (id) do update set created_at = null;

insert into public.user_profiles(id) values
  ('00000000-0000-0000-0000-0000000000f1'),
  ('00000000-0000-0000-0000-0000000000f2'),
  ('00000000-0000-0000-0000-0000000000f3'),
  ('00000000-0000-0000-0000-0000000000f4'),
  ('00000000-0000-0000-0000-0000000000f5')
on conflict do nothing;

-- Every one of these streak rows is written the way the ATTACKER writes it:
-- a plain client-side upsert. That is the whole point — the column carries no
-- authority, so the test never pretends otherwise.
insert into public.user_streaks(user_id, current_streak, longest_streak) values
  ('00000000-0000-0000-0000-0000000000f1', 365, 365),
  ('00000000-0000-0000-0000-0000000000f2', 400, 400),
  ('00000000-0000-0000-0000-0000000000f3',   7,   7),
  ('00000000-0000-0000-0000-0000000000f4',   7,   7),
  ('00000000-0000-0000-0000-0000000000f5', 400, 400)
on conflict (user_id) do update
  set current_streak = excluded.current_streak,
      longest_streak = excluded.longest_streak;

-- ── (1) THE EXPLOIT IS DEAD ─────────────────────────────────────────────────
set local role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','00000000-0000-0000-0000-0000000000f1','role','authenticated')::text,
  true);

select throws_ok(
  $$ select public.claim_streak_milestone(7) $$,
  NULL, NULL,
  '1a. forged current_streak=365 on a fresh account → claim(7) raises');

select throws_ok(
  $$ select public.claim_streak_milestone(90) $$,
  NULL, NULL,
  '1b. …and claim(90), the 400-Noor prize, raises too');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f1'),
  0,
  '1c. the attacker minted 0 Noor');

-- ── (2) LEGITIMATE CLAIMS STILL WORK ────────────────────────────────────────
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','00000000-0000-0000-0000-0000000000f2','role','authenticated')::text,
  true);

select is(
  (public.claim_streak_milestone(30) ->> 'newly_claimed')::boolean,
  true,
  '2a. 400-day-old account: claim(30) → newly_claimed=true');

select is(
  (public.claim_streak_milestone(7) -> 'noor_awarded')::int,
  40,
  '2b. claim(7) mints the server-derived 40');

select is(
  (public.claim_streak_milestone(14) -> 'noor_awarded')::int,
  75,
  '2c. claim(14) mints the server-derived 75');

select is(
  (public.claim_streak_milestone(90) -> 'noor_awarded')::int,
  400,
  '2d. claim(90) mints the server-derived 400');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f2'),
  150 + 40 + 75 + 400,
  '2e. balance is the sum of the four mintable grants');

-- ── (3) IDEMPOTENT REPLAY ───────────────────────────────────────────────────
select is(
  (public.claim_streak_milestone(30) ->> 'newly_claimed')::boolean,
  false,
  '3a. replay claim(30) → newly_claimed=false');

select is(
  (public.claim_streak_milestone(30) -> 'noor_awarded')::int,
  0,
  '3b. replay claim(30) → noor_awarded=0');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f2'),
  150 + 40 + 75 + 400,
  '3c. balance unchanged by the replay');

-- ── (4) UNRECOGNIZED DAY ────────────────────────────────────────────────────
select throws_ok(
  $$ select public.claim_streak_milestone(42) $$,
  NULL, NULL,
  '4a. claim(42) raises — 42 is not a recognized milestone day');

-- ── (5) RECOGNIZED BUT NON-MINTABLE: 180 / 365 ──────────────────────────────
select lives_ok(
  $$ select public.claim_streak_milestone(180) $$,
  '5a. claim(180) does not raise');

select is(
  (public.claim_streak_milestone(365) ->> 'newly_claimed')::boolean,
  true,
  '5b. claim(365) → newly_claimed=true');

select is(
  (public.claim_streak_milestone(365) -> 'noor_awarded')::int,
  0,
  '5c. claim(365) mints 0 (recognized, no award_noor arm)');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f2'),
  150 + 40 + 75 + 400,
  '5d. 180/365 left the balance untouched');

-- ── (6) THE current_streak GUARD IS STILL ENFORCED ──────────────────────────
-- Age alone must not be sufficient: this account is 400 days old, so it clears
-- the new guard, and must still be rejected on the streak it has not reached.
reset role;
update public.user_streaks set current_streak = 40
  where user_id = '00000000-0000-0000-0000-0000000000f2';
set local role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','00000000-0000-0000-0000-0000000000f2','role','authenticated')::text,
  true);

select throws_ok(
  $$ select public.claim_streak_milestone(60) $$,
  NULL, NULL,
  '6a. aged account with current_streak=40 is still refused day 60');

-- ── (7) THE AGE BOUNDARY DOES NOT DENY REAL USERS ───────────────────────────
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','00000000-0000-0000-0000-0000000000f3','role','authenticated')::text,
  true);

select lives_ok(
  $$ select public.claim_streak_milestone(7) $$,
  '7a. 5-UTC-dates-old account claims day 7 (a real day-7 needs only 6)');

reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','00000000-0000-0000-0000-0000000000f4','role','authenticated')::text,
  true);

select throws_ok(
  $$ select public.claim_streak_milestone(7) $$,
  NULL, NULL,
  '7b. 4-UTC-dates-old account is refused day 7');

-- ── (8) NULL created_at IS NOT TREATED AS EVIDENCE OF FORGERY ───────────────
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','00000000-0000-0000-0000-0000000000f5','role','authenticated')::text,
  true);

select lives_ok(
  $$ select public.claim_streak_milestone(7) $$,
  '8a. NULL created_at → allowed (unknown age is not proof of a forged streak)');

-- ── Deferred grant-ledger assertions (superuser; noor_grants has no SELECT policy)
reset role;
select set_config('request.jwt.claims','',true);

select is(
  (select count(*)::int from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000f1'),
  0,
  '1d. the attacker wrote NO rows to the Noor ledger');

select is(
  (select amount from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000f2'
       and reason_key = 'milestone:90'),
  400,
  '2f. the legitimate milestone:90 grant landed with the server-derived amount');

select is(
  (select count(*)::int from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000f2'
       and reason_key = 'milestone:30'),
  1,
  '3d. exactly ONE milestone:30 ledger row survives the replays');

select * from finish();
rollback;
