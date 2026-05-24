# Paywall Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the onboarding paywall at PageView index 26 (was 25 — see `2026-05-14-rating-gate.md`) to match the 6 structural decisions that the 2026 paywall research surfaced as the actual conversion drivers. Result: Weekly + Annual side-by-side (annual default-selected), short trial framing, animated CTA, honest billing copy, optional social proof (off by default until real reviews exist), no monthly. Ship the full 6-change bundle as one PR — this is v1 of the paywall and there is no prior production cohort to confound. v1 IS the baseline.

**Pre-launch reframe (2026-05-13):** Sakina has zero production users today. The earlier CEO-review concern that "shipping a paywall rebuild 9 days after the 2026-05-05 redesign destroys cohort attribution" is moot — there is no cohort yet. The split-into-pieces + wait-for-baseline recommendation collapses. Ship all six changes as one PR, gated behind env-driven feature flags for fast rollback if any element misbehaves in TestFlight.

**Brand stance — no urgency:** Sakina is named for the Arabic word for tranquility. The reference apps (Hallow, Glorify, Calm) deliberately reject SaaS-extractive paywall patterns — no countdown timers, no "limited time" badges, no scarcity copy. This plan inherits that stance. Animation is breathing-soft, not pulsing-aggressive. Copy is honest, not urgent. Annual is default-selected for brand coherence; weekly exists as a lower-commitment option but is NOT promoted via badge, anchoring, or "best for trying it out" framing.

**Architecture:** The paywall stays as a Flutter-rendered `PaywallScreen` (NOT RevenueCat Paywall UI), because we already have one and Flutter rendering gives us pixel control over the animated elements and the honest-billing footer. RevenueCat continues to own offerings, packages, and purchase mechanics — `PurchaseService.getOfferings()` returns the `current` offering's `availablePackages`, and the screen renders our own UI on top. (Verified: `presentPaywall` is not called anywhere in the codebase, so the RC dashboard paywall is genuinely unused on this surface.) The 6 changes are:

