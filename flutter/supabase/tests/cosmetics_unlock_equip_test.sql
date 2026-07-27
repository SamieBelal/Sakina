-- unlock_cosmetic + equip_cosmetic RPCs: server-authoritative cosmetics.
--
-- unlock_cosmetic invariants under test:
--   1. Unlocking a purchasable item returns true, deducts noor_balance by the
--      catalog price, and records an inventory row in user_cosmetics.
--   2. Unlocking an ALREADY-OWNED item returns true but does NOT charge again
--      (balance stays put) — idempotent, no double-spend.
--   3. Unlocking with insufficient funds raises 'insufficient noor'.
--
-- equip_cosmetic invariants under test:
--   4. Equipping an OWNED lantern skin returns true and sets
--      user_profiles.equipped_lantern_skin.
--   5. Equipping a NOT-OWNED item raises 'cannot equip unowned item'.
--
-- auth.uid() is driven the same way cosmetics_award_noor_test.sql does it:
--   set local role authenticated + request.jwt.claims with a 'sub' uuid.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetics_unlock_equip_test.sql
-- pgTAP style (plan/is/finish), matching the project's pgtap harness.

begin;
select plan(9);

-- Seed a purchasable catalog row.
insert into public.cosmetic_catalog(item_type, item_id, noor_price, active)
values ('lantern_skin', 'obsidian_gold', 200, true)
on conflict (item_type, item_id) do update
  set noor_price = excluded.noor_price, active = excluded.active;

-- Buyer: enough Noor to afford it (balance 220).
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000c1', 'unlock-buyer@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000c1')
on conflict do nothing;

-- Pauper: cannot afford it (balance 10).
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000c2', 'unlock-pauper@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000c2')
on conflict do nothing;

-- Seed starting balances as the owner (superuser), flipping the guard GUC so
-- the RPC-only trigger permits the direct write.
select set_config('app.cosmetics_rpc', 'on', true);
update public.user_profiles set noor_balance = 220
  where id = '00000000-0000-0000-0000-0000000000c1';
update public.user_profiles set noor_balance = 10
  where id = '00000000-0000-0000-0000-0000000000c2';
select set_config('app.cosmetics_rpc', 'off', true);

-- ---------------------------------------------------------------------------
-- unlock_cosmetic — buyer path
-- ---------------------------------------------------------------------------
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c1',
    'role', 'authenticated')::text,
  true);

-- (1) First unlock returns true.
select is(
  public.unlock_cosmetic('lantern_skin', 'obsidian_gold'),
  true,
  'first unlock_cosmetic returns true');

-- (2) Balance dropped from 220 to 20 (charged the 200 price).
select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000c1'),
  20,
  'noor_balance becomes 20 after unlock (220 - 200)');

-- (3) Inventory row now exists.
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id = '00000000-0000-0000-0000-0000000000c1'
       and item_type = 'lantern_skin' and item_id = 'obsidian_gold'),
  1,
  'inventory row exists after unlock');

-- (4) Second unlock of the SAME item still returns true (already owned).
select is(
  public.unlock_cosmetic('lantern_skin', 'obsidian_gold'),
  true,
  'second unlock_cosmetic (already owned) returns true');

-- (5) Balance STAYS 20 — no second charge.
select is(
  (select noor_balance from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000c1'),
  20,
  'noor_balance stays 20 on already-owned re-unlock (no double charge)');

-- ---------------------------------------------------------------------------
-- unlock_cosmetic — insufficient funds path (pauper)
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c2',
    'role', 'authenticated')::text,
  true);

-- (6) Pauper with balance 10 < price 200 → raises 'insufficient noor'.
select throws_ok(
  $$ select public.unlock_cosmetic('lantern_skin', 'obsidian_gold') $$,
  'insufficient noor',
  'unlock_cosmetic raises insufficient noor when balance < price');

-- ---------------------------------------------------------------------------
-- equip_cosmetic — buyer (who now owns obsidian_gold) equips it
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000c1',
    'role', 'authenticated')::text,
  true);

-- (7) Equipping the owned obsidian_gold skin returns true.
select is(
  public.equip_cosmetic('lantern_skin', 'obsidian_gold'),
  true,
  'equip_cosmetic returns true for an owned skin');

-- (8) equipped_lantern_skin is now set to obsidian_gold.
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id = '00000000-0000-0000-0000-0000000000c1'),
  'obsidian_gold',
  'equipped_lantern_skin is set to obsidian_gold after equip');

-- (9) Equipping a NOT-owned skin raises 'cannot equip unowned item'.
select throws_ok(
  $$ select public.equip_cosmetic('lantern_skin', 'crystal_star') $$,
  'cannot equip unowned item',
  'equip_cosmetic raises when equipping an unowned item');

reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
