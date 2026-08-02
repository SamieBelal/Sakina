# Daily-loop audit vs the reel/ICP promise

> **Provenance.** Commissioned 2026-07-29 when the founder asked why the daily loop is
> neither noticeable nor retentive. Paired with
> [`2026-07-29-day-open-loops-external-research.md`](./2026-07-29-day-open-loops-external-research.md)
> (what comparable apps do). Together they are the evidence base for
> [`../superpowers/specs/2026-07-30-daily-loop-asks-design.md`](../superpowers/specs/2026-07-30-daily-loop-asks-design.md).
> Line numbers are accurate as of HEAD `9b0f0a0` and will drift — treat them as
> pointers, not contracts.

Read-only audit of `/Users/appleuser/CS Work/Repos/sakina-reel-first/flutter` on branch
`feat/reel-first-w2-onboarding` (HEAD `9b0f0a0`), 2026-07-29. All paths below are relative to
that worktree root unless noted. Three docs (`2026-04-26-*` findings and
`docs/analytics/2026-07-14-conversion-diagnosis-and-research.md`) exist only as untracked files
in `/Users/appleuser/CS Work/Repos/sakina/flutter` and were read there — read-only, nothing
touched.

---

## 1. The exact current day-open sequence

**Step 0 — launch → router → home.** There is no dedicated home route object; `/` mounts
`ProgressScreen` inside the bottom-nav `ShellRoute` (`lib/core/router.dart:313-322`). The
bottom-nav order is Home · Collection · Reflect · Duas · Journal
(`lib/widgets/app_shell.dart:410-457`). Nothing in the router special-cases first-launch-of-day
— the day gate lives entirely in `ProgressScreen`.

**Step 1 — `ProgressScreen.initState`** (`lib/features/progress/screens/progress_screen.dart:142-153`)
fires four things: `_checkDiscoveryQuiz()`, `_maybeShowLapsedTrialSheet()`,
`_maybeShowCancellationFeedback()`, and `unawaited(_maybeShowDailyLaunch())`. The comment at
`:148-151` records that the guided tour used to be chained onto the launch-overlay dismissal and
was deleted 2026-07-28 ("it cost ~48% of signups").

**Step 2 — the loading gate.** Until `_launchGateReady` flips true, `ProgressScreen` renders
*only* a centred `SakinaLoader` (`:336-350`) — the home content never flashes behind the overlay.

**Step 3 — "first launch of the day" determination.** `shouldShowDailyLaunch()`
(`lib/services/launch_gate_service.dart:24-46`):
1. `launchGateOverlayPushedThisSession` → false (in-memory session guard,
   `lib/services/launch_gate_state.dart:12,31`).
2. Best-effort `reconcileDailyRewardsFromServer()` so admin/QA resets and multi-device claims
   re-trigger correctly.
3. Compares the scoped SharedPref marker `sakina_launch_gate` against **UTC** today
   (`launch_gate_state.dart:24-29,42-47`). UTC, not local — deliberate, so the marker agrees
   with `daily_rewards_service._today()` and the `claim_daily_reward` SQL RPC; the dartdoc at
   `launch_gate_state.dart:14-22` records the near-midnight bug that forced it.
4. Fresh-install fallback: marker absent but server says `claimedToday` → persist marker,
   return false (suppresses a repeat "Reward Claimed!" screen after delete+reinstall same day).

**Step 4 — the overlay push.** `_maybeShowDailyLaunch()` (`progress_screen.dart:217-249`) defers
to a post-frame callback and pushes an **opaque root-navigator** `PageRouteBuilder` named
`'DailyLaunchOverlay'` (`:234-245`). The route name is load-bearing: `TourRouteObserver`
(`lib/features/tour/providers/tour_route_observer.dart:29`) treats it as a blocking route.

**Step 5 — what the overlay actually renders.** `lib/features/daily/screens/daily_launch_overlay.dart`
is a two-step `AnimatedSwitcher` (`:160-173`):

- **Step 0 `_StreakGreetingStep`** (`:184-338`): a 96px `CompanionMedallion` (the lantern, with
  the equipped skin, `:229-240`); "**N** \n day streak" in 48px amber (`:244-265`); a
  time-of-day greeting (`:269-275`, `_timeGreeting()` at `:332-337`); a gold-bordered card
  labelled **"Your Starting Name"** (streak 0) or **"Today's Name"** carrying 36px Arabic +
  `transliteration — english` (`:280-318`); CTA **"Begin"** (`:323-326`).
  Note: on streak ≥ 1 that Name is `getTodaysName()` — a pure **date rotation**
  (`:213-218`), unrelated to the muḥāsabah Name the user is about to reveal and unrelated to the
  W3 queue. On streak 0 it is the onboarding starter Name via `starterNameProvider`.
- **Step 1 `_RewardClaimStep`** (`:344-433`): blocks on a `SakinaLoader` until the rewards
  provider reconciles (`:370-372`, guarding the 2026-05-12 stale-Day-N bug); then a 7-day
  reward strip (`_RewardStrip`, `:435-524`), today's reward highlight, **"Claim Reward"** →
  `_ClaimSuccess` + **"Continue"**.
- **Step 2 is dead.** `switch (_step)` has a `_ => const SizedBox.shrink(key: ValueKey(2))`
  fall-through (`:172`) and `_step` is never set to 2. `_advance()` (`:107-119`) reads:

  ```dart
  if (_step == 0 && _rewardClaimed) { _dismiss(); }
  else if (_step == 0) { setState(() => _step = 1); }
  else { /* After reward claim — dismiss overlay (Muhasabah is on its own screen now) */ _dismiss(); }
  ```

  The `_step == 0` field comment at `:35` still says "0 = streak greeting, 1 = reward claim,
  2 = check-in" — a fossil of the removed questionnaire.

**Step 6 — hand-off.** `_dismiss()` is `Navigator.of(context).pop()` (`:121-124`). The overlay
hands off **nothing**: it does not start, pre-seed, or route into the muḥāsabah. The user lands
back on `ProgressScreen` with no auto-start of any kind.

