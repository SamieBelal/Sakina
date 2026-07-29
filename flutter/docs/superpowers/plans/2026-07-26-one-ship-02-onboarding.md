# One Ship 02 — W2 Onboarding Rebuild

**Status: APPROVED (founder, 2026-07-26 — all 4 open items decided: bundled JSON · deterministic Silver · aspiration map author=Claude/reviewer=founder · anxiety pair v2 approved). Build in progress — A–E done + reviewed; G built; F (rewritten 2026-07-28 — the tour is DELETED, not suppressed) and H open. ⚠️ Wave H corrects the ICP this plan was written against — read H0 before implementing any user-facing copy.**
**Date:** 2026-07-26 · **Waves G and H added 2026-07-28**
**Branch/worktree:** `feat/reel-first-w2-onboarding` at `/Users/appleuser/CS Work/Repos/sakina-reel-first` (rebased 2026-07-28 onto master `433c537` = lantern cosmetics PR #61 merged; was off `44f8628` = W1 merged, W1 schema live on prod, dormant)
**Parents:** distilled doc Phase 1 → W2 (incl. the founder-approved hook-screen UX spec + mock) · plan of record §V5.1/§V6.8 · `2026-07-25-name-stories-deck-format.md` · decks in `docs/superpowers/content/decks/` (12 approved; anxiety pair = DRAFT v2 awaiting founder) · W1 plan (binding notes)

W2 is the client rebuild of onboarding: reel-voice hook screen → story-deck reveal → real-queue plan screen → deferred signup, default-on for new users with the complete legacy flow retained behind the `reel_first_onboarding_enabled` kill switch. No paywall changes (W4), no daily-loop changes (W3), no analytics beyond stubs the screens need (W5 completes).

---

## Verified baseline (from the 2026-07-26 code map; all refs checked)

- Page machinery: `onboarding_provider.dart:21-52` (index constants, trimmed=19 / legacy=26), `onboarding_screen.dart:396-512` (two child lists), `OnboardingFinalGate` leaf-switch contract at `:568-580`. Six test files pin indices and will be rewritten.
- Current hook screen `first_checkin_screen.dart`: emotion chips (hardcoded `:41-48`), 2-line text field primary, chips hidden on focus `:151-155`, two-step commit, ~36pt chips — all condemned by the approved UX spec. Keep only the 60ms stagger-fade pattern (`:198-199`).
- Current reveal = `CardRevealOverlay` at hardcoded **Bronze** (`first_checkin_screen.dart:320-321`) + `StarterNameData` 7-Name emotion map (`demo_result_card.dart:130-167`) — both replaced.
- `BeatRevealFlow` (`lib/widgets/beat_reveal/`): consumes `ReflectResponse` only; `BeatKind` enum at `beat_reveal_models.dart:6`; two call sites (reflect/muhasabah) use static `onAnalyticsEvent` hooks; **no onboarding surface constant exists**.
- **No machine-readable decks exist** — the 14 approved decks are markdown prose. No `install_id`/alias machinery exists. `docs/qa/ui-map.md` does not exist (W6 creates it).
- Deferred-signup precedent: `pending_referral` prefs key + pure parser + cold/warm link capture in `main.dart:51-113` — the pattern `sakina://reel|feel` clones.
- W1 server objects live, zero client references yet: `seed_name_queue` (refuses re-seed — call once, treat raise as non-fatal), `unseal_next_name`, `acquisition_promise`/`onboarding_flow`/`first_problem_text` columns (freeze only after `onboarding_completed=true`; MUST ride the final persist in `saveOnboardingData`, `auth_service.dart:273-303`), sync now returns the six W1 profile keys (client parser ignores them until extended).
- Tour trigger chain mapped: suppression seams are `progress_screen.dart:165-172` + an early return in `resumeForGate()` (`onboarding_tour_controller.dart:238`) — keyed on the user's `onboarding_flow`, NOT on flag flips (kill-switch revert must restore the tour).

## Binding rules carried in

- Scripture only from verified sources: decks are transcribed **verbatim** from the founder-approved files; nothing AI-generated at build time. Arabic and Latin never share a `Text` — deck JSON keeps `arabic`/`transliteration`/`translation` as separate fields end-to-end.
- **Unseal/reveal never directly grants tokens/XP/tier** (W1 binding note): the card award goes through the existing gacha/economy path; the queue only picks the Name.
- No urgency mechanics on the hook screen; no progress bar there; ~~sign card distinct by typography only (founder decision 2026-07-25)~~ → **sign card has NO visual distinction, founder 2026-07-29; see Status addendum D1.**
- Reverence firewall applies to all new copy (no "sign" language system-initiated, no waiting-Allah claims, tier language attaches to card not Name).

---

## Wave A — Deck content pipeline (the long pole; everything else renders it)

**A1. Machine-readable decks.** New asset `assets/content/name_stories.json` (bundled by the existing `assets/content/` glob): array of deck objects per the spec's metadata JSON (`deck_id, name_id, chip_keys[], beats[], sources[], author, reviewed_by, reviewed_at, review_verdict`), each beat `{kind, label?, primary, arabic?, transliteration?, translation?, source?}` with kinds from the spec table (bridge, name_intro, story×3, verse, dua, takeaway, recognition, comfort_verse, pair_synergy). Content transcribed **verbatim** from the 7 approved deck files (14 decks). Loaded by a small `NameStoriesService` (asset-only in W2 — no Supabase table yet, so no overwrite-drift risk; the public-catalog contract shape is deliberately mirrored so a server refresh path can be added post-keep without reshaping).

**A2. Ship gate as a test, not runtime logic:** `test/content/name_stories_ship_gate_test.dart` asserts (a) every chip key in the taxonomy maps to exactly 2 decks, (b) every deck has `review_verdict == 'good'` + non-empty `reviewed_by/at`, (c) every verse/dua beat carries all three script fields separately and none mixes Arabic+Latin in one string, (d) `name_id`s exist in `collectible_names.json`, (e) beat kinds/order match the spec. A failing deck fails CI — uncovered chips can never render (the runtime fallback to the comfort pair still exists as defense).

**✅ RESOLVED (verified 2026-07-29 — all seven deck files now read APPROVED, ship gate green).** Original text kept for history: **⚠️ BLOCKING PRE-A1 DEPENDENCY (review 6): the anxiety pair is NOT approved.** Its file header reads "DRAFT v2 — awaiting founder review" (the v2 revision reset it; the other six files carry APPROVED = 12/14 decks). The transcriber carries the TRUE status — never stamps `good` on unreviewed scripture — so until the founder approves anxiety v2, the ship gate correctly fails the anxiety chip and it falls back to the comfort pair. Founder sign-off on anxiety v2 is an open item below.

**A3. Beat spine extension.** Add `BeatKind.recognition` + `BeatKind.comfortVerse` (`beat_reveal_models.dart:7`) with rendering in `beat_screen_view.dart` — Dart 3 exhaustive-switch errors will surface BOTH switch sites (`_content` and `semanticText`; review 13). **Wire format decided now (review 12): analytics emit snake_case via a `beatKindWireName` extension (`comfort_verse`, not `comfortVerse`)** — retrofit the two existing emitters (`reflect_screen.dart:224`, `muhasabah_screen.dart:232`) in the same change so `beat_kind` is uniform (existing kinds are single-word, so historical values are unaffected). Add a **deck-native path**: `buildBeatScreensFromDeck(NameStoryDeck, {includePairSynergy})` returning `List<BeatScreen>` directly, and a `BeatRevealFlow.deck(...)` constructor variant. **Dua beat (review 7):** `BeatScreen` gains standalone `duaArabic/duaTransliteration/duaTranslation/duaSource` fields and the `BeatKind.dua` render case prefers them over the legacy `ReflectResponse? dua` (which currently renders `SizedBox.shrink()` when null — the deck path would otherwise show a BLANK dua screen); the Ameen overlay keys off `BeatKind.dua` and applies to deck flows intentionally. Existing `ReflectResponse` path untouched (pinned by existing tests).

**A4. Surface + analytics stubs:** `surfaceOnboardingReveal = 'onboarding_reveal'` beside `analytics_event_names.dart:44-45`; `reveal_deck_completed/abandoned` constants; emitted via a plain callback into `analyticsProvider` (no Riverpod in the widget lib — same hook pattern as the existing call sites).

## Wave B — Hook screen (the approved UX spec, verbatim)

**B1. Chip taxonomy constants:** new `lib/features/onboarding/content/problem_chips.dart` — the 6 problem chips + sign chip with `chip_key`, sentence label, `problem_category`, `contract` ('problem'|'sign'), Name-pair ids (pairs per the approved table; comfort pair Ar-Rahman+Al-Latif as fallback), and the free-text keyword map (must catch family/marriage/exams/sleep/grief → nearest chip; unmatched → comfort pair + `problem_category:'unmatched'`).

**B2. New `hook_problem_screen.dart`** replacing `first_checkin_screen.dart` at page 0 of the reel flow, per the spec: single-column full-width cards ≥64pt, 16px radius, ~12px gaps; tap=commit (selected tint + haptic + ~450ms beat → advance — mutation in the tap handler per the Riverpod build-phase rule, respecting `_navigating`); header "What's weighing on you right now?" + "Take your time."; **no progress bar**; illustration cut; ~~free text demoted to an expanding "Or say it in your own words…"~~ → **a modal (D4)**, never hides the cards; sign card last, ~~typography-only distinction~~ → **no distinction (D1)**; all 7 visible ≥812pt, gentle scroll + fade below; 60ms stagger-fade; 44pt/Dynamic-Type/VoiceOver.

**B3. State:** `OnboardingState` → `version: 8` adding `contract, problemCategory, chipKey, problemTextRaw, pairNameIds, aspiration, carryingDuration, reelSource, reelId, hookType` (map's field list; `demoFeelingInput` machinery retired from the reel flow). Writes `acquisition_promise` `{reel_id?, hook_type, contract, problem_category}` + `first_problem_text` + `onboarding_flow:'reel_v1'` into `saveOnboardingData` (new named params + UPDATE columns) so they ride **every** persist including the final one.

## Wave C — Reveal + queue + card award

**C1. Reveal sequence** (replaces the demo-checkin theater): chip commit → brief loader (reuse `SakinaLoader`, not the 3.5s fake theater; `GeneratingScreen` is absent from the reel order) → **Name₁ deck** on `BeatRevealFlow.deck` (sign contract prepends `recognition` beat + `comfort_verse`); "Ameen" → **card award at deterministic SILVER** (review blocker 1: no gacha tier roll exists anywhere — first discovery is hardcoded Bronze at `card_collection_service.dart:2066-2071`; a weighted roll would be a NEW economy mechanic needing its own review): render `CardRevealOverlay` with `revealSpecFor(CardTier.silver)`, persist by generalizing `seedStarterCard` to seed at `'silver'`. If the Name is already met, **clamp** to `max(current, silver)` — never an engage-style increment (`completeOnboarding` is designed to re-run, review 8b). A weighted Silver/Gold/Emerald roll is post-keep polish. Then **Name₂ tease**: identity shown (name + transliteration + one-line anchor), deck sealed with unseal-tomorrow framing (no countdown clock). The reveal is fully local pre-auth (deck asset + const `allCollectibleNames` — review-verified); the SEEN tier is fixed (silver) so a pre-auth kill can't desync seen-vs-persisted tier.

**C2. Queue seeding:** after signup succeeds (needs auth), call `seed_name_queue([name1, name2, r3..r7])` — rows 3-7 derived from the aspiration answer via a static aspiration→Names map in `problem_chips.dart`'s module (deterministic, reviewable). Called from `completeOnboarding()` (`onboarding_provider.dart:471+`) with **pre-check, never raise-swallowing** (review 5: the RPC raises the same errcode for already-seeded, bad length, AND duplicate ids — swallowing hides a wholesale seed failure that leaves the user with a dead W3 unseal): SELECT own queue via RLS (`NameQueueService`); rows exist → skip; zero rows → call RPC and treat ANY raise as a surfaced error. Unit test pins that every aspiration sequence is internally unique AND disjoint from every chip pair + the comfort pair. Ordering fix (review 8a): the `prefs.remove(_prefsKey)` state wipe moves AFTER the server writes so a crash mid-completion can't re-run onboarding with a fresh Name₁ against a frozen queue. Position 1 is born unsealed server-side — matches Name₁ being met in onboarding.
**C3. Sync parser extension:** `user_data_batch_sync_service.dart` surfaces `onboarding_flow` (→ `AppSessionNotifier`, for tour suppression) + `acquisition_promise`/queue hydration hook (`user_name_queue` rows arrive via RLS select in a small `NameQueueService`; W3 consumes).

## Wave D — Derived questions, plan screen, source question

**D1. Questions between reveal and signup** (all single-tap, question-scaffold reuse): "How long have you been carrying this?" (pacing + AI-context field), aspiration (sign-register variant when contract='sign') → queue rows 3-7, reminder-time screen retained as-is. The §V6.8.A6 orphan questions (age/prayer-frequency/familiarity/dua-topics/commitment/attribution/intention) are **absent from the reel flow** (files stay for legacy).
**D2. Plan screen rebuild** (`personalized_plan_screen` successor): renders the **real 7-Name queue** (Name₁ met ✓, Name₂ sealed-tomorrow, 3-7 as veiled silhouettes) + the 8-stamp journey track pre-stamped 2/8 (arrived + first Name; replaces the legacy journey timeline) — **rendered as a filling BAR since 2026-07-29, semantics unchanged (D3)**. Copy in depth register, no worship-streak framing.
**D3. Post-reveal "Where did you find us?"** single-tap (TikTok/IG/friend/other) → stored in state. **⚠️ SHIPPED AS `reel_source_selected{source}`, not the specified `reel_source_captured`, and NO `reel_hook` super property exists (D5). W5 work; setup steps in TODO.md.**

## Wave E — Flow assembly, deferred signup, deep links

**E1. Flow selection — THREE flows coexist (review 4):** at onboarding entry, read `reel_first_onboarding_enabled` (app_config, `AppConfigService` pattern, fallback **true**). ON → `_reelChildren()` (new order: hook → reveal → questions → plan → signup → paywall gate). OFF → **the existing behavior exactly**: `onboarding_trim_enabled` selects trimmed(20) vs legacy(27) as today (`onboarding_screen.dart:174-182`) — the kill switch must reproduce the current prod experience, which is the TRIMMED flow, not the 27-page one. Three child lists + three index-constant sets until post-keep deletion. `onboarding_flow` state field set at entry ('reel_v1' vs 'legacy' for both fallback flows). Step-name analytics map gains the reel steps (stable `step_id`s). Reel progress bar: new `totalSegments` for the ~10-page flow, hidden on hook + reveal + paywall pages (review 9). `/welcome` (`HookScreen` at `router.dart:218`) is deliberately unchanged in W2 — the reel journey still enters through it (review 11).
**E2. Deferred signup:** signup trio moves to after the plan screen in the reel order (value first, account last). All pre-auth state lives in `OnboardingState` v8 prefs (survives restart mid-flow — including the revealed Name pair, so an app-kill after the reveal resumes with the SAME Names). `persistOnboardingToSupabase` unchanged in timing (post-signup); queue seed + starter card seed remain in `completeOnboarding`. **Social-auth landing (review 10):** new `onboardingReelPostSignupPageIndex` constant — `onSocialAuthComplete` in the reel order jumps there (the page after the signup trio), replacing `_skipToPostSignup`'s trimmed target; `onboarding_auth_routing_test.dart` is rewritten to pin it.
**E3. Install id:** generate a UUID once at boot (unscoped prefs), register as `install_id` super property; Simplified ID-merge links pre-signup events at `identify()` (no alias API needed — verified house identity model); set the same id as a RevenueCat subscriber attribute at purchase-service init (the RC↔Mixpanel join key). 
**E4. Deep links:** clone the `pending_referral` pattern (`main.dart:70-113`): pure parsers for `sakina://reel/<id>` and `sakina://feel/<emotion>` (+ optional `name_ids` query override per §V6.8.A1, validated ints ∈ catalog), unscoped prefs keys, captured cold+warm before `runApp`, drained by the hook screen (pre-select chip for `feel`, stamp `reel_id`/`hook_type` for `reel`). Best-effort: malformed → silent ignore.

## Wave F — Delete the tour, first-visit hints, rating gate, tests (REWRITTEN 2026-07-28)

**Founder decisions 2026-07-28 supersede the original F1–F3.** The tour is not suppressed for reel users — **it is deleted for everyone**. The rating gate **stays in onboarding**. Coachmarks are replaced by a different mechanic entirely (see F3 — the existing "coachmark" component is itself a forced tour, which the earlier F3 wording missed).

**⚠️ F0. DO NOT "just flip `guided_tour_enabled`" — it strands users, and it does so in the CURRENT build.** This is the obvious lever to reach for in an incident, and it is the wrong one. The flag is read inside the *controller* (`onboarding_tour_controller.dart:136-139`), which returns early and — by explicit design, so the tour can be switched back on later — **does NOT mark the tour seen**. But the *router* never consults the flag: `onboarding_stage.dart` routes purely on booleans (`!tourCompleted → tour`). So flipping it produces: router sends the user to stage `tour` → controller declines to start → **user parked on a dead stage with no tour and no paywall**. The flag is a PAUSE, not an OFF.

Who is actually exposed: users onboarded before the gate shipped were backfilled `onboarding_paywall_cleared = true`, and `paywallCleared` short-circuits BEFORE the tour check — they route straight to `app` and are unaffected by anything here. Users who finished the tour have `tourCompleted = true` — also unaffected. **The at-risk group is only: signed up after the gate, `tourCompleted = false`, `paywallCleared = false`** — i.e. mid-tour or abandoned inside it, which given the ~48% tour leak is a real slice of recent signups.

**This makes F1a strictly SAFER than the flag.** Collapsing `tourCompleted` to vestigially-true does not merely stop new users entering the tour — it **releases everyone already trapped in it** on their next launch, dropping them to the paywall stage (or `app` when `post_tour_paywall_mode` is `off`), which is where they should have been. If a lever is needed before F1a ships, the correct ones are `post_tour_paywall_mode`, or a server-side backfill of `onboarding_tour_seen` for stuck users — never `guided_tour_enabled=false`.

**F1. Delete the tour, in two phases.** The original design threaded a dual path around a live tour; deleting removes the whole stranding-bug class instead of routing around it. But the footprint is **26 files** (9 tour/coachmark + 17 referencing, incl. `main.dart`, `router.dart`, `app_shell.dart`, `app_session.dart`, `onboarding_gate_service.dart`) — too much blast radius for one change in a wave that also has to ship. Split:

  - **F1a (this wave) — kill the trigger and collapse the stage.** This is where the danger lives. Remove the tour trigger (`progress_screen.dart:165-172`, `onboarding_tour_controller.start()` / `resumeForGate()`), unmount `OnboardingTourOverlayHost`, and make **`tourCompleted` vestigial (always true)** in `app_session.dart` + `onboarding_stage.dart` + `onboarding_gate_service.dart` + `tour_service.dart`. Once nothing can enter stage `tour`, **no user of any flow can be stranded without a paywall surface** — the bug class is gone by construction rather than by guard. Touches ~10 files.
  - **F1b (post-keep cleanup, NOT this wave) — remove the inert remains.** The `TourAnchor` GlobalKeys scattered through duas/journal/muhasabah/progress/settings become harmless dead weight once nothing reads them; likewise `tour_anchor_registry`, `tour_route_observer`, `onboarding_tour_step`, `coachmark_overlay`, `coachmark_step`. **`deferred_celebrations_provider` needs care, not a blind delete** — it exists solely to withhold gamification celebrations while the tour runs, so removing it means those celebrations start firing live; that is a behaviour change to schedule deliberately.
  - **Consequence, accepted by the founder:** the kill switch no longer restores the tour. Flipping it yields the trimmed flow *without* it. Since the tour is the ~48% leak, there is no scenario where we would want it back — but this is a one-way door and it is recorded as such.
  - **Pre-W4 gate behaviour, unchanged from the original F1.2:** reel users see the existing `PaywallScreen(placement: placementOnboarding)` as the final-gate page, dismissible, then stage `app`. W4 replaces its contents; the position is already right.

**F2. Rating gate STAYS in the reel flow** (founder call — reversing the original "relocate to post-D1-unseal"). Placement: **after the plan screen**, so it lands on the payoff rather than before it. ⚠️ Note when building: despite the name, `rating_gate_screen.dart` is **not** a two-step "are you enjoying Sakina?" gate — it calls `InAppReview.instance.requestReview()` directly (`:66-78`). iOS silently rate-limits to 3 prompts/365 days, so a user who has not yet received value can burn one of three attempts on a low rating. Existing `os_prompt_available` instrumentation tells us who actually saw the system sheet.

**F3. First-visit hints — a NEW component, not a reuse.** The earlier F3 said "reuse the coachmark overlay pattern". That was wrong: `CoachmarkOverlay` **is** a guided tour — its own header calls it one, it takes `stepIndex`/`totalSteps`, it installs *"invisible absorber strips… so the user can't wander off the tour"*, it advances only on a target tap, and it has an `allowSkip: false` mode for the mandatory gate. Reusing it would rebuild a small forced tour with the same DNA as the big one.

  - **The mechanic (founder-specified):** **per-surface, first-visit, independent, once-ever.** A small cream banner near the thing it describes. **No dimming, no tap absorbers, no step counter, no skip affordance, no sequence.** Dismisses on any tap anywhere, or auto-fades ~6s. One prefs key per hint. Ignoring it entirely blocks nothing and loses nothing. Fired lazily on first arrival at a surface — so hints spread across days naturally, and a user who never opens a surface never spends its hint.
  - **Which surfaces earn one** (test applied: is the feature genuinely not self-explanatory?): **Reflect** (the tab name does not convey what it does, and it is the single biggest payer/free behavioural gap — 13.0% vs 36.8%); **Companion stage** (reached by *tapping the Home medallion* — an unguessable gesture; the same hint can carry why the lamp is dim); **Noor** (a currency with no explanation of what it is or where it comes from). **Held in reserve:** Build-a-Dua — "Build" is a non-obvious verb but it already gets 55% free usage, so it is demonstrably discoverable; let `dua_built` decide.
  - **Explicitly do NOT earn one:** Collection, Journal, Duas tab, streaks, widgets (Wave G covers them), the daily unseal (the plan screen sets it up, and Wave H strengthens that).
  - **⚠️ Guardrails are binding, not optional.** Per-surface hints with no global budget is precisely the Clippy failure mode the Wave G mascot research names (excessive interruption). Three rules: **max one hint per session**; **none during the first session after onboarding** (the user has just come through ~18 pages — a hint there reads as more onboarding); and a **lifetime cap**, so this cannot quietly grow into a hint system as features ship.

**F4. Tests:** rewrite the index-pinned files for the current page counts; a test asserting **no blocking overlay can be constructed on the reel path** (the F1 bug class, pinned so it cannot return); first-visit-hint tests (once-ever, non-blocking, auto-fade, and each guardrail); `flutter analyze` + full suite green; RTL/Arabic isolation on all new surfaces (W6 re-verifies on device).

## Wave G — The lantern in onboarding (added 2026-07-28)

**Full spec: [`2026-07-28-lantern-in-onboarding-design.md`](../specs/2026-07-28-lantern-in-onboarding-design.md).** Founder-approved 2026-07-28 after a research pass over Duolingo's 17-screen onboarding + the mascot/companion literature. Summary only here; the spec is the contract.

**G0. Role decision (binding).** The lantern is a **MIRROR, not a GUIDE** — it never speaks, never gets a speech bubble, never uses first person. Duolingo's layout system transfers; its mascot personality does not (a talking object over "I keep sinning and going back" is the Clippy failure mode and collides with the reverence firewall). What the lantern has instead is seven real states wired to behaviour — Duo's poses are costumes, ours are consequences.

**G1. Kindling beat (NEW-A).** The bare `SakinaLoader` phase between hook and reveal (already specified in C1) gains a body: the lamp **catches**, once, because of what the user just said. Glow 0 → 0.34 over ~900ms with a luminance-only flare to ~0.45. Pre-kindle frame is `pendingUnlit` params with `wear: 0` — **never `dormant: true`** (cold Day 0 is a standing reverence guardrail). **⚠️ The flame's on/off threshold is `g < 0.04` and breath modulates `g` ±10%, so the ramp must cross 0.04 decisively or the flame blinks once per breath** — test-pinned. Not a new PageView page.

**G2. Placement map.** HERO at: NEW-A, page 6 (notifications, at `pendingUnlit` — "waiting to be lit" is literally true, and it converts an OS permission ask into a stake the user already owns), NEW-B, page 7 (queue plan, `endowedDim`). **ABSENT** at `/welcome`, page 0 (we removed the basmala from that screen for being decoration — a lantern is the same mistake), pages 2–5, pages 8–11, and **page 12 the paywall — a dim lamp beside a price reads as "pay to light it", enforced by test, not convention.** The ANCHOR (small persistent corner lantern on question screens) is **cut for v1**: with no bubble to hold it is decoration.

**G3. Widget carousel (NEW-B).** New page after notifications: all **three** shipped widgets in a browsable `PageView` (founder override of the single-dominant-option recommendation; the choice-overload trade is recorded in the spec). Order: Your Lantern → A Name for What You're Carrying → Duʿā Times. **⚠️ iOS has no API to add a widget** — the CTA opens an instructional sheet and installs nothing (Duolingo's button is instructional too). **We are NOT reordering `SakinaWidgetBundle.swift`** — that would change the gallery for every existing user.

**G4. Index migration + tests.** `onboardingReelLastPageIndex` 12 → 13; the six index-pinned files move with it. New tests: flame-blink guard, reduce-motion, **paywall-absence**, placement map, carousel order + "Not now", pre-auth `classicGold` skin fallback.

**G5. Implementation debt to clear in-wave.** `CompanionMedallion._loadShader()` calls `FragmentProgram.fromAsset` **per instance** — add a static cached future before four placements ship. Use `renderableLanternSkinProvider` at every placement (never hardcode a skin); its `autoDispose` fallback to `classicGold` is correct for the pre-auth pages, not a bug. `ambient: true` only on the dark sacred canvas; `ambient: false` everywhere else or the dormant vignette renders as a grey box.

**Corrected baseline:** the lantern is **already in onboarding** — `card_reveal_overlay.dart:506` renders a `CompanionMedallion` as the card's vessel (master `6bece34`), and our reveal screen pushes that overlay. Page 1 is not a blank slate; G1 lands *before* an appearance the user already gets, which is the right order.

## Wave H — Intake depth + the comfort opening (added 2026-07-28)

**Full spec: [`2026-07-28-onboarding-intake-depth-design.md`](../specs/2026-07-28-onboarding-intake-depth-design.md).** Question set settled with the founder 2026-07-28. Summary only here; the spec is the contract.

**⚠️ H0. The ICP this plan was built against was WRONG, and the correction drives everything below.** An ICP pass concluded "lapsed/returning Muslim" — but both researchers reasoned backwards from our own shipped taxonomy ("again", "even when I slip", "I keep sinning and going back"), which is a downstream chip-set decision, not evidence about who arrives. The acquisition truth is the two reels (§V6.1): Reel 1 promises *Names that solve your problem*, Reel 2 promises *Allah is aware, He does not burden a soul beyond capacity, learn His Names*. **Neither mentions drifting, sinning or returning.** Corrected ICP (founder-confirmed): **a Muslim at ANY level of practice, in a period of real difficulty.** The axis is acute weight, not religious lapse — a devout user having the worst month of their life is squarely the target. Guilt/distance are 2 of 7 things they might carry, not the centre.

**H1. The central finding: we under-ask.** Only three questions are about the user (problem, duration, aspiration); everything else is an ask *of* them or a payoff. The in-repo research says intake QUIZZES convert better longer (Noom/Duolingo/Flo/Headway 30+; shortening a winner cost −13%) while product TOURS convert better shorter. W2 deleted the tour — correct — and trimmed the intake too, which was the wrong half. It collides with the product thesis: rows 3–7 come from ONE answer, so the "personalised plan" is one of five pre-baked sequences, and the Day-0 depth-buyer converts on feeling *specifically* seen. **Governing constraint: every intake question must produce a visible consequence on the plan screen, asserted by test — an extractive longer form is worse than the three we have.**

**H2. Seven intake questions** between reveal and plan: duration *(exists)* · **when is it heaviest** (derives the reminder time — **deletes the reminder-time ask**) · **have you told anyone** (approved, conditional on acting on it) · **how many Names could you name** (the projection baseline — Duolingo's "how much French do you know?") · **what would help most** (multi-select, replaces aspiration) · **how much time feels right** (**NOT a commitment device** — founder call; streak/lantern/widget own commitment, and "I'M COMMITTED" is explicitly not imported) · **anything to add** (skippable free text — a payer-detection surface, since payers do 3× reflections).

**H3. The multi-select is a calm chip cloud, capped at 3.** Seven full-width multi-select rows would reintroduce the exact "seven stacked rectangles" failure the hook screen was redesigned to escape. Sourced mitigations: constrain the count (Daylio caps at five; Chernev says the levers are categorisation + constraint, not fewer options), chips over rows (Material 3), and Headspace's own multi-select "What brings you to Headspace?" as the closest comp. **"You can change this later" is load-bearing copy** — this ICP's top fears include failing at another thing. Two new options carry motives nothing currently captures: **"Learning His Names"** (Reel 2's literal promise) and **"Strength to keep going"** (sabr/endurance). The hook screen stays single-select full-width — that inconsistency is deliberate and recorded, not a bug.

**H4. The comfort opening replaces the welcome screen** (founder's proposal). 2:286 in motion + one short English acknowledgement → smooth transition into the hook. It REPLACES rather than precedes `/welcome` (else two gates before the ask); only the "I already have an account" link survives. **Supersedes review 11's "`/welcome` unchanged" note** — that predates the reel-contract audit. Rationale is ad-scent, not decoration: a Reel-2 arrival promised 2:286 currently meets a *different* ayah (94:6) under the tagline "Reflect · Build · Discover" over a **remotely-fetched `googleusercontent.com` image**. Bundle that asset locally regardless.

**H5. Re-sequencing.** The kindling beat's slot is right, its content is wrong — the user names pain and we answer with a lamp and a streak promise; **re-voice it to acknowledgement** and move the lantern's introduction to the notification screen. **"Where did you find us?" moves off the emotional peak** (it currently asks the user to do market research for us moments after Ameen — the only screen giving them nothing, at their most open) to just before the signup trio. **Widget carousel moves after the plan.** ~~**Sign chip promoted** out of 7th place — a Reel-2 arrival's row is currently in the least-read position.~~ **⚠️ NOT IMPLEMENTED — `problem_chips.dart` was last touched in Wave B and still lists `sign` seventh. Superseded by the 2026-07-29 decision, which keeps it last deliberately: reading the six problem chips does real diagnostic work and one of them usually lands.** New order is **19 pages** (includes the rating gate, which F2 keeps, placed after the plan screen and bar-less like the other gates); `onboardingReelLastPageIndex` 13 → **18**, `onboardingReelTotalSegments` 10 → **14** → **15 (2026-07-29: the plan screen gained a progress bar, D3)**.

**H6. Retire the lapse presupposition.** "To feel close to Allah **again**" and "even when I slip" are exclusionary under the corrected ICP. Copy-test pinned so it cannot innocently revert.

## Master-rebase reconciliation (2026-07-28)

Rebased onto `433c537` — **123 commits**, chiefly lantern cosmetics (PR #61) and the sacred-canvas threshold (PR #63). Two rebase conflicts, both additive (a `sacred_canvas_threshold` vs `beat_reveal_models` import in the two AI surfaces; `stepNamesFor` vs the cosmetics constants block in `analytics_event_names.dart`). One genuine semantic break: master's `6bece34` put a Riverpod `Consumer` inside `CardRevealOverlay`, so the reveal-screen tests needed a `ProviderScope` (production always has one at the app root). **Full suite green afterwards: 2337 passed, 4 skipped, 0 failed** — note this supersedes the long-standing "the suite fails on a clean baseline" caveat; master fixed both flaky tests and gated the widget-frame generator behind `REGEN_WIDGET_FRAMES=1`.

**What the merge changed in this plan:**

1. **C1's "brief loader" wording is stale.** master `1952ba0` made `BeatRevealFlow` dissolve its own `loading` state into beat 1 rather than popping. The reveal no longer needs a separately-managed loader phase — Wave G1's kindling beat composes with that dissolve instead of replacing it, which makes G1 *cheaper*, not costlier.
2. **`SacredCanvasThreshold` is now the house entrance/exit motion** for sacred-canvas surfaces (`78a94b3`, timings in `docs/superpowers/specs/2026-07-27-sacred-canvas-threshold*`). The reveal and the kindling beat use it rather than inventing motion.
3. **F3's coachmark target list grows** — see F3.
4. **The lantern is already rendered in onboarding** and **all three widgets already ship** — both corrections are folded into the Wave G spec.

**What did NOT need adjusting:** the three-flow kill switch, deferred signup, queue seeding, the deck pipeline, and every index constant (the rebase reconciled them; the six index-pinned files pass). The `sync_all_user_data` collision flagged as a merge blocker is **resolved on both sides** — verified that the last-applied migration (`20260727100300`) is a true superset: all six W1 profile keys plus the `noor`/`equipped`/`cosmetics` sections. The tour's blocking-route handling already anticipates us: `tour_route_observer.dart:25` lists `CardRevealOverlay.routeName` with the comment "(muḥāsabah, collection, onboarding)", and our `onboarding_card_reveal.dart` uses the shared const.

## Sequencing & review gates

A (content+spine) → B (hook) → C (reveal+queue) → D (questions+plan) → E (assembly+signup+links) → F (suppression+tests) → **G (lantern)** → **H (intake depth + comfort opening)**. H re-sequences parts of G, so G must land first. Waves A+B are independently reviewable; agent review after A, C, F, G and H; founder eyeballs the hook screen + reveal on simulator after C (screenshots via `sips -Z 1600`), full flow after F, and the kindling beat + carousel after G. Merge W2 alone into master when green (same PR discipline as W1) — invisible to users until the release ships; the kill switch only ever affects the new binary.

## Review record (2026-07-26)

Adversarial eng+flow review, all 13 findings folded in. Blockers: **(1)** "clamp the gacha roll" was fiction — no tier roll exists (first discovery is hardcoded Bronze); reveal award is now deterministic Silver, weighted roll deferred post-keep. **(2)** naive tour suppression stranded reel users in stage `tour` with no paywall surface — F1 rebuilt: reel completion latches `tourCompleted`+`paywallCleared` synchronously, pre-W4 gate = existing onboarding-placement paywall. Majors: day-0 race → synchronous session mirror; three-flow kill-switch semantics (fallback = trimmed, not legacy-27); queue-seed raise-swallowing → pre-check + disjointness test; anxiety pair is DRAFT v2 not approved (blocking dependency); blank dua beat → standalone dua fields on `BeatScreen`. Minors: prefs-wipe ordering, tier clamp not increment, reel `totalSegments`, social-auth landing constant, `/welcome` unchanged note, snake_case `beat_kind` wire names, cite fixes. Also recorded: aspiration→AI-teaching-context + notification-rotation consumers are deliberately deferred (W3 / Phase B).

## Open items for founder

1. **Deck transport = bundled asset JSON** (no server table until post-keep; ship-gate enforced in CI) — confirm.
2. **Aspiration → queue rows 3-7 map**: I'll draft the 5-Name sequences per aspiration option from the approved taxonomy's Name pool; you review them like the decks (orderings of already-approved Names, no new content). Each sequence is test-pinned disjoint from the chip pairs.
3. **Card award = deterministic SILVER at the onboarding reveal** (review found no gacha tier roll exists to clamp — first discovery is hardcoded Bronze today; a weighted Silver/Gold/Emerald roll would be a new economy mechanic, deferred post-keep) — confirm.
4. **Anxiety pair v2 needs your sign-off** — its file still reads "DRAFT v2 — awaiting founder review" while the other six files are APPROVED. Until then the anxiety chip falls back to the comfort pair (ship gate enforces this).

### Wave G open items (2026-07-28)

5. **Luminance flare vs the no-bounce rule** — the kindle flare is luminance-only (no scale, no translate), so it should not breach a rule aimed at spatial overshoot; a flame flaring as it catches is physically true rather than cute. Confirm, or it falls back to a plain ramp.
6. **Widget gallery order** (`SakinaWidgetBundle.swift`, currently Duʿā Times → Name → Lantern) — pointing a new user at the third entry costs us, but reordering changes the gallery for every existing user. Product call, not blocking.
7. **`/welcome` remote arch image** — the app's first screen fetches its illustration from a `googleusercontent.com` Stitch URL (`hook_screen.dart:22`). Should become a bundled asset; out of scope for W2, recorded so it is not lost.

---

## Status addendum (2026-07-29) — post-build audit

Every W2 line item walked against what is committed on `feat/reel-first-w2-onboarding`.
Divergence IDs (D1-D8) are shared with the divergence log in
`2026-07-23-conversion-refactor-changes-and-implementation.md`; the full rationale lives
there. This section records only what changed for *this* doc.

### Open items — resolved

- **#4 Anxiety pair sign-off — RESOLVED.** All seven deck files now read APPROVED
  (verified by reading the file headers, 2026-07-29). The #1 chip by research is no
  longer falling back to the comfort pair. `test/content/name_stories_ship_gate_test.dart`
  passes, including "exactly one pair-synergy beat per pair".
- **#6 Widget gallery order — RESOLVED.** The carousel follows the iOS gallery exactly
  (Duʿā Times → Name → Lantern), so the how-to sheet reads against the same list the user
  is looking at. Commit `5c2b743`.
- **#7 `/welcome` remote arch image — RESOLVED.** The comfort opening replaced
  `hook_screen.dart` outright (commit `9721b05`), and the arch is now the code-drawn
  `MihrabArchFrame`. Worth noting what this actually fixed: the app's **first frame** had
  been fetching its illustration from a `googleusercontent.com` URL, so the opening
  depended on a third-party CDN.

### Open items — ALL CLOSED (founder, 2026-07-29)

Each was verified in code before closing, not stamped:

- **#1 Deck transport = bundled asset JSON — CLOSED.**
  `NameStoriesService.assetPath = 'assets/content/name_stories.json'`; `assets/content/`
  registered at `pubspec.yaml:134`; **no migration anywhere creates a `name_stories`
  table**. Shipped as specced. The CI ship-gate carries the approval contract, so there is
  no server dependency to add before post-keep.
- **#2 Aspiration → queue rows 3-7 map — CLOSED; it was already approved on 2026-07-27.**
  `lib/features/onboarding/content/aspirations.dart:1` reads verbatim: *"APPROVED (founder
  verdict: good, 2026-07-27 — stems, labels, and all five sequences as drafted)."* This
  item was stale, not outstanding. Invariants are test-pinned in
  `test/features/onboarding/aspirations_test.dart`: 5 options with unique keys, every
  sequence exactly 5 internally-unique ids, and **no sequence collides with any chip pair
  including the comfort pair** — the disjointness the plan required.
- **#3 Card award = deterministic SILVER — CLOSED.**
  `OnboardingRevealScreen.awardTier = CardTier.silver`, with the review-blocker rationale
  in the class doc: no gacha tier roll exists to clamp (first discovery is hardcoded Bronze
  today), and a weighted Silver/Gold/Emerald roll would be a new economy mechanic —
  deferred post-keep.
- **#5 Luminance flare vs the no-bounce rule — CLOSED, the flare stays.**
  `lantern_kindle.dart` implements it as `lerpDouble` on a glow value; the code states
  *"The flare is a **luminance** overshoot only — nothing moves, nothing scales."* The
  no-bounce rule targets **spatial** overshoot, and a flame flaring as it catches is
  physically true rather than decorative. Reduced motion drops the flare and the breath,
  never the lighting itself.

**Process note.** Two of these had already been resolved and the doc had not caught up —
#2 (approved 2026-07-27) and the anxiety-pair blocker above (all seven decks APPROVED).
Both read as outstanding for days. When an open item is answered, close it here in the same
change; a ⚠️ that has gone stale costs more than no marker at all, because it sends the
next reader to re-derive an answer that already exists.

### Divergences from this doc's own spec

- **D1** sign card visual distinction removed.
- **D3** journey track renders as a bar; `onboardingReelTotalSegments` 14 → 15.
- **D4** free text is a modal.
- **D5** `reel_source_selected` shipped in place of `reel_source_captured`; no `reel_hook`
  super property — the one genuine W2 gap, deferred to W5.
- **H5 sign-chip promotion never landed** — see the struck line in Wave H above.

### Beyond this doc's scope, shipped in the same window

The comfort opening became a two-movement cold open (greeting → verse, ~14s, tap to skip,
once per install); the hook screen took an emerald promise line and a corrected spacing
rhythm; the plan screen was rebuilt to match its siblings; the widget-offer screen now
uses real Home Screen screenshots. Paywall and referral changes are D6-D8 in the shared
log.

**W1 is complete and applied to prod** (`user_name_queue` live with RLS, all
`user_profiles` columns present, `sync_all_user_data` verified as a genuine superset of
both the W1 and cosmetics key sets, quests local-vs-UTC bug fixed per review eng-1,
softener wave written and staged unexecuted in `supabase/staged/`). Local migration
filenames differ from the prod-applied versions — same schema, and re-applying is a no-op
because every statement is guarded.
