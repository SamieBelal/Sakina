-- grant_cosmetic_iap: server-authoritative, service_role-only à-la-carte skin
-- IAP grant. Ownership binds to the PASSED p_user_id (the RC app_user_id),
-- NEVER auth.uid() — the RPC is callable only by the webhook under service_role.
--
-- Invariants under test:
--   1. Granting a valid à-la-carte SKU (product_id matches catalog
--      iap_product_id, not premium-exclusive) for the passed p_user_id returns
--      granted=true / already_owned=false / item_id, and inserts a
--      user_cosmetics row FOR THAT USER with acquired_via='iap'.
--   2. A ledger row keyed on the transaction id is recorded, with
--      created_inventory=true (this grant created the row — I1).
--   3. Re-granting the SAME transaction id is idempotent: returns granted=false
--      / already_owned=true, and does NOT insert a second inventory row.
--   4. A product_id that matches no catalog iap_product_id raises.
--   5. A product_id that maps to item A but is called with item_id B (mismatch)
--      raises — the server never trusts the caller's item↔product pairing.
--   6. A premium-exclusive SKU (even with an iap_product_id) is rejected.
--   7. A Noor-only SKU (no iap_product_id) is rejected.
--   8. The CLIENT PATH IS CLOSED: the authenticated and anon roles CANNOT
--      execute grant_cosmetic_iap (permission denied / not granted).
--   9. I1: a user who ALREADY owns the skin (via a direct/Noor insert) then
--      gets an IAP grant for the same skin → the ledger records
--      created_inventory=false and the RPC returns already_owned=true (it did
--      not create the inventory row).
--
-- service_role-only RPC (like clawback_consumable_grant): we call the happy
-- path as the default superuser connection (which satisfies the service_role
-- grant in tests) WITHOUT an authenticated jwt — the RPC takes p_user_id, not
-- auth.uid(). The closed-client-path asserts run under `set local role`.
--
-- pgTAP throws_ok subtlety (learned by the existing cosmetics tests): arg2 is
-- the EXPECTED ERROR MESSAGE, not an errcode. When we don't want to pin the
-- exact text we pass NULL (the 3-arg form).
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetic_iap_grant_test.sql

begin;
select plan(13);

-- ---------------------------------------------------------------------------
-- Catalog fixtures: one à-la-carte skin, one premium-exclusive skin (with an
-- iap_product_id to prove the premium check fires regardless), one Noor-only
-- skin (no iap_product_id).
-- ---------------------------------------------------------------------------
insert into public.cosmetic_catalog(item_type,item_id,noor_price,iap_product_id,is_premium_exclusive,active)
values
  ('lantern_skin','obsidian_gold', 200, 'sakina.skin.obsidian', false, true),
  ('lantern_skin','ramadan_royal', null,'sakina.skin.ramadan',  true,  true),
  ('lantern_skin','moonlit_silver',120, null,                   false, true)
on conflict (item_type,item_id) do update
  set iap_product_id       = excluded.iap_product_id,
      is_premium_exclusive = excluded.is_premium_exclusive,
      noor_price           = excluded.noor_price,
      active               = excluded.active;

-- Buyer + a second user who pre-owns the skin (I1 fixture).
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000d1', 'iap-buyer@test.local'),
       ('00000000-0000-0000-0000-0000000000d2', 'iap-preowner@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000d1'),
       ('00000000-0000-0000-0000-0000000000d2')
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- grant_cosmetic_iap — happy path (service_role context: default superuser
-- connection, no authenticated jwt). Ownership binds to the PASSED p_user_id.
-- ---------------------------------------------------------------------------

-- (1) granted=true on first grant, bound to the passed p_user_id.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000d1',
     'obsidian_gold','sakina.skin.obsidian','txn-aaa')
     ->> 'granted')::boolean,
  true,
  'first grant returns granted=true');

-- (2) replay of same txn returns already_owned=true.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000d1',
     'obsidian_gold','sakina.skin.obsidian','txn-aaa')
     ->> 'already_owned')::boolean,
  true,
  'replay of same txn returns already_owned=true');

-- (3) returned item_id echoes the granted item.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000d1',
     'obsidian_gold','sakina.skin.obsidian','txn-aaa')
     ->> 'item_id'),
  'obsidian_gold',
  'grant returns the item_id');

