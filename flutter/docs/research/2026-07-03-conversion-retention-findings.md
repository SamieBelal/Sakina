# Conversion & Retention Research Findings — Full Compendium

**Data snapshot date: 2026-07-03** (all Mixpanel/Supabase/RevenueCat numbers are as of that date; work shipped after it — duʿā-times widget, Live Activities, dua-windows observability — is not reflected here).

> **Fresher numbers exist:** [`docs/analytics/2026-07-14-conversion-diagnosis-and-research.md`](../analytics/2026-07-14-conversion-diagnosis-and-research.md) re-ran the diagnosis on a larger window (cohort n=646, subscribers n=42) and confirms the findings here with updated figures (76% Day-0 conversion, D0→D1 return 31% by cohort method, 3% AI-cap-hit, 191 soft-gate dismissals, control ~5% vs reverse-trial ~1.2% directional). Prefer its numbers where they differ; the plan's v4 section reconciles the two.
**Companion to the plan of record:** [`docs/superpowers/plans/2026-07-03-reel-first-conversion-refactor.md`](../superpowers/plans/2026-07-03-reel-first-conversion-refactor.md) (v1 reel-first refactor → v2 data review + retention strategy → v3 3-day hook architecture → §G Promise Ledger). This document is the *evidence base*; the plan is the *decisions*.

---

## 1. Context — why this research happened

- **Acquisition is 100% Instagram/TikTok reels.** The two highest-viewed formats:
  1. *"2 Names of Allah that will change everything for you"* — situation/feeling → the Name that addresses it → CTA to download.
  2. *"Don't skip this, wallahi this is a message for you"* — emotional story built around a Name → CTA.
  The implied contract of both: **"tell the app how you feel → get the Name of Allah meant for you."**
- **Founder problems stated:** long onboarding (mostly useless), users don't land on the right feature, the first dopamine hit comes late or never, and story/reflection content reads as a wall of ChatGPT text.
- **Founder decision (fixed):** every new user gets an automatic **3-day full-premium reverse trial**, then a **soft paywall**. Conversion strategy = make the app maximally retentive/habit-forming inside those 3 days (streaks, widgets, companion, Rive animation overhaul), so the gate lands on a habituated user.
- Live config at snapshot (`app_config`): `onboarding_trim_enabled=true` (20-page flow), `guided_tour_enabled=true`, `post_tour_paywall_mode=soft`, `reverse_trial_experiment_enabled=true`, `tour_ab_enabled=false`.

## 2. Query hygiene (how the numbers were produced)

- Mixpanel project `4013350`; **66 test/deleted distinct_ids excluded on every query** (list: `docs/qa/mixpanel-orphaned-distinct-ids.json`; method: one `user_id does-not-equal` filter per id).
- Mixpanel MCP gotchas found: `All Events` + `Event Name` breakdown returns empty for this project (use `Get-Events` + explicit per-event metrics); retention report rejects a top-level `unit` param.
- Supabase queries run against production public schema (577 `user_profiles` at snapshot). RevenueCat project `proje6681c8c`.
- Caveat inherited from `docs/analytics/funnel-flags-and-querying.md`: conversion events only trustworthy from 2026-06-03; Phase 1-3 events only populate post-release.

## 3. Analytics findings — Mixpanel (30d window ending 2026-07-03)

### 3.1 Activation funnel (unique users, 7-day conversion window)
| Step | Users | Step conv. | Cumulative |
|---|---|---|---|
| onboarding_started | 206 | — | 100% |
| signup_completed | 170 | 83% | 83% |
| onboarding_completed | 169 | 99% | 82% |
| tour_started | 167 | 99% | 81% |
| tour_completed | 87 | **52%** | 42% |
| check_in_completed | 57 | 66% | **28%** |

