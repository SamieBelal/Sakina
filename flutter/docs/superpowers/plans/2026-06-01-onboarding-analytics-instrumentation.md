# Onboarding Analytics — Verification, Gap Analysis & Implementation Plan (2026-06-01)

**Question that prompted this:** *Was the full Mixpanel suite verified on-simulator — i.e. that every
onboarding event (including where users drop off) is tracked well enough to drive onboarding decisions —
and are there valuable analytics we're NOT tracking?*

**Short answer:**
1. **Instrumentation already exists and is healthier than expected.** Sakina *does* emit a real per-step
   onboarding funnel (`onboarding_step_viewed`/`_completed` with `step_index`, `step_name`, `trimmed`),
   field capture, completion+duration, and abandonment — all firing continuously (verified live in Mixpanel).
2. **But our regression run did NOT rigorously validate the drop-off funnel** — lanes only confirmed events
   "fire." This plan adds that validation.
3. **There ARE real gaps**, the biggest being the paywall-rebuild's `paywall_flow_*` events which are
   **defined but never wired** (0 call sites, 0 events), plus missing A/B `variant_id`, activation-cohort
   retention, and the social-auth-skip property. Best-practice research (cited below) confirms the priorities.

---

## A. Current state — what Sakina tracks today (audited in code + Mixpanel)

| Capability | Event(s) | Properties | Status |
|---|---|---|---|
| Per-step funnel | `onboarding_step_viewed`, `onboarding_step_completed` | `step_index`, `step_name`, `trimmed` | ✅ wired (`onboarding_screen.dart` `_emitStepViewedOnce/_CompletedOnce`; helpers in `analytics_events.dart:287`), firing (3429/3153 last 30d, 127 this wk) |
| Field-level capture | `onboarding_answer_captured` | `key`, `value`, `step_index`, `step_name` | ✅ wired (`trackOnboardingAnswerWithRef` across screens), 1771/30d |
| Completion + duration | `onboarding_completed` + `timeEvent` + super-prop `onboarding_completed=true` + `setUserProperties(profile)` | total duration | ✅ wired (`onboarding_screen.dart:257`), 151/30d |
| Abandonment (delayed) | `onboarding_abandoned_at_page` | `page` | ✅ wired (`onboarding_screen.dart:186`) but fires **only after a 24h+ background gap** (re-engagement signal, NOT immediate drop-off). Verified by Lane B: not exercisable in a QA session w/o time-mock; unit-tested. **Immediate per-step drop-off must be DERIVED from the `onboarding_step_viewed` funnel** (works given `step_index`). Recommend a `debugAbandonmentThreshold` seam for testability. |
| Signup | `signup_method_selected`, `signup_completed`, `signup_failed{reason}` | reason | ✅ wired; `identify(userId)` at signup (3 sites) |
| Flow variant | `trimmed` flag on step events; `stepNames` vs `trimmedStepNames` maps | — | ✅ present but not a global super-property |
| Paywall (coarse) | `paywall_viewed`, `paywall_plan_selected` | — | ✅ wired (`onboarding_screen.dart:112`), 144/30d |
| Rating gate | `rating_gate_shown/skipped/...` | — | ✅ wired |
| Activation candidate | `first_checkin_submitted` (step_name `first_checkin`) | — | ⚠️ defined — **verify it fires & adopt as activation event** |

**Verdict:** the onboarding funnel foundation is solid — `step_index` + `step_name` + `trimmed` is exactly
what drop-off analysis needs. This is *not* a rebuild; it's targeted gap-filling + validation.

## B. Gaps vs. best practice (research-backed)

Research synthesis (Mixpanel, Amplitude, Lenny's, Reforge/Aakash Gupta, RevenueCat, Digia — full citations
in the research appendix at the bottom). Priorities:

| # | Gap | Severity | Best-practice source |
|---|-----|----------|----------------------|
| G1 | **`paywall_flow_*` events dead** (`paywall_flow_loader_shown/plan_shown/journey_shown/dropoff` — 0 call sites). The paywall-rebuild's intended granular funnel (loader→plan→journey→dropoff, pages 22–26) is uninstrumented. | **High** | RevenueCat Funnels (per-step paywall conversion/dropoff) |
| G2 | **No global `variant_id` super-property** for A/B testing onboarding/paywall changes. `trimmed` exists only on step events. Without it you can't compare flow variants cleanly. | High | Mixpanel Funnels Advanced (breakdown by variant + significance) |
| G3 | **Activation not formalized.** `first_checkin_submitted` exists but isn't used as the activation event, no `time_to_activate`, no activation-cohort retention. Activation is THE metric linking onboarding→retention. | High | Lenny's (activation metric), Reforge setup/aha/habit |
| G4 | **No `auth_method` property** on auth steps. Social-auth skips pages 18→21 (per CLAUDE.md) → looks like a false drop-off cliff in the funnel. | Medium | Mixpanel cohorts / "segment, don't assume" |
| G5 | **Pre-auth → post-auth stitch unverified.** `identify()` at signup but no `alias()`; need to confirm anonymous onboarding steps (pages 0–18) merge to the signed-up user so the funnel doesn't break at signup. | Medium | Mixpanel identity merge / alias guidance |
| G6 | **No explicit `trial_started` / `purchase` / `paywall_dismissed`** in the onboarding paywall (have `paywall_closed`; `paywall_purchase_completed` referenced in funnel JSON but unverified). | Medium | RevenueCat, Amplitude trial metrics |
| G7 | **`docs/analytics/onboarding_funnel.json` is a stale placeholder** — says "replace with real export," references `step_viewed`/`paywall_purchase_completed` that don't match actual event names (`onboarding_step_viewed`). | Low | — |
| G8 | No `onboarding_skipped` for optional steps; `onboarding_field_submitted` partially covered by `answer_captured`. | Low | Digia step set |

