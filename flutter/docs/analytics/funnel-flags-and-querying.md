# Funnel analytics: feature-flag dimensions & how to query

**Audience:** anyone (human or AI agent) querying Mixpanel for the onboarding → guided tour → paywall funnel.
**Last updated:** 2026-06-15 (Phases 1–3 of the funnel-instrumentation plan shipped).
**Plan of record:** [`docs/superpowers/plans/2026-06-15-analytics-funnel-instrumentation.md`](../superpowers/plans/2026-06-15-analytics-funnel-instrumentation.md).
**Mixpanel project:** `4013350`. **RevenueCat project:** `proje6681c8c`.

---

## TL;DR — the one rule

There is **ONE funnel**. The feature flags are **breakdown dimensions** (Mixpanel super properties) on every event — NOT separate event streams. To compare "hard vs soft paywall" or "slim vs full tour," you build the funnel once and **break it down / filter by a super property**. Never look for flag-specific event names; there are none.

---

## Identity is intact (verified 2026-06-15)

The funnel stitches per-user across the anonymous→signed-up boundary. Verified empirically (not just assumed): a funnel from the anonymous pre-signup `onboarding_step_viewed{step_index=0}` → `signup_completed` converted at **80%**, and → `tour_started` at 48%. That is only possible if pre- and post-signup events share one `distinct_id` → the project behaves as **Simplified ID Merge**. The app calls `identify()` at signup (`sign_up_password_screen.dart`, `save_progress_screen.dart`) and never resets identity. **Implication:** you can stitch the whole funnel by `distinct_id` + timestamp; no special handling needed. (If the project is ever switched to Original ID Merge, this breaks — re-verify after any Mixpanel identity-setting change.)

---

## The flag → dimension map (super properties)

Registered at app boot (`lib/main.dart`) + tour start, so they ride on **every** event. Convention: flag booleans are prefixed `flag_`; outcomes/dimensions are bare.

| Super property | Type | Source flag / origin | What it differentiates |
|---|---|---|---|
| `flag_onboarding_trim` | bool | `onboarding_trim_enabled` (default true) | trimmed 20-page onboarding (true) vs legacy 27-page (false) |
| `flag_hard_paywall` | bool | `hard_paywall_after_tour_enabled` | hard post-tour wall + suppressed onboarding paywall (true) vs soft onboarding paywall (false) |
| `flag_tour_ab` | bool | `tour_ab_enabled` (default false) | whether the slim-vs-full tour A/B is running |
| `tour_variant` | string | `assignTourVariant` (50/50 when `flag_tour_ab`) | `slim` (7-step) vs `full` (13-step) guided tour |
| `flag_guided_tour` | bool | `guided_tour_enabled` (default true) | tour shown at all |
| `app_version` | string | `package_info_plus` (e.g. `1.1.0+2`) | release-over-release comparison |
| `platform` | string | `defaultTargetPlatform` | iOS / Android |
| `is_premium` | bool | `PurchaseService.isPremium()` (boot + refresh on `premiumStateProvider` change) | exclude already-converted users from funnels |

### The experience matrix
Today's production experience = `flag_onboarding_trim=true` + `flag_hard_paywall=true` + `tour_variant=slim` (A/B off). The flags interact — most importantly **`flag_hard_paywall` moves where the paywall lives**, so paywall analysis ALSO needs the `placement` event property (below), not just the flag.

---

## Canonical funnel events

Every event also carries the super properties above. Build funnels by chaining these and breaking down by a super property.

