# W4 — The daily loop asks

**Status: SPEC — SETTLED 2026-07-30. Sequencing approved (this becomes W4; gate + free tier slides to W5). Both product decisions closed in the same session: §6 = ceremony after the work, with the reward *claimed* at answer-submit; §7 = one generic question whose answer space carries the good day, no separate gratitude branch. Input is free text primary (Reflect-shaped) per founder direction. Ships to all users, not cohort-gated (§8a). Implementation plan: [`../plans/2026-07-30-one-ship-04-daily-loop-restructure.md`](../plans/2026-07-30-one-ship-04-daily-loop-restructure.md).**
**Date:** 2026-07-30
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first`
**Parents:** `2026-07-23-conversion-refactor-changes-and-implementation.md` (master plan — this wave overturns its §V6.8.A5 deferral, see §2) · `2026-07-29-one-ship-03-daily-loop.md` (W3, whose queue seam this builds on) · `2026-07-03-reel-first-conversion-refactor.md` §Phase-2 (the original prescription, ranked #2 of 5 at ~1 week) · `docs/analytics/2026-07-14-conversion-diagnosis-and-research.md` (the leak table)
**Evidence base:** `docs/research/2026-07-29-daily-loop-internal-audit.md` · `docs/research/2026-07-29-day-open-loops-external-research.md`

---

## 1. Why this wave exists

**D0→D1 return is 31%.** 200 of 646. Sixty-nine percent of the people who sign up never open the app a second time. It is the largest leak in the funnel by volume, and the diagnosis names two broken pieces feeding it: the forced tour (killed 2026-07-28, it cost ~48% of signups) and **the core loop not re-delivering the reel promise**. The tour is dead. This wave is the other one.

The reels sell one thing: *tell it how you feel → your Name*. The app delivers that exactly once, on onboarding page 0. The live daily loop — `discoverName()` — is a blind gacha pull whose own dartdoc says *"Picks today's Name and engages it. No AI call, no questions."* The half of the product that matches the ad lives on a different tab (Reflect), grants no card and no XP, and sits behind a daily cap.

One detail from the audit says the whole thing in miniature. `_buildMuhasabahPromptLabel` (`progress_screen.dart:1095-1102`) **already renders today's question on the home screen** — *"Today: What is weighing on you most right now?"* — at 11px, the smallest type on the screen, as the subtitle of a button that is below the fold on essentially every device and that does not ask it when tapped.

We are already asking the reel's question. We are whispering it, below the fold, on a button that ignores the answer.

## 2. The deferral we are overturning, and the price

The master plan defers the feeling-first rewire to the first slot *after* the T0+6wk keep decision (§V6.8.A5). **That deferral was never about product doubt.** The plan calls the rewire *"the retention fix"*, ranks it **#2 of 5**, estimates **~1 week**, and targets exactly the metric that is bleeding. It was deferred for **measurement hygiene**: the One Ship's read is a pre/post comparison against a trailing-90d baseline with **no control arm** (§V6.9, founder decision 2026-07-23), so a second user-facing change inside the read window makes the ship's own result uninterpretable.

**The freeze is defined relative to T0, and T0 has not happened.** The one-change-at-a-time rule binds between T0 and the keep read. Folding this in *before* T0 does not break the freeze — it enlarges what the keep read measures as a single unit.

**The price, stated plainly so nobody rediscovers it in six weeks:** at the T0+6wk keep read we will not be able to separate the paywall's contribution from the loop change's. We will know whether the ship worked. We will not know which half did it. The founder accepted that trade on 2026-07-30 against the alternative of leaving the largest leak in the funnel unaddressed for six more weeks.

**Recorded consequence for W6's instrumentation:** because attribution is coarse at the cohort level, the *within-wave* instrumentation has to carry more weight than it otherwise would. Question-shown → answered → reveal-completed must be a clean funnel on its own, so that if the ship underperforms we can at least tell whether the question was the thing people bounced off.

## 3. What the day-open does today

From the audit, verified against source at HEAD `9b0f0a0`:

| # | tap | file:line |
|---|---|---|
| 1 | "Begin" (streak greeting) | `daily_launch_overlay.dart:323` |
| 2 | "Claim Reward" | `:414` |
| 3 | "Continue" | `:425` |
| 4 | "Begin Muhāsabah" on home | `progress_screen.dart:1048-1051` |

**Four taps, three of them pure ceremony**, and then `_dismiss()` (`:121-124`) hands off **nothing** — no auto-start, no pre-seed, no route. The user lands back on a home screen where the CTA to start the core loop sits at roughly **800-820px** into the scroll body against ~700-760px of usable height, bracketed by 1px dividers in the identical rhythm to the Quests and Daily-Rewards rows below it, so it reads as one item in a settings stack rather than the purpose of the screen. Once the day is complete it degrades to an **unfilled plain text row** with no container at all.

Two facts that make the fix cheap, and that are easy to miss:

- **`DailyLoopStep.checkin` is an empty slot.** It is the initial step and it has no UI — `muhasabah_screen.dart:388-389` falls through to a spinner because `discoverName()` is already running. There is a hole exactly where the question goes.
- **The answer already has a consumer.** `DailyLoopState.checkinAnswers` is already persisted (`:1431`) and restored (`:1466`), and `_deeperContextText` (`:1183-1203`) **already prefers it over the card blurb**. Writing one string into it before the prefetch makes the entire reflection be written about the stated problem, against the queue's Name, with **zero new AI plumbing**.

## 4. Why the 4-question check-in's removal is not evidence against asking

This matters because the obvious objection to this wave is "we tried questions and removed them."

**We did not remove them on evidence.** The finding that deleted `_CheckInStep` (`docs/qa/findings/2026-04-26-launch-overlay-dead-checkinstep.md`) is titled *"widget is unreachable"*, severity **"Low (code cleanup)"**. Its entire content is that `_advance()`'s else-branch dismissed instead of setting `_step = 2`, orphaning ~250 lines. No data, no A/B, no complaint, no product argument. The 267-line deletion rode along inside an unrelated commit about built-duʿā rollback (`9348d93`). The real product decision is three weeks earlier — `a4a5d2b`, *"skip questions, smart local gacha"* — whose stated rationale was replacing an AI round-trip with an **instant local card picker**. A latency and card-economy trade, not a verdict.

**And the external evidence says it would not have failed on length either.** JMIR 2021 mobile-EMA meta-analysis, 68 datasets, pooled compliance **81.9%**; by items per prompt: ≤5 → 82.8%, >5–9.5 → 78.6%, >9.5–26 → **84.0%**, >26 → 63.0%. Non-monotonic below 26 items — there is **no per-question drop-off in the range we care about**. What moves compliance is *frequency of asking* (1–3/day → 87.0% vs ≥4/day → 76.9–79.4%). Wrzus & Neubauer 2023 found the same independently.

So: reviving the *shape* is not repeating a known mistake. It is reviving a path abandoned by drift. **We are not reviving the *code*** — `answerCheckin()` stays scheduled for deletion (master plan `:662`), because its engine `getDailyResponse` returns a Name and nothing else, strictly weaker than `reflectWithOpenAI`.

What the old path plausibly *did* get wrong, and what we must not repeat: it was a **gate before the payoff**, it **changed nothing visible**, and it was **identical every day**. Those three are the design constraints below.

## 5. The five moves

### M1 — Reverse the day-open order

Streak and lantern become **ambient state** on open, not a modal ceremony. The question comes first. The reward ceremony lands **after** completion.

> **CORRECTED 2026-07-30 during Wave 4 groundwork — this section originally said "the reward ceremony *and the streak increment* land after completion", and that was wrong.** `_markStreakAndHandleMilestones()` is called from `discoverName()` (`daily_loop_provider.dart:957`), not from the ceremony — the sentence was written without checking where the streak actually lives. Applied literally it would mean **a user who answers, receives their Name, and then abandons before "Ameen" loses their streak day** — a far worse takeaway than the reward-ladder problem this section exists to solve, because the streak drives the lantern, the freezes, the milestones and the whole retention spine. **The streak increment does not move.** Only the *animated celebration* moves behind completion. The rule across this whole wave is one sentence: **grant at engagement, celebrate at completion.**

*Evidence:* the pattern is unanimous and we are currently inverted against all of it. Duolingo increments the streak in the **post-lesson** sequence. Finch's pet is energised *by* the completed check-in and then goes adventuring. Calm's mood check-in sits **after** the meditation — and still produced its measured lift, which is evidence a check-in need not be a gate to pay off. Glorify's tree waters after the devotional. **No verified comparable app gates the day's reward before the day's action.** We do.

*The one genuine pro-pre-reward finding is narrower than it looks.* Nunes & Drèze's endowed progress (19% → 34% redemption) licenses pre-granting **progress toward a goal not yet started, with a stated reason** — it does not license handing over the day's payoff before the day's work. Showing the streak *counter* on open is endowed progress. Spending the *ceremony* pre-work is not.

*Shape:* **streak state before (quiet, glanceable), ceremony after (loud, animated, once).**

This kills three of the four taps.

**Refinement that removes almost all the migration risk (founder, 2026-07-30).** Separate the *grant* from the *ceremony*: **claim the reward when the user submits their answer**, run the ceremony at "Ameen".

The reason this matters is the ladder. `claim_daily_reward` is a 7-day escalating ladder (5 / 10 / 15 tokens, streak freeze at day 4) and it resets hard:

```sql
if stored_last_claim is not null
    and stored_last_claim <> today_utc
    and stored_last_claim <> yesterday_utc then
  stored_day := 0;
