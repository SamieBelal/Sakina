# Lantern Cosmetics — Lane A-bis (Cosmetic IAP Grant RPC + RevenueCat Webhook path)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the server-side à-la-carte cosmetic IAP infrastructure that Lane B (`…-02-client-services.md`) already coded against but which does NOT exist yet (spec §13 item 4). This is: a `grant_cosmetic_iap` **service_role-only** SECURITY DEFINER RPC that permanently grants skin ownership to an explicit user (idempotent on the store transaction id), a `clawback_cosmetic_iap` refund/revoke RPC (mirroring `clawback_consumable_grant`), and the `revenuecat-webhook/handler.ts` wiring that routes non-renewing/non-consumable skin-SKU purchase events to the grant and skin-SKU CANCELLATION events to the clawback — all while preserving the existing subscription + consumable behavior byte-for-byte.

**Restore path is WEBHOOK-ONLY (v1) — read before implementing.** There is NO client-callable grant RPC and NO client-side receipt table in v1. À-la-carte skin restore (reinstall / new device) is handled by RevenueCat re-firing its purchase/`TRANSFER` event to this webhook: the Lane B client calls `Purchases.restorePurchases()` and re-syncs, and the webhook performs the grant under the service role. Accepted tradeoff: reinstall-restore relies on RC re-firing the transaction to the webhook; because skins are also earnable via Noor/tokens/milestones, a missed re-fire is a mild (non-billing) failure mode — the user can re-earn or re-purchase. A receipt-verified client-callable restore RPC is a documented future option if reinstall-restore proves to matter in practice. This webhook-only design is the fix for a security-critical flaw in the earlier draft: the previous `grant_cosmetic_iap` was `GRANT EXECUTE … TO authenticated` and bound ownership to `auth.uid()`, which let any logged-in user self-grant a paid skin for free (product ids are world-readable; the only gate was a catalog match). The RPC is now service_role-only and binds ownership to an explicit `p_user_id`, mirroring `clawback_consumable_grant`.

**Architecture:** Postgres migrations (source of truth for schema + RPCs + RLS, per CLAUDE.md) layered AFTER the merged Lane A migrations (`20260726000000`–`…000400`). The grant RPC mirrors the shipped `unlock_cosmetic` ownership-insert pattern (row-locked profile is unnecessary here — no balance to deduct — but the idempotent `ON CONFLICT DO NOTHING` inventory insert + a transaction-id ledger table mirror `noor_grants`). It sets the `app.cosmetics_rpc` GUC exactly as `unlock_cosmetic`/`equip_cosmetic` do so the `cosmetics_guard()` trigger permits the write. Product-id→item mapping is **server-authoritative via the existing `cosmetic_catalog.iap_product_id` column** (never a client map, never hardcoded in the RPC). The refund RPC + ledger mirror the `consumable_clawback_events` idempotency table and `clawback_consumable_grant` RPC. Webhook changes add two pure builder functions (`buildCosmeticGrant`, `buildCosmeticClawback`) alongside the existing `buildUserSubscriptionUpsert`/`buildConsumableClawback`, plus two isolated dispatch options, keeping the handler's "one event → at most one payload per builder" shape.

**Tech Stack:** Supabase Postgres (plpgsql SECURITY DEFINER RPCs), pgTAP (run via `psql`, local DB `postgresql://postgres:postgres@127.0.0.1:54322/postgres`), Deno (`deno test` for `handler.ts`), RevenueCat webhook (`REVENUECAT_WEBHOOK_SECRET` + service-role key live in **Supabase Edge Function secrets only**, never `env.json`).

---

## ⚠️ CONTRACT CHANGE — Lane B Task 7 updated (read first)

**This supersedes the earlier "frozen contract, no changes required" notice.** An independent security review found that the earlier signature `grant_cosmetic_iap(p_item_id, p_product_id, p_transaction_id)` — `GRANT EXECUTE … TO authenticated`, ownership bound to `auth.uid()` — let **any logged-in user self-grant a paid skin for free** (product ids are world-readable; the only gate was a catalog match), and was simultaneously **unusable by the webhook** (under `service_role`, `auth.uid()` is null → `not authenticated`, and there was no way to say which user bought the skin). Both are CRITICAL. The contract is therefore revised:

```
grant_cosmetic_iap(p_user_id uuid, p_item_id text, p_product_id text, p_transaction_id text)
  returns jsonb  -- { "granted": bool, "already_owned": bool, "item_id": text }
```

- **SECURITY DEFINER**, pinned `set search_path = public`.
- **service_role-only**: `grant execute … to service_role`; `revoke … from authenticated, anon, public`. **NO client may call it.** (Grant/revoke mirror `clawback_consumable_grant` exactly.)
- Ownership binds to **`p_user_id`** (the RevenueCat `app_user_id`), **NEVER** `auth.uid()`. The `auth.uid()` guard is removed entirely.
- Return keys are UNCHANGED (`granted` / `already_owned` / `item_id`) — the return-shape half of the Lane B contract is preserved, only the parameter list gains a leading `p_user_id`.

**LOUD Lane B Task 7 update (DEP-1 + DEP-2):** Lane B previously coded a client-side `grantSkinIap` that calls this RPC directly from `authenticated`. **That call path no longer exists** — the RPC is service_role-only, so a client call now fails with permission-denied. Lane B Task 7 must be updated so:

- There is **NO client-callable grant**. Remove `grantSkinIap`'s direct `callRpc('grant_cosmetic_iap', …)` (it cannot succeed as `authenticated`).
- The à-la-carte **restore path** (`reconcileSkinIapsFromCustomerInfo`, DEP-2) no longer grants via an RPC. Instead it calls `Purchases.restorePurchases()` and re-syncs; RevenueCat re-fires the purchase/`TRANSFER` event to the webhook, and the webhook does the service_role grant. Lane B's role is only to trigger the RC restore + re-sync so the (re-)granted `user_cosmetics` row lands in its cache.
- The initial-purchase path is likewise webhook-driven: after a successful StoreKit purchase, RC fires `NON_RENEWING_PURCHASE` to the webhook, which grants. The client re-syncs to pick up the row.

Specifically preserved (server side):