1. **Hard-paywall stance preserved** — no free tier; already true.
2. **Weekly + Annual side-by-side, no monthly** — the existing paywall already picks packages by `PackageType` (`_annualPackage`/`_weeklyPackage` at `paywall_screen.dart:92-100` + `_findSelectedPackage` at `309-316`), so monthly is already structurally unrenderable in the UI. The gap is at the service boundary: `PurchaseService.getOfferings()` returns the raw `availablePackages` list. We filter monthly *there* so other consumers (future paywalls, exit sheets, debug screens) also benefit.
3. **3-day trial on weekly, 7-day trial on annual** — RC-side config; the screen reads `package.storeProduct.introductoryPrice` and renders the right copy. No code changes needed if RC dashboard products are configured correctly; we just verify and surface accurately.
4. **Loading interstitial** — `GeneratingScreen` already exists at page 22. Duration is already 3500ms (`onboarding_provider.dart:368-385`). Add 3 rotating testimonials as overlay text on a `Timer.periodic`.
5. **Animated paywall elements** — `flutter_animate` (already imported in `paywall_screen.dart`, see `scaleXY` usage at line 1226) drives a breathing CTA (wrap the CTA's inner `Text` child, not the button container, so the `_purchasing` spinner state is unaffected) and a gold shimmer on the SAVE badge.
6. **Honest billing footer** — REPLACE the existing `_TrialTimelineStrip` (`paywall_screen.dart:1268-1306`) with the Blinkist-style explicit single-line timeline. The strip and the new footer are two contradictory visual representations of the same trial — keeping both creates a "Day 2 reminder email" line AND a "Day 7: $X unless cancelled" line on the same screen, which is incoherent. The new footer is the single source of truth.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, `purchases_flutter` (existing), `flutter_animate` (existing), Riverpod, RevenueCat dashboard (manual config — listed in Task 0).

> **Update (2026-05-24):** Task 4 (rotating testimonials on GeneratingScreen)
> and its `Env.paywallTestimonialsEnabled` flag were dropped during
> implementation. Real reviews don't exist yet; when App Store / TestFlight
> reviews come in, testimonials will be re-introduced behind a fresh flag at
> that point. References below to `paywallTestimonialsEnabled` and Task 4 are
> historical only. See `docs/superpowers/plans/2026-05-24-master-review-cleanup.md`
> finding 4 for context.

### Rollback / Kill Switch

Every visible piece of the rebuild is gated behind a compile-time feature flag in `lib/core/env.dart` so we can disable any individual element without an App Review cycle. The disable path is: edit `env.json`, rebuild, push to TestFlight (or App Store via expedited release if already public). No code revert needed for the on/off path.

| Flag | Default | What it gates |
|------|---------|---------------|
| `Env.paywallAnimationsEnabled` | `true` | Breathing CTA `Text` (Task 3) + gold shimmer on the SAVE badge (Task 3). |
| ~~`Env.paywallTestimonialsEnabled`~~ | ~~`false`~~ | ~~Rotating-testimonial overlay on `GeneratingScreen` (Task 4).~~ **DROPPED 2026-05-24 — feature not built. Flag will be re-added with a fresh name when real reviews exist.** |
| `Env.paywallHonestBillingEnabled` | `true` | The Blinkist-style honest-billing footer beneath the CTA (Task 2). |

Each Task wraps its UI in a conditional on the appropriate flag (see per-Task steps). If `paywallAnimationsEnabled` flips false, the CTA and badge render as plain widgets — no animation wrapper, no jitter risk. If `paywallTestimonialsEnabled` flips false, `GeneratingScreen` renders only the existing loader (the 3500ms duration is unchanged) (N/A — flag dropped, see 2026-05-24 update banner). If `paywallHonestBillingEnabled` flips false, the footer is omitted — the screen reverts to the pre-rebuild state below the CTA (no contradictory timeline because the strip itself has already been removed).

These flags exist for reversibility, not for A/B testing. They are intentionally compile-time `String.fromEnvironment` booleans, NOT a remote config service — we do not want a runtime config dependency for the paywall on day one.

---

## Background — why these 6 changes

From RevenueCat State of Subscription Apps 2026 + Adapty 2026 reports (presented in the 2026-05-13 conversation):
- Hard paywall median trial→paid is **10.7%**, vs **2.1%** freemium (5x lift).
- Weekly + 3-day trial is the highest-LTV configuration at $49.27/12mo.
- Weekly subscriptions now account for **55.6%** of subscription revenue, up from 43.3% two years ago.
- Animated paywall elements lift conversion **+12–18%** vs static (Adapty).
- Blinkist's "Honest Paywall" (explicit billing timeline) lifted conversion **+23%** and reduced refund complaints **-55%**.
- Cal AI ran **61 paywall experiments** to land their current structure (+31% trial→paid in 10 months).

This plan is not a guess — each of the 6 changes maps to a documented lift in a known study.

---

## File Structure

**Modify:**
- `lib/core/env.dart` — add `paywallAnimationsEnabled`, `paywallTestimonialsEnabled`, `paywallHonestBillingEnabled` compile-time flags (see Rollback / Kill Switch above).
- `env.json` + `env.example.json` — add the three new keys with their defaults (`true`, `false`, `true`).
- `lib/services/purchase_service.dart` — filter monthly packages out of `getOfferings()` at the service boundary so every consumer is defended (not just the paywall screen).
- `lib/features/onboarding/screens/paywall_screen.dart` — REMOVE `_TrialTimelineStrip` and its call site; add honest-billing footer below the CTA gated on `_planHasTrial && Env.paywallHonestBillingEnabled`; conditionally wrap the CTA's inner `Text` (NOT the button container) with breathing animation behind `Env.paywallAnimationsEnabled`; conditionally add gold shimmer to the SAVE badge behind `Env.paywallAnimationsEnabled`.
- ~~`lib/features/onboarding/screens/generating_screen.dart` — add rotating testimonials overlay behind `Env.paywallTestimonialsEnabled` (duration is already 3500ms, do NOT bump it). Default off in v1.~~ **DROPPED 2026-05-24.**
- `lib/core/constants/app_strings.dart` — add honest-billing strings + testimonial strings (testimonial placeholders prefixed `FAKE_DO_NOT_SHIP_` AND only consumed when the flag is true).

**Create:**
- `test/services/purchase_service_monthly_filter_test.dart` — pins that monthly packages are removed at the service boundary.
- `test/features/onboarding/paywall_honest_billing_test.dart` — pins the literal "Day 7: $X.XX/year unless cancelled" copy is present, gated on `_planHasTrial`, and contains the actual annual price from the package.
- ~~`test/features/onboarding/generating_screen_testimonial_rotation_test.dart` — pins that 3 testimonials rotate during the 3.5s window WHEN the flag is enabled. A second sub-test pins that with the flag off, no testimonial widget renders.~~ **DROPPED 2026-05-24.**
- `scripts/check_no_fake_strings.sh` — pre-commit / manual pre-merge grep that fails if any `FAKE_DO_NOT_SHIP_` prefix remains in `lib/`. Documented in Task 6.

**Do NOT modify:**
- `purchase_service.dart` entitlement + initialization logic (`isPremium`, `purchaseSubscription`, `restorePurchases`, `hadTrial`) — only `getOfferings()` changes.
- RevenueCat default Paywall in the RC dashboard — we render in Flutter; the dashboard paywall is unused on this surface (verified: no `presentPaywall` call sites exist).
- The `lapsed_trial_sheet.dart` / `warmup_exhausted_sheet.dart` / `daily_cap_sheet.dart` files — they reuse a separate sheet UI for in-app upsell, not the onboarding paywall.

---

## Task 0: RevenueCat dashboard configuration (manual, blocking)

This is a prerequisite for the code tasks. **The code changes in Tasks 1-5 assume the dashboard is configured per this task.** Do this before merging Task 1.

- [ ] **Step 1: Confirm products exist in App Store Connect**

In ASC, ensure these subscription products exist on the iOS app:
- `sakina_weekly` — $9.99/week, 3-day free trial as introductory offer.
- `sakina_annual` — $59.99/year, 7-day free trial as introductory offer.

If either is missing, create it. App Review will require screenshots of the in-app paywall referencing each, so do this first.

- [ ] **Step 2: Confirm matching products in Google Play Console**

Same SKU ids, same prices (Play converts USD automatically). Mirror trial durations.

- [ ] **Step 3: Wire up the RevenueCat `default` offering**

In the RC dashboard → Offerings → `default`:
- Annual package → `sakina_annual` (Apple) + `sakina_annual` (Google).
- Weekly package → `sakina_weekly` (Apple) + `sakina_weekly` (Google).
- **No monthly package.** If one exists, archive it. If you want monthly to remain as a fallback for the in-app "manage subscription" surface, keep it in a separate offering not named `default`.

- [ ] **Step 4: No commit (dashboard-only change)**

---

## Task 1: Filter out monthly packages at the service boundary

**Why this is mandatory:** the paywall screen already picks packages by `PackageType` (`_annualPackage`/`_weeklyPackage` getters at `paywall_screen.dart:92-100`, plus `_findSelectedPackage` at `309-316`), so a monthly package returned by RC dashboard would never get rendered as a chip on the current screen. BUT future consumers (a winback sheet, a debug paywall, the consumable surfaces, an A/B variant) might iterate the raw list. Defending at the service boundary protects every caller, not just `paywall_screen.dart`.

**Files:**
- Modify: `lib/services/purchase_service.dart` — filter the list returned from `getOfferings()`.
- Create: `test/services/purchase_service_monthly_filter_test.dart`.

- [ ] **Step 1: Write the failing test** — `test/services/purchase_service_monthly_filter_test.dart`

```dart
// Use mocktail to stub Purchases.getOfferings() to return an Offering with
// weekly + monthly + annual packages. Call PurchaseService.getOfferings()
// and assert the returned list contains weekly + annual only — no
// PackageType.monthly, twoMonth, threeMonth, sixMonth.
```

Match the pattern of existing `test/services/purchase_service_*_test.dart` files for the mock setup and `debugMarkInitialized` seam.

- [ ] **Step 2: Run test — expect FAIL**

Run: `flutter test test/services/purchase_service_monthly_filter_test.dart`

- [ ] **Step 3: Add the filter** — `purchase_service.dart:150`

Modify `getOfferings()`:

```dart
Future<List<Package>> getOfferings() async {
  if (!_initialized) return [];

  final offerings = await Purchases.getOfferings();
  final packages = offerings.current?.availablePackages ?? [];
  // Defense-in-depth: even if the RC dashboard's `default` offering is
  // misconfigured with a monthly package, the client never surfaces it.
  // Weekly + annual only — 2026 research shows monthly cannibalizes
  // annual LTV without lifting trial-start rate.
  return packages.where((p) {
    return p.packageType != PackageType.monthly &&
        p.packageType != PackageType.twoMonth &&
        p.packageType != PackageType.threeMonth &&
        p.packageType != PackageType.sixMonth;
  }).toList();
}
```

- [ ] **Step 4: Run test — expect PASS**

- [ ] **Step 5: Verify no paywall screen regression**

Run: `flutter test test/features/onboarding/paywall_screen_test.dart`

The paywall screen's existing tests should still pass — they don't fixture monthly packages, so the filter is a no-op for them.

- [ ] **Step 6: Commit**

```bash
git add lib/services/purchase_service.dart test/services/purchase_service_monthly_filter_test.dart
git commit -m "feat(purchases): filter monthly packages at service boundary

Even with the dashboard configured to exclude monthly from the default
offering, PurchaseService.getOfferings() now strips any monthly /
twoMonth / threeMonth / sixMonth package before returning. The paywall
screen already picks by PackageType so this is defense-in-depth for
future consumers (winback sheets, debug surfaces, A/B variants)."
```

---

## Task 2: Replace `_TrialTimelineStrip` with the honest-billing footer

**Files:**
- Modify: `lib/core/env.dart` — add `paywallAnimationsEnabled`, `paywallTestimonialsEnabled`, `paywallHonestBillingEnabled` (this is the first Task that consumes any of these; Task 3 and Task 4 reuse them).
- Modify: `env.json` + `env.example.json` — add `PAYWALL_ANIMATIONS_ENABLED=true`, `PAYWALL_TESTIMONIALS_ENABLED=false`, `PAYWALL_HONEST_BILLING_ENABLED=true`.
- Modify: `lib/core/constants/app_strings.dart` — add the templated strings.
- Modify: `lib/features/onboarding/screens/paywall_screen.dart` — DELETE `_TrialTimelineStrip` (and `_TimelineStep`), DELETE its call site (`paywall_screen.dart:589-601`), add the new footer below the CTA gated on `_planHasTrial && Env.paywallHonestBillingEnabled`.
- Create: `test/features/onboarding/paywall_honest_billing_test.dart`.

- [ ] **Step 0: Add the three feature flags to `Env`**

In `lib/core/env.dart`:

```dart
static const bool paywallAnimationsEnabled =
    bool.fromEnvironment('PAYWALL_ANIMATIONS_ENABLED', defaultValue: true);
static const bool paywallTestimonialsEnabled =
    bool.fromEnvironment('PAYWALL_TESTIMONIALS_ENABLED', defaultValue: false);
static const bool paywallHonestBillingEnabled =
    bool.fromEnvironment('PAYWALL_HONEST_BILLING_ENABLED', defaultValue: true);
```

In `env.json` and `env.example.json` add matching string entries (`bool.fromEnvironment` reads `"true"` / `"false"` strings):

```json
"PAYWALL_ANIMATIONS_ENABLED": "true",
"PAYWALL_TESTIMONIALS_ENABLED": "false",
"PAYWALL_HONEST_BILLING_ENABLED": "true"
```

These defaults match the Rollback / Kill Switch table. Verify with `dart run build_runner build --delete-conflicting-outputs` only if you've changed any `@freezed` model (you haven't; this is pure constants).

