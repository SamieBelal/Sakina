# One Ship W6 — instrumentation

**Date:** 2026-08-01
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first`
**Parents:** [`2026-07-23-conversion-refactor-changes-and-implementation.md`](./2026-07-23-conversion-refactor-changes-and-implementation.md) §W6 + **D5**, **D9** · W1–W5 (all built)
**Readout doc this feeds:** [`../../analytics/funnel-flags-and-querying.md`](../../analytics/funnel-flags-and-querying.md)

W6 ships **no user-visible change**. It is the ability to read whether the ship
worked. The keep decision at T0+6wk runs on the numbers this wave produces, and
the failure mode is silent: an event that does not fire looks exactly like a
behaviour that did not happen, and nobody finds out until the read.

**Non-goals:** the guided tour (**deleted 2026-07-28** — do not instrument it,
do not re-add `flag_tour_ab`) · new user-facing surfaces of any kind · the
softener wave's telemetry (post-keep) · Phase B notifications (post-ship) · any
Mixpanel *dashboard* construction (that is the readout doc's job, after T0) ·
the token→Noor merge's economy events (softener wave).

---

## 1. What this wave actually is, after the audit

The W6 bullet in the master plan is nine days old and reads as though nothing
exists. **That is badly wrong in both directions.** Waves 2–5 shipped a large
part of W6 as a side effect of needing their own telemetry — the beat spine, the
deck events, the three-page gate's per-page event, the free-tier entry, the
whole daily-question funnel. What they did *not* ship is the part that has no
screen attached to it: **the super properties**, which are the entire mechanism
by which the One Ship is read as one funnel rather than five.

So W6 is smaller than its bullet and more dangerous than it looks. The
remaining work is concentrated in the two places where a mistake is invisible:

1. **Provenance and ordering of super properties.** A super property registered
   after the first event that needs it is *absent* on exactly the widest event
   in the funnel. Mixpanel does not backfill.
2. **One name meaning two things.** `problem_category` is already live as an
   event property meaning "what the user said today". The W6 bullet asks for a
   super property of the same name meaning "what they arrived with". Shipping
   that verbatim would put two meanings behind one key in one payload —
   see **D4**.

---

## 2. The audit — plan vs the tree, 2026-08-01

Every W6 line item, walked against the committed tree on this branch. **Do not
trust the master plan's W6 bullet as a checklist; trust this table.** Symbols
were grepped, not remembered; line numbers drift, so grep the symbol.

### 2a. Super properties and the people property

| Item | Verdict | Evidence / what has to happen |
|---|---|---|
| `onboarding_flow` super property | **Not built** | Exists as `user_profiles.onboarding_flow` (`auth_service.dart:52`), as `AppSession.onboardingFlow` (`app_session.dart:134-156`), and hydrated at `user_data_batch_sync_service.dart:183`. **Never registered with Mixpanel anywhere.** Must be registered from the `_flowFuture.then` continuation in `onboarding_screen.dart:335-347`, **before** `_emitEntryFunnelEvents` on the next line — that continuation already exists precisely because an earlier race mis-labelled the first `onboarding_step_viewed`. Returning users get it at boot from `AppSession`. |
| `reel_hook` super property | **Not built** (divergence D5) | `reelStepNames[0] = 'reel_hook'` (`analytics_event_names.dart:916`) is a *step name*, not this. No super property of this name is registered. See **D2**. |
| `contract` super property | **Not built** | The value exists and is already load-bearing: `HookContract.problem` / `.sign` (`problem_chips.dart:20-90,130`), persisted into `acquisition_promise.contract` and asserted present at `auth_service.dart:446`. Nothing tells Mixpanel. |
| `problem_category` super property | **Shipped but DIVERGENT — and a collision** | `propProblemCategory = 'problem_category'` (`analytics_event_names.dart:1082`) is live as an **event** property on `check_in_completed` (`daily_loop_provider.dart:1370`) and `daily_question_answered` (`:863`), meaning *today's answer*. The W6 bullet wants a super property of the same name meaning *acquisition*. Two meanings, one key. See **D4**. |
| `free_tier_cohort` super property | **Not built, and not reachable at boot** | `GatingService.isNewCohort()` (`gating_service.dart:255`) reads a **user-scoped** prefs key written only by `hydrateFromProfile` (`:1328`). On a fresh install there is no value until the first `sync_all_user_data`. Register from the existing `GatingService.onProfileHydrated` hook (`:125`, wired at `app_lifecycle_observer.dart:72`), not from `registerBootstrapAnalytics`. |
| `names_met` people property | **Not built** | No "met" definition exists client-side; W3 explicitly declined to invent one (`2026-07-29-one-ship-03-daily-loop.md:253`). `AnalyticsService.setUserProperties` (`analytics_service.dart:76`) is the mechanism. See **D8**. |

### 2b. Events

| Item | Verdict | Evidence / what has to happen |
|---|---|---|
| `reel_source_captured` | **Shipped but DIVERGENT** | Ships as `reel_source_selected{source}` — constant at `analytics_event_names.dart:81`, emitted at `source_question_screen.dart:79`. See **D1**. |
| `beat_kind` gains `recognition` / `comfort_verse` | **Already shipped** | `BeatKind.recognition` / `.comfortVerse` with wire values `recognition` / `comfort_verse` (`beat_reveal_models.dart:17-22,48-51`); the deck kinds are renderable (`name_story_deck.dart:181-187`). Nothing to do. |
| `reveal_deck_completed` / `_abandoned` | **Already shipped** | `onboarding_reveal_screen.dart:217,225` and `muhasabah_screen.dart:146,157`, both stamped with `surface` (`onboarding_reveal` vs `daily_unseal`) exactly as the readout doc requires. Nothing to do. |
| `second_name_teased` / `_unseal_available` / `_unsealed{source}` | **Not built** | W3's Wave 5 **did not land**. `grep -rn second_name lib/` → nothing. `lib/services/reveal_entry_source.dart` does not exist. `check_in_completed` carries no `name_source` / `queue_position` (only comments at `daily_loop_provider.dart:56,170,1132` anticipating them). This is the largest single gap in W6 and it is not in the W6 bullet at all — it is inherited scope. |
| `paywall_page_viewed{page_id}` | **Already shipped** | `paywall_screen.dart:411-421`, deduped on `_lastTrackedPageId`, and it also carries `placement`. Nothing to do. |
| `paywall_viewed{placement:'onboarding'}` | **Already shipped** | Emitted single-source at `paywall_screen.dart:336`; the onboarding push passes `PaywallPlacement.onboarding` (`onboarding_screen.dart:1025`, enum at `paywall_placement.dart:17`). Nothing to do. |
| `paywall_closed` | **Shipped but DIVERGENT — confirmed W5 carry-over** | `paywall_screen.dart:581` — `track(paywallClosed)` with **no properties at all**. Every other emission on that screen stamps `placement`; this one does not, so gate dismissals and in-app upsell dismissals are indistinguishable. The adjacent `soft_gate_dismissed` three lines below *does* carry it. |
| `ai_taste_consumed{feature, allowance, remaining}` | **Not built** | The consume path exists — `GatingService.markUsed` (`gating_service.dart:519`) → `_consumePostWarmup` (`:598`) → `_consumeWeeklyPool` — and emits nothing. Warmup spend is likewise silent; only its *exhaustion* surfaces, via `UsageOutcome.warmupJustExhausted` and the sheet. |
| `ai_allowance_exhausted` | **Effectively shipped under another name** | `_emitCapHit` (`gating_service.dart:663`) fires `daily_cap_hit{feature}` from **both** new-tier blocks — `GateReason.weeklyPool` (`:645`) and `GateReason.rerollPremium` (`:637`) — and from the legacy daily cap (`:681`). Its own docstring says *"Segmentation by cohort belongs to W6's instrumentation pass, not here."* See **D5**. |
| `free_tier_entered` | **Already shipped** | `paywall_screen.dart:629`, carries `placement`, and is once-ever per user via the `alwaysFreeCardShownPrefsBaseKey` latch. ⚠️ It fires on dismissal of **any** placement, not just the onboarding gate — the name over-promises. Recoverable by filtering `placement`; the readout doc must say so. |
| stable `step_id` on onboarding steps | **Already shipped, spelled `step_name`** | `trackStepViewed` / `trackStepCompleted` (`analytics_events.dart:94-117`) emit `step_index` + `step_name` from `stepNamesFor(...)`; `reelStepNames` (`analytics_event_names.dart:915-939`) deliberately reuses the legacy names for the six shared screens so a funnel joins across flows. That *is* the stable id the bullet asks for. See **D6**. |
| install→signup (App Store Connect) | **Not built** | Nothing in code; nothing can be. ASC Campaign Links are an ops task (TODO step 3) — aggregate-only, never joinable to a `distinct_id`. |
| RC↔Mixpanel cohort-reconciliation query | **Not built** | The join key exists and is correct: `InstallIdService` mints a stable id (`install_id_service.dart`), registered as a super property at `analytics_events.dart:66-67` and as an RC subscriber attribute at `purchase_service.dart:77`. Only the documented query is missing. |
| Debug-assert: `ai_bypass_offered` never for `reel_v1` | **Behaviour already correct; the guard is missing** | `daily_cap_sheet.dart:265-286` already gates both `firstBypassOffered` and `aiBypassOffered` on `!newTier`, with a comment explaining that firing them would inflate a funnel whose remaining steps cannot fire. `GatingService.reserveBypass` also returns null for the new cohort (`:881`). **What is missing is the assert and the test** — the invariant is currently held by a boolean anyone can drop. |

### 2c. The never-superseded v1 Phase-4 holes

Confirmed against the tree before minting anything, as instructed — a duplicate
event under a near-miss spelling is worse than a missing one.

| Item | Verdict | Evidence |
|---|---|---|
| `reflect_started` / `reflect_completed` | **Not built** | Reflect emits exactly three things: `reflect_beat_advanced` and `reflect_flow_skipped` (`reflect_screen.dart:241,251`) and `journal_entry_created` (`reflect_provider.dart:940`). **There is no start/complete pair, and no near-miss spelling to collide with.** The seam is `ReflectNotifier.submit()` (`reflect_provider.dart:525`). |
| `names_browse_viewed` | **Not built** | `lib/features/names/screens/names_screen.dart` has **zero** analytics references, and is a `StatelessWidget` (`:3`) — so this needs either a conversion to `ConsumerStatefulWidget` or a route-level emit. |
| `dua_read` | **Not built** | `lib/features/duas/` emits `dua_built` and `journal_entry_created` only (`duas_provider.dart:651,748,815`). There is one screen (`duas_screen.dart`) — no separate detail route — so "read" needs a definition before it needs an emitter (see Wave D). |

### 2d. Moot, or already correctly retired

| Item | Verdict |
|---|---|
| All tour instrumentation | **Moot** — tour deleted 2026-07-28. `tour_step_viewed` / `tour_completed` emitters survive in `onboarding_tour_controller.dart` and `app_lifecycle_observer.dart:140` **only** because the kill-switch legacy flow still renders the tour. A `reel_v1` user cannot reach any of them. Do not extend, do not delete (post-keep ledger owns that). |
| `flag_tour_ab` | **Correctly retired** — omitted from registration and explicitly scrubbed from upgraded installs (`analytics_events.dart:74`). Never re-add. |
| `paywall_exp_arm` / `flag_reverse_trial_exp` | **Correctly frozen** — scrubbed at `analytics_events.dart:80-81` with a comment that the next paywall experiment ships a *new* property and that `onboarding_flow` must never be unioned with it. |

### 2e. Found in the audit, not mentioned anywhere in the plan

These are not W6 bullets. They are things the audit turned up that a reader of
the numbers would be misled by.

1. **`flag_hard_paywall` boots with the wrong fallback.** `main.dart:363` passes
   `fallback: false`; the live prod value is `true` (master plan's flag
   inventory). On a **first** install — no cached `app_config` — every event
   before the first successful config read carries `flag_hard_paywall=false`.
   That is the widest part of the funnel, mis-segmented, on exactly the cohort
   we are measuring. Fix is one word.
2. **Two undocumented super properties are live.** `first_open_date`
   (`main.dart:302`, `setSuperPropertiesOnce`) and `onboarding_completed`
   (`onboarding_screen.dart:511`). Neither appears in
   `funnel-flags-and-querying.md`. `onboarding_completed` in particular is a
   *durable boolean super property* that will read `true` forever after the
   first completion — trivially mistakable for an event.
3. **`free_tier_entered` is not gate-specific** (above). Name vs meaning.
4. **`daily_cap_hit` has no cohort or reason property**, so at T0 the same event
   name will carry three structurally different blocks (legacy daily cap,
   weekly pool, second-Name-is-premium) with nothing to tell them apart except
   a super property that does not exist yet. Wave A must land before this
   matters, which is why it is Wave A.

**Counts:** 8 already shipped correctly · 5 shipped but divergent · 11 not built
· 3 moot.

---

## 3. Decisions

### D1 — Keep `reel_source_selected`; amend the plan, not the code. **(recommended)**

The master plan and `TODO.md` specify `reel_source_captured`. The code has
emitted `reel_source_selected{source}` since W2.

**Recommendation: keep the code, amend the two documents.** Historical events do
not rename. A rename creates a permanent seam at the T0 build: every query about
reel source must union two names forever, and the union is the kind of thing
that gets dropped from a chart six months later by someone who only knows one of
them. The information gained is zero — both names mean the same thing, and
`_selected` is arguably the more honest of the two (the user *selected* from a
list; nothing was *captured*).

**Cost of the recommendation:** edit `docs/superpowers/plans/2026-07-23-…md:197`
and `TODO.md:289-302`, and make sure the readout doc names the shipped event.
**Cost of the alternative:** a two-name union in perpetuity, on the one signal
the plan calls *"the plan's biggest measurement hole."*

### D2 — `reel_hook` states its provenance in a **second** property, not inside its value.

Register **two** super properties, at onboarding entry:

| Property | Values |
|---|---|
| `reel_hook` | the `reel_id` from a `sakina://reel/<id>` deep link, or the source screen's stable key, or `unknown` |
| `reel_hook_source` | `deep_link` \| `self_report` \| `unknown` |

