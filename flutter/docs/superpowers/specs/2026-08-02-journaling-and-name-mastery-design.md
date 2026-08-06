# Journaling, the archive, and Name mastery — research + design direction

**Status:** RESEARCH + DIRECTION, not yet a settled spec. Nothing here is approved; §11 lists the decisions that need a founder call before any of it becomes a plan.
**Date:** 2026-08-02
**Commissioned:** founder request — "make the journaling part much better", plus a follow-up on Cozy's trivia-pack economy (screenshot) and a clarification that packs should be *knowledge testing over the Names*, not party trivia.
**Evidence base (all written this session):**
- `.context/research-cozy-couples.md` — Cozy teardown (685 verbatim reviews, screenshots read as images, live paywall)
- `.context/research-journaling-patterns.md` — 15 journaling/reflection apps + the psychology literature
- `.context/research-trivia-packs-economy.md` — pack economies, the dual gate, and quiz pedagogy for sacred content
- `.context/map-muhasabah.md` — our daily loop, file:line
- `.context/map-journal-and-story-ui.md` — our Journal screen + `BeatRevealFlow`, file:line
- `.context/map-economy-and-packs.md` — currencies, Store, gating, collection, quests, cosmetics, file:line

**Parents / constraints:** `2026-07-30-daily-loop-asks-design.md` (W4, shipped — the daily question) · `2026-07-23-conversion-refactor-changes-and-implementation.md` §V6.9 (the T0 change freeze) · `flutter/CLAUDE.md` (content rules, "What NOT to build") · `flutter/TODO.md` (the 1.3.0 / T0 runbook)

---

## 1. The short version, in plain language

Right now the app asks you one good question every night — *"What's on your heart today?"* — and then throws your answer away. It uses your words to pick what the AI writes, shows you a Name, and never saves a single word of it. That is why the Journal doesn't show your muhasabah: there is nothing to show. So the first and most important change is invisible: **start saving the nightly reflection as a real journal entry** (your words, the Name you met, the verses, the duʿā). Everything else becomes possible once that exists. Then we fix the three things you noticed. **The "done" screen stops being a dead end** — instead of ending on "Complete", it shows you what you just wrote, lets you keep adding to tonight's entry like a thread rather than a form you already submitted, and shows you *your own answer to the same question a month or a year ago*. **The Journal becomes a real archive** — entries render in the tap-through story format we already built instead of two lines of grey text, you can start or continue tonight's entry straight from that screen, and the existing "Month of Light" calendar becomes how you browse, so tapping a lit night opens that night. **And the app starts bringing your past back to you** — "on this night last year" — which is the single biggest retention lever in this whole category and which no Islamic app currently does. There's also a cap to fix on the way: a free user can only ever **save five reflections, ever** — a rule from May that nobody revisited when the July free-tier change made *generating* the scarce thing instead. Today they spend one of their three weekly uses, see the reflection, and lose it. That cap should go. On the trivia idea: build it, but change the money part. Cozy's stars are really dollars in disguise, and putting a price tag *and* a crown on the same card is the thing their users complain about most. Ours should unlock by **how many of that theme's Names you've actually collected**, so the daily practice is what opens it, and the subscription buys *depth* rather than access. And tokens shouldn't be what buys packs — tokens being useless is an argument for finishing the currency merge, not for inventing a place to spend them, least of all on knowledge about Allah. The one rule we cannot get wrong: never show a wrong answer about Allah — every option on screen is a true Name, and the question only asks which one *fits*.

---

## 2. What is actually true about our app today

All four of the founder's observations are correct. One is worse than described.

| Observation | Verdict | Where |
|---|---|---|
| "Completing muhasabah doesn't offer to do it again" | **Correct** | The gate is `!state.checkinDone` in `_showsQuestion`, `muhasabah_screen.dart:380-385`. The one re-entry CTA, "Seek Another Name" (`:1003-1051`), calls `resetToday()` → `discoverName()` **directly** — it never routes back through the question. A re-roll is a card pull, not a second reflection. The home CTA vanishes entirely once the day is done (`progress_screen.dart:969-971`). |
| "It isn't framed as journaling" | **Correct, and structural** | `daily_question_copy.dart:20` is a single hardcoded constant. One `TextField`, `minLines:1 maxLines:6`, no title, no draft, no edit, no attachment, no tag step. |
| "Journal entries are blobs of text" | **Correct for the list** | Each row is `_ExpandableCard` (`journal_screen.dart:1266`): type chip + relative date + Name badge + `Text('"${r.userText}"', maxLines: 2, ellipsis)` (`:810-819`). The *detail* page is already beat-structured via `ChunkedSectionView`. |
| "The Journal doesn't even show the daily muhasabah" | **Correct — and the reason is worse than a missing query** | Different table, and the table has nowhere to put it. `user_checkin_history` (`20260407000000_initial_schema.sql:231-244`) has **no column for body text**; the discover path writes `q1='discover'` with q2–q4 empty. **The AI reflection is never persisted at all.** The user's typed sentence survives only in a device-local SharedPreferences day blob (`daily_loop_provider.dart:2482-2518`). |
| "You can't add an entry from the Journal page" | **Correct** | No FAB, no compose button (`journal_screen.dart:169-198`). The primary All-tab empty state has no CTA at all (`:979-985`). |

### The finding that reframes the whole request

**The core loop leaves no artifact.** This is not a UI omission. Sixty-nine percent of monthly openers complete a check-in; seventeen percent create a journal entry. Those are two different features because the check-in has never written anything down. Every good idea below — story-format entries, resurfacing, "on this night", a recall quiz over your own history — is blocked behind the same one-line problem, and unblocked by the same fix.

### Two constraints that will bite whoever builds this

1. **The free journal cap would break the daily loop** — and it is already misfiring on its own. Full analysis in §9A. Short version: `_saveReflection` refuses at 5 saved reflections for free users (`reflect_provider.dart:887`), this is a *different and older* gate than W5's weekly pool of 3, the two stack, and the save is refused **after** the weekly use has already been spent. **Muhasabah entries must not count against it — and the cap itself should probably go.**
2. **The privacy rule is narrower than it looks, and that is load-bearing.** The "answer text NEVER leaves the device" invariant is **analytics-only**: the guard test sweeps `track` / `setUserProperties` / `onAnalyticsEvent` call sites and nothing else (`test/services/no_free_text_reaches_analytics_test.dart:59-74`). The app already stores typed text server-side under RLS — `user_reflections.user_text` and `user_profiles.first_problem_text`. So persisting the nightly reflection to the user's own row is *consistent with existing practice*, not a reversal of it. It is still a posture decision worth taking explicitly (§11 D2), because muhasabah content is confessional in a way a Reflect entry may not be.

---

## 3. What the research says

### Cozy, verified

4.84★ / 42,358 iOS ratings; #93 Top Grossing US iPhone Lifestyle; ~$70K/mo (Adapty). The transferable findings:

- **The daily prompt is a conversation container, not a form.** Answering opens a chat thread with alternating bubbles, and the same author can post consecutively. *"Write more" is the default state, not a CTA.* This is the direct answer to "it doesn't offer to do it again" — and it is not a re-do button.
- **The ritual is free; the accumulated memory is rented.** Writing is never gated. Free accounts lose their own entries after 14 days. "Unlimited history" is the headline paywall bullet, at $29.99/yr.
- **That same mechanic is their angriest review cluster** — because it was retrofitted onto users who had already written months of entries. *"You guys are gonna hold our messages hostage?"* Ship a history window from day one or not at all.
- **No skip, no shuffle** — an unanswered prompt blocks and wedges people. Our "Not right now" defer is already better than this.
- **Zero recap, rewind, or "on this day."** They charge for the archive and never resurface it, while reviewers describe re-reading as the entire emotional point.

### The category