**Why we replace (not append):** the existing `_TrialTimelineStrip` shows three icon-headed mini-cards (Today / Day 2: reminder / Day 3: charged). Adding the new footer's "Day 7: $X unless cancelled" line on the same screen creates two contradictory timelines competing for the user's eye — and the strip's "Day 2: reminder email" subtly implies *we* send the email (we don't; we have no Day-2 email system — grep confirms). Removing the strip and using a single explicit footer line is the Blinkist pattern that produced the cited +23% lift.

- [ ] **Step 1: Add the templated strings** — `app_strings.dart`

```dart
  // Honest-billing footer copy (paywall rebuild, 2026-05-14).
  // Templates accept a {price} placeholder rendered from
  // package.storeProduct.priceString. The "Day N" reminder references
  // Apple's automatic trial-ending notification (24h before charge),
  // NOT a Sakina-side email — we don't send those. Reviewer-compliant
  // and factually accurate.
  static const paywallHonestBillingAnnual =
      'Today: full access. Day 6: Apple sends a trial-ending reminder. Day 7: {price}/year unless cancelled. Cancel anytime in Settings.';
  static const paywallHonestBillingWeekly =
      'Today: full access. Day 2: Apple sends a trial-ending reminder. Day 3: {price}/week unless cancelled. Cancel anytime in Settings.';
```

