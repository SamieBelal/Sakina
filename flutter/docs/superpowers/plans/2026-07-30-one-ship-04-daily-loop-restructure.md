# One Ship W4 — the daily loop asks

**Status: PLAN — ready to build. All product decisions closed (spec §12). No blocking founder questions.**
**Date:** 2026-07-30
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first`
**Spec:** [`../specs/2026-07-30-daily-loop-asks-design.md`](../specs/2026-07-30-daily-loop-asks-design.md)
**Parents:** `2026-07-23-conversion-refactor-changes-and-implementation.md` §W4 + D9 · `2026-07-29-one-ship-03-daily-loop.md` (the queue seam this consumes)
**Evidence:** `docs/research/2026-07-29-daily-loop-internal-audit.md` · `docs/research/2026-07-29-day-open-loops-external-research.md`

W4 makes the daily loop ask the question the reels sell. Day-open routes into a free-text prompt on the sacred canvas, the answer drives the reflection, the card reveal covers the AI latency, and the reward ceremony moves behind the work. **Ships to all users**, kill-switched, with Name *selection* still cohort-scoped.

**Non-goals:** the paywall and free-tier limits (W5) · funnel super-properties and `reel_hook` (W6) · Phase B notifications (post-ship) · rotating the question's framing (W6) · any mood graph, ever (spec §10) · onboarding-screen changes of any kind.

---

## 1. Verified baseline (read on 2026-07-30, at HEAD `bdf0c34`)

- `DailyLoopStep.checkin` is the initial step and has **no UI**: `muhasabah_screen.dart:388-389` falls through to `ReflectLoading()` because `discoverName()` is already in flight.
- `DailyLoopState.checkinAnswers` (`daily_loop_provider.dart:59`) is already in `copyWith`, already persisted by `_persistTodayState` (`:1431`), already restored by `_loadTodayState` (`:1466`).
- `_deeperContextText` (`:1183-1203`) **already prefers `checkinAnswers`** over the card blurb. `_deeperRequestFor` (`:1169-1181`) already sets `forceName = state.checkinName`.
- `reflectWithOpenAI(userText, {ReflectContext? context, String? forceName})` — `ai_service.dart:804-807`, force clause at `:156-159`. Model `gpt-4o-mini`, `maxCompletionTokens: 1500`, `temperature: 0.7`. **Measured system prompt: 6,664 chars ≈ 1,666 tokens** with no context; 2–3k with history + teaching context. ≈ **$0.001/call**.
- `normalizeApprovedVerses` (`reflection_verse_catalog.dart:1138-1163`) drops any verse the model returns that is not in the approved catalog, then falls back to approved-verses-for-Name. **98 Names carry approved verses, including the gratitude Names.** The AI selects; it never authors.
- `claimDailyReward()` is already called at `daily_loop_provider.dart:1160`, idempotent, with a comment that the overlay may have claimed first.
- `claim_daily_reward` (`20260417000000_daily_reward_premium_multiplier.sql:86-92`) is a 7-day escalating ladder that **resets to day 0** when `last_claim_date` is neither today nor yesterday.
- `progress_screen.dart:975-1010` — CTA calls `canUse` then `markUsed` **before** the reveal, behind a `_discoverInFlight` re-entry guard added after a double-tap double-charged.
- **CORRECTED 2026-07-30 during Wave 1** — that is only the *re-roll* CTA. The day-open path is **neither gated nor metered**: `progress_screen.dart:1046-1050` ("Begin Muḥāsabah") pushes `/muhasabah` with no `canUse` at all, and the screen's one-shot fires `discoverName()` unmetered. Only the two re-roll CTAs — "Discover a New Name" (`:975-1010`) and "Seek Another Name" (`muhasabah_screen.dart:780-841`) — ever charged. **A free user past warmup therefore has an effective 2 reveals/day: one unmetered day-open plus one metered re-roll**, and the 5-use warmup budget is spent on re-rolls only. `dailyFreeDiscoverNames = 1` is correct for what it governs; it simply never governed the day-open path. This went unrecorded, which is how Wave 1 nearly shipped a silent halving of the free tier.
- `parseWidgetDeepLink` (`widget_deep_link.dart:22-31`) → `/muhasabah`; handler comment (`:49-51`): a widget tap **takes precedence over the launch overlay**.
- `syncHomeWidget` (`widget_sync.dart:111-130`) pushes `todaysName: getTodaysName()` with `personalized:false` until check-in — a date rotation unrelated to the queue.
- `TourRouteObserver:29` treats route name `'DailyLaunchOverlay'` as blocking.
- `GatingService.warmupBudget[discoverName] = 5`; `discoverName` is permanently 1/day free for all users (§V6.8.B3) and the daily match is free forever (v1 plan `:522`).

## 2. Binding rules carried in

1. **Never fork `check_in_completed`.** `path` stays `'discover'`. It is the DAU event and the D1/D7 retention spine.
2. **Never write economy tables from Flutter.** Reward stays behind `claim_daily_reward`; XP/streak stay behind `sync_all_user_data()`.
3. **Never fabricate scripture.** The approved-verse normalizer is the firewall; do not add a path that bypasses it.
4. **Never mix Arabic and English in one `Text`.**
5. **The daily reveal stays free forever**, 1/day, for everyone. W5's tightening must not reach it.
6. **Copy firewall:** no "sign"/"meant for you" near a price, no clock or countdown near the reveal, no tier word adjacent to a Name, no guilt phrasing, and **no notification copy at all in this wave**.
7. **The escape hatch is non-negotiable.** Any day-open surface a user is dropped into must have a visible exit to home.

---

## 3. Wave 1 — move `markUsed` off the CTA *(prerequisite, lands alone)*

The single most dangerous edit in the wave, and everything else depends on it. Today the daily reveal is consumed when the button is pressed. Put a question between the tap and the reveal and a user who opens the prompt and backs out has burned their reveal for the day.

**Change:** `canUse` stays at the CTA (so a capped user is told *before* being asked to disclose anything); `markUsed` moves into `discoverName()`, firing only once a Name has actually been engaged.

**And the free tier is held exactly where it is.** Per the §1 correction, moving `markUsed` into `discoverName()` unqualified would have charged the day-open reveal for the first time ever, cutting a post-warmup free user from an effective 2 reveals/day to 1. This wave ships to **all** users, and §8a already went out of its way to avoid an unannounced takeaway on the reward ladder — silently removing a free reveal is the same class of thing. So Wave 1 splits it: **the day's first reveal is free and unmetered; only re-rolls are metered.** Net behaviour is identical to today, with the abandon-costs-nothing fix on top. `dailyFreeDiscoverNames` stays 1.

The marker (`daily_usage_service.hasTakenFreeDailyRevealToday` / `markFreeDailyRevealTaken`) is keyed off the same `_capDay()` as the cap counters, so the free reveal and the metered allowance cannot disagree about when the day turned over. It is read inside `discoverName` rather than passed down, because the re-roll signal cannot survive the trip: the home CTA calls `resetToday()` (wiping the day blob) and then navigates, so whatever fires the reveal on the other side of that push has no idea it was a re-roll.

This is a **safety** property as much as an economic one: the day-open reveal is where W4 asks what is on the user's heart, and that surface must never be able to answer a disclosure with a cap sheet. Because the free reveal consults no gate at all, it cannot. Any later wave that adds gating to the day-open path has to solve that first.

**What this drags in, and must not break:**
- `discoverNameWithBypass` (`:763-788`) and `discoverNameWithFirstBypass` (`:795-821`) — the reserve/commit/cancel machinery.
- The refund invariant: `state.error` decides commit-versus-cancel. If `markUsed` now fires inside the same method that sets `state.error`, ordering matters.
- `_discoverInFlight` (`progress_screen.dart:983`) must survive.
- Pinned by `discover_name_dispose_cancel_test.dart`.

**Tests:** open the question and abandon → nothing consumed. Complete → consumed exactly once. Double-tap → consumed once. Bypass purchase then failure → refunded. Warmup 5th use → `warmupJustExhausted` still surfaces. Plus the split: first-of-day → nothing consumed; the re-roll after it → consumed once; the re-roll after *that* → meets the cap sheet at exactly the moment it does today.

*Ships and is verified before any question UI exists.*

## 4. Wave 2 — the question surface

**New:** `lib/features/daily/widgets/daily_question_prompt.dart` (<200 lines, one widget per file).

- Sacred canvas (`AppColors.sacredCanvas*`), matching `BeatRevealFlow` so the transition into the reveal has no seam.
- **Header:** `What's on your heart today?` · **placeholder:** `A worry, a thanks, a question — however it comes out.`
- **Free-text field primary.** Reuse the keyboard-safety pattern every text screen uses: `LayoutBuilder → SingleChildScrollView → ConstrainedBox → IntrinsicHeight`.
- **7 problem chips demoted underneath** as quick-fill; tapping one fills and submits.
- **"Not right now" → defers the whole loop to the home CTA** for the rest of the day (spec M2). This is the exit, and it is a *defer*, not a dismissal: question, reveal and reward all remain collectible by tapping the promoted CTA. Skipping does **not** grant the reward.
- **Skip writes the day marker**, so auto-entry happens at most once per local day. After a skip the home CTA is the only entry — the question must not re-throw on every subsequent open.
- Calm entrance animation per `app_motion.dart` — no urgency mechanics, no timer, no auto-advance, no skip-pressure copy.
- Muḥāsabah introduced as a **gloss**, never as the button.

