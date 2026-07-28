# Wave H — Onboarding intake depth & the comfort opening

**Status: SPEC — question set settled with the founder 2026-07-28 (Q3 approved · Q6 de-committed · Q5 broadened to multi-select chips). Blend orderings and final copy still need founder review (§11).**
**Date:** 2026-07-28
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first`
**Parents:** `2026-07-26-one-ship-02-onboarding.md` (W2 plan — this lands as **Wave H**) · `2026-07-28-lantern-in-onboarding-design.md` (Wave G, which this partly re-sequences) · `2026-07-03-reel-first-conversion-refactor.md` §V6.1 (the two reel contracts) · `docs/analytics/2026-07-14-conversion-diagnosis-and-research.md` (Day-0 + depth-payer data) · `docs/research/2026-07-25-muslim-struggles-chip-taxonomy.md`

---

## 1. Why this wave exists — the ICP was wrong

An ICP pass on 2026-07-28 (two independent researchers) concluded the primary user was a **lapsed/returning** Muslim. **That conclusion was wrong, and the error is instructive enough to record so it is not repeated.**

Both researchers reasoned backwards from the shipped taxonomy — *"I keep sinning and going back"*, *"To feel close to Allah **again**"*, *"even when I slip"* — and read lapse into it. But the taxonomy is a **downstream chip-set design decision**, not evidence about who arrives. The orchestrating agent compounded the error by feeding that presupposition into the second brief as the hypothesis to test, which anchored it. Two agents agreeing is worth nothing when both were handed the same anchor.

**The acquisition truth is the two reels** (plan §V6.1), and neither mentions drifting, sinning, missed prayers, or returning:

- **Reel 1 — "2 Names of Allah that have the solutions to your problems."** Problem → "is that you?" → two Names, each explained against the problem, plus a prophet/companion story. A **diagnosis contract**.
- **Reel 2 — "Allah is sending you a sign right now."** Struggles/pain/doubt/burdens → Allah is aware, never burdens a soul beyond what it can bear → learn about Allah and His Names. A **recognition contract**, for a vague, unnamed burden. Its spine is **2:286** — a comfort verse addressed to believers under strain, not a repentance verse addressed to sinners.

### The corrected ICP (founder-confirmed 2026-07-28)

**A Muslim — at any level of practice — in a period of real difficulty, landed by a reel, who wants to know the deen has something specific for *this*.**

The axis is **acute weight, not religious lapse**. A perfectly consistent Muslim whose father just died, or who cannot make rent, or whose marriage is failing, is squarely the target — arguably more so, because they already believe the deen has answers and are looking for the specific one. Guilt and distance-from-Allah are **two of seven** things a user might be carrying, not the centre of gravity; and for many, hardship *caused* the distance, which inverts the causality the earlier framing assumed.

**What survives from the ICP work regardless**, because it comes from our own revenue data rather than from any persona reading:

- **76% of subscribers convert on Day 0**, 88% within two days. Signup→paid ≈2.9%.
- **Payers are DEPTH users, not frequency users**: near-identical check-in counts to free users (3.3 vs 2.9) but 3.0× reflections, 2.6× built duʿās, 2.8× Reflect usage.
- Therefore: **onboarding is optimised for the Day-0 depth-diver.** The habit-former is a retention persona served by the streak/lantern/widget stack; they are not who the first session is for.

Also surviving (and unaffected by practice level): the fear ranking — being told to *just pray more*, being judged, being data-mined (the Muslim Pro location-data sale is a live wound in this demographic), fabricated scripture, and abandoning yet another app, which for a *deen* app feels like failing Allah rather than churn.

The **waswas / religious-OCD anti-persona** also stands: they will install (our reel promise is catnip for compulsive reassurance-seeking) but serving them harms them, because reassurance loops are the pathology. The 1/day reveal cap is a safety rule, not a monetisation lever.

---

## 2. The central finding

**We ask the user only three questions about themselves** — problem, carrying duration, aspiration. Everything else in the flow is an ask *of* them (reminder, notifications, widget, name, email, password) or a payoff.

Our own research file draws a sharp line: intake **quizzes** convert better when *longer* (Noom, Duolingo, Flo, Headway all run 30+ screens; shortening a winner cost −13%), while product **tours** convert better when shorter or deleted. W2 correctly deleted the tour — and then trimmed the intake too. That was the wrong half.

It matters more than a benchmark because it collides with the product thesis. The founder's stated goal is that the user feels *"Allah understands **my** problem."* Three questions cannot manufacture specificity: the queue's rows 3–7 come from a single aspiration answer, so the "personalised plan" is really one of five pre-baked sequences. **The Day-0 depth-buyer converts on feeling specifically seen, and we have not asked enough to see them.**

**The governing constraint for this wave:** every intake question must produce a **visible consequence** on the plan screen. A question whose answer never surfaces is extractive, and a longer extractive form is worse than the three questions we have now.

---

## 3. Audit findings being fixed

| Severity | Finding |
|---|---|
| 🔴 | **The kindling beat is in the wrong register.** The user taps *"I keep sinning and going back"* or *"Everything feels heavy"*, and the app answers with a lamp and *"Your lantern is lit. It brightens the longer you keep coming back."* They named pain; we replied with a gamification object and a retention promise. Duolingo's equivalent slot (COURSE BUILDING) works because "I want to learn French" carries no emotional weight. Ours does. |
| 🔴 | **"Where did you find us?" sits at the emotional peak.** Immediately after the deck, the duʿā and Ameen, we ask the user to do market research for us — the subtitle literally reads *"It helps us know who we are reaching."* It is the only screen that gives the user nothing, placed at the moment they are most open. |
| 🔴 | **The welcome screen breaks ad-scent for Reel 2.** A viewer promised 2:286 opens the app to a *different* ayah (94:6), under the tagline **"Reflect · Build · Discover"** — a feature list delivered to someone in pain — over an arch image fetched from a `googleusercontent.com` URL on the app's first screen. |
| 🟡 | **The sign chip is 7th of 7.** A Reel-2 arrival carries a vague, unnamed burden, and the row built for them sits last, after six that do not fit. By the same NN/g fold data used to justify the compact SE layout, that is the least-read position — given to the person who most needs it. |
| 🟡 | **The widget carousel is too early** (Wave G). Second ask in a row, before the payoff, before we have asked their name. Duolingo places theirs at 15 of 17, *after* the value summary. |
| 🟡 | **The aspiration options presuppose lapse** — "again", "even when I slip" — which the corrected ICP makes actively exclusionary toward a devout user having a terrible month. |
| 🟢 | Working and unchanged: the hook question + promise line, carrying-duration, deferred signup, the reveal as payoff, no progress bar on the hook. |

---

## 4. The intake set (7 questions)

Placed between the reveal and the plan. Every row's third column is the contract this wave is held to.

| # | Question | Options | Visible consequence |
|---|---|---|---|
| H1 | **How long have you been carrying this?** *(exists, unchanged)* | Only these past few days · Months, on and off · Years · As long as I can remember | The plan's pacing line |
| H2 | **When is it heaviest?** | Mornings · During the day · At night · When I'm alone · It doesn't let up | **Derives the reminder time** — replaces the reminder-time ask entirely |
| H3 | **Have you been able to tell anyone?** | Someone knows · A little · No one · Rather not say | Register of the reveal + notification copy; the "unseen" thread |
| H4 | **How many of Allah's Names could you name right now?** | Just a few · Maybe ten · A good number · I've tried to learn them all | **The projection baseline** on the plan; deck depth |
| H5 | **What would help most right now?** *(multi-select, cap 3 — see §5)* | 7 chips | Queue rows 3–7 |
| H6 | **How much time feels right most days?** | Just a minute · A few minutes · As long as I need | Plan pacing line; deck length preference |
| H7 | **Anything you want to add?** *(free text, skippable)* | — | AI context for Reflect / Build-a-Dua |

### Why each earns its slot

**H2 replaces the reminder-time screen rather than adding to it.** Today we ask *"what time do you want reminders?"* — a chore, and an ask. Asking *when it is heaviest* extracts the same information with the opposite emotional valence, and lets the app say something true back: *"You said nights are hardest. We'll be here then."* Net-zero screen count, entirely different feeling. **The reminder-time screen is deleted from the reel flow** (it stays in the kill-switch flows untouched).

**H3 is the highest-variance question in the set, and is approved on the condition that we act on it.** It is the most ICP-resonant thing we can ask — 40% of young Muslim men in the MYH data told *nobody* about their last problem, and answering "No one" to an app is itself the moment of being seen. But if the answer changes nothing visible, it is voyeurism. Binding: an answer of "No one" or "A little" must alter at least the plan line and the first notification's register.

**H4 is what makes the learning promise real.** Nothing in the current intake establishes what the user already knows, so *"you'll learn 30 Names"* has nothing to be measured against. This is Duolingo's *"How much French do you know?"* (their screen 8) — load-bearing, because it is what lets the plan say **"You know about five. In 30 days you'll know thirty-five."** That is the Cal AI shape, and because it is a claim about the **user's own knowledge**, it stays the right side of the reverence line (§8).

**H6 is deliberately NOT a commitment device.** The founder's call, 2026-07-28: the streak, lantern and widget already own commitment, and this question must not compete with them. Specifically, **the Duolingo "I'M COMMITTED" CTA is NOT imported** — the plan CTA stays warm. Option wording avoids any choice that reads as the failure option; "As long as I need" replaces "Longer when I can" because the latter implies scarcity the user should feel bad about.

**H7 is a payer-detection surface, not merely an input.** Payers do 3× the reflections on identical check-in counts. Giving the depth-diver somewhere to go deep on Day 0 targets the person who actually converts. Skippable, so it costs everyone else nothing.

---

## 5. H5 presentation — the calm-multi-select spec

Seven full-width multi-select rows would reintroduce exactly the "seven stacked rectangles" failure the hook screen was redesigned on 2026-07-27 to escape. Three mechanisms, all sourced:

- **Constrain the count.** Daylio — the most-used mood tracker — has users tap a mood then **up to five** activity icons; the cap *is* the design. Cognitive-load work puts working memory at 5–9 items. Chernev's meta-analysis (already relied on for the hook screen) finds no magic count: the mitigations are **categorisation and constraint**, not fewer options.
- **Chips, not rows.** Material 3 and the multi-select literature both favour chips at this scale — every selection visible at a glance, materially lighter than stacked rectangles, and they do not read as a form. The one documented risk is that users may not realise multi-selection is possible; solved with microcopy, not iconography.
- **Headspace is the closest comp and already does this.** *"What brings you to Headspace?"* is multi-select, six options, including *"Just checking it out"* as a no-commitment escape; their whole onboarding is three questions.

### Spec

> **What would help most right now?**
> Choose up to three. You can change this later.
>
> `Words to turn to` · `Making sense of it` · `Something small each day` ·
> `Feeling less alone` · `Feeling closer to Allah` · `Learning His Names` ·
> `Strength to keep going`

- Wrapping chip cloud, **cap 3**, Continue enables at ≥1 selection.
- **"You can change this later" is load-bearing copy, not filler.** Our ICP's fear ranking has *failing at another thing* near the top; stating the choice is reversible removes the pressure to get it right, which is most of what makes a seven-option screen feel heavy.
- Chips stagger in on `AppMotion` (`listStart` 320ms, `stagger` 40ms) — they arrive rather than appearing as a wall. Same treatment that fixed the hook screen.
- Selected state uses the hook screen's emerald tint; **no checkbox glyphs** (the hook screen's borderless direction).

### Two deliberate additions to the option set

**"Learning His Names"** is Reel 2's literal promise and the founder's stated second product aspect; nothing in the current intake captures the learning motive at all. **"Strength to keep going"** covers the sabr/endurance motive the old four missed entirely, and is plausibly the most common thing a practising Muslim in hardship actually wants.

Rejected wording: *"To understand what Allah is teaching me in this"* — attributes intent to Allah, violating §8. *"Making sense of it"* does the same job cleanly.

### The deliberate inconsistency with the hook screen — record it, do not "fix" it

The hook screen is **single-select, full-width rows, tap-to-commit**. H5 is **multi-select chips with a cap**. That difference is intentional: the hook asks one exposing question where the tap *is* the commitment, so it earns full-width weight and instant advance. H5 is lower-stakes, later, and reversible, so it should feel physically lighter under the thumb. Different interaction weight signalling different stakes is the point; flattening them to one treatment would lose it.

### Blend rule (needs founder review — §11)

The queue map is currently `one aspiration → five Names`. Multi-select needs a deterministic blend: **weight by selection order, interleave, dedupe against the revealed Name pair, cap at five.** Test-pinned for internal uniqueness and disjointness from every chip pair and the comfort pair, exactly as the single-select sequences are today. **These are orderings of already-approved Names — no new content — but they need the founder's eye the way the original five did.**

---

## 6. The comfort opening (replaces the welcome screen)

**Founder's proposal, 2026-07-28, adopted.** A Reel-2 arrival is promised 2:286 and currently meets a different ayah, a feature-list tagline, and a remotely-fetched image.

- **2:286 in motion** as the app's opening beat — Arabic and English in **separate `Text` widgets** with explicit `textDirection` (the standing RTL rule), plus one short English line of acknowledgement.
- Then a smooth transition **directly into the hook screen**.
- **It REPLACES the welcome screen; it does not precede it.** Otherwise the flow is comfort → welcome → question, two gates before the ask. The only element the welcome screen must retain is the **"I already have an account"** link.
- Supersedes the W2 note that `/welcome` is deliberately unchanged (plan review 11) — that decision predates the reel-contract audit.
- **Bundle the arch illustration as a local asset** regardless of what else changes here. The first screen of the app must not depend on a network fetch of a Google-hosted Stitch URL (`hook_screen.dart:22`).

**Why this is more than aesthetics:** creative-to-first-run matching is the highest-leverage lever available to us and the only one that works for organic reels, which carry no attributed click. Measured comparables in our own research file: PatPat 4× CVR, Adapty +41.5% install→trial, Hallow +33% CVR / −31% cost-per-trial. It also fixes a structural gap — **we currently ask the most exposing question in the app before depositing any trust.** Duolingo spends four screens before asking anything. This is the deposit before the withdrawal.

---

## 7. Re-sequencing

The kindling beat's **slot** is right (it fills the reveal's loading phase and inherits the dissolve into beat 1); its **content** is wrong.

- **Re-voice the kindle slot to acknowledgement** — the recognition moment, which is Reel 2's actual promise. The lamp may still light, but the copy must acknowledge what the user just named rather than announce a companion or a streak.
- **Move the lantern's introduction to the notification screen**, where streaks are already the topic and the `pendingUnlit` framing does real work.
- **"Where did you find us?" moves** out of the post-reveal peak to immediately before the signup trio — the flow's lowest-emotion moment, still pre-paywall so capture is preserved. It cannot be deleted: reel-source capture is named the biggest measurement hole in the plan.
- **The widget carousel moves** to after the plan screen (Duolingo's position, after the value summary).
- **Promote the sign chip** out of last place on the hook screen.

### Proposed page order (18 pages)

`0` Hook · `1` Reveal · `2` H1 duration · `3` H2 heaviest · `4` H3 told anyone · `5` H4 Names known · `6` H5 what would help · `7` H6 time · `8` H7 free text · `9` **Plan (payoff)** · `10` Rating gate · `11` Notifications · `12` Widget · `13` Where did you find us · `14` Name · `15` Save progress · `16` Email · `17` Password · `18` Paywall

Asks come **after** the payoff, matching Duolingo's shape (goal → projection → notifications → widget → value → paywall). The **rating gate stays in the flow** (Wave F2, founder call 2026-07-28) and sits immediately after the plan so it lands on the payoff rather than before it.

Progress bar hidden on `0`, `1`, `9`, `10`, `18` (hook, reveal, plan, rating gate, paywall — the gates and payoffs, none of which are "steps") — the 14 bar-visible pages fill segments 0–13, so `onboardingReelTotalSegments` becomes **14** and `onboardingReelLastPageIndex` becomes **18**. Every index constant and the index-pinned test files move with them, as in Wave G.

---

## 8. Copy rules carried in (binding)

- **Never attribute a stance, intent or outcome to Allah.** No "Allah will lift this", no "what Allah is teaching you", no guaranteed spiritual result. Safe promises are about the **user's** knowledge, words, or practice.
- **No "sign" / "meant for you" language system-initiated**, and never near a price. (The sign *contract* is a routing key; it is not a copy register.)
- **No lapse presupposition anywhere** — the corrected ICP makes "again" and "when I slip" exclusionary toward a devout user in hardship. This retires the current aspiration wording.
- **No prescriptive tone.** "Just pray more" is the advice this user has already failed at; it is the top-ranked bounce trigger.
- Arabic and Latin never share a `Text` widget.
- Tier language attaches to the **card**, never to the Name.

---

## 9. Analytics

New constants (stubs here; **W5 completes them and must also add `flag_reel_first`** as a super property, carried over from the Wave E review P3-9):

- `onboarding_intake_answered { question_id, answer }` — one event, `question_id` ∈ `h1_duration | h2_heaviest | h3_told_anyone | h4_names_known | h5_would_help | h6_time | h7_free_text`. One event name with a dimension, not seven names, so the intake funnel is a single segmentable series.
- `h5_would_help` carries `selection_count` and the ordered `selections` array — the blend inputs, needed to evaluate whether multi-select beat single-select.
- `onboarding_intake_skipped { question_id }` — H7 is skippable and its skip rate is the cheapest read on whether the depth-diver hypothesis holds.
- `comfort_opening_completed` — the new first beat; a drop here would be the most alarming possible signal and must not be invisible.

---

## 10. Tests

- **Every intake answer has a visible consequence** — the §2 governing constraint, asserted rather than trusted: for each question, a test that changing the answer changes something rendered on the plan screen.
- **H5 blend**: deterministic for a given selection set; result is internally unique, disjoint from the revealed pair and the comfort pair; capped at five; order-stable.
- **H5 cap**: a fourth selection is refused without disabling the first three; Continue gated at ≥1.
- **No lapse presupposition**: a copy test asserting the strings "again" and "slip" do not appear in the intake option set — cheap, and it pins a decision that is otherwise one innocent copy edit from reverting.
- **Reduce-motion** on the comfort opening and the chip stagger.
- **RTL isolation** on the 2:286 beat — Arabic and Latin in separate widgets.
- Index migration for the six index-pinned files (`onboardingReelLastPageIndex` 13 → 17, `onboardingReelTotalSegments` 10 → 14).
- The kill-switch flows are **untouched**: the trimmed/legacy page lists, their reminder-time screen and their aspiration screen must be byte-identical after this wave.

---

## 11. Open items for the founder

1. **The H5 blend orderings** — weighted interleaves of already-approved Names for each multi-select combination. Author = Claude, reviewer = founder, same protocol as the original five aspiration sequences.
2. **Final copy for H2–H4, H6, H7** and the comfort-opening English line. Drafted in this spec; not yet approved.
3. **What "No one" changes** (H3's binding condition) — needs a concrete decision on the plan line and first-notification register, or H3 should be cut rather than shipped as voyeurism.
4. **The projection sentence** on the plan screen. Candidate: *"You know about {n}. In 30 days you'll know {n+30} — and which one to turn to when life gets heavy."* Safe under §8 because it promises the user's own knowledge.
5. **Reel split** — is Reel 1 or Reel 2 the bigger driver? If Reel 2 dominates, "being seen" and "learning the Names" should lead the flow, where "name your problem" leads today. `reel_source_selected` will answer it post-ship; IG/TikTok insights could answer it now.