- Idempotent on `p_transaction_id` (a server-side ledger `cosmetic_iap_grants`, mirroring `noor_grants` / `consumable_clawback_events`) — a webhook retry or an RC re-fire of the same transaction returns `{granted:false, already_owned:true}` and never double-inserts. This is the seam that makes the restore path safe.
- Server re-verifies `p_product_id == cosmetic_catalog.iap_product_id` for `p_item_id` (never trusts the caller's item↔product mapping). An unknown/mismatched SKU is **rejected** (raise → the webhook returns 500 → RC retries → idempotent).
- Only à-la-carte purchasable rows are grantable: premium-exclusive / Noor-only / seasonal-without-`iap_product_id` SKUs are rejected (spec §13 item 6 — permanent à-la-carte ownership is distinct from equippable-while-premium perks).

**Refund (DEP-2):** the refund clawback (`clawback_cosmetic_iap`) is entirely server-side; Lane B's only role is to re-sync so the removed `user_cosmetics` row disappears from its cache. Its ledger `created_inventory` flag (see I1 below) means a refund only revokes ownership the IAP grant actually created — a skin the user also earned via Noor/milestone is kept.

---

## Product-ID → item mapping decision (justification)

**Decision: use the existing `cosmetic_catalog.iap_product_id` column as the single source of truth. NO new mapping table, NO hardcoded map in the RPC.**

Why:
- The column already exists and is already seeded (`20260726000100_seed_cosmetic_catalog.sql`): `obsidian_gold`→`sakina.skin.obsidian`, `masjid_brass`→`sakina.skin.masjid`, `crystal_star`→`sakina.skin.crystal`. Adding a second mapping table would create a two-source-of-truth drift hazard against the catalog the wardrobe already reads for price/availability.
- Spec §4 explicitly designed `cosmetic_catalog` as "the economic source of truth (never trust client price)" with an `iap_product_id` column for exactly this. A sales/SKU change is a data change (one catalog row), no app release and no new migration — matching the spec's stated goal.
- The RPC verifies the `(p_item_id, p_product_id)` pair against the catalog in one `SELECT`, so product→item verification and à-la-carte-eligibility gating happen in the same query (a row exists AND is active AND has a non-null matching `iap_product_id` AND is not premium-exclusive). Rejecting unknown/mismatched SKUs is then just "no row found".
- Uniqueness caveat handled in Task 1: a partial unique index on `iap_product_id` (where non-null) guarantees one product id maps to at most one catalog row, so the reverse lookup can never be ambiguous.

The Lane B client keeps a small `skinIapProductToItem` map ONLY to recognize which RC transactions are skin purchases and to pass `p_item_id` alongside `p_product_id`; the server re-verifies. That is intentional defense-in-depth, not a competing mapping.

---

## File Structure

| File | Responsibility |
|---|---|
| `supabase/migrations/20260726000500_cosmetic_iap_grant.sql` (create) | `cosmetic_iap_grants` ledger table (idempotency on `transaction_id`, incl. a `created_inventory boolean` column — I1) + RLS + the partial-unique index on `cosmetic_catalog.iap_product_id` + the **service_role-only** `grant_cosmetic_iap(p_user_id, p_item_id, p_product_id, p_transaction_id) returns jsonb` RPC (SECURITY DEFINER, binds ownership to `p_user_id` not `auth.uid()`, guard-aware, catalog-verified, à-la-carte-only; resets the guard GUC after the write — N1). |
| `supabase/migrations/20260726000600_cosmetic_iap_clawback.sql` (create) | `clawback_cosmetic_iap(p_transaction_id, p_event_timestamp) returns jsonb` RPC — reverses a grant on refund ONLY when the ledger row's `created_inventory = true` (I1): deletes the `user_cosmetics` row + resets the equipped slot to default if the refunded skin was equipped; when `created_inventory = false` it revokes nothing (user keeps a separately-earned skin) but still marks the ledger row revoked. Idempotent on `transaction_id`. Resets the guard GUC after the write (N1). |
| `supabase/tests/cosmetic_iap_grant_test.sql` (create) | pgTAP: service_role-context happy path (ownership binds to the passed `p_user_id`), idempotent double-grant, unknown/mismatched SKU rejected, premium-exclusive SKU rejected, Noor-only (no `iap_product_id`) SKU rejected, `authenticated`/`anon` roles CANNOT execute the function (client path closed), I1 already-owned skin records `created_inventory=false`, ledger row recorded. |
| `supabase/tests/cosmetic_iap_clawback_test.sql` (create) | pgTAP: refund removes ownership + resets the equipped slot to `classic_gold`, refund of a non-equipped skin leaves the slot, idempotent double-refund, refund of an unknown transaction is a safe no-op, I1 refund of a grant that did NOT create inventory (`created_inventory=false`) leaves ownership intact but still marks the ledger revoked. |
| `supabase/functions/revenuecat-webhook/handler.ts` (modify) | Add `COSMETIC_SKU_TO_ITEM` map + `CosmeticGrantPayload` (incl. `user_id`) / `CosmeticClawbackPayload` interfaces + `buildCosmeticGrant` / `buildCosmeticClawback` pure builders (grant payload carries the resolved RC `app_user_id` as `user_id`) + two dispatch options (`grantCosmetic`, `clawbackCosmetic`); wire them in `handleRevenueCatWebhook` WITHOUT touching subscription/consumable paths. |
| `supabase/functions/revenuecat-webhook/index.ts` (modify) | Implement the two new options against `supabase.rpc('grant_cosmetic_iap' / 'clawback_cosmetic_iap')` (grant call now passes `p_user_id: payload.user_id`), mirroring the `clawbackConsumable` wiring. The edge function uses the service-role client, matching the RPC's service_role-only grant. |
| `supabase/functions/revenuecat-webhook/index.test.ts` (modify) | Deno tests for the two new builders + the dispatch (grant on skin NON_RENEWING purchase, clawback on skin CANCELLATION, subscription/consumable paths unchanged). |

**Timestamp choice:** `20260726000500` and `…000600` are both strictly AFTER the last merged Lane A migration `20260726000400_cosmetics_hardening.sql`, so they apply in order without renumbering anything shipped.

---

## Task 1: `cosmetic_iap_grants` ledger + `grant_cosmetic_iap` RPC

**Files:**
- Create: `supabase/migrations/20260726000500_cosmetic_iap_grant.sql`
- Test: `supabase/tests/cosmetic_iap_grant_test.sql`

Grants permanent à-la-carte skin ownership to an explicit `p_user_id` (the RC `app_user_id`), **service_role-only** — mirrors `clawback_consumable_grant`'s service-role-only + explicit-user pattern. Mirrors `unlock_cosmetic`'s idempotent ownership insert (`ON CONFLICT DO NOTHING` on `user_cosmetics` PK) and `noor_grants`'s dedup ledger (PK on the dedup key). Sets `app.cosmetics_rpc` so `cosmetics_guard()` permits the write, then resets it to `off` after (N1). Verifies `(item_id, product_id)` against `cosmetic_catalog` so an unknown/mismatched/premium-exclusive/Noor-only SKU is rejected. Idempotent on `p_transaction_id` via the ledger. Records `created_inventory` on the ledger row (I1) — whether THIS grant actually inserted the `user_cosmetics` row (vs. the user already owning the skin via Noor/milestone) — so Task 2's clawback only revokes ownership the IAP grant created.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/cosmetic_iap_grant_test.sql`:

```sql
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
```

> **Note on the anon-role assertion:** the plan pins the `authenticated`-role permission-denied case as subtest (13) because that is the exploit the review flagged (a logged-in user self-granting). The `anon` role is covered by the same `revoke … from anon, public` in the migration; add a parallel `set local role anon; select throws_ok(...)` if the executor wants explicit anon coverage (bump `plan()` to 14). The migration's `revoke` closes both.

- [ ] **Step 2: Run the test to verify it fails**

The migration + RPC don't exist yet, so the local DB won't have them. Ensure the merged Lane A migrations plus this new file are applied, then run the test — it must fail because `grant_cosmetic_iap` and `cosmetic_iap_grants` don't exist.

```bash
export DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c 'create extension if not exists pgtap;'
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/cosmetic_iap_grant_test.sql
```

Expected: FAIL — `ERROR: function public.grant_cosmetic_iap(...) does not exist` (and/or `relation "public.cosmetic_iap_grants" does not exist`).

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260726000500_cosmetic_iap_grant.sql`:

```sql
-- À-la-carte cosmetic IAP grant (spec §13 item 4 — net-new non-consumable path).
--
-- Grants PERMANENT skin ownership after a RevenueCat non-consumable purchase.
-- This is distinct from premium-exclusive/subscriber-perk skins (which are
-- equippable-while-premium and never converted to ownership) and from Noor
-- unlocks (unlock_cosmetic). Only rows that are genuinely à-la-carte purchasable
-- — active, NOT premium-exclusive, with a matching iap_product_id — are grantable.
--
-- SECURITY (webhook-only design): this RPC is service_role-only. It binds
-- ownership to the PASSED p_user_id (the RC app_user_id), NEVER auth.uid().
-- An earlier draft granted TO authenticated bound to auth.uid(), which let any
-- logged-in user self-grant a paid skin for free (product ids are world-readable;
-- the only gate was a catalog match) AND was unusable by the webhook (auth.uid()
-- is null under service_role). This mirrors clawback_consumable_grant's
-- service-role-only + explicit-user pattern. NO client calls this — the client
-- restore path re-triggers RevenueCat, which re-fires the transaction to the
-- webhook, which grants under the service role.
--
-- Idempotency: a ledger keyed on the store transaction id (mirroring noor_grants
-- / consumable_clawback_events) makes a webhook retry OR an RC re-fire a safe
-- no-op. This is the seam that makes Lane B's restore-reconcile safe (DEP-2).
-- Ownership itself is also ON CONFLICT DO NOTHING on the user_cosmetics PK,
-- mirroring unlock_cosmetic.
--
-- I1 (refund-safety): the ledger records created_inventory — whether THIS grant
-- actually inserted the user_cosmetics row (vs. the user already owning the skin
-- via Noor/milestone). Task 2's clawback only revokes ownership when
-- created_inventory = true, so a refund never removes a skin the user earned
-- another way.
--
-- Product->item mapping is server-authoritative via cosmetic_catalog.iap_product_id
-- (never a client map). A partial unique index guarantees one product id maps to
-- at most one catalog row, so the reverse lookup is unambiguous.
--
-- Guard: sets the app.cosmetics_rpc GUC exactly like unlock_cosmetic /
-- equip_cosmetic so cosmetics_guard() permits the inventory write, then resets
-- it to 'off' after the write so the flag doesn't leak to the rest of the
-- transaction (N1, defense-in-depth).

-- Ledger / idempotency table. Keyed on the RC transaction id. A replay finds
-- the existing row and returns already_owned without re-inserting inventory.
-- `created_inventory` records whether THIS grant inserted the user_cosmetics row
-- (I1). `revoked_at` is set by clawback_cosmetic_iap (Task 2) on refund.
create table if not exists public.cosmetic_iap_grants (
  transaction_id    text primary key,
  user_id           uuid not null references auth.users(id) on delete cascade,
  item_type         text not null,
  item_id           text not null,
  product_id        text not null,
  created_inventory boolean not null default false,
  granted_at        timestamptz not null default now(),
  revoked_at        timestamptz
);

create index if not exists cosmetic_iap_grants_user_id_idx
  on public.cosmetic_iap_grants(user_id);

-- One product id maps to at most one catalog row (guards the reverse lookup).
-- Partial (non-null only) so the many null iap_product_id rows don't collide.
create unique index if not exists cosmetic_catalog_iap_product_id_uq
  on public.cosmetic_catalog(iap_product_id)
  where iap_product_id is not null;

-- RLS: user may SELECT their own ledger rows (parity with user_cosmetics_read);
-- no insert/update/delete policy → all writes are via the SECURITY DEFINER RPCs.
alter table public.cosmetic_iap_grants enable row level security;
drop policy if exists cosmetic_iap_grants_read on public.cosmetic_iap_grants;
create policy cosmetic_iap_grants_read on public.cosmetic_iap_grants
  for select using ((select auth.uid()) = user_id);

-- grant_cosmetic_iap: grant permanent à-la-carte skin ownership after a receipt-
-- verified purchase, to an explicit p_user_id. service_role-only. Idempotent on
-- p_transaction_id. Returns the Lane-B contract shape { granted, already_owned,
-- item_id }.
create or replace function public.grant_cosmetic_iap(
  p_user_id text,
  p_item_id text,
  p_product_id text,
  p_transaction_id text
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid;
  v_ledger public.cosmetic_iap_grants%rowtype;
  v_item_type text;
  v_created boolean;
begin
  if p_user_id is null or length(trim(p_user_id)) = 0 then
    raise exception 'missing user id';
  end if;
  v_uid := p_user_id::uuid;  -- validates the uuid shape; bad input raises.
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    raise exception 'missing transaction id';
  end if;

  -- Idempotency: a prior grant for this transaction returns already_owned
  -- WITHOUT touching inventory (webhook retry / RC re-fire).
  select * into v_ledger from public.cosmetic_iap_grants
    where transaction_id = p_transaction_id;
  if found then
    return jsonb_build_object(
      'granted', false,
      'already_owned', true,
      'item_id', v_ledger.item_id);
  end if;

  -- Server-authoritative verification: the (item_id, product_id) pair must be a
  -- genuinely à-la-carte purchasable catalog row — active, NOT premium-exclusive,
  -- with a matching non-null iap_product_id. A Noor-only row (null iap_product_id)
  -- never matches; a premium-exclusive row is excluded; an unknown/mismatched
  -- product id finds no row. All rejections land here.
  select item_type into v_item_type from public.cosmetic_catalog
    where item_id = p_item_id
      and iap_product_id = p_product_id
      and iap_product_id is not null
      and not is_premium_exclusive
      and active;
  if v_item_type is null then
    raise exception 'item not IAP-purchasable or product/item mismatch';
  end if;

  -- Insert ownership under the guard flag. ON CONFLICT DO NOTHING mirrors
  -- unlock_cosmetic — a user who already owns the skin (e.g. earned it another
  -- way) keeps their single row. The RETURNING probe tells us whether THIS grant
  -- created the row (I1): if a row comes back, we inserted it; if the CTE is
  -- empty, ON CONFLICT fired and the user already owned the skin.
  perform set_config('app.cosmetics_rpc', 'on', true);
  with ins as (
    insert into public.user_cosmetics(user_id, item_type, item_id, acquired_via)
      values (v_uid, v_item_type, p_item_id, 'iap')
      on conflict (user_id, item_type, item_id) do nothing
    returning 1
  )
  select exists (select 1 from ins) into v_created;
  -- N1: reset the guard flag so it doesn't leak to the rest of the transaction.
  perform set_config('app.cosmetics_rpc', 'off', true);

  -- Record the ledger row (dedup anchor + created_inventory for I1). A concurrent
  -- replay collides on the PK and raises unique_violation → translate to
  -- already_owned.
  begin
    insert into public.cosmetic_iap_grants(
      transaction_id, user_id, item_type, item_id, product_id, created_inventory)
      values (p_transaction_id, v_uid, v_item_type, p_item_id, p_product_id, v_created);
  exception when unique_violation then
    return jsonb_build_object(
      'granted', false, 'already_owned', true, 'item_id', p_item_id);
  end;

  -- granted reflects whether this call created inventory; a pre-owned skin
  -- returns already_owned=true (I1) even though the ledger row is new.
  return jsonb_build_object(
    'granted', v_created,
    'already_owned', not v_created,
    'item_id', p_item_id);
end $$;

revoke all on function public.grant_cosmetic_iap(text,text,text,text) from public, anon, authenticated;
-- service_role-only: the webhook grant path (index.ts) is the ONLY caller. No
-- client may execute this — the client restore path re-triggers RevenueCat,
-- which re-fires the transaction to the webhook (mirrors clawback_consumable_grant).
grant execute on function public.grant_cosmetic_iap(text,text,text,text) to service_role;

comment on function public.grant_cosmetic_iap is
  'Grants permanent à-la-carte skin ownership to an explicit p_user_id after a '
  'receipt-verified non-consumable purchase. service_role-only (webhook path). '
  'Idempotent on transaction_id. Records created_inventory (whether this grant '
  'inserted the row) so a refund only revokes ownership it created. Verifies '
  'product->item against cosmetic_catalog.iap_product_id (à-la-carte only; rejects '
  'premium-exclusive / Noor-only / unknown SKUs). Sets+resets app.cosmetics_rpc '
  'for the guard. Returns { granted, already_owned, item_id } (Lane B contract).';
```

- [ ] **Step 4: Run the test to verify it passes**

Apply the migration file, then re-run the test:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260726000500_cosmetic_iap_grant.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/cosmetic_iap_grant_test.sql
```

Expected: `# Looks like you passed all 13 tests` — all 13 subtests OK. (Subagents apply migrations via `psql -f`, NEVER `supabase db reset`.)

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260726000500_cosmetic_iap_grant.sql supabase/tests/cosmetic_iap_grant_test.sql
git commit -m "feat(cosmetics): grant_cosmetic_iap RPC + ledger (server-authoritative à-la-carte grant)"
```

---

## Task 2: `clawback_cosmetic_iap` RPC (refund revokes ownership + resets equipped slot)

**Files:**
- Create: `supabase/migrations/20260726000600_cosmetic_iap_clawback.sql`
- Test: `supabase/tests/cosmetic_iap_clawback_test.sql`

Mirrors `clawback_consumable_grant`: idempotent on `transaction_id`, service-role only. On refund, **only if the ledger row's `created_inventory = true`** (I1 — this IAP grant actually created the ownership row), it (a) deletes the `user_cosmetics` ownership row and (b) if the refunded skin was the user's equipped skin, resets `equipped_lantern_skin` to the default `classic_gold` (server nulls-out the equipped slot decision, pinned by a test). If `created_inventory = false` (the user already owned the skin via Noor/milestone before the IAP), it **revokes nothing** — the user keeps the separately-earned skin — but still (c) marks the ledger row `revoked_at` (records the refund + keeps idempotency). Refund of an unknown/never-granted transaction is a safe no-op (`{status:'not_found'}`), refund of an already-revoked transaction returns `{status:'already_processed'}`.

**Design ruling (pinned):** an equipped-then-refunded skin **falls back to `classic_gold`** (the default `equipped_lantern_skin`), not to some prior skin — the server has no reliable "previous equip" history and `classic_gold` is always owned. This is the single-premium-definition-safe behavior and matches the `equipped_lantern_skin` column default.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/cosmetic_iap_clawback_test.sql`:

```sql
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
select plan(11);

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
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
export DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/cosmetic_iap_clawback_test.sql
```

Expected: FAIL — `ERROR: function public.clawback_cosmetic_iap(...) does not exist`.

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/20260726000600_cosmetic_iap_clawback.sql`:

```sql
-- À-la-carte cosmetic IAP refund clawback (spec §13 item 4 — refund path).
--
-- Mirrors clawback_consumable_grant: service-role only, idempotent on the
-- transaction id. On a RevenueCat CANCELLATION for a skin SKU the webhook calls
-- this to REVOKE ownership — but ONLY the ownership this IAP grant created.
--
-- I1 (refund-safety): the clawback deletes the user_cosmetics row and resets the
-- equipped slot ONLY when the ledger row's created_inventory = true (this grant
-- inserted the ownership row). If created_inventory = false — the user already
-- owned the skin via Noor/milestone before the IAP — the clawback revokes
-- NOTHING (the user keeps the separately-earned skin) but still marks the ledger
-- revoked_at. Pinned by cosmetic_iap_clawback_test.sql (subtests 10, 11).
--
-- Design ruling: an equipped-then-refunded skin falls back to classic_gold (the
-- equipped_lantern_skin column default) — the server keeps no "previous equip"
-- history, and classic_gold is always owned, so this is the single-premium-
-- definition-safe reset. Pinned by cosmetic_iap_clawback_test.sql.
--
-- The equipped-slot write goes through the app.cosmetics_rpc guard flag, exactly
-- like equip_cosmetic, and (N1) resets it to 'off' after so the flag doesn't
-- leak to the rest of the transaction. The user_cosmetics delete is a
-- service-role SECURITY DEFINER write (RLS has no delete policy, but SECURITY
-- DEFINER owner bypasses RLS; the guard trigger is on user_profiles only, so the
-- delete needs no flag).
create or replace function public.clawback_cosmetic_iap(
  p_transaction_id text,
  p_event_timestamp timestamptz
)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_ledger public.cosmetic_iap_grants%rowtype;
begin
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    raise exception 'missing transaction id';
  end if;

  -- Row-lock the ledger row so a racing redelivery serializes.
  select * into v_ledger from public.cosmetic_iap_grants
    where transaction_id = p_transaction_id
    for update;

  -- Never granted here → safe no-op (a refund for a SKU we didn't grant, or a
  -- transaction we never saw).
  if not found then
    return jsonb_build_object('status', 'not_found',
                              'transaction_id', p_transaction_id);
  end if;

  -- Already revoked → idempotent (RC retries CANCELLATION on 5xx).
  if v_ledger.revoked_at is not null then
    return jsonb_build_object('status', 'already_processed',
                              'transaction_id', p_transaction_id);
  end if;

  -- I1: only revoke ownership THIS grant created. If the user already owned the
  -- skin another way (created_inventory=false), leave their inventory + equipped
  -- slot untouched — but still mark the ledger revoked below.
  if v_ledger.created_inventory then
    -- Remove ownership.
    delete from public.user_cosmetics
      where user_id = v_ledger.user_id
        and item_type = v_ledger.item_type
        and item_id = v_ledger.item_id;

    -- If the refunded skin was equipped, reset the slot to the default. Guarded
    -- write → set the RPC GUC so cosmetics_guard() permits the equipped_* update,
    -- then reset it (N1).
    if v_ledger.item_type = 'lantern_skin' then
      perform set_config('app.cosmetics_rpc', 'on', true);
      update public.user_profiles
         set equipped_lantern_skin = 'classic_gold'
       where id = v_ledger.user_id
         and equipped_lantern_skin = v_ledger.item_id;
      perform set_config('app.cosmetics_rpc', 'off', true);
    elsif v_ledger.item_type = 'backdrop' then
      perform set_config('app.cosmetics_rpc', 'on', true);
      update public.user_profiles
         set equipped_backdrop = 'default'
       where id = v_ledger.user_id
         and equipped_backdrop = v_ledger.item_id;
      perform set_config('app.cosmetics_rpc', 'off', true);
    end if;
  end if;

  -- Mark the ledger row revoked (records the refund + keeps idempotency), even
  -- when created_inventory=false and nothing was revoked.
  update public.cosmetic_iap_grants
     set revoked_at = coalesce(p_event_timestamp, now())
   where transaction_id = p_transaction_id;

  return jsonb_build_object(
    'status', 'revoked',
    'transaction_id', p_transaction_id,
    'item_id', v_ledger.item_id);
