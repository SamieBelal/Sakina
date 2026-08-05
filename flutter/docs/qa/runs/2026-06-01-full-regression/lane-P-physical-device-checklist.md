# Lane P — Physical Device Checklist (run on YOUR iPhone)

Everything here needs **real StoreKit** and/or **real push receipt**, which a simulator can't do.
Run the `default` build (`flutter run --dart-define-from-file=env.json -d <your-iphone>`), signed into a
**RevenueCat sandbox tester** Apple ID. Reset sandbox first via `asc-mcp sandbox_clear_purchase_history`.

Tick each box; log failures to `docs/qa/findings/2026-06-01-<slug>.md`. DB checks via Supabase MCP; billing via RevenueCat MCP.

## P1 — Paywall purchase / cancel / restore
- [ ] Onboarding paywall renders **annual + weekly** pricing from live offerings (not placeholder).
- [ ] **Purchase (annual)** → StoreKit sheet → success → entitlement granted → routed to Home.
- [ ] DB: `user_subscriptions` row upserted; `user_profiles.is_premium` (or premium source) reflects active.
- [ ] RC MCP `get-customer` shows active entitlement for your Supabase user id.
- [ ] **Cancel mid-purchase** → stays on paywall, no entitlement, no crash.
- [ ] **Restore** with entitlement → routed Home. **Restore** with none → user-facing error (not blank/hang).
- [ ] Force offerings load failure (airplane mode) → recoverable error UI, not blank paywall.

## P2 — Webhook → premium state
- [ ] After purchase, `revenuecat-webhook` fires → `is_premium` flips true (Supabase MCP).
- [ ] After cancel/expire (or sandbox auto-renew lapse) → webhook flips it back. Check `get_logs` for the function.

## P3 — Cancellation feedback survey (the real trigger)
- [ ] With an active sandbox sub, **cancel** in iOS Settings → reopen app.
- [ ] `user_subscription_cancellation_transition` detects the transition → **survey sheet appears** once.
- [ ] Submit a reason → `cancellation_feedback` row written; Mixpanel `cancellation_feedback_submitted`.
- [ ] Repeat on a second cancel within the recency window → **no re-prompt** (recency guard, 4f66c2b).
- [ ] Dismiss-by-swipe path → treated as implicit skip → `cancellation_feedback_dismissed` (2a210f5).
- [ ] Webhook cancellation **push** fires **only because sandbox-gated** (89c795a) — confirm via OneSignal MCP `view_message_history`.

## P4 — IAP→sub upsell (PR #24) purchase
- [ ] As an IAP-state user, the upsell banner is tappable → completes the actual sub purchase.
- [ ] `iap_to_sub_banner_tapped` then entitlement transition; `iap_upsell_banner_dismissed_at` set if dismissed.

## P5 — Push receipt (real APNs)
- [ ] Set a daily reminder time; confirm the daily notification **arrives** at that local time (honors `reminder_time`).
- [ ] Trigger a referral confirm (referee converts) → **referral-confirm push arrives** on referrer's device.
- [ ] Cold-launch the app the next morning → **no "Open Settings" nag loop** (5b07d16).

## P6 — AI bypass on device (sanity, parallels Lane C)
- [ ] Day-1 freebie offered on first AI feature; token bypass purchase deducts 25 tokens; cap blocks the 3rd.
- [ ] Premium user (after P1 purchase) **never sees** the bypass/token-spend prompt (short-circuit).

## P7 — Store consumable purchase analytics (PR #37, engagement-economy-analytics)
Only the purchase **outcomes** are device-gated — StoreKit can't complete a consumable buy on the
simulator. `store_viewed` + `pack_selected` are sim-verifiable and do NOT belong here.
- [ ] Open Store → tap a **tokens** pack → StoreKit sheet → success → Mixpanel `store_purchase_succeeded` `{pack_id, amount, kind: tokens, price, currency}` with the **real** localized price/currency (not the hardcoded UI string).
- [ ] Tokens balance credited once (no double-credit vs. the orphan-recovery listener); toast shows.
- [ ] Repeat for a **scrolls** pack → `store_purchase_succeeded` `{kind: scrolls, …}`.
- [ ] **Cancel** the StoreKit sheet mid-purchase → `store_purchase_cancelled` `{pack_id, amount, kind}`; no credit, no error toast.
- [ ] Force a failure (airplane mode after the sheet, or a declined sandbox card) → `store_purchase_failed` `{…, reason: platform}`; user-facing "Purchase failed" toast.
- [ ] (Edge) If the consumables offering is missing/unconfigured → `store_purchase_failed` `{reason: unavailable}` + "Pack not available yet" toast.
- [ ] Confirm `price` is a numeric double and `currency` is the ISO code (e.g. `USD`) on every success event — these power the Store revenue dashboard.

> Coordinate with Lane C/D agents: they seed and verify the same DB tables on simulators with separate
> accounts, so use a **distinct Apple ID + Supabase account** here to avoid cross-contaminating assertions.
