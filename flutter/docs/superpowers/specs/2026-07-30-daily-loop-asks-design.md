# W4 — The daily loop asks

**Status: SPEC — sequencing approved by the founder 2026-07-30 (this becomes W4; gate + free tier slides to W5). Two decisions still open and marked as such: §6 (where the reward ceremony lands) and §7 (the good-day answer). Everything else below is settled enough to build.**
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

Streak and lantern become **ambient state** on open, not a modal ceremony. The question comes first. The reward ceremony and the streak increment land **after** completion.

*Evidence:* the pattern is unanimous and we are currently inverted against all of it. Duolingo increments the streak in the **post-lesson** sequence. Finch's pet is energised *by* the completed check-in and then goes adventuring. Calm's mood check-in sits **after** the meditation — and still produced its measured lift, which is evidence a check-in need not be a gate to pay off. Glorify's tree waters after the devotional. **No verified comparable app gates the day's reward before the day's action.** We do.

*The one genuine pro-pre-reward finding is narrower than it looks.* Nunes & Drèze's endowed progress (19% → 34% redemption) licenses pre-granting **progress toward a goal not yet started, with a stated reason** — it does not license handing over the day's payoff before the day's work. Showing the streak *counter* on open is endowed progress. Spending the *ceremony* pre-work is not.

*Shape:* **streak state before (quiet, glanceable), ceremony after (loud, animated, once).*

This kills three of the four taps.

### M2 — The question goes in `DailyLoopStep.checkin`, not in the overlay

Render it where the spinner currently is, on the sacred canvas, and defer `discoverName()` in `MuhasabahScreen.initState` (`:87-96`) until an answer arrives. The overlay's job shrinks to: *don't stop the user, hand off into `/muhasabah`*.

*Why not restore the overlay's dead third branch:* it would put the most important screen in the product inside a modal, and it would resurrect the exact code path a cleanup pass deleted. The `checkin` step is already the right host, already persisted, already reset cleanly by `resetToday()`.

*The escape hatch is not optional.* NN/g heuristic #3 — a clearly marked exit that does not require an extended dialogue. A returning user who opened the app to reread yesterday's Name must not have to declare a burden to get there. Of every app the external research could verify, **exactly one (Stoic) auto-opens into a check-in, and it ships an off switch.** Duolingo — the app most associated with compulsion — explicitly does not auto-enter; it removed doubt about which choice, not the choice.

*The transferable pattern, from Glorify:* **don't auto-enter the app; auto-advance the session.** Once the user taps in, everything after the first tap chains without a decision.

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

### M5 — Home: promote the CTA, name it the job, cut what outranks it

- **Move the CTA above the fold** and out of the divider stack, so it stops reading as a sibling of Quests and Daily Rewards.
- **Stop rendering the question as an 11px subtitle.** If the loop now asks it, the home screen shouldn't whisper it.
- **Rename it.** Drop *"Begin Muḥāsabah"* as the CTA label; make the CTA the job to be done. Keep **muḥāsabah** as the taught word, introduced as a gloss — which is exactly how Hallow handles Lectio Divina and the Examen: *jargon names the content item, never the primary daily CTA; every unfamiliar term earns a one-line plain-language gloss stating the benefit, not the etymology.* Hallow's own home entry point is the plainest word in the product — "Routine". The button should sound like the reel; the word should teach rather than gate.
- **Cut what sits above it.** A free user currently meets up to five self-collapsing promo cards (of which `HomePremiumStrip` is unconditional), a six-element stats row, an XP bar, a 152px lantern, a streak line, a 60px Arabic Name and a teaching paragraph — all before reaching the purpose of the app. The fully-completed state also needs a real design; today it is an unstyled text row.

**Note the honest framing of this move:** the CTA is, in saturation terms, the loudest pixel on the page — it is the only *filled* button on the screen. This is a **prominence and rhythm** problem, not a colour problem. Making it bigger and greener is not the fix; moving it above the fold and breaking it out of the settings-stack rhythm is.

## 6. DECISION 1 — where the daily reward ceremony lands

**Open. Founder's call.** M1 says the ceremony belongs after the work; the question is what happens to the *reward economy* when it moves.

| | Option | What it costs |
|---|---|---|
| **A** *(recommended)* | Ceremony + streak increment fire after the muḥāsabah completes. Streak counter still visible, quiet, on open. | A user who opens and doesn't finish doesn't collect that session. Correct incentive, and it is what every comparable app does — but it can read as a takeaway to a user who is used to collecting on open. |
| **B** | Reward claim stays on open; only the *animated* ceremony moves after completion. | No economy change at all, and the visible celebration still lands on real work. But the daily reward — the thing with actual token value — is still granted for opening the app, so the incentive stays pointed at opening rather than practising. |
| **C** | Reward stays exactly as-is; this wave only changes routing and the question. | Zero economy risk, smallest diff. Leaves the inversion in place — we would still spend the day's celebration on an act that hasn't happened. |