- **The "now what?" screen is the neglected surface, and nobody's answer is "write another entry."** Six patterns found: a tagging/completion step (Stoic), 2–3 AI follow-ups (Rosebud), a gated reveal (Paired), an appointment set in motion (Finch's pet departs for 6 hours), matched revelation (Muslim Pro's mood→āyah), and celebration + streak reveal.
- **Resurfacing is the biggest retention lever, and the Islamic category is empty on it.** Tumaninah (judgment-free, device-only, tracks *answered duʿās*) and Muhasaba (scored tracker) sit at opposite poles; Muslim Pro does shallow mood→āyah. None does "On This Day", same-prompt-over-time, or a real weekly recap.
- **Numbers worth holding onto:** Finch 54% D1 / 37% D7 at 10M MAU — better than a top-grossing game. Duolingo: 7+ day streaks → 2.4× retention; two streak freezes beat one, three ≈ two, unbounded forgiveness erodes the habit; freezes applied *silently*. Streaks + milestones together → 40–60% higher DAU than either alone. Peterson's Future Authoring: 14% dropout vs 27% control — which argues for ending the muhasabah on forward resolve (ʿazm), classically correct anyway.
- **A constraint to treat as hard:** vary the *content* received (which Name, which memory, which āyah), never *whether* the user is rewarded. Do not gamble a user's sense of divine favour.

### What we already own that the research says to build

| Pattern (research rank) | We already have |
|---|---|
| #1 Same-prompt time machine | Nothing — but P0 creates the data |
| #2 Never end on Save | `_buildCompleted`, `muhasabah_screen.dart:948-1120` |
| #3 Calendar archive whose empty cells compose | **`MonthOfLight`** — `streaks/widgets/month_of_light.dart` + provider, states `lit / todayPending / excused / held / missed / future`, currently read-only |
| #6 Bounded, silent, earnable streak forgiveness | Freeze system + `streak_rescue_sheet.dart` + `FreezeBurnCard` |
| #7 Matched revelation (state → the Name that answers it) | `CardRevealOverlay` + `BeatRevealFlow` — a better version than Muslim Pro's |
| #13 Companion appointment mechanic | Lantern + cosmetics + widget frames; missing only *duration* |
| Story-format entries | **`BeatRevealFlow`** — accepts pre-built `List<BeatScreen>`; `SavedReflection` already persists the identical beat fields in `beat_data` jsonb |

---

## 4. P0 — Persist the nightly reflection (prerequisite, user-invisible)

Nothing else in this document is buildable without this, and on its own it changes no pixel.

**Do:** on `completeDeeper()`, write one row per night carrying the user's answer, the revealed Name, the verses, the duʿā and the beat structure.

**Reuse `user_reflections`, don't add a table.** It already has `user_text`, `name`, `name_arabic`, `verses` jsonb, the four `dua_*` columns, `related_names`, and `beat_data` jsonb (`20260714000000_user_reflections_beat_data.sql`). It has RLS, length caps, and a `sync_all_user_data()` union.

**Migration:** add `source text not null default 'reflect'` (values `reflect` | `muhasabah`) and `entry_local_day date` — the local day, not `saved_at`, because the streak, the launch gate and the reward ladder all key on local/UTC day and a timestamp will disagree with them near midnight.

**Then, non-negotiably:**
- Muhasabah entries are free forever, unlimited, for everyone. If §9A's recommendation is taken and the 5-entry cap is removed outright, this is automatic. If the cap is kept, the check at `reflect_provider.dart:887` must count **only `source='reflect'`**.
- Extend the `sync_all_user_data()` reflections union as a **superset of the latest definition** (`20260727100300_sync_one_ship_profile_keys.sql:47+`) — this has already collided once (`20260726000300`).
- Do **not** add the text to any analytics payload. The existing guard test will catch a `track(...)` violation; it will not catch a new Supabase column, so this needs a code-review note rather than a test.

**Cost:** 1 migration, one write in `completeDeeper()`, one predicate change, one sync union, tests. Small. **Blast radius: the freemium guard triggers and the sync RPC** — both are documented tripwires (`map-economy-and-packs.md` R4, R5).

---

## 5. P1 — The night stops dead-ending

Today: "Muhāsabah Complete" → "Seek Another Name" (a premium-gated card re-roll for the `reel_v1` cohort) → "Return to Home". The research is unanimous that this is the most valuable screen in a journaling product and ours currently ends on a full stop.

**P1.1 — The entry becomes a thread, not a form.** This is Cozy's real lesson and the honest answer to "it should let me do it again." After the reveal, tonight's entry stays open until the local day rolls over. "Add to tonight" appends; it does not re-run anything.

> **The hard architectural line:** appending text must **not** touch `discoverName()`. The reveal, the streak mark, the reward-ladder claim, the queue unseal, the card engage and the allowance consumption all fire **once** per night, at first submit. Additions are pure text writes. This is what lets us widen journaling without widening the gate the codebase is deliberately defended against — the "phantom second gacha" bug class (`daily_loop_provider.dart:85-91`). Do not widen `!state.checkinDone`; bypass it with a separate append path.

**P1.2 — Land the completion on something, per Stoic.** Show what was saved (the words, the Name, the duʿā), then exactly one forward action. Optionally a lightweight tag step — but see §11 D4, tags are a taxonomy decision, not a UI one.

**P1.3 — The same-prompt time machine (the highest-ranked pattern in the research).** Completing tonight reveals *your own answer to the same question* from 30 / 90 / 365 days ago. Cannot be peeked at first. It costs no content, it makes the archive pay rent nightly, and it is the reason P0 exists. Degrades gracefully: a new user sees nothing, which is fine — it arrives as a surprise on day 31.

**P1.4 — End on ʿazm.** One line of forward resolve, resurfaced as tomorrow night's opening. Strongest retention datum in the literature (Peterson) and classically correct for muhasabah.

---

## 6. P2 — The Journal becomes an archive

**P2.1 — Show the muhasabah.** Free once P0 lands; it is the same table.

**P2.2 — Story-format entries.** Reuse `BeatRevealFlow`. Per the code map this is close to drop-in: it already accepts a pre-built `List<BeatScreen>` (`beat_reveal_flow.dart:122-132`) and `SavedReflection` already stores the same beat fields. Net new: one ~40-line `buildBeatScreensFromReflection()`, a completion-label prop (the hardcoded "Ameen" pill and 1.1s ceremony are wrong for a re-read), a guard on "Skip to duʿa" when no duʿā beat exists, and one new `BeatKind` for a date/cover card.
*Know before promising:* `BeatScreenView` is a **closed switch over string slots**, not arbitrary widgets. Photos, charts and rich media are not a small change. Paging *between* entries needs the Scaffold hoisted out of the flow (3 lines, 3 call sites).

**P2.3 — Compose from the archive.** A single primary control whose meaning depends on the day's state: *start tonight's muhasabah* if undone → *add to tonight* if open → *free write* otherwise.

**P2.4 — Promote `MonthOfLight` to the browse surface.** It is currently a read-only bottom sheet reachable only from the streak line. It already computes `lit / todayPending / excused / held / missed / future` from check-in history. Make lit cells open that night and `todayPending` start tonight. One control then does browse + compose + streak repair, and the gaps are already rendered gently — *"an open invitation, not a gap"* (`month_of_light_provider.dart`).

**P2.5 — Fix the sort bug.** Saved related duʿās have no timestamp, so the All-feed merge stamps `DateTime.now()` (`journal_screen.dart:139`) and pins them permanently to the top.

---

## 7. P3 — Resurfacing (the open lane)

"On This Night" — your entry from this date last month / last year. Weekly recap — themes, the Names you met, one line you wrote. Answered-duʿā resurfacing — *"you asked for this four months ago"* — which is the single highest-emotion mechanic available to a Muslim app, maps onto Build-a-Duʿā, and is the one thing Tumaninah does that nobody else does.

**Blocked, and say so:** notification copy is frozen at `COPY_VERSION = "reel_v1"` (`send-scheduled-notifications/index.ts:29`) until the keep read. The *in-app* surfaces are not blocked; the push channel is. Day One's evidence is that "On This Day" earns its own separately-timed notification because it re-engages people who have **stopped** writing, which no write-reminder can — so the push half is worth scheduling deliberately rather than dropping.

---

## 8. P4 — Name mastery (the founder's pack idea, reframed)

The instinct is right and the framing survives. The pricing model does not.

### 8.1 What Cozy is actually doing, and why not to copy it

Stars are **cash-purchasable** (200/$2.99, 400/$4.99, 1000/$9.99), so ★100/★150 is a **$1.00–$1.50 price rail with a slow free path**, not an earned soft currency. The crown is a real subscription wall on top of it. The documented consequence: users who *bought every trivia pack with stars* still need Plus to reopen quizzes they already purchased and completed.

Showing a currency price on an item that currency cannot buy is a catalogued dark pattern and is under EU consumer-org challenge. And Cozy is the **outlier**: Duolingo charges gems for *convenience* and walls nothing; Finch's own docs state there are no member-only items; Paired, Gottman, Lumosity, Elevate, Hallow, Glorify and Abide run no currency at all. The entire Islamic quiz category — Quran Companion, Pillars, namesofallah.net — is **free**, and Pillars markets not charging as a virtue. There is no demonstrated willingness to pay for Names-of-Allah quiz content.

There is also a specific reason this is worse for us than for them. The CHI 2026 finding: the same virtual reward flips motivational sign by *interpretation* — read as **controlling**, intrinsic motivation drops; read as **informational**, it rises. A currency that *reports* your learning is informational. A currency that *rations access to knowledge about Allah* is controlling.

### 8.2 The reverence rule — the highest-severity finding in the whole research set

Standard multiple-choice pedagogy says build distractors from misconceptions. Applied here that means **authoring plausible falsehoods about Allah and putting four on screen at once.** The Bible-trivia genre already ran this experiment and failed it publicly: wrong answer keys with no report mechanism, an Apocryphal angel name marked correct (a canon dispute encoded as a right/wrong key — the direct analogue to our disputed-Names problem, e.g. *Ar-Rāfiʿ*, which is why namesofallah.net ships 107 rather than 99), and the summary verdict *"shallow on theology — this is trivia, not study."*

**The rule, which is not negotiable and should be written into `CLAUDE.md` if this ships:**

> **Every option on screen is a true Name or a true statement. The stem asks which one *fits*.** A wrong tap means "you picked a less-fitting true Name" — never "you endorsed a falsehood."

Corollaries: no red ✗, no timer, no failure state, **no leaderboard of any kind**, every answer cited to the approved catalog, and **"report this question" in v1, not v2.**

> ⚠️ **CORRECTION, 2026-08-06.** This line previously read *"no correctness leaderboard (rank effort if anything — **Quran Companion's precedent**)"*. That citation was exactly backwards and would have led whoever builds Wave F straight into the failure it was meant to prevent. Quran Companion is not a precedent to follow; **it is the app that crossed the line.** Its own FAQ documents a **Daily Hasanah Leaderboard** — *"The Top 100 Hasanah points will be shown by everyone who is using the app, sorted out by country, and by Facebook friends"*, reset daily — fed by a *"Hasanah Calculator"* that multiplies memorised letters tenfold.
>
> There is a mainstream classical ruling directly against this, and it is the document to end any future points-on-worship conversation with:
>
> - **[IslamQA 247769](https://islamqa.info/en/answers/247769)** — calculating ḥasanāt per letter *in the abstract* is permissible, but **using devices to count your own ḥasanāt is makrūh**. Ibn Masʿūd: *"Is he reminding Allah of his good deeds?"* Two grounds: **acceptance of deeds is of the unseen**, so counting manufactures a false certainty; and the believer must hold hope and fear *together*, not pride in an accumulated number.
> - **[IslamQA 128914](https://islamqa.info/en/answers/128914)** — adopting counting tools *"in order to show off to people, such as **displaying them publicly**, this is either showing off to people or is likely to be thought to be showing off, which is **haraam**… one of the gravest of sins."*
>
> For fairness, the boundary is not "all competition": [IslamQA 156560](https://islamqa.info/en/answers/156560) permits prizes in Qurʾān-memorisation competitions by analogy to archery. The distinction that matters is **a bounded, sponsored competition vs. an always-on public ranking of private worship** — only the second triggers the riyāʾ ruling.
>
> **So: no ḥasanāt counter, no points on ʿibādah, no public ranking, and no "effort" ranking either** — an effort leaderboard is still a public ranking of private worship, which is the thing the ruling names. Verified 2026-08-06: the app ships no such counter today. This note exists so it never acquires one by accident.
>
> Related, from the same research: **Muslim Pro denominates worship as currency** (500 Stars = 1 Crescent, *"rate may change… due to platform fees"*, redeemable against your own subscription), and a user has publicly filed for **reimbursement of un-credited worship points**. That is the reductio. It is a second reason to keep the Noor/token merge deferred rather than inventing anything a user could describe as *earned by praying*. Pack content cannot be AI-authored — `CLAUDE.md` already forbids fabricated scripture, decks need `review_verdict = 'good'` behind a CI ship gate.

### 8.3 Format — designed for the ICP (REWRITTEN after founder direction, 2026-08-02)

**The founder's correction, and it is right:** the quiz must *genuinely test knowledge*. "Which Name did you sit with when you wrote this?" is a memory game about the user's own history — it exercises recall of an event, not understanding of a Name. It was ranked #1 by the research on *cost and safety*, which is a different axis from *learning value*.

**Restate the ICP, because it determines the format.** Our user is someone in the middle of a struggle who is learning the Names *as they bear on that struggle*. So the thing worth testing is not "can you recite the gloss of Al-Wakīl" (recall) and not "what did you write in March" (autobiography). It is:

> **When you are in a state, can you reach for the Name that meets it — and do you know why it is that one and not the neighbouring one?**

That is **application/transfer**, the highest level in the taxonomy and the only one that matches what the product claims to do.

#### The question mix

| Weight | Type | What it tests | Reverence posture |
|---|---|---|---|
| **~50%** | **Situational match** — a one-line human state → which Name meets it | The core skill the product promises | All four options are true Names; the stem asks which *fits* |
| **~20%** | **Near-synonym discrimination, situationally framed** — not "define Al-ʿAfuww" but "you can't stop replaying it; which of these two meets *that*?" | The highest-value distinction for this ICP | Taught on a comparison card **before** it is ever asked |
| **~20%** | **Concept / application** — *tawakkul, ṣabr, shukr, riḍā, muḥāsabah*: "you've been given Ar-Razzāq for money fear — which of these is what tawakkul actually looks like here?" | Whether they know what to *do* with the Name | **Safe to have genuinely wrong options** — these are claims about human conduct, not divine attributes |
| **~10%** | **Reverse recall** — given the Name, which moment is it for | Bidirectional retrieval (Quizlet/Duolingo pattern) | Options are true situations |
| **0%** | Verse identification as a *graded* item | — | Verses appear as **post-answer teaching only**. The AI selects from the approved catalog and never authors; scripture stays on the teaching side of the line, never the scoring side |

#### The mechanic that makes this both rigorous and reverent

Several true Names can defensibly fit one situation. That is a fact about the subject, not a flaw in the quiz — and it is the single most important design decision here.

> **There is no "wrong". There is "less precise".** A tap on a defensible-but-different Name returns *"Also true — here is the difference"* and teaches the distinction. Only a Name with no bearing on the stem returns "not this one", and even then the feedback explains what that Name *is* for.

This does three things at once: it satisfies the reverence rule absolutely (no red ✗ on a Divine attribute, ever), it makes the near-miss the *teaching moment* rather than a failure, and — the part that matters for D6 — **it is a harder and more genuine test than a right/wrong quiz**, because the user is being asked to discriminate between true things rather than to reject false ones.

#### The personalization that only we can build

This is the answer to "journal recall isn't right for our ICP" that keeps the rigour and keeps the moat: **use the journal to *aim* the quiz, never to *be* the quiz.**

We derive `problem_category` on every daily answer — `ProblemChipResolver.forFreeText` / `matchChipKeyForText` keyword-map typed text, so it exists on the typed path too — plus `acquisition_promise.problem_category` from onboarding. So a user whose nights keep clustering on `rizq` is asked more about Ar-Razzāq, Al-Wakīl and Al-Fattāḥ; one clustering on `guilt` gets Al-Ghaffār, At-Tawwāb and Al-ʿAfuww.

Every question is still a real knowledge question with a real answer. What the history changes is only **which** Names get tested — the ones this person's life keeps asking about. No competitor can do this, and unlike journal recall it does not degrade into a memory game.

**Mastery model: 5-box Leitner, and explicitly not FSRS/SM-2.** At 99 hard-capped items a modern scheduler buys nothing, and its 0–5 self-grade is tonally wrong ("rate your confidence in Ar-Rahman"). Four columns — `box`, `last_reviewed_at`, `correct_streak`, `last_result` — surfaced as three states: **learning → reviewing → settled**. A "less precise" answer holds the item in its box rather than demoting it; only a no-bearing answer demotes.

### 8.4 Gating — DECIDED 2026-08-02: premium-only, no currency

**Two gates doing two different jobs.** They are not redundant and both are needed:

1. **Premium gates *access*.** Packs are a subscriber feature. A free user does not see the surface. (Founder decision — this supersedes the earlier "subscription buys depth, not access" recommendation.)
2. **Collection progress gates *readiness*, inside premium.** A subscriber still cannot open the mercy pack before meeting the mercy Names — not as a monetization lever, but because **an assessment over Names you have never met is not an assessment.** Testing someone on Al-Ghaffār before they have ever been given Al-Ghaffār is a vocabulary quiz in a language they have not been taught.

**Noor never touches the Names.** No currency anywhere in this surface. The crown-over-currency pattern is rejected outright — with no price shown, the dark-pattern objection (§8.1) disappears entirely. A subscription is understood as supporting the app; a price tag on a specific sacred item reads transactional. That distinction is the whole reason this is defensible.

#### The free taste pack — AMENDMENT to D3b, recommended

**Yes, ship exactly one free pack — and make it "The Names you've met".**

Not a curated theme, and not a rotating sample. The free pack is drawn from the Names *this user has already collected*. Reasons, in order of weight:

1. **A premium-only feature nobody has experienced cannot convert anyone.** Every comparable does sample: Lumosity/Elevate/Peak rotate free games daily, Paired gives a free question a day, Hallow/Glorify/Abide all sample before subscribing — and even **Cozy, the most aggressive gate in the entire survey, ships two free games.**
2. **It is guaranteed non-empty for everyone**, which solves the empty-room problem in the same stroke — for free users *and* as the premium readiness floor.
3. **It gets better the more they use the daily loop**, so the free taste rewards the exact behaviour we want more of.
4. **It makes the premium pitch honest and concrete:** *"you've been drilling the Names you happen to have met — premium organises them around what you're actually going through."* Mercy, forgiveness, hardship. That is a real difference the user can feel, not a withheld feature.

**Do not rotate it.** Rotation works for a game library; it is destructive for a drill surface carrying mastery state, because a user mid-way through loses their progress when it changes. That reads as a takeaway.

**Depth still splits.** The free pack ships the core situational-match type and visible mastery state. The near-synonym comparison cards, the concept/application layer and the full mastery history stay premium — so "depth, not access" survives *inside* the free pack even though access gates the themed ones.

**⚠️ The failure mode this creates, which must be designed against.** A user subscribes, opens Packs, and finds everything locked because they have not collected enough Names yet. They have paid for an empty room. **Guarantee a floor: the Names met in onboarding plus the first week of reveals must always constitute at least one openable pack**, and any locked pack must state its own condition in plain words — *"opens when you've met 3 more of these"* — with progress visible. A locked pack that does not explain itself is worse than one that is not shown.

**What the free tier still gets, and why this stays honest.** The daily loop is untouched: the nightly question, the reveal, the reflection, the Name, the verses and the duʿā remain free forever (master plan `:522`). Packs are **additive practice over Names already given away for free** — they are not a gate on learning the Names, they are a gate on being *drilled* on them. That sentence is the one that has to stay true, and it is what keeps this on the right side of §8.1's "rationing knowledge about Allah" concern.

### 8.4b Two things the pack design must not collide with

**Mastery is not card tier.** The collection already ranks a Name Bronze → Silver → Gold → Emerald, earned by gacha and scroll tier-ups. Mastery (learning → reviewing → settled) is a *second, orthogonal* axis on the same 99 objects, earned by review. Two progress systems over one object set is exactly how a collection screen becomes unreadable, and worse, a user who has an Emerald card but a "learning" mastery will reasonably ask which one is real.

Rules: **tier is what you own, mastery is what you know.** Never blend them into one score, never let mastery affect tier or the gacha, never let a tier-up imply knowledge. If they cannot be shown clearly side by side on the collection screen, mastery lives only inside the pack surface and does not appear on the card at all — which is the safer v1.

**Packs must not become a third daily obligation.** The app already asks for a nightly muhasabah and holds a streak over it. A review queue that also nags daily creates a second streak the user can fail, and the research is explicit that unbounded obligation is what makes these systems feel punitive. The review queue should be *available*, never scheduled, with no streak of its own and no notification in v1.

### 8.4c Instrumentation, stated up front

Per `CLAUDE.md` this is one funnel segmented by super-properties — do not fork existing events. New surfaces need their own clean funnel from day one, because §2 of the W4 spec established that within-wave instrumentation has to carry the weight when cohort attribution is coarse:

- `pack_opened{pack_id, unlock_state}` → `pack_review_started` → `pack_review_completed{items_seen, items_settled}`
- `pack_unlocked{pack_id, names_owned, names_required}` — the progress gate's own conversion
- `mastery_state_changed{name_id, from, to}` — the only way to tell learning from guessing
- `question_reported{pack_id, question_id}` — must exist in v1 (§8.2)
- Journaling: `journal_entry_created` already exists and must **not** be forked — add a `source` property (`reflect` | `muhasabah`) rather than a new event name.

**Four practical issues with adding instrumentation to these features** (founder asked, 2026-08-02):

1. **Do not fork existing events.** `journal_entry_created` gets a `source` property, not a sibling event. `check_in_completed.path` stays `'discover'` — it is the D1/D7 retention spine and changing it breaks every historical comparison.
2. **The free-text guard cannot see new state fields, and this is the real trap.** `no_free_text_reaches_analytics_test.dart` catches `.text` on a *controller*, but once free text lands on state it looks like any other field — which is why the guard carries an explicit list, currently `['duaTopicsOther', 'intakeNote', 'firstProblemText']`. The journaling work introduces new free-text state (the thread append, any draft field). **Every new one must be added to that list in the same PR**, or the guard passes while the leak ships. The guard's own history is the argument: it was written to catch exactly this and initially had the defect it existed to catch.
3. **Volume.** A drill surface can emit one event per question, which is expensive and noisy at scale. **Aggregate at session level** — `pack_review_completed{items_seen, items_settled, less_precise_count}` — and keep per-question events behind a debug flag only.
4. **New events have no history, and under D5 that matters more.** Per the analytics doc, new events only populate post-release, so every funnel added here starts at zero at T0 and is **absolute, not comparative** — there is no pre-side for them. Two consequences: the T0+24h super-property coverage check must be extended to cover them, and the durable super-property set must be re-verified against the new callers (it was evicted by its own second caller once already, fixed in `054e5b5`).

No issue with the economy events — with no currency in this surface, `noor_earned` and the cosmetics family are untouched.

### 8.4d The story-deck build-out — scale the existing pipeline, do not invent one

**Founder direction 2026-08-02: author all 99 Names' decks via agents, then build the packs on top.** The good news is that this process already exists and has shipped once — 7 pairs / 14 decks, on 2026-07-25/26.

**What is already in place (do not re-derive it):**
- A format protocol: `docs/superpowers/specs/2026-07-25-name-stories-deck-format.md`
- Seven approved deck-draft documents in `docs/superpowers/content/decks/`, each carrying a **Sources table** (`Claim | Source | Status`) with per-claim verification
- The established provenance discipline, quoted from the anxiety pair's header: *"All sources verified at draft time (quran.com live-fetch; sunnah.com via Wayback archives of the exact URLs). Scripture quoted exactly from the verified pages; story beats paraphrase only what the cited source carries."*
- An independent adversarial review already applied once (v2 folded in all blockers)
- Founder sign-off recorded in each header
- A CI **ship gate** — `test/content/name_stories_ship_gate_test.dart` — that makes an unapproved, malformed or scripture-unsafe deck a **build failure**, and whose own comment records that it *"checks structure and safety invariants, never rewrites content"*

**So the task is scaling 14 → 99, not designing a pipeline.** Remaining: ~85 decks.

#### The one thing that will not work as described

**Decks cannot ship independently of the app.** `name_stories_service.dart:14-30` is explicit: *"Asset-only by design: there is no `name_stories` table"* — decks are bundled in the IPA. Five other content types *are* server-delivered through `PublicCatalogKeys` (daily questions, browse duʿās, discovery-quiz questions, name anchors, collectible names), so the pattern exists — but adding decks to it **moves them out from behind the CI ship gate**, because that gate is a build-time test over the asset. Server rows would become publishable without ever passing it, on the highest-risk content in the product.

**Recommendation: keep decks as an asset and ship them in app releases, in batches.** The build-time gate is a feature here, not friction. If independent shipping is genuinely required later, it needs a server-side equivalent of the ship gate *first*, and that is a separate piece of work with its own review.

#### The failure mode the agent pipeline must be built against

**Two LLMs agreeing is not verification — it is the same prior twice.** Fabricated hadith is a known and specific model failure: plausible text, plausible isnād, plausible-looking Bukhari number. An LLM reviewer will frequently accept one, because it generates from the same distribution that produced it. A "review agent" that exercises judgement over a quotation is therefore **not** a safeguard.

Binding rules for the pipeline:

1. **Agents retrieve and cite; they never compose scripture.** This is `CLAUDE.md`'s standing rule (*"NEVER fabricate Quran verses, hadith, or scholarly content"*), and the existing decks already honour it — narrative framing is authored, scripture is copied from a fetched page.
2. **Verification is mechanical before it is judgemental.** Every scripture claim must resolve to a live fetch of the exact canonical URL (quran.com / sunnah.com) and match by text, not by an agent's assessment. A quote that cannot be matched against a retrieved canonical page **fails automatically**. This is what the 2026-07-25 batch did; make it mandatory rather than conventional.
3. **Tier the sources.** Qur'an and canonical collections are authorities for *text*. Yaqeen Institute and similar are authorities for *framing and context only* — a Yaqeen article may never be the citation for a hadith; cite the collection. Conflating the two is the subtle form of the Bible-trivia canon failure (§8.2).
4. **Record the grading.** Only ṣaḥīḥ/ḥasan for anything presented as prophetic narration. The existing sources tables already annotate `(sahih)` — formalise it as a required column.
5. **Reviews must be adversarial and blind.** Reviewers are told to *refute*, and are not shown the prior verdict. Batches of 5 are fine; confirmation-shaped review of agent output is rubber-stamping.
6. **A human still signs (D7).** Agents produce a **review packet** per deck — claim → source → exact citation → grading → link → verification status — and the named reviewer signs the packet. That is what makes 85 decks tractable for a human without removing the human.
7. `./scripts/check_no_fake_strings.sh` runs before any release carrying new decks.

**Sequencing note:** deck authoring is the long pole and it is *content*, not engineering. It does not block P0–P3, and under D5 the pack surface ships dark behind a dial and lights up when reviewed decks land.

### 8.5 What else is worth quizzing — and the best idea in the whole document

Ranked by the research: **#1 is recall over the user's own reflection history** — *"which Name did you sit with when you wrote this?"* Near-zero content cost, **zero reverence risk**, and no competitor can ship it because no competitor has the data. It is also the Paired gated-reveal mechanic transplanted to a solo app, with your own past self as the other party.

Note what that means for sequencing: **the strongest quiz idea is unlocked by P0, not by the taxonomy.** It needs no scholar review and no new content. Then, in order: situational Names, duʿās the user built, and Islamic vocabulary (*tawakkul, ṣabr, shukr, muḥāsabah*) — which is underrated precisely because these are *concepts*, so ordinary MCQ pedagogy applies cleanly and false distractors are permissible there.

### 8.6 What it costs us

**Engineering is the short pole; content is the long one.**

Reusable: the **cosmetics stack is ~90% clonable in shape** — `cosmetic_catalog` + `user_cosmetics` + idempotency ledger, the `unlock_*` RPC pattern (row-locks the profile, server-owned price, already-owned = no charge), RLS shape, the GUC write-guard, the grid/tile/badge UI, and the two pure resolvers in `wardrobe_screen.dart:34-89` worth stealing verbatim. The **discovery quiz** is the other big asset: `QuizOption{text, Map<String,int> scores}` / `QuizQuestion` / `AnchorResult` (`core/constants/discovery_quiz.dart:10-45`), an 18-question public-catalog pipeline with row validation, and a full paged runner with segmented progress and animated option cards.

Net new: `content_pack_catalog` + `user_content_packs` + a pack↔Names join, an unlock RPC, RLS, a `packs` union on `sync_all_user_data`, pgTAP, a service, a provider, two screens, a route, analytics constants, tests. Roughly **1–2 migrations + 1 service + 1 provider + 2 screens.**

Two gaps to name honestly:
- **No theme taxonomy over the 99 Names exists.** Nearest seeds: the 7 problem chips (`problem_chips.dart:85-132`), the discovery-quiz score map, and — interestingly — **dormant `text[]` tag columns that have existed since the initial migration with zero client readers**: `names_of_allah.emotions`, `name_teachings.emotional_context`, `name_guidance.call_for`. Building the taxonomy is a **scholarly content task**, not an engineering one.
- **Only 14 of 99 story decks exist.** Pack depth is gated on authored content that must pass review.

---

## 9. Monetization — one idea worth taking, one worth refusing

**Refuse:** the dual gate. See §8.1.

**Consider (carefully):** *free ritual, rented archive.* Cozy's strongest converter is "unlimited history" and it maps cleanly onto what P0 creates. It is also arguably a **better free tier than what we ship today** — a hard 5-entry lifetime cap is worse than a rolling window, because it stops you writing, whereas a window only stops you re-reading.

But the honest risk is exactly Cozy's: **retrofitting a window onto people who already have entries produces their angriest reviews.** Any user with saved reflections older than the window would experience a takeaway. If this is done at all it should be *paired with lifting the 5-entry cap* so the trade is visibly a give-and-take, and it must never touch muhasabah entries in a way that breaks the "free forever" promise on the daily match. §11 D3.

---

## 9A. The free journal cap, re-analysed

Prompted by the founder's question: *"I thought we changed it so that across everything weekly it is 3?"* — that is correct, and it is a **different gate**. There are two independent rations on the same behaviour, and they were designed two months apart against different models.

### What is actually live

| Gate | Value | Where | Shipped |
|---|---|---|---|
| Lifetime warmup, `reel_v1` | **3** reflect · **3** built-duʿā · **3** discoverName | `warmup_*_size` dials, seeded `20260727100200` / `20260731090000` | W5, July |
| Combined weekly pool, `reel_v1` | **3** Reflect + Build-a-Duʿā *together*, per week | `weekly_pool_size` = 3, `consume_weekly_allowance` | W5, July |
| Daily reveal | 1st/day free and **ungated**; re-rolls premium-only | `daily_loop_provider.dart:1559-1598`, `GateReason.rerollPremium` | W5 |
| **Journal save cap** | **5 reflections lifetime · 5 built duʿās lifetime** | `reflect_provider.dart:877,887` · `duas_provider.dart:699,707` | **May, unchanged** |

The first three are *how often you may generate*. The fourth is *how many you may keep*. Only the fourth predates W5, and it was never revisited when W5 replaced the generation model.

### What a free `reel_v1` user actually experiences

Reflect-only path: uses 1–3 are warmup → 3 saved. First post-warmup week: uses 4 and 5 → 5 saved, cap reached. **Use 6 generates a reflection, displays it, and never saves it.** That lands roughly **day 8–12**.

Steady state after that: **3 AI uses per week ≈ 156 per year, of which 5 may ever be kept.** The journal is a five-slot museum, filled in the first fortnight and frozen for life.

### The part that is actually wrong

`markUsed` — which spends the weekly-pool use — fires at `reflect_provider.dart:830`. `_saveReflection` runs at `:847`, **after**. So a capped user spends one of their three weekly uses, receives the reflection on screen, and loses it when they leave. The upsell is at least shown politely and at the right moment (`UpgradeRequiredSheet` is deliberately deferred until the user lands back on the input screen, `reflect_screen.dart:161-173` — "NEVER surface it over the beat canvas mid-ritual"). But the artifact is still gone, and the allowance is still spent.

**Rationing the same behaviour twice means the second ration only destroys output the user already paid for.** Under the old model (daily cap, warmup 10) the scarcity was in *keeping* and the 5-cap was a real lever. Under W5 the scarcity moved to *generating*, and the 5-cap stopped being a lever and became a leak.

### A discrepancy worth naming

`app_strings.dart:236-239`, written 2026-08-01, justifies removing the journal bullet from the paywall:

> *"Bullet 3 promised the journal. `lib/features/journal/` contains no GatingService reference, no premium check, and no row cap: the journal is unlimited for everyone."*

That audit checked the **reading** surface and is correct about it. The cap lives in the **writing** path — `reflect_provider._saveReflection` — which is not in `lib/features/journal/`. So today: browsing is unlimited, *accumulating* stops at 5. Removing the cap would make that sentence true as written, and keep the paywall's new frequency-based framing coherent.

### Recommendation

**Remove the save cap; let the weekly pool be the single gate.** `_saveReflection` and its Build-a-Duʿā twin always save.

- **Cost:** rows. Nothing else.
- **Conversion cost: ~zero.** The paywall no longer claims the journal, by the founder's own 2026-08-01 rewrite; premium's stated differentiator is now *frequency*, which the weekly pool already enforces and which this does not touch.
- **Benefit:** every one of a free user's three weekly uses yields something keepable; the archive becomes worth building at all; and P0's nightly entries make it genuinely alive rather than a 5-slot relic.

*If a lever must be kept*, the minimum fix is to **check the cap before consuming the allowance**, not after — so a blocked user keeps their weekly use. That is strictly better than today regardless of which way the main decision goes.

---

## 9B. Should the packs cost tokens? — no, and the reason is the opposite of the problem

Prompted by the founder: *"tokens do not do anything… if we do not use tokens then tokens are essentially useless."* The premise is right. The conclusion inverts the fix.

### Do the three currencies serve different purposes?

| Currency | Only sink | Earned from | Cash SKU |
|---|---|---|---|
| **Tokens** | streak restore (100/250/500) + the 25-token AI bypass, *which is scheduled for deletion* | quests, daily rewards, XP, streak milestones, IAP | yes — 100/250/500 |
| **Scrolls** | card tier-ups (5/10) | quests, rewards | yes — 3/10/25 |
| **Noor** | lantern skins & backdrops (120–300) | daily muhasabah (10), streak milestones (40–400) | not yet (`kSkinIapEnabled=false`) |

**Different sinks, not different purposes.** The usual reason to run two currencies is a hard/soft split (paid vs earned) — but tokens *and* scrolls are both earned *and* cash-purchasable, so that isn't what's happening. These are three parallel single-purpose currencies, which is precisely why none of them is liquid. Scrolls aren't even really a currency: `tier_up_scrolls` is a **column on `user_tokens`**.

The deadness is measured, not assumed: **348,024 tokens outstanding across 1,362 accounts; 2,775 ever spent, by 31 users — 0.8% of everything ever minted.** Noor: 1 holder, 30 units. The merge plan's diagnosis is correct and this analysis does not change it.

### Five reasons packs must not be a token sink

1. **Tokens are scheduled for deletion.** The merge converts 12 SECURITY DEFINER functions and retires the Store SKUs. Building a pack economy on tokens means building it and re-pointing it at Noor weeks later — adding work to a subsystem that is being torn down.
2. **There is no scarcity to trade on.** ~255 tokens per holding account. At any price, existing users buy the entire catalogue instantly and the "purchase" means nothing; price it high enough to matter and it becomes a wall for new users who start near zero. The same number cannot be both.
3. **It reproduces the Cozy complaint, in a faith app.** A visible currency price plus a premium crown on religious content is exactly the pattern whose review evidence we gathered. The CHI 2026 finding is the sharp form: an identical reward reads as *informational* (it reports your learning) or *controlling* (it rations access) depending on framing — and a currency gating knowledge about Allah is unambiguously the controlling read.
4. **It competes with the mechanic that works.** Unlock-by-collection-progress makes the *nightly practice* the thing that opens a pack — a sink for effort we want more of, rather than for a currency nobody values.
5. **It drags packs behind the merge.** The merge is deliberately deferred to the softener wave (post keep-decision) because a currency change inside the conversion measurement window pollutes the read, and because it shares functions with the bypass deletion. Bind packs to a currency and packs inherit that gate.

### So what *does* fix "tokens are useless"?

**The merge does, and that is the whole answer.** Tokens become Noor; Noor already has a real, on-brand sink in cosmetics and self-expression. Inventing a content sink to give a currency a job is building the product around the economy instead of the other way round — and the sink it would invent is the one place in the app where a price tag is most likely to read as selling religion.

If a currency dimension on packs is wanted anyway, the safe shape is: **Noor buys expressive things *around* the practice** — a mercy-themed lantern skin unlocked alongside the mercy pack — and never the pack content itself. Currency touches cosmetics; practice touches knowledge.

### Two nuances on the merge's timing

The TODO's reasoning for deferring to the softener wave is sound and I am not arguing with it. Two things worth adding:

- **The backfill exposure only grows.** The ~704,000 Noor giveaway is a 2026-07-31 snapshot, and balances keep minting from signup grants and daily rewards. That is an argument for the *earliest* point the trigger allows, not the latest.
- **The two open decisions don't need the wave.** Whether scrolls fold in, and the conversion rate, can be *decided* now at no cost — only the *execution* needs the wave. Deciding early de-risks it and removes an item from the critical path of a wave that is already carrying the notice, the cohort migration and the bypass deletion.
- **Packs, as recommended here, create no new dependency on the merge.** Unlock-by-progress touches no currency at all. That is a feature: the two workstreams stay decoupled.

---

## 10. Sequencing — the T0 problem

**T0 has not happened.** 1.3.0 build 9 is `IN_BETA_TESTING`, beta review APPROVED, distributed to the external group — but the App Store release, the pre-T0 baseline snapshot and `t0_flip_all_to_reel_v1.sql` are all still open items in `TODO.md`. The one-change-at-a-time freeze binds between **T0 and the T0+6wk keep decision**, because the ship's read is pre/post with no control arm.

Recommended reading of that:

**DECIDED 2026-08-02 (D5): build all of it now, then run the pre-ship T0 checklist.** Everything lands in one release, before T0.

| Work | Status under D5 | Note |
|---|---|---|
| **P0 (persist) + the cap fix** | In the ship. **Do these first.** | Persistence is the only item whose delay is unrecoverable — every unsaved night can never be resurfaced. |
| **P1, P2** (completion screen, thread, time machine, archive, story format, calendar) | In the ship | |
| **P3 in-app resurfacing** | In the ship | |
| **P3 push notifications** | **Still blocked** | `COPY_VERSION = "reel_v1"` is frozen until the keep read. This is not a sequencing preference; it is a separate standing freeze. The in-app half ships; the push half does not. |
| **P4 packs — engineering** | In the ship, behind a dial, shipped dark | |
| **P4 packs — content** | **Gated on D7's reviewer**, not on engineering | See below. |

**Two things this decision costs, stated plainly so nobody rediscovers them at the keep read:**

1. **Attribution is now effectively gone at the component level.** The read was already coarse — it could not separate the paywall from W4's loop change. Adding journaling and packs makes "which part worked" unanswerable from the cohort read alone. **Consequence: the within-wave funnels in §8.4c stop being nice-to-have and become the only instrument that can tell you anything.** They must ship complete, or this release teaches us nothing about itself.
2. **P4's content cannot be compressed by engineering effort.** The theme taxonomy does not exist, needs a citable published classification and a named reviewer (D7), and only 14 of 99 story decks are authored. "Build it now" is achievable for the *engineering*; the *content* ships when it clears review. **Recommended shape: build the pack surface now behind an `app_config` dial, ship it dark in the same binary, and enable it server-side when the first reviewed pack is ready** — no second release needed, no pressure to lower the content bar to hit a date. That pressure is exactly what produces the §8.2 failure.

Everything user-facing ships behind its own dial regardless, so any piece can be turned off without a build.

**Unchanged by this decision:** the pre-T0 baseline snapshot in `TODO.md` bucket 3 is still mandatory and still unrecoverable if missed — and it now matters *more*, because a bigger ship makes the "pre" side of the comparison the only clean number left.

Everything user-facing should ship behind its own `app_config` dial — the service already supports this properly, including `hasCachedValue` so a kill switch does not act on a fallback on first install (`app_config_service.dart:83-88`).

---

## 11. Decisions — ALL RESOLVED, founder, 2026-08-02

| | Decision | Resolved |
|---|---|---|
| **D1** | The nightly muhasabah **becomes a saved journal entry** (option A) | 2026-08-02 |
| **D2** | **Store the text server-side under RLS** (option A), with export / delete-one / delete-all shipped in the same release | 2026-08-02 |
| **D3** | **Remove the 5-entry save cap** (option a); the weekly pool is the single gate | 2026-08-02 |
| **D3b** | **No currency on packs** — *and* packs are **premium-only**: a free user cannot see or use them. Collection progress still gates *readiness* inside premium (§8.4) | 2026-08-02 |
| **D4** | **No tags in v1** (option A) | 2026-08-02 |
| **D5** | **Build all of it now**, then run the pre-ship T0 checklist. Everything lands in the same release — see §10 for the one place this collides with reality | 2026-08-02 |
| **D6** | Proceed (option A): write the course-vs-review-surface distinction into `CLAUDE.md`. **But the quiz must genuinely test knowledge** — journal recall alone is not enough for our ICP; see the rewritten §8.3 | 2026-08-02 |
| **D7** | **Named external reviewer + a cited published classification** (A + C); no authoring begins before the reviewer exists | 2026-08-02 |

The rationale for each is preserved below as written before the decision, so a later reader can see what was traded away.

---

### The original options and reasoning

### D1 — Does the nightly muhasabah become a saved journal entry?

**At stake:** everything else. P1's time machine, P2's archive, P3's resurfacing and P4's journal-recall quiz all read from rows that do not exist today.

**Options.** **(A)** Write one row per night on `completeDeeper()`. **(B)** Leave the day blob alone and build journaling over Reflect entries only.

**What (B) costs:** the Journal keeps showing only Reflect entries and duʿās — for a free `reel_v1` user, at most 5 + 5 objects in a lifetime. 69% of monthly openers complete a check-in and would still produce **zero** rows, so every resurfacing mechanic is dead on arrival and the original complaint ("the Journal doesn't show the muhasabah") is unfixable by construction rather than by omission.

**What (A) costs:** one migration, one write, one sync union, tests. Blast radius is the freemium-guard triggers and `sync_all_user_data` ordering — both known tripwires, neither novel.

**Recommend (A), strongly.** It is the cheapest item in the plan and the precondition for every other one. The only thing that should change this is D2 going the other way.

---

### D2 — Is server-side storage of muhasabah text acceptable?

**At stake:** cross-device journaling, all resurfacing, and a policy posture on confessional content.

**The facts, so this is decided on the real constraint.** The "answer text NEVER leaves the device" rule is **analytics-only** — the guard sweeps `track` / `setUserProperties` / `onAnalyticsEvent` and nothing else (`test/services/no_free_text_reaches_analytics_test.dart:59-74`). The app already stores typed text server-side under RLS in `user_reflections.user_text` and `user_profiles.first_problem_text`. So (A) below is not a rule violation. **But** muhasabah is self-accounting by definition — users may write about sin — and that is a genuinely higher sensitivity bar than "how do you feel today".

**Options.** **(A)** Store it under RLS exactly as Reflect does. **(B)** Store *structure* server-side (Name, date, beats) and keep the raw text device-local. **(C)** Keep everything device-local (status quo).

**What (B) costs:** it is the worst emotional outcome — the archive exists on every device but the user's own words vanish on reinstall or a new phone, so the shell of a memory survives without the memory. It also kills the same-prompt time machine, the highest-ranked mechanic in the research.
**What (C) costs:** there is no journaling product.

**Recommend (A)** — with the user-facing controls shipped in the *same* release, not deferred: export, delete-one, delete-all in Settings, and one plain sentence in the privacy policy. The text still never enters telemetry.

**One strategic caveat.** Tumaninah positions device-only, no-account privacy as its whole identity. If privacy is meant to be a *marketing* claim for Sakina, (B)/(C) become a positioning choice rather than a caution — but that is a founder call about what the product is, not a technical constraint, and it should be made deliberately rather than by inheriting the status quo.

---

### D3 — The free-tier shape for the archive

**At stake:** whether a free user's journal is worth building at all. Evidence in §9A.

**Options.** **(a)** Remove the 5-entry save cap; W5's weekly pool becomes the single gate. **(b)** Keep the cap but check it *before* consuming the weekly allowance. **(c)** Replace it with a rolling history window (Cozy's model).

**Recommend (a).** The cap was written in May, when scarcity lived in *keeping*; W5 moved scarcity to *generating*, so the cap now only destroys output the user already spent an allowance on. Cost to us is rows. Cost to conversion is near zero, because the paywall already stopped claiming the journal and now sells frequency — which the weekly pool still enforces untouched.

**(b) is the floor.** If (a) is refused, do (b) anyway — a blocked user keeping their weekly use is strictly better than today under any policy.

**(c) is a later decision, not this one.** It is the strongest converter in the research, but it only makes sense once the archive is full of nightly entries and worth renting — and Cozy's evidence is that *retrofitting* a window onto existing entries is what produced their angriest reviews. If it is ever done, apply it only to entries created after the change, and pair it with lifting the cap so the trade is visibly two-sided.

Under all three, muhasabah entries stay uncapped — that is not part of this decision.

---

### D3b — Do the packs use a currency at all?

**At stake:** whether the pack feature inherits the currency merge's timeline and the "selling religion" read.

**Options.** **(A)** No currency — unlock by collection progress. **(B)** Noor price. **(C)** Token price.

**(C) is out** on five independent grounds (§9B): tokens are scheduled for deletion, there is no scarcity to trade on at ~255 tokens per holding account, it reproduces the documented Cozy complaint, it competes with the progress unlock, and it drags packs behind the merge.
**(B) is coherent but weaker** — it still binds packs to the merge's timing and still carries the "currency rationing knowledge about Allah" reading that the CHI 2026 controlling/informational finding warns about.

**Recommend (A).** The daily practice is what opens a pack; premium sells depth inside it.

**What would change my mind:** if authored pack content turns out to be genuinely expensive per unit (scholarly review, authored decks), there is a legitimate argument that packs are premium *content*. Even then the answer is subscription-gated depth — not a currency.

---

### D4 — Tags or moods on entries

**At stake:** forking the segmentation vocabulary, which W4 already ruled on once.

**Options.** **(A)** No tags in v1. **(B)** Reuse the 7 problem chips. **(C)** A new tag vocabulary.

**(C) forks segmentation** away from `acquisition_promise.problem_category` and makes the daily loop incomparable to onboarding — W4 §9 already rejected exactly this when it declined the 30-question option bank.

**(B) is a trap, and I am sharpening an earlier recommendation here.** The chips are *problem* framings ("I keep sinning and going back", "Everything feels heavy"), while W4 deliberately made the daily question **valence-neutral** — *"A worry, a thanks, a question."* Tagging a grateful entry from that prompt with a problem chip is wrong, and it would quietly re-import the presupposed-burden failure W4's copy decision exists to prevent.

**Recommend (A) — no tags in v1.** The research's enthusiasm is for *not ending on Save*, and P1 already satisfies that with the time machine and the ʿazm line. If a tag step is wanted later, it needs a small purpose-built valence-neutral vocabulary designed as a deliberate second taxonomy, with the segmentation cost accepted explicitly.

---

### D5 — Sequencing against T0

**At stake:** attribution quality versus six weeks against the largest leak in the funnel (D0→D1 return, 31%).

**Options.** **(A)** Ship P0 + the cap fix pre-T0; hold P1/P2 for the keep decision. **(B)** Fold P0 + cap fix + P1 + P2 into the ship. **(C)** Everything waits for the keep decision.

**Recommend (A) — and treat the P0 half as urgent rather than merely permitted.** This is the non-obvious part: **persistence is the one item whose delay is unrecoverable.** Every night that passes without saving is a night that can never be resurfaced later. Ship P0 before T0 even if literally nothing else ships, and by the time P1/P2 land after the keep decision there is already months of history for the time machine and "On This Night" to draw on. Delay P0 and those features launch into an empty archive and take another quarter to become good.

P1/P2 are genuine judgement. (B) buys speed against the biggest leak at the cost of a keep read that already cannot separate the paywall from W4's loop change — a third change makes "which half worked" close to unanswerable. (C) is defensible but leaves the leak for six more weeks. Given the read is already coarse, I would not fight hard against (B); I would fight hard against delaying P0.

---

### D6 — The "What NOT to build" collision

**At stake:** whether P4 is building something the project has already said no to. `CLAUDE.md` lists *"Multi-day courses or guided plans"* as out of scope.

**The distinction that would make packs legitimate:** a course is **scheduled instruction you enrol in and can fall behind on**. A pack as designed is an **always-available review surface over Names you already collected** — no enrolment, no schedule, no deadline, no completion state you can fail. §8.4b already forbids the daily obligation and the second streak, which are precisely the things that would turn it into a course.

**Options.** **(A)** Write that distinction into `CLAUDE.md` and proceed. **(B)** Treat the ban as binding and drop P4. **(C)** Narrow P4 to the journal-recall quiz only.

**Recommend (A) if the distinction genuinely holds for you — with (C) as a strong fallback.** (C) is more attractive than it first looks: the journal-recall quiz ranked highest of every candidate, needs no taxonomy, no scholarly review and no authored content, and is unambiguously not a course under any reading. Whichever way this goes, it must be written down, or the next person to pick this up hits the same wall and re-litigates it.

---

### D7 — Who reviews the pack content?

**At stake:** P4's critical path. Without a named reviewer it has none.

**The facts:** the existing bar is `review_verdict = 'good'` behind a CI ship gate; only 14 of 99 story decks exist; content cannot be AI-authored and scripture cannot be fabricated. The taxonomy itself — *which* Names constitute "mercy" — is a scholarly claim, not a product one. And the disputed-Names problem is real: namesofallah.net ships **107**, not 99, because the enumeration is itself contested.

**Options.** **(A)** Retain a named external reviewer before any authoring begins. **(B)** Founder reviews. **(C)** Anchor the taxonomy in an existing published classification and cite it.

**(C) is underrated** — using a recognised, attributed classification moves the dispute off us and gives every grouping a citation, which is also the honest thing to do. It does not remove the need for someone to verify the mapping and the questions.

**Recommend (A) + (C) together**, and **do not start authoring until the reviewer exists.** Content is the long pole for P4 regardless; unreviewed content on this subject is worse than no content, because the failure mode (§8.2) is a one-shot reputation loss in a community that talks to itself.

---

## 12. Top risks

1. **The journal save cap.** It already costs free users a weekly allowance for nothing from ~day 8–12 (§9A), and if P0 is done naively it would extend that to the nightly muhasabah. Fix the cap first; P0 second.
2. **"You got Allah wrong."** A red ✗, a false distractor, or an answer key taking a side in a scholarly dispute. One-shot reputation loss in a community that talks to itself, and no A/B test warns you first. §8.2.
3. **Economy fragmentation.** Tokens are provably inert — 348,024 outstanding, 2,775 ever spent, 2.3% of users have ever spent one. Adding a *fourth* purchasable category to an economy whose main currency is 99.2% unspent treats catalogue thinness as the problem when the evidence says the problem is fragmentation. Full argument in §9B; this is the strongest reason for unlock-by-progress over unlock-by-currency.
4. **The content treadmill.** The corpus is hard-capped at 99. If new packs are the reason to keep subscribing, month four is empty — and the pressure to invent content pushes straight into risk #2. Make the recurring value the **review schedule and the user's own history**, which regenerate forever.
5. **Retrofitting a history window** reproduces Cozy's worst reviews. §9.
6. **Merge pressure on `daily_loop_provider.dart`** — it is already the hot file across waves, and P0/P1 both touch it.
7. **Migration ordering on `sync_all_user_data()`** — it has collided once already; any new union must be a superset of the latest definition.

---

## 13. What I could not verify

- Whether the founder intends 1.3.0 to release imminently — the whole of §10 turns on T0's actual date, which is not derivable from the repo.
- Cozy's crown gate rests on **user reviews, not first-party documentation**; Cozy publishes no FAQ on pack mechanics. Pack counts, cadence and per-pack question counts are unpublished; the ~10-question turn-based loop is genre convention, not confirmed.
- Cozy's composer UI is INFERRED — no public screenshot exists.
- How We Feel's post-log "regulation strategies" flow (three sources returned 403) — a strong "now what" pattern whose current shape is unconfirmed.
- No public retention numbers exist for Stoic, Day One, Rosebud, or any Islamic app. Only Finch and Duolingo are quantified.
- I ran no tests and no simulator for this document; every claim about our code is read from source at the current HEAD, with `path:line` given so it can be checked.
