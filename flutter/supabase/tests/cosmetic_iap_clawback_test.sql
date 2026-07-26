-- clawback_cosmetic_iap: refund/revoke path for à-la-carte skin IAP.
--
-- Invariants under test:
--   1. Refunding a granted transaction (created_inventory=true) returns
--      status='revoked', removes the user_cosmetics row, and sets revoked_at.
--   2. If the refunded skin was EQUIPPED, the equipped_lantern_skin slot resets
--      to the default 'classic_gold'.
--   3. If the refunded skin was NOT equipped, the equipped slot is untouched.
--   4. Refunding the SAME transaction twice is idempotent → status=
--      'already_processed', no further mutation.
--   5. Refunding an unknown transaction is a safe no-op → status='not_found'.
--   6. I1: refunding a grant whose created_inventory=false (the user already
--      owned the skin via Noor/milestone) leaves ownership INTACT but still
--      marks the ledger revoked.
--
-- Both RPCs are service_role-only (like clawback_consumable_grant), so we call
-- them as the default superuser connection (which satisfies the service_role
-- grant in tests) WITHOUT setting an authenticated jwt — grant_cosmetic_iap
-- takes an explicit p_user_id and clawback_cosmetic_iap takes the txn id.
--
-- Run via:  psql "$SUPABASE_DB_URL" -f supabase/tests/cosmetic_iap_clawback_test.sql

begin;
-- NOTE: the plan document says plan(11) but its own Task 2 test body contains 12
-- `select is/isnt` assertions (a pre-refund equipped sanity check + subtests
-- 1-11). plan(12) is the count reconciled against the actual assertions so the
-- suite reports fully green ("all 12 tests").
select plan(12);

insert into public.cosmetic_catalog(item_type,item_id,noor_price,iap_product_id,is_premium_exclusive,active)
values ('lantern_skin','obsidian_gold', 200, 'sakina.skin.obsidian', false, true)
on conflict (item_type,item_id) do update
  set iap_product_id = excluded.iap_product_id, active = excluded.active;

insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000e1', 'clawback-buyer@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000e1')
on conflict do nothing;

-- Grant obsidian_gold to the buyer (service_role context — default connection,
-- explicit p_user_id), then equip it AS the buyer (equip_cosmetic is the
-- authenticated client path).
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000e1',
  'obsidian_gold','sakina.skin.obsidian','txn-refund-1');
set local role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub',  '00000000-0000-0000-0000-0000000000e1',
    'role', 'authenticated')::text,
  true);
select public.equip_cosmetic('lantern_skin','obsidian_gold');
reset role;
select set_config('request.jwt.claims', '', true);

-- Sanity: equipped is obsidian_gold before the refund.
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id='00000000-0000-0000-0000-0000000000e1'),
  'obsidian_gold',
  'pre-refund: obsidian_gold is equipped');

-- (1) Refund returns status='revoked'.
select is(
  (public.clawback_cosmetic_iap('txn-refund-1', now()) ->> 'status'),
  'revoked',
  'refund returns status=revoked');

-- (2) Ownership row removed (created_inventory was true).
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000e1'
       and item_id='obsidian_gold'),
  0,
  'refund removes the ownership row');

-- (3) Equipped slot reset to default classic_gold.
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id='00000000-0000-0000-0000-0000000000e1'),
  'classic_gold',
  'refund resets equipped slot to classic_gold');

-- (4) Ledger row marked revoked.
select isnt(
  (select revoked_at from public.cosmetic_iap_grants where transaction_id='txn-refund-1'),
  null,
  'ledger revoked_at is set');

-- (5) Idempotent second refund → already_processed.
select is(
  (public.clawback_cosmetic_iap('txn-refund-1', now()) ->> 'status'),
  'already_processed',
  'second refund is idempotent (already_processed)');

-- (6) Unknown transaction → not_found no-op.
select is(
  (public.clawback_cosmetic_iap('txn-does-not-exist', now()) ->> 'status'),
  'not_found',
  'refund of unknown txn is a safe no-op');

-- ---------------------------------------------------------------------------
-- (7)+(8): non-equipped refund leaves the equipped slot untouched.
-- Buyer2 owns obsidian_gold but has classic_gold equipped; refunding obsidian
-- must NOT change the (already-default) equipped slot AND must remove ownership.
-- ---------------------------------------------------------------------------
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000e2', 'clawback-buyer2@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000e2')
on conflict do nothing;

select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000e2',
  'obsidian_gold','sakina.skin.obsidian','txn-refund-2');

select public.clawback_cosmetic_iap('txn-refund-2', now());

-- (7) Ownership removed for buyer2.
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000e2'
       and item_id='obsidian_gold'),
  0,
  'non-equipped refund still removes ownership');

-- (8) Equipped slot stays classic_gold (was never obsidian).
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id='00000000-0000-0000-0000-0000000000e2'),
  'classic_gold',
  'non-equipped refund leaves equipped slot at classic_gold');

-- (9) grant_cosmetic_iap can be re-driven after a refund with a NEW txn id
--     (a re-purchase) — proves the refund didn't poison future grants.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000e2',
     'obsidian_gold','sakina.skin.obsidian','txn-refund-2b')
     ->> 'granted')::boolean,
  true,
  're-purchase after refund grants again with a new txn id');

-- ---------------------------------------------------------------------------
-- (10)+(11): I1 — refund of a grant that did NOT create inventory.
-- Buyer3 already owns obsidian_gold (earned via Noor). A later IAP grant records
-- created_inventory=false. Refunding that grant must LEAVE ownership intact
-- (the user keeps the separately-earned skin) but still mark the ledger revoked.
-- ---------------------------------------------------------------------------
insert into auth.users(id, email)
values ('00000000-0000-0000-0000-0000000000e3', 'clawback-preowner@test.local')
on conflict do nothing;
insert into public.user_profiles(id)
values ('00000000-0000-0000-0000-0000000000e3')
on conflict do nothing;

-- Pre-own the skin (guarded write; RLS has no insert policy).
select set_config('app.cosmetics_rpc', 'on', true);
insert into public.user_cosmetics(user_id,item_type,item_id,acquired_via)
  values ('00000000-0000-0000-0000-0000000000e3','lantern_skin','obsidian_gold','noor')
  on conflict (user_id,item_type,item_id) do nothing;
select set_config('app.cosmetics_rpc', 'off', true);

-- IAP grant for the pre-owned skin → created_inventory=false.
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000e3',
  'obsidian_gold','sakina.skin.obsidian','txn-refund-3');

-- Refund it.
select public.clawback_cosmetic_iap('txn-refund-3', now());

-- (10) Ownership INTACT (created_inventory was false → nothing revoked).
select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000e3'
       and item_id='obsidian_gold'),
  1,
  'I1: refund of a non-creating grant leaves the separately-earned skin intact');

-- (11) Ledger still marked revoked (idempotency + audit).
select isnt(
  (select revoked_at from public.cosmetic_iap_grants where transaction_id='txn-refund-3'),
  null,
  'I1: ledger revoked_at is set even when nothing was revoked');

select * from finish();
rollback;
