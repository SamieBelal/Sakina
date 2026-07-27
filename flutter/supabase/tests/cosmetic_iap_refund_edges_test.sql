-- À-la-carte cosmetic IAP refund edge cases (I-1, I-2, N-1).
--
-- These are the "Pre-store-enablement follow-ups" from the independent /review
-- of Lane A-bis, recorded in
-- docs/superpowers/plans/2026-07-25-lantern-cosmetics-01b-iap-grant-webhook.md.
-- They are P1: they MUST be closed before the skin SKUs go live on the store,
-- because each one either destroys ownership the user legitimately holds or
-- silently drops a refund.
--
-- I-1  created_inventory tracks ROW CREATION, not entitlement PROVENANCE.
--      (a) an IAP creates the ownership row, the row's provenance later becomes
--          non-IAP (milestone/Noor/seasonal) → refunding the IAP must NOT delete
--          the separately-earned ownership.
--      (b) IAP-A creates the row, IAP-B for the SAME skin records
--          created_inventory=false → refunding A must NOT delete ownership while
--          B is paid-for and unrefunded; refunding B as well MUST then remove it
--          (otherwise both purchases are refunded and the skin is kept for free).
--
-- I-2  A refund that arrives BEFORE its grant used to be permanently lost:
--      clawback returned not_found and wrote nothing, so a later grant retry
--      (RevenueCat redelivering the purchase) re-granted the skin AFTER the
--      refund. The clawback now writes a TOMBSTONE ledger row that the grant
--      path consults, making the two order-independent.
--
-- N-1  REFUND_REVERSED (Apple reinstating a refunded purchase) was unhandled.
--      A naive re-grant cannot fix it — the revoked ledger row short-circuits
--      grant_cosmetic_iap — so reinstatement is its own RPC.
--
-- All three RPCs are service_role-only, so (like cosmetic_iap_clawback_test)
-- these run on the default superuser connection with no authenticated jwt.
--
-- Run via:  psql "$DATABASE_URL" -f supabase/tests/cosmetic_iap_refund_edges_test.sql

begin;
select plan(39);

-- ---------------------------------------------------------------- fixtures --
insert into public.cosmetic_catalog(item_type,item_id,noor_price,iap_product_id,is_premium_exclusive,active)
values ('lantern_skin','obsidian_gold', 200, 'sakina.skin.obsidian', false, true)
on conflict (item_type,item_id) do update
  set iap_product_id = excluded.iap_product_id, active = excluded.active;

insert into auth.users(id, email) values
  ('00000000-0000-0000-0000-0000000000f1', 'edge-provenance@test.local'),
  ('00000000-0000-0000-0000-0000000000f2', 'edge-two-iaps@test.local'),
  ('00000000-0000-0000-0000-0000000000f3', 'edge-tombstone@test.local'),
  ('00000000-0000-0000-0000-0000000000f4', 'edge-reinstate@test.local'),
  ('00000000-0000-0000-0000-0000000000f5', 'edge-reinstate-noop@test.local')
on conflict do nothing;

insert into public.user_profiles(id) values
  ('00000000-0000-0000-0000-0000000000f1'),
  ('00000000-0000-0000-0000-0000000000f2'),
  ('00000000-0000-0000-0000-0000000000f3'),
  ('00000000-0000-0000-0000-0000000000f4'),
  ('00000000-0000-0000-0000-0000000000f5')
on conflict do nothing;

-- ===========================================================================
-- I-1 (a): the IAP created the row, but its provenance is now non-IAP.
-- ===========================================================================
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f1',
  'obsidian_gold','sakina.skin.obsidian','txn-edge-a1');

select is(
  (select created_inventory from public.cosmetic_iap_grants where transaction_id='txn-edge-a1'),
  true,
  'I1a setup: the grant created the ownership row');

-- The user subsequently earns the same skin through a non-IAP path. Today's
-- unlock_cosmetic/milestone inserts are ON CONFLICT DO NOTHING so they cannot
-- upgrade an existing row's provenance; this writes the end state those paths
-- are expected to produce once they do, which is precisely the state the guard
-- has to survive.
select set_config('app.cosmetics_rpc', 'on', true);
update public.user_cosmetics set acquired_via = 'milestone'
 where user_id = '00000000-0000-0000-0000-0000000000f1'
   and item_type = 'lantern_skin' and item_id = 'obsidian_gold';
select set_config('app.cosmetics_rpc', 'off', true);

select is(
  (public.clawback_cosmetic_iap('txn-edge-a1', now()) ->> 'ownership_revoked'),
  'false',
  'I1a: refund reports ownership_revoked=false when provenance is no longer iap');

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f1' and item_id='obsidian_gold'),
  1,
  'I1a: refund does NOT delete separately-earned ownership');