Two properties rather than one encoded string (`self_report:tiktok`) because a
breakdown should not require parsing, and because the two axes are asked
different questions: *which reel* vs *how sure are we*.

**`unknown` must be registered at onboarding entry, in the same continuation as
`onboarding_flow`** — before `onboarding_started`. If it is registered only when
learned, it is *absent* rather than `unknown` on every event before the source
screen (index 13 of 18), which is most of the funnel. An absent property and a
`unknown` one break down differently and only one of them is honest.

Provenance sources already exist: `consumePendingReelArrival()` returns a
validated `reel_id` (`reel_deep_link_service.dart`, drained at
`onboarding_screen.dart:385`) → `deep_link`; the source screen's answer
(`source_question_screen.dart:79`) → `self_report`, upgrading `unknown` in
place.

### D3 — `contract` is the primary reel-of-origin dimension. `reel_hook` corroborates it. **(recommended, agreeing with TODO step 4)**

`contract` is **behavioural, taken at arrival, with near-total coverage** —
every reel user picks a chip or types, and typed input is forced to
`HookContract.problem` (`problem_chips.dart:353-355`). The self-report sits at
index 13, after the payoff and every ask, and can be declined silently ("Rather
not say" emits nothing).

**Recommendation: register `contract` as a super property at hook selection and
treat it as the reel-of-origin proxy in the readout; keep `reel_hook` as
corroboration and as the only thing that can distinguish two reels that make the
same promise.**

State the limit in the readout doc rather than discovering it at the read:
`contract` has **two values**. It separates Reel 1 ("your problem → two Names")
from Reel 2 (2:286 / "can't put it into words"). It cannot separate two future
reels that both make the problem promise. When that happens, ASC Campaign Links
(aggregate) and `reel_hook` (per-user, self-reported) are what is left.

### D4 — The acquisition category ships as `acquisition_problem_category`, **not** `problem_category`. **(new — the plan would have shipped a collision)**

`problem_category` is already a live **event** property meaning *today's answer*
(`check_in_completed`, `daily_question_answered`). Registering a super property
of the same name meaning *what they arrived with* puts two meanings behind one
key: event-level properties win where both exist, so `daily_question_answered`
would report today's answer and `paywall_viewed` would report the acquisition
one — **under the same name, with nothing to signal the switch**. Every chart
built on it would be right some of the time.

**Recommendation: name the super property `acquisition_problem_category`**,
sourced from `acquisition_promise.problem_category`, and document both keys
side by side in the readout doc. The vocabularies are deliberately the same
7-chip taxonomy (`analytics_event_names.dart:1078-1082`), so cross-tabbing
"arrived with X, answers Y today" is exactly one breakdown — and *that* is the
question worth asking, which a single overloaded key would have made
unaskable.

### D5 — Do not mint `ai_allowance_exhausted`. Extend `daily_cap_hit`. **(recommended)**

`daily_cap_hit` already fires on every block a free user can hit, in both
cohorts, from one function. Minting a second exhaustion event for the new tier
forks the cap-hit→upgrade funnel **exactly across the T0 boundary we need it
continuous over** — the pre/post comparison is the whole read.

**Recommendation:** add `reason` (the `GateReason` wire value: `daily_cap` /
`weekly_pool` / `reroll_premium` / `had_trial_no_budget`) to `daily_cap_hit`,
and let the `free_tier_cohort` super property from Wave A do the cohort split.
Amend the master plan's W6 bullet to say so.

`ai_taste_consumed` **is** genuinely new and does get minted — it is the
denominator (`consumed`) that `daily_cap_hit` is the numerator of, and nothing
today emits on a *successful* spend.

### D6 — `step_name` is the stable step id. Do not emit a second spelling. **(recommended)**

`reelStepNames` already reuses the legacy names for the six shared screens
precisely so a funnel joins across flows, and the map's own comment says *"Copy
on these screens may change; these ids may not."* Emitting `step_id` as a
duplicate of `step_name` would create the two-spellings-of-one-thing defect this
wave exists to prevent.

**Recommendation: amend the plan bullet; document in the readout doc that
onboarding's stable join key is `step_name` (the tour's was `step_id`, and the
tour is deleted).**

