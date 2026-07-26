-- award_noor RPC: server-derived Noor grants, idempotent per (user, reason_key).
--
-- Invariants under test:
--   1. The amount is DERIVED SERVER-SIDE from the reason (client never passes an
--      amount) — 'daily' grants exactly 10.
--   2. A grant lands on user_profiles.noor_balance.
--   3. The (user, reason_key) ledger row makes the grant idempotent — calling
--      award_noor again with the SAME reason_key returns 0 and leaves the
--      balance unchanged (this is what stops streak-rebuild farming).
--
-- auth.uid() is driven the same way the project's backend_rls_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_award_noor_test.sql
-- pgTAP style (plan/is/finish), matching the project's pgtap harness.

begin;
select plan(4);

-- Seed an auth user + profile row (default connection = superuser, RLS/guard
-- bypass irrelevant here since the RPC is SECURITY DEFINER). Only
-- user_profiles.id lacks a default, so a bare insert suffices.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000b1', 'awardnoor@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000b1')
on conflict do nothing;

-- Impersonate the seeded user so auth.uid() resolves inside the RPC.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000b1',
    'role', 'authenticated')::text,
  true);

-- (1) First grant returns the server-derived amount for 'daily' (10).
select is(
  public.award_noor('daily', 'daily:2026-07-26'),
  10,
  'first award_noor(daily) returns server-derived amount 10');

-- (2) Balance reflects the grant.
select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000b1'),
  10,
  'noor_balance becomes 10 after first daily grant');

-- (3) Re-granting the SAME reason_key is idempotent → returns 0.
select is(
  public.award_noor('daily', 'daily:2026-07-26'),
  0,
  'duplicate award_noor(daily, same reason_key) returns 0 (idempotent)');

-- (4) Balance is unchanged by the duplicate call.
select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000b1'),
  10,
  'noor_balance stays 10 after idempotent duplicate grant');

reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