-- (4) inventory row exists FOR THE PASSED USER with acquired_via='iap'.
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000d1'
       and item_type='lantern_skin' and item_id='obsidian_gold'
       and acquired_via='iap'),
  1,
  'inventory row exists for the passed user with acquired_via=iap');

-- (5) exactly ONE inventory row after replays (no double-insert).
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000d1'
       and item_id='obsidian_gold'),
  1,
  'idempotent: no second inventory row on replay');

-- (6) ledger row recorded with created_inventory=true (I1: this grant made it).
select is(
  (select created_inventory from public.cosmetic_iap_grants
     where transaction_id='txn-aaa'
       and user_id='00000000-0000-0000-0000-0000000000d1'
       and item_id='obsidian_gold'),
  true,
  'ledger row recorded with created_inventory=true');

-- ---------------------------------------------------------------------------
-- Rejections
-- ---------------------------------------------------------------------------
-- (7) Unknown product id → raise (no catalog match).
select throws_ok(
  $$ select public.grant_cosmetic_iap('00000000-0000-0000-0000-0000000000d1','obsidian_gold','sakina.tokens_100','txn-unk') $$,
  NULL,
  'unknown product id is rejected');

-- (8) Product/item mismatch (obsidian product with a different item) → raise.
select throws_ok(
  $$ select public.grant_cosmetic_iap('00000000-0000-0000-0000-0000000000d1','moonlit_silver','sakina.skin.obsidian','txn-mis') $$,
  NULL,
  'product/item mismatch is rejected');

-- (9) Premium-exclusive SKU → raise (permanent grant only for à-la-carte).
select throws_ok(
  $$ select public.grant_cosmetic_iap('00000000-0000-0000-0000-0000000000d1','ramadan_royal','sakina.skin.ramadan','txn-prem') $$,
  NULL,
  'premium-exclusive SKU is rejected');

-- (10) Noor-only SKU (no iap_product_id) with any product id → raise.
select throws_ok(
  $$ select public.grant_cosmetic_iap('00000000-0000-0000-0000-0000000000d1','moonlit_silver','sakina.skin.moonlit','txn-noor') $$,
  NULL,
  'Noor-only SKU (no iap_product_id) is rejected');

-- ---------------------------------------------------------------------------
-- I1: pre-owned skin → grant records created_inventory=false, already_owned=true.
-- Buyer d2 already owns obsidian_gold (e.g. earned via Noor/milestone). A later
-- IAP grant must NOT claim it created the row — so a refund can't revoke it.
-- The pre-existing insert goes through the guard flag (RLS has no insert policy).
-- ---------------------------------------------------------------------------
select set_config('app.cosmetics_rpc', 'on', true);
insert into public.user_cosmetics(user_id,item_type,item_id,acquired_via)
  values ('00000000-0000-0000-0000-0000000000d2','lantern_skin','obsidian_gold','noor')
  on conflict (user_id,item_type,item_id) do nothing;
select set_config('app.cosmetics_rpc', 'off', true);

-- (11) IAP grant for the pre-owned skin returns already_owned=true.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000d2',
     'obsidian_gold','sakina.skin.obsidian','txn-preowned')
     ->> 'already_owned')::boolean,
  true,
  'I1: grant of a pre-owned skin returns already_owned=true');

-- (12) The ledger records created_inventory=false for that grant (I1).
select is(
  (select created_inventory from public.cosmetic_iap_grants
     where transaction_id='txn-preowned'),
  false,
  'I1: ledger records created_inventory=false when the row pre-existed');

-- ---------------------------------------------------------------------------
-- Client path is CLOSED: authenticated/anon cannot execute the function.
-- ---------------------------------------------------------------------------
-- (13) authenticated role → permission denied (no execute grant).
set local role authenticated;
select throws_ok(
  $$ select public.grant_cosmetic_iap('00000000-0000-0000-0000-0000000000d1','obsidian_gold','sakina.skin.obsidian','txn-client') $$,
  NULL,
  'authenticated role cannot execute grant_cosmetic_iap (client path closed)');
reset role;

select * from finish();
rollback;