- [ ] **Step 2: Write the failing test** — `test/features/onboarding/paywall_honest_billing_test.dart`

```dart
// Render the paywall with a fake offering whose annual.priceString is "$59.99"
// AND introductoryPrice.price == 0 (so _planHasTrial == true).
// Assert find.textContaining('Day 7: \$59.99/year unless cancelled') finds one.
// Switch the selected plan to weekly. Assert find.textContaining('Day 3:').
//
// Negative case: render with introductoryPrice == null. Assert that the
// "Day N:" copy is NOT present — _planHasTrial gates the footer.
```

NOTE: the existing `paywall_screen_test.dart:266` already uses `tapVisible` scroll-into-view because the 800x600 default test viewport overflows. Pre-emptively scroll the new footer into view (`tester.dragUntilVisible` or set a larger viewport via `tester.view.physicalSize`) so the assertions land. Add a sub-step in this test for that scroll/resize setup.

- [ ] **Step 3: Run test — expect FAIL**

- [ ] **Step 4: Delete `_TrialTimelineStrip` and its call site in `paywall_screen.dart`**

- Delete `class _TrialTimelineStrip` (lines 1268-1306).
- Delete `class _TimelineStep` (lines 1308-1350).
- Delete the `if (hasTrial) ...[ _TrialTimelineStrip(...) ]` block at lines 589-601.
- The `AppStrings.paywallTimelineTodayHeading`, `paywallTimelineDay2Heading`, etc. constants become unused — leave them in `app_strings.dart` for now (cleaning unused strings is a separate task; removing them mid-paywall-rebuild risks breaking unrelated tests).

- [ ] **Step 5: Render the new footer in `paywall_screen.dart`**

Below the primary CTA + "No payment today" line, BEFORE the legal links row (around line 770), add:

```dart
if (_planHasTrial(_selectedPlan) && Env.paywallHonestBillingEnabled) ...[
  const SizedBox(height: AppSpacing.sm),
  Text(
    (_selectedPlan == _PlanType.annual
            ? AppStrings.paywallHonestBillingAnnual
            : AppStrings.paywallHonestBillingWeekly)
        .replaceAll('{price}', _activePackagePriceString()),
    style: AppTypography.bodySmall.copyWith(
      color: AppColors.textTertiaryLight,
      fontSize: 11.5,
      height: 1.35,
    ),
    textAlign: TextAlign.center,
  ),
],
```

The `Env.paywallHonestBillingEnabled` gate exists for rollback only — default is `true` (see Rollback / Kill Switch). If post-launch we see App Review pushback on the literal price quote (unlikely; this is the Blinkist pattern Apple has explicitly approved in other apps), we flip the flag without an App Review cycle.

Add a private helper:

```dart
String _activePackagePriceString() {
  if (_selectedPlan == _PlanType.annual) {
    return _annualPackage?.storeProduct.priceString ??
        AppStrings.paywallAnnualPrice;
  }
  return _weeklyPackage?.storeProduct.priceString ??
      AppStrings.paywallWeeklyPrice;
}
```

The footer is gated by `_planHasTrial(_selectedPlan)` (defined at `paywall_screen.dart:182-186` as `intro.price == 0`). In a storefront where the StoreKit product has no introductory price (rare but real — some EU/IN storefronts), the user will be charged immediately and the "Day 7: $X unless cancelled" footer would lie about a trial that doesn't exist. Gate it; in the no-trial case the existing `AppStrings.paywallNoTrialNote` already explains the immediate charge.

- [ ] **Step 6: Run test — expect PASS**

- [ ] **Step 7: Run `paywall_screen_test.dart` to confirm no viewport regression**

Run: `flutter test test/features/onboarding/paywall_screen_test.dart`. If the deleted timeline strip frees enough vertical space that an existing `tapVisible` test becomes a `tap`-without-scroll test, that's fine — tests should still pass.

- [ ] **Step 8: Commit**

```bash
git add lib/core/constants/app_strings.dart lib/features/onboarding/screens/paywall_screen.dart test/features/onboarding/paywall_honest_billing_test.dart
git commit -m "feat(paywall): replace timeline strip with honest billing footer

Deletes _TrialTimelineStrip (and _TimelineStep) and replaces them with a
single Blinkist-style explicit timeline line beneath the CTA:
'Today: full access. Day 6: Apple sends a trial-ending reminder.
Day 7: \$X/year unless cancelled. Cancel anytime in Settings.'

The strip and a separate footer were two contradictory timelines on one
screen. The old strip also implied Sakina sends a Day-2 reminder email
(we don't — that's Apple's automatic 24h pre-charge notification). New
copy is factually accurate and reviewer-compliant. Footer is gated on
_planHasTrial so storefronts without an intro offer don't get a false
trial promise.

Per Blinkist's public case study, single-line explicit billing copy
lifts conversion ~23% and cuts refund complaints ~55%."
```