**Where the user physically lands and what's on it:** the home tab (`ProgressScreen`), scrolled
to top, with the content enumerated in §2.

**Tap count, app-open → core loop started (returning free user, reward unclaimed):**

| # | tap | file:line |
|---|---|---|
| 1 | "Begin" (streak greeting) | `daily_launch_overlay.dart:323` |
| 2 | "Claim Reward" | `:414` |
| 3 | "Continue" | `:425` |
| 4 | "Begin Muhāsabah" on home | `progress_screen.dart:1048-1051` |

**Four taps**, three of which are pure ceremony. If the reward was already claimed elsewhere
today, tap 1 dismisses straight to home → **two taps**. `discoverName()` only fires from
`MuhasabahScreen.initState` (`muhasabah_screen.dart:87-96`), i.e. after tap 4.

---

## 2. The home screen's real information hierarchy

`progress_screen.dart` is 1483 lines. Structure: `build()` at `:311`, a `SingleChildScrollView`
with `AppSpacing.pagePadding = 24` (`app_spacing.dart`) wrapping a `Column` (`:355-407`), plus
one big `_buildDashboardCard` (`:478-901`).

**Vertical order as a returning free user sees it** (approximate cumulative offset from the top
of the scroll body; estimated from constants, not measured on device — treat ±15%):

| order | element | file:line | ~height | ~top edge |
|---|---|---|---|---|
| 1 | Greeting row: "Assalamu Alaykum!" (`displayLarge`) + Store circle + Settings gear | `:361`, `_buildGreetingRow` `:416-472` | ~40 | 24 |
| 2 | `RamadanGiftCard` | `:367` | **0** outside `islamic_occasions` windows | — |
| 3 | `DuaTimesCard` | `:375` | **0** unless a duʿā window is active/imminent | — |
| 4 | `ReferralNudgeCard` | `:383` | **0** unless active RC subscriber pre-first-grant | — |
| 5 | `WidgetInstallNudgeCard` | `:389` | ~86 once the user has a streak, until dismissed | ~96 |
| 6 | `HomePremiumStrip` "Try Sakina Premium →" | `:395` | ~80 — **always present for free users** (`home_premium_strip.dart:28-36`) | ~182 |
| 7 | Dashboard card opens (20px padding) | `:398`, `:521-535` | — | ~262 |
| 7a | Stats row: rank avatar + "Lv N" pill + title + streak pill + token pill + scroll pill (6 elements) | `:539-687` | 36 | ~282 |
| 7b | `AnimatedXpBar` (3px) | `:690-694` | 9 | ~318 |
| 7c | divider | `:713` | 31 | ~327 |
| 7d | `FreezeBurnCard` | `:699-710` | **0** unless a pending freeze burn | — |
| 7e | **`CompanionMedallion` — fixed 152px lantern slot**, tappable → `/companion` | `:720-739` | 152 | ~358 |
| 7f | `buildStreakLine` (merged streak + milestone bar, tap → month-of-light sheet) | `:748-758` | ~32 | ~518 |
| 7g | Gold eyebrow label ("TODAY'S NAME" / "YOUR STARTING NAME") | `:764-771` | ~48 | ~550 |
| 7h | **Arabic Name at fontSize 60** (`AdjustedArabicDisplay`) | `:773-779` | ~105 | ~598 |
| 7i | `transliteration — english` | `:781-787` | ~42 | ~703 |
| 7j | `hero.lesson` (teaching paragraph, ~2 lines) | `:789-796` | ~42 | ~745 |
| 7k | divider | `:800` | 31 | ~787 |
| **7l** | **`_buildMuhasabahRow` — the core-loop CTA** | `:802`, `_buildMuhasabahRow` `:951-967`, inner `:969-1093` | ~48 | **~818** |
| 7m | divider + **Quests** row | `:805-844` | ~75 | ~866 |
| 7n | divider + **Discover Your Anchor Names** row (if quiz undone) | `:847-888` | ~75 | ~941 |
| 7o | divider + **Daily Rewards calendar** | `:891-894`, `_buildRewardCalendar` `:1108` | large | ~1016 |

The muḥāsabah CTA's top edge lands at roughly **800-820px** below the top of the scroll body,
plus the safe-area inset. Usable height above the bottom nav on a modern iPhone is ~700-760px.
**Conclusion: the CTA to start the core loop is below the fold on essentially every device — it
requires a scroll of roughly 100-250px to reach.** I could not verify this on a simulator
(read-only constraint), so treat the number as an estimate; the ordering itself is exact.

### Is it "just the green line"? — precise verdict

**Partly right, and right about the thing that matters.**