## Implementation status (2026-06-01)

**Shipped + on-device verified (the two core-loop P0s):**
- ✅ **`check_in_completed`** — emitted in `daily_loop_provider.dart` (both `discoverName` discover path and `answerCheckin` questionnaire path) via a static `onAnalyticsEvent` hook wired in `main.dart`. Properties: `path`, `name` (clean transliteration), `tier_changed`, `is_duplicate`. **Verified:** fired once with `path="discover"` driving the Home muḥāsabah on a sim → Mixpanel.
- ✅ **`session_started`** — emitted in `app_lifecycle_observer.dart` on a genuine background→foreground. **Verified on device:** controlled test (cold launch + 3 quick + 2 real resumes) → exactly 2 events; cold-start and quick/transient resumes suppressed.
- Migration for the F-01 revoke committed at `supabase/migrations/20260601000000_revoke_public_execute_on_notification_eligibility.sql` + regression test `supabase/tests/notification_eligibility_grant_test.sql`.

**⚠️ Lesson (logged):** the first `session_started` gate checked `_lastState == paused`, but on iOS the lifecycle state immediately before `resumed` is `inactive`/`hidden`, never `paused` — so it never fired. On-device verification (not unit reasoning) caught it. Correct approach: gate on a `_backgroundedAt` timestamp set ONLY on `paused`/`detached`, with a min-duration threshold, consumed on resume. Apply this pattern to any future lifecycle-gated event.

**Still TODO (P0 backlog — see retention-audit/RETENTION-COVERAGE-SUMMARY.md):** subscription-lifecycle events (webhook + client purchase), notification attribution (sent/opened), store purchase events, paywall_flow_* wiring (F-08), streak telemetry.

## C. Implementation plan

### P0 — ship first
1. **Wire `paywall_flow_*` (G1).** In the paywall-flow screens (pages 22–26; see `lib/features/paywall/` + `onboarding_screen.dart` paywall section), fire `paywall_flow_loader_shown`/`_advanced`, `paywall_flow_plan_shown`/`_continued`, `paywall_flow_journey_shown`/`_continued`, and `paywall_flow_dropoff` (on exit) — each with `{variant_id, page_index}`. Constants already exist in `analytics_events.dart:35-41`.
2. **Add `variant_id` super-property (G2).** In `main.dart` analytics init / onboarding start, `setSuperProperties({'onboarding_variant': trimmed ? 'trimmed' : 'legacy', 'rating_gate': Env.ratingGateEnabled})` so every event is segmentable. Extend to a real experiment id when A/B infra exists.
3. **Formalize activation (G3).** Confirm `first_checkin_submitted` fires on first muḥāsabah completion; add `time_to_activate` (timeEvent from `onboarding_completed` → first check-in). Adopt it as the **activation event** (first check-in → first Name result).
4. **Fix the funnel definition (G7).** Rewrite `docs/analytics/onboarding_funnel.json` with the real event names (below).

### P1 — diagnosis & monetization
5. **`auth_method` property (G4)** on `signup_method_selected` / a super-prop, tagging email vs google vs apple, so the page-18→21 social skip is filterable (not false drop-off).
6. **Verify identity stitch (G5)** — empirically confirm a user's funnel includes their pre-auth steps after `identify()`; if not, add `alias()` at the password/social-auth completion.
7. **Paywall monetization events (G6):** `trial_started{plan_id,trial_length}`, `purchase{plan_id,price,is_trial}`, `paywall_dismissed{last_action}` in the onboarding paywall.

### P2 — refinement
8. `onboarding_skipped{step_index}` for optional steps; per-step `time_on_step` p50/p75 dashboards; activation-cohort retention (activated vs not, D1/D7/D30); activation-to-paid conversion; channel/source segmentation.