### D7 — `paywall_closed` gains `placement`. No migration cost.

Adding a property to an existing event costs nothing historically: pre-W6 events
simply lack it, which reads correctly as "pre-W6". Not adding it means gate
dismissals and in-app upsell dismissals stay indistinguishable through the
entire watch window.

### D8 — `names_met` ships as a client-derived people property, explicitly scoped. **(recommended)**

W3 declined to invent a "met" definition and was right to. Rather than defer
again, ship the honest available one: **the count of rows in
`user_card_collection`** (i.e. Names whose card has been discovered), set as a
people property at `hydrateFromProfile`, and **document it as "cards discovered",
not "Names met"**, in the readout doc. It is a people property, so it is
retroactive in cohort/profile breakdowns and does not need to have existed at
event time.

Alternative if the founder prefers: cut it from W6 entirely. It is the only W6
item with no consumer named in the plan — nothing in the T0+2wk / T0+4wk /
T0+6wk read list uses it.

---

## 4. The waves

> ⚠️ **SUPERSEDED IN PART BY §8f AND §9.** This section was written before the
> W1–W5 audit. The wave list below is missing **Wave 0** and **Wave F**, Wave C
> is larger than described, and **Wave B is no longer part of W6** (split out at
> eng review, D2). **§9 is the authoritative wave list.** Everything else in
> this section — the file lists, the steps, the test tables — still stands.

Five slices. **Wave A lands first and alone** — it registers the super
properties every later event must carry, and a super property registered after
an event is absent on that event forever. B, C and D touch disjoint files and
can run in parallel after A. E is documentation and lands last, because it
describes what the others actually shipped.

### Wave A — Super properties and their provenance

**Files:** `lib/services/analytics_event_names.dart` (append-only) ·
`lib/services/analytics_events.dart` · `lib/main.dart` ·
`lib/features/onboarding/screens/onboarding_screen.dart` ·
`lib/features/onboarding/screens/hook_problem_screen.dart` ·
`lib/features/onboarding/screens/source_question_screen.dart` ·
`lib/core/app_lifecycle_observer.dart`

1. Constants for `onboarding_flow`, `contract`, `acquisition_problem_category`,
   `reel_hook`, `reel_hook_source`, `free_tier_cohort` (D2, D4). Append at the
   end of `AnalyticsEvents` — other workstreams append to the same file.
2. **Onboarding entry registration**, inside the existing `_flowFuture.then`
   continuation at `onboarding_screen.dart:335-347`, **above** the
   `_emitEntryFunnelEvents(initialPage)` call: `onboarding_flow` (the resolved
   kind) and `reel_hook_source = 'unknown'` / `reel_hook = 'unknown'`. The
   deep-link drain runs on the next line and upgrades both when it finds a
   `reel_id`.
3. **Hook selection** stamps `contract` and `acquisition_problem_category` at
   the moment the chip (or typed sentence) resolves.
4. **Source screen** upgrades `reel_hook` / `reel_hook_source` to
   `self_report` alongside the existing `reel_source_selected` emit — one call
   site, so the two can never disagree.
5. **`free_tier_cohort`** registered from `GatingService.onProfileHydrated`
   (already wired in `app_lifecycle_observer.dart:72` — add a second statement,
   do not add a second hook).
6. **Returning users**: `registerBootstrapAnalytics` re-registers
   `onboarding_flow` from `AppSession` when known. Follow the existing
   `installId` pattern — **omit rather than register null**, for the reason the
   file already states at `analytics_events.dart:63-65`.
7. **Fix `flag_hard_paywall`'s fallback** to `true` (§2e.1).

**Tests that pin it**

