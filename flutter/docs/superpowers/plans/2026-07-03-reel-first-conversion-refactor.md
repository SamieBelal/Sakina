# Reel-First Conversion Refactor — Plan of Record

> **Distilled net state (2026-07-23):** [`2026-07-23-conversion-refactor-changes-and-implementation.md`](./2026-07-23-conversion-refactor-changes-and-implementation.md) — every net change in bullet form + the concrete implementation plan. This doc remains the append-only history and full rationale.

> **v2 (same day):** see the **Addendum** at the bottom — full-data review (Supabase + RevenueCat + Mixpanel), the reverse-trial retention strategy (streaks/widgets/companion/Rive/notifications), and the revised roadmap. The v2 roadmap supersedes §4; the founder decision to KEEP the 3-day reverse trial supersedes the Phase-4 "3→7-day trial A/B" item.

> **Evidence base:** the full research findings behind every number and citation in this plan (analytics queries, production-data results, codebase audits, and all six external-research reports with sources) are compiled in [`docs/research/2026-07-03-conversion-retention-findings.md`](../../research/2026-07-03-conversion-retention-findings.md).
>
> **v4 (2026-07-18):** reconciles this plan with the [`2026-07-14 conversion diagnosis`](../../analytics/2026-07-14-conversion-diagnosis-and-research.md); re-scopes v3 as a retention (not conversion) program and adopts four new workstreams (free-tier tightening, checkout + install instrumentation, Ramadan/seasonal architecture).
>
> **v5 (2026-07-23):** founder direction update. Onboarding goes reel-*verbatim* (problem-first hook, full story-deck reveal with a sealed second Name, problem-derived questions only); most of the v2/v3 retention stack is now **shipped** (streaks 0-3, lantern companion, widgets, Live Activities, emerald cards, beat decks); fresh experiment read (control 2.44% vs reverse-trial 1.68% — both soft arms at the freemium median) + dedicated hard-vs-soft research → **decision: retire the reverse trial; ship a front-loaded, dismissible-to-limited-free hybrid gate with a real store trial at the end of the new onboarding.**
>
> **v6 (2026-07-23) — START HERE:** five-agent reel-contract audit of the whole plan against the two live reel formats. Adds the **two-contract onboarding** (Reel 2 "sign" router — one chip, three copy branch points, no second flow), the **"sign"-language copy boundary**, pre-authored story decks (no runtime AI pre-auth), both-Names-Day-0 + the **second-Name free guarantee**, the **gate copy firewall** + dismissal-to-home, grandfathering + close-out specs, reel/contract/problem super properties + guardrail **stopping rules**, reel-voice notification copy (ships now, server-only), the **99-Name arc**, Ramadan reframed as "30 Names for 30 Nights" with a generosity posture, and a depth-first backlog purge of retired-trial residue. **§V6.6 (as amended by §V6.8) is the current implementation order**, superseding §V5.4. A second audit pass (same day) added **§V6.7 — the superseded-clauses ledger (consult before implementing ANY pre-v6 text)** and **§V6.8 — round-2 amendments**: Name-PAIR map, the D1-D7 daily-loop seam, hook-chip-only routing, story-deck pipeline w/ ship-gate + ~5-6-chip cap, arm-keyed tour kill, LapsedTrialSheet kept + re-paced, `discoverName` exempt from tightening, one 7-day trial on every SKU, server-mirrored pool, change freeze + corrected 7-day-trial read schedule + honest decision ladder, two-phase notification rewrite (server lacks today's Name), the waiting/addressing reverence rule, "met" definition reconciling queue/gacha/cards, Ramadan offer mechanics, and the One Ship scope cut-line (anon auth → fallback; grandfathering + offers → post-decision). **§V6.9 (founder decision, same day): rollout is 100% ship-and-watch — no A/B, no control arm, no holdout; the legacy flow survives only behind one kill switch; reads are pre/post vs the trailing baseline with a T0+6wk keep decision. The A/B machinery in V5.3/V6.8.C is superseded where V6.9 says so. §V6.10 (2026-07-24): NO grandfathering — the tightened free tier reaches ALL existing users via one post-keep-decision softener wave (30-day notice, done before Ramadan prep); the bypass subsystem is deleted after the wave; research dissent recorded in §V6.10.**

**Date:** 2026-07-03
**Goal:** minimum friction from reel-driven install → the promised "tell it how you feel → your Name of Allah" moment → trial start. Leanest app for maximum conversion.
**Inputs:** Mixpanel project 4013350 (30d window, 66 test distinct_ids excluded per `docs/qa/mixpanel-orphaned-distinct-ids.json`), codebase audit, external research (RevenueCat State of Subscription Apps 2025/2026, Superwall Cal AI case study, comp teardowns: Calm, Headspace, Hallow, YouVersion, Duolingo, Imprint, Glorify).

---

## 1. Diagnosis — what the data actually says

### The funnel (last 30 days, real users only)

| Step | Users | Step conv. | Cumulative |
|---|---|---|---|
| onboarding_started | 206 | — | 100% |
| signup_completed | 170 | 83% | 83% |
| onboarding_completed | 169 | 99% | 82% |
| tour_started | 167 | 99% | 81% |
| **tour_completed** | **87** | **52%** | **42%** |
| check_in_completed (first core-loop value) | 57 | 66% | **28%** |

- **Avg time from onboarding start → first check-in: ~38 hours.** The dopamine hit the reel sold arrives a day and a half after install. Industry data: 82% of trial starts happen same-day as install (RevenueCat 2025) — the first session is the whole game.
- **The onboarding quiz is NOT the big leak.** Per-page drop across the 20-page flow is only ~14% total (603 → ~517 uniques by the last steps). It's *wasteful* (see below) but users push through it.
- **The forced guided tour IS the big leak.** Of 483 tour starts (30d): 254 completed (53%), **161 backgrounded the app mid-tour (33%)**, **95 hit anchor timeouts (20%)**, and only **2 deliberately skipped**. Users aren't opting out — they're being lost to a fragile 9-step forced walkthrough that stands between them and the app.
- **Paywall is weak:** paywall_viewed 150 → CTA tapped 19 (**13%**) → sheet 9 → trial_started 5 (3% overall). Benchmark: Cal AI converts 57% of paywall presentations to trial starts. The reverse-trial arm's app-granted `trial_activated` = 81 users; RC `trial_started` = 20; `subscription_started` = 20 (30d).

### Feature usage (30d uniques, of 681 app-openers)

| Feature | Users | % |
|---|---|---|
| check_in_completed (muhasabah/gacha) | 472 | 69% |
| card_revealed | 472 | 69% |
| streak_extended | 470 | 69% |
| quest_completed | 438 | 64% |
| dua_built (AI build-a-dua) | 120 | 18% |
| journal_entry_created | 114 | 17% |
| store_viewed | 31 | 5% |
| notification_opened | 8 | **1%** |

**Read:** the daily Name/card/streak loop is the product — everything else is periphery. The Reflect tab (the actual feeling→Name AI engine!) is **not instrumented at all** — no event exists for it, so we're blind on the one feature that matches the reel. Notifications are effectively dead (8 opens/30d) despite onboarding collecting a reminder time.

### The core mismatch (codebase)

1. **The reel promise is delivered exactly once, then never again.** Onboarding page 0 (`first_checkin_screen.dart`) does feeling → Name reveal — but with a hardcoded 7-Name map (`demo_result_card.dart:130-169`), pre-auth, and then buries the payoff under 19 more pages.
2. **The live core loop doesn't match the reel.** `discoverName()` (`daily_loop_provider.dart:458-530`) skips the feeling question entirely — it's a card-collection gacha pull, not "tell me how you feel." The real feeling→Name engine (`reflectWithOpenAI`, `ai_service.dart:626`) is tucked away on the Reflect tab behind daily-cap gating.
3. **~8 of 20 onboarding pages are write-only surveys.** Pages 2–8 + 11 (`ageRange`, `intention`, `prayerFrequency`, `familiarity`, `duaTopics`, `dailyCommitmentMinutes`, `attribution`, `commitmentAccepted`) are captured, persisted, and **never read by anything** — not AI context, not personalization, not notification scheduling. Only `signUpName` and `starterNameId` are genuinely consumed.
4. **The "wall of ChatGPT text":** reflect/muhasabah steps render 2–5-sentence prose blocks per card (1500-token completions); build-a-dua returns up to **3500 tokens**; journal cards dump everything on expand.

---

## 2. What the external evidence says (with the numbers)

- **Deliver the aha before extraction.** Duolingo's deferred signup (after first lesson): **+20% D1 retention**. YouVersion gates nothing behind signup. Calm opens with "What brings you here?" — the user states the feeling first.
- **Long quizzes convert only when each screen visibly changes the output** (Cal AI ~20 steps but every answer feeds the "personalized plan"; +13% activation from merely asking a name). Undifferentiated screens are pure loss (Headspace measured 38% start-to-end drop on its long flow).
- **Paywall/creative continuity:** paywalls that echo the user's stated feeling/goal and the ad's language outperform layout tests (RevenueCat JTBD case: +169% compounded; Adapty ad-matched paywalls ~35% directional). The reel's exact words belong on the paywall.
- **Trial length: 3-day trials are the worst-converting bucket** — 25.5% trial→paid vs 42.5% for 17–32-day trials; 55% of 3-day-trial cancels happen Day 0 (RevenueCat 2026). Our reverse trial is 3 days.
- **Hard paywall vs freemium:** 10.7% vs 2.1% D35 trial→paid, with *identical* 1-year retention (RevenueCat 2026). Showing value first, then a firm gate, is the winning shape.
- **Streaks:** Duolingo D1 12%→55% with streak mechanics; the streak must start during the first session's core action, before signup.
- **Bite-sized content:** microlearning chunking has real evidence (40-study review: significant engagement + retention gains). The reverent-content template is YouVersion's Guided Scripture (tap-through story cards, share-per-section) × Imprint (≤2-min tap-forward decks, auto-save cards). Audio is a premium differentiator, **not** a proven retention lever — instrument before investing.
- **TTS:** gpt-4o-mini-tts ≈ $0.015/min, steerable ("slow, soothing, reverent"), ~6.7× cheaper than ElevenLabs. **Never machine-TTS Arabic scripture** — tashkeel/tajweed errors change meaning; Arabic stays text or human-recorded.

---

## 3. The refactor — four phases

### Phase 1 — Honor the reel: first-session redesign (highest impact, ship first)

**New first session (installed from reel → value in ~30 seconds, 3 taps):**

| # | Screen | Notes |
|---|---|---|
| 1 | **Hook screen = the reel's promise.** "How is your heart today?" + emotion chips + free text. This *replaces* the welcome screen — the feeling input IS the first screen. Visual language matches the reels. | Reuse `first_checkin_screen.dart` as the entry route |
| 2 | **THE REVEAL.** 2s anticipation loader → `NameRevealOverlay` gacha: the Name (Arabic display), meaning, one verse + short dua from the verified catalog. | Expand `StarterNameData.forEmotion` beyond 7 Names using existing `collectible_names.json` + `name_anchors.json` content (static map = instant, free, offline, reliable; AI upgrade is Phase 2) |
| 3 | **Streak Day 1, inline on the reveal.** "You've met your first Name. Day 1." | Duolingo pattern: streak starts pre-signup |
| 4 | **Micro-quiz, 4–5 screens max, every answer visibly personalizes.** Keep: name (feeds tour/greeting tokens), reminder time + push permission (pair them; actually wire reminder → OneSignal), one "what are you seeking" that seeds tomorrow's Name preview. **Cut pages 2–8 + 11** (age, intention, prayer frequency, familiarity, dua topics, commitment minutes, attribution*, pact) — nothing reads them. (*keep attribution only if marketing needs it; it's one screen of pure friction otherwise) | Update `saveOnboardingData` + `analytics_event_names.dart` step-index maps in lockstep |
| 5 | **Plan theater** (`generating_screen` + `personalized_plan_screen`) — now genuinely seeded by the feeling + answers ("Because you're carrying anxiety → As-Salam is your anchor this week…"). | Keep — investment moment |
| 6 | **Deferred signup.** "Save your Name, your streak, and your plan." Apple/Google/email. | Migrate the pre-auth reveal + streak into the account (Duolingo +20% D1 pattern) |
| 7 | **Rating gate → paywall.** Paywall headline echoes the user's own feeling and the reel's language: "There's a Name for every moment you'll face. Keep discovering yours." | JTBD copy; see Phase 4 for trial-length test |

**Kill the forced 9-step tour.** It converts 52% and loses users to anchor timeouts (95/30d) and mid-tour app-backgrounding (161/30d). Replace with:
- Day-0 lands directly in a **first muhasabah that is already primed by the onboarding feeling** (no re-entry needed — the reveal already happened; home shows "Your Name today: As-Salam" with the Go Deeper CTA).
- 2–3 dismissible contextual coachmarks max (Duas tab, streak), never blocking, never multi-step choreography.
- Ship behind `guided_tour_enabled=false` for the new-flow arm — zero code deletion needed to test.

**Flag:** `reel_first_onboarding_enabled` (new `AppConfigService` bool + `flag_reel_first` super property), A/B against current flow per the one-funnel convention.

**Estimated scope:** ~1–2 weeks. Mostly reordering + deletion; the reveal UI, feeling input, flags, and analytics scaffolding all exist.

### Phase 2 — Make the core loop match the reel (the retention fix)

- **Rewire `Begin Muḥāsabah` to feeling-first.** `/muhasabah` opens with the same one-question feeling input, then calls `reflectWithOpenAI` (all 99 Names, personal history/anchors context) → Name reveal → **card still awarded** (keep the gacha tier/collection as the reward layer; the feeling becomes the input, the card the prize). Route through `GatingService.canUse/markUsed` so the freemium economy is untouched.
- Retire `discoverName()`'s blind card-pull as the primary path (keep as offline/AI-failure fallback — the static map covers that too).
- Fix `check_in_completed` to carry `path:'feeling'` and the chosen emotion as a property.
- Deep-link readiness: support `sakina://feel/<emotion>` (deferred deep link from reel link-in-bio) so a "2 Names for anxiety" reel can open the app directly into the anxious→As-Salam reveal. Creative-consistent onboarding is the strongest ad-continuity lever available.
- **Estimated scope:** ~1 week. Engine + UI exist; this is routing + gating + one prompt tweak.