*Where the founder is imprecise:* in the not-yet-started state the CTA is **not** a hairline. It
is the only *filled* button on the entire home screen — a full-width `AppColors.primary`
(#1B6B4A deep emerald) container, 12px radius, 12px vertical padding, with a white
`play_circle_outline_rounded` icon, white 600-weight "**Begin Muhāsabah**" (or "Continue
Muhāsabah" when in progress), a subtitle, and a chevron (`:1053-1091`). In pure saturation terms
it is the loudest pixel on the page.

*Where the founder is right:*
1. **Mass.** ~48px of emerald against a 152px animated lantern and a 60px Arabic Name directly
   above it. The eye lands on the lantern and the Name; the CTA is a footnote to them.
2. **Framing.** It sits between two 1px dividers (`:800`, `:806`) in an identical rhythm to the
   Quests row, the Anchor-Names row and the Daily-Rewards row below it. Structurally it reads as
   **one list item in a settings-like stack**, not as the purpose of the screen.
3. **Position.** Below the fold (above).
4. **After completion it literally becomes a line.** Once `state.currentStep ==
   DailyLoopStep.completed`, `_buildMuhasabahRowInner` takes the first branch (`:975-1044`) and
   renders an **unfilled plain text row** — "Discover a New Name" + an 11px tertiary subtitle,
   no container, no fill, indistinguishable from Quests. If the founder was looking at the
   screen after having checked in, "just the green line" is a generous description.

### Is it "clutter"? — verdict: yes

Between the greeting and the CTA a free user can meet up to five self-collapsing promotional
cards (`:367`, `:375`, `:383`, `:389`, `:395`), of which the premium strip is *unconditional*
for free users, plus a six-element gamification stats row, an XP bar, a lantern, a streak line,
a Name hero, and a teaching paragraph. Below the CTA, three sibling rows compete with it. The
CTA has no visual priority claim over any of them.

### The sharpest irony

`_buildMuhasabahPromptLabel` (`:1095-1102`) already renders **today's question** as the CTA's
subtitle: `'Today: ${state.todaysQuestion.question}'` — e.g. *"Today: What is weighing on you
most right now?"* — in 11px `textTertiaryLight` (or 70%-alpha white on the emerald fill). So the
app already **displays** the ICP question on the home screen, at the smallest type size on the
screen, and tapping it does not ask it. The fallback when no question resolves is the generic
`'Daily spiritual check-in'` (`:1098`).

---

## 3. The core loop itself

**Route.** `/muhasabah` → `MuhasabahScreen` (`lib/features/daily/screens/muhasabah_screen.dart`,
747 lines). `initState` (`:83-96`) does a single post-frame `discoverName()` call, guarded on
`!state.checkinDone && !state.checkinLoading`. The comment at `:85-91` records that this is the
*only* implicit trigger and that keeping side effects in `ref.listen` rather than `build` is what
closed the "phantom second gacha on Return to Home" bug class.

**`discoverName()`** (`lib/features/daily/providers/daily_loop_provider.dart:592-742`). Confirmed:

- **It asks the user nothing.** Its own dartdoc (`:585-586`): *"Picks today's Name and engages
  it. No AI call, no questions."*
- **Name selection**, post-W3-Wave-2: resolves queue rows (`_resolveQueueRows` `:559-571`,
  server + `name_queue_cache` fallback), resolves the user's local day
  (`resolveUserLocalDay` `:605`), runs the pure planner `planQueueReveal` (`:606-612`), and
  switches on the five outcomes (`:621-640`): `QueueUnseal` → `unsealNext()` RPC;
  `QueueResume` → re-present the already-consumed row; `QueueHold` / `QueueExhausted` /
  `QueueAbsent` → `queueRow = null`. Fallback is `pickNextCard(collection, maxTier:,
  exclude: sealedQueueNameIds(queueRows))` (`:658-664`) — the original
  undiscovered/lowest-tier card-collection pick. Every legacy user is `QueueAbsent` and their
  pull is bit-identical to before.
- **Reveal.** `engageCard(card.id, maxTier:, floorTier: queueDriven ? 2 : 1)` (`:665-672`) —
  the §8 dignity floor lands queue-driven first discoveries at Silver. `tierChanged` →
  `cardEngageResult` (drives `CardRevealOverlay`); `isDuplicate` → 1 bonus token instead
  (`:674-681`).
- **Then it prefetches the deeper reflection** (`_prefetchDeeperReflection()` `:700`) and offers
  "Go Deeper" into `BeatRevealFlow` (`muhasabah_screen.dart:196-210`, canvas branch at `:153-159`).
- **History write:** `saveCheckinRecord(CheckInRecord(date:, q1: 'discover', q2: '', q3: '',
  q4: '', nameReturned:, nameArabic:))` (`:707-715`).
- **Streak:** `_markStreakAndHandleMilestones()` (`:720`). **XP** is awarded at
  `completeDeeper()`, not here (`:718`).
- **Analytics:** `check_in_completed` with `path: 'discover'` (`:730-735`), best-effort in a
  try/catch because the bypass wrapper reads `state.error` to decide refund-vs-commit.

**Render branches.** `_buildContent` (`:376-389`):
```
checkinLoading || reflectLoading      → ReflectLoading()
currentStep == completed              → _buildCompleted()
checkinDone && checkinName != null    → _buildCheckinResult()
otherwise (i.e. the checkin step)     → ReflectLoading()   // :389
```

### Where a question could be inserted without fighting the state machine

**`DailyLoopStep.checkin` is an empty slot.** It is the initial step
(`DailyLoopStep { checkin, deeper, quest, completed }`, `:44`) and it has **no UI at all** — the
fall-through at `muhasabah_screen.dart:388-389` renders a spinner because `discoverName()` is
already running. Rendering a question there instead of a spinner, and deferring the
`discoverName()` call in `initState` until an answer arrives, is a change to two call sites.

### What already exists that would consume an answer — this is the important part

1. **`DailyLoopState.checkinAnswers`** (`:59`) — `List<String>`, already in `copyWith` (`:181`,
   `:231`), already **persisted** by `_persistTodayState` (`:1431`) and **restored** by
   `_loadTodayState` (`:1466`). A stored answer survives a cold restart for free.
2. **`_deeperContextText(source)`** (`:1183-1203`) **already prefers `checkinAnswers` over the
   card blurb**:
   ```dart
   if (source.checkinAnswers.isNotEmpty) return source.checkinAnswers.join(' / ');
   ```
   The card-description fallback at `:1188-1195` only runs when no answers exist.
3. **`_deeperRequestFor`** (`:1169-1181`) forces the revealed Name: `forceName =
   state.checkinName`.
4. **`reflectWithOpenAI(userText, {ReflectContext? context, String? forceName})`**
   (`lib/services/ai_service.dart:804-807`, force clause at `:156-159`) is the engine both paths
   share.

**Net:** writing one answer string into `state.checkinAnswers` before `_prefetchDeeperReflection()`
makes the entire `BeatRevealFlow` reflection be written **about the stated problem, against the
revealed Name**, with **zero new AI plumbing**. That is the cheapest possible version of "the
answer visibly drives the reveal" and it is already wired.

---

## 4. The graveyard — why the questions actually went away

### 4a. `answerCheckin()` — what it asked and what it produced

`daily_loop_provider.dart:842-1026`, under a header block (`:823-832`) that says it is
DEPRECATED, has no live UI, and is *"preserved as a reference for the AI-context shape and for
the latent re-entry-guard fix; delete with the next muhasabah refactor."*

**What it asked (q1-q4).** The four questions were never four *distinct* hardcoded prompts in
this function — `answerCheckin(String answer)` advances an index 0→3 (`:844-854`) collecting four
answers. The question *content* lives in `lib/core/constants/daily_questions.dart`:
**30 questions, each with exactly 4 multiple-choice options**, `dailyQuestions` at `:17-259`,
overridable from the Supabase public catalog (`dailyQuestionsCatalog` `:262-271`,
`PublicCatalogKeys.dailyQuestions`), rotated by `getTodaysDailyQuestion()` (`:282-289`,
`dayOfYear % questions.length`). Question id 0 is verbatim **"What is weighing on you most right
now?"** with options *Uncertainty about the future · A strained relationship · Feeling behind in
life · Loss or grief* — i.e. the W2 hook screen's question, already written, already seeded.

**What it did with the answers** (`:863-1025`):
- `getCheckinHistory()` → `buildHistoryContext(history)`; last-10 `recentNames` for dedup;
  `discoveredNames` from the card collection so the AI prefers undiscovered Names (`:868-887`).
- `getDailyResponse(updatedAnswers, historyContext:, recentNames:, discoveredNames:)` (`:889-894`).
- Resolved the returned Name to a `CollectibleName` by transliteration then by
  whitespace-stripped Arabic (`:900-917`), then `engageCard` → gacha overlay on `tierChanged`,
  1 bonus token on `isDuplicate` (`:918-933`). **So the questionnaire path awarded cards too.**
- Cleaned the AI name (strips Arabic ranges + " — meaning" suffix) (`:941-948`).
- `saveCheckinRecord` with real q1-q4 (`:967-975`); `_markStreakAndHandleMilestones()` (`:982`);
  `check_in_completed` with `path: 'questionnaire'` (`:999-1006`) — with a long comment (`:990-997`)
  warning not to build a dashboard on that bucket until a question UI returns; then an idempotent
  `claimDailyReward()` (`:1012`) and `_persistTodayState()`.

**The AI-context shape it produced** — `getDailyResponse` (`lib/services/ai_service.dart:1660-1730`):
```
How they feel: {q1}
Where it is coming from: {q2}
How it feels deeper down: {q3}
What they need from Allah: {q4}
```
system prompt = *"A person has completed a 4-question daily check-in… identify the single most
fitting Name of Allah"* + avoid-recent clause + prefer-undiscovered clause + history section +
the canonical 99-Name list; `maxCompletionTokens: 100`; response marker `##NAME## English ·
Arabic`; returns `DailyReflectResponse{name, nameArabic}` only — **no verses, no duʿā, no
reflection**, with a hardcoded `Al-Wakeel` fallback on any failure. That is a much thinner engine
than `reflectWithOpenAI`, which returns the full reframe/story/verse/duʿā beat structure.

### 4b. Why `_CheckInStep` was removed — the decision-relevant fact

`/Users/appleuser/CS Work/Repos/sakina/flutter/docs/qa/findings/2026-04-26-launch-overlay-dead-checkinstep.md`
is titled **"Launch overlay `_CheckInStep` widget is unreachable"**, severity **"Low (code
cleanup + plan correction)"**. Its content:

- `_advance()`'s `else` branch dismissed the overlay after step 1 instead of advancing to step 2,
  and *"There is no other code path that sets `_step = 2`. **The `_CheckInStep` widget (line 587,
  ~250 LOC) and its tap handlers — including the `answerCheckin(option)` call at line 804 — are
  unreachable in production.**"*