- **Avg time onboarding_start → first check-in ≈ 38 hours** (funnel avg_time 138,253s).
- Onboarding page drop-off is shallow: `onboarding_step_viewed` uniques go ~603 → ~517 across the 20-page flow (~14% total loss). **The quiz is not the leak.**
- **The forced tour is the leak.** All tour starts 30d: 483 → 254 completed (53%). Loss modes: **tour_backgrounded 161 uniques (silent mid-tour app abandonment), tour_anchor_timeout 95 (technical failure), tour_skipped 2 (deliberate)**. Users aren't opting out; they're being lost.
- Paywall funnel: paywall_viewed 150 → paywall_cta_tapped 19 (**13%**) → purchase_sheet_presented 9 → trial_started 5 (3% overall). (Comp: Cal AI converts 57% of paywall presentations to trial starts.)

### 3.2 Feature usage (uniques of 681 app-openers, 30d)
| Feature | Users | % |
|---|---|---|
| check_in_completed / card_revealed / streak_extended | ~470-472 | ~69% |
| quest_completed | 438 | 64% |
| first_checkin_submitted | 570 | — |
| dua_built | 120 | 18% |
| journal_entry_created | 114 | 17% |
| store_viewed | 31 | 5% |
| notification_opened | 8 | **~1%** |

- The daily Name/card/streak loop IS the product; everything else is periphery.
- **The Reflect tab had zero instrumentation** at snapshot — the one feature matching the reel promise was analytically invisible. (Post-snapshot: dua-windows observability shipped 2026-07-18 adds widget/notif/LA events; reflect events still per plan.)

### 3.3 Trial lifecycle (30d)
trial_activated 81 → trial_expired seen by only 27 → trial_paywall_surfaced 32 · soft_gate_dismissed 88 · daily_cap_hit 11 · experiment_assigned 167. **Most trials expire in absentia; free-tier caps are almost never felt (premium has no perceived contrast).**

## 4. Production-data findings — Supabase + RevenueCat

### 4.1 Business scale (RevenueCat, 28d)
650 new customers · 693 active users · **11 active subscriptions · $103 MRR · $266 revenue · 1 active trial**.

### 4.2 The headline: reverse trial converts ~1%
- `trial_premium_until` granted: **82 users → 1 ever subscribed** (~1.2%). RevenueCat's reverse-trial case study: 0.4% → **4.5%** when done well. H&F opt-in trial→paid median: 37.7%.

### 4.3 Retention curve (signup cohort 14-60d old, n=407, `user_activity_log`)
D1 **21.9%** · D2 17.0% · D3 **11.3%** · any-of-D1-D3 33.7% · D7 7.9%. **Two-thirds of users never return during their 3 premium days.**

### 4.4 Conversion timing
Of 35 all-time production subscriber users: **31 subscribed Day 0** (avg 0.0-1.1 days from signup); only **2 after Day 3**. The trial decision is a first-session event even with a soft gate.

### 4.5 What distinguishes payers — depth, not early frequency
| | Non-subs (n=542) | Subs (n=35) |
|---|---|---|
| Check-ins first 3d | 1.36 | 1.46 |
| Days active first 3d | 1.37 | 1.49 |
| Cards | 3.82 | **6.60** |
| Built duas | 0.68 | **1.86 (2.7×)** |
| Reflections | 0.16 | **0.54 (3.4×)** |

**Payers are the users who touched the AI depth features and accumulated collection.** The trial must force-feed exactly those.

### 4.6 Other production facts
- Streaks: of 577 users, **414 (72%) never exceeded a 1-day streak**; 47 ever hit 4+; 5 ever hit 14+; max 20; live 2+-day streaks: 43.
- **575/577 users set a reminder_time** in onboarding — unused at snapshot (notif opens ~1%).
- Engagement depth: 1,343 lifetime check-ins (~2.3/user), 436 built duas, **106 reflections all-time**, 2,303 cards (~4/user).
- `name_returned` spread thin across the 99 Names (top = 23) — the blind gacha yields arbitrary Names; the loop is not feeling-matched.

## 5. Codebase findings (agent audit, file refs)

