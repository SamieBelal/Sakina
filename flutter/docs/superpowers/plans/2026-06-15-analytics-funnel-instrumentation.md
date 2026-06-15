# End-to-End Funnel Instrumentation — segment by feature flag

**Date:** 2026-06-15
**Status:** Plan (not yet implemented)
**Source:** 4-agent instrumentation audit (onboarding pages · guided tour · paywall · identity plumbing), 2026-06-15.
**Goal:** Make the entire onboarding → guided tour → paywall funnel measurable **per feature-flag combination**, so we can tell *which variant of each experience converts and where each one drops off.*

---

## 0. Principle: one funnel, sliced by dimensions — NOT separate analytics per flag

We do **not** create different events per flag (that's event sprawl and unmaintainable). We keep **one canonical funnel** and attach the **flag state as dimensions (Mixpanel super properties)** on every event. Then any funnel can be broken down by `onboarding_trim`, `hard_paywall_flow`, `tour_variant`, app version, etc. — and any combination of them — in the Mixpanel UI without new instrumentation.

This is the single most important architectural decision: **the flags become breakdown dimensions, not separate event streams.**

---

## 1. The experience matrix (what we're differentiating)

| Flag | Code source | Dimension we register | Effect on the funnel |
|---|---|---|---|
| `onboarding_trim_enabled` (default true) | `onboarding_screen.dart:179` | `flag_onboarding_trim` (bool) | 20-page trimmed vs 27-page legacy onboarding; changes which `step_name`s exist |
| `hard_paywall_after_tour_enabled` | `appSession.hardPaywallFlowEnabled` | `flag_hard_paywall` (bool) | **Hard flow:** onboarding paywall events suppressed, real wall is post-tour. **Soft flow:** onboarding paywall fires on page 19, no post-tour wall |
| `tour_ab_enabled` (default false) + assignment | `onboarding_tour_controller.dart` | `flag_tour_ab` (bool) + `tour_variant` (`slim`/`full`/`none`) | slim (7-step) vs full (13-step) guided tour |
| `guided_tour_enabled` (default true) | `onboarding_tour_controller.dart:104` | `flag_guided_tour` (bool) | tour shown at all vs skipped |

**Today's production experience** = trimmed onboarding + hard paywall + slim tour (tour A/B off). The experiment will vary `tour_variant` while holding the others.

**Critical interaction the audit surfaced:** `flag_hard_paywall` changes *where the paywall lives*. So the paywall funnel MUST also carry a `placement` property (`onboarding` / `hard_wall` / `soft_inapp`) — the flag dimension alone isn't enough because the same flag value can route to different surfaces. `placement` + the flag super-properties together make every paywall funnel unambiguous.

---

## 2. Foundation — the experiment-context super-property layer

Register a canonical set of dimensions so **every** event is segmentable. Super properties attach to all *subsequent* events (no backfill), so they must be set as early as possible. The flags are already primed at boot via `AppConfigService.primeCache` (`main.dart:136`), so they're available before the first funnel event.

**Canonical dimensions (all registered as super properties):**

| Property | Type | Set where | Notes |
|---|---|---|---|
| `app_version` | string | app boot | **Replace hardcoded `'1.0.0'`** (`main.dart:197`) with `package_info_plus`. Without this, no release-over-release comparison is possible. |
| `platform` | string | app boot | already set (`main.dart:196`) |
| `flag_onboarding_trim` | bool | app boot (after primeCache) | from `onboarding_trim_enabled` |
| `flag_hard_paywall` | bool | app boot | from `hard_paywall_after_tour_enabled` |
| `flag_tour_ab` | bool | app boot | from `tour_ab_enabled` |
| `flag_guided_tour` | bool | app boot | from `guided_tour_enabled` |
| `tour_variant` | string | tour start (`_recordVariant`) | `slim`/`full`; promote from the per-user property to a **super property** so EVERY event (retention, paywall) segments by arm, not just tour events |
| `is_premium` | bool | after premium resolves + on change | lets you exclude already-converted users from funnels |

**Mechanism:** add `AnalyticsService.registerExperimentContext({...})` (thin wrapper over `setSuperProperties`) and call it:
1. At boot, right after `primeCache` completes, reading the four flags.
2. At tour start, adding `tour_variant`.
3. When `PurchaseService.isPremium()` first resolves and whenever entitlement changes, adding `is_premium`.

**Naming convention:** flag booleans are prefixed `flag_`; experience/outcome dimensions are bare (`tour_variant`, `is_premium`). Document this once so analysts can find them.

---

## 3. Per-stage fixes (close the dark steps from the audit)

### Stage A — Onboarding pages
- **A1 (bug, P1).** Fix `onboarding_answer_captured.step_name` corruption: `trackOnboardingAnswer` (`analytics_events.dart:49`) hardcodes the legacy 27-page name map while the live flow is trimmed → wrong `step_name` on every answer from index 4+. Thread the active map via `stepNamesFor(trimmed:)`.
- **A2.** Add `signup_email_submitted` in `sign_up_email_screen.dart` `_submit` so email-screen completion is distinguishable from password-screen drop.
- **A3 (optional).** Retire the duplicate answer event: pages 3/5/8 fire both `survey_answered` and `onboarding_answer_captured`. Standardize on one schema.

### Stage B — Guided tour
- **B1 (P1).** Add `variant` (and `step_index` where missing) to **all** tour events: `tour_step_viewed`, `tour_step_advanced`, `tour_completed`, `tour_skipped`, `tour_anchor_timeout`. Today only `tour_started` has `variant`. Without this, per-step funnels mis-attribute across A/B arms (same `step_index` = different step in slim vs full). *(Largely moot once `tour_variant` is a super property per §2, but adding it on-event keeps the funnel self-contained and is cheap.)*
- **B2.** Emit `tour_start_skipped` for ALL non-start reasons (`already_checked_in`, `cold_offline`, `no_auth`), not just `disabled` — and add a `tour_offered` event at gate resolution (`progress_screen.dart`). Closes the `onboarding_completed → tour_started` dark gap (users who finish onboarding but never see the tour).
- **B3.** Add a mid-tour abandonment event: make `AppLifecycleObserver` tour-aware and emit `tour_backgrounded {step_id, step_index, variant}` on `paused`/`detached` while the tour is active. This is the only way to separate *abandoned-on-step-N* from explicit skip/timeout — the biggest real tour drop.
- **B4.** Add `{variant, step_count, final_step_id}` to `tour_completed`; tag `replay()` with its resolved variant.

### Stage C — Paywall (largest blind spot)
- **C1 (P0).** Emit `paywall_viewed` from `PaywallScreen.initState` (`paywall_screen.dart:266`) for **all three surfaces**, carrying `placement` (`onboarding`/`hard_wall`/`soft_inapp`) + `hard_gate`. Today the hard wall fires **no** view event and most soft entries don't either → no view→trial rate for the most important gate. Replace the page-level onboarding emitter with this.
- **C2 (P0).** Instrument the native StoreKit sheet (the dark CTA→trial step): in `PurchaseService.purchaseSubscription` (`purchase_service.dart:421`) emit `purchase_sheet_presented`; in the cancel branch (`paywall_screen.dart:572`) emit `purchase_sheet_cancelled`; in the failure branches (`:574,:580`) emit `purchase_sheet_failed {reason}`. Closes the ~15% CTA→trial gap that is currently invisible.
- **C3 (P0).** Add `placement` to `paywall_cta_tapped` and client `trial_started`. Thread a `placement` param through the `PaywallScreen` constructor (router already differentiates `router.dart:115` vs `:128`).
- **C4.** Emit `paywall_safety_valve_used` in `_continueViaValve` (`paywall_screen.dart:326`); add a bridge event on the daily-cap→paywall `onUpgrade` tap.

### Stage D — Plumbing / identity
- **D1 (P1).** `flush()` on `paused`/`detached` in `AppLifecycleObserver` — today events only flush at `onboarding_completed`, so mid-onboarding churners (the exact drop-off cohort) can lose all queued events.
- **D2.** Wire the existing dead `AnalyticsService.reset()` into the sign-out / delete-account paths (`app_session.dart:187`, `settings_screen.dart`) to stop cross-user contamination on shared/QA devices.
- **D3.** Add a true `app_install` (once, guarded by its own SharedPreferences flag — not the `onboarding_completed` proxy) and an `onboarding_started` event, so install→start and a clean funnel entry exist.

---

## 4. Canonical end-to-end funnel (target schema)

Ordered events an analyst chains into one funnel; every event also carries the §2 super properties.

| # | Event | Key props | Applies when |
|---|---|---|---|
| 1 | `app_install` | — | first launch |
| 2 | `onboarding_started` | — | all |
| 3 | `onboarding_step_viewed` | `step_index, step_name` | all (per page) |
| 4 | `signup_method_selected` → `signup_completed`/`signup_failed` | `method` | all |
| 5 | `onboarding_completed` | duration | all |
| 6 | `tour_offered` → `tour_started` | `variant` | `flag_guided_tour` |
| 7 | `tour_step_viewed` | `step_index, step_id, variant` | per step |
| 8 | `tour_completed` / `tour_skipped` / `tour_anchor_timeout` / `tour_backgrounded` | `variant, step_id` | tour end |
| 9 | `paywall_viewed` | `placement, hard_gate` | all paywall surfaces |
| 10 | `paywall_cta_tapped` | `placement, plan` | — |
| 11 | `purchase_sheet_presented` → `purchase_sheet_cancelled`/`failed` | `placement, plan, reason` | StoreKit |
| 12 | `trial_started` / `subscription_started` | `placement, plan` (client) · `product_id` (server webhook) | conversion |

---

## 5. Phasing

- **Phase 1 — Foundation ✅ DONE 2026-06-15:** §2 super-property layer (`flag_*` + `tour_variant` + real `app_version` via `package_info_plus`) in `main.dart`/controller, flush-on-background (D1), step_name fix (A1). Tests: `test/services/analytics_phase1_test.dart`. After this, *every existing event* is segmentable by flag.
- **Phase 2 — Paywall dark steps ✅ DONE 2026-06-15:** C1–C4 — `paywall_viewed` from `PaywallScreen.initState` for all 3 surfaces + `placement` on view/cta/trial; `purchase_sheet_presented/cancelled/failed`; `paywall_safety_valve_used`; removed the duplicate onboarding-page emitter. Tests: `test/features/paywall/paywall_placement_analytics_test.dart`.
- **Phase 3 — Tour completeness ✅ DONE 2026-06-15:** B1–B4 — `variant` (+`step_index`) on all tour events; `tour_start_skipped` reasons for every non-start path; `tour_offered`; `tour_backgrounded` abandonment; enriched `tour_completed`. Tests: `test/features/tour/onboarding_tour_instrumentation_test.dart`.
- **Phase 4 — Quality/identity ✅ DONE 2026-06-15:** D2 `reset()` on signout (static `AppSessionNotifier.onAnalyticsReset` hook) + delete-account; D3 `app_install` (once, own SharedPreferences flag) + `onboarding_started`; A2 `signup_email_submitted`; A3 dropped the duplicate `survey_answered` on intention/familiarity/attribution (kept on the legacy `quran_connection` rollback screen); `is_premium` super property (boot + refresh on `premiumStateProvider` change); dropped the IAP-banner duplicate `paywall_viewed`. Tests: `test/core/app_session_test.dart`, `test/features/onboarding/sign_up_email_analytics_test.dart`, updated `iap_to_sub_upsell_banner_test.dart`. **All four phases of the funnel-instrumentation plan are now complete.**

Each phase: `flutter analyze` + `flutter test` green, plus unit tests asserting the new props/events fire (mirroring the `dua_built`/variant tests already added).

---

## 6. How you'll read it (the payoff)

Once Phase 1 lands, in Mixpanel you build the funnel `onboarding_step_viewed[0] → onboarding_completed → tour_started → tour_completed → paywall_viewed → trial_started` **once**, then:
- **Breakdown by `tour_variant`** → slim vs full tour conversion + per-step drop (the A/B read).
- **Breakdown by `flag_hard_paywall`** → hard vs soft paywall conversion.
- **Filter `flag_onboarding_trim=true`** → only the live trimmed cohort.
- **Breakdown by `app_version`** → did the change help release-over-release.
- **Filter `is_premium=false`** → exclude already-converted users.
All from one funnel, no new events per question.

---

## 7. Decisions to confirm + external check

1. **Naming convention:** `flag_*` for flag booleans, bare names for outcomes (`tour_variant`, `is_premium`). OK?
2. **Scope/phasing:** ship Phase 1 first (foundation) and read existing events segmented before building Phases 2–4? Or batch more.
3. **Duplicate events (A3) + `reset()` on signout (D2):** retire/standardize now or defer?
4. ✅ **VERIFIED 2026-06-15 (Simplified ID Merge):** confirmed empirically via Mixpanel MCP — funnel `onboarding_step_viewed{step0, anonymous}` → `signup_completed` converts at 80% (→ `tour_started` 48%), which is only possible if pre/post-signup events share one distinct_id. The funnel stitches per-user. (Re-verify if the project's identity-merge setting is ever changed.)

---

## Risks

- **Super-property backfill:** dimensions only attach going forward. Mitigated by setting flags at boot (already primed) — but `tour_variant`/`is_premium` won't be on the earliest events (acceptable; they're resolved later by nature).
- **Don't rename existing live events** — analysts/dashboards depend on them. Only ADD props/events.
- **PII:** never put display name / email values in props (only booleans like `display_name_set`).
- **Hard-paywall suppression interaction:** when `flag_hard_paywall=true` the onboarding paywall is intentionally silent; the `placement=hard_wall` view event (C1) is what makes that cohort's paywall measurable. Verify the two don't double-count.
