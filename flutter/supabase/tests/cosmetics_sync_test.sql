-- sync_all_user_data extension: the batch-sync RPC must now surface the three
-- cosmetics-economy sections (noor, equipped, cosmetics) WITHOUT dropping any
-- existing section of its jsonb payload.
--
-- Invariants under test:
--   1. result -> 'noor' ->> 'balance' reflects user_profiles.noor_balance.
--   2. result -> 'equipped' ->> 'lantern_skin' reflects the equipped skin.
--   3. result -> 'cosmetics' is a jsonb array of the user's user_cosmetics rows.
--
-- auth.uid() is driven the same way award_noor's fixture does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
-- Guarded columns (noor_balance / equipped_lantern_skin) are seeded as the
-- owner connection with the guard GUC flag on, then we auth as the user.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_sync_test.sql

begin;
select plan(3);

-- Seed an auth user + profile row.
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000c1', 'cosmsync@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000c1')
on conflict do nothing;

-- Seed the guarded columns as owner with the cosmetics-RPC guard flag on.
select set_config('app.cosmetics_rpc', 'on', true);
update public.user_profiles
   set noor_balance          = 10,
       equipped_lantern_skin = 'obsidian_gold'
 where id = '00000000-0000-0000-0000-0000000000c1';
select set_config('app.cosmetics_rpc', '', true);

-- One owned cosmetic row.
insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
values ('00000000-0000-0000-0000-0000000000c1', 'lantern_skin', 'obsidian_gold', 'noor')
on conflict do nothing;

-- Impersonate the seeded user so auth.uid() resolves inside the RPC.
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c1',
    'role', 'authenticated')::text,
  true);

-- (1) noor balance surfaced.
select is(
  (public.sync_all_user_data() -> 'noor' ->> 'balance')::int,
  10,
  'sync_all_user_data() -> noor -> balance = 10');

-- (2) equipped lantern skin surfaced.
select is(
  public.sync_all_user_data() -> 'equipped' ->> 'lantern_skin',
  'obsidian_gold',
  'sync_all_user_data() -> equipped -> lantern_skin = obsidian_gold');

-- (3) cosmetics is an array with the one owned row.
select is(
  jsonb_array_length(public.sync_all_user_data() -> 'cosmetics'),
  1,
  'sync_all_user_data() -> cosmetics has 1 entry');

reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