### 5.1 Onboarding (live trimmed 20-page flow)
- **~8 pages are write-only**: pages 2-8 + 11 (age, intention, prayer frequency, familiarity, dua topics, commitment minutes, attribution, pact) are persisted to `user_profiles` and **read by nothing** — not AI context, not personalization, not notifications. Only `signUpName` and `starterNameId` are genuinely consumed; `reminderTime` had no client-side reader.
- **Page 0 already delivers the reel promise once**: `first_checkin_screen.dart` feeling input → `NameRevealOverlay` gacha — but via a **hardcoded 7-Name map** (`demo_result_card.dart:130-169`: anxious→As-Salam, sad→Al-Jabbar, grateful→Ash-Shakur, angry→As-Sabur, lost→Al-Hadi, hopeful→Al-Wakeel, default Ar-Rahman), pre-auth, then buried under 19 more pages.
- Paywall flow = pages 16-19 (fake "generating" loader → plan tiles → rating gate → gate); signup at pages 13-15 (social auth jumps 13→16).
- `docs/qa/ui-map.md` was stale (legacy 27-page indices). Step-index maps in `analytics_event_names.dart:505,539` must move in lockstep with any reorder.

### 5.2 First session / core loop
- Post-onboarding: hard/soft wall → `ProgressScreen` (home) → `DailyLaunchOverlay` (2 steps, no questionnaire) → forced slim tour (9 steps, `kSlimOnboardingTourSteps`).
- **`discoverName()` (`daily_loop_provider.dart:458-530`) skips feelings entirely** — blind pick (undiscovered→lowest tier) → gacha. Writes `q1='discover'`. The core loop is a card pull, not the reel's promise.
- The real feeling→Name engine exists: **`reflectWithOpenAI` (`ai_service.dart:626`)** — gpt-4o-mini, all 99 Names, teaching context, off-topic classifier; lives on the Reflect tab behind daily-cap gating; works signed-out but degraded. Dormant `answerCheckin()` has no live callers.
- No anonymous auth; page-0 reveal proves the moment works pre-auth.

### 5.3 Wall-of-text surfaces
- Reflect + muhasabah "Go Deeper": `reflectWithOpenAI`, 1500-token completions, marker format `##NAME/REFRAME(2-3 sent)/STORY(3-5 sent)/DUA##`, paginated but dense prose per card; dua step stacks verse+dua+translit+translation in one scroll.
- **Build-a-Dua is the biggest wall**: `buildDua` (`ai_service.dart:1160-1433`), **3500 tokens**, 4 full sections + 3 related duas, prompt demands "do NOT truncate."
- Journal: expand-all cards dump everything.
- Content inventory: 99 `collectible_names` (meaning/lesson/hadith/per-Name dua), 98 `name_anchors` (anchor + detail para), 121 `browse_duas` (with `emotion_tags`, `when_to_recite`), 30 daily questions, 18 quiz questions. **All long-form narrative is AI-generated at runtime; no per-Name story table.**

### 5.4 Engagement-mechanics inventory (v3 basis)
- **Quests** (`quests_provider.dart`): 3 daily (from pool of 9, day-of-year rotation) + 3 weekly + 3 monthly + 3 one-time First Steps (75 XP/50 tokens/5 scrolls each + bundle bonus).
- **7-day reward strip** (`daily_rewards_service.dart:39-81`): 5/10/15 tokens (d1-3), **freeze d4**, 20 (d5), 5 scrolls (d6), 30 (d7); 5× premium multiplier; miss >1 day resets to day 0.
- **Streaks** (`streak_service.dart:39-67`): milestones 7/14/30/60/90/180/365 (100→2000 XP + titles "Consistent"/"Unwavering"/"Steadfast Soul"/"Guardian of Light"); one boolean freeze; no repair; largely client-side.
- **Gacha** (`card_collection_service.dart:1815,1994`): pick priority new→Bronze→Silver→Gold; **first pull always lands Bronze**; tier-up on re-encounter; Emerald enum exists but unused; no pity; scroll costs 5 (B→S) / 10 (S→G).
- **XP/levels**: 25+ levels ("Seeker"→"Beloved", Arabic titles), 5-13 tokens/level. **Tokens**: start 50; sinks are IAP only.
- **Notifications** (`notification_service.dart`): 5 OneSignal categories with routing; no app-icon badge.
- **Three defects for a 3-day-trial strategy:** (1) **all resets at UTC midnight** (`quests_provider.dart:564-574`) — incoherent local timing; (2) **zero appointment mechanics** — nothing changes between same-day opens; (3) **reward curve backwards** — weakest rewards on trial days 1-3, spikes after; weakest reveal (Bronze) at the most important moment.