select isnt(
  (select revoked_at from public.cosmetic_iap_grants where transaction_id='txn-edge-a1'),
  null,
  'I1a: ledger is still marked revoked');

select is(
  (select revoked_inventory from public.cosmetic_iap_grants where transaction_id='txn-edge-a1'),
  false,
  'I1a: ledger records that this clawback removed no inventory');

-- ===========================================================================
-- I-1 (b): two IAPs for the same skin. Refunding one must not revoke the other's
-- ownership; refunding BOTH must.
-- ===========================================================================
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f2',
  'obsidian_gold','sakina.skin.obsidian','txn-edge-b1');
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f2',
  'obsidian_gold','sakina.skin.obsidian','txn-edge-b2');

select is(
  (select created_inventory from public.cosmetic_iap_grants where transaction_id='txn-edge-b2'),
  false,
  'I1b setup: the second grant did not create the row');

select is(
  (public.clawback_cosmetic_iap('txn-edge-b1', now()) ->> 'ownership_revoked'),
  'false',
  'I1b: refunding IAP-A reports ownership_revoked=false while IAP-B stands');

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f2' and item_id='obsidian_gold'),
  1,
  'I1b: refunding IAP-A leaves ownership intact (IAP-B is paid for)');

select isnt(
  (select revoked_at from public.cosmetic_iap_grants where transaction_id='txn-edge-b1'),
  null,
  'I1b: IAP-A ledger is marked revoked');

-- Now refund the second purchase too. Nothing is paid for any more, and the row
-- is IAP-provenance, so ownership must go — otherwise a double refund keeps the
-- skin for free.
select is(
  (public.clawback_cosmetic_iap('txn-edge-b2', now()) ->> 'ownership_revoked'),
  'true',
  'I1b: refunding the LAST unrevoked IAP reports ownership_revoked=true');

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f2' and item_id='obsidian_gold'),
  0,
  'I1b: refunding every IAP for the skin does remove ownership');

-- ===========================================================================
-- I-2: refund arrives BEFORE the grant.
-- ===========================================================================
select is(
  (public.clawback_cosmetic_iap('txn-edge-early', now()) ->> 'status'),
  'not_found',
  'I2: an unmatched refund still reports not_found (unchanged contract)');

select is(
  (public.clawback_cosmetic_iap('txn-edge-early2', now()) ->> 'tombstoned'),
  'true',
  'I2: an unmatched refund reports that it wrote a tombstone');

select is(
  (select tombstone from public.cosmetic_iap_grants where transaction_id='txn-edge-early'),
  true,
  'I2: a tombstone ledger row exists for the unmatched refund');

select isnt(
  (select revoked_at from public.cosmetic_iap_grants where transaction_id='txn-edge-early'),
  null,
  'I2: the tombstone is already revoked');

select is(
  (select created_inventory from public.cosmetic_iap_grants where transaction_id='txn-edge-early'),
  false,
  'I2: the tombstone claims no inventory');

-- A second delivery of the same refund is the ordinary already-revoked path.
select is(
  (public.clawback_cosmetic_iap('txn-edge-early', now()) ->> 'status'),
  'already_processed',
  'I2: re-delivering the early refund is idempotent');

-- The grant now arrives (RevenueCat redelivering the purchase). It must NOT
-- grant, and must say so honestly rather than claiming already_owned.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000f3',
     'obsidian_gold','sakina.skin.obsidian','txn-edge-early') ->> 'granted'),
  'false',
  'I2: a grant for a tombstoned transaction does not grant');

select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000f3',
     'obsidian_gold','sakina.skin.obsidian','txn-edge-early') ->> 'revoked'),
  'true',
  'I2: the blocked grant reports revoked=true');

select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000f3',
     'obsidian_gold','sakina.skin.obsidian','txn-edge-early') ->> 'already_owned'),
  'false',
  'I2: the blocked grant does NOT claim already_owned');

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f3' and item_id='obsidian_gold'),
  0,
  'I2: the refunded-then-retried purchase leaves the user without the skin');

-- A grant that is genuinely revoked (not a tombstone) is blocked the same way.
select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000f2',
     'obsidian_gold','sakina.skin.obsidian','txn-edge-b1') ->> 'revoked'),
  'true',
  'I2: a re-fire of an already-refunded purchase is blocked too');

-- ===========================================================================
-- N-1: REFUND_REVERSED reinstatement.
-- ===========================================================================
select is(
  (public.reinstate_cosmetic_iap('txn-edge-nothing', now()) ->> 'status'),
  'not_found',
  'N1: reinstating an unknown transaction is a safe no-op');