**Wiring:** `muhasabah_screen.dart:376-389` renders it for the `checkin` step instead of `ReflectLoading()`; `initState` (`:87-96`) stops auto-firing `discoverName()` when no answer exists. The existing "only implicit trigger" comment must be updated, not deleted — it records the phantom-second-gacha bug class.

**Accessibility:** 44pt minimum targets, Dynamic-Type-safe, VoiceOver reads header + placeholder, RTL isolation on every string.

## 5. Wave 3 — the answer drives the reflection

**New notifier method** on `DailyLoopNotifier`:

1. Write the text into `state.checkinAnswers` (single-element list) — persisted and restored for free.
2. Derive `problem_category` via `ProblemChipResolver.forFreeText` / `matchChipKeyForText` (pure, offline) — so typed input segments identically to a chip tap.
3. **Claim the reward here** (spec §6): `claimDailyReward()`, idempotent, at submit — not at "Ameen", so the escalating ladder survives a half-finished session.
4. Call `discoverName()`.

`discoverName()` is unchanged in its Name selection — queue planner for the cohort, `pickNextCard` for legacy. Then `_prefetchDeeperReflection()` picks the answer up through `_deeperContextText` **with no edit**, and `forceName` keeps the queue's Name during D1–D7.

**Latency rule:** the reveal must never block on the AI. The card reveal plays while the reflection is being written — the prefetch is already fire-and-forget; the requirement is that no new `await` gets added between submit and the reveal.

