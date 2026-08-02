# Day-open loops in comparable apps — external research

Research date: 2026-07-29. For Sakina (problem-first Islamic spiritual wellness app).

> **Provenance.** Commissioned alongside
> [`2026-07-29-daily-loop-internal-audit.md`](./2026-07-29-daily-loop-internal-audit.md);
> together they are the evidence base for
> [`../superpowers/specs/2026-07-30-daily-loop-asks-design.md`](../superpowers/specs/2026-07-30-daily-loop-asks-design.md).
> Read the "Where the evidence is thin" section at the bottom before quoting any
> number from this document — several of the load-bearing claims are design
> precedent, not measurement, and they are labelled as such.

**Evidence labels used throughout:**
- `[P]` **Primary, verified** — I fetched the app's own support doc / App Store listing / the paper itself.
- `[S]` **Credible secondary** — teardown, review, or search-surfaced summary of a primary source I did not open.
- `[I]` **Inference** — my reasoning, not a finding.

**Method note / limitation:** the session's web-search budget was exhausted partway through (shared across agents), so the later apps were covered by direct fetches of App Store listings and support docs rather than by teardown hunting. Apps I could **not** verify and have therefore left thin or omitted: **Ahead**, **Bearable**, **Pray.com**, **Headspace's "Today" tab** (404s / no primary source reached). I have not guessed their flows.

---

## 1. Day-open patterns in comparable apps

### The taxonomy that emerged

Four day-open archetypes, and the distribution is lopsided:

