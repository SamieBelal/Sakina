# Funnel analytics: feature-flag dimensions & how to query

**Audience:** anyone (human or AI agent) querying Mixpanel for the onboarding → guided tour → paywall funnel.
**Last updated:** 2026-07-30 — added **the daily question funnel (One Ship W4)**: six new events, `entry_source`, `attempt`, the bucket boundaries, and the `check_in_completed` extension (`path` is still `'discover'`). Two caveats to read before trusting a number: abandon is not one minus the answer rate, and in the `attempt ≥ 2` slice `answered` exceeds `shown` by design. Previous update: 2026-07-30 — added the `surface` property map (four screens, one beat-flow event set; `reveal_deck_*` must be filtered by it). Previous update: 2026-07-25 — `flag_tour_ab` RETIRED (A/B concluded; `tour_ab_enabled` key deleted from app_config and the super property unregistered from installs). It remains valid ONLY as a filter on historical events (pre-2026-07-25); never re-add instrumentation for it. Previous update: 2026-06-15 (Phases 1–3 shipped).
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
| `flag_tour_ab` ⚠️ RETIRED 2026-07-25 | bool | ~~`tour_ab_enabled`~~ (key deleted) | historical events only — the slim-vs-full tour A/B concluded; everyone gets slim |
| `tour_variant` | string | always `slim` since 2026-07-25 (A/B retired) | `slim` (7-step) vs `full` (13-step, historical) guided tour |
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

## The `surface` property — four screens share one beat-flow event set

The tap-through reflection flow (`BeatRevealFlow`) is one widget rendered by four different screens, and they all emit the **same event names**. `surface` is an **event property** (not a super property) and is the ONLY thing separating them. Never query a `reveal_deck_*` or `reflect_beat_*` event without it.

| `surface` | Emitted by | Events carrying it |
|---|---|---|
| `onboarding_reveal` | `onboarding_reveal_screen.dart` | `lantern_kindled` · `reveal_deck_completed` · `reveal_deck_abandoned` |
| `daily_unseal` | `muhasabah_screen.dart`, deck path (the D1 queue unseal) | `reveal_deck_completed` · `reveal_deck_abandoned` · `reflect_beat_advanced` · `reflect_flow_skipped` |
| `muhasabah` | `muhasabah_screen.dart`, AI path (the ordinary daily reflection) | `reflect_beat_advanced` · `reflect_flow_skipped` |
| `reflect` | `reflect_screen.dart` | `reflect_beat_advanced` · `reflect_flow_skipped` |

The deck events additionally carry `deck_id` + `name_id`, and `reveal_deck_abandoned` carries `beat_index` (how far the user got before leaving).

**Onboarding deck-completion rate** — the named T0+2wk health metric — is `reveal_deck_completed` ÷ (`reveal_deck_completed` + `reveal_deck_abandoned`), **filtered to `surface = onboarding_reveal`**. `daily_unseal` was minted specifically so the D1 reveal stays out of that number.

---

## The daily question funnel (One Ship W4)

**Why this one is instrumented harder than it looks like it needs to be.** W4 (the daily loop asks a question) ships **in the same release as the paywall wave**, and the One Ship's keep read is a pre/post comparison against a trailing-90d baseline with **no control arm**. At the T0+6wk read we will know whether the ship worked and **not which half did it** — that trade was accepted deliberately (spec §2). This within-wave funnel is the compensation: it is the only way to find out whether the *question* carried its weight.

### `check_in_completed` was EXTENDED, not forked

`path` is still **`'discover'`**. The original prescription wanted `'feeling'` now that the loop asks something; that would have broken every historical D1/D7 comparison built on this event, which is the retention spine. Instead it gained two properties:

| New prop | Values |
|---|---|
| `problem_category` | a `ProblemChip.problemCategory` (`anxiety`/`heavy`/`guilt`/`far_from_allah`/`rizq`/`unseen`/`unspoken`) or `unmatched` |
| `input_mode` | `typed` \| `chip` |

Both are **null on every path that did not go through the question** — a metered re-roll (`resetToday()` returns a blank state), a restored pre-W4 day blob, the dormant `answerCheckin`. Null is the honest value and segments cleanly as "no answer"; do not read it as a data gap.

