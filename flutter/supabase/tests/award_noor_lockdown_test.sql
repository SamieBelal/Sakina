-- award_noor lockdown: the client may no longer mint Noor of its own choosing.
--
-- THE EXPLOIT THIS CLOSES
--   `award_noor(p_reason text, p_reason_key text)` was `grant execute … to
--   authenticated`. It derives the AMOUNT from the client-supplied p_reason and
--   dedupes on the client-supplied p_reason_key — but a dedupe key the caller
--   picks is not a dedupe key. Reproduced against the local DB as role
--   `authenticated`:
--       award_noor('milestone:90','k1') → 400
--       award_noor('milestone:90','k2') → 400   (any fresh key mints again)
--       … → noor_balance 1600
--       unlock_cosmetic('lantern_skin','crystal_star') → t
--   `crystal_star` carries BOTH noor_price = 300 AND iap_product_id
--   'sakina.skin.crystal' (an à-la-carte real-money SKU), so forged Noor buys
--   paid content. Direct revenue loss.
--
-- THE FIX UNDER TEST
--   1. EXECUTE on award_noor is revoked from authenticated/anon/public. It stays
--      reachable by service_role and by SECURITY DEFINER callers (which run as
--      the owner) — `claim_streak_milestone` must keep minting.
--   2. `award_daily_noor()` is the ONE client-callable earn path. It takes no
--      arguments: both the reason ('daily') and the dedupe key
--      ('daily:<server UTC date>') are derived server-side, and it mints only if
--      the caller actually has a `user_checkin_history` row for the server's
--      current UTC date.
--   3. There is deliberately NO award_quest_noor — see the migration header;
--      quest completion has no server-authoritative record to verify against.
--
-- auth.uid() is driven the same way cosmetics_award_noor_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/award_noor_lockdown_test.sql

begin;
select plan(10);

-- ── Fixtures ────────────────────────────────────────────────────────────────
-- f1: has today's checkin + a high streak (the legitimate earner).
-- f2: has NO checkin today (the forger).
insert into auth.users(id, email) values
  ('00000000-0000-0000-0000-0000000000f1', 'noorlockdown1@test.local'),
  ('00000000-0000-0000-0000-0000000000f2', 'noorlockdown2@test.local')
on conflict do nothing;
insert into public.user_profiles(id) values
  ('00000000-0000-0000-0000-0000000000f1'),
  ('00000000-0000-0000-0000-0000000000f2')
on conflict do nothing;
insert into public.user_streaks(user_id, current_streak)
values ('00000000-0000-0000-0000-0000000000f1', 400)
on conflict (user_id) do update set current_streak = excluded.current_streak;

-- f1's checkin for the server's current UTC date, shaped like the live
-- muḥāsabah path (q1='discover', q2/q3/q4 empty — see CLAUDE.md).
insert into public.user_checkin_history
  (user_id, checked_in_at, q1, q2, q3, q4, name_returned, name_arabic)
values
  ('00000000-0000-0000-0000-0000000000f1',
   ((now() at time zone 'utc')::date + time '12:00') at time zone 'utc',
   'discover', '', '', '', 'As-Sabur', 'الصبور');

-- f2 has a checkin YESTERDAY only — proves the check is date-scoped, not
-- "has ever checked in".
insert into public.user_checkin_history
  (user_id, checked_in_at, q1, q2, q3, q4, name_returned, name_arabic)
values
  ('00000000-0000-0000-0000-0000000000f2',
   (((now() at time zone 'utc')::date - 1) + time '12:00') at time zone 'utc',
   'discover', '', '', '', 'As-Sabur', 'الصبور');

-- ── (1) authenticated can no longer call award_noor directly ────────────────
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000f1',
    'role', 'authenticated')::text,
  true);

select throws_ok(
  $$ select public.award_noor('milestone:90', 'forged-key-1') $$,
  '42501',
  null,
  '1a. award_noor(milestone:90) → permission denied for role authenticated');

select throws_ok(
  $$ select public.award_noor('daily', 'forged-key-2') $$,
  '42501',
  null,
  '1b. award_noor(daily) → permission denied for role authenticated too');

-- ── (2) the SECURITY DEFINER path is intact: claim_streak_milestone mints ───
select is(
  (public.claim_streak_milestone(90) ->> 'noor_awarded')::int,
  400,
  '2a. claim_streak_milestone(90) still mints 400 through the revoked function');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f1'),
  400,
  '2b. the milestone mint landed on noor_balance');

-- ── (3) award_daily_noor(): mints exactly once for a user with today's checkin
select is(
  public.award_daily_noor(),
  10,
  '3a. award_daily_noor() mints the server-derived daily amount (10)');

select is(
  public.award_daily_noor(),
  0,
  '3b. award_daily_noor() returns 0 on replay (server-derived dedupe key)');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f1'),
  410,
  '3c. balance moved by exactly one daily grant despite two calls');

-- ── (4) THE ANTI-FORGERY ASSERTION: no checkin today → nothing minted ───────
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000f2',
    'role', 'authenticated')::text,
  true);

select is(
  public.award_daily_noor(),
  0,
  '4a. award_daily_noor() mints NOTHING for a user with no checkin today');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000f2'),
  0,
  '4b. that user''s balance is untouched');

reset role;

select is(
  (select count(*)::int from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000f2'),
  0,
  '4c. and no ledger row was written for them');

reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