---

## Task 3: Add the breathing CTA + gold shimmer on the SAVE badge

**Files:**
- Modify: `lib/features/onboarding/screens/paywall_screen.dart`.

**Important compatibility note:** the CTA at `paywall_screen.dart:725` swaps its child between `Text` and `CircularProgressIndicator` based on `_purchasing`. Wrapping the outer `ElevatedButton` (or its `SizedBox` parent) with `.animate().scale(...)` would keep pulsing during the spinner state, which looks jittery. Wrap the inner `Text` widget instead so the breathing motion stops cleanly when the spinner takes over the child slot.

Also: existing animate calls in this file use `scaleXY` (see `paywall_screen.dart:1226`), not the `Offset`-based `.scale()` overload. Match the house idiom.

- [ ] **Step 1: Wrap the CTA's inner `Text` with a repeating breathing animation**

In `paywall_screen.dart` around line 746, replace:

```dart
: Text(
    hasTrial ? AppStrings.paywallCtaTrial : AppStrings.paywallCtaSubscribeRevised,
    style: AppTypography.labelLarge.copyWith(...),
  ),
```

with a helper that wraps only when the animations flag is enabled:

```dart
: _maybeBreathe(
    Text(
      hasTrial ? AppStrings.paywallCtaTrial : AppStrings.paywallCtaSubscribeRevised,
      style: AppTypography.labelLarge.copyWith(...),
    ),
  ),
```

Add the private helper near the other animation helpers in the file:

```dart
Widget _maybeBreathe(Widget child) {
  if (!Env.paywallAnimationsEnabled) return child;
  return child
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scaleXY(
        begin: 1.0,
        end: 1.025,
        duration: 1400.ms,
        curve: Curves.easeInOut,
      );
}
```

Subtle — 2.5% scale, 1.4s cycle, breathing-soft to match the Sakina/tranquility brand. Anything bigger reads as gimmicky on a premium spiritual app. Because the wrap is on the inner `Text` (not the button container), the `_purchasing ? CircularProgressIndicator : Text(...)` branch in the parent `child:` slot means the animation simply doesn't exist while the spinner is showing — no jitter, no conflict. With the flag off, the helper is a pass-through — no animation wrapper rendered, no perf cost.

- [ ] **Step 2: Add gold shimmer to the existing SAVE badge**

The badge already exists — `_PricingCard` renders it at `paywall_screen.dart:1096-1128` via the `badge` prop, fed from `AppStrings.paywallAnnualBadge`. Do NOT change the badge text or the underlying savings math; the current anchor calculation (`_annualAnchorPrice` at lines 119-141) computes a 2x anchor producing roughly "SAVE 50%". Adjusting the anchor multiplier to manufacture "SAVE 88%" would require either (a) inflating the strikethrough price to ~8.3x the real price (deceptive under Apple guideline 3.1.1) or (b) changing the badge string while keeping the math wrong (internally inconsistent). Keep the existing SAVE % and just add the shimmer pass.

Conditionally wrap the badge `Container` (line 1101) — only when `Env.paywallAnimationsEnabled`:

```dart
final badgeContainer = Container(/* existing styling */);
return Env.paywallAnimationsEnabled
    ? badgeContainer
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 2400.ms,
          delay: 1200.ms,
          color: Colors.white.withValues(alpha: 0.55),
        )
    : badgeContainer;
```

- [ ] **Step 3: Manual visual check**

Run: `flutter run --dart-define-from-file=env.json`

The CTA `Text` should pulse gently when idle, freeze cleanly when you tap (replaced by spinner). The SAVE badge should have a slow diagonal shimmer pass roughly every 3.6s. If either feels distracting, halve the amplitude.

- [ ] **Step 4: No new test** — visual-only changes; widget tests would just assert the `Animate` wrapper is present, which adds noise without catching regressions.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/paywall_screen.dart
git commit -m "feat(paywall): add subtle CTA breathing + SAVE-badge shimmer

Per Adapty's 2026 report, animated paywall elements lift conversion
12-18% vs static. Kept tasteful — 2.5% scale on the CTA Text over
1.4s (wrapping the Text not the button so the spinner state is
unaffected), slow gold shimmer on the existing SAVE badge every
~3.6s. SAVE % math unchanged — keeping the 2x anchor that produces
a justifiable SAVE 50% rather than fabricating a higher claim."
```

---

## Task 4: Rotating testimonials on the GeneratingScreen interstitial (FLAG-GATED, DEFAULT OFF in v1)

> **DROPPED 2026-05-24** — feature not built. Skipped during implementation. The remainder of this Task is historical context only.

**Status in v1:** ship the code path but with `Env.paywallTestimonialsEnabled = false` in `env.json`. The loader runs the existing 3500ms without testimonials — exactly the current behavior. The rotation code exists, is unit-tested, and lights up the moment we flip the flag (after Phase 2 testimonial sourcing — see below).

**Why off by default:** Sakina is pre-launch. We have zero real App Store reviews and zero TestFlight feedback we can quote with permission. Shipping fabricated testimonials — even prefixed `FAKE_DO_NOT_SHIP_` as a tripwire — risks an accidental merge that violates Apple guideline 3.1.1 + FTC endorsement rules. The flag-off default removes that risk entirely. The CI grep gate in Task 6 is the second line of defense.

**Files:**
- Modify: `lib/features/onboarding/screens/generating_screen.dart` — rotation wrapped in `if (Env.paywallTestimonialsEnabled)`.
- Modify: `lib/core/constants/app_strings.dart` — add 3 placeholder testimonial strings prefixed `FAKE_DO_NOT_SHIP_`.
- Modify: `env.json` + `env.example.json` — add `PAYWALL_TESTIMONIALS_ENABLED=false`.
- Create: `test/features/onboarding/generating_screen_testimonial_rotation_test.dart` — covers BOTH flag states.

**Pre-flight:** the existing `GeneratingScreen` duration is already 3500ms (`onboarding_provider.dart:368-385` sets `totalDuration = Duration(milliseconds: 3500)`). Do NOT bump it. Three testimonials at ~1100ms each = 3300ms; the final 200ms covers the outro transition.

- [ ] **Step 1: Add 3 placeholder testimonials** — `app_strings.dart`

```dart
  // Testimonials rotated on GeneratingScreen during the ~3.5s pre-paywall
  // loader. These placeholders are FLAG-GATED OFF in v1 and MUST be
  // replaced with real reviews before paywallTestimonialsEnabled is
  // flipped to true. Fabricated reviews violate Apple guideline 3.1.1
  // and FTC endorsement rules. The `FAKE_DO_NOT_SHIP_` prefix is
  // grep-gated by scripts/check_no_fake_strings.sh (Task 6).
  static const generatingTestimonials = <String>[
    'FAKE_DO_NOT_SHIP_"This is the first app that gets what I needed as a Muslim." — Layla, NJ',
    'FAKE_DO_NOT_SHIP_"I open it before fajr. It centers me." — Yusuf, London',
    'FAKE_DO_NOT_SHIP_"Finally something for my heart." — Aaliyah, Toronto',
  ];