```

Today, *opening the app* keeps that ladder alive. Move the claim all the way to "Ameen" and a user at day 6 who opens without time to tap through the whole reflection loses the ladder they would have kept — one missed claim resets to day 1. Claiming at answer-submit keeps the incentive pointed at the practice (you must show up **and** answer) without punishing someone for not finishing every beat.

**Nothing is removed from anyone's balance, and the streak is a separate system entirely** (`markActiveToday` / `logActivity`) — untouched by this re-timing.

`claimDailyReward()` stays idempotent and server-authoritative. It is already called from `daily_loop_provider.dart:1160` with a comment noting the launch overlay may have claimed first; moving the trigger changes *when*, never *who decides*.

### M2 — The question goes in `DailyLoopStep.checkin`, not in the overlay

Render it where the spinner currently is, on the sacred canvas, and defer `discoverName()` in `MuhasabahScreen.initState` (`:87-96`) until an answer arrives. The overlay's job shrinks to: *don't stop the user, hand off into `/muhasabah`*.

*Why not restore the overlay's dead third branch:* it would put the most important screen in the product inside a modal, and it would resurrect the exact code path a cleanup pass deleted. The `checkin` step is already the right host, already persisted, already reset cleanly by `resetToday()`.

*The escape hatch is not optional.* NN/g heuristic #3 — a clearly marked exit that does not require an extended dialogue. A returning user who opened the app to reread yesterday's Name must not have to declare a burden to get there. Of every app the external research could verify, **exactly one (Stoic) auto-opens into a check-in, and it ships an off switch.** Duolingo — the app most associated with compulsion — explicitly does not auto-enter; it removed doubt about which choice, not the choice.

*The transferable pattern, from Glorify:* **don't auto-enter the app; auto-advance the session.** Once the user taps in, everything after the first tap chains without a decision.

**Input shape — free text primary (founder direction, 2026-07-30).** The screen is Reflect-shaped: a text field as the primary input, with the 7 problem chips demoted underneath as quick-fill. This diverges from the external research, which found one-tap-first universal and free text always *after* a tap-selected state — recorded as a deliberate divergence, not an oversight, on two grounds:

1. **It is the reel promise literally.** Reflect already is *free text → `reflectWithOpenAI` → Name + verses + duʿā*; the daily loop becoming the same surface (plus card, streak, XP) is the whole point of the wave.
2. **Payers are depth users** — 3.0× reflections, 2.8× Reflect usage, near-identical check-in counts. The people who type are the people who pay. *Honest caveat: that is correlational. Depth users type; making people type does not demonstrably create depth users.* The chips underneath are the hedge for the day someone has nothing to write.

**No loss of segmentation.** `ProblemChipResolver.forFreeText` / `matchChipKeyForText` already keyword-map typed text to a chip key, so `problem_category` is derived on the typed path too and stays comparable with onboarding.

**Latency is genuinely reintroduced.** The April 2026 commit that removed the questions did it precisely to swap an AI round-trip for an instant local picker. Mitigation: the call runs *behind the card-reveal animation* — the user sees their card while the reflection is being written, never a spinner. The reveal is not allowed to block on the AI.

**Off-topic and empty input** reuse Reflect's existing handling (`reflect_provider.dart:774`), not a new branch.

#### Skip = defer, not dismiss (founder, 2026-07-30)

The exit is **"Not right now"**, and it leaves the entire loop live on home for the rest of the day. Tapping the promoted CTA re-enters the same flow from the top.

This is a better answer to the auto-entry problem than a bare close button, and it is the dominant external pattern rather than a divergence from it: Duolingo makes the next step unmissable and still leaves the tap to the user; Stoic auto-opens its check-in but ships an off switch; Finch lets you skip a goal and meets the skip without punishment. It also materially reduces the free-text friction risk — *"type, or come back to it whenever"* is a far smaller daily ask than *"type now."*

**Skip defers the reward too — it does not grant it.** Question, reveal and reward move as one unit.

*Why this and not "skip but still collect":* granting on skip rebuilds exactly the inversion §6 exists to correct. A user learns within two days that open → skip → collect → leave is the efficient path, and the daily reward is once again payment for launching the app — worse than today, because today they at least sit through the ceremony. Nothing is lost by deferring: the reward stays collectible all day by doing the muḥāsabah. A user only misses it by never doing the practice at all, which is already true today of a user who never opens the app.

**Skip writes the day marker.** Auto-entry happens **at most once per local day**; after a skip, the home CTA is the only entry. Without this, every app open that day re-throws the question, which is nagging — and nagging a user who already said "not right now" is the fastest way to make the exit feel fake.

**No new CTA state.** A deferred day *is* a not-started day, which the emerald filled button already renders. This only works because M5 promotes that button above the fold — a defer into a below-the-fold CTA is a defer into a dead end.

**Skip and abandon are different events** (§9). A skip says the *placement* was wrong for that moment; a close/back says the *question* was wrong. Conflating them leaves us unable to distinguish "people want this later" from "people don't want this."

**Copy:** *"Not right now."* Nothing guilt-shaped on the way out, and nothing on the way back in that references having skipped.

### M3 — The queue keeps picking the Name; the answer shapes the reflection

This is the reconciliation that lets this wave coexist with the seven-Name promise W3 just built, and it is nearly free.

- `_deeperRequestFor` (`:1169-1181`) already forces the revealed Name (`forceName = state.checkinName`).
- `_deeperContextText` already prefers `checkinAnswers` over the card blurb.
- `reflectWithOpenAI(userText, {forceName})` is the engine both paths already share.

**Net: write the answer into `state.checkinAnswers` before `_prefetchDeeperReflection()` and the reflection is written about the stated problem, against the queue's Name, with no new plumbing.**

**The split, recommended:** while the queue is live (D1–D7) the answer **shapes** the reflection and the queue picks the Name. Once the queue is exhausted, the answer may **pick** the Name outright via `ProblemChipResolver` — pure, offline, no AI. Letting the answer pick during the queue window would contradict the promise the last two waves were built to keep.

### M4 — The question is valence-neutral, and the good day is a first-class answer

**Never presuppose a burden.** *"What are you carrying today?"* is a great ad and a bad daily question, because on day 12 the honest answer is "nothing, alhamdulillah" and we have left no slot for it.

*Evidence:* How We Feel gives **two of four Mood Meter quadrants to pleasant states**; Daylio centres a 5-point scale on neutral; Finch tracks "what has been lifting you up or bringing you down". None of them ask what's wrong. The sharpest line in the whole corpus is a participant's: ***"I like recording what keeps me well, not what makes me ill. I'd much prefer… to think more positively."***

**And a good-day answer must produce genuinely different output.** If it returns the same consolation content as a grief answer, users learn inside a week that the question is decorative — the exact failure mode in the npj meta-synthesis (*"It's informative. It doesn't change my lifestyle."*).

For a faith app this is not a compromise. Gratitude and self-accounting are the same tradition, and muḥāsabah has always been two-sided. The 99 Names give a natural positive branch a mood tracker doesn't have.

**Vary the framing, not the schema.** Fatigue is a function of days and sameness (~15% decline in entries over 20 days; *"the same sort of questions every day so it's a little bit monotonous"*), not of item count. Rotate how the question is asked; keep what it collects stable.

#### The approved copy (founder, 2026-07-30)

> ### What's on your heart today?
> *placeholder:* `A worry, a thanks, a question — however it comes out.`

**Why this phrasing and not the alternatives we considered:**

- **"What's on your heart today?"** over *"How is your heart today?"* — the screen's primary input is a text field, and "how is" invites *"fine"* while "what's on" invites a sentence. Phrase the prompt for the answer you want typed.
- **Over *"What's weighing on you right now?"*** — this is the onboarding hook line and the strongest ICP resonance we have, and its continuity value is real (the user meets the same question at signup and on day 2). It was considered and set aside because it presupposes a burden **every single day**, which is the failure the evidence is most emphatic about. Keep it for the reels.
- **Over *"What are you bringing to Allah today?"*** — stronger deen-register and genuinely two-sided, but heavier; a daily prompt is worn every day and this one asks for a posture before it asks for a sentence.

**The placeholder is load-bearing, not decoration.** With chips, the answer set itself showed the user that gratitude was a legitimate answer. With free text there is nothing else doing that job — so without the placeholder the question silently means *"what's wrong."* Any copy change to the header must keep a placeholder that spans worry → thanks.

**This closes the good-day question (§7) without a separate branch.** The answer space carries the valence, so a grateful answer flows into the same engine and comes back with a Name and verses appropriate to it — `normalizeApprovedVerses` already covers the gratitude Names (Ash-Shakur, Al-Wahhab, Al-Kareem, Al-Basit, Ar-Razzaq). No new chip, no new mapping, no authored scripture.

**Rotation is deferred to W6, deliberately.** One fixed opener for v1, instrumented; rotate only once the funnel shows sameness actually costing us. Rotating on day one would mean we could never tell which framing performed.

### M5 — Home: promote the CTA, name it the job, cut what outranks it

- **Move the CTA above the fold** and out of the divider stack, so it stops reading as a sibling of Quests and Daily Rewards.
- **Stop rendering the question as an 11px subtitle.** If the loop now asks it, the home screen shouldn't whisper it.
- **Rename it.** Drop *"Begin Muḥāsabah"* as the CTA label; make the CTA the job to be done. Keep **muḥāsabah** as the taught word, introduced as a gloss — which is exactly how Hallow handles Lectio Divina and the Examen: *jargon names the content item, never the primary daily CTA; every unfamiliar term earns a one-line plain-language gloss stating the benefit, not the etymology.* Hallow's own home entry point is the plainest word in the product — "Routine". The button should sound like the reel; the word should teach rather than gate.
- **Cut what sits above it.** A free user currently meets up to five self-collapsing promo cards (of which `HomePremiumStrip` is unconditional), a six-element stats row, an XP bar, a 152px lantern, a streak line, a 60px Arabic Name and a teaching paragraph — all before reaching the purpose of the app. The fully-completed state also needs a real design; today it is an unstyled text row.

**Note the honest framing of this move:** the CTA is, in saturation terms, the loudest pixel on the page — it is the only *filled* button on the screen. This is a **prominence and rhythm** problem, not a colour problem. Making it bigger and greener is not the fix; moving it above the fold and breaking it out of the settings-stack rhythm is.

## 6. DECISION 1 — where the daily reward ceremony lands — **CLOSED**

**Decided 2026-07-30: ceremony after the work, reward *claimed* at answer-submit.**

M1 carries the reasoning and the ladder-reset detail. In short: the animated ceremony and the streak increment land after "Ameen", but `claimDailyReward()` fires the moment the user submits their answer, so nobody loses the escalating reward ladder for failing to tap through every beat of a reflection. Nothing leaves anyone's balance; the streak system is untouched.

*Options B (claim on open, animate at the end) and C (leave it entirely) were considered and rejected — B keeps the token grant pointed at opening the app rather than practising, and C declines the move rather than staging it.*

## 7. DECISION 2 — what the good-day answer returns — **CLOSED**

**Decided 2026-07-30: the question is generic and the answer space carries the good day. No separate gratitude branch, no new chip, no new mapping.** See the approved copy under M4 — the placeholder (*"A worry, a thanks, a question"*) is what makes a grateful answer a first-class one.

The findings that made this cheap are worth keeping, because I got them wrong first. On 2026-07-29 I called the positive branch "the one part with a real content cost rather than a code cost." **That was wrong:**

- Scripture on the reflection path is **not** AI-generated. `normalizeApprovedVerses` (`reflection_verse_catalog.dart:1138-1163`) drops anything the model returns that isn't in the approved catalog, then falls back to approved-verses-for-Name. The AI selects; it never authors.
- **The catalog already covers the gratitude Names** — Ash-Shakur, Al-Wahhab, Al-Kareem, Al-Basit, Ar-Razzaq all have approved verses.
- Decks are **optional** on the daily path. W3 already drops an undrawable deck and falls through to the AI beat path, so a Name without an authored deck renders fine.

Because free text (not a chip set) is the primary input, the gratitude case needs **no branch at all** — the user's own words go to the same engine, and the approved-verse floor covers where it lands. What the placeholder buys is that they know a grateful sentence is a permitted answer.

**Note for anyone reopening this:** a *gratitude chip on the onboarding hook screen* would be a different question and would still need the W7 ship-gate (two verified decks per rendered chip). This wave adds nothing to that screen — it is the daily loop only, where one Name is revealed and no pair is required.

## 8a. Scope — this ships to everyone, not just the new cohort

**Decided 2026-07-30.** W1–W3 are cohort-scoped because they change what a *new signup* is promised. This wave changes how the daily loop works for anyone who opens the app, and the leak it targets — 31% D0→D1 — is not exclusive to new signups.

The argument for gating it was the reward re-timing reading as a takeaway to the ~1,343 existing users. **Claiming at answer-submit (§6) removes that**: the change becomes "answer the question to collect", which is a fair exchange rather than a loss, and the ladder survives.

*The cost, recorded:* shipping to all users means the pre/post keep read now spans a population that also changed mid-window. Given D9 already accepted coarse attribution for this ship, this does not make the read materially worse — but it is a second reason the within-wave funnel (§9) has to stand on its own.

*What stays cohort-scoped regardless:* Name **selection**. Queue-cohort users get the queue's Name (forced); legacy users are `QueueAbsent` and keep the existing `pickNextCard` pull. Both get the question, and for both the answer shapes the reflection.

## 8. The single most dangerous edit

**`markUsed` currently fires at the CTA, before navigation.** `progress_screen.dart:988-1001` calls `GatingService().canUse(discoverName)` and then `markUsed` at the tap, deliberately — the comment says so.

Put a question between the tap and the reveal and **anyone who opens the prompt and backs out has burned their one free reveal for the day.**

Fixing it means moving `markUsed` into `discoverName()`, which drags in both bypass wrappers (`discoverNameWithBypass` `:763-788`, `discoverNameWithFirstBypass` `:795-821`) and the refund invariant where `state.error` decides commit-versus-cancel. Pinned by `discover_name_dispose_cancel_test.dart`.

**This is a prerequisite, not a follow-up.** It lands first, on its own, with its own tests, before any question UI exists.

*Softening note, so this isn't over-weighted:* `GatingService.warmupBudget[discoverName] = 5`, so a fresh free user's first four discovers never touch the daily counter at all. The exposure is real but it is not day-one for new users — it bites returning users past warmup.

## 9. Analytics

**Do not fork `check_in_completed`.** It is the recurring core-loop DAU event and the D1/D7 retention spine. Changing `path` from `'discover'` (to `'feeling'`, as the original Phase-2 prescription proposed) breaks every historical comparison. Per `CLAUDE.md`, this is ONE funnel segmented by super properties.

- **Add** `problem_category` as a *property* on the existing event. Never touch `path`.
- W3's Wave 5 is also about to add `name_source` / `queue_position` to the same event — coordinate or accept a trivial merge.
- **New funnel, and it has to be clean** (see §2): `daily_question_shown` → `daily_question_answered{problem_category}` → the existing completion event. Because cohort-level attribution is coarse this ship, this within-wave funnel is how we find out whether the question itself is carrying its weight.
- Reuse the chip taxonomy, **not** the 30-question option bank. The bank is a different vocabulary (emotions, avoidances, needs) that doesn't map onto `problem_category`; reusing it would fork segmentation away from `acquisition_promise.problem_category` and make the daily loop incomparable to onboarding.

## 9a. Every surface this touches

The audit covered the daily loop; this is the sweep for everything *else* that reads or writes the same state. Three of these are bugs you would only find on device.

**The home-screen widget — no entry changes needed, three consequences.** `parseWidgetDeepLink` (`widget_deep_link.dart:22-31`) maps a tap to `.go('/muhasabah')`, and the handler's own comment records that a widget tap **deliberately takes precedence over the launch overlay**. Because the question renders on the muḥāsabah screen and not inside the overlay, a widget tap lands *in the question* for free.

1. **The reward must be claimed from the loop, not the overlay.** The overlay owns the claim today. A widget user never sees the overlay — so unless the claim hangs off answer-submit, they complete the whole muḥāsabah and collect nothing. This makes the widget path *better* than today's.
2. **The launch-gate marker must be set on completion too.** `sakina_launch_gate` is written by the overlay path (`launch_gate_state.dart:24-29`). Enter by widget, finish the loop, open the app normally an hour later → `shouldShowDailyLaunch()` is still true and the day-open fires again on a day already done.
3. **The widget shows a Name before the user has earned one.** `syncHomeWidget` (`widget_sync.dart:111-130`) passes `todaysName: getTodaysName()` — a deterministic date rotation — and `personalized: false` until check-in. So there are **three different "today's Name"** in the product: the widget's rotation, the launch overlay's separate rotation (`daily_launch_overlay.dart:213-218`), and the actual queue/gacha reveal. They do not agree. Harmless today; corrosive once the reveal is a ceremony the user earns by answering. **Fix in this wave:** pre-check-in, the widget shows lantern + streak and withholds the Name (or shows the queue's real next Name) rather than advertising one we won't deliver.

**The launch overlay** (`daily_launch_overlay.dart`) loses its reward step from the front and keeps only ambient streak state, or disappears from the open path entirely. Its route name is load-bearing — `TourRouteObserver:29` treats `'DailyLaunchOverlay'` as blocking — so whatever survives must not trap a user who came in for duʿā times.

**`progress_screen.dart`** gives up the `canUse`/`markUsed` pair at the CTA (§8), the 11px question subtitle (`_buildMuhasabahPromptLabel`), and the CTA's position in the divider stack. Its `_discoverInFlight` re-entry guard must survive the refactor — it exists because a double-tap previously passed the gate twice.

**`reflect_screen.dart` and the sealed-Name offer.** Reflect and the daily loop become nearly the same surface (free text → `reflectWithOpenAI` → Name). The distinction is now *once-a-day-and-awards-a-card* versus *gated-but-repeatable*. W3's carried `sealed_name_offer.dart` — the Reflect epilogue pointing at the sealed Name — still makes sense, but its copy should be re-read once the daily loop also asks.

**Notifications.** Templates are frozen at `reel_v1` until the keep read, and Phase B (queue-based "a Name for what you're carrying") is post-ship. **This wave adds no notification copy.** Worth stating explicitly because a daily question is exactly the kind of thing that invites a "you haven't answered today" nudge — which would be a guilt mechanic and trips the copy firewall.

**Live Activities / duʿā-times widget** — unaffected. A Live Activity `Link` is delivered straight to GoRouter, not through the widget-click stream, so it does not pass this path at all.

**`app_config` dials.** The question surface needs a kill switch consistent with the rest of the ship — one key that reverts the daily loop to the current no-question `discoverName` path, verified on device before submission.

## 10. Deliberately out of scope

- **No mood graph, ever.** In **11 of 11** relevant studies participants reported the monitoring itself confronted them with a worsening mood; reviewers warn daily mood monitoring without an attached therapeutic component *"might have either no effect or even make depression worse."* Our protection is structural and already built: the answer is met with a Name, verses and a duʿā — **a response, not a chart**. Adding a trend line would throw that away. This is a safety rule, not a scope call.
- ~~**No free-text as the first ask.**~~ **[REVERSED 2026-07-30 — founder direction. Free text IS the primary input; see M2. The research finding it contradicts is real and is recorded there as a deliberate divergence, with the chips retained underneath as the low-effort floor.]**
- **No reviving `answerCheckin()`** — its deletion proceeds as scheduled.
- **No auto-entry without a marked exit** (§M2).
- **The daily problem→Name match stays free forever** (master plan `:522`), and `discoverName` keeps its permanent 1/day free cap for all users (§V6.8.B3). Paywalling the daily reveal would kill the streak engine. W5's tightening must not reach this path.

## 11. Cost

**~3–6 days** for M1–M3 + M5, on the audit's estimate, which I believe: the state machine is the cheap part (`checkin` is an empty slot, `checkinAnswers` is already persisted and already preferred by the AI-context builder, `resetToday()` already wipes cleanly). M4's positive branch adds roughly half a day now that the verse-catalog question is settled. The `markUsed` move in §8 is the schedule risk — small in lines, large in blast radius.

**Merge-conflict warning:** W3's Waves 4–5 are unbuilt and also edit `daily_loop_provider.dart`. A question insertion is a fourth writer on the same function. Either land the carried W3 items first or accept the merge.

## 12. Decision log

| | Decision | Resolved |
|---|---|---|
| Sequencing | Restructure becomes W4; gate + free tier slides to W5 | 2026-07-30, master-plan D9 |
| §6 | Ceremony after the work; reward **claimed at answer-submit** so the escalating ladder survives a half-finished session | 2026-07-30 |
| §7 | One generic question; the answer space carries the good day; no separate gratitude branch | 2026-07-30 |
| M2 | **Free text primary**, chips demoted to quick-fill — a deliberate divergence from the one-tap-first research | 2026-07-30 |
| M4 copy | *"What's on your heart today?"* + a placeholder spanning worry → thanks | 2026-07-30 |
| §8a | Ships to **all users**, not cohort-gated. Name *selection* stays cohort-scoped | 2026-07-30 |
| Skip | **"Not right now" defers the whole loop** — question, reveal *and* reward — to the home CTA for the rest of the day. Skip writes the day marker (auto-entry at most once/day). Skip does **not** grant the reward | 2026-07-30 |
| Rotation | One fixed opener for v1; rotate in W6 only if the funnel shows sameness costing us | 2026-07-30 |

**Nothing is blocking.** Remaining judgement calls are build-time and mine to make unless they turn out to be product questions in disguise — in which case they come back here.