- It cites the comment *"After reward claim — dismiss overlay (Muhasabah is on its own screen
  now)"* as confirming a design change that had **already happened**.
- Its "Doc impact" section is about `docs/manual-test-plan.md` §5 documenting a UI that no longer
  existed, and about two QA edge cases (B1, B3) targeting dead code.
- Its "Fix" is three cleanup items: delete the widget, update the provider doc comment, patch the
  test plan.

**So: `_CheckInStep` was removed because it was DEAD, not because it was bad and not because it
was clutter.** Nobody evaluated the questions on merit at that point. There is no user data, no
A/B, no complaint, and no product argument anywhere in the finding.

**Git confirms this even more bluntly.** The 267-line deletion of `_CheckInStep` /
`_CheckInStepState` rode along inside an entirely unrelated commit:

```
9348d93  2026-04-26  feat: implement rollback for removeSavedBuiltDua on server error,
                     add regression test for local state restoration
  flutter/lib/features/daily/screens/daily_launch_overlay.dart | 267 ---------
```
(11 files, mostly duas rollback + journal.) It is textbook drive-by dead-code removal.

**The actual product decision is three weeks earlier and has a different rationale.** Two
same-day commits on **2026-04-07**:

- `a4a5d2b` — *"feat: overhaul Discover a Name — **skip questions**, smart local gacha, collection
  glow + new filter"*, whose first bullet is *"Replace 4-question AI flow with **instant local
  card picker** (undiscovered → bronze → silver → gold priority)"*. The stated motivation is
  **latency and the card-collection economy** — an instant local pick instead of an AI round trip
  — not "questions were the wrong product."
- `7d6d908` — *"Muhasabah: extracted to own full-screen route (/muhasabah)… 'Seek Another Name'
  for card re-rolls"*, which is where "Muhasabah is on its own screen now" comes from, and which
  also lists *"AI: **simplified daily check-in (Name only)**"*.

Together: the questions were traded for instant gacha in April 2026 as a speed/economy
optimisation, the orphaned UI sat dead for three weeks, and then a cleanup pass deleted it. **The
founder's request is not a repeat of a known mistake. It is a revival of a path that was
abandoned by drift and was never judged on user evidence.**

### 4c. Other docs bearing on this

- `docs/qa/findings/2026-04-26-answercheckin-no-reentry-guard.md` (main worktree, untracked) —
  the latent double-tap race on the final question; the reason `answerCheckin` still exists at
  all (guard now at `daily_loop_provider.dart:843`, pinned by
  `test/features/daily/answer_checkin_reentry_guard_test.dart`).