```

- [ ] **Step 2: Add the testimonial flag default OFF**

In `env.json` and `env.example.json`, add:

```json
"PAYWALL_TESTIMONIALS_ENABLED": "false"
```

In `lib/core/env.dart`, add:

```dart
static const bool paywallTestimonialsEnabled =
    bool.fromEnvironment('PAYWALL_TESTIMONIALS_ENABLED', defaultValue: false);
```

(Companion entries for `PAYWALL_ANIMATIONS_ENABLED=true` and `PAYWALL_HONEST_BILLING_ENABLED=true` should be added in the same Env.dart edit if they aren't already there from Tasks 2/3.)

- [ ] **Step 3: Wire up rotation in `generating_screen.dart` — flag-gated**

Add a `_testimonialIndex` state field. In `initState`, only when `Env.paywallTestimonialsEnabled` is true, kick off a `Timer.periodic(Duration(milliseconds: 1100), ...)` that increments the index mod 3 and calls `setState`. Cancel the timer in `dispose`. Render the current testimonial below the existing loader spinner with a 240ms fade-in animation on index change (use `AnimatedSwitcher` keyed on the index). When the flag is off, render only the existing loader — no testimonial widget at all (not even an empty `SizedBox`, to avoid layout shifts when we later flip the flag).

Do NOT wire a `paywallSocialProofViewed` analytics event — `onboarding_step_viewed` already covers this surface and a per-rotation event would be noisy.

- [ ] **Step 4: Write the rotation test (covers BOTH flag states)**

The test runner does not pick up `env.json`; tests run with all `String.fromEnvironment` defaults unless overridden via `--dart-define`. So with `paywallTestimonialsEnabled` defaulting to `false`, the unit test for the rotation needs a seam.

Two approaches; pick one:
1. **Recommended:** add a `@visibleForTesting` constructor parameter `bool testimonialsEnabledOverride` to `GeneratingScreen` that the widget falls back to when set. Test passes `true` to exercise rotation; passes `false` (or omits) to exercise the loader-only path.
2. Alternative: a top-level `debugPaywallTestimonialsEnabled` mutable bool, set in `setUp`. Less clean but matches the `debugRewardsClock` pattern already in the codebase.

```dart
// Flag ON: pumpWidget(GeneratingScreen(testimonialsEnabledOverride: true)).
// expect find.textContaining('Layla') findsOneWidget.
// await tester.pump(Duration(milliseconds: 1100));
// expect find.textContaining('Yusuf') findsOneWidget;
// await tester.pump(Duration(milliseconds: 1100));
// expect find.textContaining('Aaliyah') findsOneWidget;

// Flag OFF: pumpWidget(GeneratingScreen(testimonialsEnabledOverride: false)).
// expect find.textContaining('Layla') findsNothing;
// expect find.textContaining('FAKE_DO_NOT_SHIP_') findsNothing;
```

Use stable substrings (a person's first name from the placeholder OR a real-review fragment) — never assert on the `FAKE_DO_NOT_SHIP_` prefix because (a) the strings are expected to change and (b) the CI grep would fail before the assertion ever ran.

- [ ] **Step 5: Run test + commit**

```bash
git add lib/features/onboarding/screens/generating_screen.dart lib/core/constants/app_strings.dart lib/core/env.dart env.json env.example.json test/features/onboarding/generating_screen_testimonial_rotation_test.dart
git commit -m "feat(onboarding): testimonial rotation behind paywallTestimonialsEnabled flag

GeneratingScreen now supports rotating 3 testimonials during its existing
3.5s window (duration unchanged at 3500ms in onboarding_provider). The
code path is gated behind Env.paywallTestimonialsEnabled, which defaults
to false in v1 because Sakina is pre-launch and has no real reviews to
quote. Placeholder strings are prefixed FAKE_DO_NOT_SHIP_ as a tripwire
and gated by scripts/check_no_fake_strings.sh (Task 6).