end $$;

revoke all on function public.clawback_cosmetic_iap(text, timestamptz) from public, anon, authenticated;
-- Refunds are driven only by the webhook under the service role.
grant execute on function public.clawback_cosmetic_iap(text, timestamptz) to service_role;

comment on function public.clawback_cosmetic_iap is
  'Reverses an à-la-carte skin IAP grant on refund. Idempotent on transaction_id. '
  'Deletes the user_cosmetics row; if the refunded skin was equipped, resets the '
  'equipped slot to the default (classic_gold / default). Marks the ledger '
  'revoked_at. Called by the revenuecat-webhook edge function on a CANCELLATION '
  'for a skin SKU.';
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/20260726000600_cosmetic_iap_clawback.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/cosmetic_iap_clawback_test.sql
```

Expected: `# Looks like you passed all 11 tests` — all 11 subtests OK.

- [ ] **Step 5: Re-run the full cosmetics SQL suite (no regression)**

The shipped Lane A tests must still pass against the two new migrations:

```bash
for f in cosmetics_schema_test cosmetics_guard_test cosmetics_award_noor_test \
         cosmetics_unlock_equip_test cosmetics_hardening_test \
         cosmetics_milestone_fix_test cosmetics_sync_test \
         cosmetic_iap_grant_test cosmetic_iap_clawback_test; do
  echo "== $f =="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "supabase/tests/$f.sql"
done
```