- `docs/qa/findings/2026-04-22-core-loop-fixes.md` (main worktree, untracked) — exists; not
  read in depth, it predates the removal.
- **`CLAUDE.md`** ("Daily flow — the muḥāsabah path") is the standing statement: `discoverName()`
  writing `q1='discover'` with empty q2-q4 is *"intentional, not a bug"*, and the questionnaire is
  *"dormant… Delete with the next muhasabah refactor unless the questionnaire returns."*
- **`docs/superpowers/plans/2026-07-03-reel-first-conversion-refactor.md:662`** — a standing
  hygiene rule schedules the deletion: *"the entire legacy onboarding, tour code, **and the
  dormant `answerCheckin()` path** — one release after the keep decision."* The founder's request
  collides with a pre-registered deletion task.
- **`docs/analytics/2026-07-14-conversion-diagnosis-and-research.md:118`** lists the *"dormant
  4-question check-in path (0 users)"* under **"Dead weight"**, and changelist item #9 is *"Trim
  dead weight: discovery quiz, Store surface, dormant 4-Q path, dead intake pages"* — 0 users
  because it has no UI, not because users rejected it.

---

## 5. What consumes a stated feeling today

### `/reflect` — the one live free-text "how do I feel" surface

A bottom-nav tab (`lib/core/router.dart:323-328`; `app_shell.dart:438`).
`lib/features/reflect/providers/reflect_provider.dart` (`ReflectNotifier` at `:468`):

- **Flow:** free text (+ `selectedEmotions` chips, + AI follow-up questions —
  `_buildCombinedText` `:823-839`) → `submit()` (`:525`) → `GatingService.canUse(GatedFeature.reflect)`
  (`:537`) → `_doSubmit()` (`:623`) → `_reflect(text)` (`:766-820`) →
  `reflectWithOpenAI(text)` → off-topic branch or `ReflectStep.name` result.
- **What it awards:** `markActiveToday()` **and** `logActivity()` (`:806-807`) → the **streak**
  advances. **No XP** — the comment at `:805-806` says XP is intentionally zero, only muḥāsabah /
  quests / streak milestones grant it. **No card** — there is no `engageCard` anywhere on the
  reflect path. Auto-saves to the journal (`_saveReflection` `:846`), free cap
  `freeJournalLimit = 5` (`:824`) then `needsUpgrade`.
- **Gating:** `GatedFeature.reflect` — lifetime warmup **10**
  (`gating_service.dart:133-137`), then a **1/day** free cap; premium `premiumDailyFairUseCap = 30`
  (`:117`); 25-token bypass, max 2/day (`:124`, `:129`); `submitWithBypass` (`:559`) /
  `submitWithFirstBypass` (`:600`).
- **How it differs from muḥāsabah:** Reflect **asks** and answers with a Name + full reflection
  but grants **no card and no XP** and does not touch the daily reveal. `discoverName` grants
  **card + streak + XP** but asks **nothing**. The two halves of the reel promise are split
  across two tabs, and the half that matches the reel is the one that doesn't feed the collection
  economy. `docs/superpowers/plans/2026-07-03-reel-first-conversion-refactor.md:57` says exactly
  this.

### Existing problem → Name mapping the daily loop could reuse

**1. `ProblemChipResolver`** — `lib/features/onboarding/content/problem_chips.dart:290-381`.
The strongest asset. Pure, offline, no AI, no I/O beyond one asset read:
- `forChip(chipKey)` (`:297`) and `forFreeText(text)` (`:305`) → `ChipSelection`
  (`:243-286`) carrying `contract`, `problemCategory`, `hookType`, `pairNameIds`, `chipKey`,
  `problemTextRaw`.
- `matchChipKeyForText(text)` (`:219-231`) — pure keyword matcher over
  `problemChipKeywords` (`:161-205`), ~190 terms across 6 buckets in load-bearing evaluation
  order (guilt → far-from-allah → rizq → unseen → anxiety → heavy), space-padded whole-token /
  phrase matching, `normalizeProblemText` (`:210-214`).
- `pairNameIdsForChip` (`:366-372`) resolves the founder-approved **Name pair** from
  `assets/content/name_stories.json` via `NameStoriesService`, falling back to the comfort pair
  (Ar-Rahman + Al-Lateef, `comfortChipKey` `:239`) — never half a pair.
- Bench-chip routing (family, marriage, exams, sleep, grief) is pinned by
  `test/features/onboarding/problem_chips_test.dart`.

**2. The 30-question multiple-choice bank** — `lib/core/constants/daily_questions.dart:17-259`,
server-overridable, `getTodaysDailyQuestion()` (`:282`). Already surfaced (as text only) as the
home CTA subtitle via `DailyLoopState.todaysQuestion` (`daily_loop_provider.dart:405,416,472`).

**3. `dailyQuestionProvider` — a complete, fully dormant question→Name→persistence pipeline.**
`lib/features/daily/providers/daily_question_provider.dart`:
- `loadTodaysQuestion()` (`:67`) with per-day prefs restore; `answerQuestion(answer)` (`:90-142`)
  → `getDailyResponse([questionText, answer])` → `markActiveToday()` → persists to prefs
  **and inserts a `user_daily_answers` row** (`:127-137`); full two-way Supabase hydration
  (`syncDailyAnswersFromSupabase` `:148`, `hydrateDailyAnswersCacheFromRows` `:183`,
  `seedDailyAnswersToSupabaseFromLocalCache` `:207`).
- **Live consumers: none.** `grep` for `dailyQuestionProvider` across `lib/` returns exactly two
  hits — its own definition (`:235`) and `lib/core/utils/invalidate_providers.dart:24`. The only
  other references are `test/features/daily/daily_question_provider_test.dart`. There is a
  Supabase table, a sync path, a notifier and a 30-question catalog with **no screen**.

**4. `reflectWithOpenAI(text, {forceName})`** — `ai_service.dart:804-807`. The seam that lets a
stated problem and a queue-chosen Name coexist: force the Name, write the reflection about the
problem. Already used this way by `_startDeeperReflectionRequest`
(`daily_loop_provider.dart:1205-1212`).