| Test | Pins | Mutation that must fail it |
|---|---|---|
| `test/services/bootstrap_super_properties_test.dart` (extend existing coverage of `registerBootstrapAnalytics`) | the boot-time set, incl. the corrected `flag_hard_paywall` fallback and null-omission | flip the fallback back to `false`; register `onboarding_flow: null` |
| `test/features/onboarding/onboarding_flow_super_property_order_test.dart` | **ordering** — a spy `AnalyticsService` asserts `onboarding_flow` was set *before* the first `onboarding_started`/`onboarding_step_viewed` | move the registration below `_emitEntryFunnelEvents` |
| `test/features/onboarding/reel_hook_provenance_test.dart` | `unknown` at entry → `deep_link` after a `sakina://reel/x` drain → `self_report` after the source screen, and that the two properties always move together | upgrade `reel_hook` without `reel_hook_source` |
| `test/services/acquisition_problem_category_name_test.dart` (source-level) | greps `lib/` and fails if any `setSuperProperties` call registers the literal `'problem_category'` | rename `acquisition_problem_category` back to `problem_category` (D4's collision) |
| `test/services/free_tier_cohort_super_property_test.dart` | registration fires from `onProfileHydrated`, and **not** at boot | move it into `registerBootstrapAnalytics`, where it would read a user-scoped key that does not exist yet |

### Wave B — The Second-Name lifecycle (inherited from W3 Wave 5)

**Files:** `analytics_event_names.dart` · `lib/services/reveal_entry_source.dart`
(new) · `lib/features/daily/providers/daily_loop_provider.dart` ·
`lib/features/onboarding/screens/onboarding_reveal_screen.dart` ·
`lib/core/widget_deep_link.dart` · `lib/services/notification_service.dart` ·
`lib/main.dart`

Implements W3 §9 verbatim — it was specified and never built.

1. `second_name_teased{name_id, deck_id, contract}` from the reveal screen's
   existing static hook, latched alongside `kindledFired`.
2. `second_name_unseal_available{name_id, days_since_tease}`, **deduped on the
   user-local date** (`user_local_day.dart` already exists) so four app opens
   emit once.
3. `second_name_unsealed{source, name_id, days_since_tease}` on position 2 only.
4. `reveal_entry_source.dart` — a process-global `(source, timestamp)` stamp
   with a ~10-minute TTL, written by `WidgetDeepLinkHandler` and the
   notification click listener, read once by the unseal emit and cleared.
   Degrades to `organic`; the split is directional and must be documented as
   such.
5. `check_in_completed` gains `name_source` (`queue` | `gacha`) and
   `queue_position`. **Do not fork the event, do not change `path`** — the
   binding rule from W3/W4.
6. Every emit wrapped in the same bare `catch (_)` as its neighbours: a throwing
   hook inside `discoverName` flips `state.error` and refunds a bypass.

**Tests that pin it**

| Test | Pins | Mutation that must fail it |
|---|---|---|
| `test/features/daily/second_name_analytics_test.dart` | the three events fire once each, with their props, on a queue path | emit `second_name_unsealed` for position 3 |
| `test/features/daily/second_name_unseal_dedup_test.dart` | four opens in one local day → one `_unseal_available` | drop the date latch |
| `test/features/onboarding/second_name_teased_test.dart` | tease fires from the reveal screen, once | remove the latch, or emit on every build |
| `test/services/reveal_entry_source_test.dart` | TTL expiry → `organic`; read clears the stamp | make the read non-clearing (a stale widget stamp would then attribute a later organic unseal to the widget) |
| `test/features/daily/check_in_completed_not_forked_test.dart` | `path` is still `'discover'` and the two new props ride alongside | change `path` to `'queue'` |
| `test/features/daily/second_name_emit_never_errors_test.dart` | a throwing analytics hook does not set `state.error` | remove a `catch (_)` |

### Wave C — The gate's meter

**Files:** `analytics_event_names.dart` · `lib/services/gating_service.dart` ·
`lib/features/onboarding/screens/paywall_screen.dart` ·
`lib/features/paywall/widgets/daily_cap_sheet.dart`

1. `ai_taste_consumed{feature, allowance, remaining}` from `markUsed`'s consume
   paths (`_consumePostWarmup`, `_consumeWeeklyPool`, and the warmup decrement),
   with `allowance` naming which budget was spent (`warmup` | `weekly_pool` |
   `daily`).
2. `daily_cap_hit` gains `reason` (D5) — one added property in `_emitCapHit`,
   which every block already routes through.
3. `paywall_closed` gains `placement` (D7).
4. **The `reel_v1` bypass assert.** An `assert` in `DailyCapSheet.show` that
   `ai_bypass_offered` / `first_bypass_offered` are unreachable when
   `newTier == true` — the behaviour is already correct at
   `daily_cap_sheet.dart:265-286`; this makes it break loudly instead of
   silently.

**Tests that pin it**

| Test | Pins | Mutation that must fail it |
|---|---|---|
| `test/services/ai_taste_consumed_test.dart` | one emit per successful spend, with the right `allowance`, and **none** for premium (premium short-circuits before the cohort read) | emit before the premium short-circuit |
| `test/services/daily_cap_hit_reason_test.dart` | all four `GateReason` blocks produce their own `reason`, and premium fair-use produces **no** event | route `premiumFairUse` through `_emitCapHit` |
| `test/features/paywall/paywall_placement_analytics_test.dart` (extend) | `paywall_closed` carries `placement` from all four placements | drop the property from `_doClose` |
| `test/features/paywall/bypass_never_offered_to_reel_cohort_test.dart` | with `free_tier_cohort=reel_v1`, neither offer event fires; **plus** a source-level grep that `aiBypassOffered` has no emit site lacking a `newTier` guard | delete `!newTier` from either predicate |

### Wave D — The three v1 Phase-4 holes

**Files:** `analytics_event_names.dart` ·
`lib/features/reflect/providers/reflect_provider.dart` ·
`lib/features/names/screens/names_screen.dart` ·
`lib/features/duas/screens/duas_screen.dart`

1. `reflect_started` / `reflect_completed` from `ReflectNotifier.submit()`
   (`:525`) — started at the gate-passed point, completed on a successful
   `ReflectResponse`. `reflect_completed` carries `off_topic` so the classifier's
   cost on Reflect stays comparable with the daily loop's.
2. `names_browse_viewed` — `NamesScreen` is a `StatelessWidget`; emit once per
   mount, deduped per session so a tab-switcher does not inflate it.
3. `dua_read` — **define before emitting.** There is one duas screen and no
   detail route, so "read" must mean a specific interaction (a dua card expanded
   / opened), not a screen mount. Pick the interaction, name it in the constant's
   docstring, and emit `dua_read{dua_id, source}`.

**Tests that pin it**

| Test | Pins | Mutation that must fail it |
|---|---|---|
| `test/features/reflect/reflect_started_completed_test.dart` | pair fires once per submit; a gated submit fires **neither**; a failed AI call fires `started` only | emit `completed` in the `catch` |
| `test/features/names/names_browse_viewed_test.dart` | one emit per mount, deduped per session | remove the dedup (tab switching would inflate it) |
| `test/features/duas/dua_read_test.dart` | fires on the chosen interaction, not on screen mount | move the emit to `initState` |

### Wave E — People property, docs, and the amendments

**Files:** `lib/services/gating_service.dart` (or the sync seam) ·
`docs/analytics/funnel-flags-and-querying.md` ·
`docs/superpowers/plans/2026-07-23-…md` · `TODO.md`

1. `names_met` people property at `hydrateFromProfile` (D8), documented as
   "cards discovered".
2. **Readout doc update** — the single most important deliverable of this wave.
   Add: the new super-property rows and their **provenance and coverage**
   caveats; `acquisition_problem_category` vs `problem_category` side by side
   (D4); `step_name` as onboarding's join key (D6); the `free_tier_entered`
   placement caveat; the two undocumented super properties (§2e.2); the
   Second-Name funnel; `ai_taste_consumed` / `daily_cap_hit{reason}`.
3. **The RC↔Mixpanel cohort-reconciliation query**, written out, joining on
   `install_id` (never `$mixpanelDistinctId` — Mixpanel's distinct id changes at
   `identify()`, the install id does not), with the reinstall caveat, and
   **applying the test-ID exclusion list at
   `docs/qa/mixpanel-orphaned-distinct-ids.json`** — read the file, never
   hardcode a count.
4. **ASC Campaign Links runbook** — one link per reel behind the bio link;
   aggregate-only, not joinable to a `distinct_id`.
5. **Amendments**: master plan W6 bullet → `reel_source_selected` (D1),
   `daily_cap_hit{reason}` (D5), `step_name` (D6),
   `acquisition_problem_category` (D4); `TODO.md` §`reel_hook` → close steps 1,
   2 and 4, leaving step 3 (ASC) as the only open item.

**Tests that pin it:** `test/services/names_met_people_property_test.dart` (set
once per hydrate, from the collection count, never from a client guess). The doc
work is pinned by review, not by tests — say so rather than pretending
otherwise.

### Parallelism

**A → then B ‖ C ‖ D → then E.** A must land alone: it registers the super
properties, and anything landing before it emits events that will never carry
them. B, C and D touch disjoint files (`daily_loop_provider` + reveal screen ·
`gating_service` + paywall · `reflect`/`names`/`duas`) and only collide in
`analytics_event_names.dart`, which is append-only — take the merge. E last,
because it documents what actually shipped, and half of this wave's value is in
E.

---

## 5. What can only be verified after release

Stated plainly, because a simulator pass will look green and prove nothing about
these:

- **No new event has any history until the binary ships.** Every event and
  property in Waves A–D populates only for users on the T0 build. A Mixpanel
  query run the day after merge returns zero rows and that is correct. This is
  the same rule already recorded for the Phase 1–3 and W4 events.
- **Super-property coverage is only measurable in production.** A widget test
  proves the registration ordering on one code path. It cannot prove that a
  real cold launch, with a cold `app_config` cache and a slow network, sets
  `onboarding_flow` before the first event. **The founder must check, at T0+24h:
  the share of `onboarding_started` events carrying `onboarding_flow`,
  `contract` and `reel_hook_source`. Anything below ~95% is an ordering bug, not
  a sampling artifact.**
- **`free_tier_cohort` coverage depends on sync timing**, by construction — it
  cannot exist before the first `sync_all_user_data`. Expect it absent on the
  earliest events of a brand-new user's first session. Check at T0+24h that it
  is present on `paywall_viewed` and `daily_cap_hit`; those are the two that
  matter.
- **The RC↔Mixpanel reconciliation cannot be run before there are purchases on
  the new cohort.** Earliest meaningful run is the T0+4wk trial→paid read.
- **ASC install→signup is aggregate and lagged** — App Analytics reports on its
  own schedule and cannot be joined per user, ever.
- **`reveal_entry_source` attribution is directional, not exact** — cold-launch
  races and a user who wanders before revealing both degrade to `organic`. Do
  not build a precision claim on it.

---

## 6. Risks

1. **The characteristic risk of this wave is an event whose absence is invisible
   until the keep read.** Mitigation is the T0+24h coverage check above, and it
   is a *check somebody has to run* — it is not automatable from here. Put it on
   the T0 checklist, not in this document only.
2. **Ordering.** `onboarding_flow` / `reel_hook_source` registered one line too
   low costs the funnel's widest event its segmentation, and the resulting chart
   looks fine — it just has a large unattributed bucket that reads as "organic
   traffic". Pinned by the ordering test; that test is the load-bearing one in
   Wave A.
3. **D4's collision, if overruled.** Shipping the super property as
   `problem_category` produces charts that are right on two events and wrong on
   every other one, with no visible signal. There is no recovery except renaming
   later, which creates the seam D1 declines to create.
4. **Second-Name events are inherited scope that no one is tracking.** W3's plan
   lists them under a wave that shipped its other four slices; the W6 bullet
   does not mention them at all. If W6 is descoped under time pressure, this is
   the piece most likely to be dropped silently — and it is the only measurement
   of whether the seven-day queue, the ship's central retention mechanic,
   actually ran.
5. **`daily_cap_hit` semantics change at T0** whichever way D5 goes: the same
   event will mean "hit the daily cap" for legacy users and "spent the weekly
   pool" for reel users, in the same series. The `reason` property makes it
   readable; without it the series is uninterpretable across the boundary, and
   the boundary is the read.
6. **The tour's dead emitters.** `tour_*` events still exist for the kill-switch
   flow. If the kill switch is ever flipped during the watch window, tour events
   reappear in a funnel nobody expects them in. Not a defect — but the readout
   doc should say that tour events after 2026-07-28 mean *the kill switch was
   pulled*, which is useful signal rather than noise.

---

## 7. Not in this wave

- Any Mixpanel dashboard or saved report (readout doc's job, post-T0).
- The `names_met` **server-side** "met" definition (§V6.8.D4) — D8 ships a
  client-derived, explicitly-scoped substitute instead.
- Deleting the tour's dead emitters, the legacy flag reads, or
  `answerCheckin()` — all post-keep, on the hygiene ledger.
- Retiring `free_tier_cohort` and the bypass events — post-softener-wave, on the
  same ledger.
- Any new experiment flag. The standing rule is at most one live product flag,
  and `reel_first_onboarding_enabled` is it.

---

## 8. The W1–W5 audit — code paths and coverage (2026-08-01)

Six parallel read-only audits, one per wave plus two cross-cutting, commissioned
after Wave A landed. **Method note that matters for how much you trust this:**
every P0- and P1-class finding below was independently re-verified against the
tree or against production by the session lead before being recorded here. Where
an agent's framing was directionally right but imprecise, the entry states what
was actually confirmed, not what was reported. Findings labelled SUSPECTED were
not confirmed and are marked as such.

The audit changes §4's shape. It is recorded here rather than folded silently
into the waves so the next reader can see *why* Wave C grew and Wave F exists.

### 8a. The three structural findings

These are not missing events. They are shapes that cannot be fixed by adding one
constant, and each one invalidates a class of question you would otherwise
assume you could ask.

**S1 — `onboarding_abandoned_at_page` can only be emitted by users who did not
abandon.** It fires exclusively from `didChangeAppLifecycleState` on `resumed`
(`onboarding_screen.dart:407-435`, gated by `shouldEmitAbandonment` at `:80-91`).
The user must *come back* in order to report that they left. Anyone who
backgrounds and never reopens — uninstall, loss of interest, the overwhelming
majority of real abandonment — emits nothing, ever. A pre-existing finding doc
(`docs/qa/findings/2026-06-01-abandonment-telemetry-not-exercisable.md`) recorded
this in June for the legacy flow; it is unresolved and now also true of the reel
flow.

> **Consequence for the design, not just the backlog:** the honest abandonment
> signal is **`step_viewed` without a matching `step_completed`**. It requires no
> cooperation from a departed user. Build the drop-off funnel on that pairing and
> treat `onboarding_abandoned_at_page` as a *returner* signal — which is a real
> and different thing worth keeping, under a name that says so.

**S2 — the cap sheets are instrumented only on the path the new cohort cannot
reach.** `warmup_exhausted_sheet.dart` emits **zero** analytics. `daily_cap_sheet.dart`
emits exactly two events — `first_bypass_offered` (`:282`) and `ai_bypass_offered`
(`:286`) — and **both sit on the token-bypass slot, which W5 removes for
`reel_v1`**. So for a user on the tightened free tier, the single most important
monetization surface in the whole ship fires nothing on impression and nothing on
dismissal, across all six call sites (`reflect_screen.dart:120,154`;
`duas_screen.dart:167,201`; `muhasabah_screen.dart:235,786`). The cap-hit →
upgrade-tapped rate — the number the free-tier change is *for* — is currently
uncomputable for the cohort it was built for.

**S3 — W3's Wave 5 (the Second-Name lifecycle) was never built.** Confirmed
independently by two agents and by the lead: `grep -rn "second_name\|secondName" lib/`
returns **zero** hits outside a planning comment. Absent: `second_name_teased`,
`second_name_unseal_available`, `second_name_unsealed{source}`,
`lib/services/reveal_entry_source.dart`, and the `name_source`/`queue_position`
properties on `check_in_completed` (`daily_loop_provider.dart:1366-1374` carries
`path`, `name`, `tier_changed`, `is_duplicate`, `problem_category`, `input_mode`
and nothing else — `state.revealSource` and `revealQueuePosition` are computed,
stored, and never surfaced).

> This is **feature work sitting inside a wave budgeted as instrumentation**. W4
> shipped its own, more rigorous `entry_source` (`day_open|widget|home_cta`,
> enforced by a repo-wide grep test that fails CI on any untagged `/muhasabah`
> push), which answers *how did they get to the question* — but never answered
> *which queued Name got taught*. The two were never the same thing, and the W6
> bullet assumed W3 had delivered it.

### 8b. Ranked findings

Severity is "what decision goes wrong if this stays broken," not code ugliness.

| # | Sev | Finding | Location | The question you cannot answer |
|---|---|---|---|---|
| 1 | **P0** | Cap + warmup sheets emit nothing for `reel_v1` (S2) | `daily_cap_sheet.dart:282,286`; `warmup_exhausted_sheet.dart` (0 calls) | Did hitting the cap drive upgrades, or did people just walk away? |
| 2 | **P0** | Seven Wave-H intake screens emit **zero** analytics | `carrying_duration`, `heaviest_time`, `told_anyone`, `names_known`, `help_chips`, `daily_time`, `intake_note` — grep count 0 each | What did a third of the live onboarding flow actually tell us? Chip distribution, typed-vs-skipped: all unknown. |
| 3 | **P0** | Real abandonment is unmeasurable (S1) | `onboarding_screen.dart:407-435` | Where do people actually quit onboarding? |
| 4 | **P0** | Restore Purchases has zero instrumentation | `paywall_screen.dart:813-835`; `store_screen.dart:415-430` | Is restore failing? A silent failure is identical to never-tapped — and it is a churn + support path. |
| 5 | **P0** | `paywall_closed` is a bare `track()` — no properties at all | `paywall_screen.dart:581` | Which surface did they close? Every sibling (`soft_gate_dismissed` `:586`, `free_tier_entered` `:628`, exit-offer `:565`) carries `placement`. |
| 6 | **P1** | `consume_weekly_allowance` failures are invisible | `gating_service.dart:395-408`; `supabase_sync_service.dart:371` (`debugPrint` only, dead in release) | Is the weekly pool working in prod? If the RPC refuses everyone, the only symptom anywhere is fewer Postgres rows. |
| 7 | **P1** | `daily_cap_hit` carries only `{feature}` | `gating_service.dart:663-667` (comment at `:658` explicitly defers this to W6) | Warmup exhaustion vs weekly-pool block vs lapsed-trial vs re-roll wall — indistinguishable. |
| 8 | **P1** | `check_in_completed` lacks `name_source`/`queue_position` (S3) | `daily_loop_provider.dart:1366-1374` | Did the 7-day plan actually run, or are people getting gacha Names? |
| 9 | **P1** | A failed AI call is indistinguishable from an abandon | `daily_loop_provider.dart:2087-2092` | An OpenAI outage would read as a user-behaviour collapse. AI path only; the deck path is immune by construction. |
| 10 | **P1** | No purchase economics on any purchase event | `trial_started`/`subscription_started_no_trial`/`purchase_sheet_*` carry only `plan` | If RevenueCat's price or offering changes, Mixpanel alone cannot detect or attribute it. |
| 11 | **P1** | ~7 distinct soft-paywall triggers all collapse to `soft_inapp` | `settings_premium_card.dart:100`, `home_premium_strip.dart:96`, `collection_screen.dart:277`, `progress_screen.dart:197`, + the cap/warmup upgrades | Which surface moved conversion? |
| 12 | **P1** | `flag_hard_paywall` boots with `fallback: false` while prod is `true` | `main.dart:364` | First-install users mis-segment at the funnel's widest point. Mechanism is **boot-order**, not just the fallback: the super property is stamped from a cold cache, while the behavioural read later in the session sees the primed `true`. |
| 13 | **P1** | No `onboarding_flow` / `flag_reel_first_onboarding` super property | `analytics_events.dart:47-53` carries only `flag_onboarding_trim`, `flag_hard_paywall`, `flag_guided_tour` | Which flow did this user get? Only inferable from which step names appear — fragile, and not a filter. |
| 14 | **P1** | Cohort assignment failure is silent | `handle_new_user` falls back to `'legacy'` on a missing/misspelled `new_signup_cohort` | If the T0 flip typos the value, every new signup silently gets the wrong tier and nothing alerts. |
| 15 | P2 | Nothing pins the two new `removeSuperProperty` calls | `analytics_events.dart:79-81`; `test/services/bootstrap_analytics_test.dart:73-75` still only asserts `flag_tour_ab` | A refactor could drop one and upgraded installs stamp `flag_reverse_trial_exp`/`paywall_exp_arm` forever — the exact failure the code's own comment warns about. |
| 16 | P2 | Every migration from `20260726` on has a filename-vs-`schema_migrations` version mismatch | `supabase/migrations/` vs remote | Bodies are byte-identical to prod, so nothing is broken — but `supabase db reset` applies in filename order, provably not the order prod saw. Latent; spans the lantern set too. |
| 17 | P2 | `paywall_plan_selected` fires without `placement` | `paywall_screen.dart:947` | The one event on that screen inconsistent with its own siblings. |
| 18 | P2 | Intro-offer eligibility is not recorded at view time | derived post-purchase only, `paywall_screen.dart:216-227` | Cannot segment `paywall_viewed` by "was a trial even available?" |

### 8c. Verified clean — do not re-audit

Recording this deliberately; it is the half that stops the next person repeating
the work.

- **Wave A close-out**: no P0/P1. `flutter analyze` 0 errors. Every deleted test
  either died with its sole source file or was **re-pointed**; the
  `purchase_service_trial_premium_test.dart` case was *strengthened*. Zero live
  references remain to `assignPaywallArm`, `paywall_exp_arm`,
  `reverse_trial_experiment_enabled`, `tourBucket` and friends — every hit is a
  comment explaining the freeze. Staged SQL is idempotent with its destructive
  step commented out behind a count gate.
- **Full suite green**: 3086 passed / 4 skipped / **0 failed** on the post-Wave-A
  tree.
- **W1 server correctness**: all five W1 function/trigger bodies **byte-identical**
  to prod (diffed via `pg_get_definition`). The ratchet guard is genuinely
  decrement-only and the client never writes a locally-derived absolute back into
  a guarded column — *the known hazard pattern does not apply here.* `safe_user_tz`
  NULL/invalid → UTC is correct; worst case is a few-hour week-boundary skew.
- **Privacy holds.** `trackOnboardingAnswer` (`analytics_events.dart:131-146`)
  takes structured values, never free text. `IntakeNoteScreen` — the one
  free-text screen — never calls it. The gap in 8b#2 and the safety guarantee are
  the *same fact*.
- **`reelStepNames`** (`analytics_event_names.dart:915-939`) has exactly 19 entries
  matching the 19 `_reelChildren` 1:1, and joins correctly across flow variants.
  D6 stands: it *is* the stable step id.
- **Boot ordering is otherwise correct** — `platform`, `app_version`, `install_id`
  and the `flag_*` set all register before `app_opened` (`main.dart:302-368`).
  `identify()` fires immediately before `signup_completed` on both email and
  social paths, consistent with Simplified ID Merge.
- **Daily-loop code paths**: `completeDeeper()` idempotent (`:2105`); quest hooks
  double-tap-guarded; `resetToday()` cannot lose a granted reward (economy is
  server-committed first); `markUsed` placement preserves the "the surface that
  asks what is on your heart must never answer with a cap sheet" invariant — in
  code, not just in comments.
- **`d696049` (home CTA completed-state deletion) took no analytics with it** —
  verified against the pre-deletion diff.
- **Two good patterns already in-tree, to copy rather than design:**
  `LapsedTrialSheet.show`'s `fireDismissOnce` reconciliation collapses all four
  dismissal routes into exactly one event — this is what the cap/warmup sheets
  need. And `seed_name_queue` failure handling
  (`onboarding_provider.dart:1195`: `name_queue_seed_failed{error_class, id_count}`
  plus a persisted retry marker) is the model for 8b#6, which has the identical
  failure shape and none of the handling.

### 8d. Release-blocking, and NOT W6's problem

Recorded here because it surfaced in this audit and must not be lost in a plan
nobody reads before shipping.

**1.3.0 must not reach users before 2026-08-04 ~17:18 UTC.** Verified in prod
2026-08-01 18:22 UTC: **25 app-granted trials still in flight**, last expiry
**2026-08-04 17:17:40 UTC**. `reverse_trial_experiment_enabled` is now `false`,
so the horizon is **frozen** — before the flip it slid forward 72h with every
signup.

The nuance, because the two halves are easy to conflate:

- An existing device with a **cached** trial is fine. `purchase_service.dart:135`
  still reads it and `_isTimedPremium` re-compares against `now()` every call, so
  it self-expires and nothing claws it back. Pinned by a new test.
- A trial user with an **empty cache** — reinstall, new device, cleared storage —
  is **not** fine. The writer is gone (`purchase_service.dart:202` marks where
  `refreshTrialPremiumCache()` lived; grep confirms nothing else writes that key),
  so there is no path to restore their premium from the server.

Submit whenever; **hold the release** (1.2.0 used `releaseType: MANUAL`) until the
in-flight count reads 0. See `TODO.md` §"Ship checklist — 1.3.0".

### 8e. Cross-cutting: out-of-app surfaces and release health

Continues the ranking in 8b. **The first entry outranks everything above it** and
is recorded separately only because it is not an instrumentation gap — it is the
thing that decides whether instrumentation exists at all.

| # | Sev | Finding | Location | The question you cannot answer |
|---|---|---|---|---|
| 19 | **P0 ↑** | **`Mixpanel.init` is unguarded, and a null client fails silently forever** | `analytics_service.dart:6-9` — `_mixpanel = await Mixpanel.init(token, …)` with no try/catch, called unguarded from `main.dart:300`. Every emitter is `_mixpanel?.track(...)` (`:11-13`). | **Did we receive any data at all?** If init throws — or the token is empty, which `:7` treats as a silent early return — `_mixpanel` stays null and *every* `track()` for the entire process lifetime is a no-op. No exception, no log, no partial data. Note `env.json` is a compile-time define: a build without it produces an empty token and therefore a totally silent app. This is the single highest-leverage failure in the pipeline and it has **zero** guardrail. |
| 20 | **P0** | **No crash reporting of any kind** | Verified: `grep -rniE "sentry\|crashlytics\|runZonedGuarded\|FlutterError.onError\|PlatformDispatcher.instance.onError" lib/ pubspec.yaml` → **zero matches** | **Is this drop a quit or a crash?** They are indistinguishable, everywhere, by construction. Every drop-off number in this document has an unknown crash component, and `session_started`/`app_opened` counts include crash-truncated sessions with no denominator correction. |
| 21 | **P0** | **Push rows are marked sent *before* the send, and regardless of its result** | `send-scheduled-notifications/index.ts:891-897` — `await markSent(...)` runs for **all** eligible users and sets `marked = users.length`; the per-user send loop follows, and only `ok` gates `sent` + `notification_sent` (`:918`) | **Did the notification go out?** A transient OneSignal 5xx means: no push delivered, the row permanently stamped sent, **no retry ever**, and the only trace is a `console.error` (`:628`) nobody reviews. `summary[type].sent < .marked` is the sole in-band signal and it is surfaced nowhere. Same family as the 2026-07-17 outage — **do not touch cron auth/wiring while fixing this.** |
| 22 | **P0** | Widget staleness is permanently invisible | `widget_sync.dart:178-208` — the entire refresh pipeline behind one `catch (_) {}` | **Is the widget showing the right Name?** Any failure leaves stale content forever with no telemetry. There is no failure event to pair against `widget_installed_state`. |
| 23 | **P1** | `notification_opened` is **dropped entirely** on a cold launch via push tap | `main.dart:294` wires `addClickListener()`; `NotificationService.onAnalyticsEvent` is not assigned until `:400`. The emitter at `notification_service.dart:534` is `onAnalyticsEvent?.call(...)`. | **Do pushes drive opens?** In that window the hook is still null, so the event is not merely missing super-properties — it never fires. This is a *different* class from the ordering gaps elsewhere and needs its own fix. |
| 24 | P2 | Reel `reel_id` never reaches Mixpanel | `reel_deep_link_service.dart`, `onboarding_provider.dart:399` — survives into the Supabase `acquisition_promise` jsonb only | **Which reel converts?** Measurable only by joining Supabase; not natively segmentable. Relevant to **D3**, which leans on `contract` precisely because reel identity is weak. |

**Attribution verdict — good, with one real gap.** `app_version`, `platform`,
`is_premium` and `install_id` are all registered before `app_opened` and ride
every subsequent event; `install_id` is correctly a join key on both the Mixpanel
and RevenueCat sides (and correctly re-mints on reinstall). The `'unknown'`
`app_version` sentinel (`main.dart:320-321`) is realistically near-zero but
unmonitored. The gap is #23 above, plus everything in the `await` window between
`analytics.initialize()` (`main.dart:300`) and `registerBootstrapAnalytics()`
(`:355`).

**Solid, confirmed rather than assumed:** the Duʿā-times and Live-Activities
telemetry is genuinely complete end to end (`dua_schedule_built`,
`dua_notif_synced`, `dua_live_activity_started/_ended/_tapped`);
`widget_opened{target,launch,source}` and `widget_installed_state` are real and
correctly wired; session/lifecycle and the `is_premium` resume-refresh are
well-designed; push has real `notification_sent` telemetry with `insertId` dedup
**on the success path**.

**Swallowed errors:** 66 bare `catch (_) {}` blocks in `lib/` (215 `catch (_)`
occurrences overall). The three that matter are #21, #22, and
`purchase_service.dart:122-136`, where a transient RevenueCat network error
inside `isPremium()` is swallowed and the user is treated as free **for that
call** — which can show a paywall or gate an AI feature for an active subscriber,
with no log line.

### 8f. What the audit changes about §4

The waves in §4 were written against the plan. Against the tree they need three
amendments, and the ordering argument gets stronger, not weaker.

**1. A new Wave 0 precedes everything, and it is not optional.** Findings #19 and
#20 are prerequisites for *trusting any number this plan produces*. Guarding
`Mixpanel.init` and adding a delivery/health assertion is a handful of lines;
without it, a green build can ship total analytics silence and the first symptom
is an empty dashboard at the T0 read. Crash reporting is a larger call — it is a
new dependency and the founder may reasonably defer it — but it must be **decided**,
not defaulted, because every drop-off number in §8b carries an unmeasured crash
component until it exists.

**2. Wave C absorbs the cap-sheet blackout (S2) and Restore.** It was scoped as
"add `reason` to `daily_cap_hit`". It now also owns the sheet impression and
dismissal events for both cap and warmup sheets, and Restore instrumentation. The
dismissal work is a **transplant, not a design**: `LapsedTrialSheet.show`'s
`fireDismissOnce` reconciliation already collapses button / scrim / swipe /
Android-back into exactly one event. Copy it.

**3. A new Wave F — the seven silent intake screens.** Mechanically the smallest
item in the plan (seven `trackOnboardingAnswerWithRef` calls mirroring
`age_range_screen.dart:35`) and among the highest value, because it is a third of
the live flow. **Keep the privacy line exactly where it is:** bucketed and
categorical values only; `IntakeNoteScreen` records *that* a note was written and
its length bucket, never its text.

**4. Wave B is bigger than a wave.** S3 confirms it inherits unbuilt W3 feature
work, not just events. Either scope it honestly or split the feature out — but do
not leave it costed as instrumentation.

**5. The abandonment funnel is redesigned, not instrumented** (S1). Pair
`step_viewed` against `step_completed`; rename the resume-only event to say it
measures returners.

**6. Ordering.** Wave A already had to land first and alone. #19 makes that
stricter: **Wave 0 lands before Wave A**, because a super property registered
into a null Mixpanel client is not registered at all.

---

## 9. Eng review outcomes — the authoritative wave list (2026-08-01)

`/plan-eng-review`, run after the W1–W5 audit. Four decisions were put to the
founder; all four are recorded here with what changed. **This section supersedes
§4's wave list.** §4's file lists, steps and test tables remain valid for the
waves that survive.

### D2 — W6 is instrumentation. Two things that are not instrumentation were split out.

**Decision: split.** W6 was budgeted as "add events." Two waves were not that:

- **Wave B (the Second-Name lifecycle) LEAVES W6.** It is inherited *feature*
  work from W3 Wave 5 that never shipped — a new service, a TTL-stamped
  attribution seam, changes to the daily loop. Costing it as instrumentation is
  how it gets silently dropped under time pressure, which §6.4 already flagged as
  its most likely fate. **It must be tracked as its own scoped item.** Do not let
  it die here: it is the only measurement of whether the seven-day queue — the
  ship's central retention mechanic — actually ran. §4's Wave B section stays in
  this document as its specification, not as W6 scope.
- **Crash reporting LEAVES W6** and becomes its own decision. It is a new
  third-party dependency (SDK, symbol upload, privacy) and does not get smuggled
  in under "instrumentation." **Until it exists, every drop-off number in this
  document carries an unmeasured crash component** — a crash and a quit are
  indistinguishable by construction (§8e#20). State that caveat wherever a
  drop-off number is quoted.
- **The `Mixpanel.init` guard STAYS** (§8e#19). It is ~10 lines and it protects
  every other number in the plan.

### D3 — The ordering risk is guarded structurally, not instance by instance.

**Decision: debug assert in `track()`.** `AnalyticsService.track()` currently
sends whether or not super properties are registered, so an early event ships
permanently unlabelled and Mixpanel never backfills. The plan's original answer
was one ordering test plus a manual T0+24h check — which covers the events
enumerated here and nothing anyone adds later.

The assert fires in debug and test builds when `track()` runs before the boot
super properties are registered. It is a no-op in release, so there is **no**
production behaviour change and no risk of eating events in the field. Wave A's
ordering test stays; this generalises it to every future event.

Rejected: buffering events until registration completes. It is the only option
that also fixes production, but a flush that never runs (init throws, app killed
early) silently drops the whole session — trading a visible-in-aggregate problem
for total loss, on the one class that must never fail.

### D4 — A satisfaction readout is added to Wave E.

**Decision: add it, using signals that already emit.** The plan measured whether
users *move* and whether they *pay*, and nothing about whether they are happy —
which would let a conversion-positive, retention-negative outcome read as success
for the entire six-week watch window.

Most of the signal already exists and was never assembled:

| Signal | Status | Where |
|---|---|---|
| Rating-gate accept rate | **already emitting** | `rating_gate_shown` / `_prompt_triggered` / `_continue_tapped` / `_skipped`, `analytics_event_names.dart:163-166` |
| Churn reasons | **already emitting** | `cancellation_feedback_shown` / `_submitted` / `_dismissed`, `:424-425` |
| D1 / D7 / D30 retention | **computable** | `app_opened`, `session_started` |
| Refunds | **not wired** | RevenueCat webhook; deliberately deferred (touches a server-secret path that has bitten this project) |
| Review velocity / keywords | **not wired** | App Store Connect; stays the master plan's manual weekly scan |

Wave E gains: the four readable numbers above, segmented by `free_tier_cohort`
and `app_version`, **with explicit "what bad looks like" thresholds** — a
retention guardrail stated as a number, not a vibe, so a conversion win that
hides a retention loss cannot pass unnoticed. Name the two unwired signals in the
readout doc as known blind spots rather than leaving them implied.

### The authoritative wave list

```
Wave 0  ── the guard ─────────────────────────────┐
          Mixpanel.init try/catch + empty-token   │  must land first:
          signal + debug assert in track()        │  a super property
                                                  │  registered into a
Wave A  ── super properties ──────────────────────┤  null client is not
          onboarding_flow, contract,              │  registered at all
          acquisition_problem_category,           │
          reel_hook + reel_hook_source,           │
          free_tier_cohort, flag_hard_paywall fix ┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
     Wave C          Wave D          Wave F          (parallel — disjoint files,
   the gate's       Phase-4          the seven        collide only in the
     meter           holes         intake screens     append-only constants file)
        │               │               │
        └───────────────┼───────────────┘
                        ▼
                     Wave E
              people property, readout doc,
              satisfaction read, amendments

SPLIT OUT OF W6:  Wave B (Second-Name lifecycle — feature work, own costing)
                  Crash reporting (new dependency, own decision)
```

**Wave C is larger than §4 describes.** Beyond `daily_cap_hit{reason}`,
`ai_taste_consumed` and `paywall_closed{placement}`, it absorbs from §8b:

- **The cap-sheet blackout (§8a S2)** — `warmup_exhausted_sheet.dart` emits
  nothing and `daily_cap_sheet.dart` emits only the two bypass events, both on a
  path `reel_v1` cannot reach. Impression and dismissal events for both sheets.
  **The dismissal work is a transplant, not a design**: `LapsedTrialSheet.show`'s
  `fireDismissOnce` reconciliation already collapses button / scrim / swipe /
  Android-back into exactly one event. Copy it.
- **Restore Purchases (§8b#4)** — currently zero instrumentation at
  `paywall_screen.dart:813-835` and `store_screen.dart:415-430`.

**Wave F is new** — the seven Wave-H intake screens that emit nothing
(`carrying_duration`, `heaviest_time`, `told_anyone`, `names_known`,
`help_chips`, `daily_time`, `intake_note`). Mechanically the smallest item here
and among the highest value, since it is a third of the live flow. Mirror
`age_range_screen.dart:35`. **Keep the privacy line exactly where it is:**
bucketed and categorical values only; `IntakeNoteScreen` records *that* a note
was written and its length bucket, never its text.

### Tests for the two new waves

§4's test tables cover A, C, D and E. Wave 0 and Wave F did not exist when those
were written.

| Test | Pins | Mutation that must fail it |
|---|---|---|
| `test/services/analytics_init_guard_test.dart` | a throwing `Mixpanel.init` is caught and surfaced, not swallowed into a permanently-null client; an empty token is distinguishable from a healthy one | remove the try/catch; make the empty-token path silent again |
| `test/services/track_before_super_properties_test.dart` | `track()` asserts when called before boot registration | emit any event ahead of `registerBootstrapAnalytics` |
| `test/features/onboarding/intake_screens_emit_answers_test.dart` | all seven screens emit a bucketed answer on advance | drop the call from any one screen |
| `test/features/onboarding/intake_note_never_sends_text_test.dart` | `IntakeNoteScreen` emits a length bucket and **never** the note body — source-level grep plus a behavioural assert | pass the raw text as the property value |

### Still open after this review

- **`step_viewed` without `step_completed` is the drop-off signal** (§8a S1).
  Wave E's readout must define the funnel on that pairing and rename the
  resume-only event to say it measures *returners*. Not yet written into Wave E's
  steps.
- **Wave B and crash reporting need homes.** Split out, not cancelled.

---

## 10. What already exists (do not rebuild)

The §2 audit is the full version. The three found *during eng review*, absent
from §2, all bear on the satisfaction read (D4):

| Already emitting | Where | W6 reuses it for |
|---|---|---|
| Rating gate, 4 events | `analytics_event_names.dart:163-166` | satisfaction proxy at onboarding |
| Cancellation feedback, 3 events | `:424-425` | churn reasons |
| `app_opened` / `session_started` | `:8,30` | D1/D7/D30 retention |
| `LapsedTrialSheet.fireDismissOnce` | `lapsed_trial_sheet.dart:83-89` | **copy verbatim** for the cap/warmup sheet dismissals (Wave C) |
| `trackOnboardingAnswerWithRef` | `analytics_events.dart:131-146` | the seven intake screens (Wave F) — mirror `age_range_screen.dart:35` |
| `seed_name_queue` failure handling | `onboarding_provider.dart:1195` | the model for instrumenting `consume_weekly_allowance` |

Nothing in W6 needs a new mechanism. Every wave is either a call to an existing
helper or a property added to an event that already fires.

## 11. NOT in scope

| Deferred | Why |
|---|---|
| **Wave B — Second-Name lifecycle** | Feature work, not instrumentation (D2). Split out with its own costing. Spec stays at §4 Wave B. **Must be tracked; it is the only measurement of the seven-day queue.** |
| **Crash reporting** | New third-party dependency; own decision (D2). Until it lands, every drop-off number carries an unmeasured crash component. |
| **Refund events (RevenueCat webhook)** | Touches a server-secret path that has caused an outage here. Named as a known blind spot in the readout instead (D4). |
| **App Store review velocity** | ASC-side, aggregate, lagged. Stays the master plan's manual weekly keyword scan. |
| **Any Mixpanel dashboard** | Readout doc's job, post-T0. |
| **ASC Campaign Links** | Ops task, not code. TODO.md §`reel_hook` step 3 keeps it. |
| **Deleting tour emitters / legacy flags / `answerCheckin()`** | Post-keep hygiene ledger. |
| **Server-side `names_met` definition** | D8 ships a client-derived, explicitly-scoped substitute. |

## 12. Implementation Tasks

Synthesized from this review. Each derives from a specific finding. P1 blocks
the T0 build; P2 should land the same branch; P3 is tracked elsewhere.

- [ ] **T1 (P1, human: ~2h / CC: ~15min)** — Wave 0 — Guard `Mixpanel.init` and assert ordering in `track()`
  - Surfaced by: §8e#19 — a throwing init or empty token leaves `_mixpanel` null and every event a silent no-op forever
  - Files: `lib/services/analytics_service.dart`, `lib/main.dart`
  - Verify: `flutter test test/services/analytics_init_guard_test.dart test/services/track_before_super_properties_test.dart`

- [ ] **T2 (P1, human: ~1d / CC: ~45min)** — Wave A — Register the six super properties, with provenance; fix `flag_hard_paywall`
  - Surfaced by: §2a (none of the six built) and §2e.1 (`main.dart:364` boots `fallback: false` against a prod `true`)
  - Files: `analytics_event_names.dart`, `analytics_events.dart`, `main.dart`, `onboarding_screen.dart`, `hook_problem_screen.dart`, `source_question_screen.dart`, `app_lifecycle_observer.dart`
  - Verify: the five tests in §4 Wave A, each with its stated mutation

- [ ] **T3 (P1, human: ~1d / CC: ~40min)** — Wave C — The gate's meter, the cap-sheet blackout, and Restore
  - Surfaced by: §8a S2 (sheets dark for `reel_v1`), §8b#4 (Restore untracked), #5 (`paywall_closed` bare), #7 (`daily_cap_hit` has only `feature`)
  - Files: `gating_service.dart`, `paywall_screen.dart`, `store_screen.dart`, `daily_cap_sheet.dart`, `warmup_exhausted_sheet.dart`
  - Verify: §4 Wave C's four tests + a dismissal test per sheet copying `fireDismissOnce`

- [ ] **T4 (P1, human: ~2h / CC: ~15min)** — Wave F — The seven silent intake screens
  - Surfaced by: §8b#2 — grep count of `track(` is 0 in all seven; a third of the live flow reports nothing
  - Files: the seven screens under `lib/features/onboarding/screens/`
  - Verify: `intake_screens_emit_answers_test.dart` + `intake_note_never_sends_text_test.dart`

- [ ] **T5 (P2, human: ~4h / CC: ~25min)** — Wave D — `reflect_started`/`_completed`, `names_browse_viewed`, `dua_read`
  - Surfaced by: §2c — the never-superseded v1 Phase-4 holes; Reflect was zero-instrumented at diagnosis
  - Files: `reflect_provider.dart`, `names_screen.dart`, `duas_screen.dart`
  - Verify: §4 Wave D's three tests

- [ ] **T6 (P2, human: ~4h / CC: ~30min)** — Wave E — Readout doc, satisfaction read, people property, amendments
  - Surfaced by: D4 (no satisfaction readout), §8a S1 (drop-off must be defined on `step_viewed` vs `step_completed`), D1/D5/D6 amendments
  - Files: `docs/analytics/funnel-flags-and-querying.md`, master plan, `TODO.md`, `gating_service.dart`
  - Verify: `names_met_people_property_test.dart`; the doc work is pinned by review, not tests

- [ ] **T7 (P3, tracked outside W6)** — Wave B — Second-Name lifecycle
  - Surfaced by: §8a S3 — W3 Wave 5 never landed; zero `second_name` hits in `lib/`
  - Files: per §4 Wave B
  - Verify: §4 Wave B's six tests

- [ ] **T8 (P3, decision not code)** — Crash reporting: adopt or accept the blind spot
  - Surfaced by: §8e#20 — zero crash reporting; a crash is indistinguishable from a quit
  - Verify: n/a — a decision with a dated entry either way

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 8 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**Scope:** REDUCED — Wave B and crash reporting split out of W6 (D2); Wave 0 and
Wave F added from the W1–W5 audit.

**Findings:** Architecture 4 · Code Quality 0 blocking · Tests 2 gaps (both newly
added waves, now written) · Performance 0. Four decisions taken (D1–D4 of this
review), all folded into §9.

**VERDICT:** ENG CLEARED — ready to implement. Wave order is
`0 → A → C ‖ D ‖ F → E`; Wave 0 lands first because a super property registered
into a null Mixpanel client is not registered at all.

NO UNRESOLVED DECISIONS
