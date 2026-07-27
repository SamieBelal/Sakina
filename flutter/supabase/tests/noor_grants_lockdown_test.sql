-- public.noor_grants is unforgeable: RLS AND table grants, not RLS alone.
--
-- ── WHY THIS MATTERS ────────────────────────────────────────────────────────
-- noor_grants is the idempotency ledger behind every Noor mint. award_noor
-- dedupes on (user_id, reason_key), so a user who could INSERT into it directly
-- could either block their own future grants or — far worse — forge the
-- server-authoritative activity record that 20260726200700's header explicitly
-- plans to lean on:
--
--     "award_daily_noor() writes noor_grants rows keyed 'daily:'||<server UTC
--      date>, and noor_grants has RLS enabled with no write policy for
--      authenticated, so those rows are unforgeable and cannot be backdated.
--      Once that ledger is older than the longest milestone, this guard can be
--      tightened to count(distinct daily: grants) >= p_day."
--
-- That future tightening is only sound if the ledger is genuinely unforgeable.
-- The table shipped with RLS enabled and ZERO policies (so writes were blocked)
-- but its underlying GRANTs to anon/authenticated were never revoked. RLS was
-- the only thing standing in the way: a single stray
-- `alter table ... disable row level security`, or one policy added for an
-- unrelated read, would have exposed a forgeable economy ledger.
-- 20260726201100 revokes the grants so the lockdown is defense in depth.
--
-- ── WHAT IS ASSERTED ────────────────────────────────────────────────────────
--   1-8.   anon and authenticated hold NO select/insert/update/delete grant.
--   9-10.  RLS is still enabled and the table still has zero policies — the
--          revoke is an ADDITIONAL layer, not a replacement for either.
--   11.    service_role keeps its grants (the webhook/admin path is untouched).
--   12.    A direct insert as authenticated is refused.
--   13-16. The SECURITY DEFINER mint path still works end to end: award_noor
--          returns the server-derived amount, writes the ledger row, credits the
--          balance, and stays idempotent per reason_key.
--   17-18. claim_streak_milestone — which mints through award_noor inside its
--          own transaction — still awards and still writes its ledger row.
--
-- 13-18 are the ones that would catch an over-broad revoke: SECURITY DEFINER
-- functions execute as their owner, so revoking from the CALLER roles must not
-- touch them. If it did, these fail loudly.
--
-- NOTE FOR CI/LOCAL RUNS: scripts/restore_local_role_grants.sql re-grants the
-- client roles after migrations (the local Supabase image no longer does it,
-- unlike the hosted platform) and therefore has to re-apply this revoke. If
-- assertions 1-8 fail while the migration is clearly present, that file has
-- drifted — not this test.
--
-- Run via:  psql "$DATABASE_URL" -f supabase/tests/noor_grants_lockdown_test.sql

begin;
select plan(18);

-- ── 1-8: no client-role grants remain ───────────────────────────────────────
select is(has_table_privilege('authenticated', 'public.noor_grants', 'insert'),
  false, 'authenticated cannot INSERT into noor_grants');
select is(has_table_privilege('authenticated', 'public.noor_grants', 'update'),
  false, 'authenticated cannot UPDATE noor_grants');
select is(has_table_privilege('authenticated', 'public.noor_grants', 'delete'),
  false, 'authenticated cannot DELETE from noor_grants');
select is(has_table_privilege('authenticated', 'public.noor_grants', 'select'),
  false, 'authenticated cannot SELECT noor_grants (nothing reads it client-side)');

select is(has_table_privilege('anon', 'public.noor_grants', 'insert'),
  false, 'anon cannot INSERT into noor_grants');
select is(has_table_privilege('anon', 'public.noor_grants', 'update'),
  false, 'anon cannot UPDATE noor_grants');
select is(has_table_privilege('anon', 'public.noor_grants', 'delete'),
  false, 'anon cannot DELETE from noor_grants');
select is(has_table_privilege('anon', 'public.noor_grants', 'select'),
  false, 'anon cannot SELECT noor_grants');

-- ── 9-10: the original layers are still in place ────────────────────────────
select is(
  (select relrowsecurity from pg_class
     where oid = 'public.noor_grants'::regclass),
  true,
  'noor_grants still has RLS enabled (the revoke ADDS a layer, it does not replace one)');

select is(
  (select count(*)::int from pg_policy
     where polrelid = 'public.noor_grants'::regclass),
  0,
  'noor_grants still has zero policies (no client read/write path by design)');

-- ── 11: the trusted role is unaffected ──────────────────────────────────────
select is(has_table_privilege('service_role', 'public.noor_grants', 'select'),
  true, 'service_role keeps its noor_grants grants (webhook/admin path unchanged)');

-- ── 12: a direct client write is refused ────────────────────────────────────
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000c1', 'noorlockdown@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000c1')
on conflict do nothing;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c1',
    'role', 'authenticated')::text,
  true);

select throws_ok(
  $$ insert into public.noor_grants(user_id, reason_key, amount)
     values ('00000000-0000-0000-0000-0000000000c1', 'daily:forged', 9999) $$,
  '42501',
  NULL,
  'a direct insert as authenticated is refused (permission denied, before RLS)');

reset role;

-- ── 13-16: the SECURITY DEFINER mint path is untouched ──────────────────────
-- award_noor's EXECUTE is service_role-only since 20260726200600, so this runs
-- on the default owner connection — the privilege position of the SECURITY
-- DEFINER callers that are now the only ways in. Same rationale as
-- cosmetics_award_noor_test.sql.
select is(
  public.award_noor('daily', 'daily:noor-lockdown'),
  10,
  'award_noor still mints the server-derived amount through SECURITY DEFINER');

select is(
  (select amount from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000c1'
       and reason_key = 'daily:noor-lockdown'),
  10,
  'award_noor still writes its ledger row (the revoke did not break the owner path)');

select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000c1'),
  10,
  'the mint still lands on noor_balance');

select is(
  public.award_noor('daily', 'daily:noor-lockdown'),
  0,
  'the ledger still dedupes a repeat grant on the same reason_key');

select set_config('request.jwt.claims', '', true);

-- ── 17-18: claim_streak_milestone still mints ───────────────────────────────
-- Aged account + streak, matching milestone_server_verified_test's legitimate
-- fixture, so the server-verified age guard is satisfied.
insert into auth.users(id, email, created_at)
values ('00000000-0000-0000-0000-0000000000c2', 'noorlockdown-ms@test.local',
        now() - interval '400 days')
on conflict (id) do update set created_at = excluded.created_at;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000c2')
on conflict do nothing;
insert into public.user_streaks(user_id, current_streak, longest_streak)
values ('00000000-0000-0000-0000-0000000000c2', 400, 400)
on conflict (user_id) do update
  set current_streak = excluded.current_streak,
      longest_streak = excluded.longest_streak;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c2',
    'role', 'authenticated')::text,
  true);

select is(
  (public.claim_streak_milestone(7) -> 'noor_awarded')::int,
  40,
  'claim_streak_milestone still mints milestone Noor through award_noor');

reset role;

select is(
  (select amount from public.noor_grants
     where user_id = '00000000-0000-0000-0000-0000000000c2'
       and reason_key = 'milestone:7'),
  40,
  'the milestone mint still writes its noor_grants ledger row');

select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