---

## 6. The ICP as the code actually defines it

**The seven chips, labels verbatim** (`problem_chips.dart:85-132`, render order = approved order,
six problem chips then the sign chip last):

| # | `chipKey` | label (verbatim) | `problemCategory` | `contract` |
|---|---|---|---|---|
| 1 | `anxiety` | **"My mind won't stop racing"** | `anxiety` | problem |
| 2 | `heavy` | **"Everything feels heavy"** | `heavy` | problem |
| 3 | `guilt` | **"I keep sinning and going back"** | `guilt` | problem |
| 4 | `far-from-allah` | **"I feel far from Allah"** | `far_from_allah` | problem |
| 5 | `rizq` | **"I'm worried about money / providing"** | `rizq` | problem |
| 6 | `unseen` | **"No one sees what I'm carrying"** | `unseen` | problem |
| 7 | `sign` | **"I can't put it into words"** | `unspoken` | **sign** |

The taxonomy cap is deliberate and is the choice-overload guard; bench chips (family strain,
grief, sleep) are *deliberately absent from the screen* and reachable only through the free-text
keyword map (`:1-8`). Chip 7's comment (`:124-127`) records that the long form duplicated `heavy`
and that the escape hatch reads best as the shortest, least-committal line (Noom's "I haven't
decided yet").

**The `contract` concept** — `HookContract` (`:22-25`): `problem` vs `sign`. It is the `contract`
key of `user_profiles.acquisition_promise` and carries a **DB check constraint requiring it**
(`:20-21`; `lib/services/auth_service.dart:447`). Semantics: `problem` = the user named what they
are carrying; `sign` = they could not, and asked for a sign. Typed free text is **always** the
problem contract — *"the sign contract is a claim only the user's own tap on the sign card may
make"* (`:353-355`). The contract also switches copy register everywhere downstream, e.g. the
aspiration question's two stems (`aspirations.dart:50-51`, `aspirationQuestionFor` `:112-114`).

**`acquisition_promise`** — the jsonb payload built at
`lib/features/onboarding/providers/onboarding_provider.dart:392-403`:
`{reel_id?, hook_type, contract, problem_category?, carrying_duration?}`. `contract` is
mandatory; if `contract` or `hookType` is missing the app emits **nothing** rather than guess an
arrival story (`:382-385`). `HookType` (`problem_chips.dart:47-53`) records **origin, not the
last widget touched**: `reel` outranks `chip` and `freeText`.

**`first_problem_text`** — the verbatim typed sentence, `user_profiles.first_problem_text`
(`problem_chips.dart:268`, `onboarding_provider.dart:285`, `auth_service.dart:51`). Stored for
later verbatim echo, **never interpolated into scripted copy** (plan §V6.8.A4).
`problemCategoryUnmatched = 'unmatched'` (`:58`) records that the taxonomy did not cover what
they typed — *"the signal that grows it."*

**`aspirations.dart`** — `Aspiration` (`:19-47`); founder-approved 2026-07-27; five options, each
seeding **queue positions 3-7** in order: `closeness` ("To feel close to Allah again" /
"To feel Him near"), `consistency` ("To keep turning back, even when I slip" / "To stop
drifting"), `peace` ("To carry less noise inside" / "To be still"), `gratitude` ("To notice what
He has already given" / "To see the good again"), `guidance` ("To know what He wants from me" /
"To be shown the way"). Register rule (`:10-13`): *"depth, not productivity. The options name
what a heart is reaching for, never a habit target, a streak, or a completion goal."*

**Operational implication for a daily question:** the answerable vocabulary is the six problem
registers plus the "can't put it into words" escape hatch. Any daily question must be answerable
in that vocabulary — which means a chip-shaped daily question can reuse `ProblemChipResolver`
verbatim, and would keep `problem_category` comparable between onboarding and the daily loop.
The 30-question bank's option sets are a *different* taxonomy (emotions, avoidances, needs) that
does **not** map onto `problemCategory` — reusing it would fork the segmentation vocabulary.

---

## 7. What our own analytics/diagnosis already say

### `docs/analytics/2026-07-14-conversion-diagnosis-and-research.md` (main worktree, untracked)

**Headline** (`:53-62`): *"Conversion is decided in the first session, and Sakina's first session
doesn't sell anything."* 32/42 all-time subs (76%) converted Day 0; 88% within 2 days. Signup→paid
~2.9% ≈ the published freemium median (2.1%) — *"the soft-gate model is performing to spec; the
spec is the problem."*

**The leak table** (`:71-86`) — three named leaks: tour start→complete 52% (leak #1);
**D0→D1 return 31% (200/646) — "Leak #2 (largest by volume). 69% never return"**; CTA tap→paid
~16-22% (leak #3). Activation (ever check in) is 95.5% but **~38h average install→first check-in**.
Streaks: 600/865 users (69%) have `longest_streak ≤ 1`.

**Payers are depth users, not frequency users** (`:96-110`): check-ins 2.9 free vs 3.3 payers
(~1.1×, identical) but built duʿās 2.6×, reflections 3.0×, Reflect usage 2.8×.

**H1 verdict — "half right; remedy wrong"** (`:130-136`): *"The mismatch is real: reels promise
'tell it how you feel → your Name,' the app delivers that once (onboarding page 0, hardcoded
7-Name map), and the live loop (`discoverName()`) is a blind gacha that never asks how you feel.
But onboarding *length* is not the leak… **The broken pieces are the forced tour (52%) and the
core loop not re-delivering the reel promise.**"*

**H2 verdict — "contradicted on mechanism"** (`:138-143`): conversion is a Day-0 event; the
once-a-day ceiling is a **retention** problem (31% D1), not a conversion suppressor.

**Feature census** (`:112-119`): the muḥāsabah loop is *"Load-bearing for retention (keep free)"*;
Reflect + Build-a-Duʿā are the *"Willingness-to-pay surface (gate harder)"*; the *"dormant
4-question check-in path (0 users)"* is listed as **dead weight** — and changelist #9 (`:295`) is
to trim it.

**So the diagnosis supports the founder's instinct on substance** (the core loop not
re-delivering the reel promise is one of two named broken pieces, and D0→D1 is the biggest leak
by volume) **while explicitly listing the specific dormant implementation as dead weight to
delete.** Revive the *shape*, not the `answerCheckin` code.

### `docs/superpowers/plans/2026-07-03-reel-first-conversion-refactor.md`

**The diagnosis of this exact problem** (`:57`): *"**The live core loop doesn't match the reel.**
`discoverName()` skips the feeling question entirely — it's a card-collection gacha pull, not
'tell me how you feel.' The real feeling→Name engine (`reflectWithOpenAI`) is tucked away on the
Reflect tab behind daily-cap gating."*

**The prescription — Phase 2, "Make the core loop match the reel (the retention fix)"**
(`:101-108`):
- *"Rewire `Begin Muḥāsabah` to feeling-first."* `/muhasabah` opens with the same one-question
  feeling input → `reflectWithOpenAI` (all 99 Names, history/anchors context) → Name reveal →
  **card still awarded** (*"the feeling becomes the input, the card the prize"*). Route through
  `GatingService.canUse/markUsed` so the freemium economy is untouched.
- Retire `discoverName()`'s blind pull as the *primary* path, keep it as the offline/AI-failure
  fallback.
- `check_in_completed` gains `path:'feeling'` + the chosen emotion as a property.
- `sakina://feel/<emotion>` deep links.
- **Estimated scope: ~1 week.** *"Engine + UI exist; this is routing + gating + one prompt tweak."*
- Sequenced **#2 of 5** (`:138`), targeting D1/D7 retention and check-in 69%→80% of openers,
  D1 +10pts.

### Why it was deferred — stated accurately

Three explicit statements, all pointing the same way:

1. **`:601` (§V6.8.A5)** — *"The Day 1-7 promise gets an implementation owner (the orphaned
   Phase-2 seam)."* The One Ship includes only the **minimum** daily-loop seam (D1-D7 reveal
   consults `user_name_queue`); *"A stated feeling overrides the Name, but the unseal deck is
   offered immediately after… **The full feeling-first core-loop rewire (v1 Phase 2) is the first
   post-read item.**"*