**Off-topic / empty input** reuse Reflect's existing handling rather than a new branch.

**Post-queue behaviour:** once the queue is exhausted the answer may pick the Name via `ProblemChipResolver`. Behind the same kill switch; if it slips, the fallback is today's `pickNextCard`, which is not a regression.

## 6. Wave 4 — day-open and the ceremony

- `DailyLaunchOverlay` stops being a two-step ceremony gate. Streak and lantern become **ambient**; the overlay routes into `/muhasabah` instead of `_dismiss()`-ing to home.
- The **animated ceremony + streak increment** move behind `completeDeeper()` ("Ameen"). The **grant** already happened at submit (Wave 3).
- **The launch-gate marker must be written on completion by any entry path** (`launch_gate_state.dart:24-29`), or a widget user who finishes the loop gets the day-open again an hour later.
- Whatever survives of the overlay keeps a visible exit — its route name is load-bearing for `TourRouteObserver`.
- **The UTC/local seam:** the launch gate is UTC (deliberately, to agree with `claim_daily_reward`); the queue unseal is user-local. They can disagree by up to a day near midnight. W3 fought this once — pin it with a test rather than find it on device.

## 7. Wave 5 — home screen

- CTA above the fold, out of the divider stack, no longer a sibling of Quests / Anchor Names / Daily Rewards.
- Renamed to the job. Muḥāsabah kept as a taught gloss (Hallow's Examen treatment).
- `_buildMuhasabahPromptLabel` (`:1095-1102`) deleted — the loop asks the question now; the home screen should not whisper it at 11px.
- Cut what outranks it: the unconditional `HomePremiumStrip`, the promo stack, the six-element stats row.
- **Design the completed state.** Today it degrades to an unstyled text row (`:975-1044`) indistinguishable from Quests.

## 8. Wave 6 — the widget and the three Names

**Entry needs no change** — a widget tap already lands on `/muhasabah`, which is now the question. What changes:

- **Pre-check-in, the widget stops advertising a Name it will not deliver.** `syncHomeWidget` passes `getTodaysName()` (a date rotation) with `personalized:false`; the reveal comes from the queue. Show lantern + streak and withhold the Name until check-in, or show the queue's real next Name.
- This collapses **three disagreeing "today's Name"** — widget rotation, overlay rotation (`daily_launch_overlay.dart:213-218`), and the actual reveal — into one notion.
- Re-push the widget on completion so `personalized:true` and `checkedInToday` land promptly.
- Live Activities and the duʿā-times widget are unaffected (a Live Activity `Link` goes straight to GoRouter, not through the widget-click stream).

## 9. Wave 7 — analytics

Constants into `analytics_event_names.dart` (append-only; coordinate with W6's appends). Emit via the static `onAnalyticsEvent` hook — no Riverpod in services.

**Existing event, extended — never forked:**
- `check_in_completed` gains `problem_category` and `input_mode` (`typed` | `chip`). **`path` stays `'discover'`.** W3's carried wave also adds `name_source` / `queue_position` here — same block, coordinate.

**New within-wave funnel** (spec §2 — this carries the attribution weight the coarse cohort read cannot):
- `daily_question_shown{entry_source}` — `entry_source` ∈ `day_open` | `widget` | `home_cta`, so the widget path is separable from day-open.
- `daily_question_answered{problem_category, input_mode, char_count_bucket}` — bucketed length, never the text. **The verbatim answer is never sent to Mixpanel.**
- `daily_question_skipped{dwell_ms_bucket}` — "Not right now". A deliberate defer: the *placement* was wrong for that moment.
- `daily_question_abandoned{dwell_ms_bucket}` — backgrounded or navigated away without deciding. The *question* was wrong. **These two must never be merged** — the difference between "people want this later" and "people don't want this" is the whole readout.
- **Same-day return rate is the headline metric for the skip design:** `daily_question_shown{entry_source:'home_cta'}` following a skip, over skips. If skippers do not come back, the defer is a polite exit from the product rather than a deferral within it.
- `daily_reward_claimed{trigger:'answer_submit'}` — so the re-timing is visible in the data rather than inferred.

**Guardrails:**
- Test-account exclusion applies to every readout (`docs/qa/mixpanel-orphaned-distinct-ids.json`).
- Reuse the chip taxonomy for `problem_category`, **not** the 30-question option bank — that is a different vocabulary and would fork segmentation away from `acquisition_promise.problem_category`.
- Debug-assert that `daily_question_shown` never fires twice in one local day.

## 10. Parallelism

Wave 1 lands **first and alone**. After it: Waves 2 → 3 are serial (3 consumes 2's submit callback). Waves 5, 6 and 7 can run in parallel with each other once 3 has landed. Wave 4 needs 3.

**Merge hazard:** W3's own unbuilt waves also edit `daily_loop_provider.dart` (`sealed_name_offer.dart`, the queue-aware CTA subtitle, `queueSealedRemaining` persistence). Either land those first or accept the merge — do not run them concurrently with Wave 3 here.

## 11. Test plan

- **Gating (Wave 1):** abandon consumes nothing · complete consumes once · double-tap consumes once · bypass refund on failure · warmup exhaustion still surfaces.
- **Question surface:** renders for `checkin` and not for `deeper`/`completed` · chip tap and typed text produce the same `problem_category` for equivalent input · keyboard does not overflow · RTL isolation.
- **Skip / defer:** "Not right now" lands on home with **no reveal, no reward, nothing consumed** · the day marker is written so a second open the same day does **not** re-throw the question · the home CTA renders its not-started (emerald) state and re-enters the full flow · completing after a skip claims the reward normally · a skip followed by no return leaves the ladder to reset exactly as a missed day does today.
- **Answer → reflection:** `checkinAnswers` reaches `_deeperContextText` · `forceName` still pins the queue's Name during D1–D7 · reveal does not await the AI · off-topic branch renders.
- **Reward re-timing:** claim fires at submit exactly once · idempotent on replay · a user who abandons after submit keeps the ladder · the ladder still resets after a genuinely missed day.
- **Entry paths:** widget tap → question · day-open → question · home CTA → question · completing by widget writes the launch-gate marker so day-open does not re-fire.
- **Day boundary:** cross-midnight with UTC gate vs local unseal disagreeing; the local-day memo stays scoped to the account.
- **Cold restart mid-question** — the answer survives, and a second reveal is not run.
- **Kill switch:** flipped → the current no-question `discoverName` path, verified on device.
- Full suite green + `flutter analyze` + `./scripts/check_no_fake_strings.sh`.

**Device pass (rolls into W7):** widget tap into the question on a cold launch · a full day-open → answer → reveal → Ameen → ceremony run · the same run in airplane mode (retry, never a wrong Name) · force-quit mid-question · RTL on the prompt · confirm on a real screen that the promoted CTA is above the fold.

## 12. Risks

1. **`markUsed` (Wave 1)** — small in lines, large in blast radius. Mitigated by landing alone with its own tests.
2. **Latency at day-open.** We are reintroducing exactly what the April 2026 commit removed. Mitigated by playing the reveal over the call; watched via the abandoned event.
3. **Typing daily is heavier than tapping**, and contradicts the one-tap-first research (spec M2 records the divergence and the reasoning). The chips are the hedge, the defer is the pressure valve, and the funnel is the detector. **Materially reduced** by the skip design — "type, or come back to it whenever" is a much smaller daily ask than "type now."
4. **Reflect and the daily loop converge.** W5's free-tier design assumed more separation than this leaves. Flag forward, do not solve here.
5. **Shipping to all users** widens the population changing mid-window. Accepted under D9; the within-wave funnel is the compensation.
6. **The defer could become an exit rather than a deferral.** If most users skip and never return the same day, we have shipped a polite way out of the core loop. `daily_question_skipped` → `daily_question_shown{entry_source:'home_cta'}` is the tripwire, and it is worth watching from day one rather than at the T0+2wk read.

## 13. Open questions

None blocking. Build-time judgement calls (exact motion curves, chip ordering, the completed-state layout) are mine unless they turn out to be product questions in disguise, in which case they go back to the spec's decision log.
