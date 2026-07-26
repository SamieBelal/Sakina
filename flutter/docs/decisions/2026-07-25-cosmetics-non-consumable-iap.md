# Cosmetic Non-Consumable IAP (amends the Subscription-Only Monetization ADR)

**Decision:** Sanction **non-consumable** cosmetic IAP (à-la-carte lantern skins), alongside subscriptions and the existing consumable IAPs.
**Date:** 2026-07-25
**Amends:** [`monetization-model.md`](./monetization-model.md) (2026-04-17, "Subscription-only")
**Context:** Lantern Cosmetics feature — see `docs/superpowers/specs/2026-07-25-lantern-cosmetics-design.md` (§13 items 4–7) and the Lane A-bis plan `docs/superpowers/plans/2026-07-25-lantern-cosmetics-01b-iap-grant-webhook.md`.

## What the 2026-04-17 ADR actually decided (clarification)

The prior ADR's headline "Subscription-only" is shorthand for one specific rule: **the `premium` entitlement is sold only as an auto-renewing subscription** — you cannot buy premium as a one-time purchase. That rule is **unchanged and still correct.**

That ADR did **not** make the app subscription-exclusive: it explicitly retained the Store's **consumable** IAPs (Tokens `sakina_tokens_100/250/500`, Scrolls `sakina_scrolls_3/10/25`). So the app already sells non-subscription IAPs. What that ADR removed was:
- the one-time `sakina_premium` **premium-entitlement** SKU (lifetime premium), and
- the `NON_RENEWING_PURCHASE` webhook handler (unneeded once premium was subscription-only).

## What changes now

Cosmetic skins may be sold as **à-la-carte non-consumable purchases** (`sakina.skin.obsidian` / `sakina.skin.masjid` / `sakina.skin.crystal` → catalog items `obsidian_gold` / `masjid_brass` / `crystal_star`). These are **cosmetic goods, not the premium entitlement** — buying a skin never grants `premium`, and premium is still subscription-only. This reintroduces the `NON_RENEWING_PURCHASE` handler the prior ADR deleted, plus a refund/restore path — built in Lane A-bis.

Skins remain acquirable three ways (all named + direct — **no gacha/loot boxes ever**, per the Shariah boundary in the spec §3): earned **Noor**, purchasable **Tokens**, or à-la-carte **non-consumable IAP**.

## Why this is safe against the prior ADR's objections

The 2026-04-17 ADR's reasons #4/#5 avoided one-time products because of *"idempotent one-time bonus crediting"* and *"one-time refunds would require reversing granted tokens, which is ugly."* Those objections were about crediting **consumable** balances. They do not bite here:

1. **Idempotent crediting is solved, not avoided.** Lane A-bis grants ownership through `grant_cosmetic_iap`, idempotent on the store transaction id via a `cosmetic_iap_grants` ledger (mirrors `noor_grants`). A webhook retry or a client-initiated restore is a safe no-op.
2. **Refund semantics are clean, not ugly.** A skin refund revokes a **cosmetic entitlement** (`clawback_cosmetic_iap`) — it does not claw back spent consumables. If the refunded skin was equipped, the equipped slot resets to the always-owned `classic_gold`. There is no partial-consumption problem because a skin is never consumed.
3. **Product→item verification + à-la-carte gating** live server-side in the catalog (`cosmetic_catalog.iap_product_id`); unknown or non-à-la-carte SKUs are rejected.

## Ruling: premium-exclusive skins vs à-la-carte ownership (maintainer, 2026-07-25)

Two distinct concepts must not be conflated:

- **À-la-carte non-consumable skins** — bought with real money → **permanent** ownership in `user_cosmetics`, kept forever (survives a lapse). This is what this ADR sanctions.
- **Premium-exclusive (subscriber-perk) skins** — the rotating monthly-exclusive + guaranteed seasonal skins that come with a subscription. **Ruling: equippable ONLY while a premium source is active; NEVER converted to permanent ownership.** When premium lapses (including trial/gift/referral premium ending), the perk skin is no longer equippable and the equipped slot falls back to a default the user owns. Trial/gift/referral users do **not** permanently keep the monthly exclusive.

This keeps a single, enforceable premium definition and prevents "grab a perk skin during a 3-day trial, keep it forever."

## Implications

| Area | Before | After |
|---|---|---|
| Premium entitlement | Subscription-only | **Unchanged** — still subscription-only |
| Consumable IAP (tokens/scrolls) | Sold | **Unchanged** |
| `NON_RENEWING_PURCHASE` handler | Deleted | **Restored, scoped to skin SKUs only** (Lane A-bis) |
| Non-consumable cosmetic IAP | N/A | **New** — permanent, idempotent-granted, refundable/restorable |
| Premium-exclusive skins | N/A | Equippable **while premium active**, never converted to ownership |
| Refund of a skin | N/A | Revokes cosmetic entitlement; equipped → `classic_gold` |

## Ongoing invariants (carried forward + added)

- Premium status is still `entitlements.active.containsKey('premium')` (client) / `has_active_premium_entitlement(auth.uid())` (server). **Buying a skin does not touch this.**
- À-la-carte skin ownership is server-authoritative in `user_cosmetics`, granted only via `grant_cosmetic_iap` (never a client write).
- Premium-exclusive equip is gated on live premium; the server `equip_cosmetic` is the authority.

## Revisit triggers

- Skin-IAP refund rate is materially higher than subscription refunds (non-consumable refund abuse).
- App Store / Play Store change non-consumable economics.
- Cosmetics revenue does not justify the added reconciliation surface (then collapse to Tokens/Noor-only, dropping Lane A-bis).