## 6. External research — activation & onboarding (sources inline)

- **Same-day decisions:** 82% of trial starts happen day of install; 55% of 3-day-trial cancels on Day 0 (RevenueCat State of Subscription Apps 2025/2026). Trial length: 3-day trials convert 25.5% vs 42.5% for 17-32-day (relevant to opt-in trials; superseded for us by the reverse-trial decision).
- **Deferred signup:** Duolingo signup-after-first-lesson = **+20% D1**; YouVersion gates nothing. Calm opens with "What brings you here?"
- **Quiz length:** long quizzes convert only when answers visibly change output (Cal AI ~20 steps, 87% paywall-presentation → 57% trial-start → 63% checkout, built on 123 A/B tests; +13% activation from merely asking a name; Headspace measured 38% drop on its long flow).
- **Creative continuity:** paywalls/first screens mirroring the ad's language outperform layout tests (RevenueCat JTBD +169% compounded; Adapty ad-matched ~35% vendor-directional). Zero-party data echoed on the paywall beats most experiments.
- **Hard vs soft:** hard 10.7% vs freemium 2.1% D35 trial→paid with identical 1-yr retention (RevenueCat 2026); a separate Adapty read has soft out-converting hard on view-to-payment — trade LTV for volume/brand warmth (our soft gate is defensible).
- Faith comps first-session shapes: YouVersion (skip signup, nothing gated), Headspace (participatory breathing before any ask; aha paywalled), Hallow (~85% gated, bump-into-wall in week 1), Glorify (generous free tier, swappable paywall blocks).

## 7. External research — content format & audio

- **Format winner: tap-through beat cards** (Imprint ≤2-min tap-forward lessons with auto-saved cards × YouVersion Guided Scripture: tap-sides navigation, devotional+question+prayer, **share-per-section**). Microlearning chunking has real evidence (40-study review: significant engagement+retention gains). Vertical TikTok-swipe rejected for reverence.
- **Structured generation** (JSON beats: hook/body/pull_quote/key_line/verse/dua/closing) is the enabling move — same model call, near-zero cost. One idea per card, key-line highlighting, gentle line fade-in, manual advance (no countdown).
- **TTS:** gpt-4o-mini-tts ≈ **$0.015/min**, steerable ("slow, soothing"), <100ms streaming; ElevenLabs ~6.7× dearer with best prosody. **Arabic must never be machine-TTS'd** (tashkeel/tajweed errors change meaning — doctrinal risk); Arabic stays text or human-recited. Architecture: Edge Function, content-hash → Supabase Storage CDN cache; ~$0.012 per unique reflection. Audio is a differentiation play, **not** a proven retention lever — instrument (`reflection_audio_played`) before investing further. Flutter: just_audio + audio_service (+ just_audio_background); flutter_tts only as offline fallback.

## 8. External research — retention mechanics (evidence-ranked)