**Recommendation: A**, with the ambient streak counter on open so nothing feels *removed*, only re-timed. If A reads as too aggressive, B is a coherent halfway house; C is not — it declines the move rather than staging it.

**Whatever we pick, `claim_daily_reward()` stays idempotent and server-authoritative.** Moving *when* we call it must not move *who decides* it.

## 7. DECISION 2 — what the good-day answer actually returns

**Open. Founder's call.** And it is cheaper than I told you on 2026-07-29 — I said the positive branch was "the one part with a real content cost rather than a code cost." **That was wrong, and the correction is worth having in writing:**

- Scripture on the reflection path is **not** AI-generated. `normalizeApprovedVerses` (`reflection_verse_catalog.dart:1138-1163`) drops anything the model returns that isn't in the approved catalog, then falls back to approved-verses-for-Name. The AI selects; it never authors.
- **The catalog already covers the gratitude Names** — Ash-Shakur, Al-Wahhab, Al-Kareem, Al-Basit, Ar-Razzaq all have approved verses.
- Decks are **optional** on the daily path. W3 already drops an undrawable deck and falls through to the AI beat path, so a Name without an authored deck renders fine.

So the positive branch needs **a chip, a keyword bucket, and a Name mapping** — not newly authored scripture. The remaining question is what it *returns*:

| | Option | Trade |
|---|---|---|
| **A** *(recommended)* | A real gratitude branch: the good-day answer routes to Names of shukr / provision / bestowal, with approved verses that already exist. | ~1 new chip + a `ProblemChipResolver` bucket + Name mapping. Makes the question honestly two-sided on day one. |
| **B** | The good-day answer skips the reframe and goes straight to the day's Name unadorned — "nothing heavy today" gets the Name without consolation framing. | Zero new mapping. But it risks reading as *the answer didn't matter*, which is the decorative-question failure the research is most emphatic about. |
| **C** | Ship problem-only now, add the positive branch in W6. | Smallest wave. Also means shipping a loop that asks what's wrong every single day — the thing the evidence says teaches users to lie to us. |

**Recommendation: A.** The cost collapsed once the verse catalog was checked, and it is the difference between a question and an interrogation.

**Constraint that binds all three:** authored decks for gratitude Names would still need the W7 ship-gate (two verified decks per rendered chip) *if* a gratitude chip ever appears on the **onboarding hook screen**. It is not appearing there in this wave — this is the daily loop only, where a single Name is revealed and no pair is required.

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

## 10. Deliberately out of scope

- **No mood graph, ever.** In **11 of 11** relevant studies participants reported the monitoring itself confronted them with a worsening mood; reviewers warn daily mood monitoring without an attached therapeutic component *"might have either no effect or even make depression worse."* Our protection is structural and already built: the answer is met with a Name, verses and a duʿā — **a response, not a chart**. Adding a trend line would throw that away. This is a safety rule, not a scope call.
- **No free-text as the first ask.** Universally one-tap first across every verified app; text is offered after a tap-selected state. The hook screen's demoted-free-text pattern is the precedent to copy.
- **No reviving `answerCheckin()`** — its deletion proceeds as scheduled.
- **No auto-entry without a marked exit** (§M2).
- **The daily problem→Name match stays free forever** (master plan `:522`), and `discoverName` keeps its permanent 1/day free cap for all users (§V6.8.B3). Paywalling the daily reveal would kill the streak engine. W5's tightening must not reach this path.

## 11. Cost

**~3–6 days** for M1–M3 + M5, on the audit's estimate, which I believe: the state machine is the cheap part (`checkin` is an empty slot, `checkinAnswers` is already persisted and already preferred by the AI-context builder, `resetToday()` already wipes cleanly). M4's positive branch adds roughly half a day now that the verse-catalog question is settled. The `markUsed` move in §8 is the schedule risk — small in lines, large in blast radius.

**Merge-conflict warning:** W3's Waves 4–5 are unbuilt and also edit `daily_loop_provider.dart`. A question insertion is a fourth writer on the same function. Either land the carried W3 items first or accept the merge.

## 12. Open questions for the founder

1. **§6** — where does the daily reward ceremony land? (recommend A)
2. **§7** — what does the good-day answer return? (recommend A)
3. **Question rotation** — M4 says vary the framing, not the schema. Do we rotate copy across a small approved set, or keep one fixed neutral opener for v1 and rotate in W6? (I lean: one fixed opener now, instrument it, rotate once we can see whether sameness is actually costing us.)