`problem_category` reuses the **7-chip taxonomy**, deliberately NOT the 30-question onboarding option bank — that is a different vocabulary (emotions, avoidances, needs) and reusing it would fork segmentation away from `acquisition_promise.problem_category` and make the daily loop incomparable to onboarding. A typed sentence is keyword-mapped to the same chip key a tap would have produced, so the two input modes segment identically.

### The five new events

| Event | Props | Fires when |
|---|---|---|
| `daily_question_shown` | `entry_source` | the question surface mounts — **not on a re-ask** |
| `daily_question_answered` | `problem_category`, `input_mode`, `char_count_bucket`, `attempt` | the answer is submitted |
| `daily_question_off_topic` | `attempt` | the classifier rejected an answer and asked the user to rephrase |
| `daily_question_skipped` | `dwell_ms_bucket` | the explicit **"Not right now"** tap |
| `daily_question_abandoned` | `dwell_ms_bucket` | backgrounded or navigated away **without deciding** |
| `daily_reward_claimed` | `trigger` (`answer_submit`), `day` | the daily reward is actually granted |

**`daily_question_skipped` and `daily_question_abandoned` are NOT the same event and must never be merged.** A skip says the *placement* was wrong for that moment — the user deferred, and the question, reveal and reward all stay collectible from the home CTA for the rest of the day. An abandon says the *question* was wrong. The difference between "people want this later" and "people don't want this" is the entire readout for the defer design.

**`daily_reward_claimed` counts grants, not calls.** The claim RPC is idempotent and server-authoritative; a replay returns the same ladder state without granting anything and emits nothing. `day` is the 7-day ladder position (1-7) the grant landed on.

### `attempt`, and the off-topic classifier — read this before trusting the funnel

`attempt` is **a dimension, not a stage**: `1` on the first try, `2`+ after the classifier rejected an answer and asked the user to rephrase. It rides on `daily_question_answered` and `daily_question_off_topic`. Minting a separate re-ask *event* would have forked the funnel at step two and left every existing segment silently under-counting the people who had to try twice — so segment on this instead.

**A re-ask emits NO `daily_question_shown`, NO `daily_question_skipped` and NO `daily_question_abandoned`.** A rephrase is a continuation of one asking, not a second one: the user was asked once and *we* failed to parse what they said, so counting it as another ask would record our classifier's failure as the user being asked again — backwards for the one thing this event exists to measure. An outcome without its show would corrupt those rates permanently, while the information itself stays derivable (below).

**Two consequences in the data. Both are correct and both look broken:**

1. In the `attempt ≥ 2` slice, **`answered` exceeds `shown`** — the re-answer emits `answered` with no new `shown` behind it.
2. In that same slice **there are no abandon events at all**, so someone who gives up at the re-ask appears nowhere directly. **Do not go looking for the missing `daily_question_abandoned`; it does not exist and its absence is not a bug.**

**Give-ups at the re-ask are a subtraction, not an event:**

```
daily_question_off_topic{attempt=1} − daily_question_answered{attempt=2}
```

= people who were told to rephrase and never came back with one. This is the number that says what the classifier costs, and it is the only way to see it.

**`daily_question_off_topic` is a product finding, not a funnel curiosity.** The classifier has **never fired on real daily text**: before W4 the loop sent the revealed card's own blurb to the reflection engine, so it was structurally unreachable on this path, and it has only ever run against Reflect — which is opt-in and self-selected. W4 points it at every daily user's sentence about grief, money and prayer at once, **with no measured false-positive rate**.

So `daily_question_off_topic ÷ daily_question_answered` is a genuine first-run measurement, and a high rate means **a large number of people are being asked to re-type something that was hard to type once**. The question that number answers is *should we loosen the classifier* — not *how is the funnel doing*. Watch it from day one rather than at the T0+2wk read.

### `entry_source` — and the default that makes it trustworthy

| Value | Means |
|---|---|
| `day_open` | the app put the question in front of the user on open. **The only entry the app initiates on the user's behalf.** |
| `widget` | a home-screen widget tap (deliberately takes precedence over the day-open overlay) |
| `home_cta` | any in-app tap — the home CTA, a metered re-roll, a quest card, a cap-sheet bypass |