- **Reverse trials:** work via endowment + loss aversion, but "engagement > exposure — if they don't use the premium features, nothing changes" (RevenueCat; 0.4% → 4.5% case).
- **Streaks:** Duolingo's #1 lever — 7-day streak → 2.4× retention (32M DAU carry one); **Streak Freeze −21% churn**; friend streaks **+22%** daily completion; milestone share-card redesign → 5-10× organic sharing. Habit science: formation averages **66 days** (18-254); single misses cause only minor automaticity dips → forgiveness (freeze/repair) is science-backed, not charity. Faith precedent: YouVersion streaks since 2017 (completion spikes days 3-21), Tarteel ships streaks/heatmaps/badges without backlash; Hallow praised for restraint.
- **Companion:** Finch = **$30M+ ARR bootstrapped, 10M MAU, D1/D7 54%/37%** (beats Duolingo) on a care-loop (energy → 8-hour adventures → must reopen); customization-first onboarding. Forest = 25M+ downloads on a **non-figurative** grow-and-tend loop. **Decision: no figurative avatar** (theological sensitivity + "gamified sacred" backlash documented, e.g. NCR); build a **growing garden** (jannah imagery, reverence-additive) or illuminating khatam/calligraphy — same mechanic, safe skin.
- **Widgets:** Duolingo streak widget ≈ **+60% daily commitment**; half of widget installers carry 6-month+ streaks; app-icon streak badge +6% DAU. Widgets bypass push permission entirely — the answer to a dead notification channel.
- **Notifications:** personalized/contextual 14.4% opens vs 4.2% generic; per-user send-time +40% reaction; one push received in first 90d → 3× retention; Duolingo's bandit (KDD 2020) +0.5% DAU/+2% new-user retention. **Calm: users who set a daily reminder retained 3×** — the single strongest wellness retention lever. For a Muslim app, prayer-time alignment is the unfair advantage (Muslim Pro's adhan-push model, Tarteel's post-Fajr habit-stacking pedagogy).
- **Animation:** Duolingo's streak-phoenix redesign alone = **+1.7% D7**; concentrate Rive spend on reveal + milestones only.

## 9. External research — multi-open & first-72h engineering

- **Hooked model:** external triggers (push/widget) must convert to internal triggers (feeling → open); investment at end of each session loads the next trigger. Habit stacking (BJ Fogg): anchor to an existing rock-solid routine — **salah is a divinely-scheduled 5×/day anchor; morning/evening adhkar are natural session bookends** (Duolingo had to invent Early Bird/Night Owl chests to engineer 2 sessions/day; Sakina gets it natively).
- **Variable rewards:** variable-ratio reinforcement = strongest schedule known; dopamine fires on anticipation; rare outcomes imprint hardest (fMRI); pity timers raise retention ~35% (Genshin soft pity ~74/hard 90). Reverent version: tier roll + rare "blessed" luminous variant + dignity floor (never long without a Gold+) + **no dud reveals ever** (the slot-machine firewall).
- **Appointment mechanics ranked by coercion:** Finch 8-hour adventure (LOW — the model to copy), Pokémon GO 7-stamp breakthrough (maps to our 7-day strip), BeReal random moment (MED), Clash Royale chest queues (HIGH — Supercell retired them 2025), Snapstreaks (VERY HIGH — the anti-pattern; documented teen anxiety).
- **Quests/day-structure:** Duolingo Daily Quests **+25% DAU**; Early Bird (lesson before noon → chest at 6pm) + Night Owl (after 6pm → chest next morning) is the published two-session template; leagues/expiring boosts add urgency (leagues = riyāʾ risk for worship — private progress only).
- **First-72h gaming doctrine:** time-to-core-loop <60s; guaranteed-win first pull; **D1 churn 64-72% is the cliff**; fix = end session 1 with unfinished business (Zeigarnik: overnight-unsealing chest/card) + visibly-bigger day-2 comeback + reward-timed (not generic) push (+18% D7 case). **Endowed progress (Nunes & Drèze 2006): 10-stamp card pre-stamped 2 → 34% vs 19% completion** — start any journey track at 2/N. **One day-1 achievement completion → 33.4% vs 20.4% next-day retention (Duolingo).** 8-day login calendars with aspirational final rewards are near-universal in top grossers; final day worth more than days 1-6 combined. Session-1 churn predictors (duration, claims, feature touches) reach ~73-81% accuracy with 1 day of data → tailored D1 interventions.
- **Trial-as-event:** framing the window as a milestone-tracked journey (battle-pass-lite) is directionally supported; the paywall should fire **at the completion peak** because in-window decisions are made once and users rarely re-encounter a passed paywall.
- **Ethical/legal lines:** paid randomness = Belgium/NL gambling rulings **and maysir (haram)** — never; streak anxiety is a documented dark-pattern criticism — mitigate with generous freezes + gentle copy; no public worship leaderboards (riyāʾ); no social debt ("you let X down") — social = intercession (gift a dua).

