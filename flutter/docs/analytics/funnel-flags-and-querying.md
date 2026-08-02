# Funnel analytics: feature-flag dimensions & how to query

**Audience:** anyone (human or AI agent) querying Mixpanel for the onboarding → guided tour → paywall funnel.
**Last updated:** 2026-08-01 — added **One Ship W6 (instrumentation)**: the six new super properties and their provenance/coverage caveats, `acquisition_problem_category` vs `problem_category` side by side, `step_name` as onboarding's join key, the `free_tier_entered` placement caveat, two previously-undocumented super properties (`first_open_date`, `onboarding_completed`), `ai_taste_consumed`/`daily_cap_hit{reason}`, the cap/warmup sheet impression-dismissal pair, the Restore trio, `reflect_started`/`_completed`, `dua_read`, `names_browse_viewed`, the Wave F intake-block events, the honest drop-off funnel (`step_viewed` vs `step_completed`), a satisfaction readout, the RC↔Mixpanel reconciliation query, the `names_met` people property, and the ASC Campaign Links runbook. Plan: [`2026-08-01-one-ship-06-instrumentation.md`](../superpowers/plans/2026-08-01-one-ship-06-instrumentation.md). Previous update: 2026-07-30 — added **the daily question funnel (One Ship W4)**: six new events, `entry_source`, `attempt`, the bucket boundaries, and the `check_in_completed` extension (`path` is still `'discover'`). Two caveats to read before trusting a number: abandon is not one minus the answer rate, and in the `attempt ≥ 2` slice `answered` exceeds `shown` by design. Previous update: 2026-07-30 — added the `surface` property map (four screens, one beat-flow event set; `reveal_deck_*` must be filtered by it). Previous update: 2026-07-25 — `flag_tour_ab` RETIRED (A/B concluded; `tour_ab_enabled` key deleted from app_config and the super property unregistered from installs). It remains valid ONLY as a filter on historical events (pre-2026-07-25); never re-add instrumentation for it. Previous update: 2026-06-15 (Phases 1–3 shipped).
**Plan of record:** [`docs/superpowers/plans/2026-06-15-analytics-funnel-instrumentation.md`](../superpowers/plans/2026-06-15-analytics-funnel-instrumentation.md); W6 plan: [`docs/superpowers/plans/2026-08-01-one-ship-06-instrumentation.md`](../superpowers/plans/2026-08-01-one-ship-06-instrumentation.md).
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
| `install_id` | string (uuid) | `InstallIdService`, minted at first boot, registered before `app_opened` | the join key across Mixpanel and RevenueCat — see the reconciliation query below. NOT an identity alias (`$mixpanelDistinctId` changes at `identify()`; this never does). A reinstall mints a new id, so reinstalls read as fresh arrivals. |
| `onboarding_flow` | string | `reel_v1` \| the legacy kill-switch value; registered inside the onboarding `_flowFuture` continuation, **before** `onboarding_started` (One Ship W6-A) | which onboarding experience this user actually ran. Returning users get it at boot, mirrored from the server via `hydrateUserDataFromBatchRpc`. Never union with the frozen `paywall_exp_arm`. |
| `contract` | string | `problem` \| `sign` (`HookContract`), registered when the hook chip/typed answer resolves | **the primary reel-of-origin dimension (D3)** — behavioural, taken at arrival, near-total coverage (typed input always resolves to `problem`). Two values only: separates the two shipped reels, not any future reel making the same promise. |
| `acquisition_problem_category` | string | the 7-chip taxonomy, registered alongside `contract` | what the user **arrived with**. See "`acquisition_problem_category` vs `problem_category`" below before building anything on it. |
| `reel_hook` / `reel_hook_source` | string / string | `unknown` at onboarding entry → `deep_link` (from a drained `sakina://reel/<id>`) → `self_report` (source-question screen, index 13) | always read together — see the provenance section below. |
| `free_tier_cohort` | string | `reel_v1` \| `legacy`, registered from `GatingService.onProfileHydrated` (NOT at boot) | which free-tier economy governs this user. **Cannot exist on a fresh install until the first `sync_all_user_data`** — expect it absent on the earliest events of a brand-new user's first session, by construction. |
| `first_open_date` ⚠️ undocumented until now | string (ISO 8601) | `main.dart`, `registerBootstrapAnalytics`, `setSuperPropertiesOnce` | first-open cohort dating. Was live and unlisted here before this update. |
| `onboarding_completed` ⚠️ undocumented until now, and NOT an event | bool | `onboarding_screen.dart`, set `true` on first completion | **a durable boolean, not an event** — it reads `true` forever after the first completion. Trivially mistaken for `onboarding_completed` the event (there isn't one under that name); the completion event is `onboarding_completed`'s sibling in the canonical table below, which is a genuinely different thing carrying total duration. Don't build a "completions over time" chart on the super property; it never resets. |

### The experience matrix
Today's production experience = `flag_onboarding_trim=true` + `flag_hard_paywall=true` + `tour_variant=slim` (A/B off). The flags interact — most importantly **`flag_hard_paywall` moves where the paywall lives**, so paywall analysis ALSO needs the `placement` event property (below), not just the flag.

---

## W6 super properties — provenance and coverage (read before segmenting by any of these)

Registered going forward from the point below — Mixpanel never backfills, so an
event before a property's registration point simply lacks it. That is expected,
not a bug, for every row here.

| Property | Absent before | Present from | Why |
|---|---|---|---|
| `onboarding_flow` | the `_flowFuture` continuation resolves | first onboarding event on new installs; boot (mirrored from server) for returning users | registered **above** `_emitEntryFunnelEvents` specifically so `onboarding_started` — the funnel's widest event — carries it |
| `reel_hook` / `reel_hook_source` | same as above | same as above, value `unknown`/`unknown` until upgraded | registered as `unknown`, not omitted, at entry — see below for why that distinction matters |
| `contract` / `acquisition_problem_category` | onboarding entry through the hook screen | the moment the chip/typed answer resolves (screen 0 of the reel flow) | can't exist before the user has answered anything |
| `free_tier_cohort` | app boot, and the whole first session before the first successful sync | after the first `sync_all_user_data` completes | **by construction** — it is a user-scoped value written only by `GatingService.hydrateFromProfile`; there is no way to know it sooner. Check coverage on `paywall_viewed` and `daily_cap_hit`, not on the earliest onboarding events. |

**`reel_hook` / `reel_hook_source` are `unknown`, never absent, before the source screen.** If they were only set once learned, they would be *absent* — not `unknown` — on every event before onboarding index 13, which is most of the funnel. An absent property and an `unknown` value break down differently in Mixpanel, and only `unknown` is honest about "we don't have a data point yet" vs. "no data was possible."

**T0+24h check (someone has to run this manually — it is not automatable from here):** the share of `onboarding_started` carrying `onboarding_flow`, `contract` and `reel_hook_source`. Anything below ~95% is an ordering bug, not sampling noise — a debug-only assert in `AnalyticsService.track()` guards this in dev/test builds, but production coverage still has to be eyeballed once.

### `acquisition_problem_category` vs `problem_category` — same vocabulary, different question

Both use the identical 7-chip taxonomy (`anxiety`/`heavy`/`guilt`/`far_from_allah`/`rizq`/`unseen`/`unspoken`, or `unmatched`) — deliberately, so cross-tabbing them is exactly one breakdown. They are **not** the same property and must never be treated as interchangeable:

| | `acquisition_problem_category` | `problem_category` |
|---|---|---|
| Scope | **super property** | **event property**, on `check_in_completed` and `daily_question_answered` |
| Means | what the user arrived with (the reel hook screen) | what the user answered **today** |
| Set once? | yes, at arrival | fresh per check-in / per daily answer |

They were kept as two keys specifically because a single overloaded `problem_category` super property would have made every chart built on it *right some of the time* — event-level properties win where both exist, so `daily_question_answered` would silently report today's answer under a name that reads as "acquisition." **The question worth asking is the cross-tab**: "arrived with anxiety, answers guilt today" is one query, `acquisition_problem_category` on the funnel breakdown vs `problem_category` on the event.

### `step_name` — onboarding's stable join key (not `step_id`)

`onboarding_step_viewed` and `onboarding_step_completed` both carry `step_name`, resolved per-flow from `AnalyticsEvents.stepNamesFor(trimmed:, reel:)`. The reel flow's 19 steps (indices 0–18) deliberately reuse the six shared screens' existing names, so a funnel keyed on `step_name` joins across the trimmed, legacy and reel flows — only `flag_onboarding_trim` / `onboarding_flow` need to do the segmenting on top. **The tour's join key was `step_id` (`tour_step_viewed{step_id}`); the tour is deleted, and onboarding never had a `step_id` — don't go looking for it.**

`onboarding_answer_captured` still deliberately omits `step_name` (a pre-existing gotcha, unchanged by W6) — use `key` + `flag_onboarding_trim` there instead; see the Gotchas section.

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
| Other surfaces | `paywall_closed{placement}` · `paywall_exit_offer_shown/accepted` · `paywall_safety_valve_used{placement}` · rating_gate_* · paywall_flow_loader/plan_* | `paywall_closed` gained `placement` in W6 (D7) — see the gotcha below for the pre-W6 gap |
| The gate's meter (W6-C) | `ai_taste_consumed{feature, allowance, remaining}` → `daily_cap_hit{feature, reason}` | see "the gate's meter" below |
| Cap/warmup sheets (W6-C) | `cap_sheet_shown{feature, reason, sheet}` → `cap_sheet_dismissed{sheet, method}` | see "the gate's meter" below |
| Restore Purchases (W6-C) | `restore_started` → `restore_completed{premium_active}` / `restore_failed{reason}` | previously zero instrumentation on either surface it lives on |
| Reflect (W6-D) | `reflect_started` → `reflect_completed{off_topic}` | see "Reflect, the browse surface, and `dua_read`" below |
| Names browse (W6-D) | `names_browse_viewed` | fires from `CollectionScreen`, not `NamesScreen` — see below |
| Duʿā read (W6-D) | `dua_read{dua_id, source}` | see below for the exact interaction it means |

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

## The gate's meter, the cap/warmup sheets, and Restore (One Ship W6-C)

Before W6 the gate could say when it BLOCKED someone (`daily_cap_hit`) and never
when it let them through — so a cap-hit rate had no denominator — and the sheets
that carry the block were emitting nothing for the `reel_v1` cohort at all (both
`daily_cap_sheet.dart` events lived on the token-bypass slot W5 removes for that
cohort; `warmup_exhausted_sheet.dart` had zero analytics). All fixed in this
wave.

**The denominator: `ai_taste_consumed{feature, allowance, remaining}`** — fires
on every SUCCESSFUL gated spend. `feature` ∈ `reflect` / `built_dua` /
`discover_name`; `allowance` names which budget was spent: `warmup` (the
lifetime per-feature warmup, `reel_v1`) / `weekly_pool` (the shared Reflect +
Build-a-Duʿā pool, `reel_v1`) / `daily` (the legacy per-day counter). **Never
fires for premium** — `markUsed` short-circuits on the premium check before the
cohort read, so a payer's use is not a "taste."

**The numerator: `daily_cap_hit{feature, reason}`** — `reason` is new in W6 and
is the `GateReason` wire value: `daily_cap` (legacy) / `weekly_pool` /
`reroll_premium` (a second Name today is premium for `reel_v1` — the day-open
reveal itself is unaffected, it consults no gate) / `had_trial_no_budget` (a
lapsed trialer). **The event name did not change and does not fork at T0** —
deliberately (D5): the cap-hit→upgrade funnel needs to stay continuous exactly
across the boundary where the meaning of a "cap" changes from daily to weekly.
Segment by `reason`, and by the `free_tier_cohort` super property for the
cohort split.

**Sheet impression/dismissal: `cap_sheet_shown{feature, sheet, reason?}` →
`cap_sheet_dismissed{sheet, method}`.** `sheet` ∈ `daily_cap` /
`warmup_exhausted`.

⚠️ **`reason` is present on `daily_cap` impressions and ABSENT on
`warmup_exhausted` ones — do not filter on it unless you mean to exclude the
warmup sheet.** This is deliberate, not an omission: the warmup sheet fires on a
SUCCESSFUL use that happened to spend the last warmup budget, so nothing was
refused and there is no `GateReason` to carry. An ill-fitting constant was
declined rather than forced on. A query that filters `cap_sheet_shown` by
`reason` therefore silently drops every warmup impression — and the warmup sheet
is the one a `reel_v1` user meets FIRST, so the exclusion lands hardest on the
newest cohort. Filter on `sheet` when you want one surface, and treat `reason`
as a `daily_cap`-only refinement. **`method` has TWO values, not four**, and it is a
framework limit, not a shortcut: a sheet can be closed four ways (the CTA tap,
a scrim tap, a swipe-down, Android back), but `showModalBottomSheet` completes
its route future identically for the last three — there is no public API to
tell them apart without intercepting gestures at the route level, which this
wave declined to do. `method` is `button` (an explicit decline via the sheet's
own control) vs `dismissed` (any of the other three). If you see a plan or an
old doc promising `scrim`/`swipe`/`back` as separate values, that promise
predates the code and was never shippable as written.

**Restore: `restore_started` → `restore_completed{premium_active}` /
`restore_failed{reason}`**, on both surfaces that offer it
(`paywall_screen.dart`, `store_screen.dart`). `premium_active` on completion
matters because "restore succeeded, found an entitlement" and "restore
succeeded, found nothing" are the same RC call outcome and very different user
experiences — collapsing them would have hidden exactly the silent-failure
churn/support risk this was built to catch.

**`free_tier_entered{placement}`** — fires once-ever per user (a
`SharedPreferences` latch), the first time they dismiss a paywall without
converting. **The name over-promises: it fires on dismissal of ANY placement**,
not only the onboarding gate — `_doClose` in `paywall_screen.dart` runs the
same bookkeeping regardless of which of the four placements (`onboarding` /
`hard_wall` / `soft_inapp` / `post_trial_soft`) the user was looking at.
Recoverable by filtering `placement`; do not read raw volume as "entered free
from onboarding" without that filter.

**`paywall_closed` gained `placement` in W6 (D7).** Before this it was a bare
`track()` with no properties — the only dismissal event that fires from every
placement, so pre-W6 `paywall_closed` volume cannot be broken down by surface
at all; post-W6 it can.

---

## Reflect, the browse surface, and `dua_read` (One Ship W6-D)

**`reflect_started` → `reflect_completed{off_topic}`.** Reflect was
zero-instrumented before this — it emitted `reflect_beat_advanced`,
`reflect_flow_skipped` and `journal_entry_created` and nothing marking a start
or a finish. The pair fires from `ReflectNotifier.submit()`. **The asymmetry is
load-bearing**: a gated submit (the user hit a cap) fires NEITHER event; a
submit that passes the gate but whose AI call then fails fires `started` alone,
with no matching `completed`. That is what makes an OpenAI outage
distinguishable from a wave of users abandoning Reflect — without it the two
look identical in the data. `off_topic` on `completed` keeps the classifier's
cost on Reflect comparable to the daily loop's `daily_question_off_topic`.

**`names_browse_viewed` fires from `CollectionScreen`, not `NamesScreen`.** The
original W6 plan aimed this at `NamesScreen` because an early audit found it
had zero analytics references — true, but incomplete: `NamesScreen` is dead
code, unreferenced by the router or any tab or push. `CollectionScreen`
(`/collection`, the Collection tab) is the 99-Names surface users actually
reach, and that is where the event lives. Deduped per session via a static
latch so a bottom-nav tab-switcher doesn't inflate the count; the latch resets
on next app launch, which is the "session" scope. **If you go looking for this
event on `NamesScreen`, you will not find it, and that is correct.**

**`dua_read{dua_id, source}` — a specific interaction, not a screen mount.**
There is one duas screen and no detail route for an individual duʿā, so "read"
had to be DEFINED before it could be emitted. The chosen definition: a
collapsed→expanded tap on a Related Duʿā card on the built-dua ("Ameen")
screen (`BuiltDuaRelatedCard`), which is why the section header above those
cards literally reads "Tap a dua to read it in full." **`source` currently has
exactly one live value, `built_dua_related`** — there is no second `dua_read`
emit site today, despite the property shape implying multiple sources. The
first related duʿā renders pre-expanded (it anchors the guided-tour heart), so
its initial state does NOT count as a read — only a subsequent collapse→expand
does.

---

## The onboarding intake block (One Ship W6-F)

Seven screens — `carrying_duration`, `heaviest_time`, `told_anyone`,
`names_known`, `help_chips`, `daily_time`, `intake_note` — were a third of the
live reel onboarding flow and emitted nothing before this wave. All seven now
call `trackOnboardingAnswerWithRef`, landing on the existing
`onboarding_answer_captured{key, value, step_index}` event with `key` set to
the screen name above. **`intake_note` is the privacy-sensitive one**: it sends
`intakeNoteLengthBucket(text)` — a bucketed length — and never the note body.
Enforced structurally (the bucket function takes the raw text and returns an
`int`-backed bucket string; there is no code path that could pass the text
itself as the value) and by a source-level test. Same rule as the daily
question's free text: bucket on-device, never send the raw string.

---

## The honest drop-off funnel: `step_viewed` vs `step_completed`

**`onboarding_abandoned_at_page` can only be emitted by users who did not
abandon.** It fires exclusively on app **resume** (`didChangeAppLifecycleState`
in `onboarding_screen.dart`) — the user has to come back to report that they
left. Anyone who backgrounds and never reopens (uninstall, lost interest, the
overwhelming majority of real abandonment) emits nothing, ever. Treat this
event as a **returner** signal — "someone who left AND came back reports
having left at page N" — not as abandonment measurement, and don't build the
drop-off funnel on it.

**The honest signal is `onboarding_step_viewed` without a matching
`onboarding_step_completed`** for the same `step_name`, per user. It requires
no cooperation from a departed user — a view that never resolves into a
completion IS the drop-off, by construction. Build the funnel by chaining
`onboarding_step_viewed` → `onboarding_step_completed` (joined on `step_name`,
per D6 above) and reading the gap at each step as where people actually quit,
rather than by counting `onboarding_abandoned_at_page`.

**One caveat, and it decides your funnel window.** `step_completed` fires only
on FORWARD navigation (`onboarding_screen.dart:474` — back navigation is
treated as abandonment, not completion, which is right). So a user who views
page N, retreats to N−1, and later re-advances past N emits `step_completed(N)`
**late**, not never — `_emitStepCompletedOnce` guards it, so it is a delayed
fire rather than a lost one. A short funnel-conversion window will therefore
read that user as having abandoned page N when they in fact completed it.

Use a conversion window generous enough to absorb a there-and-back
(the whole reel flow is ~19 short screens), and treat an unusually high
drop reading on a step users commonly reverse into as suspect before treating
it as real. A user who retreats and never returns still reads as abandoned at
roughly the right place — just not at the exact page they quit from.

**A skip is not a drop — but the two decline paths report differently, and
the difference is not cosmetic.** Several screens have an explicit decline
(`intake_note`'s "Nothing to add", the source screen's "Rather not say"). All
of them advance the flow, so `step_completed` DOES fire and a considered
decline is never counted as abandonment.

What they do NOT share is the answer event, and you cannot assume one rule:

* **`intake_note` skip → `onboarding_answer_captured` STILL FIRES**, with a
  length bucket (`none` if nothing was typed). Its skip and its Continue run the
  same commit path (`intake_note_screen.dart:107,109`), which is deliberate —
  the screen's own doc treats deleting your text and skipping as one intent.
  Consequence: **you cannot tell a quiet decline from an answered-then-emptied
  note on this step.** If that distinction matters to a question you are asking,
  this event cannot answer it.
* **Source screen "Rather not say" → emits NOTHING.** No answer event, no
  `reel_source_selected`, and no `reel_hook` upgrade.

So `onboarding_answer_captured` present-vs-absent separates answer from skip on
the source screen and NOT on `intake_note`. Read each step's decline path before
building a skip-rate metric across the block.

**Tour events dated after 2026-07-28 mean the kill switch was pulled, not that
the tour is back.** The tour was deleted that date; its emitters
(`tour_step_viewed`, `tour_completed`, etc.) survive only because the
kill-switch legacy flow still renders it, and a `reel_v1` user cannot reach any
of them. If tour events reappear in a post-2026-07-28 funnel, that is useful
signal — someone flipped the kill switch — not noise or a regression to
investigate in the tour code itself.

---

## The satisfaction read: are users liking it?

The W1–W5 build measures whether users MOVE (funnel steps) and whether they
PAY (conversion). Nothing measured whether they were happy — which would let a
conversion-positive, retention-negative T0+6wk read pass as an unqualified win.
Four numbers, all computable from events that already emit, all segmented by
**`free_tier_cohort`** and **`app_version`**:

| Signal | Query | What bad looks like |
|---|---|---|
| Rating-gate accept rate | `rating_gate_continue_tapped` ÷ `rating_gate_prompt_triggered` | a drop of **more than 10 percentage points** vs. the trailing-90-day pre-T0 baseline for the same ratio |
| Churn reasons | `cancellation_feedback_submitted` reason distribution, against `cancellation_feedback_shown` | not a threshold — a diagnostic read. Watch for the top reason shifting toward something the free-tier tightening (W5) plausibly caused (e.g. "too restrictive"/"couldn't use it enough") vs. unrelated reasons (price, content) |
| D1 retention | `app_opened`/`session_started` day-0 → day-1, `reel_v1` cohort vs. trailing-90-day pre-T0 baseline | a drop of **more than 5 percentage points** — looser than D7 because D1 has more week-to-week noise at ~21 signups/day, but it is the earliest warning and worth flagging even before D7 confirms |
| D7 retention (**the guardrail**) | `app_opened`/`session_started` day-0 → day-6..8, `reel_v1` cohort vs. trailing-90-day pre-T0 baseline | a drop of **more than 3 percentage points**. **This is the number that vetoes a conversion win** — a conversion lift that ships alongside a D7 drop past this line is not a win, full stop, regardless of what the paid-conversion number says |

**These thresholds are proposed, not verified against a live baseline** — this
wave did not query production numbers (T0 has not shipped — see the "W6 events
have no history" gotcha below), and the plan's own methodology is a
pre/post comparison against a trailing-90-day baseline with **no control arm**
at ~21 signups/day, where audience dimensions are already agreed to be
directional-only. The percentage-point deltas above are picked to be larger
than plausible week-to-week noise at that volume while still catching a real
regression; the founder should sanity-check them against the actual trailing
baseline once it's queryable, and adjust before the T0+6wk read, not during it.

**D30 retention is directional only** — six weeks from T0 is not enough
runway for a D30 cohort of meaningful size. Note it in the readout; don't gate
on it.

**Two named blind spots, not silently missing:**
- **Refunds** — RevenueCat webhook events, deliberately deferred. That path
  touches a server-secret webhook auth surface that has caused a production
  outage here before (`send-scheduled-notifications`, 2026-07-17); it is not
  being smuggled in under "instrumentation."
- **App Store review velocity/keywords** — App Store Connect is aggregate and
  lagged and was never going to be per-user joinable. Stays the plan's manual
  weekly scan; not automated by this wave.

---

## RC ↔ Mixpanel cohort reconciliation

The join key is **`install_id`**, on both sides — a Mixpanel super property
(registered before `app_opened`) and a RevenueCat subscriber attribute
(`purchase_service.dart`, same property name). **Never join on
`$mixpanelDistinctId`** — under Simplified ID Merge, Mixpanel's distinct id
changes at `identify()` (anonymous → signed-in), while the install id never
does. `install_id` is a join key, not an identity alias: it does not mean
Mixpanel and RevenueCat have merged identities, only that both sides recorded
the same install.

**Worked query shape** (post-T0, once there are purchases on the new cohort —
see below):

1. Mixpanel: `signup_completed` events with super property `onboarding_flow =
   'reel_v1'`, dated ≥ T0. Pull `install_id` + `distinct_id` for each. **Apply
   the test-ID exclusion list first** —
   [`docs/qa/mixpanel-orphaned-distinct-ids.json`](../qa/mixpanel-orphaned-distinct-ids.json).
   **Read the file's `distinct_ids` array and count it at query time; do not
   hardcode a count from memory or from the file's own `count`/`_count_note`
   fields** — that count key has drifted from the array's real length before
   (recorded in the file itself) and will again.
2. RevenueCat: pull subscriber records where the `install_id` attribute is in
   the set from step 1. `subscription_started` / `trial_started` per
   subscriber gives the paid-conversion numerator.
3. Join on `install_id`. The denominator is step 1's post-exclusion count; the
   numerator is step 2's converted subset.

**Caveats, stated plainly rather than discovered at the read:**
- **Cannot be run before there are purchases on the new cohort.** The earliest
  meaningful run is the T0+4wk trial→paid read, not T0+24h.
- **A reinstall mints a new `install_id`.** A user who reinstalls between
  signup and purchase will not join — they read as two people, an arrival and
  a separate, unattributed conversion. This underscores the join, it does not
  invalidate it: the alternative (an identity-based join) would be wrong in a
  different, worse way (per `$mixpanelDistinctId` above).
- **Client `trial_started` carries `placement`; the RevenueCat webhook's
  `subscription_started` does not** — the webhook cannot know the surface. Use
  the client event for surface attribution, RC for revenue truth.

---

## ASC Campaign Links runbook

App Store Connect Campaign Links are free, first-party, and answer a different
question than anything above: **which reel drives App Store views and
installs**, in aggregate. Generate one Campaign Link per reel, placed behind
the Instagram/TikTok bio link (one link per reel, not one shared link for all
of them — the whole point is to tell reels apart). App Analytics then reports
views/downloads per campaign on its own schedule.

**Aggregate only — never joinable to a Mixpanel `distinct_id` or an
`install_id`.** This informs which reel's creative is working, not which
individual user came from which reel; `reel_hook`/`reel_hook_source` and
`contract` remain the only per-user reel-of-origin signals (§ above), each
with its own stated limits. Do not attempt to reconcile ASC's aggregate counts
against Mixpanel's per-user funnel counts — they answer different questions at
different grains and will not match by design (different attribution windows,
no shared key).

This was TODO.md's open step for `reel_hook`; the other three steps (register
`reel_hook` with provenance, reconcile the event name, consider `contract` as
a proxy) are closed by this wave — see the amendment note in that file.

---

## `names_met` — a people property, not a "met" definition

Ships as `names_met` (a people property, `AnalyticsService.setUserProperties`)
set from the count of rows `sync_all_user_data` returns in `card_collection` —
i.e., Names whose card has been discovered — at
`hydrateUserDataFromBatchRpc`, once per hydrate. **Document and query this as
"cards discovered," not "Names met."** W3 explicitly declined to invent a
server-side "met" definition and was right to; this is an honest,
client-derived substitute for it, not that definition. Absent (never set)
rather than a guessed zero when the server payload omits the
`card_collection` section entirely (a pre-W1 backend, or a dropped section) —
a real returning user's collection must never read as zero.

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

- **Always exclude the test distinct_ids** in `docs/qa/mixpanel-orphaned-distinct-ids.json` —
  the file is the source of truth and the list grows. (It said "54" until 2026-07-31, when the
  file actually held 66. Do not re-hardcode a count here; read the file.)
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
- **W6 events have no history before the T0 build ships** — same rule as every prior wave above. `ai_taste_consumed`, `daily_cap_hit{reason}`, `cap_sheet_shown`/`_dismissed`, `restore_started`/`_completed`/`_failed`, `reflect_started`/`_completed`, `names_browse_viewed`, `dua_read`, all seven Wave F intake events, and the `onboarding_flow`/`contract`/`acquisition_problem_category`/`reel_hook`/`reel_hook_source`/`free_tier_cohort` super properties are all new in that binary. **A Mixpanel query run the day after merge returns zero rows for all of these, and that is correct** — not a wiring bug. `names_met` is the one exception: it's a people property, so once set it applies retroactively to all of that user's historical events in a profile breakdown, not just events after it was first set.
- **Wave B (the Second-Name lifecycle: `second_name_teased`/`_unseal_available`/`_unsealed{source}`, `name_source`/`queue_position` on `check_in_completed`) was scoped OUT of W6 and does not exist yet.** It is inherited W3 feature work, tracked separately, not a W6 gap. If you go looking for it here, it is deliberately absent — the only measurement of whether the 7-day queue actually ran is not yet built.
- **Crash reporting does not exist.** There is no way to distinguish a crash from a quit anywhere in this document's numbers. Every drop-off / abandonment figure carries an unmeasured crash component until that ships (its own, separate decision — not part of W6).