### Corrected `onboarding_funnel.json` (P0 item 4)
```json
{
  "name": "Onboarding → Activation → Paywall",
  "conversion_window": "1 day",
  "order": "specific",
  "funnel_steps": [
    { "event": "onboarding_step_viewed", "filter": "step_index = 0", "name": "Onboarding start" },
    { "event": "onboarding_step_completed", "filter": "step_index = 0", "name": "First check-in done" },
    { "event": "signup_completed", "name": "Account created" },
    { "event": "onboarding_completed", "name": "Onboarding done" },
    { "event": "paywall_viewed", "name": "Paywall viewed" },
    { "event": "paywall_flow_plan_shown", "name": "Plan shown" },
    { "event": "purchase", "name": "Subscribed" }
  ],
  "breakdowns": ["onboarding_variant", "auth_method", "$os"],
  "abandonment_events": ["onboarding_abandoned_at_page", "paywall_flow_dropoff"]
}
```

## D. End-to-end test plan (iOS Simulator + Mixpanel MCP)

For each new/fixed event, validate **fire-on-sim → property correctness → funnel buildability**.

### D1. Per-event on-simulator validation
Driver: `ios-simulator` MCP (UDID-pinned), fresh account per run. For each event:
1. Drive the UI to the trigger (e.g. advance each onboarding page → expect `onboarding_step_viewed{step_index:n}`).
2. After firing, query Mixpanel **`Run-Query`** (project 4013350, insights, `math:total`, `dateRange` today) filtered to confirm the count incremented **and the properties are present** (use a `breakdown` on `step_index`/`variant_id` to confirm).
3. Screenshot the UI state as evidence (`sips -Z 1600`).

| Event | Sim trigger | Assert (Run-Query) |
|---|---|---|
| `onboarding_step_viewed` | advance each page | count += per page; breakdown by `step_index` shows each step; `step_name` populated; `onboarding_variant` set |
| `onboarding_step_completed` | advance past page | per-step; `time_on_step` present |
| `onboarding_answer_captured` | submit a field | `key`/`value`/`step_index` present |
| `onboarding_abandoned_at_page` | background-kill mid-flow | fires with `page` (Lane B) |
| `onboarding_completed` | finish flow | total duration; super-prop set |
| `first_checkin_submitted` (activation) | complete first muḥāsabah | fires; `time_to_activate` present |
| `paywall_flow_loader/plan/journey_shown` | reach pages 22–24 | **NEW — currently 0**; each fires with `variant_id` |
| `paywall_flow_dropoff` | exit paywall via X | fires with `last_step` |
| `purchase` / `trial_started` | (Lane P — physical device, real StoreKit) | fires with `plan_id`,`price` |

### D2. Funnel buildability (the actual "can we analyze drop-off?" proof)
Via Mixpanel `Run-Query report_type:funnels` (use `Get-Query-Schema('funnels')` for shape):
- Build the ordered funnel from the corrected definition above, **conversion window = 1 day**, **Specific Order**.
- Break down by `onboarding_variant` (trimmed vs legacy — Lane A vs Lane B data) and `auth_method`.
- Confirm per-step conversion %, the largest drop step, and Time-to-Convert render. This is the artifact PMs use to decide onboarding changes.
- Build an **activation-cohort retention** report: cohort = fired `first_checkin_submitted`; compare D1/D7 vs non-activated — validates the activation event is causal before committing to it as North Star.

### D3. Regression guard
- Add a widget/unit test asserting each onboarding page emits `onboarding_step_viewed` with the right `step_index` (pins the funnel against future refactors — the trim refactor is exactly the kind of change that could silently break it).
- A `paywall_flow_*` wiring test (would have caught G1).

## E. What this plan does NOT cover (scope)
- Server-side / warehouse analytics (Mixpanel only here).
- Acquisition attribution (`app_install`/`first_open` from the attribution SDK) — P2.
- The actual A/B experiment framework (only the `variant_id` plumbing to enable it).

---

## Appendix — research citations
Mixpanel Funnels (https://docs.mixpanel.com/docs/reports/funnels) + Advanced (https://docs.mixpanel.com/docs/reports/funnels/funnels-advanced) · Flows (https://docs.mixpanel.com/docs/reports/flows) · Appcues×Mixpanel onboarding funnels (https://www.appcues.com/blog/mixpanel-funnels-user-onboarding) · Galaxy funnel modeling (https://www.getgalaxy.io/learn/glossary/funnel-analysis-modeling-in-mixpanel) · Amplitude North Star (https://amplitude.com/blog/product-north-star-metric) + 7% rule (https://amplitude.com/blog/7-percent-retention-rule) + freemium/trial (https://amplitude.com/blog/freemium-free-trial-metrics) · Lenny's activation metric (https://www.lennysnewsletter.com/p/how-to-determine-your-activation) · Aakash Gupta onboarding metrics (https://www.news.aakashg.com/p/how-to-measure-onboarding-advanced) · Reforge setup/aha/habit (https://www.retention.blog/p/deep-dive-into-activation-and-retention) · RevenueCat Funnels (https://www.revenuecat.com/blog/company/funnels-public-beta/) · Digia mobile onboarding metrics (https://www.digia.tech/post/mobile-app-onboarding-metrics/) · hoop.dev instrumentation pitfalls (https://hoop.dev/blog/onboarding-process-analytics-tracking-turning-guesswork-into-precision)
