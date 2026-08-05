# Analytics Coverage Audit — Churn & Monetization Retention Surfaces

**Date:** 2026-06-01
**Scope:** Cancellation feedback survey · Win-back discount · Paywall · Subscription lifecycle (RevenueCat webhook) · IAP→sub upsell banner
**Method:** Code audit (`lib/`, `supabase/functions/`) cross-referenced against `lib/services/analytics_events.dart` (event catalog) and Mixpanel firing counts (project 4013350, `Run-Query`, 30-day relative window).
**Mixpanel business context:** none configured for this org/project.

---

## 1. Coverage matrix

Legend — Defined?: const exists in `analytics_events.dart`. Wired?: ≥1 call site in `lib/` (via `grep -rn AnalyticsEvents.<const>`). Firing: total events, last 30d.

| Surface | Event (const → name) | Defined? | Wired? (call sites) | Firing (30d) | Sufficient for retention? | Gap / recommendation |
|---|---|---|---|---|---|---|
| **Cancellation survey** | `cancellationFeedbackShown` → `cancellation_feedback_shown` | Yes | Yes (1) | 10 | Partial | Carries `source`, `is_trial`. Good. |
| Cancellation survey | `cancellationFeedbackSubmitted` → `cancellation_feedback_submitted` | Yes | Yes (1) | 2 | **Yes** | Carries `reason_code`, `period_type`, `is_trial`, `source`, `has_text`. Best-instrumented surface. |
| Cancellation survey | `cancellationFeedbackDismissed` → `cancellation_feedback_dismissed` | Yes | Yes (1) | 4 | Yes | Carries `period_type`, `source`. |
| **Paywall (onboarding 22-26)** | `paywallViewed` → `paywall_viewed` | Yes | Yes (2) | 144 | Partial | Onboarding fire has no `trigger` prop; only the IAP→sub banner sets `trigger`. Cannot split onboarding vs other entry points. |
| Paywall | `paywallPlanSelected` → `paywall_plan_selected` | Yes | Yes (1) | 189 | Yes | — |
| Paywall | `paywallCtaTapped` → `paywall_cta_tapped` | Yes | Yes (1) | 49 | **No** | Fires on TAP only (intent). No paired success/failure event — see Gap #2. |
| Paywall | `paywallClosed` → `paywall_closed` | Yes | Yes (1) | 174 | Partial | No close-reason / step property. |
| Paywall | `paywallExitOfferShown` → `paywall_exit_offer_shown` | Yes | Yes (1) | 118 | Yes | — |
| Paywall | `paywallExitOfferAccepted` → `paywall_exit_offer_accepted` | Yes | Yes (1) | 7 | Partial | "Accepted" tracked; no explicit "declined/dismissed exit offer" counterpart (inferable from shown−accepted but not direct). |
| **Paywall flow steps** | `paywallFlowLoaderShown` → `paywall_flow_loader_shown` | Yes | **No (0)** | 0 | **No** | DEAD. Loader/plan/journey screens fire only generic `onboarding_step_viewed`. |
| Paywall flow steps | `paywallFlowLoaderAdvanced` | Yes | **No (0)** | 0 | No | DEAD. |
| Paywall flow steps | `paywallFlowPlanShown` | Yes | **No (0)** | 0 | No | DEAD. `personalized_plan_screen.dart` has zero `track()` calls. |
| Paywall flow steps | `paywallFlowPlanContinued` | Yes | **No (0)** | 0 | No | DEAD. |
| Paywall flow steps | `paywallFlowJourneyShown` | Yes | **No (0)** | 0 | No | DEAD. `your_journey_screen.dart` has zero `track()` calls. |
| Paywall flow steps | `paywallFlowJourneyContinued` | Yes | **No (0)** | 0 | No | DEAD. |
| Paywall flow steps | `paywallFlowDropoff` → `paywall_flow_dropoff` | Yes | **No (0)** | 0 | No | DEAD. Cannot locate per-step drop-off inside the 4-page paywall flow. |
| **Subscription lifecycle** | (purchase / renewal / cancel / expiration / billing) | **No** | **No** | 0 | **No** | NO server-side analytics. `revenuecat-webhook/handler.ts` handles all 7 RC event types (INITIAL_PURCHASE, RENEWAL, PRODUCT_CHANGE, UNCANCELLATION, CANCELLATION, BILLING_ISSUE, EXPIRATION) but emits NO Mixpanel/track call — DB write + OneSignal push only. No client purchase-success event either. See Gap #1. |
| **IAP→sub upsell banner** | `iapToSubBannerShown` → `iap_to_sub_banner_shown` | Yes | Yes (1) | 3 | Yes | — |
| IAP→sub banner | `iapToSubBannerTapped` → `iap_to_sub_banner_tapped` | Yes | Yes (1) | 6 | Yes | Tap routes to paywall with `trigger=iap_to_sub_upsell`. |
| IAP→sub banner | `iapToSubBannerDismissed` → `iap_to_sub_banner_dismissed` | Yes | Yes (1) | 3 | Yes | — |
| IAP→sub banner | `iapToSubBannerDismissFailed` → `iap_to_sub_banner_dismiss_failed` | Yes | Yes (2) | 0 | Yes | Failure-path event; 0 is expected (no failures). |
| **Settings premium card** | `settingsPremiumCtaTapped` | Yes | Yes (1) | 16 | Yes | — |
| Settings premium card | `settingsPremiumManageTapped` | Yes | Yes (1) | 17 | Yes | — |
| Settings premium card | `settingsPremiumBillingIssueTapped` | Yes | Yes (1) | 0 | Partial | Wired but 0 fires — billing-issue surface may rarely render; verify it can fire. |
| **Win-back DISCOUNT** | (n/a) | **No** | **No** | 0 | **N/A — feature does not exist** | The `2026-05-14-winback-discount.md` plan was ABANDONED and replaced by the Ramadan/Eid Gift (file body is the gift plan; "original winback-discount plan optimized ARPU at the cost of brand"). No discount product, no SKU, no events. The only "win-back" in code is the E5 **tour-replay push** (`tour_*` events + `winBackPush*` copy in `tour_service.dart`), unrelated to discounts. |