Per RevenueCat 2026 research, loading interstitials with rotating social
proof lift conversion in established apps. We light this up in Phase 2
after sourcing real App Store / TestFlight reviews with written quote
permission."
```

**Phase 2 follow-up plan (testimonial sourcing):**
Once Sakina has ~50+ TestFlight or live App Store users:
1. Filter 5-star App Store reviews for short, quotable lines.
2. Reach out to TestFlight beta participants for explicit written quote permission.
3. Replace `FAKE_DO_NOT_SHIP_` strings with real attributed quotes (first name + city/region).
4. Run `scripts/check_no_fake_strings.sh` locally to confirm no markers remain.
5. Flip `PAYWALL_TESTIMONIALS_ENABLED=true` in `env.json` and rebuild.

This is a known leverage point but a meaningful chunk of work and is intentionally deferred out of v1.

---

## Task 5: Full-suite verification + manual sanity check

- [ ] **Step 1: Run the full Flutter test suite**

Run: `flutter test`
Expected: pass. Pay particular attention to `test/features/onboarding/` and `test/services/purchase_service_*`.

- [ ] **Step 2: `flutter analyze`**

- [ ] **Step 3: Manual walk-through on physical device**

RevenueCat purchases do NOT work on iOS simulator — test on a real device per `CLAUDE.md`. Walk fresh onboarding, confirm:
- GeneratingScreen rotates 3 testimonials (real, not `FAKE_DO_NOT_SHIP_`).
- Paywall shows only Annual + Weekly, no monthly.
- Annual card has the existing SAVE badge with a slow gold shimmer.
- Primary CTA `Text` pulses subtly (and stops cleanly during the spinner state after tap).
- Honest-billing footer shows real price and reads "Day 7: $X/year unless cancelled" (annual) or "Day 3: $X/week unless cancelled" (weekly).
- The old icon-headed timeline strip is gone.
- "Start 7-day free trial" tap initiates real StoreKit sandbox purchase.

- [ ] **Step 4: No commit (verification-only)**

---

## Task 6: CI / pre-merge grep gate against `FAKE_DO_NOT_SHIP_` placeholders

**Why:** the testimonial placeholders are prefixed `FAKE_DO_NOT_SHIP_` as a tripwire. The catastrophic failure mode is an accidental flag-flip + merge that ships those strings as real testimonials — that's an Apple guideline 3.1.1 + FTC endorsement-rules violation. A 5-minute grep gate prevents it permanently.

**Files:**
- Create: `scripts/check_no_fake_strings.sh` — a tiny shell script that exits non-zero if any `FAKE_DO_NOT_SHIP_` prefix is found in `lib/`.
- Document the manual pre-merge invocation in the project root `CLAUDE.md` Commands section. (CI workflow integration is deferred — see note below.)

**Pre-flight finding:** `.github/workflows/` does NOT exist in this repo today (verified by glob). There is no GitHub Actions CI to wire into. The gate is therefore a manual pre-merge script + a `CLAUDE.md` reminder. When/if we add GH Actions in the future, add an `- run: ./scripts/check_no_fake_strings.sh` step before the existing `flutter test` step.

- [ ] **Step 1: Create the gate script** — `scripts/check_no_fake_strings.sh`

```bash
#!/usr/bin/env bash
# Fails the build if any FAKE_DO_NOT_SHIP_ placeholder leaks into lib/.
# These markers exist as tripwires for content that must be replaced
# with real, attributable copy before shipping (testimonials, etc).
# Apple guideline 3.1.1 + FTC endorsement rules.
set -euo pipefail

if grep -rE 'FAKE_DO_NOT_SHIP_' lib/ ; then
  echo ""
  echo "ERROR: FAKE_DO_NOT_SHIP_ placeholders found in lib/."
  echo "Replace with real attributable content before merging."
  echo "See docs/superpowers/plans/2026-05-14-paywall-rebuild.md Task 4."
  exit 1
fi

echo "OK: no FAKE_DO_NOT_SHIP_ placeholders in lib/."
```

`chmod +x scripts/check_no_fake_strings.sh` after creating.

- [ ] **Step 2: Verify the gate**

Run: `./scripts/check_no_fake_strings.sh`

Expected: FAILS (because Task 4 just added the placeholders to `app_strings.dart`). This is the correct state for v1 — the placeholders are intentionally present and the flag is off. The gate's purpose is to fire the day someone flips the flag without replacing the strings.

To make the gate green in v1, the testimonials would need to be moved OUT of `lib/` to a `Phase2` follow-up file, or replaced with real strings. We deliberately leave them in `lib/` (with flag off) so the gate fires loudly the moment someone tries to enable testimonials without the sourcing work.

**Practical convention:** the gate is wired as a release-readiness check, not a per-commit pre-merge check. Run `./scripts/check_no_fake_strings.sh` before any `flutter build ios --release` or TestFlight push. Add this to the project root `CLAUDE.md` Commands section so it's part of every release checklist.

- [ ] **Step 3: Add reminder to `CLAUDE.md`**

Append to the Commands section:

```bash
# Pre-release: fail if any FAKE_DO_NOT_SHIP_ placeholders remain in lib/
./scripts/check_no_fake_strings.sh
```

- [ ] **Step 4: Commit**

```bash
git add scripts/check_no_fake_strings.sh CLAUDE.md
git commit -m "feat(ci): add FAKE_DO_NOT_SHIP_ release gate script

Tiny shell script that fails if any FAKE_DO_NOT_SHIP_ placeholder
remains in lib/. Tripwire against accidentally shipping fabricated
testimonials when Env.paywallTestimonialsEnabled gets flipped on
without replacing the placeholder strings. Apple 3.1.1 + FTC
endorsement rules.

