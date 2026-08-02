# Conversion Diagnosis & External Research — 2026-07-14

**Purpose:** Founder asked for a full diagnosis of why Sakina has strong MAU/DAU but ~2% paid
conversion, testing two hypotheses against the data before designing against them, plus
evidence-based external research (5 independent research passes) and a prioritized changelist.

**Authored by:** Claude Code session 2026-07-14 (data pulls: Supabase prod SQL + Mixpanel
project 4013350 + RevenueCat; research: 5 parallel web-research subagents).

---

## Context at time of writing

- **App state:** 1.2.0+5 live on the App Store since 2026-06-18 (T0). Prod flags:
  `post_tour_paywall_mode="soft"`, `reverse_trial_experiment_enabled=true`.
- **Reverse-trial A/B running:** control_no_trial (post-tour soft paywall, no trial) vs
  treatment_reverse_trial (app-granted 3-day full premium → Day-3 soft gate), 50/50 via
  `assignPaywallArm`. Directional read: control ~5% vs treatment ~1.2% conversion
  (82 trials granted → 1 subscribed). **Severely underpowered** (~4 assigned/arm/day vs
  ~1,500/arm needed) — treat as directional only.
- **Monetization state:** 30d snapshot: 711 MAU, ~91% free tier, ~14 genuinely paying
  (RC prod subs), 55 in reverse-trial windows, 3 RC StoreKit trials. Soft gate dismissed by
  191 users/30d; only 22/711 ever hit the free AI cap; 9 bought the 25-token AI bypass.
- **Acquisition:** ~100% organic IG/TikTok reels. Highest performer: *"2 Names of Allah that
  are the solution to your problems."* No paid UA, no attributed links.
