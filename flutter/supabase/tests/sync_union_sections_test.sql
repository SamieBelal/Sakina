-- sync_all_user_data() must carry BOTH lineages of sections at once.
--
-- WHY THIS TEST EXISTS
--   sync_all_user_data() is a single monolithic function returning one big
--   jsonb_build_object. Two PRs each shipped a full `create or replace`
--   re-emitted from the SAME older base, so the higher-timestamped migration
--   silently deleted the other's sections:
--     * 20260726000300 (PR #61, cosmetics) added noor / equipped / cosmetics
--     * 20260726200300 (PR #62, One Ship)  added six `profile` keys
--   20260726200400 unions them. This test is the tripwire: it fails loudly the
--   next time someone re-emits the function from a stale base and drops a
--   section from either lineage.
--
-- Invariants under test:
--   1. Every expected TOP-LEVEL key is present (base sections + cosmetics).
--   2. The `profile` object carries all six One-Ship keys.
--   3. A value from each lineage round-trips (not just key presence).
--
-- auth.uid() is driven the same way cosmetics_sync_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
-- Cosmetics columns are RPC-only (cosmetics_guard), so they are seeded as the
-- owner connection with the app.cosmetics_rpc GUC on.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/sync_union_sections_test.sql

begin;
select plan(26);

-- Seed an auth user + profile row.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000c2', 'syncunion@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000c2')
on conflict do nothing;

-- Cosmetics-lineage seed (guarded columns -> owner + guard flag).
select set_config('app.cosmetics_rpc', 'on', true);
update public.user_profiles
   set noor_balance          = 42,
       equipped_lantern_skin = 'obsidian_gold'
 where id = '00000000-0000-0000-0000-0000000000c2';
select set_config('app.cosmetics_rpc', '', true);

-- One-Ship-lineage seed (plain profile columns).
update public.user_profiles
   set first_problem_text = 'anxious about rizq',
       weekly_pool_used   = 3
 where id = '00000000-0000-0000-0000-0000000000c2';

insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
values ('00000000-0000-0000-0000-0000000000c2', 'lantern_skin', 'obsidian_gold', 'noor')
on conflict do nothing;

-- Impersonate the seeded user so auth.uid() resolves inside the RPC.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c2',
    'role', 'authenticated')::text,
  true);

-- (1-17) Every top-level section from BOTH lineages is present.
--   Base sections (from 20260722000000 §6, carried through both re-emits)
--   followed by the three cosmetics sections added by 20260726000300.
with r as (select public.sync_all_user_data() as j)
select ok(
  r.j ? k,
  format('sync_all_user_data() top-level key present: %s', k))
from r, unnest(array[
  'xp',
  'tokens',
  'streak',
  'daily_rewards',
  'checkin_history',
  'reflections',
  'built_duas',
  'card_collection',
  'profile',
  'achievements',
  'discovery_results',
  'daily_usage',
  'daily_answers',
  'quest_progress',
  'noor',
  'equipped',
  'cosmetics'
]) as k;

-- (18-23) The six One-Ship keys survive inside the `profile` object.
--   (weekly_pool_reset_at is deliberately server-internal and NOT exposed.)
with r as (select public.sync_all_user_data() -> 'profile' as p)
select ok(
  r.p ? k,
  format('sync_all_user_data() -> profile key present: %s', k))
from r, unnest(array[
  'acquisition_promise',
  'first_problem_text',
  'onboarding_flow',
  'free_tier_cohort',
  'weekly_pool_used',
  'weekly_pool_week_start'
]) as k;

-- (24) Cosmetics lineage: noor balance round-trips.
select is(
  (public.sync_all_user_data() -> 'noor' ->> 'balance')::int,
  42,
  'sync_all_user_data() -> noor -> balance = 42');

-- (25) Cosmetics lineage: equipped lantern skin round-trips.
select is(
  public.sync_all_user_data() -> 'equipped' ->> 'lantern_skin',
  'obsidian_gold',
  'sync_all_user_data() -> equipped -> lantern_skin = obsidian_gold');

-- (26) One-Ship lineage: a profile key round-trips (not just key presence).
select is(
  public.sync_all_user_data() -> 'profile' ->> 'first_problem_text',
  'anxious about rizq',
  'sync_all_user_data() -> profile -> first_problem_text round-trips');

reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