No GH Actions workflow exists in this repo yet — this is a manual
pre-release check documented in CLAUDE.md. When CI is added, wire
the script in before flutter test."
```

---

## Instrumentation — v1 is the baseline

There is no prior production cohort to confound. The existing analytics events fire on this surface today:

- `paywall_viewed` (when `PaywallScreen.initState` runs)
- `paywall_cta_tapped` (on primary button press)
- `paywall_plan_selected` (on chip toggle)
- `paywall_closed` (on X dismiss)

These populate naturally from the first 100 users. **No pre-baseline measurement is required, and no "wait 14 days for cohort to mature" gating applies — Sakina is pre-launch.** v1 of the rebuilt paywall IS the baseline. Future paywall iterations will compare against this v1 cohort once it has matured.

If we observe v1 trial-start conversion below ~25% after the first ~200 paywall views, the leverage points (in priority order) are:
1. Replace placeholder testimonials with real ones and flip `PAYWALL_TESTIMONIALS_ENABLED=true`.
2. Build the Discovery-Name personalized hero (see Phase 2 candidates below).
3. Iterate on CTA copy / pricing presentation.

We do NOT pre-commit to any of these — let v1 data tell us.

---

## Phase 2 candidates (deferred, NOT in v1)

These are known leverage points captured here so they're not lost. Each becomes a separate plan when v1 data warrants it.

- **Discovery-Name personalized hero.** Highest-leverage differentiation surfaced in CEO review. The onboarding flow's first-check-in screen produces a `resonant_name_id` (column on `user_profiles`, also written as `starter_name_id` in some recent migrations — verify the live schema before referencing). Read it on paywall render and frame the hero as "{Name of Allah}, continue your relationship with Allah's Names for 7 days free." or similar. This is what Hallow/Glorify wish they had — a personalized scriptural hook unique to each user. A meaningful chunk of work (schema read path, fallback when the column is null, Arabic + transliteration rendering, copy tuning) — deferred to its own plan.
- **Testimonial sourcing (Phase 2 plan candidate).** Filter App Store reviews, request quote permissions from TestFlight beta users, replace `FAKE_DO_NOT_SHIP_` strings, flip `PAYWALL_TESTIMONIALS_ENABLED=true`. See Task 4 follow-up.
- **A/B testing individual elements.** Skip in v1 (Cal AI ran 61 experiments to learn the same lessons we just imported wholesale). Revisit once we have a meaningful cohort.
- **Localizing the honest-billing copy.** English-only for now; Sakina has not yet shipped localized strings, per CLAUDE.md.

---

## NOT in scope

- **3-plan paywall** (monthly + annual + weekly). Explicitly excluded per research; 3 choices paralyze.
- **Switching to RevenueCat Paywall UI.** Our Flutter render gives pixel control; the RC paywall editor is for teams without engineering bandwidth.
- **Weekly-pricing badge / anchoring.** Brand stance — Sakina = tranquility. Weekly is available for users who want a lower-commitment trial entry but is NOT promoted, badged, or anchored. Annual is default-selected for brand coherence with Hallow / Glorify / Calm (none of whom run urgency-driven weekly framing).
- **24h post-dismiss discount flow.** Separate plan: `2026-05-14-winback-discount.md`. NOTE: that plan references a `paywall_dismiss_count` SharedPrefs key that does NOT exist in the codebase today (verified by grep). It is introduced by the refer-unlock plan (`2026-05-14-refer-unlock.md`, Task 5), so refer-unlock is a soft prerequisite for winback if neither has shipped yet.
- **Referral fallback.** Separate plan: `2026-05-14-refer-unlock.md`.
- **Adjusting the SAVE % math.** Keep the existing 2x anchor (~SAVE 50%); inflating the anchor multiplier to manufacture a bigger headline number is deceptive under Apple guideline 3.1.1.
- **Adding a `paywallSocialProofViewed` analytics event.** Existing `onboarding_step_viewed` is sufficient; per-rotation events would be noisy.
- **Pre-baseline measurement gating ("wait 14 days for the 2026-05-05 cohort to mature").** Moot — pre-launch reframe (see top of plan). v1 IS the baseline.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEARED (pre-launch reframe) | Split-into-pieces concern resolved by pre-launch context (Sakina has zero production users — no cohort to confound). Ship the full 6-change bundle as one PR. Three env-driven feature flags added for rollback (`paywallAnimationsEnabled`, `paywallTestimonialsEnabled`, `paywallHonestBillingEnabled`). Testimonials default OFF in v1 because no real reviews exist yet — placeholders prefixed `FAKE_DO_NOT_SHIP_` and grep-gated by `scripts/check_no_fake_strings.sh` (Task 6). Brand stance documented: no urgency, annual default-selected, weekly unbadged. Discovery-Name personalized hero deferred to Phase 2 (highest-leverage diff but meaningful work). Forward instrumentation only — no pre-baseline gating. |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | BLOCK → CLEAR-WITH-CHANGES (revised) | Task 1 retargeted to `purchase_service.getOfferings()`; `_TrialTimelineStrip` replaced (not appended); Apple-reminder framing replaces invented "Sakina email" copy; footer gated on `_planHasTrial`; CTA breathing wraps inner `Text` not button; `scaleXY` idiom used; placeholder testimonials prefixed `FAKE_DO_NOT_SHIP_`; SAVE% math preserved; `paywallSocialProofViewed` dropped; 3500ms duration bump removed (already correct). |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** DRAFT — Eng Review cleared with revisions; CEO Review cleared with pre-launch reframe; awaiting Codex / Design / DX reviews