- **Related docs:** `docs/superpowers/plans/2026-07-03-reel-first-conversion-refactor.md`
  (plan of record this analysis largely confirms — its **v4 section, 2026-07-18, folds this
  changelist into the unified implementation order; its v5 section, 2026-07-23, resolves
  changelist #3: reverse trial retired, front-loaded hybrid gate w/ real store trial adopted.
  NOTE: the "control ~5%" figure below went stale — the 07-23 pull reads control 2.44% vs
  treatment 1.68% on n=768 signups since T0**),
  `docs/research/2026-07-03-conversion-retention-findings.md` (earlier evidence compendium;
  where numbers differ, prefer this doc's fresher window),
  `docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md` (ADR),
  `docs/analytics/reverse-trial-experiment-readout.md` (readout playbook),
  `docs/analytics/funnel-flags-and-querying.md` (event schema).
- **Data hygiene:** Supabase queries auto-exclude deleted test accounts. Mixpanel test/orphaned
  distinct_ids listed in `docs/qa/mixpanel-orphaned-distinct-ids.json` (64 IDs); the 30d funnel
  below was run without the exclusion filter (Mixpanel funnels can't express a 64-ID not-in) —
  residual skew ≤ a handful of QA accounts on counts in the hundreds.

## The founder's two hypotheses (as submitted)

- **H1 — Acquisition/onboarding mismatch.** The top reel drives most installs, but users land
  in a generic onboarding. Hypothesis: shorten onboarding and route users straight into the
  Names feature that brought them there.
- **H2 — Low-frequency use case.** Core features are "use as you go" (~once/day), so users
  never build enough habit/perceived value to justify paying — hypothesis: that suppresses
  conversion.

---

# THE SINGLE BIGGEST FINDING

**Conversion is decided in the first session, and Sakina's first session doesn't sell
anything.** 32 of 42 all-time subscribers (76%) converted on Day 0; 88% within 2 days — before
any habit could form. This matches industry data (82% of trial starts happen on install day;
55% of 3-day-trial cancels happen Day 0 — RevenueCat SOSA 2026). Meanwhile the funnel loses
48% of signups inside the forced tour before they reach the paywall, and the free tier hands
the entire core loop away uncapped, so survivors have nothing to buy. Signup→paid of ~2.9% is
almost exactly the published freemium median (2.1%) — **the soft-gate model is performing to
spec; the spec is the problem.**

---

# PART 1 — DIAGNOSIS (Sakina's own data)

30-day signup cohort n=646 (Supabase, 2026-06-14 → 07-14) + Mixpanel 30d funnel (n=746
signup_completed) + all-time subscriber analysis.

## 1.1 Drop-off in order of severity

| Stage | Number | Verdict |
|---|---|---|
| Install → signup | **unmeasured** | Blind spot — no ASC-installs↔signup join instrumented. |
| Signup → tour start | 98% (728/746) | Healthy. |
| Onboarding intake pages | ~86–92% complete | Healthy — at the 90–95% benchmark for quiz onboarding. |
| **Tour start → complete** | **52% (375/728)** | **Leak #1 (in-session).** Earlier diagnosis: 161 backgrounded + 95 anchor-timeouts vs 2 deliberate skips per 483 starts → breakage/length, not disinterest. Only ~42% of signups ever reach the post-tour paywall. |
| Activation (ever check in) | 95.5% (617/646) | Fine eventually, but ~38h avg install→first check-in. |
| **D0 → D1 return** | **31% (200/646)** | **Leak #2 (largest by volume).** 69% never return. 28% reach 3 active days; 9% reach 7. |
| Paywall view → CTA tap | 34% (86/254 users, 30d) | Decent intent. |
| **CTA tap → paid** | **~16–22% (86 → 14–19)** | **Leak #3.** Partly normal StoreKit sheet abandonment, but uninstrumented (no `purchase_started` → RC reconciliation). |
| Signup → paid | 2.9% (19/646) | = freemium median. |

Streaks: 600/865 users (69%) have longest_streak ≤ 1. Distribution: ≤1: 600 · 2–3: 188 ·
4–7: 48 · 8+: 29.

## 1.2 Conversion timing (all-time, prod subs n=42 with signup join)

| Days signup→subscribe | n |
|---|---|
| 0 | 32 (76%) |
| 1 | 5 |
| 2–10 | 5 |

## 1.3 Payers vs free: depth, not frequency

Among users with ≥1 check-in (payers n=38, free n=755):

| Metric | Free | Payers | Ratio |
|---|---|---|---|
| Avg check-ins | 2.9 | 3.3 | ~1.1× (identical) |
| Median active days | 1 | 2 | — |
| Avg built duas | 0.8 | 2.1 | 2.6× |
| Avg reflections | 0.3 | 0.9 | 3.0× |
| % used Reflect | 13.0% | 36.8% | 2.8× |
| % used Build-a-Dua | 55.5% | 76.3% | 1.4× |
| Avg cards | 4.6 | 8.4 | 1.8× |

**Payers are depth users, not frequency users.**

## 1.4 Feature census

- **Load-bearing for retention (keep free):** muḥāsabah loop — check-in → Name reveal →
  streak → quests → XP. ~90–100% of retained users; 100% of payers.
- **Willingness-to-pay surface (gate harder):** Reflect + Build-a-Dua (see 1.3).
- **Dead weight:** discovery quiz (~6.5%), Store surface (~5% views), dormant 4-question
  check-in path (0 users), ~8 onboarding pages capturing data nothing reads.
- **Broken lever:** notifications — 575/577 users set `reminder_time`, opens ~1%.

## 1.5 Is the free tier too generous?

Yes — textbook. Only 3% of MAU ever hit the free cap → the paywall is invisible in normal use
(benchmark: 80%+ of D1 users should *see* a paywall — Phil Carter). 191 users dismissed the
soft gate in 30d because dismissing costs nothing. The features payers pay for (AI depth) are
gated too loosely to be felt; the core loop retains and must stay free.

## 1.6 Hypothesis verdicts

**H1 — half right; remedy wrong.** The mismatch is real: reels promise "tell it how you feel →
your Name," the app delivers that once (onboarding page 0, hardcoded 7-Name map), and the live
loop (`discoverName()`) is a blind gacha that never asks how you feel. But onboarding *length*
is not the leak — the quiz completes at benchmark, and the best published test shows shortening
a healthy quiz **cost 13%**. The broken pieces are the forced tour (52%) and the core loop not
re-delivering the reel promise.

**H2 — contradicted on mechanism.** Conversion is a Day-0 event here (76% of subs) and
industry-wide; payers' early frequency is identical to free users'; hard-paywall apps convert
5× freemium with zero accumulated usage. The once-a-day ceiling is a **retention** problem
(31% D1; 69% never pass a 1-day streak), not what suppresses conversion. Fix first-session
value delivery and gate architecture first.

---

# PART 2 — EXTERNAL RESEARCH (5 independent streams)

Findings tagged **MEASURED** (numbers from experiments/reports) vs **OPINION** (advice without
data). Vendor-published numbers flagged where the vendor sells the solution.

## 2.1 Ad-to-onboarding continuity ("creative-to-first-run matching")

- **MEASURED (A/B vs control):** PatPat via AppsFlyer OneLink + Meta DPA — deep-linked users
  landed on the advertised product: CVR 17% vs 4.13% control (~4×), >3× revenue, +65% ARPU.
  https://www.appsflyer.com/use-cases/onelink-dynamic-product-ads/
- **MEASURED (aggregate, vendor):** Adapty — paywall matched to acquiring intent lifted
  install→trial **+41.5%** and trial→paid **+24.2%** vs default.
  https://adapty.io/blog/profitable-ads-for-subscription-apps/
- **MEASURED (platform case):** **Hallow** ran the faith-category version twice:
  (a) keyword-matched Apple Ads custom product pages: +33% CVR, +52% TTR, −31% cost-per-trial
  YoY (https://ads.apple.com/app-store/success-stories/hallow); (b) Branch deferred deep links
  landing installs on shared prayer content: 50% of installs / 43% of subscriptions attributed,
  −42% CAC, 2.2× MoM trial conversion — Lent-confounded
  (https://www.branch.io/resources/case-study/how-hallow-drove-2-million-app-installs-and-became-1-on-the-app-store/).
- **MEASURED (vendor marketing, no methodology):** AppsFlyer "110% D30 retention from
  deep-linked onboarding"; Branch "1.8× signups / 1.9× retention" — treat skeptically.
- **MEASURED (vendor A/B library):** Adapty — long personalized onboarding beat none by +40%
  payment conversion; **shortening the winner cost −13%**; personalized vs generic flow:
  +17% paying conversions. https://adapty.io/blog/how-to-fix-your-onboarding-flow/
- **Caveats:** deferred deep linking post-ATT is 70–90% accurate and **doesn't apply to organic
  reels at all** (no attributed click). The zero-infrastructure equivalent the measured wins
  actually used: an early onboarding question ("What brings you here?") routing users to the
  promised content. RevenueCat: >82% of trial starts happen Day 0 → first-session content is
  where the match matters.

## 2.2 Onboarding length (intake quiz ≠ product tour)

- **"Longer wins" (intake quizzes):** category leaders converged on 30+ screens (Noom,
  Duolingo, Flo, Headway — Phil Carter, MEASURED-observational); Lose It! lengthened
  onboarding → double-digit trial-start lift (MEASURED,
  https://www.revenuecat.com/blog/growth/why-your-onboarding-experience-might-be-too-short/);
  Adapty A/Bs above; Superwall (40M paywall opens): multi-page onboarding paywalls convert
  12.41% vs 9.07% single-page, **+37%** (MEASURED,
  https://superwall.com/blog/new-postmulti-page-onboarding-paywalls-convert-37-better-than-single-page-heres-why).
- **"Shorter wins" (tutorials/walls/dead screens):** Vevo deleted its forced tutorial: +5.85%
  completed signups, ~+10% logins, no retention cost (MEASURED,
  https://apptimize.com/blog/2015/10/vevos-app-defies-user-onboarding-best-practices-heres-why/);
  Duolingo delayed signup until after first lesson: +20% DAU (MEASURED); Adapty: removing
  dead loading screens +22% trial conversions.
- **Forced tours specifically:** Pendo: 2–4-step guides ~50% completion; 5+ steps ~63%
  abandonment (secondary); contextual/just-in-time education ~2.5× engagement vs forced tours;
  checklist onboarding: Blip +124% activation (MEASURED,
  https://www.pendo.io/pendo-blog/measuring-the-effectiveness-of-walkthrough-guides-in-pendo/,
  https://www.saasfactor.co/blogs/why-most-product-tours-fail-and-how-to-implement-contextual-onboarding).
- **Benchmarks:** B2C quiz onboarding should complete 90–95% (Sakina: ~92% ✓). ~90% of trial
  starts happen Day 0; users who don't convert at the onboarding paywall rarely see one again
  (https://adapty.io/blog/high-performing-paywall-2026/).
- **Faith comps:** Hallow/Glorify = quiz → trial paywall at onboarding end; **no forced
  post-onboarding tour gates the paywall in any comp.** No faith app publishes onboarding A/Bs.

## 2.3 Paywall strategy

- **MEASURED (RevenueCat SOSA 2025/2026, 115k apps):** hard paywall 10.7–12.1% download→paid
  D35 vs freemium 2.1–2.2% (~5×); revenue/install D60 $3.09 vs $0.38 (8×); 1-yr subscriber
  retention nearly identical (27% vs 28%) — no retention penalty.
  https://www.revenuecat.com/state-of-subscription-apps
- **MEASURED (Adapty nuance):** per-VIEW, soft paywalls convert ~50% better (4.85% vs 3.34%);
  hard wins at install level because 100% of installs see it; hard-paywall users have +21%
  1-yr LTV. https://adapty.io/blog/high-performing-paywall-2026/
- **Trial length (MEASURED, RC 2026):** 17–32-day trials convert 42.5% vs **25.5% for ≤4-day**;
  55.4% of 3-day-trial cancels happen Day 0. These are card-on-file StoreKit numbers — an
  app-granted trial ending at a *soft* gate (Sakina's treatment arm) is the weakest
  configuration in the data. Opt-in trials ~25% vs 48–60% opt-out
  (https://www.businessofapps.com/data/app-subscription-trial-benchmarks/).
- **Case studies (MEASURED):** Rootd moved a *dismissible* paywall to the front of onboarding →
  **5× revenue**; Headspace locked ~100% of content → double-digit paid lift
  (https://www.revenuecat.com/blog/growth/hard-paywall-vs-soft-paywall/). Phil Carter: one app
  hard→freemium with multistep paywall +75% LTV; another lost >50% of conversion — "freemium is
  a product strategy, not a pricing strategy"
  (https://www.revenuecat.com/blog/growth/hard-paywall-vs-freemium/).
- **Faith comps (MEASURED-observational):** Hallow locks ~85% of content, trial-first
  onboarding paywall, $69.99/yr / $9.99/mo, 30-day extended trials during Lent/Advent; Glorify
  ~$59.99/yr; Pray.com $59.99/yr. **None monetizes via a dismissible-forever soft gate.**
  YouVersion = 100% free donor-funded outlier (sets the norm that scripture itself is free).
- **Pricing:** wellness high-priced annual plans earn ~4× LTV/user ($70 vs $17, Adapty);
  faith category clusters $59.99–69.99/yr. Under-pricing is the bigger measured risk.
- **Soft-paywall failure mode:** not dismissibility per se — **dismissible + nothing meaningful
  locked**. Exit-discounts train users to dismiss (Adapty playbook). ~74% of top-grossing
  paywalls have no visible close button (Lazyweb).
- **Checkout leak:** no public StoreKit-sheet abandonment benchmark; Superwall treats
  abandoned-transaction as a first-class recovery trigger — instrument before concluding.

## 2.4 Free tier design frameworks

- **Frameworks:** free tier = acquisition asset that must market the paid tier (Patrick
  Campbell); gate the value metric, never the activation/aha features (Kyle Poyar); retention
  features free / monetization features gated (Reforge); Phil Carter's Subscription Value Loop:
  don't give away so much that upgrade rationale disappears; benchmark 80%+ D1 paywall-view.
- **The category-defining contrast (MEASURED):** Calm/Headspace/**Hallow** keep a daily ritual
  anchor free and gate the depth library → category revenue leaders. **Insight Timer** gave the
  depth library away → most engagement-hours in meditation, ~1/50th of Calm's revenue
  (https://tricycle.org/magazine/meditation-app-profits/). This maps 1:1 to Sakina today.
- **Duolingo (MEASURED):** all content free, monetizes friction-relief (hearts→Energy);
  ~9% paid penetration on 56.5M DAU; kept tightening friction as A/Bs held, amid backlash.
  Works only at massive scale.
- **Clawback literature (MEASURED events):** works when the retained free core preserves the
  habit/network (Strava 2020 — profitable same year; softener: 60-day free premium) and fails
  when the cut guts the core use case (Evernote). Playbook: staged %-rollout test (Evernote
  2023, Duolingo), softener window, grandfather actives, never touch the habit loop.
- **AI gating (MEASURED, RC):** AI apps earn +41% revenue per payer, ~2× revenue/install;
  dominant 2024–26 patterns: premium-only AI, caps, credit packs. Daily caps suppress usage
  and paywall encounters vs weekly/monthly pools (a never-hit cap converts nobody).

## 2.5 The frequency problem

- **Verdict: once-a-day is NOT a conversion ceiling.** Wordle built elite retention *on*
  one-per-day scarcity + shareable artifact; Hallow makes ~$40M/yr on episodic seasonal spikes;
  RC 115k-app data: conversion is a Day-0 event regardless of frequency. DAU/MAU correlates
  with conversion (Saljoughian benchmark) but no causal study found shows manufactured
  frequency lifts paid conversion independent of first-session value.
- **The one clean causal result (MEASURED): Calm's reminder experiment.** Users prompted to set
  a daily reminder right after their first session got a **causal ~3× retention lift**, 40%
  opt-in (prompted cohort matched organic setters → not selection).
  https://amplitude.com/case-studies/calm
- **Streaks (MEASURED):** Duolingo: streak-adjacent changes compounded to −40%+ daily churn and
  4.5× DAU over 4 years; individual changes small (+1.7% D7 from milestone animations; +0.38%
  DAL from a 2nd streak freeze). *Journal of Consumer Research* (Silverman & Barasch 2023):
  streak loss — even glitch-caused — **causes** disengagement → build forgiveness (freeze/
  repair), never surface "you broke your streak." Snapchat/Duolingo monetize repair directly.
- **Seasonal/serialized (MEASURED):** Hallow Lent = 4–7× monthly downloads and ~25% of annual
  revenue lands in the single post-Lent conversion month
  (https://appfigures.com/resources/insights/hallow-lent-surge-prayer-app-revenue); YouVersion:
  3M+ one-year-plan signups on New Year's Day 2026. Ramadan cuts both ways (Muzz −20% during
  fast; documented post-Ramadan dip — plan the Eid re-engagement beat).
- **Failures (MEASURED):** Duolingo's transplanted Gardenscapes mechanic: zero effect;
  X Communities: <0.4% adoption, shut down; meditation category D30 retention 3–5% *despite*
  streaks+daily drops — mechanics amplify value that landed, they don't rescue value that
  didn't; 3–6 promo pushes/week → ~40% opt-out. Overjustification risk for worship: keep
  gamification adjacent to the devotional act (cards/collection), never inside it.

---

# PART 3 — PRIORITIZED CHANGELIST

| # | Change | Evidence | Impact / Confidence | Effort | Measure |
|---|---|---|---|---|---|
| 1 | **Kill the forced tour** → contextual coach-marks + straight to first muḥāsabah | Own data: 48% mid-tour loss, breakage not skips. Vevo A/B; contextual ~2.5×; no comp gates paywall behind a tour | ~+40–50% paywall/core-loop reach · **High** | S–M | signup→same-session first check-in; paywall-reach; D1 |
| 2 | **Reel-first first-run**: feeling→Name in ~3 taps; "What brings you here?" routing; echo reel promise on paywall; cut only the ~8 dead pages (keep the quiz) | Adapty intent-match +41.5%; PatPat 4×; Hallow playbook; −13% warning against over-cutting. = existing 7/03 plan | Activation speed, D1 22%→35%+, trial starts · **High (direction)** | L | install→first-reveal time; D1; trial-start rate |
| 3 | **Gate architecture (A/B)**: onboarding paywall leading with 7-day StoreKit opt-out trial; and/or reverse trial → 7d ending at a harder gate; tie trial messaging to completing 2–3 muḥāsabahs | Hard/trial-first 5× freemium, no retention penalty; ≤4-day trials worst; own control > 3d-soft treatment directionally | Revenue lever, plausibly 2–3× conversion · **Med-High** | M | D35 signup→paid by arm; D7 retention + review-sentiment guardrails |
| 4 | **Tighten AI free tier (staged A/B)**: replace never-felt 1/day cap with small taste (e.g. 3/week or lifetime intro), premium = unlimited + journal history/insights. Never cap the core loop. Grandfather actives | Payers use AI ~3×; 3% cap-hit = invisible paywall; Insight Timer vs Calm; AI = proven WTP surface | Paywall-encounter 3%→30%+ · **Med** | S–M | cap-hit rate; paywall views from AI surfaces; conversion; D7 guardrail |
| 5 | **Reminder prompt after first check-in + fix dead notif pipeline** (575/577 set reminder_time, ~1% opens); anchor to user-picked prayer time; ≤1/day | Calm causal 3× retention, 40% opt-in; 3–6 pushes/wk → 40% opt-out | D1/D7 · **High** | S | opt-in rate; open rate; D1/D7 prompted-vs-not |
| 6 | **Streak forgiveness** (freeze/repair; sell repair via tokens/premium — no paid randomness) | 69% never pass day 1; JCR: streak loss causes abandonment; Duolingo/Snapchat monetize repair | Retention med-high, revenue low | S | % passing 3-day streak; D7 |
| 7 | **Instrument checkout leak** (`purchase_started` → RC reconciliation) + recovery offer on sheet-cancel | 86 CTA taps → ~14 paid, currently un-diagnosable | Diagnostic · **High** | S | tap→sheet→paid stages |
| 8 | **Ramadan/seasonal challenge architecture** (30-day muḥāsabah journey, Dhul-Hijjah, Jumu'ah beat; Eid re-engagement for the post-Ramadan dip) | Hallow Lent 4–7× + ~25% of annual revenue; YouVersion NY plans; `islamic_occasions` infra exists | Growth+conversion spikes · **High** | L | challenge signups; trial starts; post-window retention |
| 9 | **Trim dead weight**: discovery quiz, Store surface, dormant 4-Q path, dead intake pages | Adoption ≤6.5%; 0 users on dead path | Focus, not revenue | S | — |
| 10 | **Instrument install→signup** (ASC) — the one unmeasured funnel stage | — | Diagnostic | S | install→signup rate |

## A/B test rather than ship blind

1. **Gate architecture (#3)** — highest stakes; faith audience punishes clawbacks on basics
   (Muslim Pro widget backlash), so measure sentiment alongside conversion.
2. **AI free-tier tightening (#4)** — staged % rollout, grandfather actives, guardrails on
   retention + reviews.
3. **Reel-first onboarding (#2)** — big enough change to want the retention read; use the
   existing flag/super-property pattern.

**Ship blind (evidence overwhelming, reversible):** tour removal (#1), reminder prompt (#5),
streak freeze (#6), checkout instrumentation (#7).

**Volume constraint:** at ~21 signups/day, a 50/50 paywall A/B accrues slowly — prioritize
big-effect tests (gate architecture) and let #1/#2/#5 grow the denominator first.

---

## Appendix — key source index

RevenueCat SOSA 2026: https://www.revenuecat.com/state-of-subscription-apps ·
SOSA 2025: https://www.revenuecat.com/state-of-subscription-apps-2025 ·
Hard vs soft: https://www.revenuecat.com/blog/growth/hard-paywall-vs-soft-paywall/ ·
Hard vs freemium (+75% LTV case): https://www.revenuecat.com/blog/growth/hard-paywall-vs-freemium/ ·
Onboarding too short: https://www.revenuecat.com/blog/growth/why-your-onboarding-experience-might-be-too-short/ ·
Adapty paywall report 2026: https://adapty.io/blog/high-performing-paywall-2026/ ·
Adapty onboarding A/Bs: https://adapty.io/blog/how-to-fix-your-onboarding-flow/ ·
Adapty intent-matched ads: https://adapty.io/blog/profitable-ads-for-subscription-apps/ ·
Superwall multi-page paywalls: https://superwall.com/blog/new-postmulti-page-onboarding-paywalls-convert-37-better-than-single-page-heres-why ·
Hallow Apple Ads: https://ads.apple.com/app-store/success-stories/hallow ·
Hallow × Branch: https://www.branch.io/resources/case-study/how-hallow-drove-2-million-app-installs-and-became-1-on-the-app-store/ ·
Hallow Lent economics: https://appfigures.com/resources/insights/hallow-lent-surge-prayer-app-revenue ·
Calm reminder experiment: https://amplitude.com/case-studies/calm ·
Duolingo growth: https://www.lennysnewsletter.com/p/how-duolingo-reignited-user-growth ·
Duolingo streaks: https://blog.duolingo.com/how-duolingo-streak-builds-habit/ ·
Broken-streak causality (JCR): https://academic.oup.com/jcr/article-abstract/49/6/1095/6623414 ·
Insight Timer economics: https://tricycle.org/magazine/meditation-app-profits/ ·
Vevo tutorial removal: https://apptimize.com/blog/2015/10/vevos-app-defies-user-onboarding-best-practices-heres-why/ ·
Trial benchmarks: https://www.businessofapps.com/data/app-subscription-trial-benchmarks/ ·
PatPat OneLink: https://www.appsflyer.com/use-cases/onelink-dynamic-product-ads/ ·
Subscription Value Loop: https://www.lennysnewsletter.com/p/the-subscription-value-loop-a-framework ·
Meditation retention rates: https://www.pauso.com/blog/meditation-app-retention-rates