## 10. Implementation facts (2026 state of the art, verified)

- **Rive:** `rive` 0.14.9 / `rive_native` 0.1.9 (FFI rewrite; Flutter ≥3.28 OK). `Factory.rive` renderer sidesteps Impeller quirks. Data-binding view models (number/bool/enum/trigger) are the modern API — bind `streakLength`/`growth` from Riverpod. Perf vs Lottie: ~32% vs ~92% CPU, ~60 vs ~17 FPS, files 10-15× smaller. **Arabic/RTL inside Rive: unsupported (no BiDi/shaping) — Arabic stays in Flutter Text.** CI must cache native-lib downloads. Specialist $75-150/hr; ~$2-8K for reveal+milestones; ~$3-8K for a rigged multi-stage companion. One `growth` scalar (server-derived via `sync_all_user_data()`) drives the whole garden scene. *(Note: the repo currently has a Lottie pipeline — see MEMORY `lottie-animation-pipeline`; a Rive migration decision should weigh what's already shipped.)*
- **Widgets:** `home_widget` 0.9.3 is plumbing only — widget UIs are native SwiftUI (WidgetKit) + Kotlin (Glance). `renderFlutterWidget` → PNG gets Amiri/Aref-Ruqaa typography into widgets. iOS refresh budget ~40-70/day → **freshness = multi-entry precomputed timelines** written on app foreground (now: OK → 8pm local: at-risk → midnight: lost) — correct with zero background execution. Effort: static daily widget 4-7d; lock-screen +2-3d. *(Post-snapshot: a duʿā-times widget and Live Activities have since shipped — see MEMORY.)*
- **Live Activities:** `live_activities` 2.4.9 + OneSignal first-class support (`setupDefault()`, REST start/update/end, .p8 key); countdowns tick natively via `Text(timerInterval:)`.
- **Streak server:** per-user IANA tz; day = `(ts AT TIME ZONE tz - interval '4h')::date`; increment in the check-in RPC (idempotent, `FOR UPDATE`); freeze = ledger-backed auto-consume on gap=2; repair = 48h-window RPC + token charge; hourly pg_cron sweep only for boundary consumption + at-risk push (pg_net → Edge Function → OneSignal batched `include_aliases`, ≤20K/request).
- **OneSignal:** Growth tier required for custom events + >2-step Journeys ($19/mo + $0.012/MAU ≈ $79/mo @5K MAU); free-tier stopgap = `delayed_option: last-active`. Journey: enter on `trial_started` custom event → D0/D1/D2 → exit on `subscribed`. REST key in Edge Function secrets only.

## 11. Where the decisions live

The plan of record turns all of the above into sequenced work: **[`2026-07-03-reel-first-conversion-refactor.md`](../superpowers/plans/2026-07-03-reel-first-conversion-refactor.md)** — v1 (reel-first onboarding, feeling-first core loop, beat decks, instrumentation), §G (Promise Ledger: reel→app contract, answer→consumer map, 7-Name Journey), v2 (retention stack + revised roadmap + metric targets), v3 (3-day hook architecture: two-session adhkar backbone, Trial Journey with endowed 2/8 track, beginner's barakah, appointment layer, reverence firewall, roadmap deltas). Related ADR/readouts: `docs/decisions/monetization-model.md`, `docs/analytics/reverse-trial-experiment-readout.md`.

---

## 12. 2026-07-23 refresh — fresh experiment read, shipped inventory, and the hard-vs-soft research pass

### 12.1 Reverse-trial experiment (Supabase prod, signups since T0 2026-06-18, n=768)
| Arm | Signups | Subscribed | % |
|---|---|---|---|
| Control (no trial, soft post-tour gate) | 410 | 10 | **2.44%** |
| Treatment (3-day reverse trial → soft gate) | 358 | 6 | **1.68%** |

Underpowered (16 conversions), but stable across two pulls: the reverse trial doesn't win, and **both soft arms sit at the freemium median (~2.1%)** — the ceiling is the gate model. (Supersedes the 07-14 doc's "control ~5%" figure. Treatment identified via `trial_premium_until IS NOT NULL`.)

### 12.2 Shipped since 07-03 (git-verified)
Beat-deck story format (wall-of-text fix) · streak overhaul Phases 0-3 (soft-decay ladder, paid repair, excused days, server-side milestones, freeze-burn, month-of-light, reverent notif copy) · lantern companion (non-figurative, 3 surfaces) · widget gallery (Duʿā Times / Name / Lantern + lock screen + 8pm at-risk timeline state) · Live Activities v1 · emerald premium cards · unified notification decision model · level-up/milestone Lottie animations · paywall benefit checklist + free-user premium strip. Animation stack settled on **Lottie** (not Rive).

### 12.3 Hard-vs-soft paywall research pass (2026-07-23; MEASURED unless noted)
- **Lens matters:** RevenueCat measures install→paid (hard wins ~5×: 10.7% vs 2.1% D35, RPI 8-9×, identical 1-yr retention, refunds +70%); Adapty measures view→paid (soft wins ~50% per-view because fewer users ever reach a soft wall). For maximizing paid per new user, install→paid is the right lens.
- **Placement/format:** onboarding paywalls beat in-app (1.35% vs 0.89% w/ trial, Adapty); multi-page value-establishing paywalls +37% (Superwall, 40M opens); real store trial is the biggest LTV lever (weekly no-trial $7.40 → 3-day trial $54.50 LTV, +636%; trial users retain 1.4-1.7×); post-close welcome/exit offer +10-15% ARPU.
- **Rootd "5×" corrected:** it was a *dismissible trial paywall moved to the front of onboarding* (hybrid "secret freemium"), not a locked door — near-zero negative feedback. This is the template.
- **Duolingo doesn't transfer:** 9.1% paid penetration works via 137.8M MAU + ads on the 93% who never pay + zero marginal content cost; "freemium math works at 1M+ MAU, rarely at 10K" (Airbridge). Their Hearts→Energy throttling backlash = never throttle your own value proposition.
- **Why our reverse trial lost:** endowment requires the loss to be *felt*; behind a toothless gate (191 free dismissals/30d, 3% cap-hit) expiry is a non-event.
- **Faith line:** backlash targets gating scripture itself (Muslim Pro / Quran-app reviews); Hallow (~85% gated, first-session paywall, daily devotional free, $69.99/yr) and Glorify ($83.88/yr, daily devotional free, sponsor-a-membership) prove gating personalization/tools is accepted. Names/verses/duas/daily reveal + share card stay free.
- **Low-volume testing:** need ~200 subs/variant for significance → test only big architectural levers; 2 arms max at ~21 signups/day; pre-registered 6-8 wks; early read on Day-0 purchase + checkout-starts, decide on D30 RPI; daily guardrails = review velocity/stars, refund rate, D1/D7.
- Sources: RevenueCat SOSA 2026 · Adapty State of In-App Subscriptions 2026 · Superwall multi-page study · Airbridge 2026 · Purchasely (Rootd) · growthgems hard-paywall mitigations · Hallow/Glorify help centers · BuzzFeed "Nothing Sacred."

### 12.4 Resulting decision
Plan v5 (2026-07-23): reverse trial retired; new reel-verbatim onboarding (problem-first hook, full story-deck reveal + sealed second Name, problem-derived questions) ends in a **front-loaded, hard-looking, dismissible-to-limited-free paywall with a real RC 3-day trial (annual-anchored)**; free tier tightened to a small AI taste with actives grandfathered. A/B vs current soft control, targets 5-8% signup→paid conservative.

> **2026-07-23 amendment (founder decision):** the trial ships at **7 days**, not 3 — see plan §V6.3.2. The 3-day figure above is superseded (RC 2026: ≤4-day trials are the worst-converting bucket; diagnosis changelist #3 concurred). 7d-vs-3d remains a conditional post-read fast-follow only.