Expected: every file prints its `Looks like you passed all N tests` line; no `not ok`.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260726000600_cosmetic_iap_clawback.sql supabase/tests/cosmetic_iap_clawback_test.sql
git commit -m "feat(cosmetics): clawback_cosmetic_iap RPC (refund revokes ownership + resets equipped slot)"
```

---

## Task 3: Webhook builders — `buildCosmeticGrant` + `buildCosmeticClawback`

**Files:**
- Modify: `supabase/functions/revenuecat-webhook/handler.ts`
- Test: `supabase/functions/revenuecat-webhook/index.test.ts`

Add two pure builders alongside `buildUserSubscriptionUpsert` / `buildConsumableClawback`, plus the SKU→item map and payload interfaces. A skin **purchase** arrives as a non-renewing/non-consumable event (`NON_RENEWING_PURCHASE`) whose `product_id` is a skin SKU; a skin **refund** arrives as `CANCELLATION` with a skin SKU. Both filter independently and never overlap the subscription/consumable builders (skin SKUs are not in `CONSUMABLE_SKU_TO_AMOUNT` and carry no `premium` entitlement). This step is builders-only; wiring is Task 4.

- [ ] **Step 1: Write the failing test**

Append to `supabase/functions/revenuecat-webhook/index.test.ts` (after the consumable-clawback block). Also add the two new builder names to the top-of-file import from `./handler.ts`:

```ts
import {
  buildConsumableClawback,
  buildCosmeticClawback,
  buildCosmeticGrant,
  buildUserSubscriptionUpsert,
  type ConsumableClawbackPayload,
  type CosmeticClawbackPayload,
  type CosmeticGrantPayload,
  handleRevenueCatWebhook,
  hasActivePremiumAccess,
  type RevenueCatEvent,
  type UserSubscriptionUpsert,
} from "./handler.ts";
```

Then append:

```ts
// ── À-la-carte skin IAP grant + refund (Lane A-bis) ───────────────────────
//
// Skin purchases arrive as NON_RENEWING_PURCHASE with a skin SKU; refunds as
// CANCELLATION with a skin SKU. Neither carries the premium entitlement and
// neither SKU is in CONSUMABLE_SKU_TO_AMOUNT, so they never collide with the
// subscription/consumable paths.

function skinPurchaseEvent(
  overrides: Partial<RevenueCatEvent> = {},
): RevenueCatEvent {
  return {
    type: "NON_RENEWING_PURCHASE",
    id: "rc-event-skin-1",
    app_user_id: userId,
    original_app_user_id: userId,
    aliases: [],
    entitlement_ids: [],
    product_id: "sakina.skin.obsidian",
    transaction_id: "apple-skin-txn-1",
    store: "APP_STORE",
    environment: "PRODUCTION",
    event_timestamp_ms: nowMs,
    ...overrides,
  };
}

function skinRefundEvent(
  overrides: Partial<RevenueCatEvent> = {},
): RevenueCatEvent {
  return {
    type: "CANCELLATION",
    id: "rc-event-skin-refund-1",
    app_user_id: userId,
    original_app_user_id: userId,
    aliases: [],
    entitlement_ids: [],
    product_id: "sakina.skin.obsidian",
    transaction_id: "apple-skin-txn-1",
    store: "APP_STORE",
    environment: "PRODUCTION",
    event_timestamp_ms: nowMs,
    ...overrides,
  };
}

Deno.test("buildCosmeticGrant maps a known skin SKU on NON_RENEWING_PURCHASE", () => {
  const payload = buildCosmeticGrant(skinPurchaseEvent());
  assert(payload);
  assertEquals(payload.user_id, userId);
  assertEquals(payload.product_id, "sakina.skin.obsidian");
  assertEquals(payload.item_id, "obsidian_gold");
  assertEquals(payload.transaction_id, "apple-skin-txn-1");
});

Deno.test("buildCosmeticGrant returns null for a subscription event", () => {
  assertEquals(buildCosmeticGrant(baseEvent()), null);
});

Deno.test("buildCosmeticGrant returns null for an unknown SKU", () => {
  assertEquals(
    buildCosmeticGrant(skinPurchaseEvent({ product_id: "sakina.tokens_100" })),
    null,
  );
});

Deno.test("buildCosmeticGrant returns null for anonymous user", () => {
  assertEquals(
    buildCosmeticGrant(skinPurchaseEvent({
      app_user_id: "$RCAnonymousID:anon-a",
      original_app_user_id: "$RCAnonymousID:anon-b",
      aliases: ["$RCAnonymousID:anon-c"],
    })),
    null,
  );
});

Deno.test("buildCosmeticGrant returns null when transaction id AND event id are missing", () => {
  assertEquals(
    buildCosmeticGrant(skinPurchaseEvent({ transaction_id: null, id: null })),
    null,
  );
});

Deno.test("buildCosmeticGrant falls back to event id when transaction_id missing", () => {
  const payload = buildCosmeticGrant(
    skinPurchaseEvent({ transaction_id: null, id: "rc-fallback-skin" }),
  );
  assert(payload);
  assertEquals(payload.transaction_id, "rc-fallback-skin");
});

Deno.test("buildCosmeticClawback maps a known skin SKU on CANCELLATION", () => {
  const payload = buildCosmeticClawback(skinRefundEvent());
  assert(payload);
  assertEquals(payload.transaction_id, "apple-skin-txn-1");
});