### Phase 3 — Kill the wall of text: reflection beat-decks (+ audio later)

**3a. Structured beats (cheap — do with Phase 2):**
- Change `reflectWithOpenAI`/`getDailyResponse` prompts to emit structured beats (the marker format already exists — tighten it): `hook / reframe (≤2 short paras of 1–2 sentences) / story beats (3 × 1–2 sentences each) / key_line / verse / dua / closing`. Same model call, ~zero cost.
- Render as a **tap-through deck** (5–8 cards, ≤2 min): one idea per card, gold/emerald key-line highlight, gentle line fade-in, manual tap-forward (no auto-advance countdown — reverence over urgency). Hand-rolled `PageView` + tap zones beats `story_view`'s entertainment chrome.
- Last card = **share this card** (per-card share is YouVersion's growth loop; the result card is already the share asset) + auto-save to collection with a soft toast (Imprint pattern — reinforces the existing card economy).
- **Tame build-a-dua:** cut `maxCompletionTokens` 3500 → ~1800, drop the 3 related-duas from the default response (fetch on demand), keep the section-by-section reader. Journal expand-all cards become deck previews.

**3b. Audio (moderate — only after 3a ships and is instrumented):**
- English reflection audio via **gpt-4o-mini-tts** behind a Supabase Edge Function: hash(text+voice+instructions) → check Storage → generate on miss → stream + cache to Storage CDN. ~$0.012 per unique reflection, replays free. Keeps the OpenAI key server-side (aligns with the existing proxy TODO).
- Client: `just_audio` + `audio_service` (+ `just_audio_background`), Hallow-style: short (1–2 min), background-capable, journal CTA after.
- **Arabic is never machine-voiced.** Names/verses/duas stay text; Phase-4-optional human recitation for the fixed catalog.
- Instrument `reflection_audio_played` and let the data decide whether karaoke word-sync (Phase 3c, expensive) is ever justified.

### Phase 4 — Monetization + instrumentation hygiene

- **Trial length A/B: 3-day → 7-day** reverse trial (3-day is the worst-converting bucket industry-wide; 55% of 3-day cancels are Day 0). Coordinate with the running reverse-trial experiment readout (`docs/analytics/reverse-trial-experiment-readout.md`) — do NOT change arms mid-read; queue this as the next experiment after the T0+21d decision.
- **Paywall copy = JTBD + feeling echo** (Phase 1 ships the layout; iterate copy variants here). Show the user's discovered Name on the paywall ("As-Salam is waiting tomorrow").
- **Fill the instrumentation holes:** `reflect_started/completed`, `story_deck_opened/card_viewed/completed/shared`, `names_browse_viewed`, `dua_read`, plus `emotion` on check-in events. We cannot optimize what the reel funnels into if the reel-shaped feature is invisible in Mixpanel.
- **Notifications:** 8 opens/30d means the current pipeline is effectively off. Actually schedule the reminder-time push (it's collected and unused) with content that mirrors the loop: "Your Name for today is waiting." This is the cheapest D1 lever after the streak.
- Refresh `docs/qa/ui-map.md` (stale — still documents legacy 27-page indices).

---

## 4. Sequencing & measurement

| Order | Work | Primary metric | Target |
|---|---|---|---|
| 1 | Phase 1 (reel-first onboarding + tour removal) | onboarding_start → first reveal; → trial_started same-day | reveal <60s for >90%; tour-loss (48%) recovered into check-in |
| 2 | Phase 2 (feeling-first core loop + deep links) | D1/D7 retention; check_in_completed rate | check-in 69% → 80% of openers; D1 +10pts |
| 3 | Phase 3a (beat decks) | story completion (new event); share rate | ≥60% deck completion |
| 4 | Phase 4 (trial length, paywall copy, notifications) | paywall CTA 13% → 25%+; trial→paid | RC benchmarks: median 1.8% install→paid |
| 5 | Phase 3b (audio) | reflection_audio_played, D7 lift | data-gated |

All arms ride the existing one-funnel/super-property convention (`flag_reel_first`, etc.). Min ~200 new users/week currently — expect ~3–4 weeks per clean A/B read at this volume; prioritize big swings (Phase 1) over micro-tests.

## 5. Constraints honored

- No fabricated scripture: reveal content only from `collectible_names.json` / `browse_duas.json` / verified DB; AI still only *selects*.
- No Arabic/English mixing in one `Text`; Arabic never machine-TTS'd.
- Economy writes stay behind `sync_all_user_data()`; AI paths stay behind `GatingService`.
- No new scope from the "What NOT to build" list (no courses, no audio library — reflection audio is per-reflection TTS, not a content library).
- Reverse-trial experiment integrity: no flag flips before the scheduled readout.

---
---

# ADDENDUM (v2, 2026-07-03) — Full-Data Review & Reverse-Trial Retention Strategy

**Decision input (founder, fixed):** keep the automatic 3-day full-premium reverse trial at onboarding + soft paywall after. The app must be maximally retentive inside that window. Planned investments: streaks, companion/avatar, home-screen widgets, Rive animation overhaul.

## A. What the full data says (Supabase production DB + RevenueCat + Mixpanel)

### The business today (RevenueCat, 28d)
650 new customers · 693 active users · **11 active subscriptions · $103 MRR · $266 revenue · 1 active trial**.

### The reverse trial is converting ~1% (Supabase, all-time)
- `trial_premium_until` granted to **82** users → **1** of them ever appears in `user_subscriptions` (production). **~1.2% reverse-trial→paid** vs the RevenueCat reverse-trial case study of **4.5%** (up from 0.4% freemium) and H&F trial→paid median of **37.7%** (opt-in trials, not directly comparable but directional).
- Mixpanel 30d: `trial_activated` 81 → `trial_expired` seen by only 27 → `trial_paywall_surfaced` 32, `soft_gate_dismissed` 88 uniques. **Most trials expire in absentia** — the user is gone before the gate ever renders.
- `daily_cap_hit`: 11 uniques/30d — free-tier limits are barely ever felt, so "premium" has almost no perceived contrast.

### Retention is the broken layer (Supabase cohort, signups 14–60d ago, n=407)
| Day | Active | % |
|---|---|---|
| D1 | 89 | **21.9%** |
| D2 | 69 | 17.0% |
| D3 | 46 | **11.3%** |
| any of D1–D3 | 137 | 33.7% |
| D7 | 32 | 7.9% |

**66% of users never return at all during their 3 premium days.** The trial isn't failing at the paywall; it's failing at re-entry.

### Streaks exist but don't grip
Of 577 users: **414 (72%) never exceeded a 1-day streak**; only 47 ever reached 4+; **5** ever reached 14+; max ever = 20. Live 2+-day streaks right now: 43. `streak_extended` fires for 69% of active users — the mechanic runs, but nothing defends it (freeze exists; no risk messaging, no widget, no repair).

### Conversion is a Day-0/1 event — even with a soft gate
Of 35 all-time production subscriber users: **31 subscribed on Day 0** (avg 0.0–1.1 days from signup across period types); **2** after Day 3. Matches RevenueCat: 55% of 3-day-trial cancels happen Day 0; 82% of trials start Day 0. **Whatever the Day-3 gate does, the fate is sealed in session one.**

### What distinguishes payers: depth, not early frequency (Supabase)
| | Non-subs (n=542) | Subs (n=35) |
|---|---|---|
| Check-ins in first 3d | 1.36 | 1.46 (~same) |
| Days active in first 3d | 1.37 | 1.49 (~same) |
| Cards collected | 3.82 | **6.60 (+73%)** |
| Built duas | 0.68 | **1.86 (2.7×)** |
| Reflections | 0.16 | **0.54 (3.4×)** |

Payers are the users who reached the **AI depth features** (Build-a-Dua, Reflect) and accumulated **collection**. The trial's job is therefore to force-feed exactly these: reveal → reflect story → built dua → cards, in the first sessions.

### Wasted assets
- **575/577 users set a reminder time** in onboarding; notification opens = 8 uniques/30d (~1%). Benchmarks: personalized/contextual push opens at 14.4%; one push received in first 90d → 3× retention. This is the single cheapest broken lever in the product.
- `name_returned` is spread thin across the 99 Names (top name only 23 returns) — the blind gacha yields arbitrary Names, confirming the loop is not feeling-matched (reel mismatch, v1 Phase 2).
- Reflect: 106 rows all-time; Built duas: 436; check-ins: 1,343 (≈2.3/user lifetime). Depth features that predict payment are nearly unused by the median user.

### Live config (app_config, verified)
`onboarding_trim_enabled=true`, `guided_tour_enabled=true`, `hard_paywall_after_tour_enabled=true`, `post_tour_paywall_mode=soft`, `reverse_trial_experiment_enabled=true`, `tour_ab_enabled=false`.

## B. Best-converting format — conclusion from all data

The converging evidence (usage: Name/card/streak loop = 69% of actives while everything else is ≤18%; payers = depth users; conversion = day-0; acquisition = feeling-promise reels) defines the winning format:

> **A daily feeling→Name ritual app.** One sacred daily loop (feel → reveal → 2-minute story-deck → dua → card + streak), delivered in the first 60 seconds of session one, defended by streak+widget+prayer-time notifications, with the AI depth features (Reflect, Build-a-Dua) surfaced *inside the trial choreography* because they are what payers do. Periphery (store, quests overload, browse surfaces) is de-emphasized, not expanded.

Everything in v1 stands and gains urgency: reel-first onboarding (Phase 1), feeling-first core loop (Phase 2), beat-card story decks (Phase 3). What v2 adds is the **retention armor around the 3-day window** and supersedes the trial-length test with trial *choreography*.

## C. Retention stack (evidence-ranked for the 3-day window)

| # | Mechanic | Evidence | Effort |
|---|---|---|---|
| 1 | **First-session reveal (kill the 38h gap)** — v1 Phase 1/2 | 55% of 3-day-trial cancels on Day 0; endowment requires *use*, not access (RevenueCat) | done in v1 plan |
| 2 | **Notification resurrection: prayer-time-aligned, personalized, streak-loss framed** | personalized 14.4% vs generic 4.2% opens; STO +40% reaction; 1 push in 90d → 3× retention; Duolingo bandit +2% new-user retention | S (server + OneSignal; no app release) |
| 3 | **Trial-end choreography** — D0 welcome→D1 nudge→D2 "ending tomorrow + pick your reminder" (Duolingo transparency)→D3 loss-framed soft gate→post-expiry winback | trial-expiry messaging +15–35% trial→paid | S |
| 4 | **Streak defense: freeze auto-consume, 48h repair, at-risk sweep** | Duolingo streak = #1 lever (7-day streak → 2.4× retention); freeze −21% churn; habit science: never hard-reset on one lapse (66-day formation, misses are recoverable) | S-M (SQL/RPC) |
| 5 | **Home-screen widget: streak flame + today's Name (then lock-screen)** | Duolingo widget ≈ +60% daily commitment; bypasses dead push channel, no permission needed | M (4-7d + 2-3d) |
| 6 | **Rive overhaul of the reveal + streak milestones (3/7/30)** | Duolingo phoenix redesign alone +1.7% D7; concentrate on reveal + milestones only | M eng + $2-8K asset |
| 7 | **Non-figurative companion: a growing garden (jannah imagery) fed by the daily loop** | Finch D1/D7 54%/37% on companion loop; Forest 18M users on non-figurative grow-and-tend; ownership psychology (name it, customize it) | L — LAST |
| 8 | Live Activity streak countdown (Dynamic Island) | novel, unproven delta; do after widgets show engagement | M-L |

**Avatar decision: NO figurative avatar/creature.** Figurative depiction is theologically risky for this audience and invites "gamified sacred" backlash (documented for faith apps). The retention mechanic (grows from your actions, return to tend, loss if neglected) transfers fully to: **primary = growing garden** (Quranic jannah imagery, reverence-additive, Forest-proven); **alternative = illuminating geometric khatam / completing calligraphy** (closer to the mushaf aesthetic; the SakinaLoader khatam SVG is already brand language). Users name/lightly customize it (ownership effect). Streak freeze = "your garden is protected"; missed day = wilt, never death (reverent loss-framing).

**Gamification-reverence guardrails:** gamify *showing up*, never the sacred act's quality/minutes; rewards = meaning (Names, verses, garden growth), not confetti-points; gentle loss language; vocabulary = journey/garden/muḥāsabah, never grind/win.

## D. The 3-day trial choreography (target user experience)

- **Day 0 (decides everything):** reel-matched feeling input → full-Rive Name reveal ≤60s → story beat-deck (≤2 min) → streak Day 1 + first card + garden seed planted *in-session* → widget install prompt right after the reveal ("keep your Name on your home screen") → push permission framed as prayer-time reflections → **force one depth feature**: end the first session with a one-tap "seal it with a dua" that runs Build-a-Dua on their stated feeling (payers build duas — make everyone taste it Day 0, premium is free right now). Goal: streak=1, ≥1 depth action, widget or push opted in.
- **Day 1:** prayer-time-aligned push ("As-Salam was your Name yesterday — today's is waiting"). Reveal #2 → streak=2, garden grows visibly. Surface Reflect explicitly ("premium, yours free today").
- **Day 2:** streak=3 milestone micro-celebration (Rive). "Your trial ends tomorrow — when should we remind you?" (transparency prompt). Show the assembled loss object: garden + N cards + streak.
- **Day 3 (soft gate):** loss-framed, personal, in their own words: "Your 3-day streak, your 4 Names, and your garden stay with you — keep going." Countdown Live Activity (later phase). Post-expiry push within 24h; winback grant path already exists (`last_winback_grant_at`).

## E. Implementation notes (2026 state of the art, verified by research)

- **Rive:** `rive` 0.14.9 / `rive_native` 0.1.9 (FFI rewrite; Flutter ≥3.28 OK). Use `Factory.rive` renderer (sidesteps Impeller quirks). Data binding (view models) is the modern API — bind `streakLength`/`growth`/`mood` numbers from Riverpod. Perf vs Lottie: ~32% vs ~92% CPU, ~60 vs ~17 FPS, 10-15× smaller files. **Arabic/RTL text inside Rive = unsupported (no BiDi/shaping) — all Arabic stays in Flutter Text; Rive is the illustrated layer around it.** Pin/cache native lib downloads in CI. Specialist cost $75–150/hr; reveal+milestones ≈ $2–8K; lock the input-naming contract with the animator early.
- **Widgets:** `home_widget` 0.9.3 = plumbing only; widget UIs are native SwiftUI (WidgetKit) + Kotlin (Glance/RemoteViews). Use `renderFlutterWidget` → PNG for Amiri/Aref-Ruqaa typography. **Freshness = multi-entry precomputed timeline** written on every app foreground: entry(now: streak OK) → entry(8pm local: at-risk) → entry(midnight: lost), policy `.after(endOfDay)` — correct with zero background execution. Silent push reconciliation is best-effort garnish only. Effort: w1 static 4-7d, w2 lock-screen +2-3d.
- **Live Activities:** `live_activities` 2.4.9 + **OneSignal first-class LA support** (`setupDefault()`, REST start/update/end; .p8 APNs key required). Countdown ticks natively via `Text(timerInterval:)` — push only to reset/end. 6-10d; do late.
- **Streak server:** per-user IANA timezone; day = `(ts AT TIME ZONE tz - interval '4h')::date` (post-midnight grace); increment inside the check-in RPC (idempotent, `FOR UPDATE`); freeze = ledger-backed inventory auto-consumed on gap=2; repair = 48h-window SECURITY DEFINER RPC + token charge; hourly pg_cron sweep only for boundary freeze-consumption + at-risk push enqueue (pg_net → Edge Function → OneSignal batched `include_aliases`, up to 20K/request, `idempotency_key` on retries). All within the existing `sync_all_user_data()`/RPC economy rules.
- **OneSignal:** current 1% open rate is a targeting/timing/content failure, not a channel failure. **Growth tier required** ($19/mo + $0.012/MAU ≈ $79/mo @5K MAU) for custom events + >2-step Journeys. Journey: enter on `trial_started` custom event → D0/D1/D2 drip → exit-branch on `subscribed`. Free-tier workaround meanwhile: `delayed_option: last-active` on API sends. `OneSignal.login(supabaseUserId)` for external_id targeting. Server keys live in Edge Function secrets only.

## F. Revised roadmap (supersedes §4 sequencing)

| Wk | Ship | Why now |
|---|---|---|
| 1 | **Notification journeys + trial choreography + streak-risk cron** (OneSignal Growth, `trial_started` event, D0/D1/D2 drip, prayer-time/reminder-time sends, 8pm streak sweep) | No app release needed; directly targets the window where 82→1 is happening; cheapest lever |
| 1–2 | **Streak freeze/repair server-side** (+ garden `growth` scalar derived from streak/XP) | Pure SQL, de-risks widgets/LA; proven churn reducer |
| 1–3 | **v1 Phase 1: reel-first onboarding + kill forced tour** (flag `reel_first_onboarding_enabled`) | The Day-0 fix; tour loses 48%; reveal must land ≤60s |
| 2–3 | **Commission Rive specialist** (reveal + streak milestones; asset production is the long pole) → integrate `rive` 0.14.9 | Wow-factor for the only sessions trial users see |
| 3–4 | **v1 Phase 2: feeling-first core loop + Day-0 forced depth taste (Build-a-Dua seal, Reflect surfacing)** | Payers = depth users; make every trial user taste depth |
| 4–5 | **Home-screen widget w1** (streak flame + today's Name, precomputed timeline), then lock-screen w2 | +60% daily-commitment analog; bypasses push apathy |
| 5–6 | **v1 Phase 3a: story beat-decks** (structured beats, share-per-card) | Kills the wall of text; share loop |
| After signal | Live Activity countdown → **garden companion** (Rive, non-figurative) → TTS audio (v1 Phase 3b) | Expensive bets sequenced after funnel is patched and Rive pipeline exists |

**Metric targets (re-based):**
- Reverse-trial→paid: **1.2% → 4%+** (RevenueCat reverse-trial benchmark 4.5%)
- D1: **22% → 40%**; D3: **11% → 25%** (Finch: 54% D1 is the ceiling to aim at)
- % of trial users doing ≥1 depth action (reflect or built dua) in D0: **~15% → 60%**
- Live 2+ streaks: **43 → 150+**; notification opens: **1% → 10%+**
- Instrument everything new: `reflection_*`, `widget_installed`, `garden_*`, `trial_day{n}_returned`, journey events.

**Standing cautions:** reverse-trial experiment readout integrity (no arm/flag flips before the T0+21d read — the choreography Journey targets *both* arms' trial users, which is fine since it acts post-assignment; note it as a covariate in the readout). OneSignal REST key server-side only. Arabic never inside Rive or TTS. Economy writes stay behind RPCs.

## G. The Promise Ledger — making onboarding personalization REAL, not theater (v2.1)

**Rule: every onboarding input must have a named, code-level consumer, and every promise the onboarding makes must be verifiable by the user within 24h.** The legacy flow's failure wasn't length — it was that 8 pages of answers fed nothing. Length is fine (Cal AI runs ~20 steps) *only when each screen visibly compounds into the output*. This section pins the wiring.

### G1. Reel → app contract (the promise enters in concrete form)

Each reel campaign gets a **promise payload**: `{reel_id, hook_type: names|story, name_ids: [..], emotion}` — e.g. the "2 Names that will change everything" reel featuring Al-Wadud + Ar-Razzaq ships `name_ids:[47,17]`.

- **Path A (deferred deep link, preferred):** link-in-bio → `sakina://reel/<reel_id>` — onboarding opens already knowing the promise: "You came for Al-Wadud. Let's begin there." The featured Name becomes the starter reveal (or Day-1 follow-up if the feeling maps elsewhere).
- **Path B (no link attribution, always works):** repurpose the currently write-only attribution screen into a **"What brought you here?"** selector whose options are the live reel hooks ("A reel about 2 Names…", "A message that felt meant for me…", emotion chips). The selection resolves to the same promise payload locally. This converts the one pure-marketing page into a functional personalization input.
- Persist as `user_profiles.acquisition_promise` (jsonb). Consumers: starter/next reveal selection, plan screen, paywall copy, D1 notification.

### G2. Answer → consumer map (enforced; anything without a consumer gets cut)

| Input | Named consumers (all must be wired, not aspirational) |
|---|---|
| Feeling (free text + chip, page 0) | starter Name selection · stored raw as `first_feeling_text` · echoed verbatim on paywall + Day-3 gate ("the weight you named on day one") · seeds `reflectWithOpenAI` context · D1 push copy |
| Reel promise (G1) | starter/Day-1 Name queue · plan screen content · paywall headline |
| "What are you seeking" (single kept quiz Q, maps to `aspirations`) | drives the **Name queue** (G3) · AI teaching-context bias · notification content rotation |
| Display name | greeting/tour tokens (already real) |
| Reminder time | **actually schedules** the OneSignal daily send (v2 wk-1 work) — closes today's 575-captured/0-used gap |
| Push permission | OS-level (already real) |

### G3. The plan screen becomes a real artifact: the 7-Name Journey

Replace the static "✨ Crafted for you" tiles with a **concrete, server-stored queue**: from `{feeling, promise, aspiration}`, assemble the user's first 7 Names (e.g. anxious + "2 Names" reel → As-Salam today, Al-Wadud tomorrow, Ar-Razzaq day 3…). Store it (`user_name_queue` table or jsonb column, written via the existing RPC layer), and make the daily loop **consult it**: tomorrow's reveal and tomorrow's push are literally the plan's row 2.

This is the hammer: the plan screen shows "Tomorrow: Al-Wadud — the Name your reel spoke about," the D1 prayer-time push says "Al-Wadud is waiting, as promised," and the Day-1 reveal delivers exactly that. Promise → artifact → verification, three times in 48h. (The feeling-first loop of Phase 2 overrides the queue whenever the user states a new feeling — stated feeling always outranks the queue; the queue is the default when they just show up.)

### G4. Acceptance test for any future onboarding screen

Before adding/keeping any screen, it must pass: **(a)** does its answer change what the user sees within 24h, through a consumer named in code? **(b)** can the user *catch us keeping the promise* (see it referenced later)? If either fails → cut it or fix the wiring. This test is the durable form of the "no write-only pages" finding.

---
---

# v3 (2026-07-03) — The 3-Day Hook Architecture: engineering daily return during the reverse trial

**Goal (founder):** every new user gets 3 days of full premium → they must use the app every one of those days, multiple times a day, so the Day-3 soft gate lands on a habituated, invested user. This section supersedes v2 §D (trial choreography) and refines the v2 roadmap; everything else stands.

**Research base:** Hooked model / variable-reward / appointment-mechanic literature (Duolingo, Finch, Forest, Clash Royale, BeReal, Pokémon GO), mobile-gaming FTUE + first-72h doctrine (GameAnalytics benchmarks, endowed-progress study, login-calendar design), and a full inventory of Sakina's existing engagement code.

## H1. What the codebase inventory found (all systems exist; three defects block the strategy)

Existing & tunable: 3-tier quest system (3 daily/weekly/monthly, deterministic rotation — `quests_provider.dart`), 7-day escalating reward strip with day-4 freeze (`daily_rewards_service.dart:39-81`), streak milestones 7/14/30/… with title unlocks (`streak_service.dart:39-67`), 4-tier card gacha with new-card-first priority (`card_collection_service.dart:1815`), XP/25-level/title ladder, token economy (50 start; IAP-only sink), 5-category OneSignal notification service. All code-constant (no remote config) — tuning requires app releases; consider moving key dials (reward tables, odds) to `app_config` while in there.

**Defect 1 — UTC day boundaries.** Daily/weekly/monthly resets and the muḥāsabah "new day" all flip at UTC midnight (`quests_provider.dart:564-574`), i.e. 4-5 PM in California, 3 AM in Jakarta. Any morning/evening choreography is incoherent until day boundaries are per-user local time (store IANA tz; v2 §E streak-server pattern already specifies this). **Prerequisite for everything below.**

**Defect 2 — zero appointment mechanics.** Nothing in the app matures, unlocks, or changes between two opens on the same day. There is currently *no reason to open Sakina twice*.

**Defect 3 — the reward curve is backwards for a 3-day trial.** The strip pays its weakest rewards on days 1-3 (5/10/15 tokens) and saves the exciting drops (freeze day 4, scrolls day 6, 30 tokens day 7) for after the trial is over. Meanwhile the gacha's first pull always lands at **Bronze — the lowest tier** — so the single most important reveal of the user's life with the app is the least impressive one. Games do the exact opposite (beginner's-luck boosted first pulls; final-day-spike login calendars).

## H2. The two-session backbone: morning & evening adhkar (the core mechanic)

Duolingo's Early Bird + Night Owl chests are the cleanest published two-sessions-per-day engineering (do a lesson before noon → chest unlocks 6pm; do one after 6pm → chest unlocks next morning — each session arms the next). **Sakina gets this pattern with religious legitimacy Duolingo can only fake:** morning and evening adhkar are already the two canonical devotional bookends of a Muslim's day, and salah provides up to five natural anchors (habit-stacking doctrine: attach the new habit to a rock-solid existing anchor — Tarteel explicitly teaches "after Fajr" stacking).

- **Morning session (post-Fajr / user's morning window):** short morning adhkar (seeded from `browse_duas` `when_to_recite` tags — verified content, no AI) → daily Name reveal (variable tier) → claim reward-strip day → **plant an intention** (one tap: "today I seek patience / As-Sabur"). Planting the intention **arms the evening session** (investment → next trigger).
- **Daytime maturing (Finch appointment, care-framed):** the intention "is being prepared" — the AI reflect story for their intention/feeling generates and **matures during the day**. Copy is anticipation ("your reflection is being prepared"), never countdown-panic. This is also how the trial force-feeds the depth features payers use (v2 §A).
- **Evening session (evening adhkar window):** evening adhkar → **harvest the matured reflection** (beat-deck story, v1 Phase 3a format) → journal line (investment) → tomorrow's Name teased from the 7-Name queue (§G3). Completing morning+evening both = a small "barakah boost" live at next login (Duolingo's guarantee-a-reward-on-next-open trick).
- Quests: during the trial, one of the 3 daily quests is morning-anchored, one evening-anchored ("Morning Light" / "Evening Light"), replacing two rotation slots.
- **Prayer-time/adhkar-time push is the appointment engine** (Muslim Pro's model); reminder-time is already captured for 575/577 users. Day-0 must aggressively confirm the reminder — Calm's single strongest retention lever: **users who set a daily reminder retained 3×**.

Target: 2 solid opens + 1 optional micro-open (post-Dhuhr "dua of the moment") per day by Day 1-2. The test that the internal trigger has formed: user opens *before* the push fires.

## H3. "Your First Days with the Names" — the Trial Journey (trial-as-event, not passive access)

Reframe the auto-granted premium from invisible entitlement → a **visible 3-day journey with a milestone track** (battle-pass-lite, reverently framed). Hard evidence anchors: endowed progress (10-stamp card pre-stamped 2 = **34% vs 19%** completion — start the track at **2/8**, truthfully: the reveal + account are stamps 1-2); one day-1 achievement completion = **33.4% vs 20.4%** next-day retention (guarantee it); the D1→D2 cliff is the biggest churn moment (fix with an unfinished-business hook); the trial decision is made in-window and most users never re-encounter a paywall (fire the gate at the completion peak).

| Beat | Trigger | Grant (existing economy) | Lever |
|---|---|---|---|
| Start | first launch | Journey track shown **at 2/8** ("two doors already opened") | endowed progress |
| D0 reveal | first muḥāsabah | **guaranteed Silver+ or "blessed" luminous variant** (beginner's barakah) + token bundle + first quest auto-completes | guaranteed win; day-1 achievement |
| D0 close | end of session 1 | **locked card "unsealing overnight"** + first set (e.g. Names of Mercy: Ar-Rahman ✓ / Ar-Raheem ✓ / Al-Wadud 🔒) shown **2/3** | Zeigarnik; D2 rescue |
| D1 morning | return | unsealed card → **set 3/3 → Gold card + Sabr Shield** (streak freeze, granted not sold) | comeback visibly bigger than D0 |
| D1 evening | matured reflection | beat-deck story + journal; track → 5/8; **Emerald + Title teased for D2-3** | open next loop |
| D2 | both sessions | rarest drop of the trial (**Emerald / blessed calligraphy variant**) + **"Gift a dua"** unlock (make a dua for someone — intercession-framed social; Duolingo friend-streak lift: +22%) | peak + social investment |
| D3 finale | journey complete | track **8/8** + permanent **Title "Seeker of the Names"** (kept forever, even unsubscribed) | identity + loss anchor |
| D3 gate | at the completion moment | soft paywall as **continuation**: "your streak, your 8 Names, your journal — the path continues"; collection shown as already-theirs | in-window conversion at emotional peak |

## H4. Concrete tuning of existing systems (TUNE, don't rebuild)

1. **Local-time day boundaries** (Defect 1) — per-user IANA tz + grace window; migrate quests/rewards/muḥāsabah/streak together. Prereq.
2. **Re-curve the reward strip** (Defect 3): move the freeze ("Sabr Shield") to day 2, put a visible spike on day 3 (trial end), keep day-7 as the biggest single prize (pull through week 1). Days 1-3 must each feel *bigger than the last*.
3. **Beginner's barakah odds** (gacha): first reveal guaranteed Silver+; boosted tier odds days 0-2; **dignity floor** thereafter (soft pity: never let a user go long without a Gold+/blessed reveal — framed as generosity, never shown as a meter). Add the low-odds **"blessed" luminous card variant** (special calligraphy) as the rare-pull imprint (rare-reward fMRI: rarer outcomes → stronger reward response & re-engagement urge). **Every reveal is spiritually valuable — no dud outcomes, ever.**
4. **Appointment layer** (Defect 2): the overnight unsealing card (D0→D1) + the daytime maturing reflection (morning→evening) are the only two timers needed. No chest-queue mechanics (Clash Royale's own maker retired them as coercive).
5. **Quest slots**: trial-period morning/evening anchored quests (H2); post-trial, keep Early-Bird/Night-Owl as the daily structure.
6. **Widget & Live Activity** (v2 roadmap): widget shows streak + today's Name + "evening reflection ready" state — the passive external→internal trigger bridge (Tarteel/Muslim Pro pattern).
7. **Churn-flag intervention**: session-1 signals (sub-60s session, no reward claim, no card added) → flag → tailored D1-morning push + small token grace on next open (early-churn ML literature: 1 day of data predicts churners at ~73-81%; personalized targeting beats blanket).

## H5. The reverence firewall (hard rules)

- **No paid randomness, ever.** Real money must never buy a random pull — regulatory tripwire (Belgium/NL loot-box rulings) and *maysir* (gambling), categorically haram. Tokens for deterministic things only.
- **No public worship leaderboards** — riya' (ostentation in worship) is a spiritual harm; private progress only.
- **No panic/guilt copy** — no hourglass emojis, no "don't lose everything!", no Snapstreak-style social debt ("you let X down"). Streak loss is forgivable by design (freeze auto-consume + 48h repair); copy mirrors tawbah/mercy, not punishment.
- **Anticipation framing, not scarcity framing** — "your reflection is being prepared," never "offer expires in 03:59:59." (Trial-end countdown is the one allowed clock, stated plainly and transparently — Duolingo's user-chosen reminder day pattern.)
- **Social = praying for each other** (gift a dua, family adhkar circle), never obligation or comparison.
- Gamify **showing up**; never score the worship itself (no "prayer quality points," no minutes-of-dhikr leaderboards).

## H6. Roadmap deltas (v2 roadmap holds; these slot in)

| Change | Where it lands |
|---|---|
| Local-time boundary migration (tz column + RPC/cron updates) | with wk-1-2 streak-server work (same migration) |
| Reward-strip re-curve + beginner's barakah odds + blessed variant | first app release alongside reel-first onboarding (wk 1-3) |
| Trial Journey track (8 stamps, endowed 2/8, title) + D3 gate-at-completion | wk 2-4 — client feature, replaces v2 §D choreography; the OneSignal D0/D1/D2 Journey (wk 1) becomes its push layer |
| Overnight unsealing card + maturing reflection (appointment layer) | wk 3-4, with the feeling-first core loop (Phase 2) — the maturing reflection IS reflectWithOpenAI output, pre-generated |
| Morning/evening adhkar sessions + anchored quests | wk 4-6 (needs local-time boundaries + adhkar content curation from browse_duas; new light UI) |
| Gift-a-dua social mechanic | after trial-journey ships (uses existing gift/referral rails) |
| Move reward/odds tables to app_config (remote tunability) | opportunistic, during the strip re-curve |

**New metrics:** opens/day during trial (target ≥2 by D1), D2 return (17% → 35%), Trial Journey completion rate (target ≥40% of D1 returners), % trials reaching the D3 gate *in-app* (27/81 → 60%+), reveal→evening-session same-day rate, gift-a-dua sends. Instrument: `journey_stamp_earned`, `session_slot{morning|evening|midday}`, `card_unsealed`, `reflection_matured_opened`, `dua_gifted`.

**Sanity note on ceilings:** GameAnalytics top-quartile D1 is ~27-33%; Finch (best-in-class wellness) is 54%. Current 22% → the 40% v2 target is aggressive-but-bounded; the mechanisms above are how the gap closes. Habit science says 3 days starts a habit but doesn't lock it (~15-66 days) — so the post-gate free tier must keep the streak/adhkar rhythm alive (streak, widget, morning/evening sessions all stay free; premium anchors = depth features + full journey continuation), or D3 conversion gains will churn back out at week 2.

---
---

# v4 (2026-07-18) — Reconciliation with the 2026-07-14 conversion diagnosis

The independent diagnosis in [`docs/analytics/2026-07-14-conversion-diagnosis-and-research.md`](../../analytics/2026-07-14-conversion-diagnosis-and-research.md) (fresher data: 30d cohort n=646, all-time subscribers n=42) **confirms this plan's core findings** (tour = leak #1; payers = depth users; Day-0 conversion — now 76% of n=42; dead notifications; reel-promise mismatch; quiz length not the problem) and **adds four things this plan lacked**. This section folds them in and adjudicates the one real conflict.

## V4.1 The conflict: reverse trial vs the control arm

The 07-14 read shows **control_no_trial ~5% vs treatment_reverse_trial ~1.2%** conversion (directional; severely underpowered at ~4 assigned/arm/day vs ~1,500/arm needed). Combined with: 76% of subscribers convert Day 0 · RC data that app-granted trials ending at a *soft* gate are the weakest configuration · 191 free soft-gate dismissals/30d — the v2/v3 premise ("keep the 3-day reverse trial and win via in-trial retention") is under real pressure.

**Adjudication:** the powered readout will never arrive at current volume, so treat the arm question as an *active experiment program*, not a settled decision:
- **Do not sunset the reverse trial silently** — the founder decision stands until an explicit re-decision, but the next experiment after first-run fixes is **gate architecture** (07-14 changelist #3): onboarding paywall leading with a **7-day StoreKit opt-out trial**, and/or reverse trial ending at a **harder** gate, with trial messaging tied to completing 2-3 muḥāsabahs. Sentiment guardrails (reviews) alongside conversion — faith audiences punish clawbacks.
- **Re-scope v3 accordingly:** the 3-Day Hook Architecture is a **retention program, not a conversion engine**. The 07-14 H2 verdict is right: no causal evidence that manufactured frequency lifts paid conversion (Wordle; Duolingo's Gardenscapes transplant = zero effect); mechanics amplify value that landed. v3's Trial Journey / choreography still pays for itself in D1/D7 — but it sequences AFTER first-session value and gate architecture, and its design must adapt to whichever gate wins (if the StoreKit-trial arm wins, "Your First 3 Days" becomes "Your First Week," paced to the 7-day trial).

## V4.2 New workstreams adopted from the 07-14 changelist

- **W-A: Free-tier tightening (changelist #4).** Only 3% of MAU ever hit the AI cap → the paywall is invisible in normal use (benchmark: 80%+ of D1 users should *see* one). Replace the never-felt 1/day cap with a small taste (e.g. 3/week or lifetime intro allowance) on Reflect/Build-a-Dua; premium = unlimited + journal history/insights. **Never cap the core muḥāsabah loop.** Staged % rollout, grandfather actives, retention + review-sentiment guardrails. (Insight Timer vs Calm is the category lesson; "dismissible + nothing meaningful locked" is the named soft-gate failure mode.)
- **W-B: Checkout-leak instrumentation (changelist #7).** `purchase_started` → RC reconciliation; recovery offer on sheet-cancel. 86 CTA taps → ~14-19 paid is currently un-diagnosable.
- **W-C: Install→signup instrumentation (changelist #10).** The one unmeasured funnel stage (ASC installs ↔ signups).
- **W-D: Seasonal/Ramadan challenge architecture (changelist #8).** Hallow's Lent = 4-7× downloads and ~25% of annual revenue in one month; `islamic_occasions` infra exists. Build a 30-day Ramadan muḥāsabah journey + Jumu'ah weekly beat + Eid re-engagement (for the documented post-Ramadan dip). Long lead time — start well before Ramadan 2027; ship the Jumu'ah beat much earlier.

## V4.3 Status notes (as of 2026-07-18)

Already shipped since the 07-03 snapshot: **duʿā-times home-screen widget** (built, pending Xcode target membership + device QA), **Live Activities v1** (merged, PR #54), **duʿā-windows observability** (merged, PR #55). These partially deliver v2's widget/LA roadmap items. The animation pipeline in production is **Lottie** (name_reveal, breathing_star via the text-to-lottie pipeline) — the v2/v3 "Rive overhaul" is now a *decision to make* (extend Lottie vs migrate to Rive for data-bound interactivity), not a given.

## V4.4 Unified implementation order (supersedes v2 §F and v3 §H6 sequencing)

**Wave 0 — ship blind, this week (all S effort, reversible, evidence overwhelming):**
1. **Kill the forced tour** → contextual coach-marks, straight to first muḥāsabah (`guided_tour_enabled=false` + 2-3 dismissible marks). Expected: +40-50% core-loop/paywall reach.
2. **Reminder prompt right after first check-in** + fix the dead pipeline (prayer-time-anchored, ≤1/day). Calm's causal 3× retention lever; 575/577 reminder times already captured.
3. **Streak forgiveness**: freeze auto-consume + repair window + gentle copy (never "you broke your streak").
4. **Instrumentation bundle**: W-B checkout leak, W-C install→signup, reflect/story events (v1 Phase 4 holes), `emotion` on check-ins.

**Wave 1 — reel-first first-run (L, A/B via `reel_first_onboarding_enabled`):**
5. Feeling→Name reveal in ~3 taps · "What brings you here?" reel routing (§G1) · cut only the ~8 dead pages (keep the healthy quiz — Adapty's −13% over-cutting warning) · 7-Name Journey queue makes the plan screen real (§G3) · paywall echoes the reel promise + their feeling · deferred signup after the reveal.

**Wave 2 — monetization architecture (the revenue lever; sequential big-effect A/Bs at ~21 signups/day):**
6. **Gate architecture A/B** (V4.1): 7-day StoreKit opt-out onboarding trial vs reverse-trial-ending-harder. New-user cohorts.
7. **Free-tier tightening (W-A)** — staged rollout on existing actives (separate population from #6), grandfathering + guardrails.

**Wave 3 — retention program (v3, adapted to the winning gate):**
8. Trial/first-week choreography: OneSignal Growth journeys (D0/D1/D2 drip, streak-risk cron) — server-only, can start during Wave 2.
9. Local-tz day boundaries + reward-strip re-curve + beginner's barakah odds + Trial Journey track (endowed 2/N, overnight-unsealing card, gate-at-completion-peak) — paced to the winning gate length.
10. Ship the built widget (QA + release), then streak/Name widget variant; beat-deck story format (v1 Phase 3a); animation-overhaul decision (Lottie-extend vs Rive) applied to reveal + streak milestones only.

**Wave 4 — compounding bets:**
11. **W-D Ramadan/seasonal architecture** (start design ~Nov-Dec 2026; Jumu'ah beat earlier), morning/evening adhkar two-session structure, gift-a-dua, garden companion, TTS audio — each gated on the prior wave's signal.

---
---

# v5 (2026-07-23) — Founder direction: reel-verbatim onboarding + the gate decision

Inputs: founder braindump 2026-07-23 · fresh experiment pull (Supabase, cohort since T0 2026-06-18) · dedicated hard-vs-soft paywall research pass (RevenueCat SOSA 2026, Adapty 2026, Superwall, Airbridge, Rootd/Purchasely, Duolingo financials, faith-app gate teardowns) · git-log reconciliation of shipped work.

## V5.1 Phase-1 spec revision — the onboarding mirrors the reel *verbatim*

Supersedes the v1 Phase-1 screen table and sharpens §G:

1. **Hook screen = the reel's question, not a generic feeling prompt.** The reels promise *"two Names of Allah that are the solution to your problem."* So the first screen asks for **the problem** — same register as the reel ("What's weighing on you right now?" / problem chips + free text), reusing the existing problem-input pattern already built for Reflect/find-duas. "How is your heart today?" is retired as too generic — it breaks the ad-scent.
2. **The reveal = the full experience, not a teaser.** Reels are verbose (Name + dua + verse + story); a short reveal under-delivers against the promise. The onboarding reveal is the **complete story-deck** in the shipped format (tap-through IG-story beat deck, new animations): Name → story → verse → dua → shareable result card. **Two-Name structure:** reveal Name #1 in full; **tease Name #2** ("the second Name of your answer") as sealed — it unseals on Day 1. This honors the reel's "2 Names" framing exactly AND becomes the D1 comeback hook (v3's overnight-unsealing card, now with narrative justification).
3. **Every post-reveal question derives from the stated problem.** Cal AI-style investment, zero filler: each question visibly refines *their* plan for *their* problem (e.g., "How long have you been carrying this?", "When does it hit hardest?" → sets reminder time, "Who else is affected?" → seeds gift-a-dua), flowing into the 7-Name Journey queue (§G3) and the plan screen. §G4 acceptance test is binding: any question that doesn't visibly change the output within 24h doesn't ship.

## V5.2 Shipped-status reconciliation (as of 2026-07-23)

Done since the plan was written (git-verified): **Phase 3a beat decks** (wall-of-text fixed — story-deck reveal flow + Build-a-Dua in the sacred-canvas format) · **streak overhaul Phases 0–3** (soft-decay ladder, paid repair + excused days, server-side milestone claims, freeze-burn reunion card, month-of-light calendar, reverent notification copy, winback cooldown) · **lantern companion** (non-figurative, per the v2 reverence guidance — placed on 3 in-app surfaces) · **widgets** (gallery: Duʿā Times → Name → Lantern; lock-screen lantern; after-8pm at-risk state via precomputed timeline) · **Live Activities v1** · **emerald premium cards** (+ new-card badges) · **unified notification decision model** · **level-up/milestone/reveal Lottie animations** · **paywall benefit checklist + free-user premium strip**. Net: v4's Wave 0 and Wave 3 are substantially **complete**; the outstanding big rocks are exactly Wave 1 (reel-first onboarding) and Wave 2 (gate architecture) — which v5 merges into one ship (below). The animation stack is settled: **Lottie pipeline is production reality**; Rive is off the table unless a future need for data-bound interactivity forces it.

## V5.3 The gate decision — from two soft arms to a front-loaded hybrid

**Fresh experiment read (prod subs, signups since 2026-06-18):** control (no trial, post-tour soft gate) 410 → 10 subscribed (**2.44%**) vs treatment (3-day reverse trial → soft gate) 358 → 6 (**1.68%**). Underpowered (16 conversions total), but the directional story is now stable across two pulls: **the reverse trial isn't winning, and BOTH soft arms sit at the freemium median (~2.1%)** — the ceiling is the gate model, not the arm. (This supersedes the stale "control ~5%" figure quoted 07-14; the plan's targets are re-based below.)

**What the research says (key numbers; full report in the findings doc):**
- Install→paid is the right decision lens (per-view stats favor soft only because fewer users ever reach a soft wall). Hard paywall median **10.7% install→paid D35 vs freemium 2.1%** (RevenueCat SOSA 2026, 115k apps); revenue/install ~8-9×; 1-yr retention identical; refunds run higher (+70%: 5.8% vs 3.4%).
- **Onboarding placement beats in-app** (1.35% vs 0.89% with trial — Adapty); multi-page value-establishing paywalls **+37%** (Superwall); **a real store trial is the biggest LTV lever** (weekly no-trial $7.40 → 3-day trial $54.50, +636%; trial users retain 1.4-1.7×).
- **The Rootd "5×" case is the template and it is NOT a locked door:** a *dismissible trial paywall moved to the front of onboarding* → ~5× revenue, near-zero negative feedback. The winning shape = front-loaded + trial + dismissible-to-limited-free ("secret freemium"), not a true hard wall.
- **The Duolingo model does not transfer:** ~9.1% paid penetration works because 137.8M MAU × ads on the 93% who never pay + zero marginal content cost. "Freemium math works at 1M+ monthly actives; it rarely works at 10K" (Airbridge). Sakina is two orders of magnitude below the threshold, and ads corrode reverence. Duolingo's own hard-ish experiment (Hearts→Energy throttling) drew mass backlash — the lesson is *never throttle your own value proposition*, which for Sakina means never gate the daily Name/scripture.
- **Why our reverse trial lost, per the literature:** endowment only works if premium is *felt* — behind a toothless gate (191 free dismissals/30d; 3% cap-hit) expiry is a non-event. "If they don't use the premium features, nothing changes" (RevenueCat).
- **The faith line (backlash evidence):** anger targets gating *scripture itself* (Muslim Pro/Quran-app reviews); Hallow (~85% gated, $69.99/yr, paywall in first session, daily devotional free) and Glorify ($83.88/yr, daily devotional free, "sponsor a membership" mechanic) prove gating **personalization/tools/depth** is accepted. YouVersion sets the "scripture is free" norm.

**DECISION (supersedes v4 Wave 2 item #6 and closes the reverse-trial experiment):**
Ship a **front-loaded, hard-looking, dismissible-to-limited-free paywall with a real RevenueCat trial (3-day *[superseded → **7-day**, see §V6.3.2]*, annual-anchored, weekly-equivalent price framing), placed at the emotional peak at the end of the new reel-verbatim onboarding** (after problem → full reveal deck → derived questions → plan). Multi-page (2-3 value screens echoing *their* problem and Name). On dismiss → genuine limited free tier, 24h welcome offer to non-converters, backup offer on checkout-close, re-present on reopen.
- **Stays free forever (reverence + growth loop):** the 99 Names, verses, duas, the daily Name reveal *with its story deck and shareable result card* (the share loop must survive the gate), streak/companion/widget rhythm.
- **Gated (this defines the tightened free tier — absorbs workstream W-A):** AI-personalized muḥāsabah depth (Reflect), Build-a-Dua beyond a small taste (e.g. 3/week or lifetime intro), journal history/insights, emerald tier, second-Name-of-the-day depth. Grandfather existing actives.
- **App-granted reverse trial: retired.** Record the final directional read (2.44% vs 1.68%) in `docs/analytics/reverse-trial-experiment-readout.md` and close that experiment before the new one starts — no silent flag flips.

**A/B design (low-volume discipline):** 2 arms — current soft control vs new onboarding+hybrid gate — 50/50 with a 10% permanent soft holdout after rollout. Pre-registered 6-8 week window, no peeking; early read (2wk) on Day-0 purchase rate + checkout-starts, decision on D30 revenue-per-install. Guardrails watched daily: App Store review velocity + star trend, refund rate, D1/D7 retention vs control. Note the new onboarding and the new gate ship as ONE arm intentionally — at ~21 signups/day we cannot afford factorial separation, and the gate presupposes the value-rich onboarding (this A/B tests the *package*).

**Re-based targets:** signup→paid 2.4%/1.7% → **5-8% conservative** (hybrid at Day-0 peak; hard-median 10.7% is the stretch); MRR $103 → $200+ on current volume; trial LTV effect compounds via the real store trial.

## V5.4 Updated implementation order (supersedes §V4.4)

1. **The One Ship (now):** reel-verbatim onboarding (V5.1) + hybrid front-loaded gate w/ real trial + tightened free tier (V5.3), as a single A/B arm vs current soft control. Includes closing the reverse-trial experiment cleanly.
2. **Instrumentation that must ride along:** `purchase_started`→RC reconciliation (checkout leak), install→signup (ASC), problem-input + deck + second-Name-unseal events, arm super-property per convention.
3. **Post-ship reads:** 2wk early read → D30 RPI decision → guardrail review; then iterate paywall pages/offers (the fast-metric loop).
4. **Next big rock after the read: Ramadan/seasonal architecture (W-D)** — design by ~Nov-Dec 2026; Jumu'ah weekly beat earlier if capacity allows.
5. **Backlog (signal-gated):** morning/evening adhkar two-session structure, gift-a-dua, TTS audio, Trial-Journey-style first-week track re-paced to the real 3-day store trial.

---
---

# v6 (2026-07-23) — Reel-contract audit: five-agent review of the full plan against the two live reel formats

**Input:** founder supplied the verbatim content of the two live acquisition reels; five parallel audit agents reviewed every phase (onboarding, gate, measurement, retention/seasonal, cross-cutting) for reel-traceability + research-alignment, with codebase spot-checks. This section amends v5 in place; where v6 conflicts with v5/v4/v3 text, **v6 wins**.

**The two reel contracts (ground truth):**
- **Reel 1 — "2 Names of Allah that have the solutions to your problems"** (problem → "is that you?" → 2 Names, each explained *against the problem* + a prophet/companion story). A **diagnosis contract**: state my problem → get TWO Names → each explained for MY situation → story included.
- **Reel 2 — "Allah is sending you a sign right now"** (struggles/pain/doubt/burdens → Allah is aware, never burdens a soul beyond what it can bear → learn about Allah and His Names). A **recognition contract**: the viewer carries a *vague, unnamed* burden and believes the encounter was meant for them. Promises: being seen, comfort (2:286 theme), and an *ongoing journey of learning the Names* — NOT a problem-solution transaction.

**Headline audit finding:** v5 was written almost entirely against Reel 1. The plan already contains the Reel-2 routing primitive (§G1 `hook_type: names|story`; the "message that felt meant for me" selector option) but **no screen ever consumes it** — a Reel-2 arrival hits a mandatory problem-intake form they cannot answer. Second-order findings: two places where the plan is one ambiguous sentence from paywalling the reel's literal promise; onboarding story decks currently depend on runtime AI (fabrication risk at the moment of highest trust); several Step-6 backlog items still target the retired reverse-trial architecture; and the notification channel got new plumbing but still ships generic copy.

## V6.1 Two-contract onboarding — serving the "sign" reel without a second path

Two flows is the wrong answer at ~21 signups/day (2-arm ceiling; the V5.3 A/B already consumes both arms; both reels converge on the same product — daily Name + deck + journey + gate; they differ in *register*, not structure). **Ship one flow, adaptive at three branch points, keyed on `acquisition_promise.contract: 'problem' | 'sign'`.** The Reel-1 path is byte-identical when a problem chip is tapped.

- **Router (amends V5.1.1):** the hook screen's chip set gains one final, visually distinct chip: **"I can't put it into words — everything just feels heavy."** Tapping it (or `hook_type:story` from the What-brought-you-here selector / deep link) sets `contract='sign'`; any problem chip or free text sets `'problem'`. Confirmation microcopy is the recognition moment itself: *"You don't have to name it. Allah already knows."* Free text stays available, never required. Note: the existing `first_checkin_screen.dart` chips are **emotions** (anxious/sad/…); the chip set must be rebuilt in **problem register** for Reel 1 — the plan's reuse-the-Reflect-pattern claim covers the input widget, not the chip taxonomy.
- **Branch A — reveal deck (amends V5.1.2):** for `contract='sign'`, the deck opens with a **recognition beat** before the Name ("You didn't find this by accident") followed by the burden-comfort verse (2:286 theme) **from the verified verse catalog only** (pre-ship task: confirm the catalog has this entry tagged for the beat; if absent, seed via migration — never AI-generated). Name selection uses a curated comfort/nearness default set (extend the static map's `default` slot — Ar-Raḥmān/Al-Laṭīf class) instead of a problem mapping. Sealed-Name copy variant: "the next Name of your journey — it unseals tomorrow" (problem contract keeps "the second Name of your answer").
- **Branch B — derived questions (amends V5.1.3):** same questions, same §G2 consumers, register swap: "How long have you been carrying this?" and "When does it hit hardest?" (→ reminder time) survive verbatim; the plan-seeding question becomes "What do you most want to know Him as — peace, mercy, strength, nearness?" (→ `aspirations` → queue). §G4 for the sign contract reads: does the answer visibly shape *their journey of Names* within 24h.
- **Branch C — plan screen, paywall, D1 push:** copy keyed on `contract`. Plan screen: "Your first seven Names — come to know Him, one each day." Paywall value pages: echo the **journey**, not a problem — "You've met [Name]. 92 more to know — keep meeting Him daily" (the §G2 echo-verbatim rule applies to `first_problem_text` only when it exists). D1 push: "The next Name of your journey has unsealed" (works for both contracts).
- **Analytics:** `contract` is a **segmentation super property inside the single treatment arm — never a third arm.** Post-ship read: conversion + D1 by contract; if sign-contract arrivals underperform, iterate their copy in the fast-metric loop without touching the A/B.

**V6.1.1 The "sign"-language copy boundary (binding; extends §H5):**
- **DO:** Day-0 only, once, at arrival/reveal, as confirmation of the moment *they* already believe in ("You didn't find this by accident" / "You don't have to name it. Allah already knows"). Comfort is delivered by **scripture from the verified catalog** — the app quotes; it never speaks *for* Allah.
- **DON'T (hard lines):** never in system-initiated copy — no "sign" language in any push, streak nudge, winback, trial-expiry, or gate re-present (the system claiming divine intent on its own schedule turns recognition into manipulation). Never as obligation or fear ("Don't ignore Allah's sign" is banned). Never attached to money — the words *sign*, *meant for you*, *Allah sent* may never appear on a purchase/offer surface or within one screen of a price. Never manufacture new signs ("Allah has another sign for you today" banned; "Today's Name awaits" fine).

## V6.2 Onboarding integrity amendments (One Ship scope)

1. **Pre-authored story decks — no runtime AI pre-auth.** The onboarding deck's story beats come from a new pre-authored, verified `name_stories` content set (start with the ~15 Names reachable from the problem-chip map + the comfort/nearness set), NOT from runtime `reflectWithOpenAI` — the reveal must be instant, offline-safe, pre-auth, and fabrication-proof (prophet/companion stories are hadith-adjacent; the CLAUDE.md rule applies). One templated bridge beat interpolates the chosen problem chip ("For the weight you named — {problem} — this Name answers…") to deliver Reel 1's explained-against-MY-problem promise. Live AI personalization of decks remains a post-signup (and post-OpenAI-proxy) upgrade.
2. **Show both Names on Day 0.** Reel 1 drops both Names in the reel itself; sealing Name #2's *identity* under-delivers the literal promise. Show Name #2's Arabic + transliteration + one-line meaning on Day 0; seal only its **story-deck**, which unseals Day 1. (Zeigarnik intact; promise literally kept.)
3. **Second-Name free guarantee (also lands in V6.3):** the two acquisition-promised Names — Name #1 (onboarding reveal) and Name #2 (D1 unseal) — are **free forever, full story decks included**. V5.3's gated "second-Name-of-the-day depth" refers ONLY to the *ongoing* daily companion-Name enrichment from Day 2 onward. Acceptance test: a user who installs from the reel, pays nothing, and dismisses every offer still receives both promised Names in full within 48h.
4. **§G4 enforcement on v5.1's own questions:** "Who else is affected?" seeds gift-a-dua — a consumer that lives in the signal-gated backlog and won't exist within 24h. **Cut the question** from the One Ship (restore when gift-a-dua ships), or pull gift-a-dua forward. §G4 gains an integrity clause: *(c) every content element a screen promises (story, verse, dua) must resolve to verified-DB content — no runtime-generated scripture-adjacent narrative pre-signup.*
5. **Name-matching map expansion (dropped in the v5 supersession, back in force):** expand beyond `demo_result_card.dart`'s hardcoded 7 Names to the full problem-chip taxonomy, sourced from `collectible_names.json` + name anchors (v1 Phase-1 screen 2 stands).
6. **Deferred-signup mechanism (the biggest unstated engineering seam):** pre-signup state (problem text, revealed Name, streak=1, 7-Name queue) is held under a **Supabase anonymous session** created at first launch and identity-linked at the deferred-signup step (fallback if anon auth is rejected: local cache + `persistOnboardingToSupabase` immediately post-signup, as the password screen already does). The §G3 queue table must accept anon-session writes under RLS.
7. **Deep links demoted:** `sakina://reel/<id>` / `sakina://feel/<emotion>` are best-effort warm-link handlers only (clone the `sakina://r/` pattern) — deferred deep linking doesn't apply to organic reels (no attributed click) and must not block the One Ship. **§G1 Path B (the selector/router chip) is the primary and mandatory reel-source capture.**
8. **Tour-kill made explicit:** the treatment arm ships with `guided_tour_enabled=false` + 2-3 contextual coachmarks. (v5.2's "Wave 0 substantially complete" does NOT cover tour removal — tour code was still being patched in PR #47; do not assume it's done.)

## V6.3 Gate amendments

1. **Copy firewall for the gate (new — §H5 predates the hybrid gate).** Binding on every gate/offer/winback surface: (a) **payment never buys the divine** — no copy may state or imply subscribing purchases Allah's favor, answered duas, barakah, or continuation of "a sign"; premium buys *tools and depth*, say exactly that; (b) **no guilt or spiritual-loss framing** — banned: "don't turn your back on…", divine second-person address in CTA copy, streak/lantern-loss language on the paywall; (c) **scarcity stated plainly, once** — welcome/backup offers in plain text ("this price is available until tomorrow"), **no countdown timer UI**, no pulsing badges, ≤1 push for the welcome offer; (d) **dismissal is honored** — dismiss → **home directly** (no chained ReferUnlock/winback screen at the onboarding gate; the shipped `paywall_screen.dart` dismiss→ReferUnlockScreen chain and 3s-hidden X must NOT carry over), with a one-time reverent card: "The 99 Names, your daily Name and its story, and your streak are yours — always free"; re-present caps ≤1 gate/session start, ≤2 offer surfaces/week. Add mechanical patterns to a pre-ship tripwire grep.
2. **Trial length: 7-day (founder decision 2026-07-23, supersedes V5.3's "3-day").** The v5 text inherited 3-day from the retired reverse trial without a fresh decision; it contradicted the plan's own citations (RC 2026: ≤4-day trials = worst conversion bucket, ~25.5% vs ~42.5%, 55% of 3-day cancels on Day 0; diagnosis changelist #3 recommended 7-day). The 76%-Day-0-conversion counterargument is weak — it was measured under the old no-trial architecture. **The real store trial ships at 7 days**, annual-anchored, weekly-equivalent framing unchanged. If the D30 read shows trial-start→paid leakage concentrated late in the trial window, 7d-vs-3d becomes the pre-registered fast-follow (reversed from before).
3. **The daily problem/feeling→Name match itself is free forever** (added to the V5.3 free list). It IS the reel promise; premium = deeper AI reflection, unlimited Build-a-Dua, journal history/insights, Reflect beyond the daily reveal. Without this line, the core-loop rewire and the tightened free tier collide over the promise itself.
4. **Grandfathering spec:** active = ≥1 check-in in the 30 days before the tightening flag flips; marked **server-side** (`user_profiles.free_tier_grandfathered_at`, written by migration, read in the gating RPC path — never client-only); grandfathered users keep the legacy 1/day cap permanently; other existing users get a 30-day softener notice; referral/gift premium windows unaffected.
5. **Experiment close-out checklist:** (1) dated closure addendum in `reverse-trial-experiment-readout.md` recording 2.44% vs 1.68% (n=768) and explicitly overriding the min-N rule (power unreachable at ~21 signups/day; mechanism evidence: toothless gate → expiry is a non-event); (2) **honor all in-flight trials** (`trial_premium_until > now()` at flip — no clawback); (3) flip the flag only after (1)-(2); (4) retire `reverse_trial_onboarding.dart` / `trial_expiry_service.dart` / `lapsed_trial_sheet.dart` surfaces after the last in-flight trial + winback grace; (5) freeze `paywall_exp_arm` as historical; the new experiment ships a NEW super property (`gate_exp_arm`); (6) rollback tripwire pre-registered (see V6.4.4).
6. **Pricing rides the gate change:** faith category clusters $59.99-69.99/yr (Hallow $69.99, Glorify ~$59.99-83.88); current anchor $49.99/yr; under-pricing is the bigger measured risk. Move the annual anchor to **$59.99** with the new paywall (zero-marginal-cost moment).
7. **A/B population:** new-signup cohorts only — existing users never meet a front-loaded gate mid-life.
8. **Free-tier tightening, code-grounded spec (2026-07-23 inventory — the shipped tier is MORE generous than v5 assumed).** Current reality per `gating_service.dart`: new free users get a **warmup budget of ~25 lifetime AI uses** (10 Reflect + 10 Build-a-Dua + 5 Discover Name) before the 1/day cap even starts, plus a 25-token bypass (2/day) funded by ~80 free tokens/week, plus a free Day-1 bypass — this, not the 1/day number, is why only 3% ever hit a wall. The tightening closes exactly three mechanisms for the treatment cohort:
   - **Warmup shrinks 10/10/5 → ~3 per feature**, framed inside the new onboarding's first-week arc ("your first three reflections are a gift") — kept small but alive, because payers are people who *experienced* depth (2.6-3.4×); zero taste kills desire.
   - **Weekly pool replaces the daily reset:** ~3/week across Reflect + Build-a-Dua (engaged users genuinely exhaust it mid-week and see the soft paywall).
   - **Token bypass removed for new cohorts** — it's a pressure-release valve converting free-earned tokens into paywall relief at ~$0.25/use; with the pool, the only door past the limit is premium. Grandfathered users keep warmup remainders, the 1/day cap, and the bypass.
   - **Explicitly NOT tightened further:** journal (already hard-capped at 5 saved reflections in code — the v5 "history gated" line is substantially built), cards/gacha Bronze→Gold + quests + XP + streaks + daily rewards (the free retention engine; cards are Names — faith line), browse/share/export/widgets (scripture + growth loop), the daily muḥāsabah reveal (the reel promise). Rationale: the package already moves paywall-encounter 3% → >30% target; harsher restriction adds D1/D7 + review-sentiment risk (the stopping rules) for marginal conversions, and the Rootd near-zero-backlash property depends on a livable free tier. A further notch is a clean post-read fast-follow if conversion stays low with healthy guardrails.

## V6.4 Measurement amendments (supersedes V5.4 step 2 wording)

1. **Reel-source capture is mandatory (the biggest measurement hole):** without it, "did we deliver the reel promise per audience" is unanswerable. `reel_source_captured {hook_type: 'names_solution'|'sign_from_allah'|'other'|'friend', reel_id?}` from the selector/router chip; register **`reel_hook` (and `contract`) as super properties** at capture; persist to `user_profiles.acquisition_promise` for the Supabase revenue join. Deep-link arrivals feed the same payload.
2. **`problem_category` as a super property** (chip taxonomy only — never free text; privacy + cardinality) + on `check_in_completed`. Read: paywall conversion + D1/D7 by `problem_category` × `reel_hook`.
3. **Reuse the shipped beat spine — do NOT mint `story_deck_*` or a duplicate `purchase_started`.** Deck events = `reflect_beat_advanced{surface:'onboarding_reveal', beat_index, beat_kind}` + new `reveal_deck_completed/abandoned{at_beat_kind}` + `result_card_shared{surface}` (beat_kind gives story-vs-verse-vs-dua drop-off free). Checkout leak = the existing `paywall_cta_tapped → purchase_sheet_presented → purchase_sheet_cancelled/failed` chain + **RC↔`experiment_assigned` cohort reconciliation by distinct_id** (RC server events carry no super properties) + a recovery-offer event on sheet-cancel. Second-Name lifecycle: `second_name_teased` → `second_name_unseal_available` → `second_name_unsealed{via:'push'|'organic'|'widget'}` + `source:'second_name_unseal'` on `notification_opened`. Free-tier taste: `ai_taste_consumed{feature, remaining}`; allowance-exhausted paywall emits `paywall_viewed{placement:'soft_inapp', trigger_feature}` — read: % of D1 free users who *see* a paywall (3% → target ≥30%). New onboarding gets stable `step_id` strings (cross-arm funnels by `step_id`, never `step_index` — the tour lesson). Gate events: `paywall_page_viewed/dismissed{page_index}`, `welcome_offer_shown/redeemed`, `backup_offer_shown/redeemed`, `free_tier_entered`. All constants in `analytics_event_names.dart`, emitted via the `onAnalyticsEvent` hook.
4. **Guardrails operationalized with pre-registered stopping rules (abort-only, never ship-early):** daily — ASC review velocity + star trend, RC refund rate vs trailing-30d baseline (+70% expected tolerance pre-registered), D1/D7 for **post-launch new signups only** by `gate_exp_arm`; weekly — keyword scan of new reviews for "money/paywall/scam/greedy/haram/sellout", cluster ≥3/week → founder review. **Stopping rules (any one pauses the arm, no debate):** refunds >2× baseline for 7 consecutive days · star trend −0.3 over 14d · D1 −8pts vs control sustained 7 days · any review cluster alleging scripture-gating. The 2wk early read is a **non-decision** read.
5. **Decision mechanics:** denominator = `experiment_assigned{experiment:'reel_gate', arm}`; revenue joined from RC by distinct_id (readout-doc method); decision = D30 revenue-per-assigned-user, P(treatment>control) ≥95%, no D1/D7 regression; tie → control; all queries filter `app_version ≥` release build + exclude test distinct_ids.
6. **Fast-metric loop constrained:** nothing changes inside either arm during the pre-registered window; post-decision paywall iterations are **ship-and-watch version-gated by `app_version`** (Day-0 purchase + checkout starts as fast metrics), not new A/B arms, until volume supports more.

## V6.5 Retention & seasonal amendments

1. **Ship now, server-only, no app release: reel-voice notification content.** The plumbing shipped; the copy didn't — live templates are generic app-voice ("Take a moment with Sakina today" ≈ the 4.2%-open register; personalized/contextual benchmarks 14.4%). Rewrite the three templates in `send-scheduled-notifications`: daily → "A Name for what you're carrying" / "{transliteration} — {anchor line}. Your reflection is waiting." (payload = the same Name+anchor the widget timeline already computes); re-engagement → drop "We miss you" for "{Name} has been waiting for you — whenever you're ready"; weekly (Fri 18:00) → the Jumu'ah beat: "The hour of Jumu'ah — the Name you met this week was {Name}". Streak saver gains the Name ("Your lantern rests tonight — {Name} is one reflection away"). No "sign" claims in push, ever (V6.1.1). ≤1/day preserved. Measure open-rate **by template** (1% → 10% target).
2. **The 99-Name arc (Reel 2's post-week-1 spine — new backlog item, ranked ABOVE adhkar sessions):** after the 7-Name Journey, the queue continues — the 99 Names in problem-clustered *chapters* (Names of Peace, of Provision, of Mercy; cluster keys from the existing emotion mapping). Progress = "You have met 23 of the 99 Names" (Names *met*, never days streaked) on Home + widget footer; tomorrow's Name teased at deck end. This is framing + queue extension over the existing card collection, not a new system. Every retention mechanic now defends *progress through the Names*.
3. **Ramadan reframed: "30 Names for 30 Nights" with a generosity posture.** Not a bolted-on challenge product — the accelerated chapter of the same Names arc, with beats scheduled on the **shipped dua-windows engine** (suhoor/iftar/Friday-hour are already modeled windows; respect the fasting-hours usage dip). **Gate posture in-season = generosity, never tightening:** extended trial (14-30d, the Hallow Lent mechanic), "gift Sakina for Ramadan" on the shipped `claim_sakina_gift` rails, caps loosened in-window; conversion is harvested in the post-Eid month (Hallow: ~25% of annual revenue) via the Eid recap + winback. **Eid share moment:** "the Names you met this Ramadan" recap share card. **Jumu'ah beat moves earlier** (it's ~80% shipped: Friday-hour dua window + Friday push exist; needs Jumu'ah-voice copy + a Name-of-the-week recap deck).
4. **Purge the retired-trial residue from the backlog:** CUT the reward-strip re-curve as specced (its rationale was the dead day-3 trial spike; Day-0 conversion means the strip never influenced purchase anyway — if ever re-curved, re-curve to the 7-Name Journey rhythm). KEEP beginner's barakah (first pull always lands Bronze — real, trial-independent defect at the most important reveal) but **re-anchor: guaranteed Silver+/blessed first reveal + dignity floor on the first 7 reveals** (not "trial days 0-2"). MERGE the "first-week track" into the 7-Name Journey itself — pre-stamped 2/7 (Name #1 + account, truthfully), day-2 stamp = second-Name unseal, day-7 = "Seeker of the Names" title; no parallel battle-pass. CUT streak-countdown Live Activity enhancements (unproven; brushes the anticipation-not-scarcity line; the good LA — dua windows — already shipped). v3 §§H2-H4 and v2 §D clauses tied to reverse-trial choreography are hereby marked superseded.
5. **Re-rank the backlog depth-first** (payers = 2.6-3.4× depth users; the backlog was 3 frequency items to 1 depth item): (1) gift-a-dua — new trigger = post-first-built-dua ("make one for someone you love"), **with Mixpanel instrumentation from day one** (build-a-dua is currently Supabase-only/invisible); (2) the 99-Name arc (above); (3) journal history/insights — gated in V5.3 but currently has no build item; (4) Reflect re-entry surface ("return to what you named on day one" — `first_problem_text` finally consumed post-paywall); (5) adhkar rewritten as **one depth appointment** — morning intention→Name planting + evening matured-reflection harvest (the 3.4× payer behavior); drop the two-chest session-arming scaffolding (H2 verdict: manufactured frequency doesn't convert); (6) TTS last, unchanged.
6. **Card-tier language rule (pinned):** tier vocabulary attaches to the *card*, never the *Name* — "a Bronze Name of Allah" is a dud-reveal in spiritual terms and is banned copy.

## V6.6 Implementation order (supersedes §V5.4)

1. **Immediately, server-only (independent of the One Ship):** reel-voice notification copy rewrite (V6.5.1) + Jumu'ah-voice Friday push. Cheapest lever in the product; no release.
2. **The One Ship:** reel-verbatim onboarding (V5.1 as amended by V6.1 + V6.2) + hybrid gate (V5.3 as amended by V6.3), one A/B arm vs soft control. Includes: two-contract router · pre-authored story decks · both Names Day 0 + free-guarantee · anonymous-session deferred signup · tour-kill flag · gate copy firewall · dismissal-to-home · $59.99 anchor · clean reverse-trial close-out.
3. **Instrumentation riding along (V6.4):** reel/contract/problem super properties, beat-spine deck events, second-Name lifecycle, RC cohort reconciliation, taste events, `step_id`, gate events, operationalized guardrails with stopping rules.
4. **Post-ship reads:** 2wk abort-only early read → D30 RPI decision → 10% permanent holdout; then ship-and-watch paywall iteration (no in-window changes); 3d-vs-7d trial is the first pre-registered fast-follow.
5. **Next big rock:** Ramadan "30 Names for 30 Nights" + generosity posture (design ~Nov-Dec 2026); Jumu'ah beat earlier (mostly shipped).
6. **Backlog, depth-first (signal-gated):** gift-a-dua (instrumented) → 99-Name arc → journal insights → Reflect re-entry → intention/harvest appointment → beginner's-barakah first-7-reveals fix (rides any release) → TTS. Cut: reward-strip re-curve, streak-countdown LA, two-chest adhkar scaffolding. *(Ranking amended by §V6.8.D5; barakah-fix timing amended by §V6.8.A9.)*

## V6.7 Superseded-clauses ledger (authoritative — consult before implementing ANY pre-v6 text)

The doc is append-only; ~22 pre-v6 clauses are now stale. This table is the single source of truth for dispositions. (One inline exception was made: the V5.3 DECISION paragraph's "3-day" carries a bracket annotation because it will be quoted standalone.)

| Stale clause (location) | Superseded by | Status |
|---|---|---|
| "3-day" store trial (V5.3 DECISION, V5.4.5, research doc §12.4) | V6.3.2 | **7-day** (research doc amended in place) |
| Name #2 fully sealed Day 0 (V5.1.2) | V6.2.2 | identity shown Day 0; only story deck seals |
| "second-Name-of-the-day depth" gated (V5.3) | V6.2.3 | both promised Names free forever |
| `purchase_started` (V5.4.2, v4 W-B) | V6.4.3 | banned — reuse purchase-sheet event chain |
| `story_deck_*` events (v1 Phase 4) | V6.4.3 | banned — reuse `reflect_beat_advanced` spine |
| Reward-strip re-curve incl. H6 "wk 1-3" slot (H4.2, H6, V4.4.9) | V6.5.4 | CUT |
| Trial Journey 8-stamp track + D3 gate-at-completion (H3, V4.4.9) | V6.5.4 + V6.8.A8 | merged into 7-Name Journey (2/8 pre-stamp incl. account) |
| Two-session adhkar backbone (H2, V4.4.11, V5.4.5) | V6.5.5(5) | one depth appointment only |
| Deep link "preferred" (§G1 Path A, v1 Phase 2) | V6.2.7 | best-effort; hook-chip router is primary |
| "3/week OR lifetime intro" either/or phrasing (v4 W-A, V5.3) | V6.3.8 | both/and: ~3/feature warmup + ~3/wk pool + bypass removed |
| `first_feeling_text` + "Day-3 gate" echo (§G2) | V6.1 / V5.3 | column = `first_problem_text`; echo lands on the Day-0 gate |
| "How is your heart today?" (v1 Phase 1 screen 1) | V5.1.1 | retired — problem register |
| "Who else is affected?" question (V5.1.3) | V6.2.4 | CUT from One Ship |
| Rive overhaul + §E Rive recipe (v2 §C6/§E/§F) | V5.2 | Lottie settled; Rive dead — do not build §E |
| Garden companion (v2 §C7/§D, V4.4.11) | V5.2 | lantern shipped; garden dropped |
| Streak-countdown Live Activity (v2 §C8, V4.4) | V6.5.4 | CUT |
| Reverse-trial metrics/targets (v2 §F, H6 metrics: `journey_stamp_earned`, `trial_day{n}_returned`, "% reaching D3 gate") | V6.4 | dead; use the V6.4 event set |
| "Wave 0 substantially complete" incl. tour (V5.2) | V6.2.8 + V6.8.A7 | tour kill NOT done — in One Ship, arm-keyed |
| 3→7d **reverse**-trial A/B (v1 Phase 4) + "KEEP 3-day reverse trial" (v2 header) | V5.3/V6.3.5 | reverse trial retired |
| "As-Salam is waiting tomorrow" paywall line (v1 Phase 4) | V6.8.D2 | struck — waiting/addressing rule |
| `lapsed_trial_sheet.dart` in the retirement list (V6.3.5(4)) | V6.8.B1 | KEPT — re-paced to the 7-day RC trial |
| H4.1 local-time day boundaries | **IN FORCE** (V6.8.A10) | prerequisite for D1 unseal + weekly pool; verify streak-tz coverage scope |
| H4.7 churn-flag intervention · H6 "odds tables → app_config" row | V6.8 | churn-flag CUT; app_config remote-tunability KEPT for V6.3.8 pool dials |
| H5 firewall | IN FORCE | extended by V6.1.1, V6.3.1, V6.8.D2; countdown rule: the RC trial-end reminder (system/Day-6 notice) is the one allowed clock — no in-app countdown UI anywhere |

## V6.8 Round-2 audit amendments (2026-07-23, second five-agent pass on the v6-amended plan)

Round 2 audited the plan *as amended* — hunting contradictions v6 introduced, ripple effects of the 7-day decision, feasibility, and experiment validity. Where V6.8 conflicts with earlier v6 text, **V6.8 wins**.

### V6.8.A — Onboarding structure & content

1. **The Name map is a PAIR map.** Reel 1's structure is two complementary Names against one problem, and no spec produced Name #2 for a chip arrival. The expanded map (V6.2.5) is **problem → (Name₁, Name₂) pair**, both members authored as decks; queue row 1 = Name₁, row 2 = Name₂; the aspiration answer shapes rows 3-7 only. Sign contract draws its pair from the curated comfort/nearness set. Deep-link `name_ids` override the pair when present. Day-0 deck includes one authored beat on how the two Names *together* answer the problem (the reel's actual shape).
2. **Router resolution (supersedes V6.1's selector-sets-contract clause and V6.2.7's "primary" wording).** The **hook screen is the ONLY routing intake**: chip → `contract` + `problem_category`. The What-brought-you-here selector becomes a single **post-reveal** tap ("Where did you find us?"), measurement-only — it sets `reel_hook`, never `contract`, never Name selection; `reel_source_captured` fires from it. Canonical §G1 payload: `{reel_id?, hook_type: 'names_solution'|'sign_from_allah'|'friend'|'other', contract: 'problem'|'sign', problem_category?}` — one enum taxonomy, pinned here.
3. **Story-deck production pipeline (the ship's long pole — owner + ship-gate).** Founder authors; a named reviewer verifies every story against a cited source (stored per deck; anything uncitable is rejected). **Ship-gate:** a problem chip renders only if BOTH Names of its pair have verified decks; uncovered chips fall back to the comfort pair. **The chip taxonomy is capped at ~5-6 problems** → ~6 pairs + ~3 comfort Names ≈ **15 decks max**; the taxonomy is the content-budget dial and gets decided FIRST. Content work starts week 0, parallel with engineering.
4. **Bridge beats are authored per (pair × chip), not one template.** A single interpolated line across all chips is the wall-of-ChatGPT feel at the highest-trust moment. Free text is keyword-mapped to the nearest chip (existing `forEmotion` pattern) and the bridge renders the chip's canonical phrasing ("the heaviness you named"); raw text is stored for later verbatim echo (§G2), never interpolated into scripted copy.
5. **The Day 1-7 promise gets an implementation owner (the orphaned Phase-2 seam).** The One Ship includes the minimum daily-loop seam: **D1-D7 daily reveal consults `user_name_queue`** (D1 reveal = Name #2's unseal deck — same surface, not a parallel one). A stated feeling overrides the Name, but the unseal deck is offered immediately after ("The Name we promised you is also waiting"). The full feeling-first core-loop rewire (v1 Phase 2) is the first post-read item. Without this seam, the plan screen and D1 push promise things Day 1 doesn't deliver — §G4 fails at its own test.
6. **"How long have you been carrying this?" gets its consumer** (was the same §G4 violation as the cut question): "months/years" answers set plan-screen pacing copy ("You've carried this a long time — we'll go gently, one Name a day") and ride as a context field into `reflectWithOpenAI`.
7. **Tour kill is arm-keyed, not global.** `guided_tour_enabled` is one global `app_config` bool — flipping it would remove the tour from the CONTROL arm too, deleting the biggest known leak from the baseline. Suppression is keyed client-side on `gate_exp_arm == 'treatment'`; the global flag stays true for control until the D30 decision.
8. **Small consistency fixes:** journey track = **8 stamps** (7 Names + account), pre-stamped 2/8 (restores v3's endowed ratio; day-7 title = 7 Names actually met); "D1 stamp = second-Name unseal" (calendar-day semantics per local tz); recognition copy fires ONCE — as the deck-opening beat (hook-chip confirmation microcopy is a subtitle, not a second recognition moment); the **rating gate** moves out of the pre-gate slot (it currently occupies the emotional peak the paywall needs) — relocate to post-D1-unseal.
9. **The onboarding reveal awards a card, and the beginner's-barakah fix ships IN the One Ship** (supersedes V6.6.6's "rides any release"): first reveal guaranteed Silver+ / blessed variant. Otherwise the ship re-creates the exact most-important-reveal-lands-Bronze defect at the moment the whole arm is optimized around — and a mid-window gacha change would violate the freeze (V6.8.C1).
10. **Local-tz day boundaries are IN FORCE as a One Ship prerequisite** (stranded in "superseded" H4): "unseals tomorrow" and the weekly pool reset need per-user local midnight, not UTC (the Jakarta-3AM problem). Verify what the shipped streak-tz work already covers (streaks may have it; quests/rewards/muhasabah may not) and close only the gap the ship needs.

### V6.8.B — Gate & free tier

1. **`LapsedTrialSheet` is NOT reverse-trial residue — keep it and re-pace it.** Its own header says it's the RC *store-trial* lapse winback ("the lapsed-trialer Day-1 moment is the strongest sub-upsell window in the app"). Struck from the V6.3.5(4) retirement list; instead: update its hardcoded "3-day" copy to the 7-day trial and wire it to RC trial-lapse under `gate_exp_arm`. (The actual residue to retire: `reverse_trial_onboarding.dart`, `trial_expiry_service.dart`.)
2. **Paywall copy: sell depth, never the arc (fixes v6's own firewall violation).** V6.1 Branch C's "92 more to know — keep meeting Him daily" sells the free thing (daily Names are free forever) — deceptive in hindsight for a dismisser, worst for the sign-contract arrival. Replacement register: *"You've met [Name] — and the daily Names are yours, always. Premium goes deeper with every Name: your personal reflection, your dua, your journal of the journey."* The journey-count line ("X of 99 met") is **banned from purchase surfaces** (extends V6.3.1a).
3. **`discoverName` is exempt from the tightening.** It gates the live Begin-Muḥāsabah reveal path itself; sweeping it into the pool would paywall the daily reveal (collides with V6.3.3) and kill the streak engine. It keeps a 1/day free cap permanently; its warmup (5→3) governs only *extra same-day* discovers; the weekly pool covers `reflect` + `builtDua` only.
4. **One trial length everywhere: the weekly SKU's intro trial also moves to 7-day.** Today the weekly SKU carries a 3-day trial and the exit offer pitches it — routing hesitators into RC's worst-converting bucket AND burning their once-per-subscription-group intro eligibility (taking the weekly 3-day forfeits the annual 7-day forever). Update the exit-offer/honest-billing strings in the same pass.
5. **Bypass removal, full disposition:** new cohorts get no bypass **including the free Day-1 bypass** (`claimFirstBypass`); `DailyCapSheet` gets a premium-only variant (no token slot); the IAP→sub banner's 6-bypass trigger is retired for new cohorts (re-key to token-pack purchases or drop); token earn/sinks note: with the bypass gone, free-user token utility = scrolls/cards — expect token-pack IAP softness in the new cohort (accepted; subscription is the business).
6. **Weekly pool is server-mirrored.** Usage counters today are date-keyed SharedPreferences — a reinstall would reset the pool once the bypass (the only server-enforced leg) is gone. Mirror the weekly-pool counter to a `user_profiles` column hydrated via `sync_all_user_data` (the existing warmup-mirror pattern). V6.3.4's "read inside the gating RPC path" means this sync-mirrored column.
7. **Grandfather boundary fix + sequencing:** grandfathered = check-in within 30d **OR signup within 30d** of the flip (protects last week's reel arrivals who got the old onboarding). Existing-user tightening (the 30-day softener wave) **executes only AFTER the D30 decision** — mid-window backlash from existing users would trip arm-level stopping rules that can't be segmented from the treatment.
8. **Welcome/backup offers move POST-decision (scope + validity).** They can't be added mid-window anyway (freeze), they're ARPU optimizers (+10-15%) not architecture, and they carry the dismissal-training risk. Treatment v1 ships **without** them; they enter via the post-decision ship-and-watch loop with this spec: separate first-year SKU (~$39.99 vs $59.99, ~33% off — a never-subscribed dismisser can't receive an iOS promotional offer and the annual's intro slot is consumed by the trial), shown **once per user lifetime** at 24h, plain text per V6.3.1(c). "Non-converter" = dismissed the gate without starting the trial; trial-cancellers belong to the LapsedTrialSheet path.

### V6.8.C — Experiment validity & measurement

1. **Change freeze (pre-registered).** V6.5.1's notification copy must be fully live **≥14 days before T0**, then frozen (no template/schedule/segment edits) until the D30 decision — it's asymmetric between arms (control's D1 push is the daily template; treatment's is the unseal push), so mid-window edits bias the D1 stopping rule. The freeze covers ALL user-facing surfaces regardless of channel: app releases, `app_config` flags, notification templates, store pricing/metadata, paywall remote config, gacha odds. Emergency changes get a dated readout-doc entry; their date becomes a segmentation boundary.
2. **Read schedule corrected for the 7-day trial.** Day-0 "purchases" in treatment are now $0 trial starts. T0+2wk abort-only read = Day-0 **trial-start rate** + checkout starts + paywall-encounter rate (health metrics, not cross-arm conversion — control's Day-0 events are real purchases, different units). First meaningful trial→paid read at T0+4wk. Assignment closes T0+6-8wk; **decision read at close+30d** (≈T0+10-12wk) so every assigned user has a full D30 observation including trial resolution and the refund tail. RC `subscription_started{is_trial:true}` never counts as revenue. Target decomposition pre-registered: signup→trial-start **≥15%**, trial→paid **≥30%** ⇒ ≥5% signup→paid (don't borrow RC's 42.5% — that's the 17-32-day bucket).
3. **Decision rule made honest.** Primary metric = **D30 paid-conversion per assigned user**; D30 RPI is secondary/directional (too few converters for a stable revenue read at ~440-620/arm). MDE on record: only a ≥2.3× lift is reliably detectable — this is a big-swing detector. **Inconclusive ladder (pre-registered):** P(t>c)≥95% → ship treatment · P<50% or any stopping rule → revert · P∈[80,95) with clean guardrails → extend assignment once by 4wk, re-read at new close+30d; if still [80,95) → ship only if all three secondaries (paywall-encounter, checkout-start, trial-start) are directionally positive, recorded as a judgment call · P∈[50,80) → keep control. "Tie → control" remains for the literal-tie case.
4. **D1 stopping rule de-noised:** evaluates on a rolling **14-day** cohort (n≈150/arm) and triggers at −8pts only if the gap also exceeds 2×SE; a single 7-day dip triggers review, not automatic pause.
5. **Treatment-internal dimensions stay internal.** `contract`/`reel_hook`/`problem_category` exist only in treatment (control can't emit them): never break an arm-vs-arm read down by them, never condition ship/revert on them. The `problem_category × reel_hook` matrix is **exploratory, pooled post-decision** (needs months, not the window); the only in-window per-audience read is the single sign-vs-problem split on deck completion + D1, flagged low-n.
6. **Event-name corrections (convention compliance):** `paywall_page_viewed{page_id}` with stable string ids (`value_names`, `value_journey`, `plan_select`) — no page_index; dismissal reuses `paywall_closed{placement}` (no new `paywall_dismissed`); checkout-close offer reuses `paywall_exit_offer_shown/accepted` with `offer:'backup'|'welcome'`; `second_name_unsealed{source}` not `{via}`; the gate emits `paywall_viewed{placement:'onboarding'}` segmented by `gate_exp_arm`+`app_version` (no new placement value); deck-skip reuses `reflect_flow_skipped{surface:'onboarding_reveal'}`, `reveal_deck_abandoned` reserved for non-tap exits; `beat_kind` gains `'recognition'`/`'comfort_verse'` so the sign contract's payoff beat is measurable.
7. **New-cohort allowance events:** `ai_taste_consumed` gains `allowance:'warmup'|'weekly_pool'`; exhaustion emits `ai_allowance_exhausted{feature, allowance}` + paywall `trigger:'warmup_exhausted'|'pool_exhausted'`; `daily_cap_hit` and the `ai_bypass_*` funnel become **grandfathered-cohort-only** (debug-assert `ai_bypass_offered` never fires for a new-cohort user). Register `free_tier_cohort:'grandfathered'|'softener'|'new'` as a boot super property; the 3%→≥30% paywall-encounter read filters `new`.
8. **Notification measurement:** every send includes `template_id` + `copy_version` in the push payload and on server-emitted `notification_sent`; the client echoes both onto `notification_opened`. Open-rate by template = Mixpanel-side ratio — no OneSignal-dashboard join. Template iteration is a **pre-window program** (then frozen, per C1).
9. **Declared confound:** the arms run at different prices ($59.99 treatment vs $49.99 control) and different trial mechanics by design — the test is the *package*, and the decision metric (revenue-per-assigned) absorbs price. Stated so nobody "corrects" it mid-flight. RC serves the treatment offering (7-day trial products) keyed on `gate_exp_arm`.
10. **`names_met`** becomes a Mixpanel people property from the One Ship (incremented at first-discovery `card_revealed`), so the 99-arc backlog item has a pre-arc baseline; 3d-vs-7d is confirmed as **conditional ship-and-watch, never an A/B at current volume** (supersedes V6.6.4's unconditional phrasing).

### V6.8.D — Retention, notifications, reverence

1. **The notification rewrite is two-phase — the server doesn't know today's Name yet.** `get_eligible_notification_users` returns no Name, and the widget's "today's Name" is client-computed (real only after check-in). **Phase A (now, server-only):** extend the RPC (new migration; two-step query — no FK embed, per the deploy gotchas) to return the user's most-recent Name from `user_checkin_history` joined to `name_anchors`; daily copy uses yesterday's-Name framing — *"{transliteration} — {anchor}. Today's Name is waiting."* — never claiming today's match before it exists; Jumu'ah gets a no-checkin fallback template (never interpolate null). Drop "Your reflection is waiting" until the maturing-reflection appointment exists. **Phase B (after the One Ship):** daily push reads `user_name_queue` for the user's local today; only then may copy say "A Name for what you're carrying."
2. **The waiting/addressing rule (extends V6.1.1 — scholar-review class).** No copy may attribute a stance, action, or waiting posture to Allah or to a Name: **app artifacts wait ("the story of Al-Wadūd is still open"; "your next Name is ready"); Allah and His Names never do.** Applies to push, paywall, recap. Re-engagement rewrite: *"You paused at {transliteration}. Its story is still open — whenever you're ready."* The v1 Phase-4 line "As-Salam is waiting tomorrow" is struck (it was a waiting-Name claim on a purchase surface). Add "waiting for you" + Name-adjacency to the tripwire grep. Also: V6.3.8's "your first three reflections are a gift" → **"your first three reflections are included — yours to keep"** (tool register, not grace register, on a monetization-adjacent surface).
3. **Push strings are transliteration-only** — Arabic script never appears in a notification title/body (single-string surfaces can't isolate text direction). `{Name}` in every template means transliteration. English-only `contents.en` accepted for v1; logged as i18n debt.
4. **"Met" is defined, and the three progress systems reconcile.** Met = **completed the reveal deck** for that Name (from `user_checkin_history` or a `met_at` column written by the check-in RPC) — never card ownership (Store purchases don't count; Name #2 counts at its D1 unseal, not the D0 tease). Reconciliation: **the queue selects the Name; the gacha selects only the tier; the daily card awarded is always the card OF the revealed Name.** When the queue lands on an already-met Name, the pull becomes a tier-upgrade chance (preserves the Bronze→Emerald ladder's free path). Remaining templates get the arc: milestone push → *"Tomorrow you'll have met {names_met} Names — {next} completes your {n}-day flame"*; winback → append *"{next} is next on your journey — whenever you're ready"* (both Phase-A data path; amend the streak-retention-v2 locked vocabulary in the same PR, not silently).
5. **Backlog re-rank (amends V6.5.5/V6.6.6): Reflect re-entry → #1** (it literally re-delivers Reel 1's contract), **gift-a-dua → #4** (its old rank rested on retired trial choreography; neither reel promises social). Gift-a-dua ships only with its §G4 test written: sender sees "your dua reached {name}" within 24h; installed recipient gets an in-app card; non-installed gets a share-card link that renders without the app; `dua_gifted` + `dua_gift_opened` in Mixpanel from day one. Reflect re-entry's sign-contract branch: keys on the first Name met — *"You began this journey with {Name}. Return to it — or name what you're carrying now"* (the graceful sign→problem upgrade path; write `first_problem_text` if they finally name it). The intention/harvest appointment is **not a quest** — own surface on Home/widget; completing the harvest satisfies (never stacks with) any same-day reflection quest.
6. **Ramadan mechanics named + anti-clawback framing.** (1) New users in-window: date-scheduled intro-offer change on the annual SKU to a 14-day trial, served via a seasonal RC Offering. (2) Existing free users (who already consumed their once-per-group intro trial): a Ramadan **offer-code** campaign (free-trial codes) on the shipped gift-card rail. (3) Post-Eid harvest: dedicated `placement:'eid_recap'` paywall on the Eid recap screen + a 2-push winback in Shawwal week 1 — specced before the season. Loosened caps are framed as a bounded gift from day one ("open through Ramadan"), ramp-down notice in the last 3 nights, reversion on **Eid+3** (never Eid day), recap leads with what's kept; review-keyword scan runs daily through Shawwal week 1.

### V6.8.E — One Ship scope cut-line (amends V6.6.2)

Honest sizing found ~3 L's + ~9 M's under one flag — secretly three ships. The cut-line (rule: user-invisible or both-arms-equal can trail; treatment-defining cannot):

- **Anonymous auth → CUT to the specified fallback** (local pre-auth state + `persistOnboardingToSupabase` at signup — the shipped page-0 pattern). It was the ship's biggest engineering risk spent on a non-leak (signup completion is already 99%). `gate_exp_arm` is assigned from a stable install id aliased to the user at signup (keeps RC reconciliation intact). Anon-session durability + existing-account sign-in merge rules move to fast-follow hardening.
- **Grandfathering migration → pre-written now, EXECUTED at post-decision rollout** (the window is new-signups-only; existing users feel nothing until the winner ships) — per V6.8.B7.
- **Welcome + backup offers → post-decision** — per V6.8.B8.
- **Chip taxonomy capped at ~5-6** → deck production bounded at ~15 — per V6.8.A3.
- **Trail items:** `source:'widget'` unseal attribution, RC dashboard niceties (stopping-rule guardrails are day-1, dashboards can lag).
- **Kept despite temptation:** tour kill (treatment-defining, arm-keyed per V6.8.A7), free-tier tightening for the new cohort (defines what dismissal means), beginner's-barakah first-reveal fix (V6.8.A9), reverse-trial close-out (blocks the flag), local-tz boundary gap-close (V6.8.A10).

**Day-1 blocking decisions (nothing else blocks):** ① the chip taxonomy list (~5-6 problems — the scope dial, decide first) · ② the problem→Name-PAIR map + the sign-contract comfort set (exact Names) · ③ story author + religious reviewer named · ④ day-boundary semantics verified (what streak-tz already covers) · ⑤ exact warmup/pool integers (pin the tildes) · ⑥ paywall page count + copy (freeze before T0).

## V6.9 (2026-07-23) — Founder rollout decision: 100% ship-and-watch (supersedes the A/B design)

**Decision:** the new onboarding + gate ships to **100% of new signups at release — no control arm, no 10% holdout.** Rationale: the A/B was a big-swing detector at best (MDE ≈2.3×, §V6.8.C3), the founder intends the new experience for every future install regardless of a muddy read, and running a control whose result wouldn't change the ship decision is theater. The trade — losing causal attribution — is declared, not hidden.

**Supersedes:** the V5.3 A/B design + 10% holdout (population scope *new-signups-only* survives; the arms die) · §V6.8.C1 change freeze → **one-change-at-a-time** (notification Phase A live ≥14d before T0; nothing user-facing between T0 and the keep read) · §V6.8.C2-C5 read schedule / decision ladder / arm-based stopping rules → **pre/post vs the trailing-90d baseline** (snapshot before T0; health read T0+2wk; trial→paid T0+4wk; **keep decision T0+6wk** on D30 cohorts, target ≥5% signup→paid vs 2.44% baseline; guardrails keep their thresholds but fire against history; any trigger → kill-switch flip + dated log) · §V6.8.A7 arm-keyed tour kill → **flow-keyed** (kill-switch revert restores the tour with the legacy flow) · `gate_exp_arm` / `experiment_assigned` → **`onboarding_flow: 'reel_v1'|'legacy'` super property** (recorded per user — kill-switch flips make flow non-inferable from `app_version`) · every "post-decision" sequencing trigger (grandfathering execution, softener wave, welcome/backup offers, core-loop rewire, legacy-code deletion) now keys on the **T0+6wk keep decision**.

**Not superseded:** the reverse-trial close-out (still blocks the flip) · all copy firewalls · the free-tier spec + grandfathering boundary · guardrail thresholds + de-noising rules · the sanctioned sign-vs-problem internal read (now merely low-n-flagged, no arm caveat needed).

**Companion decision — flag & dead-code hygiene (standing rule, full ledger in the distilled doc):** at most ONE live product kill-switch at a time; every flag ships with a pre-registered deletion task; loser code deleted within one release of its decision; post-keep iteration is `app_version`-gated ship-and-watch, never new flags. The single flag for this ship is `reel_first_onboarding_enabled` (legacy flow behind it, complete and revertible incl. tour + RC offering), deleted — along with the entire legacy onboarding, tour code, and the dormant `answerCheckin()` path — one release after the keep decision.

## V6.10 (2026-07-24) — Founder decision: NO grandfathering — the new free tier applies to all existing users

**Decision:** the free-tier tightening (§V6.3.8) applies to **every free user**, existing actives included — nobody is grandfathered. Supersedes §V6.3.4 (grandfathering spec), §V6.8.B7 (boundary + active-exemption), and the V6.9 "grandfathering execution" trigger. Mechanism: one **all-users softener wave** — 30-day notice, then the new warmup/weekly-pool/no-bypass tier — executed **after the T0+6wk keep decision** (existing users still feel nothing during the launch guardrail window) and scheduled to **complete before Ramadan prep** (no tightening adjacent to the generosity season). Referral/gift premium windows remain untouched; `discoverName` remains 1/day free for everyone.

**Rationale & record:** founder chose one permanent free tier over maintaining two configs indefinitely; this also upgrades the deletion ledger — the entire token-bypass subsystem (`claimFirstBypass`, `reserveBypass`, `DailyCapSheet` token slot, IAP→sub banner trigger, `ai_bypass_*` events) and the legacy cap constants get deleted once the softener wave completes (~keep+60d), rather than living forever for a shrinking grandfathered pool. **Recorded dissent (2026-07-24 research pass):** the case-study + benchmark research (LastPass/Evernote clawback outcomes; conversion is Day-0-concentrated — 31/35 own subscribers; only ~3% of users ever hit a cap, so the squeeze reaches ~10-30 legacy AI power users for a handful of possible conversions) recommended permanently grandfathering the ~30d-actives; the founder heard it and accepted the review-backlash risk for the simplicity win. Mitigations kept: post-keep-decision timing, 30-day notice, pre-Ramadan completion, review-keyword scan running through the migration (an existing-user review cluster during the wave triggers founder review, not the launch kill switch — the launch read is already closed by then).
