# Retention Analytics — Coverage Summary & Prioritized Backlog (2026-06-01)

Synthesis of three parallel audits (`churn-monetization.md`, `habit-loop.md`, `growth-reengagement.md`)
+ the onboarding plan (`docs/superpowers/plans/2026-06-01-onboarding-analytics-instrumentation.md`).
Method: code audit (defined? wired?) + Mixpanel `Run-Query` (firing?) + sufficiency-for-retention judgement.

## The one-line answer
**The features shipped in the last 60 commits are well-instrumented. The core retention engine is not.**
You can measure *acquisition → onboarding → activation* and the *new growth features*, but you **cannot
measure whether users come back, keep their habit, respond to notifications, or churn** — because the
daily loop, notifications, subscription lifecycle, store, and collection emit little or no analytics.

## Coverage scorecard

| Surface | Coverage | Headline |
|---|---|---|
| Onboarding funnel | 🟢 Good | per-step `step_viewed/completed` (+`step_index`,`step_name`,`trimmed`), answer capture, completion+duration |
| Guided tour | 🟢 Complete | end-to-end — but `tour_anchor_timeout` ~31% (F-10 reliability) |
| Rating gate | 🟢 Complete | shown/skipped/continue measurable |
| Cancellation survey | 🟢 Good | best surface — `reason_code`/`period_type`/`is_trial`/`source` |
| IAP→sub upsell banner | 🟢 Good | shown/tapped/dismissed wired+firing |
| Referrals | 🟡 Partial | funnel good; **no install-attribution** (K-factor uncountable), reward event never fired |
| Sakina gift | 🟡 Partial | claim tracked; **no gift→retention linkage** |
| AI bypass / Day-1 | 🟡 Partial | offer→purchase fires; `daily_cap_hit` missing; raw-string hygiene |
| Paywall flow (p22–26) | 🔴 Dark | `paywall_flow_*` all dead (F-08); `cta_tapped` has no purchase outcome |
| **Subscription lifecycle** | 🔴 **Dark** | **ZERO** — webhook + client purchase emit no analytics |
| **Daily loop (muḥāsabah)** | 🔴 **Dark** | no check-in-completed event (either path) |
| **Notifications** | 🔴 **Dark** | no `notification_sent` / `notification_opened` |
| **DAU / return-visit** | 🔴 **Dark** | `app_opened` cold-start only; no resume/session event |
| Streaks | 🔴 Dark | extend/milestone/freeze all uninstrumented |
| Quests / XP / economy | 🔴 Dark | no quest_completed / xp_awarded / level_up |
| Store (real-money packs) | 🔴 Dark | **ZERO** — a monetized surface invisible in analytics |
| Collection / cards / gacha | 🔴 Dark | core gamification loop uninstrumented |

## Prioritized implementation backlog

### P0 — retention is unmeasurable without these
1. **Subscription lifecycle events.** Server-side in `revenuecat-webhook/handler.ts`: emit `subscription_started`, `trial_started`, `renewal`, `cancellation` (+`reason`), `billing_issue`, `expiration` to Mixpanel (import API). Client-side in `paywall_screen._handlePurchase`: `purchase_succeeded`/`_failed`/`_cancelled` {plan_id, price, is_trial}. → enables trial→paid, churn rate, voluntary-vs-involuntary churn, renewal retention.
2. **Daily core-loop event.** `check_in_completed` on BOTH `discoverName()` and `answerCheckin()` paths, with `{path: 'discover'|'questionnaire', streak_day, name_id}`. → THE recurring DAU event; unlocks D1/D7/D30 retention curves + habit-formation rate + path comparison.
3. **Notification attribution.** `notification_sent` (server, `send-scheduled-notifications`) + `notification_opened` {type} (client, OneSignal click listener `notification_service.dart:492`). → push CTR + notification→session lift (your primary retention lever).
4. **Reliable session signal.** `session_started` on app resume (`app_lifecycle_observer.dart:86`), not just cold start. → trustworthy DAU/WAU/MAU.

### P1 — diagnosis & monetization
5. Wire `paywall_flow_*` (F-08) + paywall purchase outcome; add `variant_id` super-property (A/B).
6. **Store purchase events** — real money currently invisible: `store_viewed`, `pack_selected`, `store_purchase_succeeded/_failed/_cancelled`.
7. Streak telemetry: `streak_extended`/`streak_milestone`/`streak_freeze_consumed`.
8. `daily_cap_hit` — the AI-bypass funnel's missing first step.
9. Formalize activation: `time_to_activate` + activation-cohort retention (per onboarding plan G3).

### P2 — completeness & hygiene
10. Collection/cards/gacha engagement events (`card_revealed`{tier}, `tier_up`, `collection_completed`).
11. Quest/XP: `quest_completed`, `xp_awarded`, `level_up`.
12. Referral **install attribution** (deferred deep link) → share→install conversion / K-factor.
13. Gift→retention: window-start + post-expiry-return signals.
14. **Hygiene:** route AI-bypass/Day-1 events through `AnalyticsEvents` constants (currently raw strings → drift risk, read as dead in grep). `auth_method` tag + onboarding skip events (onboarding plan G4/G8).

## The fix pattern (low-friction)
Service-layer providers (gating, daily loop, notifications, purchase) have no Riverpod access, so reuse the
existing **static hook** pattern already wired in `main.dart:191` (`GatingService.onAnalyticsEvent`,
`DailyCapSheet.onAnalyticsEvent`). `tour_*` and `ramadan_gift_*` are good reference implementations.
Widget-layer surfaces (store, collection, paywall screens) call `ref.read(analyticsProvider).track(...)` directly.
Every new event MUST use an `AnalyticsEvents` constant + get a wiring test (F-08 and the raw-string drift
would both have been caught by one).

## Detailed reports
- `churn-monetization.md` · `habit-loop.md` · `growth-reengagement.md`
- Onboarding-specific plan + e2e test plan: `docs/superpowers/plans/2026-06-01-onboarding-analytics-instrumentation.md`