---

## 2. Prioritized list of MISSING events (with the retention decision each informs)

### P0 — Subscription lifecycle analytics (the single biggest gap)
**Missing:** `subscription_started` / `trial_started` / `subscription_renewed` / `subscription_cancelled` / `subscription_expired` / `subscription_billing_issue` (+ `purchase_completed` / `purchase_failed` on the client).
**Where:** `supabase/functions/revenuecat-webhook/handler.ts` already receives every RC lifecycle event and is the authoritative server-side seam — but emits zero analytics. Mirror each `HANDLED_EVENT_TYPES` transition to Mixpanel (server-side track w/ distinct_id = user). Add a client `purchase_completed` / `purchase_failed` in `paywall_screen.dart::_handlePurchase` (today it only fires `paywall_cta_tapped` on tap; success/failure are silent).
**Decisions it unblocks:**
- Trial→paid conversion rate, renewal/retention curves, churn rate, involuntary (billing-issue) vs voluntary churn split.
- Cancel→reactivation (UNCANCELLATION) recovery rate.
- Whether billing-issue users recover or expire (dunning effectiveness).
- True paywall tap→purchase conversion (currently `paywall_cta_tapped`=49 has no success denominator).

### P1 — Paywall flow step instrumentation (defined-but-dead)
**Missing wiring for:** `paywall_flow_loader_shown/advanced`, `paywall_flow_plan_shown/continued`, `paywall_flow_journey_shown/continued`, `paywall_flow_dropoff` (8 consts, all 0 call sites, all 0 fires).
**Where:** `personalized_plan_screen.dart` and `your_journey_screen.dart` (zero `track()` calls); the paywall-flow loader. Today only generic `onboarding_step_viewed` fires for these pages.
**Decision it unblocks:** Per-step drop-off inside the 4-page paywall flow (loader→plan→journey→rating gate→paywall) — i.e. WHERE in the flow users abandon before reaching the paid CTA. Currently you can only see "reached paywall" (144) vs "closed" (174), not which intermediate step bled users.

### P2 — Paywall purchase outcome & close attribution
**Missing:** `purchase_failed` / purchase-cancelled distinction (StoreKit cancel vs error vs missing-entitlement) and a reason/step property on `paywall_closed`.
**Where:** `paywall_screen.dart::_handlePurchase` swallows `PurchasesErrorCode.purchaseCancelledError` and other errors into a local `_errorMessage` with no analytics.
**Decision it unblocks:** Distinguish "tried to buy and StoreKit failed/cancelled" from "never tried." Diagnoses paywall friction vs pricing rejection.

### P3 — Exit-offer decline + trigger completeness
**Missing:** explicit `paywall_exit_offer_declined`; and a `trigger` property on the onboarding `paywall_viewed` fire (only the IAP→sub banner sets it).
**Decision it unblocks:** Exit-offer true accept rate (today inferred from shown−accepted) and entry-point attribution for paywall views (onboarding vs settings vs daily_cap vs upsell).

### P4 — Verify `settings_premium_billing_issue_tapped` reachability
Wired but 0 fires in 30d. Confirm the billing-issue state in `settings_premium_card.dart` can actually render so the event isn't structurally unreachable.

---

## 3. Sufficiency assessment by analysis question

| Retention question | Answerable today? | Blocker |
|---|---|---|
| Why do users cancel? | **Yes** | `cancellation_feedback_submitted.reason_code` + `is_trial` + `source`. Only weakness: low submit volume (2/30d) and a 10→2 shown→submitted drop. |
| Win-back / discount conversion? | **N/A** | Feature was abandoned; nothing to measure. |
| Paywall step drop-off? | **No** | `paywall_flow_*` defined but unwired (P1). |
| Paywall tap→purchase conversion / trial start rate? | **No** | No purchase-success event (P0/P2). |
| Subscription-state retention (renewal, voluntary vs involuntary churn, reactivation)? | **No** | Webhook emits no analytics (P0). |
| IAP→sub upsell funnel? | **Yes** | shown/tapped/dismissed all wired + firing; tap carries `trigger`. |