2. **`:658` (§V6.9, founder decision 2026-07-23)** — rollout is 100% ship-and-watch, no A/B, no
   control arm, reads are pre/post vs the trailing-90d baseline. It replaces the change freeze
   with **one-change-at-a-time**: *"nothing user-facing between T0 and the keep read"*, health
   read T0+2wk, trial→paid T0+4wk, **keep decision T0+6wk** on D30 cohorts (target ≥5%
   signup→paid vs a 2.44% baseline). And explicitly: *"every 'post-decision' sequencing trigger
   (grandfathering execution, softener wave, welcome/backup offers, **core-loop rewire**,
   legacy-code deletion) now keys on the **T0+6wk keep decision**."*
3. **`docs/superpowers/plans/2026-07-29-one-ship-03-daily-loop.md:249`**, under **"Deliberately
   out of scope"** — *"**The feeling-first core-loop rewire** (Begin Muḥāsabah → problem input →
   `reflectWithOpenAI`). §V6.8.A5 makes it the first item *after* the keep decision. §7c delivers
   the 'offered immediately after' half only."*

**The deferral rationale is measurement hygiene, not product doubt.** Nobody argued the rewire
was wrong — the plan calls it *the retention fix* and ranks it #2. It was deferred because the
One Ship's read is a **pre/post comparison with no control arm**, so a second user-facing change
inside the read window makes the ship's own result uninterpretable. Two ancillary constraints
ride along:
- **`:522`** — *"The daily problem/feeling→Name match itself is free forever… Without this line,
  the core-loop rewire and the tightened free tier collide over the promise itself."* Any daily
  question must stay free.
- **`:530-531` / §V6.8.B3** — *"`discoverName` is exempt from the tightening"*; it keeps a 1/day
  free cap permanently, because paywalling the daily reveal would kill the streak engine.

**One materially useful nuance for the founder's decision:** the freeze is defined relative to
**T0 = the One Ship's release**, and W3 was still being built on 2026-07-29 (`:15` of the W3
plan; §7c notes the freeze clock for notification templates started 2026-07-25). If T0 has not
happened, the freeze has not started, and the choice is *fold it into the ship* (before T0) vs
*wait 6 weeks after T0*. Folding it in costs the ability to attribute the result to any single
change; waiting costs ~6 weeks against the largest leak in the funnel. I could not verify T0's
date from the repo — that needs confirming before the deferral is treated as binding.

### §7c — the piece W3 *is* shipping, and its reasoning

`docs/superpowers/plans/2026-07-29-one-ship-03-daily-loop.md:186-198` is worth reading in full
because it independently re-derived the same finding: *"There is no feeling input on the muḥāsabah
path — `discoverName` skips questions by design, and the rewire that would change that is
explicitly post-keep. The one live stated-feeling surface is **Reflect**… So, concretely:
**nothing overrides anything, because the two paths were never competing** — what W3 owes the
user is the 'immediately after.'"* W3 ships one quiet card in the Reflect epilogue
(`lib/features/reflect/widgets/sealed_name_offer.dart`, new) routing to `/muhasabah`, copy
*"Your second Name is still sealed." / "Open it"* (the plan-of-record's own suggested line trips
its own copy firewall — divergence D-W3-8).

---

## 8. Cost estimate

### Minimal "day-open asks one question, and the answer visibly drives the reveal"

The cheapest coherent shape, given §3 and §5:

