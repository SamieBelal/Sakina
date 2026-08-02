# Monetization Model

**Decision:** Subscription-only.
**Date:** 2026-04-17
**Closes:** TODOS-revenuecat-integration.md H6, unblocks disposition of H7 (deferred, not needed), B2 (not needed).

## What we're shipping

Sakina Premium is sold exclusively as an **auto-renewing subscription** through the onboarding paywall:

- `sakina_sub_annual` — $49.99/year
- `sakina_sub_weekly` — $4.99/week

Both grant the `premium` entitlement in RevenueCat. Entitlement state is the single source of truth, sourced from RevenueCat webhooks and stored in `public.user_subscriptions`.

## What we're removing

- The Store screen's `sakina_premium` one-time SKU and associated client-side token/scroll grant code
- The Store screen's Premium tab entirely
- The `NON_RENEWING_PURCHASE` webhook handler (was planned under Task B2, now skipped)
- Any reference to "Premium forever" or lifetime purchase in copy

The Store screen keeps its Tokens and Scrolls tabs (consumable IAPs). Those are unchanged.

## Why

1. **One path to Premium is simpler for users.** Two flows with the same outcome creates confusion and support load.
2. **Industry standard.** Calm, Hallow, Headspace, Glorify — all subscription-only. Users already understand the model.
3. **Recurring revenue compounds.** Subscriptions retain better long-term than one-time sales, especially for wellness apps where value grows with consistent use.
4. **Simpler engineering surface.** No idempotent one-time bonus crediting, no `NON_RENEWING_PURCHASE` webhook event, no dual-product entitlement reconciliation.
5. **Cleaner refund semantics.** Sub refunds are a pro-rata lapse on the entitlement; one-time refunds would require reversing granted tokens, which is ugly.

## Implications

| Area | Before | After |
|---|---|---|
| Paywall | Subscription CTAs | Unchanged |
| Store Premium tab | Existed, sold lifetime premium | **Removed** |
| `claim_daily_reward` 5x multiplier | Gated on `has_active_premium_entitlement` | Unchanged — still correct |
| `grant_premium_monthly` | Gated on `has_active_premium_entitlement` | Unchanged — still correct |
| RevenueCat dashboard | Had `sakina_premium` SKU | Detach from the `premium` entitlement, archive the product |
| H6 (TODOS) | Open | **Closed** |
| H7 (TODOS) | Open, blocked on H6 | **Closed as WON'T-DO** |
| B2 | Blocked on C1 | **Deleted from plan** |

## Ongoing invariants

- `entitlements.active.containsKey('premium')` is the only way the client determines premium status
- `public.has_active_premium_entitlement(auth.uid())` is the only way the server determines it
- Both converge on the `user_subscriptions` row populated by the webhook
- No client-side grants. Ever. Premium perks come from server entitlement checks, not client calls to `earnTokens()`

## Revisit triggers

Revisit this decision if **any** of the following happens:

- Retention analysis shows subscriptions convert < 1% on the paywall after 90 days
- Customer support gets repeat asks for a "lifetime" option
- A competitor launches a one-time model that steals share
- App Store / Play Store change subscription economics materially

Don't revisit because a single loud user asks for it. Anchor on data.