| Stage | Event | Key event-level props |
|---|---|---|
| Onboarding entry | `app_opened` `{is_first_open}` · `onboarding_step_viewed` `{step_index}` | per-page funnel via `step_index` |
| Onboarding answers | `onboarding_answer_captured` `{key, step_index}` | `key` = canonical question id (NO `step_name` — see note) |
| Signup | `signup_method_selected{method}` → `signup_completed` / `signup_failed{method}` | auth path |
| Onboarding done | `onboarding_completed` | carries total duration |
| Tour offer/start | `tour_offered{variant}` → `tour_started{variant}` / `tour_start_skipped{reason}` | `reason` ∈ disabled/already_checked_in/cold_offline/no_auth/already_seen |
| Tour steps | `tour_step_viewed{step_index, step_id, variant}` · `tour_step_advanced{step_id, via, variant}` | **funnel across arms by `step_id`, NOT `step_index`** (same index = different step in slim vs full) |
| Tour end | `tour_completed{variant, step_count, final_step_id}` · `tour_skipped{at_step_id, step_index, variant}` · `tour_anchor_timeout{step_id, step_index, variant}` · `tour_backgrounded{step_id, step_index, variant}` | `tour_backgrounded` = silent mid-tour abandonment (distinct from skip/timeout) |
| Paywall view | `paywall_viewed{placement, hard_gate}` | `placement` ∈ `onboarding` / `hard_wall` / `soft_inapp` |
| Paywall intent | `paywall_cta_tapped{placement, plan}` | |
| **StoreKit sheet** | `purchase_sheet_presented{placement, plan}` → `purchase_sheet_cancelled{placement, plan}` / `purchase_sheet_failed{placement, plan, reason}` | the previously-dark CTA→trial step |
| Conversion (client) | `trial_started{placement, plan, hard_gate}` | surface-attributed |
| Conversion (server) | `subscription_started` (+ renewed/cancelled/expired) | from RevenueCat webhook; `{product_id, store, period_type, is_trial}` — **no `placement`** (the webhook can't know the surface; use client `trial_started` for surface attribution) |
| Other surfaces | `paywall_closed` · `paywall_exit_offer_shown/accepted` · `paywall_safety_valve_used{placement}` · rating_gate_* · paywall_flow_loader/plan_* | |

---

## How to query — worked examples

**Slim vs full tour, full funnel** (the A/B read):
- Funnel: `tour_started` → `tour_completed` → `paywall_viewed` → `trial_started`.
- Break down by **`tour_variant`**. Filter to dates `flag_tour_ab=true`.
- For per-step tour drop-off, funnel `tour_step_viewed` chained by **`step_id`** (not `step_index`) and break down by `tour_variant`.

**Hard vs soft paywall conversion:**
- Funnel: `paywall_viewed` → `paywall_cta_tapped` → `purchase_sheet_presented` → `trial_started`.
- Break down by **`flag_hard_paywall`** OR by **`placement`** (`hard_wall` vs `onboarding` vs `soft_inapp`).

**Where do CTA-tappers drop on the Apple sheet:**
- Funnel: `paywall_cta_tapped` → `purchase_sheet_presented` → `trial_started`. The gap to `trial_started` (and the `purchase_sheet_cancelled` count) is the StoreKit abandonment that used to be invisible.

**Did the slim-tour release help (release-over-release):**
- Any funnel, break down by **`app_version`**.

**Only the live trimmed cohort:** filter `flag_onboarding_trim = true`.

---

## Gotchas (read before trusting a number)

- **Always exclude the 54 test distinct_ids** in `docs/qa/mixpanel-orphaned-distinct-ids.json`.
- **Conversion events only from ≥2026-06-03** (`trial_started` shipped then).
- **New events (Phases 1–3) ship in the app binary** — they only populate for users on the **next release build**. `dua_built`, `journal_entry_created`, `purchase_sheet_*`, `tour_offered`, `tour_backgrounded`, `placement`, and all `flag_*`/`tour_variant`/real `app_version` super properties have **no history before that build ships**. Don't expect them on the current live cohort.
- **Super properties don't backfill.** They attach going forward from when they're set (boot for flags, tour-start for `tour_variant`). The earliest events of a session may predate `tour_variant`/`is_premium`.
- **`onboarding_answer_captured` has NO `step_name`** (it was historically wrong-mapped). Use `key` (canonical question id) + the `flag_onboarding_trim` super property.
- **`paywall_viewed` is single-source** (as of Phase 4): only `PaywallScreen.initState` emits it, always with `placement`. The IAP-to-sub banner's old duplicate `paywall_viewed{trigger:...}` was removed (it still fires `iap_to_sub_banner_tapped` as the entry-point signal). No more soft-in-app double-count.
- **Identity resets on sign-out / delete-account** (Phase 4): `AnalyticsService.reset()` now fires there, so a new user on the same device starts a fresh distinct_id. Pre-Phase-4 data may show cross-user contamination on shared/QA devices.
- **`subscription_started` (server) carries no `placement`** — for surface attribution use the client `trial_started`.
- **Tour `step_index` is not comparable across arms** — always pivot to `step_id` for cross-variant per-step funnels.
- **`onboarding_started` over-counts raw events** — it fires once per `OnboardingScreen` mount, so a user killed mid-onboarding and relaunched re-fires it. As a funnel denominator, count **unique users** (or filter `entry_page == 0`), not raw event total.
- **Do NOT flip `tour_ab_enabled` mid-experiment.** Variant assignment is a stable per-user hash *while the flag is on*; toggling it off mid-run reassigns in-flight users to slim (and a force-killed user resuming the tour can switch arms). Set it once at experiment start, leave it until the read is done.