| # | file | change | size |
|---|---|---|---|
| 1 | `lib/features/daily/screens/muhasabah_screen.dart` | `initState` (`:87-96`) stops auto-firing `discoverName()` when no answer exists; `_buildContent`'s `checkin` fall-through (`:388-389`) renders a question screen instead of `ReflectLoading()`; on answer → `notifier.answerDailyProblem(x)` → `discoverName()`. | M |
| 2 | new `lib/features/daily/widgets/daily_problem_prompt.dart` | The question UI. Reuse `problemChips` (7 chips) + the free-text modal pattern already built for the hook screen (`hook_problem_screen.dart`). <200 lines. | M |
| 3 | `lib/features/daily/providers/daily_loop_provider.dart` | One new method that writes the answer into `state.checkinAnswers` (already persisted `:1431` / restored `:1466`) before `discoverName()`. `_deeperContextText` (`:1183`) then picks it up **with no edit**. Optionally add `problem_category` to the `check_in_completed` props (`:730-735`). | **S** |
| 4 | `lib/features/progress/screens/progress_screen.dart` | Promote the CTA out of the divider stack / above the lantern, and stop rendering the question as an 11px subtitle (`_buildMuhasabahPromptLabel` `:1095`) if the screen now asks it. | S–M |
| 5 | `lib/features/daily/screens/daily_launch_overlay.dart` | If the question moves into the overlay instead: `_advance()` (`:107-119`) gains the third branch back, `switch (_step)` (`:160-173`) gets a real case 2, and it must route into `/muhasabah` rather than dismiss. | M |
| 6 | `lib/services/analytics_event_names.dart` | Any new props/events. | S |
| 7 | tests | `discover_name_queue_test.dart`, `check_in_completed_analytics_test.dart`, `muhasabah_screen_source_test.dart`, `daily_loop_reset_today_test.dart` all touch this path. | M |

Realistically **3-6 days of build** if the answer feeds `checkinAnswers` (reusing the existing
`forceName` reflection seam) and the Name still comes from the queue/gacha. The plan's own
estimate for the *full* Phase 2 rewire — where the answer also **chooses** the Name via
`reflectWithOpenAI` — is *~1 week* (`:107`), and I think that is honest given the engine exists.

### Expensive / risky — flag these explicitly

1. **The gating cap fires BEFORE the question.** `progress_screen.dart:988-1001` calls
   `GatingService().canUse(discoverName)` and then `markUsed` **at the CTA, before navigation**
   (the comment at `:997-999` says so deliberately). Insert a question after that and a user who
   opens the prompt and backs out has burned their 1/day free reveal. Fixing it means moving
   `markUsed` into `discoverName()` — which touches the bypass reserve/commit/cancel machinery
   (`discoverNameWithBypass` `:763-788`, `discoverNameWithFirstBypass` `:795-821`) and the
   refund invariant that `state.error` decides commit-vs-cancel. **This is the single most
   dangerous edit in the whole change.** Pinned by `discover_name_dispose_cancel_test.dart`.
2. **The W3 queue seam landed three commits ago** (`780a12a`, `9b0f0a0`) and is mid-flight —
   Waves 3-5 of `2026-07-29-one-ship-03-daily-loop.md` are unbuilt. The plan states (§10
   "Parallelism") that Waves 2, 3 and 5 **cannot be parallelised** because all three edit
   `daily_loop_provider.dart`. A question insertion is a fourth writer on the same function.
   Merge-conflict risk is high and the plan's §11 warns that any drift into new SQL means the
   design drifted.
3. **The `q1='discover'` history contract.** `CLAUDE.md` states the `q1='discover'` /
   empty-q2-q4 shape is intentional. A stated problem has an obvious home in `q1`, but writing
   the problem there **forks the contract** that `getCheckinHistory` / `buildHistoryContext` and
   any Supabase-side analysis read. Pinned by `discover_name_queue_test.dart` and
   `check_in_completed_analytics_test.dart`. Safer: keep `q1='discover'` and add a new column, or
   reuse the existing `user_daily_answers` table that `dailyQuestionProvider` already writes to
   (`daily_question_provider.dart:127-137`).
4. **The analytics funnel.** `check_in_completed{path:'discover'}` is the recurring core-loop DAU
   event and the D1/D7 retention spine. Changing `path` (to `'feeling'`, per plan `:105`) breaks
   every historical comparison; adding `problem_category` as a new prop does not. Per
   `CLAUDE.md`, this is ONE funnel segmented by super properties — do not fork the event.
   Also W3 Wave 5 is about to add `name_source` / `queue_position` to the same event.
5. **`answerCheckin` is scheduled for deletion** (plan `:662`). Reviving the *shape* while a
   standing rule says delete the *code* needs an explicit call; my recommendation is to let the
   deletion proceed (its engine, `getDailyResponse`, returns a Name and nothing else — strictly
   weaker than `reflectWithOpenAI`) and build the new question on `ProblemChipResolver` +
   `reflectWithOpenAI(problem, forceName:)`.
6. **The change freeze / T0 sequencing** (§7 above) is a scheduling decision, not an engineering
   one, but it is the founder's to overturn knowingly — and it needs T0's actual date.
7. **Two taxonomies.** The 7 problem chips (`problemCategory`) and the 30-question option bank
   are different vocabularies. Reusing the 30-question bank forks segmentation away from
   `acquisition_promise.problem_category`; reusing the chips keeps onboarding and the daily loop
   comparable. Recommend the chips.
8. **The state machine itself is not the risk.** `DailyLoopStep.checkin` is an empty slot with a
   spinner in it; `checkinAnswers` is already persisted and already preferred by the AI-context
   builder; `resetToday()` (`:1097-1107`) already wipes and re-initialises cleanly. This part is
   genuinely cheap — which is worth saying plainly, because it is the part that *looks*
   expensive.

---

## Verification limits

- All vertical-offset figures in §2 are computed from layout constants, not measured on a
  simulator or device (the task is read-only). The **ordering** is exact; the pixel totals are
  ±15% and the "below the fold" conclusion should be confirmed with one screenshot.
- I did not run `flutter test`; every behavioural claim above is read from source, and where a
  test pins a contract I name the test file rather than asserting it passes.
- T0 (the One Ship release date) is not derivable from the repo; the freeze-window nuance in §7
  depends on it.
- `docs/qa/findings/2026-04-22-core-loop-fixes.md` exists but was not read in depth; it predates
  the removal and did not surface in any grep for the check-in questions.