| Archetype | What the first 5 seconds are | Apps |
|---|---|---|
| **A. Dashboard / content home** (dominant) | A screen of options or carousels; user chooses | Calm, Insight Timer, Muslim Pro, Hallow, Headspace, Daylio (grid+chart), Bearable |
| **B. One clear next step** (a path, not a question) | A home screen engineered so exactly one thing is obviously next; still one tap | Duolingo, Glorify, Finch |
| **C. Verdict-first** | The app tells you something about yourself *before* asking anything | Oura, Whoop |
| **D. Question-first** | The app opens into a check-in | **Stoic only** (and it's a toggle) |

**The single most important finding for Sakina: almost nobody opens into a question.** Of the apps I could verify, exactly one — Stoic — auto-opens into a check-in, and it ships it as a user-controllable setting rather than a law of the app. Everything else earns the question with one tap from a home screen that makes the question unmissable.

### Per-app detail

**Stoic `[P]`** — the only true question-first day-open. Its help centre: "Each time you open stoic, you'll start with a quick mood check-in." Critically, this is **optional and configurable** via *Your Profile → Appearance → Track Mood on Launch*. After the check-in the user lands on a home screen offering "Daily Check-In" or "Morning and Evening Reflections". The docs do **not** state that the mood answer changes subsequent content — so it looks like a log, not a fork. (Source: help.getstoic.com, Daily Journaling Flow.)

**Duolingo `[P]`** — day-open is a **path**, i.e. archetype B. Duolingo's own blog (6 May 2022, "new Duolingo home screen design") frames the redesign around learner uncertainty: they "often hear from learners that they're not sure whether they're using Duolingo the 'correct' or 'best' way", so the fix was "a clear path to follow — so you can be confident that each step you take in Duolingo is truly the best step". Note what this *is not*: it is not auto-entry into a lesson, and Duolingo never claims it removed choice — it removed *doubt about which choice*. First interaction = tap the next node. No question is ever asked. `[I]` This is the "unmistakable centre of the app" pattern the founder wants, achieved without a question and without hijacking.

**Finch `[P]`** — home screen is the pet plus today's activity list; the day's core action is a "quick mood check". App Store copy: "start mornings with quick mood checks and energize your pet to go exploring" and "end days in moments of gratitude". Two things matter here: (a) the check-in is one card among the day's tasks, tapped from home, not forced; (b) **the reward flows from the work** — the mood check *energizes* the pet, which then goes adventuring. `[S]` Skipping a task is allowed and the app then invites a reflection on *why* you skipped — friction is converted into content rather than punished.

**How We Feel `[S]`** — main screen shows a check-in prompt; tapping opens the Mood Meter: a four-quadrant valence×energy grid (red = high-energy unpleasant, blue = low-energy unpleasant, yellow = high-energy pleasant, green = low-energy pleasant) with 100+ emotion labels. All subsequent steps (tags, notes, voice memo) are **optional**, advanced by swipe or arrow; there's a **long-press quick-save** that bypasses the steps entirely. Built with the Yale Center for Emotional Intelligence. Post-check-in, users are "given the opportunity to explore strategies to feel the way they want to feel" — so the answer does branch into content, though one teardown of the wireframes says the flow simply returns to the main screen `[S]`, which means the branch is offered, not forced.

**Daylio `[S]`** — the purest low-friction case: "keep a private journal without having to type a single line", **two taps** (5-point mood scale, then activity icons). Positioning is explicitly about removing the excuse not to check in "even on the worst days when opening a blank journal page feels impossible". Day-open is a log grid/stats dashboard; the answer is logged and later surfaced as correlations, not used to change the next screen.

**Reflectly `[P]` (App Store copy)** — claims adaptive questioning: "We ask personalized questions based on your diary entries so you can reflect deeper", "the world's first intelligent journal app & mood tracker that gives you personalized motivation and prompts the more you use it". The exact step count and whether it opens emoji-first I could not verify.

**Calm `[P]` (App Store copy)** — day-open is a content home with carousels `[S]`. Its daily rituals are named **Daily Calm** (Tamara Levitt), **Daily Jay** (Jay Shetty), **Daily Trip** (Jeff Warren), **Daily Move**. The listing mentions Daily Streaks & Mindful Minutes but **no** mood check-in and **no** feeling-based personalization. Calm's in-app mood check-in (see §2) is documented in research as sitting *after* a session, not before.

**Balance `[S]`** — the closest analogue to Sakina's promise, and the strongest "visible personalization" case: "Every day, Balance asks about your experience and goals to assemble a unique meditation session tailored to your exact needs and mindset", assembled from a library of thousands of audio files. So: a question is asked daily, and the answer demonstrably changes the artifact the user receives. 7M+ users. This is question→visibly-different-output, which is exactly Sakina's reel promise in a different vertical.

**Insight Timer `[P]`** — content feed/library. "80+ new free guided meditations added daily." No personalized daily pick, no mood entry point. Day-open is browse.

**Hallow `[P]`** — home screen carries a **"Routine"** tile showing your next or upcoming scheduled prayer, with "Build your Routine" / "Edit". So the day-open is a dashboard whose personalization is *scheduled by the user in advance*, not derived from today's state. No mood question. Journal is offered **after** every prayer.

**Glorify `[S]`** — day-open is a single sequenced daily flow: quote → Bible passage → devotional → "Daily Walk with God" (a virtual walk meditation), ~10 minutes, and reviewers note "the daily worship flows one into the other without having to touch your phone". Tree-watering streak. One reviewer describes the ethos as "short content, gentle nudges, no shame loops, no streak guilt" — a user can "use the app for three days and disappear for three weeks without feeling judged when they come back."

**Abide `[S]`** — AI curates a "Daily Devotional" aligned to "your current life season", and recommends meditations from stated **prayer needs** (e.g. anxiety). So the state-matching happens via a persisted need/topic, not a daily question.

**Muslim Pro `[P]`** — day-open is a utility dashboard: prayer times + athan countdown, Quran, Qibla, duas. Labels lean on Arabic/Islamic vocabulary without apology: *Ummah*, *Deen* ("Deen Mode Timer"), *Khatam*, plus "Streaks" and "Stars & Crescents". It does now ship journaling with mood tracking, but the emotional entry point is peripheral, not the day-open.

**Oura / Whoop `[S]`** — archetype C. Oura's Readiness Score answers "How ready are you for the day?" and readiness/sleep/activity are "front and center each morning". Whoop gives a 0–100 Recovery with a green/yellow/red verdict. `[I]` The relevant lesson: these apps open by *telling you something about yourself that you couldn't have computed*, which buys the right to then direct your day. They ask nothing.

### Taps to the day's core action

- Duolingo: 1 (tap next path node)
- Glorify: 1 (tap today's devotional; then hands-free)
- Finch: 1–2 (tap check-in card from home)
- Calm / Hallow / Insight Timer / Muslim Pro: 1–3, but from a screen of competing options
- Stoic: 0 (the check-in *is* the open)
- **Sakina today: 1 tap, but from a low-prominence line on a cluttered home, behind a launch overlay** — so effectively the tap is cheap and the *finding* is expensive. `[I]` This is a prominence problem masquerading as a tap-count problem.

### One-tap vs free-text

Universally **one-tap first, text optional and later**. How We Feel (tap a quadrant cell), Daylio (tap a face), Finch (tap a mood), Stoic (tap a mood), Calm (tap an emoji). The apps that use free text (Reflectly, Stoic's journal, Finch's reflections) place it *after* a tap-selected state, never as the first ask.

### Does the answer visibly change what the app shows?

This is the sharpest split I found, and it maps directly onto Sakina's problem:

- **Visibly changes the output:** Balance (assembles the session) `[S]`, Abide (curates by prayer need) `[S]`, How We Feel (offers strategies for the emotion picked) `[S]`, Reflectly (claims adaptive prompts) `[P]`.
- **Logged only:** Daylio, Stoic (per its own docs), Calm's post-session emoji, Muslim Pro journaling.

`[I]` Sakina's current design is in the worst position available: it *asks nothing* and then *serves an algorithmically-picked Name*, so the user can neither see personalization nor have supplied any. Adding a question that doesn't visibly change the Name would move it into "logged only" — the weaker half of this split.

---

## 2. The one-tap-vs-questionnaire evidence (deep)

### The headline number, and it cuts against the "too many questions" theory

**Mobile EMA compliance meta-analysis, JMIR 2021** (68 datasets: 41 nonclinical, 27 clinical) `[P]` — https://www.jmir.org/2021/3/e17023:

- **Pooled compliance: 81.9% (95% CI 79.1–84.4)**, I² = 98.
- Items per standard prompt across studies ranged **1 to 73, median 10**.
- Compliance by items per prompt (nonclinical):
  - ≤5 items → **82.8%**
  - >5 to ≤9.5 items → **78.6%**
  - >9.5 to ≤26 items → **84.0%**
  - **>26 items → 63.0%** (95% CI 42.3–79.7)
- Compliance by prompts per day (nonclinical): **1–3/day → 87.0%**; 4–5/day → 76.9%; ≥6/day → 79.4%.
- Incentives (62.9% of datasets provided them): **no significant association** with compliance.
- No significant relationship for monitoring duration, device type, training, or a burden score.

**Read this carefully, because it is the load-bearing finding.** There is **no smooth per-question drop-off** in the range Sakina cares about. Four questions vs one question sits entirely inside the flat region (82.8% vs 78.6% vs 84.0% — non-monotonic, i.e. noise). The cliff is at **>26 items**. What *does* move compliance is **frequency of being asked** (1–3/day ≫ ≥4/day).

`[I]` Direct implication: **the 4-question check-in Sakina removed in April 2026 almost certainly did not fail because it had 4 questions.** The evidence says a 4-item daily prompt is cheap. It failed for other reasons — most plausibly (a) it was a gate placed before the payoff, (b) the answers didn't visibly change anything, (c) it was the same 4 questions every day. Those are all fixable without reducing to one question. Removing the questions treated the wrong variable.

Corroborating meta-analysis: **Wrzus & Neubauer 2023, *Assessment*** `[S]` (search-surfaced summary; I did not open the paper) — across research fields, EMA studies averaged **6 assessments/day over 7 days with 79% compliance**, and "the number of assessments did not predict compliance or dropout rates." Same conclusion from an independent corpus: volume of asking is not the dominant lever.

Counter-signal worth respecting: in **youth** EMA samples, "acceptance rates decreased as the number of EMA items increased" `[S]`. And a longitudinal mood-app analysis found roughly a **0.76% decline in daily mood entries per additional day in study (~15% over 20 days)** `[S]` — i.e. **fatigue is a function of days, not of questions.**

### Does a check-in that *records* help engagement? Yes, but barely.

**The Calm mood check-in study, JMIR 2021** `[P]` — https://pmc.ncbi.nlm.nih.gov/articles/PMC8105761/ — is the best-matched real-world number I found, and it is the one to quote:

- N = **2,600 first-time subscribers** (1,300 summer 2018, 1,300 summer 2019).
- The feature: rate your mood with **a single emoji after completing a meditation**, plus preset feedback messages and a monthly calendar of past check-ins. **One tap. Placed after the activity.**
- Intent-to-treat: **+0.045 meditation sessions per week** (95% CI 0.039–0.052) for the cohort exposed to the feature launch.
- Larger for previously **inactive** users: **+0.063 sessions/week** (95% CI 0.052–0.074) vs +0.026 for active users.
- Treatment-on-treated: using mood check-ins in the previous week raised the odds of meditating the following week, **OR 1.132 (95% CI 1.059–1.211)**.
- Cumulative over 8 weeks: **~1 extra session (~5 minutes)** overall, ~1.7 sessions for inactive users.
- **Effect lasted only 1 week** — no sustained benefit at longer lags.

`[I]` So a purely recording check-in produces a real but tiny, non-durable engagement lift, and it helps *lapsing* users most. It is not a retention engine on its own. Note also the placement: Calm put it **after** the meditation, and it still worked — which is evidence that a check-in does not have to be a gate to pay off.

### Does a check-in that *visibly personalises* retain better than one that merely records?

**I found no head-to-head trial. This is the single thinnest part of the evidence base and I want to be explicit about it: no reliable figure found.** Balance's daily-question→assembled-session model is a strong existence proof commercially (7M+ users `[S]`) but there is no published A/B of personalised-visible vs logged-only check-ins that I could locate.

What I can offer instead is strong *qualitative* evidence that logging-without-return is actively resented — see §6, the npj 2025 meta-synthesis, where participants said "It's informative. It doesn't change my lifestyle", and the authors conclude mood monitoring "on its own or without such aims... might have either no effect or even make depression worse." `[P]`

`[I]` The honest synthesis: the *downside* of record-only check-ins is well evidenced; the *upside magnitude* of visible personalisation is not quantified. Treat "make the answer change the output" as a well-motivated bet, not a measured fact.

---

## 3. Auto-entry vs choice

### Who actually auto-enters

**Almost nobody, and that's the finding.** Among verified apps only **Stoic** auto-opens into its check-in — and it exposes an off switch (*Track Mood on Launch*) `[P]`. Duolingo, the app most associated with compulsion, explicitly does **not** auto-enter: it optimised the *home screen* so the next step is unambiguous, and left the tap to the user `[P]`. Glorify auto-*advances* — once you start the daily flow, segments chain "without having to touch your phone" `[S]` — which is auto-entry applied **inside** the session rather than at the app boundary. `[I]` That distinction is the most transferable idea here: **don't auto-enter the app; auto-advance the session.**

Calm's "Daily Calm"/"Daily Move" and Finch's daily activities are both **one prominent tap from home**, not forced.

### Failure modes and the escape affordance

- **NN/g, User Control and Freedom (heuristic #3)** `[S]`: users need "a clearly marked emergency exit to leave the unwanted state without having to go through an extended dialogue." An auto-entered flow with no visible exit is a textbook violation.
- **NN/g on autonomy** `[S]`: forcing users through introductory processes "does not generally make them faster and can even make tasks within the interface seem more difficult"; they cite Grammarly *not* forcing personalisation steps as the positive example.
- Finch's version of the escape hatch is instructive `[S]`: you may **skip** a goal, and skipping is met with an invitation to reflect on why — the exit exists and is non-punitive.
- How We Feel's escape hatch is **long-press to quick-save**, bypassing every optional step `[S]`.
- Duolingo's streak-freeze deploys **silently, with no user decision required**, and the user discovers retroactively that they were protected `[P]`. `[I]` Note the shape: the app absorbs the failure instead of demanding an interaction to avoid punishment.

`[I]` When auto-entry reads as hijacking: (a) when the user came in for something else (a specific dua, prayer times, their journal) and the app blocks it; (b) when the forced screen has no visible dismiss; (c) when it repeats identically every single day; (d) when it demands emotional disclosure before delivering any value. Sakina is exposed on (a) and (d) in particular — a returning user who opened the app to reread yesterday's Name should not have to declare a burden to get there.

`[I]` Defensible middle path, supported by the pattern above: make the question the *first and only* prominent thing on the day-open screen (Duolingo's "one clear next step"), auto-advance everything *after* the first tap (Glorify), and ship a persistent dismiss that lands on home (NN/g #3). If you do auto-enter, copy Stoic and make it a setting.

---

## 4. Streak-ceremony placement (deep)

### The observed pattern is unanimous: reward **after** the work

- **Duolingo `[P]`** — the streak increment is part of the **post-lesson** sequence: "On the first lesson of the day — the moment the user crosses the daily threshold — the post-lesson sequence includes the streak update: XP earned, a small celebration, and after a tap on Continue, the streak increment screen." Milestone celebrations sit in the same post-lesson flow, not as separate pre-session notifications. Cited numbers from this teardown: 32M DAU carry 7+ day streaks (attributed to Duolingo's own reporting); one animation redesign "moved day-7 retention by +1.7%" (attributed to Duolingo internal data, **no public citation** — treat as `[S]` and unverifiable); Friend Streaks users "22% more likely to complete their daily lesson" (uncited).
- **Finch `[P]`** — the pet gains energy *from* the completed check-in and *then* goes adventuring. The payoff is downstream of the work.
- **Calm `[P]`** — the mood check-in itself sits **after** the meditation, and that placement still produced the (small) measured lift in §2.
- **Glorify `[S]`** — tree-watering streak follows the devotional.
- **Muslim Pro `[P]`** — "Streaks", "Stars & Crescents" are earned currencies, i.e. consequences.

**I found no comparable app that shows the day's streak/reward ceremony as a gate before the day's action.** `[I]` Sakina currently does exactly that: `DailyLaunchOverlay` shows streak + daily reward at first open, then drops the user on home *before* any muḥāsabah has happened. That is the inverse of every app I could verify, and it spends the celebration on nothing.

### What the evidence says about rewarding before the work

The one genuine pro-pre-reward finding is narrower than it looks:

**Endowed progress effect — Nunes & Drèze (2006)** `[S]`: 300 car-wash customers got either an 8-stamp card or a 10-stamp card with **2 stamps pre-applied** (identical 8 purchases required, identical reward). Redemption: **19% vs 34%**. Crucially, "the endowed progress effect disappeared when there was no reason given for the head start" — the reason could be arbitrary, but it had to be stated.

`[I]` Read precisely: this supports pre-granting **progress toward a goal the user has not yet started**, with a stated rationale. It does **not** support handing over the day's *payoff* before the day's *work*. A streak counter shown on open is closer to endowed progress (a reminder of accumulated position) than to a reward — the problem in Sakina isn't showing the streak, it's spending the **ceremony and the daily-reward moment** pre-work, then requiring a second, less celebrated act to actually do the practice.

Also relevant `[P]`: the npj 2025 review recommends "behavioral goals and positive encouraging statements" that give a "sense of mastery and achievement" — mastery framing is inherently post-effort.

`[I]` Practical shape suggested by the whole set: **streak state before (quiet, glanceable, informational), ceremony after (loud, animated, once).** Duolingo does precisely this — the widget/counter is ambient all day, the flame animation fires only after the threshold is crossed, and reserving it for landmarks is what the teardown argues keeps it potent.

---

## 5. Naming the day's core action

### The pattern

**Name the ritual or the job, not the practice-jargon — and when you do use jargon, gloss it in the same breath.**

Verified naming inventory:

| App | Label for the day's core action | Type |
|---|---|---|
| Calm `[P]` | **Daily Calm**, Daily Jay, Daily Trip, **Daily Move** | Branded ritual (brand + format) |
| Glorify `[P]` | **Daily Walk with God** | Plain-language metaphor |
| Hallow `[P]` | **Routine** / "Build your Routine" (container); individual sessions keep jargon | Job-to-be-done for the entry point |
| Finch `[P]` | "quick mood checks", "quick self-care exercises" | Job-to-be-done |
| Stoic `[P]` | **Daily Check-In**, Morning/Evening Reflections | Job-to-be-done |
| How We Feel `[S]` | **check-in** | Job-to-be-done |
| Muslim Pro `[P]` | *Deen* Mode, *Khatam*, *Ummah* | Untranslated religious vocabulary, unapologetic |
| Abide `[S]` | Daily Devotional | Category term |

### How faith apps handle devotional vocabulary with mixed literacy — the direct answer

**Hallow keeps the jargon and glosses it `[P]`.** From its own App Store listing:

- **Lectio Divina** → "Enter into a conversation with God through Bible passages / Scripture"
- **Ignatian Examen** → "Reflect on your day & discover an awareness of God, Jesus Christ, & the Holy Spirit"
- **Rosary** → "Meditate with Mary through the mysteries of the Catholic Rosary"
- **Taizé & Traditional Chant** → "Meditative chant & music"
- Left unglossed (assumed known by the audience): Divine Mercy Chaplet, Novenas, Stations of the Cross, Liturgy of the Hours, Psalms.

Two things to take from this. First, **the jargon names a specific content item, never the app's primary daily CTA** — Hallow's home-screen entry point is the plainest word in the product, "Routine". Second, **every unfamiliar term earns a one-line plain-language gloss right next to it**, and the gloss states the *benefit/action*, not the etymology.

**Glorify goes further toward plain language** `[S]`: it blends faith vocabulary ("devotionals", "declarations", "Scripture-based") with accessible wellness terms ("meditations", "calming"), and names its centrepiece with a metaphor anyone can parse — "Daily Walk with God".

**Muslim Pro is the counter-example** `[P]`: it uses *Deen*, *Ummah*, *Khatam* as bare labels. `[I]` It can afford this because those words are near-universal in its audience and, more importantly, because they label *features*, not the thing the user must emotionally commit to. "Muḥāsabah" is not in that tier of familiarity.

### Verdict for Sakina `[I]`

Do not make **"Begin Muḥāsabah"** the CTA. The CTA should be the job to be done — ideally the question itself, which is also the reel promise ("What are you carrying today?" / "Tell me what's on your heart"). Keep **muḥāsabah** as the *name of the practice*, introduced as a gloss beneath or after the action ("this is muḥāsabah — the practice of taking account of yourself"), which is exactly Hallow's Examen treatment. That way the word teaches rather than gates, and the button matches the ad.

---

## 6. Anti-patterns for problem-first daily loops

The strongest source here is a 2025 systematic review and meta-synthesis, **14 studies / 457 participants**, on the *user experience* of mood monitoring in depression — npj Digital Medicine `[P]`, PMC12672782. Seven themes; the relevant ones:

### (a) Asking someone to rate their suffering daily can make it worse

- "**All 11 studies** included participant reports of the protocol resulted in them confronting a worsening of their mood and/or anxiety."
- The mechanism, in a participant's words: *"I would be in a pretty decent mood, and I would complete the questionnaire accordingly, and then the results would indicate that I was actually in a much worse mood than I thought I was."* — i.e. **the instrument told them they were worse than they felt.**
- Reported "worrying or even rumination about low mood after mood monitoring"; fear of getting "a little bit obsessed with it."
- "When you start to get worse, like it's just disheartening."
- The authors' conclusion, which is the sentence to carry into the design review: mood monitoring **"on its own or without such aims... might have either no effect or even make depression worse."**
- Independent corroboration `[S]`: bipolar self-monitoring reviews warn that "self-monitoring of mood symptoms may induce depressive ruminations that may result in increasing severity of depressive symptoms", and that harms are under-investigated.

### (b) "How are you feeling?" fatigue is real and it's about *repetition*, not length

- *"It felt a bit too similar, um, every day... it's like the same sort of questions every day so it's a little bit monotonous."* `[P]`
- Quantified `[S]`: ~**0.76% fewer daily mood entries per additional day in study (~15% over 20 days)**; and in a multi-condition study, ~**28% fewer entries** from first to last condition. Notably, **goal-completion tracking did not show the same fatigue** — the decay is specific to mood logging.
- `[I]` So the enemy is an identical prompt on day 30, not a 4-item prompt on day 1. Rotating the question's *framing* (not its schema) is the counter-move; Sakina already has 99 Names as a natural rotation axis.

### (c) Record-without-return is resented

- *"It's informative. It doesn't change my lifestyle."* `[P]`
- "Some users reported that the mood monitoring did not lead to any subsequent behaviour change"; for some "the app provided no additional benefit and confirmed what they suspected or knew already"; those who gained "no new insight" struggled "to maintain motivation for continued use." `[P]`
- What they wanted instead: content that "should be tailored to each patient and should adapt to the patient's condition over time"; readable visual feedback ("something more ludic, intuitive and easy"); and *interventions* attached to the monitoring — "distraction interventions... supportive messages... links to music playlists... inspirational quotes." `[P]`

### (d) Closed answer sets that don't fit the person

- *"The answers are very closed, so you can't really answer what you feel... It's very up in the air."* `[P]`
- Participants also found items "difficult to interpret" and some "could be misconstrued."
- `[I]` Directly relevant to a one-tap redesign: collapsing to a fixed chip list is the friction-minimising move *and* the fit-minimising move. How We Feel's answer to this is instructive `[S]` — 100+ labels arranged in a comprehensible grid, plus the ability to **add your own missing emotion word**. Breadth without depth of steps.

### (e) The days when nothing is wrong — **what does a problem-first app do on a good day?**

This is where I most wanted a study and there isn't one; the answer is assembled from design precedent plus one very sharp participant quote.

1. **The question is valence-neutral, and the answer space covers good states as first-class options.** How We Feel's grid gives **two of four quadrants to pleasant states** (yellow = high-energy pleasant: "excited, inspired, joyful"; green = low-energy pleasant: "chill, supported, blessed") `[S]`. Daylio's scale is 5-point with a neutral centre `[S]`. Finch's tracker exists to show "what has been lifting you up or bringing you down" — both directions `[P]`. None of them ask "what's wrong".
2. **There is an explicit positive branch, and users prefer it.** The single best line in the whole corpus, from a participant `[P]`: *"I like recording what keeps me well, not what makes me ill. I'd much prefer... to think more positively."* Finch's daily arc ends "in moments of gratitude" and invites you to "recognize your positive moments" `[P]`.
3. **The philosophical stance that makes this coherent:** How We Feel's designers held that "emotional well-being is not achieved by eliminating negative feelings but by learning to interpret them constructively... emotions are neither good nor bad" `[S]`. The app is a *meter*, not a complaint box.
4. **Faith precedent, partially verified.** Hallow's own gloss for the Ignatian Examen is *"Reflect on your day & discover an awareness of God"* `[P]` — note it is framed as noticing presence, not as reporting a problem. `[I]` The Examen traditionally opens with gratitude and reviews both consolation and desolation; I could **not** verify the canonical five steps within budget, so treat the two-sidedness claim as inference from Hallow's gloss plus general knowledge, not as a verified finding.
5. **The verdict-first alternative `[I]`:** Oura/Whoop show that on any given day an app can *lead with a statement* rather than a question. Sakina's equivalent on a good day is to offer the Name unprompted, and let the question be available rather than compulsory.

`[I]` The design conclusion: **never presuppose a burden.** A prompt like "What are you carrying today?" is a good ad and a bad daily question, because on day 12 the honest answer may be "nothing, alhamdulillah" and the app has no slot for it. A neutral opener ("How is your heart today?") with a chip set that genuinely spans gratitude→distress, where the *grateful* answers route to a **different** branch (shukr / Names of blessing and provision) rather than to the same consolation content, both preserves the promise and survives good days. If the good-day answer produces the same output as the grief answer, users will learn the question is decorative — the exact failure in quote (c).

### (f) Two more, briefly `[I]`

- **Rewarding before the work** (§4): unanimous counter-pattern across verified apps; also spends the ceremony on an act that hasn't happened.
- **Auto-entry with no marked exit** (§3): NN/g heuristic #3 violation, and the specific way "drop them into the question" degrades for the user who opened the app for something else.

---

## What this implies for a problem-first faith app

1. **The 4-question check-in did not fail because of question count.** The best meta-analytic evidence (JMIR 2021, 68 datasets, pooled 81.9%) shows compliance is flat from 1 to ~26 items per prompt and only collapses beyond 26. What moves compliance is *how often* you ask (1–3/day → 87.0% vs ≥4/day → ~77–79%). Reviving a short question set is not repeating the April 2026 mistake — provided the three real defects are fixed: it was a gate before the payoff, it changed nothing visible, and it was identical every day.
2. **Question-first at the app boundary is nearly unprecedented; one-clear-next-step is the dominant safe pattern.** Only Stoic auto-opens into a check-in, and it's a setting. Duolingo achieved "unmistakable centre of the app" with a path, not a prompt. The recommendation that follows: make the question the sole prominent element of the day-open screen, auto-advance the session after the first tap (Glorify), keep a marked exit (NN/g #3), and if you truly auto-enter, make it toggleable (Stoic).
3. **The answer must visibly change the Name.** Sakina's acquisition promise *is* question→personalised output. Balance proves the model works commercially; the npj review proves that logging without return is actively resented ("It's informative. It doesn't change my lifestyle"). This is the one place where Sakina's current loop is worse than either alternative — it neither asks nor personalises visibly. Caveat honestly: the *magnitude* of the personalisation benefit is unmeasured in the literature. The measured effect of a mere *recording* check-in is small and short-lived (Calm, N=2,600: +0.045 sessions/week; OR 1.132 for next-week return; effect gone after 1 week).
4. **Move the ceremony behind the work.** No verified comparable app gates the day's reward before the day's action; Sakina's launch overlay does. Streak state ambient and quiet on open; the animated reward once, after the muḥāsabah completes. Endowed progress (19%→34%) licenses pre-granting *progress with a stated reason*, not pre-granting the payoff.
5. **Rename the CTA to the job, keep muḥāsabah as the taught word.** Hallow's model — jargon on content items, plainest possible word on the home entry point, one-line benefit gloss on every unfamiliar term — is the direct template. The button should sound like the reel.
6. **Design for the good day from the start, or the loop will teach users to lie.** Valence-neutral prompt, answer set spanning gratitude to distress, and a genuinely different content branch for the good-day answers. The strongest single piece of user testimony in this whole corpus is *"I like recording what keeps me well, not what makes me ill."* For a faith app this is not a compromise — gratitude and self-accounting are the same tradition, and 99 Names give you a natural positive branch that a mood tracker doesn't have.
7. **Guard against the iatrogenic risk explicitly.** In 11 of 11 relevant studies, participants reported the monitoring itself confronted them with a worsening mood; reviewers warn daily mood monitoring without an attached therapeutic component "might have either no effect or even make depression worse." Sakina's mitigation is structural and already built: the question is immediately followed by scripture, a Name, and a duʿā — a response, not a chart. Keep it that way; do not add a mood *graph* as the payoff.
8. **Vary the framing, not the schema.** Fatigue is a function of days and sameness (~15% decline over 20 days; "the same sort of questions every day so it's a little bit monotonous"), not of item count.

### Where the evidence is thin — stated plainly

- **No head-to-head study of visibly-personalising vs record-only check-ins.** No reliable figure found. Treat as a motivated bet.
- **No study on auto-entry vs home-screen choice at app open.** Everything in §3 is pattern observation plus NN/g heuristics, not a measured comparison.
- **No study on reward-ceremony placement (before vs after).** §4 is a unanimous *observed* pattern plus one adjacent lab finding (endowed progress). The Duolingo "+1.7% D7" figure is attributed to Duolingo internal data with no public citation — do not quote it externally.
- **No research at all on the good-day problem in problem-first apps.** §6(e) is design precedent plus a single participant quote. This is a genuine gap and, given Sakina's framing, the highest-value thing to instrument and learn from your own users.
- **Apps I could not verify** (search budget exhausted): Ahead, Bearable, Pray.com, Headspace's Today tab, Muslim Pro's day-open beyond the feature list, and the canonical structure of the Ignatian Examen.