Every in-app navigation to `/muhasabah` tags itself `?entry=…`; an **untagged** navigation is the day-open path and reads as `day_open`. That default is why the day-open route needs no ceremony, and it is the scheme's one weakness — a new untagged push added later would silently inflate `day_open` rather than showing up as an obviously wrong value. `test/features/daily/daily_question_entry_source_test.dart` greps `lib/` and fails the build on any untagged navigation, with a two-file allowlist. **If that test is ever weakened, stop trusting `entry_source` splits.**

### Bucket boundaries

Bucketed on the device, never computed from a raw value in Mixpanel — **the raw values are not sent**.

| `char_count_bucket` | `1_20` \| `21_60` \| `61_140` \| `141_300` \| `301_plus` — inclusive upper, as the names read |
|---|---|
| **`dwell_ms_bucket`** | `0_2s` \| `2_5s` \| `5_15s` \| `15_60s` \| `60s_plus` — **exclusive** upper (`0_2s` is [0, 2000)) |

### Privacy — the rule that outranks every metric here

**The user's verbatim answer never leaves the device.** Not as a property, not truncated, not hashed, not in an error payload, and not on the off-topic path. What ships is a bucketed character count and a chip category. This is enforced structurally (`charCountBucket` takes an `int`, so no refactor can hand it the String) and by a test that asserts the answer text — and every distinctive word of it — appears in **no** emitted payload on any path. If you ever see answer text in Mixpanel, that is an incident, not a feature.

---

## How to query — worked examples

**Slim vs full tour, full funnel** (the A/B read):
- Funnel: `tour_started` → `tour_completed` → `paywall_viewed` → `trial_started`.
- Break down by **`tour_variant`**. Filter to dates `flag_tour_ab=true` (historical windows only — the A/B retired 2026-07-25).
- For per-step tour drop-off, funnel `tour_step_viewed` chained by **`step_id`** (not `step_index`) and break down by `tour_variant`.

**Hard vs soft paywall conversion:**
- Funnel: `paywall_viewed` → `paywall_cta_tapped` → `purchase_sheet_presented` → `trial_started`.
- Break down by **`flag_hard_paywall`** OR by **`placement`** (`hard_wall` vs `onboarding` vs `soft_inapp`).

**Where do CTA-tappers drop on the Apple sheet:**
- Funnel: `paywall_cta_tapped` → `purchase_sheet_presented` → `trial_started`. The gap to `trial_started` (and the `purchase_sheet_cancelled` count) is the StoreKit abandonment that used to be invisible.

**Did the slim-tour release help (release-over-release):**
- Any funnel, break down by **`app_version`**.

**Only the live trimmed cohort:** filter `flag_onboarding_trim = true`.

**Did the question itself carry its weight (the W4 within-wave read):**
- Funnel: `daily_question_shown` → `daily_question_answered` → `check_in_completed{path='discover'}`.
- Break down by **`entry_source`** to see whether the day-open, the widget and the home CTA convert differently — a question that works when the user chose to open it and fails when the app opened it is a *placement* finding, not a question finding.
- Break down `daily_question_answered` by **`input_mode`** for the free-text-vs-chips bet: free text primary was a deliberate divergence from the one-tap-first research, and the chips are the hedge. If chip share is overwhelming, the divergence did not pay.

**Is the defer a deferral or an exit (the tripwire worth watching from day one):**
- Same-day return rate = `daily_question_skipped` → `daily_question_shown{entry_source='home_cta'}` **by the same user, same local day**, over skips.
- If skippers do not come back, "Not right now" is a polite way out of the core loop rather than a deferral within it. This is the headline metric for the whole skip design, not a secondary one.

**Did moving the reward claim preserve the ladder:**
- `daily_reward_claimed{trigger='answer_submit'}` per user per day, against `check_in_completed`. The claim moved from *opening the app* to *answering the question* precisely so a day-6 user would not lose their 7-day escalating ladder by not tapping through every beat.
- **Break down by `day`** for the direct read: a healthy re-timing shows users climbing to 6 and 7; everyone stuck at 1 means the ladder is resetting and the move did not do its job.

**Is the off-topic classifier hurting people:**
- `daily_question_off_topic` ÷ `daily_question_answered{attempt=1}`. See the section above for why this is a first-run number with no prior baseline, and why a high one is a reason to loosen the classifier rather than a funnel curiosity.
- The people it cost: `daily_question_off_topic{attempt=1}` minus `daily_question_answered{attempt=2}` — asked to rephrase and never came back with one.