-- Buy, equip, refund, then have Apple reverse the refund.
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f4',
  'obsidian_gold','sakina.skin.obsidian','txn-edge-r1');

select set_config('app.cosmetics_rpc', 'on', true);
update public.user_profiles set equipped_lantern_skin = 'obsidian_gold'
 where id = '00000000-0000-0000-0000-0000000000f4';
select set_config('app.cosmetics_rpc', 'off', true);

select public.clawback_cosmetic_iap('txn-edge-r1', now());

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f4' and item_id='obsidian_gold'),
  0,
  'N1 setup: the refund removed ownership');

select is(
  (public.reinstate_cosmetic_iap('txn-edge-r1', now()) ->> 'status'),
  'reinstated',
  'N1: REFUND_REVERSED reinstates the grant');

select is(
  (select revoked_at from public.cosmetic_iap_grants where transaction_id='txn-edge-r1'),
  null,
  'N1: reinstatement clears revoked_at');

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f4' and item_id='obsidian_gold'),
  1,
  'N1: reinstatement restores the ownership row');

select is(
  (select acquired_via from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f4' and item_id='obsidian_gold'),
  'iap',
  'N1: the restored row is iap-provenance');

-- The equipped slot is deliberately NOT restored: the server keeps no equip
-- history, exactly as clawback_cosmetic_iap documents for the refund direction.
select is(
  (select equipped_lantern_skin from public.user_profiles
     where id='00000000-0000-0000-0000-0000000000f4'),
  'classic_gold',
  'N1: reinstatement does not silently re-equip the skin');

-- Redelivery of REFUND_REVERSED.
select is(
  (public.reinstate_cosmetic_iap('txn-edge-r1', now()) ->> 'status'),
  'not_revoked',
  'N1: reinstating an unrevoked grant is idempotent');

select is(
  (select count(*)::int from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f4' and item_id='obsidian_gold'),
  1,
  'N1: the idempotent replay does not duplicate ownership');

-- Reinstating a refund that never removed anything must not invent ownership
-- state — it only clears the ledger.
select set_config('app.cosmetics_rpc', 'on', true);
insert into public.user_cosmetics(user_id,item_type,item_id,acquired_via)
  values ('00000000-0000-0000-0000-0000000000f5','lantern_skin','obsidian_gold','noor')
  on conflict (user_id,item_type,item_id) do nothing;
select set_config('app.cosmetics_rpc', 'off', true);

select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f5',
  'obsidian_gold','sakina.skin.obsidian','txn-edge-r2');
select public.clawback_cosmetic_iap('txn-edge-r2', now());

select is(
  (public.reinstate_cosmetic_iap('txn-edge-r2', now()) ->> 'ownership_restored'),
  'false',
  'N1: reinstating a refund that revoked nothing restores nothing');

select is(
  (select acquired_via from public.user_cosmetics
     where user_id='00000000-0000-0000-0000-0000000000f5' and item_id='obsidian_gold'),
  'noor',
  'N1: the pre-existing non-iap provenance is left alone');

-- Reinstating a TOMBSTONE unblocks the purchase instead of restoring anything:
-- the refund that created it has been reversed, so the grant must be allowed
-- through when RevenueCat redelivers it.
select is(
  (public.reinstate_cosmetic_iap('txn-edge-early', now()) ->> 'status'),
  'tombstone_cleared',
  'N1: reinstating a tombstone reports tombstone_cleared');

select is(
  (select count(*)::int from public.cosmetic_iap_grants where transaction_id='txn-edge-early'),
  0,
  'N1: the cleared tombstone no longer blocks the ledger key');

select is(
  (public.grant_cosmetic_iap(
     '00000000-0000-0000-0000-0000000000f3',
     'obsidian_gold','sakina.skin.obsidian','txn-edge-early') ->> 'granted'),
  'true',
  'N1: after the tombstone is cleared the redelivered purchase grants');

-- ===========================================================================
-- Lockdown: reinstatement is webhook-only, exactly like grant/clawback.
-- ===========================================================================
select is(
  has_function_privilege('anon',
    'public.reinstate_cosmetic_iap(text,timestamptz)', 'execute'),
  false,
  'lockdown: anon cannot execute reinstate_cosmetic_iap');

select is(
  has_function_privilege('authenticated',
    'public.reinstate_cosmetic_iap(text,timestamptz)', 'execute'),
  false,
  'lockdown: authenticated cannot execute reinstate_cosmetic_iap');

select is(
  has_function_privilege('service_role',
    'public.reinstate_cosmetic_iap(text,timestamptz)', 'execute'),
  true,
  'lockdown: service_role can execute reinstate_cosmetic_iap');

select * from finish();
rollback;