Deno.test("buildCosmeticClawback returns null for a non-CANCELLATION type", () => {
  assertEquals(
    buildCosmeticClawback(skinRefundEvent({ type: "NON_RENEWING_PURCHASE" })),
    null,
  );
});

Deno.test("buildCosmeticClawback returns null for an unknown SKU", () => {
  assertEquals(
    buildCosmeticClawback(skinRefundEvent({ product_id: "sakina_tokens_100" })),
    null,
  );
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd supabase/functions/revenuecat-webhook
deno test --allow-none index.test.ts
```

Expected: FAIL — `buildCosmeticGrant` / `buildCosmeticClawback` / `CosmeticGrantPayload` / `CosmeticClawbackPayload` are not exported by `./handler.ts` (compile error).

- [ ] **Step 3: Add the map, interfaces, and builders**

In `supabase/functions/revenuecat-webhook/handler.ts`, add this block immediately AFTER the `CONSUMABLE_SKU_TO_AMOUNT` constant (after line 38):

```ts
// Skin SKU -> catalog item_id. Mirrors the `iap_product_id` column in
// `20260726000100_seed_cosmetic_catalog.sql` AND the Flutter map in
// `lib/services/cosmetics_service.dart` (skinIapProductToItem). When SKUs
// change, ALL THREE must update. The SERVER RPC re-verifies product->item
// against cosmetic_catalog, so this map is only a routing filter (which
// transactions are skin purchases) — it never grants on its own.
//
// A NON_RENEWING_PURCHASE for one of these product ids is an à-la-carte skin
// buy → grant_cosmetic_iap. A CANCELLATION for one is a refund →
// clawback_cosmetic_iap (mirrors the consumable clawback pattern).
export const COSMETIC_SKU_TO_ITEM: Record<string, string> = {
  "sakina.skin.obsidian": "obsidian_gold",
  "sakina.skin.masjid": "masjid_brass",
  "sakina.skin.crystal": "crystal_star",
};
```

Add the two payload interfaces immediately after `ConsumableClawbackPayload` (after line 69):

```ts
export interface CosmeticGrantPayload {
  user_id: string;
  item_id: string;
  product_id: string;
  transaction_id: string;
  event_timestamp: string;
}

export interface CosmeticClawbackPayload {
  transaction_id: string;
  event_timestamp: string;
}
```

Add the two dispatch options to `HandleWebhookOptions` (after the `clawbackConsumable` field, before `sendCancellationSurveyPush`):

```ts
  // Grants an à-la-carte skin on a NON_RENEWING_PURCHASE for a skin SKU.
  // Implementation calls grant_cosmetic_iap (idempotent on transaction_id).
  grantCosmetic?: (payload: CosmeticGrantPayload) => Promise<void>;
  // Revokes an à-la-carte skin on a CANCELLATION for a skin SKU. Implementation
  // calls clawback_cosmetic_iap (idempotent on transaction_id).
  clawbackCosmetic?: (payload: CosmeticClawbackPayload) => Promise<void>;
```

Add the two builders immediately after `buildConsumableClawback` (after line 295):

```ts
/**
 * Builds a skin-IAP grant payload from a NON_RENEWING_PURCHASE whose product_id
 * is a known skin SKU. Returns null for anything else (subscriptions,
 * consumables, unknown SKUs, anonymous users, or a missing transaction id).
 *
 * Detection:
 *   - type must be "NON_RENEWING_PURCHASE"
 *   - product_id must be in COSMETIC_SKU_TO_ITEM
 *   - user must resolve to a UUID (not anonymous)
 *   - a transaction id (or the event id fallback) must be present
 *
 * The server RPC re-verifies product->item against the catalog, so item_id here
 * is only a hint; a tampered/unknown SKU never reaches the RPC because it fails
 * the COSMETIC_SKU_TO_ITEM lookup first.
 */
export function buildCosmeticGrant(
  event: RevenueCatEvent,
): CosmeticGrantPayload | null {
  const eventType = nonEmptyString(event.type);
  if (eventType !== "NON_RENEWING_PURCHASE") return null;

  const productId = nonEmptyString(event.product_id);
  if (productId == null) return null;

  const itemId = COSMETIC_SKU_TO_ITEM[productId];
  if (itemId == null) return null;

  const userId = resolveStableUserId(event);
  if (
    userId == null || isAnonymousRevenueCatUserId(userId) || !isUuid(userId)
  ) {
    return null;
  }

  const transactionId = nonEmptyString(event.transaction_id) ??
    nonEmptyString(event.id);
  if (transactionId == null) return null;

  const eventTimestamp = msToIsoString(event.event_timestamp_ms) ??
    new Date().toISOString();

  return {
    user_id: userId,
    item_id: itemId,
    product_id: productId,
    transaction_id: transactionId,
    event_timestamp: eventTimestamp,
  };
}

/**
 * Builds a skin-IAP clawback payload from a CANCELLATION whose product_id is a
 * known skin SKU (a refund). Returns null otherwise. Only the transaction id +
 * timestamp are needed — the clawback RPC looks up the ledger row by
 * transaction id to find the user/item, so we never trust client-supplied
 * ownership here.
 */
export function buildCosmeticClawback(
  event: RevenueCatEvent,
): CosmeticClawbackPayload | null {
  const eventType = nonEmptyString(event.type);
  if (eventType !== "CANCELLATION") return null;

  const productId = nonEmptyString(event.product_id);
  if (productId == null) return null;
  if (COSMETIC_SKU_TO_ITEM[productId] == null) return null;

  const userId = resolveStableUserId(event);
  if (
    userId == null || isAnonymousRevenueCatUserId(userId) || !isUuid(userId)
  ) {
    return null;
  }

  const transactionId = nonEmptyString(event.transaction_id) ??
    nonEmptyString(event.id);
  if (transactionId == null) return null;

  const eventTimestamp = msToIsoString(event.event_timestamp_ms) ??
    new Date().toISOString();

  return {
    transaction_id: transactionId,
    event_timestamp: eventTimestamp,
  };
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd supabase/functions/revenuecat-webhook
deno test --allow-none index.test.ts
```

Expected: PASS — all existing tests plus the 9 new builder tests (`ok | 0 failed`).

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/revenuecat-webhook/handler.ts supabase/functions/revenuecat-webhook/index.test.ts
git commit -m "feat(webhook): buildCosmeticGrant + buildCosmeticClawback builders for skin IAP"
```

---

## Task 4: Wire the skin grant/clawback into `handleRevenueCatWebhook`

**Files:**
- Modify: `supabase/functions/revenuecat-webhook/handler.ts`
- Test: `supabase/functions/revenuecat-webhook/index.test.ts`

Dispatch the two new payloads in `handleRevenueCatWebhook`, keeping the "one event → at most one payload per builder" shape. A skin grant/clawback that raises returns 500 (so RC retries — safe because the RPC is idempotent), exactly like the consumable clawback. Subscription + consumable dispatch is byte-for-byte unchanged. Because `grantCosmetic`/`clawbackCosmetic` are optional options, every existing test (which omits them) still compiles and passes.

- [ ] **Step 1: Write the failing test**

Append to `supabase/functions/revenuecat-webhook/index.test.ts`:

```ts
Deno.test("Skin NON_RENEWING_PURCHASE triggers grantCosmetic, not subscription/consumable", async () => {
  const grants: CosmeticGrantPayload[] = [];
  let upsertCalls = 0;
  let consumableClawbacks = 0;

  const response = await handleRevenueCatWebhook(
    authorizedRequest(skinPurchaseEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {
        consumableClawbacks += 1;
      },
      upsertSubscription: async () => {
        upsertCalls += 1;
        return { written: true, cancellationStarted: false };
      },
      grantCosmetic: async (payload) => {
        grants.push(payload);
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "ok" });
  assertEquals(grants.length, 1);
  assertEquals(grants[0].item_id, "obsidian_gold");
  assertEquals(grants[0].transaction_id, "apple-skin-txn-1");
  assertEquals(upsertCalls, 0, "skin buy must NOT touch subscriptions");
  assertEquals(consumableClawbacks, 0, "skin buy is not a consumable");
});

Deno.test("Skin CANCELLATION triggers clawbackCosmetic, not subscription upsert", async () => {
  const clawbacks: CosmeticClawbackPayload[] = [];
  let upsertCalls = 0;

  const response = await handleRevenueCatWebhook(
    authorizedRequest(skinRefundEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        upsertCalls += 1;
        return { written: true, cancellationStarted: false };
      },
      clawbackCosmetic: async (payload) => {
        clawbacks.push(payload);
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "ok" });
  assertEquals(clawbacks.length, 1);
  assertEquals(clawbacks[0].transaction_id, "apple-skin-txn-1");
  assertEquals(upsertCalls, 0, "skin refund must NOT touch subscriptions");
});

Deno.test("Skin grant RPC failure returns 500 so RC retries", async () => {
  const response = await handleRevenueCatWebhook(
    authorizedRequest(skinPurchaseEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("should not be called");
      },
      grantCosmetic: async () => {
        throw new Error("rpc boom");
      },
    },
  );

  assertEquals(response.status, 500);
});

Deno.test("Skin purchase with grantCosmetic omitted is a 200 skip (no dispatch)", async () => {
  // Belt-and-suspenders: an event that only builds a cosmetic payload, but the
  // option is not wired, must still 200 (skipped) rather than throw.
  const response = await handleRevenueCatWebhook(
    authorizedRequest(skinPurchaseEvent()),
    {
      webhookSecret,
      clawbackConsumable: async () => {},
      upsertSubscription: async () => {
        throw new Error("should not be called");
      },
    },
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { status: "skipped" });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd supabase/functions/revenuecat-webhook
deno test --allow-none index.test.ts
```

Expected: FAIL — the dispatch isn't wired, so `grantCosmetic`/`clawbackCosmetic` are never called (the grant/clawback assertions fail; the skin purchase currently falls through to `status: "skipped"` in the first test).

- [ ] **Step 3: Wire the dispatch**

In `supabase/functions/revenuecat-webhook/handler.ts`, inside `handleRevenueCatWebhook`, replace the payload-build + short-circuit block (currently lines 334-343) with the version that also builds and dispatches the cosmetic payloads.

Change this:

```ts
  const subscriptionPayload = buildUserSubscriptionUpsert(event);
  const clawbackPayload = buildConsumableClawback(event);

  if (subscriptionPayload == null && clawbackPayload == null) {
    return jsonResponse(200, { status: "skipped" });
  }
```

to this:

```ts
  const subscriptionPayload = buildUserSubscriptionUpsert(event);
  const clawbackPayload = buildConsumableClawback(event);
  const cosmeticGrantPayload = buildCosmeticGrant(event);
  const cosmeticClawbackPayload = buildCosmeticClawback(event);

  // A cosmetic payload is only actionable if the matching option is wired
  // (grant/clawback are optional). Treat "built but unwired" as no-op so a
  // skin event on an old deploy 200-skips instead of throwing.
  const hasCosmeticGrant = cosmeticGrantPayload != null &&
    options.grantCosmetic != null;
  const hasCosmeticClawback = cosmeticClawbackPayload != null &&
    options.clawbackCosmetic != null;

  if (
    subscriptionPayload == null && clawbackPayload == null &&
    !hasCosmeticGrant && !hasCosmeticClawback
  ) {
    return jsonResponse(200, { status: "skipped" });
  }
```

Then add the cosmetic dispatch immediately AFTER the consumable clawback block (after the closing brace of `if (clawbackPayload != null) { ... }`, currently line 355, and BEFORE the `if (subscriptionPayload != null)` block):

```ts
  if (hasCosmeticGrant) {
    try {
      await options.grantCosmetic!(cosmeticGrantPayload!);
    } catch (error) {
      console.error("revenuecat-webhook cosmetic grant failed", error);
      return jsonResponse(500, { error: "Failed to grant cosmetic" });
    }
  }

  if (hasCosmeticClawback) {
    try {
      await options.clawbackCosmetic!(cosmeticClawbackPayload!);
    } catch (error) {
      console.error("revenuecat-webhook cosmetic clawback failed", error);
      return jsonResponse(500, { error: "Failed to revoke cosmetic" });
    }
  }
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd supabase/functions/revenuecat-webhook
deno test --allow-none index.test.ts
```

Expected: PASS — all tests, including the 4 new dispatch tests AND every pre-existing subscription/consumable test (unchanged behavior).

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/revenuecat-webhook/handler.ts supabase/functions/revenuecat-webhook/index.test.ts
git commit -m "feat(webhook): route skin NON_RENEWING_PURCHASE→grant and CANCELLATION→clawback"
```

---

## Task 5: Wire the RPC calls in `index.ts` (the live edge function)

**Files:**
- Modify: `supabase/functions/revenuecat-webhook/index.ts`

Implement the two new options against `supabase.rpc(...)`, mirroring the existing `clawbackConsumable` wiring exactly (errors propagate → the handler returns 500 → RC retries → the RPC's idempotency makes retries safe). `index.ts` has no unit test in this repo (it wires Deno env + the Supabase client); it's verified by the handler tests (Task 3/4) plus the manual verification in Task 6. The service-role key and `REVENUECAT_WEBHOOK_SECRET` come from Edge Function secrets, never `env.json`.

- [ ] **Step 1: Add the two option implementations**

In `supabase/functions/revenuecat-webhook/index.ts`, inside the `handleRevenueCatWebhook(request, { ... })` options object, add these two properties immediately AFTER the `clawbackConsumable` implementation (after its closing `},` near line 112):

```ts
    grantCosmetic: async (payload) => {
      // Idempotent on transaction_id server-side, so RC retries are safe.
      // Errors propagate → 500 → RC retries.
      const { error } = await supabase.rpc("grant_cosmetic_iap", {
        p_user_id: payload.user_id,
        p_item_id: payload.item_id,
        p_product_id: payload.product_id,
        p_transaction_id: payload.transaction_id,
      });
      if (error != null) {
        throw error;
      }
    },
    clawbackCosmetic: async (payload) => {
      // Idempotent on transaction_id server-side. Errors propagate → 500 → RC
      // retries.
      const { error } = await supabase.rpc("clawback_cosmetic_iap", {
        p_transaction_id: payload.transaction_id,
        p_event_timestamp: payload.event_timestamp,
      });
      if (error != null) {
        throw error;
      }
    },
```

- [ ] **Step 2: Type-check the edge function**

`index.ts` imports remote modules (`serve`, `createClient`), so run a type-check that resolves them:

```bash
cd supabase/functions/revenuecat-webhook
deno check index.ts
```

Expected: no type errors. (If the environment cannot fetch remote modules offline, this is the documented fallback: confirm the two `supabase.rpc(...)` param objects match the RPC signatures from Tasks 1-2 — `grant_cosmetic_iap(p_user_id, p_item_id, p_product_id, p_transaction_id)` and `clawback_cosmetic_iap(p_transaction_id, p_event_timestamp)` — by inspection, then proceed. Note it as a manual check.)

- [ ] **Step 3: Re-run the handler tests (confirm no regression from the import edit)**

```bash
cd supabase/functions/revenuecat-webhook
deno test --allow-none index.test.ts
```

Expected: PASS (handler tests are independent of `index.ts`; this just confirms nothing in the shared file broke).

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/revenuecat-webhook/index.ts
git commit -m "feat(webhook): wire grant_cosmetic_iap / clawback_cosmetic_iap RPC calls in index.ts"
```

---

## Task 6: Full-suite green + integration verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full cosmetics pgTAP suite**

```bash
export DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c 'create extension if not exists pgtap;'
for f in cosmetics_schema_test cosmetics_guard_test cosmetics_award_noor_test \
         cosmetics_unlock_equip_test cosmetics_hardening_test \
         cosmetics_milestone_fix_test cosmetics_sync_test \
         cosmetic_iap_grant_test cosmetic_iap_clawback_test; do
  echo "== $f =="
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "supabase/tests/$f.sql"
done
```

Expected: every file prints `# Looks like you passed all N tests`; zero `not ok` lines.

- [ ] **Step 2: Run the full webhook Deno test file**

```bash
cd supabase/functions/revenuecat-webhook
deno test --allow-none index.test.ts
```

Expected: `ok | N passed | 0 failed` — all subscription, consumable, and new cosmetic tests green.

- [ ] **Step 3: Restore-path idempotency spot check (the Lane B seam)**

Prove that the same-transaction replay (webhook grant, then an RC re-fire on restore) is a true no-op. Both calls run in the **service_role context** (default superuser connection, no authenticated jwt — the RPC is service_role-only and takes an explicit `p_user_id`), simulating the webhook grant then the webhook re-firing the same transaction. In one psql session:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
begin;
insert into public.cosmetic_catalog(item_type,item_id,noor_price,iap_product_id,is_premium_exclusive,active)
values ('lantern_skin','obsidian_gold',200,'sakina.skin.obsidian',false,true)
on conflict (item_type,item_id) do update set iap_product_id=excluded.iap_product_id, active=excluded.active;
insert into auth.users(id,email) values ('00000000-0000-0000-0000-0000000000f1','restore@test.local') on conflict do nothing;
insert into public.user_profiles(id) values ('00000000-0000-0000-0000-0000000000f1') on conflict do nothing;
-- Webhook grant (service_role context, explicit p_user_id).
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f1',
  'obsidian_gold','sakina.skin.obsidian','txn-restore') as webhook_grant;
-- RC re-fire (restore) replay of the SAME transaction id.
select public.grant_cosmetic_iap(
  '00000000-0000-0000-0000-0000000000f1',
  'obsidian_gold','sakina.skin.obsidian','txn-restore') as restore_replay;
-- Exactly one ownership row.
select count(*) as owned_rows from public.user_cosmetics
  where user_id='00000000-0000-0000-0000-0000000000f1' and item_id='obsidian_gold';
rollback;
SQL
```

Expected: `webhook_grant` = `{"granted": true, "already_owned": false, ...}`, `restore_replay` = `{"granted": false, "already_owned": true, ...}`, `owned_rows` = `1`.

- [ ] **Step 4: Manual RevenueCat / edge-function verification checklist (follow-up, not blocking)**

Record these as the deploy-time manual checks (no automated harness in this repo for the deployed function):

1. In Supabase Edge Function secrets confirm `REVENUECAT_WEBHOOK_SECRET`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL` are set — NEVER in `env.json`.
2. Deploy: `supabase functions deploy revenuecat-webhook`.
3. In RevenueCat sandbox, buy `sakina.skin.obsidian`; confirm a `user_cosmetics` row (`acquired_via='iap'`) + a `cosmetic_iap_grants` ledger row appear for the user.
4. Refund the sandbox purchase; confirm the `user_cosmetics` row disappears, `cosmetic_iap_grants.revoked_at` is set, and (if it was equipped) `equipped_lantern_skin` reset to `classic_gold`.
5. Redeliver the same purchase webhook (RC dashboard) and confirm no duplicate row (idempotency).
6. Confirm a subscription purchase/renewal/cancellation still behaves exactly as before (no regression on the sub path).

- [ ] **Step 5: Commit (verification notes only, if any file changed — otherwise skip)**

No code changes in this task; nothing to commit unless a verification uncovered a fix (in which case commit that fix with its own TDD cycle).

---

## Self-Review

**1. Spec coverage** (hard requirements from the brief + spec §13):

| Requirement | Task |
|---|---|
| `grant_cosmetic_iap` SECURITY DEFINER, **service_role-only**, binds to explicit `p_user_id` (not `auth.uid()`), idempotent on transaction id, guard-aware, mirrors `unlock_cosmetic` ownership insert + `clawback_consumable_grant` grant/revoke | Task 1 |
| Security fix: client cannot self-grant (no `authenticated` execute); webhook can grant (explicit user) | Task 1 (test 13 client-path closed; migration `revoke … from authenticated,anon,public` + `grant … to service_role`) |
| I1: ledger `created_inventory` threaded into refund logic (refund only revokes what the IAP grant created) | Task 1 (records it; tests 6, 11, 12) → Task 2 (gates delete/reset on it; tests 10, 11) |
| N1: guard GUC reset to `off` after each guarded write (grant + clawback) | Task 1, Task 2 |
| Dedup/ledger table mirroring `noor_grants` | Task 1 (`cosmetic_iap_grants`) |
| Product-id→item mapping via catalog column (justified, not hardcoded/new table) | Task 1 + the mapping-decision section |
| Returns Lane-B contract shape `{granted, already_owned, item_id}` (return keys unchanged; param list gains leading `p_user_id`) | Task 1 (verified against revised Lane B Task 7) |
| Only à-la-carte SKUs grantable; premium-exclusive / Noor-only rejected (§13.6) | Task 1 (tests 9, 10) |
| Unknown/mismatched SKU rejected | Task 1 (tests 7, 8) |
| Refund path revokes ownership (when `created_inventory`); equipped-then-refunded resets to default; pinned by test | Task 2 |
| Refund idempotent, unknown-txn no-op, mirrors `buildConsumableClawback` server side | Task 2 |
| Webhook routes skin purchase → grant, skin refund → clawback; sub/consumable byte-for-byte preserved | Tasks 3, 4 |
| Signature verification, environment, transaction id, product→item verification, idempotent redelivery | Tasks 1 (verification/idempotency), 3 (builder filters), 4 (dispatch); signature check is the existing `Authorization: Bearer` guard, untouched |
| Restore reconciliation reaches ownership via RC re-firing the transaction to the webhook (no client grant RPC) + the grant RPC's idempotency | Task 1 + Task 6 Step 3 spot check + CONTRACT CHANGE header |
| Server-only secrets in Edge Function secrets, never `env.json` | Task 5, Task 6 Step 4 |
| pgTAP for every RPC path (grant happy, double-grant, unknown SKU, premium-exclusive, refund revoke+reset, guard blocks direct) | Tasks 1, 2 |
| `throws_ok` arg2 = expected message → NULL 3-arg form used | Tasks 1, 2 (all rejection asserts use `NULL`) |
| Migrations are new files timestamped AFTER `20260726000400`; applied via `psql -f` | Tasks 1, 2 (`…000500`, `…000600`) |
| Webhook handler Deno tests (repo has the precedent — `index.test.ts`) | Tasks 3, 4 |
| Every task: failing test → run(fail) → impl → run(pass) → commit, exact commands + expected output | All tasks |

**2. Placeholder scan:** No `TBD` / `TODO` / `implement later` / "add tests for the above" — every migration, RPC body, builder, dispatch edit, and test is complete. Task 6 Step 5's "skip if nothing changed" is a genuine conditional, not a deferred implementation.

**3. Type / signature consistency:** every `grant_cosmetic_iap` reference across all 6 tasks now shows the **4-arg** signature `(p_user_id, p_item_id, p_product_id, p_transaction_id)`:
- **Migration (Task 1):** `grant_cosmetic_iap(p_user_id text, p_item_id text, p_product_id text, p_transaction_id text) → jsonb {granted, already_owned, item_id}`; `revoke all … from public, anon, authenticated` + `grant execute … to service_role`. Binds ownership to `p_user_id::uuid`, no `auth.uid()`.
- **Task 1 pgTAP:** all 12 `grant_cosmetic_iap(...)` calls pass the uuid first arg; subtest 13 asserts `authenticated` cannot execute (client path closed); subtests 6/11/12 assert `created_inventory`.
- **Task 2 migration + pgTAP:** grant calls in the fixtures use the 4-arg form under the service_role (default-connection) context; clawback gates delete/reset on `created_inventory`; subtests 10/11 pin the I1 behavior.
- **`index.ts` (Task 5):** `supabase.rpc('grant_cosmetic_iap', {p_user_id, p_item_id, p_product_id, p_transaction_id})` — 4 keys, matching. Edge function uses the service-role client, matching the service_role-only grant.
- **Task 6 Step 3 spot check + Step 4 sandbox checklist:** 4-arg service_role-context calls.
- **Lane B Task 7 (external):** LOUDLY updated in the CONTRACT CHANGE header — the client `grantSkinIap` direct RPC call is removed (a client call now fails permission-denied); restore is webhook-driven via `Purchases.restorePurchases()` + re-sync. Return-key reads (`res['granted']`/`res['already_owned']`) are unchanged where the client reads a re-sync result, not the RPC.
- `clawback_cosmetic_iap(p_transaction_id text, p_event_timestamp timestamptz) → jsonb {status,...}` — service_role-only (unchanged); `index.ts` passes `{p_transaction_id, p_event_timestamp}`, matching.
- `CosmeticGrantPayload` (user_id, item_id, product_id, transaction_id, event_timestamp) built in `buildCosmeticGrant` (sets `user_id` from the resolved RC `app_user_id`), consumed by `index.ts` `grantCosmetic` (reads user_id/item_id/product_id/transaction_id → `p_user_id`/`p_item_id`/`p_product_id`/`p_transaction_id`) — consistent.
- `CosmeticClawbackPayload` (transaction_id, event_timestamp) built in `buildCosmeticClawback`, consumed by `index.ts` `clawbackCosmetic` — consistent.
- `COSMETIC_SKU_TO_ITEM` values (`obsidian_gold`/`masjid_brass`/`crystal_star`) match the seed catalog `iap_product_id` mapping AND Lane B's `skinIapProductToItem` — three-way aligned, called out in the map's comment.
- Guard GUC flag `app.cosmetics_rpc` set identically to `unlock_cosmetic`/`equip_cosmetic` before every guarded `user_profiles`/`user_cosmetics` write and reset to `off` after (N1); the `user_cosmetics` delete in the clawback is a SECURITY DEFINER owner write (RLS-bypassing), needing no flag (the guard trigger is on `user_profiles` only).
- pgTAP harness idioms (`begin; select plan(N); ... select * from finish(); rollback;`, `set local role authenticated` + `request.jwt.claims` sub for the authenticated-context asserts, default-connection service_role context for grant/clawback, guard-GUC seeding) match `cosmetics_unlock_equip_test.sql` / `cosmetics_guard_test.sql`.

All consistent. Plan is complete, security-fixed (service_role-only, explicit user, no client self-grant), and Lane-B-return-shape-compatible (with the loud Task 7 param + restore-path update).

---

## Open questions for the maintainer

1. **RC event type for non-consumable skin purchases.** This plan routes on `NON_RENEWING_PURCHASE` (RevenueCat's canonical event type for non-subscription, non-consumable one-time products, and the type the superseded monetization ADR deleted a handler for — spec §13.5). If the skin products are configured in RevenueCat/App Store Connect as a different product class (e.g. genuinely "non-consumable" surfaced under a different RC event type), the `buildCosmeticGrant` type filter in Task 3 must match. **Confirm the exact RC event `type` string the skin SKUs emit** before deploy (Task 6 Step 4 sandbox test will reveal it if unsure). Low-risk to change: it is one string constant in one builder + its test.
2. **ADR supersession (spec §13.5) — RESOLVED 2026-07-25.** Maintainer chose to keep direct skin IAP; the superseding ADR is written: `docs/decisions/2026-07-25-cosmetics-non-consumable-iap.md` (clarifies premium-entitlement stays subscription-only, sanctions non-consumable *cosmetic* IAP, and pins clean refund semantics — a skin refund revokes a cosmetic entitlement, not consumables). It must land (be committed) before shipping IAP to users. No longer an open question.
3. **Lane B Task 7 restore-path rework (NEW — from the security fix).** Because `grant_cosmetic_iap` is now service_role-only, Lane B's client `grantSkinIap` direct RPC call is dead (permission-denied) and its restore reconcile (`reconcileSkinIapsFromCustomerInfo`) must switch from "call the grant RPC" to "call `Purchases.restorePurchases()` + re-sync; the webhook grants". This is spelled out in the CONTRACT CHANGE header. **Confirm Lane B Task 7 is updated to the webhook-only model before Lane B's IAP tasks go user-visible.** If reinstall-restore proves unreliable in practice (RC not re-firing the transaction), the documented future option is a receipt-verified client-callable restore RPC — a separate, scoped follow-up, NOT the un-gated `authenticated` grant that was just removed.

---

## Pre-store-enablement follow-ups (from independent /review 2026-07-26)

An independent `/review` (gstack + codex) of this merged Lane A-bis work (branch `feat/lantern-cosmetics`) **approved it for merge** but flagged the following edge cases that matter **only once real refunds flow on live store SKUs**. The à-la-carte cosmetic IAP feature is **not yet enabled on the App Store** (the SKUs are not live), so none of these are live-user-facing today. **None are client-exploitable, and none regress the existing subscription or consumable handling** — the entire cosmetic grant/clawback surface is gated behind the SKUs being live on the store. The P1 items below MUST be closed before those SKUs are enabled; the P2 items are cleanups.

### P1 — fix before enabling the IAP SKUs on the store

- [ ] **I-1 — `created_inventory` tracks row-creation, not entitlement provenance.** `clawback_cosmetic_iap` deletes the `user_cosmetics` row whenever the matched ledger (`cosmetic_iap_grants`) row's `created_inventory = true`. That flag records only "this grant was the INSERT that first created the inventory row," which is **not** the same as "this IAP is the sole reason the user owns the skin." Two break sequences:
  - (a) IAP-A creates the `user_cosmetics` row → the user *later* earns the same skin legitimately via Noor/milestone (`unlock_cosmetic`, `acquired_via <> 'iap'`) → refunding IAP-A deletes the now-legitimately-earned ownership.
  - (b) IAP-A creates the row (`created_inventory=true`) → a *later* IAP-B for the **same** skin records `created_inventory=false` (row already existed) → refunding IAP-A deletes ownership even though IAP-B is paid-for and unrefunded.
  - **Fix:** before the delete in `clawback_cosmetic_iap`, **skip the delete** if EITHER (i) any *other* non-revoked `cosmetic_iap_grants` row exists for the same `(user_id, item_id)`, OR (ii) any `user_cosmetics` row for that `(user_id, item_id)` has `acquired_via <> 'iap'`. (Still clear the ledger row's `revoked_at`/reset the equipped column as today — only the *ownership delete* becomes conditional.)
  - **Risk today:** low — one SKU per skin and refunds are rare, so shipping as-is is defensible. Must be closed before scale / before multiple SKUs can map to one skin.

- [ ] **I-2 — refund-before-grant is permanently lost (no tombstone).** If a `CANCELLATION`/refund webhook arrives *before* the corresponding grant has been recorded, `clawback_cosmetic_iap` finds no ledger row, returns `not_found`, and **writes nothing**. A later grant retry (RC redelivery of the purchase) then succeeds normally, so the item stays owned **after** a refund — the refund is silently dropped.
  - **Fix:** on the `not_found` branch, **insert a tombstone ledger row** (`revoked_at` set, `created_inventory = false`) keyed by the refunded `transaction_id`, and have the grant path **consult/honor** that tombstone (a grant for a tombstoned transaction id must not re-grant ownership). This makes clawback and grant order-independent.

- [ ] **N-1 — `REFUND_REVERSED` is unhandled** (Apple reinstating a previously refunded purchase). The dispatcher currently treats it as an unknown/irrelevant event → `200 skipped`, leaving the user's ownership **revoked** after Apple has un-refunded them. A naive "just re-grant" does NOT fix it: the revoked `cosmetic_iap_grants` row makes `grant_cosmetic_iap` return `already_owned` and insert nothing, so ownership is never restored.
  - **Fix (track — dedicated reinstatement path):** add an explicit `REFUND_REVERSED` handler that **reinstates** the revoked grant (clear `revoked_at`, re-insert the `user_cosmetics` ownership row) rather than routing through the ordinary grant path. Until then, the only recovery is a **same-transaction re-purchase**.

### P2 / nice-to-have

- [ ] **I-3 — `transaction_id` falls back to `event.id` when a real store transaction id is missing** (`supabase/functions/revenuecat-webhook/handler.ts`, ~lines 99–100 in the grant builder and ~lines 139–140 in the clawback builder). A purchase and its later cancellation carry **different** `event.id`s, so if a real store `transaction_id` is ever absent, a refund cannot correlate back to its grant (they hash to different ledger keys). This **mirrors the pre-existing consumable-clawback pattern** and is therefore **NOT a regression** — but on a *permanent* grant (a skin the user keeps) a missed refund is far more visible than on a consumable. **Consider:** quarantine/skip events that have no real store `transaction_id` (log + `200 skipped`) instead of substituting `event.id`.

- [ ] **N-2 — inventory insert isn't rolled back on a ledger `unique_violation`** in `grant_cosmetic_iap`. Only the ledger-insert savepoint rolls back on a concurrent duplicate; the earlier `user_cosmetics` insert is not unwound. **Harmless today:** that inventory insert is `ON CONFLICT DO NOTHING`, and producing an orphan requires the *same* `transaction_id` mapping to *different* `(user_id, item_id)` rows concurrently — effectively impossible with real RevenueCat transaction ids. **Cleanest fix:** make the RPC **ledger-first** — `INSERT INTO cosmetic_iap_grants … ON CONFLICT DO NOTHING RETURNING …`, and only the row that wins the ledger claim proceeds to touch `user_cosmetics`.

- [ ] **N-3 — grant-side guard GUC (`app.cosmetics_rpc`) is unnecessary dead code.** There is **no trigger on `user_cosmetics`** — the `cosmetics_guard()` trigger fires on `user_profiles` **only**. So `grant_cosmetic_iap` setting/resetting `app.cosmetics_rpc` around its `user_cosmetics` insert guards nothing and can be removed. The **clawback-side** GUC **is** needed (clawback writes `equipped_*` on `user_profiles`, which the guard trigger covers) — keep it. Secondary nit: both paths **reset the GUC to `'off'`** rather than restoring the prior value; latent only if these RPCs are ever nested inside an outer trusted operation that relied on the flag being set.

- [ ] **N-4 — `event_timestamp` is built into `CosmeticGrantPayload` but never reaches `grant_cosmetic_iap`.** The grant RPC has no timestamp parameter and uses `now()`, so `cosmetic_iap_grants.granted_at` records **DB-processing time, not the RevenueCat event time**. (Contrast: `clawback_cosmetic_iap` correctly threads `p_event_timestamp`.) **Fix:** either thread the timestamp through to the grant RPC (add a `p_event_timestamp` param, as clawback does) OR **drop the dead `event_timestamp` field** from `CosmeticGrantPayload`.

- [ ] **N-5 — doc-accuracy nit.** The `handler.ts` header comment (~lines 9–14) states that `COSMETIC_SKU_TO_ITEM` mirrors a Flutter map `skinIapProductToItem` in `lib/services/cosmetics_service.dart` — but **that symbol does not exist there yet**; it lands with **Lane B Task 7**. Update the comment once Task 7 adds the map (or, until then, note that the Flutter mirror is *pending Lane B Task 7*).

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-25-lantern-cosmetics-01b-iap-grant-webhook.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks. REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Note: Tasks 1-2 (migrations) can run in a worktree with a local Supabase DB; Tasks 3-5 (Deno) need `deno` on PATH.
2. **Inline Execution** — execute in this session using superpowers:executing-plans with checkpoints.

**Prerequisite scheduling:** this plan (Lane A-bis) must land BEFORE Lane B's IAP tasks (Task 7) become user-visible, and depends on the merged Lane A migrations (`20260726000000`–`…000400`) already applied. It has NO dependency on Lane B, C, D, or E code — but it now imposes a **contract change on Lane B Task 7** (RPC is service_role-only; client grant removed; restore is webhook-driven — see the CONTRACT CHANGE header and Open Question 3). Confirm Open Question 1 (RC event type) before the sandbox deploy in Task 6, and confirm Lane B Task 7 is reworked to the webhook-only restore model before Lane B ships IAP.
