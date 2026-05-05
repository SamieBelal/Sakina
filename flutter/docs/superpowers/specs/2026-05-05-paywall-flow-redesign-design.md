# Paywall Flow Redesign — Design Spec

**Date:** 2026-05-05
**Author:** Ibrahim Ahmed (with Claude assistance)
**Status:** Approved — ready for implementation plan
**Topic:** Restructure the onboarding paywall from a single screen into a 5-screen Cal AI–style flow to lift trial-start conversion.

---

## Goal

Increase paywall conversion (paywall view → trial start → first charge) by replacing the current single-screen paywall with a multi-screen flow that uses the conversion levers proven by Cal AI, Hallow, Blinkist, Fastic, and BetterMe:

1. **Manufactured perceived effort** (loading screen)
2. **Personalized plan summary** moved adjacent to the paywall
3. **Concrete 30-day journey timeline** (loss-aversion lever)
4. **Testimonial wall + rating count** at the moment of pricing decision
5. **Polished price screen** with personalized header line, MOST POPULAR badge, upgraded CTA copy, and reassurance microcopy

The current single screen is structurally good (annual default, side-by-side pricing, trial timeline, exit offer) but lacks pre-paywall narrative buildup and is missing social proof at the price-decision moment.

## Non-goals

- Outcome chart with numerical promises (off-brand for a spiritual app)
- Before/after emotional state cards (presumptuous about user's interior life)
- Countdown timers, scarcity banners, limited-time discounts
- Synthetic / fabricated testimonials — must use real users only
- Currency or per-region pricing experiments
- Student/family tier creation
- A/B test infrastructure (volume too low to power a test; ship straight)

## Background — current state

Current paywall (`lib/features/onboarding/screens/paywall_screen.dart`):
- Single screen, page index 24 of 25 (`onboardingLastPageIndex = 25`).
- Hero medallion (Ar-Rahman calligraphy, ~36% of viewport).
- Personalized aspiration headline using user's selected aspiration + daily commitment minutes.
- 3 benefit rows with check icons.
- Trial timeline strip (Today / Day 2 / Day 3) — only when StoreKit intro offer present.
- Side-by-side annual + weekly pricing, annual default with "SAVE 81%" badge and per-week breakdown.
- Pill CTA: "Start Free Trial" or "Subscribe" depending on intro-offer availability.
- Exit-offer bottom sheet on close X (offers weekly when annual selected).
- Close X delayed 3 seconds (App Review compliant).
- Restore / Terms / Privacy links at bottom.

Existing pre-paywall screens that this spec leverages:
- `personalized_plan_screen.dart` (page 17) — 4 tiles: starter Name, common emotions, reminder time, intention. Strong; will be reused inside the new paywall flow.
- `social_proof_screen.dart` (page 19) — 4.9★ pill, 2 testimonials, avatar stack, 2M+ users line. **Will be deleted**; its testimonial content moves into the new testimonial wall.
- `encouragement_screen.dart` (page 23) — "Something beautiful awaits you, {name}." Stays in place.

Strings live in `lib/core/constants/app_strings.dart`. Analytics events live in `lib/services/analytics_events.dart`.

## High-level flow change

**Before** (25 user-visible pages, paywall = page 24):
```
... → 17 Personalized Plan → 18 Value Prop → 19 Social Proof → 20 Save Progress
   → 21 Email → 22 Password → 23 Encouragement #2 → 24 Paywall
```

**After** (27 user-visible pages, paywall = page 26):
```
... pages 0–13 unchanged (through Encouragement #1) ...
14 Reminder Time    (unchanged)
15 Notifications    (unchanged)
16 Commitment Pact  (unchanged)
                    ← page 17 (Personalized Plan) is REMOVED from this position;
                       the screen file is reused inside the paywall flow at new page 23.
17 Value Prop       (was 18; content unchanged)
                    ← page 19 (Social Proof) is DELETED entirely. Its testimonial
                       copy migrates into the new Testimonial Wall (page 25).
18 Save Progress    (was 20)
19 Email            (was 21)
20 Password         (was 22)
21 Encouragement #2 (was 23)

— PAYWALL FLOW BEGINS (no progress bar) —
22 Building Your Plan        (NEW — ~3.5s loader with checklist auto-advance)
23 Personalized Plan         (RELOCATED from old page 17; lightly refreshed)
24 Your Journey              (NEW — Day 1 / Day 7 / Day 30 vertical timeline)
25 Testimonial Wall          (NEW — 3 vertical cards + rating + count)
26 Paywall — price screen    (existing, restructured + polished)
```

**Net page-count math:** start with 25 user-visible pages. Delete Social Proof (−1). Add Building Your Plan, Your Journey, Testimonial Wall (+3). Personalized Plan relocates but doesn't change count. **Result: 27 user-visible pages.**

`onboardingLastPageIndex` const moves from `25` to `27` (or whatever the equivalent index is — current code uses `25` for a 26-child PageView; preserve the same `lastPageIndex == childCount - 1` convention). PageView child count moves from `26` to `28`.

**Decisions locked:**
- Old `personalized_plan_screen` at page 17 is removed from that position; the screen file itself is reused on new page 23.
- Old `social_proof_screen` at page 19 is **deleted entirely**, with no relocation. Its testimonial copy migrates into the new Testimonial Wall on page 25. The 4.9★ rating pill + avatar-stack content also lives on the Testimonial Wall.
- Progress bar is hidden on pages 22–26 (paywall flow gets its own visual identity, not the survey progress bar).
- Optional light "Plan being built" microline on an existing earlier screen (e.g. Commitment Pact) is a "consider" item, not a hard requirement — final placement at implementation time.

## Screen designs

### Screen 22 — `BuildingYourPlanScreen` (NEW)

**Job:** Manufacture perceived effort.

**Layout** (full-bleed `AppColors.backgroundLight`):
- Soft animated star/khatam at top center — reuse `SakinaLoader.breathingStar`.
- Headline (DM Serif Display, 26pt, centered): `Personalizing your journey, {name}…`
- 4 checklist items, each tick at 700ms intervals (total ~3.5s):
  ```
  ✓ Reading your reflections
  ✓ Mapping you to Allah's Names
  ✓ Curating verses for your heart
  ✓ Setting your daily rhythm
  ```
- Each line lifecycle: faint placeholder dash → spinning indicator (300ms) → ✓ check (250ms).
- Final item lingers 700ms, then auto-advance to page 23.

**No back button. No tappable continue.** Auto-advance only.

**Why it works:** Anchoring + IKEA effect. Without manufactured effort, the personalized plan on the next screen feels instant and therefore valueless.

### Screen 23 — `PersonalizedPlanScreen` (REUSED)

**Source:** existing `lib/features/onboarding/screens/personalized_plan_screen.dart`. Light refresh:
- Add gold ribbon at top: `✨ Crafted for you` (Aref Ruqaa, gold).
- Header copy stays: `Your plan, {name}.` + `Everything you need, one tap away.`
- 4 tiles stay (starter Name, common emotions, daily check-in time, why you're here).
- CTA copy: `Continue` → `This sounds right →` (verbal commitment lever).
- Hide progress bar.

### Screen 24 — `YourJourneyScreen` (NEW)

**Job:** Concrete 30-day promise. Loss-aversion lever.

**Layout:**
- Headline (DM Serif Display, 26pt): `Where you'll be in 30 days, {name}.`
- Subtitle (DM Sans, 15pt, secondary): `Your habit, mapped out.`
- Vertical timeline with 3 milestone cards (left edge: gold dot connected by thin gold line):

  **Day 1 — Today**
  > 🌙 Your first reflection saved
  > 🤲 *{starterName}* unlocked in your collection

  **Day 7 — One week in**
  > 🔥 7-day streak burning bright
  > 📿 5 Names of Allah in your collection
  > 💚 7 reflections to look back on

  **Day 30 — One month**
  > ✨ A habit that holds — no missed days
  > 📿 12 Names collected
  > 📖 30 reflections in your journal
  > 🌟 You've felt closer to Allah every day

- Soft body line below timeline: `This is what {dailyMins} minutes a day builds.`
- CTA: `I want this →`

**Animation:** Cards fade in top-to-bottom, 200ms apart. Gold connector line "draws" downward as cards appear.

**Data inputs from onboarding state:**
- `state.starterNameId` → resolved transliteration via `PersonalizedPlanScreen.translitForCatalogId`
- `state.signUpName` → `{name}` interpolation (fallback: "friend")
- `state.dailyCommitmentMinutes` → `{dailyMins}` (fallback: 3)

**Why it works:** Every promise maps to a real app feature (streak, collection, journal). No fake numbers. Closes the loop with the starter Name shown on screen 23.

### Screen 25 — `TestimonialWallScreen` (NEW)

**Job:** Group membership at the price-decision moment.

**Layout:**
- Top pill: `⭐ 4.9 · 18,800 reviews` (gold-outlined). **If pre-launch with no real reviews:** drop the pill, lead with `Be one of the first.`
- Headline (DM Serif Display, 26pt): `You're joining a community.`
- Subtitle: `2 million+ Muslims building daily habits with Sakina.`
- 3 vertical testimonial cards (NOT a horizontal carousel — verticals convert higher per Adapty data; users skim faster):

  ```
  ★★★★★
  "Genuinely brought tears to my eyes. The way it
   matched my anxiety to Al-Wakil — I needed that."
  — Aisha · UK · 2-month streak

  ★★★★★
  "I open this before checking my phone in the morning.
   It's the only app I haven't deleted in 6 months."
  — Yusuf · USA · 47-day streak

  ★★★★★
  "Like having a daily reminder of why I'm here.
   Worth every penny."
  — Fatima · Canada · Premium subscriber
  ```

- Trust strip below cards: text-only "App Store · Google Play".
- CTA: `Join them →`

**Streak/badge line under each name** is the conversion lever vs. plain testimonials — implies retention and doubles as backdoor social proof for the streak feature.

**HARD CONSTRAINT:** Testimonials must be **real**. App Store guidelines + brand integrity require it. If real testimonials are not yet available, replace this screen with a "Be one of the first" community-build screen (no testimonial cards, just user count + invitation copy). Do not ship synthetic quotes.

### Screen 26 — Paywall price screen (RESTRUCTURED)

Changes against current `paywall_screen.dart`:

**Hero zone:**
- Shrink hero from 36% → 28% of viewport (`heroHeight = (size.height * 0.28).clamp(220.0, 280.0)`).
- Keep the Ar-Rahman medallion (it's beautiful and on-brand).
- Insert small gold all-caps line above the existing aspiration headline:
  ```
  YOU'RE 1 STEP AWAY, {name}
  ```
  (Aref Ruqaa-flavored or DM Serif Display 12pt with letter-spacing 1.5px, gold `AppColors.secondary`).
- Existing aspiration headline stays directly below: `Just 3 minutes a day to become more present.`

**Benefits zone:**
- 3 benefit rows stay.
- Replace plain check-circle icons with small thematic illustrations: crescent (Connect), flame (streak), folder (Revisit). Reuse existing icon assets where possible.
- Tighten vertical row padding from 5px → 4px.

**Trial timeline:**
- Stays as-is. Already correct. Already conditional on intro offer.

**Pricing zone:**
- Two cards stay (annual default + weekly).
- Add `MOST POPULAR` chip on annual card (top-right corner) alongside existing `SAVE 81%` (top-left). Both badges reading on a 2-card layout = confident, not desperate.
- Add a third microcopy line below the price cards: `7 days free, then $49.99/year. Cancel anytime.` (12pt secondary text, replaces some of the role of the existing "no-trial note").

**CTA:**
- Pill stays.
- Copy upgrade when trial available: `Start Free Trial` → `Try Sakina Free for 7 days →` (brand-name-in-CTA lifts conversion).
- No-trial fallback: `Subscribe` → `Start your subscription`.
- Add tiny line below CTA: `No payment due today.` (12pt gray).

**Bottom zone:**
- Restore Purchase / Terms / Privacy stays.
- Close-X 3s delay stays.

**Spacing fixes:**
- Reduce gap between hero tail fade and headline by `AppSpacing.xs`.
- Verify both pricing cards' footer lines sit on the same baseline (IntrinsicHeight check).
- Tighten benefit-row vertical padding (above).

## Engineering plan

### Files to create
- `lib/features/onboarding/screens/building_your_plan_screen.dart`
- `lib/features/onboarding/screens/your_journey_screen.dart`
- `lib/features/onboarding/screens/testimonial_wall_screen.dart`
- `lib/features/onboarding/widgets/journey_timeline.dart` — gold-line vertical timeline component
- `lib/features/onboarding/widgets/animated_checklist.dart` — for loader screen
- `lib/features/onboarding/widgets/paywall_personalized_header.dart` — small "You're 1 step away" line + chips

### Files to modify
- `lib/features/onboarding/screens/onboarding_screen.dart` — PageView children list reorders; child count 26 → 28
- `lib/features/onboarding/providers/onboarding_provider.dart` — `onboardingLastPageIndex` 25 → 27 (preserve `lastPageIndex == childCount − 1` convention); update `_skipToEncouragement` target index for Apple/Google sign-in path (Encouragement #2 is now page 21)
- `lib/features/onboarding/screens/paywall_screen.dart` — restructure (smaller hero, personalized header, illustrated benefits, MOST POPULAR badge, upgraded CTA copy, microcopy line)
- `lib/features/onboarding/screens/personalized_plan_screen.dart` — gold ribbon, CTA copy update; ensure it works without progress bar
- `lib/features/onboarding/screens/social_proof_screen.dart` — **DELETE** entirely. Migrate avatar-stack widget into the testimonial wall as needed. The 4.9★ rating pill and testimonial card content move to the testimonial wall.
- `lib/core/router.dart` — only if any direct routes reference removed screens
- `lib/core/constants/app_strings.dart` — new strings for loader, journey, testimonial wall, new paywall microcopy. Deprecate old `socialProofTestimonial1*` / `socialProofTestimonial2*` keys (or repoint into testimonial wall).
- `lib/services/analytics_events.dart` — add new events (see below)
- `docs/qa/ui-map.md` — update canonical page coords/order
- `docs/manual-test-plan.md` — update §3 onboarding test steps for new page count and order
- `CLAUDE.md` — update "Onboarding Flow" canonical page list

### Tests
- `test/features/onboarding/onboarding_auth_routing_test.dart` — verify Apple/Google `_skipToEncouragement` lands on Encouragement #2 (page 21 now) and from there flows through 22–26
- `test/features/onboarding/onboarding_page_count_test.dart` (new) — pin `onboardingLastPageIndex == 27` and PageView child count == 28
- `test/features/onboarding/building_your_plan_test.dart` — auto-advance after ~3.5s, no back button, all 4 checklist items appear in order
- `test/features/onboarding/your_journey_test.dart` — uses `starterNameId` → transliteration on Day 1 card; uses `dailyCommitmentMinutes` in body line
- `test/features/onboarding/testimonial_wall_test.dart` — renders 3 cards with author/streak; CTA copy correct
- `test/features/onboarding/paywall_screen_test.dart` (existing, augment) — new CTA copy, new microcopy line, MOST POPULAR badge present, smaller hero height

### Analytics events (additions)
```
paywall_flow_loader_shown          (page 22 enter)
paywall_flow_loader_advanced       (auto-advance after 3.5s)
paywall_flow_plan_shown            (page 23 enter)
paywall_flow_plan_continued        (CTA tap)
paywall_flow_journey_shown         (page 24 enter)
paywall_flow_journey_continued     (CTA tap)
paywall_flow_testimonial_shown     (page 25 enter)
paywall_flow_testimonial_continued (CTA tap)
paywall_flow_dropoff               (close X tapped on any flow page; property: page index)
```
Existing `paywall_*` events stay unchanged.

**KPI funnel (Mixpanel):**
`paywall_flow_loader_shown` → `paywall_cta_tapped` → `purchase_succeeded`. Compare against the same funnel pre-cutover via a date split.

### Rollout
Ship straight (no A/B flag). Watch funnel for ~3 days post-cutover. Roll back via git revert if conversion regresses >15%.

## Risks & mitigations

1. **Total flow length fatigue** (27 pages). Mitigate via fast page transitions (<250ms), aggressive 3.5s auto-advance on loader, prominent CTAs everywhere.
2. **Synthetic testimonials risk** — App Store rejection + brand trust damage. Mitigate: HARD constraint above. Replace screen with "Be one of the first" if no real testimonials.
3. **Removed `social_proof_screen` breaks references.** Mitigate: grep for `SocialProofScreen` before deletion; update tests and any direct route imports.
4. **Personalized plan moving from page 17 leaves a survey-y gap** in the middle of onboarding. Mitigate: add a light "plan being built" microline on a nearby existing screen so users don't feel the survey is purely extractive — implementation detail, not a new screen.
5. **App Store paywall rejection.** Mitigate: keep 3s close-X delay (already in place); trial-timeline only when intro offer present (already in place); no scarcity / countdown elements.
6. **Loader perceived as fake** if checklist ticks too fast. Mitigate: 700ms staggered intervals, real-feel spinner before each tick.
7. **Apple/Google sign-in skip target index drift.** Mitigate: update `_skipToEncouragement` target and pin via existing `onboarding_auth_routing_test.dart` extension.

## Success criteria

Primary: trial start rate (paywall-flow entry → CTA tap with intro offer accepted) increases vs. current single-screen baseline.
Secondary: total onboarding completion rate doesn't drop more than 5%.
Tertiary: paywall-close rate before CTA tap doesn't increase.

Measurement window: 7 days post-cutover via Mixpanel funnel.

## Open questions for implementation time

- Final placement of the "plan being built" microline (mitigation #4) — pick an existing screen at implementation time.
- Whether to keep `socialProof*` AppStrings keys for the trimmed page-14 version or rename them.
- Exact illustration assets for the 3 benefit rows on the paywall (crescent / flame / folder) — may use existing icons or commission small SVGs at implementation.
- Whether the rating count "18,800" is real today; if not, page 26 swaps to the "Be one of the first" variant and the rating pill is dropped.

## Out of scope

- A/B test infrastructure
- Outcome charts with numerical promises
- Before/after emotional cards
- Countdown / scarcity / urgency elements
- Per-region pricing experiments
- Student/family discount tiers
- Currency localization beyond RevenueCat defaults