---

## Gotchas (read before trusting a number)

- **Always exclude the 54 test distinct_ids** in `docs/qa/mixpanel-orphaned-distinct-ids.json`.
- **Conversion events only from ≥2026-06-03** (`trial_started` shipped then).
- **New events (Phases 1–3) ship in the app binary** — they only populate for users on the **next release build**. `dua_built`, `journal_entry_created`, `purchase_sheet_*`, `tour_offered`, `tour_backgrounded`, `placement`, and all `flag_*`/`tour_variant`/real `app_version` super properties have **no history before that build ships**. Don't expect them on the current live cohort.
- **Super properties don't backfill.** They attach going forward from when they're set (boot for flags, tour-start for `tour_variant`). The earliest events of a session may predate `tour_variant`/`is_premium`.
- **`onboarding_answer_captured` has NO `step_name`** (it was historically wrong-mapped). Use `key` (canonical question id) + the `flag_onboarding_trim` super property.
- **`paywall_viewed` is single-source** (as of Phase 4): only `PaywallScreen.initState` emits it, always with `placement`. The IAP-to-sub banner's old duplicate `paywall_viewed{trigger:...}` was removed (it still fires `iap_to_sub_banner_tapped` as the entry-point signal). No more soft-in-app double-count.
- **Identity resets on sign-out / delete-account** (Phase 4): `AnalyticsService.reset()` now fires there, so a new user on the same device starts a fresh distinct_id. Pre-Phase-4 data may show cross-user contamination on shared/QA devices.
- **`reveal_deck_*` must be filtered by `surface`** — `onboarding_reveal` and `daily_unseal` share the event names, so an unfiltered query folds D1 into the onboarding deck-completion metric and double-counts users who saw both.
- **`subscription_started` (server) carries no `placement`** — for surface attribution use the client `trial_started`.
- **Tour `step_index` is not comparable across arms** — always pivot to `step_id` for cross-variant per-step funnels.
- **`onboarding_started` over-counts raw events** — it fires once per `OnboardingScreen` mount, so a user killed mid-onboarding and relaunched re-fires it. As a funnel denominator, count **unique users** (or filter `entry_page == 0`), not raw event total.
- **`daily_question_abandoned` is NOT one minus the answer rate.** Abandon fires on backgrounding as well as on navigating away (the OS can reap the app from the background, so waiting for dispose would systematically undercount the likeliest way someone bails). A user who backgrounds the question, comes back, and *then* answers emits **both** `daily_question_abandoned` and `daily_question_answered` for a single `daily_question_shown`. Outcomes therefore sum to slightly **more** than shows. Read abandon as **"left at least once"**, and compute the answer rate from `answered ÷ shown` directly rather than by subtraction.
- **In the `attempt ≥ 2` slice, `answered` exceeds `shown` AND there are no abandon events.** A re-ask emits no second `shown`, `skipped` or `abandoned` (see the `attempt` section) — correct data that reads as broken twice over. Someone who gives up at the re-ask is `daily_question_off_topic{attempt=1}` minus `daily_question_answered{attempt=2}`, never a `daily_question_abandoned`.
- **`daily_question_shown` can legitimately fire twice in one local day.** A metered re-roll calls `resetToday()` and re-shows the question from `home_cta`; a user who backs out and re-taps their widget gets a second correct `widget` show. Only a second **`day_open`** show in one local day is a bug (auto-entry is once per local day), and that one is caught by a debug assert in the app. Do not treat repeat shows as double-counting without checking `entry_source`.
- **W4 events have no history before the W4 build ships** — same rule as the Phase 1–3 events above. `daily_question_*`, `daily_reward_claimed`, and the `problem_category`/`input_mode` props on `check_in_completed` are all new in that binary.
- **`check_in_completed` volume is unchanged by W4** — it was extended, not forked, and `path` is still `'discover'`. If its count moves at the W4 release, that is a real behaviour change (or a bug), not an instrumentation artifact.
- **Do NOT flip `tour_ab_enabled` mid-experiment.** Variant assignment is a stable per-user hash *while the flag is on*; toggling it off mid-run reassigns in-flight users to slim (and a force-killed user resuming the tour can switch arms). Set it once at experiment start, leave it until the read is done.
