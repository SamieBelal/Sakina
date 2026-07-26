-- Guard regression for the cosmetics economy (Task 2).
--
-- Two invariants:
--   (a) Guarded economy columns on user_profiles (noor_*, equipped_*) are
--       writable ONLY by trusted SECURITY DEFINER RPCs, which set the
--       `app.cosmetics_rpc` GUC to 'on' before writing. A plain UPDATE that
--       touches a guarded column WITHOUT the flag must raise.
--   (b) Direct client (authenticated role) INSERT into the inventory table
--       user_cosmetics is blocked by RLS — there is no insert policy, so all
--       writes must go through SECURITY DEFINER RPCs.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_guard_test.sql
-- pgTAP style (plan/throws_ok/finish), matching the project's pgtap harness.

begin;
select plan(2);

-- Seed an auth user + profile row (default connection = superuser, RLS bypassed
-- for setup). Only user_profiles.id lacks a default, so a bare insert suffices.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000a1', 'guard@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000a1')
on conflict do nothing;

-- (a) Guard fires (flag not set) → guarded-column update throws.
select throws_ok(
  $$ update public.user_profiles set noor_balance = 999999
       where id = '00000000-0000-0000-0000-0000000000a1' $$,
  NULL,
  'guarded noor_balance update throws when app.cosmetics_rpc not set');

-- (b) RLS blocks direct client insert into inventory (no insert policy exists).
select throws_ok(
  $$ set local role authenticated;
     insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
     values ('00000000-0000-0000-0000-0000000000a1',
             'lantern_skin', 'obsidian_gold', 'noor') $$,
  NULL,
  'direct inventory insert blocked by RLS');

select * from finish();
rollback;
