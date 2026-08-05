# Rating Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Insert a "Leave a rating" gate between `YourJourneyScreen` (page 24) and `PaywallScreen` (page 25) in the onboarding PageView. The gate uses Apple's `SKStoreReviewController` (and Play's in-app review on Android) to surface the OS rating prompt, then morphs its CTA to "I rated" so the user can continue. The goal is to lift App Store rating count + leverage commitment/consistency bias before the paywall. After insertion the PageView grows from 26 → 27 pages (indices 0..26), paywall moves to index 26, `onboardingLastPageIndex` becomes 26. The gate is gated by a compile-time kill-switch flag (`Env.ratingGateEnabled`) so it can be reversed without an App Review cycle.

**Architecture:** A new full-page widget `RatingGateScreen` lives in `lib/features/onboarding/screens/`. It owns its own `StatefulWidget` (not Riverpod-stateful) because its `_rated` flag is purely local UI state with no cross-screen dependency. It calls `InAppReview.instance.requestReview()` from the `in_app_review` package — the canonical wrapper around iOS `SKStoreReviewController.requestReview(in:)` and Android Play `ReviewManager`. Apple silently caps this at 3 prompts per 365 days per user; the gate is honest about that (after the user taps "Leave a rating" the button always flips to "I rated", regardless of whether iOS actually showed the sheet). App Store Guideline 5.6.1 is satisfied because (a) the gate does not block app functionality — onboarding is not core app functionality, and (b) the user can always tap "I rated" without rating.

**Copy stance:** Sakina is named after the Arabic word for *tranquility* (sakīna). The gate's voice must sit on the Hallow/Glorify/Calm spectrum — service, not urgency. Generic "rate us — it really helps!" SaaS copy contradicts the brand. The screen reads the user's `signUpName` (collected on page 1, the name screen) and `intention` (page 3) from `onboardingProvider` and frames the ask as one Muslim leaving a sign on the road for the next. This is the spiritual moat: personalized + service-framed is what generic competitors can't ship.

### Rollback / Kill Switch

The PageView inclusion of `RatingGateScreen` is conditional on `Env.ratingGateEnabled`. When the flag is `false` (or empty/missing), the gate is omitted from the children list and the paywall remains the next page after `YourJourneyScreen` exactly as before. Page-index constants and the `stepNames` map are still updated for the "gate on" path; when the flag is off, the PageView simply has 26 children again and `onboardingLastPageIndex` is computed from the children list rather than the constant (or — simpler — flip the constant back to 25 alongside the flag).

**To roll back without an App Review cycle:** ship a fresh build with `RATING_GATE_ENABLED=false` in `env.json`. There is no server-side flag because RevenueCat-style remote config isn't currently wired and the gate's behavior is purely client-side. Document the flag toggle in `TODO.md` so future engineers know the lever exists.

The flag also enables future cohort A/B testing (toggle for half of user_ids), but **v1 ships with the flag in a single hardcoded state** (true) — A/B comes later when there's traffic to power it.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, `in_app_review` package (new dependency), Riverpod for analytics provider lookup, existing onboarding PageView mechanism.

---

## Background — why this matters

From the research presented on 2026-05-13 (preceding conversation): rating count is the highest-leverage App Store ranking factor per RevenueCat's 2026 State of Subscription Apps report. Most top-grossing consumer apps surface the OS rating prompt at the moment of peak intent — typically inside the onboarding sequence after a personalized payoff screen and before any paid ask. The mechanic stacks three psychological levers: (1) commitment bias — rating commits the user to a public stance about liking the app, making the immediately-following paywall feel coherent with that stance; (2) reciprocity — the gate copy frames the ask as service to other Muslims, not a transactional favor; (3) effort justification — by the time the user has finished a 24-page onboarding + rated the app, the paywall feels like a natural next step rather than a surprise.

The mechanic is well-established but the public A/B numbers are thin — the rationale here is psychological soundness + competitive parity, not a specific lift figure to beat.

### Forward instrumentation (post-launch analysis)

Sakina is pre-launch with zero users — there is no baseline to measure against and no cohort to wait on. Instead of "validate before shipping," the strategy is ship + instrument forward so the first 100 users' data is captured cleanly. Once those users arrive, this funnel is queryable in Mixpanel:

1. `onboarding_step_viewed` where `step_index=24` (YourJourney) → `rating_gate_shown` — measures the YourJourney → gate transition (should be ~100% minus drop-off).
2. `rating_gate_shown` → `rating_gate_continue_tapped` — measures gate engagement (the "did they get past it" rate).
3. `rating_gate_continue_tapped` → `paywall_viewed` — measures gate-exit-to-paywall (should be ~100%).
4. `paywall_viewed` → `paywall_cta_tapped` — measures trial-start, the ultimate downstream signal.

The kill-switch flag (`Env.ratingGateEnabled`) is the lever for cohort A/B once there's enough traffic — half the user_ids get true, half false — but **v1 ships with a single hardcoded value (true)**. The flag is there so the gate is reversible, not so the launch is an experiment.

---

## File Structure

**Modify:**
- `pubspec.yaml` — add `in_app_review: ^2.0.10`.
- `lib/core/env.dart` — add `static const bool ratingGateEnabled = bool.fromEnvironment('RATING_GATE_ENABLED', defaultValue: true);` to the `Env` class. Defaults to `true` so a forgotten env entry doesn't accidentally disable the gate; flip to `false` in `env.json` to roll back.
- `env.json` (gitignored) and `env.example.json` (committed) — add `"RATING_GATE_ENABLED": "true"` so the contract is documented for fresh checkouts.
- `lib/features/onboarding/screens/onboarding_screen.dart` — conditionally insert `RatingGateScreen(onNext: _next, onBack: _back)` into the PageView children list between `YourJourneyScreen` (currently index 24) and `PaywallScreen` (currently index 25), gated on `Env.ratingGateEnabled`. Update the inline comment at `onboarding_screen.dart:266` from `// 25 — Paywall (was 24)` to `// 26 — Paywall (was 25)` (when the flag is on). Increment any hardcoded `26` (page count) references to `27`.
- `lib/features/onboarding/providers/onboarding_provider.dart` — bump `onboardingLastPageIndex` from `25` to `26`. Update the doc comments referencing "26 pages" → "27 pages". `onboardingPasswordPageIndex = 20` and `onboardingEncouragementPageIndex = 21` are UNCHANGED (the new screen sits AFTER them at index 25).
- `lib/services/analytics_events.dart` — (1) add `ratingGateShown`, `ratingGatePromptTriggered`, `ratingGateContinueTapped` constants, AND (2) update the `stepNames` Map<int, String> at lines 44-71: change the trailing entry `25: 'paywall'` to `25: 'rating_gate', 26: 'paywall'`. Also update the stale header comment at line 40 from "26 pages, 0-25" to "27 pages, 0-26".
- `CLAUDE.md` — update the "Onboarding Flow" canonical page order to insert "**24.5. Rating gate**" after "24. Paywall flow — Your Journey".

**Create:**
- `lib/features/onboarding/screens/rating_gate_screen.dart` — the new screen.
- `test/features/onboarding/rating_gate_screen_test.dart` — widget test for the two-state CTA + analytics emission.

**Do NOT modify:**
- `paywall_screen.dart` — its placement at "the next page after `YourJourneyScreen`" is preserved by virtue of being the next entry in the PageView list. No paywall logic changes here.
- `OnboardingContinueButton` — `RatingGateScreen` uses its own bespoke button because the CTA label morphs (`Leave a rating` ↔ `I rated`), which `OnboardingContinueButton` doesn't support.

---

## Task 1: Add the `in_app_review` dependency + kill-switch flag + analytics event constants

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/env.dart`
- Modify: `env.json`, `env.example.json`
- Modify: `lib/services/analytics_events.dart`

- [ ] **Step 1: Add dependency to `pubspec.yaml`**

Find the `dependencies:` block. Add (alphabetically positioned, after `image:` or similar):

```yaml
  in_app_review: ^2.0.10
```

- [ ] **Step 2: Install**

Run: `flutter pub get`
Expected: success, no resolution conflicts (the package is mature and pure-platform-channel, no transitive deps).

- [ ] **Step 2b: Add kill-switch flag** — `lib/core/env.dart`

Append to the `Env` class (after `googleIosClientId`):

```dart
  /// Compile-time kill switch for the onboarding rating gate. Defaults to
  /// `true` so a missing env entry doesn't silently disable the gate; flip
  /// to `"false"` in `env.json` and rebuild to roll back without an App
  /// Review cycle. See docs/superpowers/plans/2026-05-14-rating-gate.md
  /// (Rollback / Kill Switch).
  static const bool ratingGateEnabled =
      bool.fromEnvironment('RATING_GATE_ENABLED', defaultValue: true);
```

Then update `env.json` (gitignored) and `env.example.json`:

```json
  "RATING_GATE_ENABLED": "true"
```

(`bool.fromEnvironment` reads the string `"true"`/`"false"` — keep it as a string in the JSON.)

- [ ] **Step 3: Add analytics event constants** — `lib/services/analytics_events.dart`

Find the existing paywall events block (lines 15-19). Directly above it, insert:

```dart
  // Rating gate (page 25, inserted between YourJourney and Paywall — see
  // docs/superpowers/plans/2026-05-14-rating-gate.md).
  static const ratingGateShown = 'rating_gate_shown';
  static const ratingGatePromptTriggered = 'rating_gate_prompt_triggered';
  static const ratingGateContinueTapped = 'rating_gate_continue_tapped';
```

- [ ] **Step 4: Update `stepNames` map** — `lib/services/analytics_events.dart`

The `stepNames` Map<int, String> at lines 44-71 maps PageView indices to step names. It currently ends with `25: 'paywall'`. After insertion the rating gate is index 25 and paywall shifts to 26. Edit:

```dart
    // ... previous entries unchanged ...
    24: 'paywall_your_journey',
    25: 'rating_gate',
    26: 'paywall',
  };
```

Also update the stale header comment at line 40: `// 26 pages, 0-25` → `// 27 pages, 0-26`.

This map is what `onboarding_step_viewed` reads to populate the `step_name` analytics property — see finding 7 below (the duplication with `ratingGateShown` is intentional; `step_name=rating_gate` is now correct).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/env.dart env.example.json lib/services/analytics_events.dart
# env.json is gitignored — update it locally too but don't stage.
git commit -m "feat(onboarding): add in_app_review dep + rating-gate kill switch + analytics events

Part of the rating-gate insertion plan. Adds the in_app_review package
(wraps SKStoreReviewController on iOS, Play in-app review on Android),
introduces Env.ratingGateEnabled as a compile-time kill switch so the
gate can be reversed without an App Review cycle, reserves three
Mixpanel event names for the new screen, and rewires the stepNames
map so PageView index 25 → 'rating_gate' and 26 → 'paywall'."
```

---

## Task 2: Build `RatingGateScreen` with two-state CTA + tests

**Files:**
- Create: `lib/features/onboarding/screens/rating_gate_screen.dart`
- Create: `test/features/onboarding/rating_gate_screen_test.dart`

- [ ] **Step 1: Write the failing widget test** — `test/features/onboarding/rating_gate_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/rating_gate_screen.dart';
import 'package:sakina/services/analytics_provider.dart';

import '../../support/fake_analytics_service.dart'; // existing test helper

void main() {
  testWidgets('CTA starts as "Leave a rating", flips to "I rated" after tap, headline personalizes from signUpName',
      (tester) async {
    final fakeAnalytics = FakeAnalyticsService();
    var nextCalled = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // NOTE: the actual project provider is `analyticsProvider`, NOT
          // `analyticsServiceProvider` (see lib/services/analytics_provider.dart:9).
          analyticsProvider.overrideWithValue(fakeAnalytics),
          // Seed onboarding state so the screen can read signUpName / intention.
          onboardingProvider.overrideWith(
            (ref) => OnboardingNotifier()
              ..setSignUpName('Aisha')
              ..setIntention('Spiritual Growth'),
          ),
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () => nextCalled = true,
            onBack: () {},
            // Test seam: skip the real platform call.
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );

    // Headline should contain the user's name (personalized).
    expect(find.textContaining('Aisha'), findsOneWidget);

    expect(find.text('Leave a rating'), findsOneWidget);
    expect(find.text('I rated'), findsNothing);
    expect(nextCalled, isFalse);

    await tester.tap(find.text('Leave a rating'));
    await tester.pumpAndSettle();

    expect(find.text('Leave a rating'), findsNothing);
    expect(find.text('I rated'), findsOneWidget);
    expect(nextCalled, isFalse,
        reason: 'First tap triggers the OS prompt only, does not advance');

    await tester.tap(find.text('I rated'));
    await tester.pumpAndSettle();

    expect(nextCalled, isTrue);
  });

  testWidgets('headline falls back to "Friend" when signUpName is null',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(FakeAnalyticsService()),
          // No signUpName set.
        ],
        child: MaterialApp(
          home: RatingGateScreen(
            onNext: () {},
            onBack: () {},
            requestReviewOverride: () async => true,
          ),
        ),
      ),
    );
    expect(find.textContaining('Friend'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL** (file does not exist yet)

Run: `flutter test test/features/onboarding/rating_gate_screen_test.dart`

- [ ] **Step 3: Create `RatingGateScreen`** — `lib/features/onboarding/screens/rating_gate_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';

/// Persistence key for the "user has already passed the rating gate" flag.
/// On iOS, SKStoreReviewController presents as a system overlay; if the user
/// backgrounds the app mid-prompt the screen state can be torn down + rebuilt.
/// Persisting `_rated` ensures they don't re-enter the "Leave a rating" state.
const _kRatingGateCompletedPrefsKey = 'rating_gate_completed';

class RatingGateScreen extends ConsumerStatefulWidget {
  const RatingGateScreen({
    required this.onNext,
    required this.onBack,
    this.requestReviewOverride,
    super.key,
  });

  /// Matches the callback shape used by every other onboarding screen
  /// (see `onboarding_screen.dart:265`, e.g. `PaywallScreen(onNext: _next, onBack: _back)`).
  /// `OnboardingNotifier` does NOT expose `nextPage(controller:)` — only `setPage(int)` —
  /// so the parent's `_next` helper is what actually advances the PageView.
  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Test seam — replace in widget tests to avoid platform-channel calls.
  /// In production this is null and the real `InAppReview.instance.requestReview()`
  /// runs. The function returns true if the review prompt was *attempted*;
  /// Apple does not surface whether the user actually rated.
  final Future<bool> Function()? requestReviewOverride;

  @override
  ConsumerState<RatingGateScreen> createState() => _RatingGateScreenState();
}

class _RatingGateScreenState extends ConsumerState<RatingGateScreen> {
  bool _rated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Re-hydrate persisted "rated" state in case the screen was torn down
      // while the iOS review overlay was up (background → resume rebuild).
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kRatingGateCompletedPrefsKey) == true && mounted) {
        setState(() => _rated = true);
      }

      // NOTE: `analyticsProvider` is the canonical project provider name
      // (lib/services/analytics_provider.dart:9), NOT `analyticsServiceProvider`.
      ref.read(analyticsProvider).track(AnalyticsEvents.ratingGateShown);
    });
  }

  Future<void> _onPrimary() async {
    final analytics = ref.read(analyticsProvider);
    final available = widget.requestReviewOverride != null ||
        await InAppReview.instance.isAvailable();
    // Finding 6: track os_prompt_available so we can tell apart users who
    // got the system sheet vs. older iOS / Android-without-Play-Services
    // who silently fell through.
    analytics.track(
      AnalyticsEvents.ratingGatePromptTriggered,
      properties: {'os_prompt_available': available},
    );
    final fn = widget.requestReviewOverride ??
        () async {
          if (available) {
            await InAppReview.instance.requestReview();
            return true;
          }
          return false;
        };
    await fn();
    if (!mounted) return;
    setState(() => _rated = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRatingGateCompletedPrefsKey, true);
  }

  void _onContinue() {
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.ratingGateContinueTapped);
    widget.onNext();
  }

  /// Personalized headline using the name the user entered on page 1 of
  /// onboarding (`signUpName`). Falls back to "Friend" so the screen never
  /// breaks for users who somehow reach the gate without a name set
  /// (shouldn't happen — the name screen is mandatory — but defensive).
  String _buildHeadline() {
    final name = ref.read(onboardingProvider).signUpName?.trim();
    final greeting = (name == null || name.isEmpty) ? 'Friend' : name;
    return '$greeting, before you see your plan…';
  }

  /// Service-framed subhead. NOT a transactional "rate us → it helps the
  /// team" SaaS ask — Sakina (سَكِينَة, tranquility) is brand-positioned
  /// against urgency. The frame is one Muslim leaving a sign on the road
  /// for the next. The intention the user picked on page 3 is woven in
  /// when present (e.g. "spiritual growth", "a difficult time") so the
  /// ask anchors to their own stated reason for being here.
  String _buildSubhead() {
    final intention = ref.read(onboardingProvider).intention;
    if (intention != null && intention.isNotEmpty) {
      return 'You came to Sakina for ${intention.toLowerCase()}. Would you '
          'leave a sign on the road for the next Muslim searching for the '
          'same? It helps Sakina reach more hearts, in shā\u02BCa Allāh.';
    }
    return 'Would you leave a sign on the road for the next Muslim searching '
        "for what you've just found? It helps Sakina reach more hearts, "
        'in shā\u02BCa Allāh.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              Text(
                _buildHeadline(),
                style: AppTypography.headline.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _buildSubhead(),
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _rated ? _onContinue : _onPrimary,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _rated ? 'I rated' : 'Leave a rating',
                    style: AppTypography.button,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

Run: `flutter test test/features/onboarding/rating_gate_screen_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/rating_gate_screen.dart test/features/onboarding/rating_gate_screen_test.dart
git commit -m "feat(onboarding): add RatingGateScreen with two-state CTA

Screen displays 'Built by a small Muslim team' framing, primary CTA
flips from 'Leave a rating' → 'I rated' after the OS prompt. Test
seam (requestReviewOverride) keeps widget tests free of platform
channel calls."
```

---

## Task 3: Wire the screen into the onboarding PageView at index 25

**Files:**
- Modify: `lib/features/onboarding/screens/onboarding_screen.dart`
- Modify: `lib/features/onboarding/providers/onboarding_provider.dart`

- [ ] **Step 1: Bump page index constants** — `onboarding_provider.dart`

Replace:
```dart
const int onboardingLastPageIndex = 25;
```
with:
```dart
import '../../../core/env.dart';

/// Last index in [OnboardingScreen]'s PageView. When the rating gate is
/// enabled (default), PageView has 27 children (0..26) and paywall sits
/// at index 26. When the kill switch flips RATING_GATE_ENABLED=false,
/// the gate is elided, PageView has 26 children, and paywall is at 25
/// exactly as before. Computed from the flag so the two paths stay in sync.
/// Updated 2026-05-14 by rating-gate insertion.
final int onboardingLastPageIndex = Env.ratingGateEnabled ? 26 : 25;
```

Note: this becomes `final` (not `const`) because `Env.ratingGateEnabled` is a `static const bool` but the ternary on a top-level `const` requires both arms to be const-evaluable in a way Dart accepts — `final` sidesteps the issue with zero runtime cost (the value is fixed at first read). If a downstream `const` context already depends on `onboardingLastPageIndex`, search-and-fix those call sites (likely none — it's used as an int comparison).

The constants `onboardingPasswordPageIndex = 20` and `onboardingEncouragementPageIndex = 21` are UNCHANGED — the new screen sits AFTER them at index 25.

- [ ] **Step 2: Insert `RatingGateScreen` into the PageView (kill-switch gated)** — `onboarding_screen.dart`

`grep -n 'YourJourneyScreen\|PaywallScreen' lib/features/onboarding/screens/onboarding_screen.dart` to find the children list. The children list contains, in order, 26 screens ending with `YourJourneyScreen()` then `PaywallScreen(...)` (see `onboarding_screen.dart:265`). The PageView's `children:` block is a `List<Widget>` literal — convert it to a spread-friendly list and conditionally include the gate.

If the existing form is `children: [ ... ]`, change to:

```dart
            children: [
              // ... existing screens up through YourJourneyScreen() ...
              const YourJourneyScreen(),
              if (Env.ratingGateEnabled)
                // 25 — Rating gate (new, gated by RATING_GATE_ENABLED)
                RatingGateScreen(onNext: _next, onBack: _back),
              // 26 — Paywall (was 25 before rating gate; index now depends on flag)
              PaywallScreen(onNext: _next, onBack: _back),
            ],
```

Add imports at the top of the file:
```dart
import '../../../core/env.dart';
import 'rating_gate_screen.dart';
```

**When the flag is off:** the `if (Env.ratingGateEnabled)` collection-if elides the entry at compile time, the PageView has 26 children again, and paywall is at index 25 exactly as before. This is the rollback path.

**Important:** `OnboardingNotifier` does NOT expose a `nextPage(controller: ...)` method — only `setPage(int)`. Every other onboarding screen receives `onNext`/`onBack` callbacks from the parent's local `_next`/`_back` helpers (see how `PaywallScreen` is wired on the line immediately below). Copy that exact pattern; do NOT call `ref.read(onboardingProvider.notifier).nextPage(...)` because that method does not exist.

While you're in that file, update the inline comment at `onboarding_screen.dart:266`:
- Before: `// 25 — Paywall (was 24)`
- After:  `// 26 — Paywall (was 25 — see Env.ratingGateEnabled)`

- [ ] **Step 3: Update CLAUDE.md canonical page order**

In the "Onboarding Flow" section, between page 24 ("Paywall flow — Your Journey") and page 25 ("Paywall"), insert a new line. Renumber subsequent line `25. Paywall` to `26. Paywall`. Update the `onboardingLastPageIndex = 25` reference at the bottom of that section to `onboardingLastPageIndex = 26`. Update "PageView has 26 children" → "PageView has 27 children".

- [ ] **Step 4: Run the onboarding test suite**

Run: `flutter test test/features/onboarding/`
Expected: All pre-existing onboarding tests pass + the new `rating_gate_screen_test.dart` passes.

If `onboarding_auth_routing_test.dart` fails because it hardcoded the page index for password (20) or encouragement (21), it shouldn't — those indices are unchanged. `onboardingEncouragementPageIndex = 21` in `onboarding_provider.dart` is unchanged because the new screen is at index 25, AFTER page 21. The auth-routing test (`test/features/onboarding/onboarding_auth_routing_test.dart`) asserts that social-auth users skip from page 18 to page 21 — that jump is unaffected by an insertion at index 25. If the test asserts on `onboardingLastPageIndex`, update the assertion to `26`.

- [ ] **Step 4b: Verify `OnboardingProgressBar.totalSegments` default** — `lib/features/onboarding/widgets/onboarding_progress_bar.dart`

The widget at `onboarding_progress_bar.dart:8` defaults `totalSegments = 25`. The progress bar is HIDDEN on the paywall-flow pages 22-25 and on the rating gate (page 25), so the segment count should reflect *visible* segments, not PageView indices. Confirm by reading the call site in `onboarding_screen.dart` what value is passed. If the call site passes the literal `onboardingLastPageIndex`, segments will mis-count after the bump — in that case pass an explicit constant (e.g. the original 21) instead. Document the finding; do not auto-edit the default without verifying.

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/screens/onboarding_screen.dart lib/features/onboarding/providers/onboarding_provider.dart CLAUDE.md
git commit -m "feat(onboarding): wire RatingGateScreen between YourJourney and Paywall

Inserts the new gate at PageView index 25, shifting the paywall to 26.
onboardingLastPageIndex bumped 25 → 26. Password (20) and encouragement
(21) indices are unchanged because the new screen sits after them.
CLAUDE.md page order updated."
```

---

## Task 4: Manual verification on simulator

- [ ] **Step 1: Run on simulator + walk a fresh onboarding**

Run: `flutter run --dart-define-from-file=env.json`

On the simulator:
1. Delete the app if previously installed (to reset onboarding state).
2. Reinstall + launch.
3. Walk through onboarding to page 24 ("Your Journey").
4. Tap continue. Expect: RatingGateScreen appears with the headline "Built by a small Muslim team".
5. Tap "Leave a rating". Expect: the iOS SKStoreReview overlay appears (or silently does nothing if Apple's 3/year cap is hit — that's fine). The button morphs to "I rated".
6. Tap "I rated". Expect: paywall appears.

- [ ] **Step 2: Verify analytics in Mixpanel Live View**

In the Mixpanel project for Sakina, open Live View and watch for the three new events as you walk the flow:
- `rating_gate_shown` fires once on page 24 → 25 transition.
- `rating_gate_prompt_triggered` fires when "Leave a rating" is tapped.
- `rating_gate_continue_tapped` fires when "I rated" is tapped.

- [ ] **Step 3: No commit (verification-only)**

---

## NOT in scope

- **Adding a "skip" / "not now" option.** The whole psychological mechanic relies on the friction of presenting only one path forward. App Store policy is satisfied by the implicit skip path (don't rate, then tap "I rated" — the OS prompt is non-blocking).
- **Suppressing the gate on second-time openers / restored users.** This is the first onboarding flow only; users who reach this screen have just completed the personalization quiz. The gate fires once per fresh install, which is consistent with Apple's 3/year cap.
- **Negative-feedback intercept** (the "are you enjoying the app? 👍/👎 → if 👎, route to feedback form" pattern). Too clever for a first launch — but the strongest candidate for Phase 2 (see below). The reframe is *service-to-user*: users who aren't feeling it get a way to be heard instead of being asked to rate. Brand-coherent with Sakina's tranquility positioning.
- **Android-specific copy variation.** The same copy works for both platforms; `in_app_review` picks the right native API.
- **Backend persistence of "user rated".** We don't know if they actually rated — Apple doesn't tell us. Don't store a fake claim. (We DO persist a local-only `rating_gate_completed` SharedPreferences flag so the gate's CTA doesn't reset to "Leave a rating" if the screen rebuilds while iOS is showing the system overlay — but that flag is intentionally not synced to the server.)

### Phase 2 candidates (post-launch, after first-100-users data lands)

Ordered by expected impact:

1. **Negative-feedback intercept (service-to-user reframe).** Add a 👍/👎 pre-prompt: thumbs-up routes to the OS rating sheet, thumbs-down routes to an in-app feedback textarea that emails the team (or files a Supabase row in a `user_feedback` table). This (a) protects the App Store star average by routing unhappy users to a private channel and (b) genuinely serves users who aren't feeling it. Brand-coherent because it's not a dark pattern — it's tranquility in practice (you can be heard without performing positivity). Implement when v1 funnel data shows the gate is converting well *and* there's any signal of negative reviews leaking through. CEO review surfaced this as the highest-leverage Phase 2 add.
2. **Cohort A/B via `Env.ratingGateEnabled` flipped by user_id hash.** Requires enough traffic (≥1k users per arm to detect realistic effect sizes). Wire when traffic supports it.
3. **Different copy variants for different `intention` values.** The current single subhead has one branch (intention present vs. absent). With more data, test whether "spiritual growth" users vs. "difficult time" users respond to differently-framed asks.

---

## Known migration UX behavior (acknowledged, not fixed)

- **Restore-mid-onboarding lands on rating gate instead of paywall.** `onboarding_screen.dart:72` clamps `restoredPage` to `onboardingLastPageIndex`. Pre-update users whose persisted `currentPage` was `25` (paywall under the old numbering) will, after installing this update, find their restored page index `25` is now the rating gate, not the paywall. Acceptable — they have to do one extra tap. Not worth a migration shim.
- **Analytics double-fire is intentional.** The parent `_goToPage` fires `onboarding_step_viewed` with `step_index=25, step_name='rating_gate'` (from the updated `stepNames` map). The screen also fires `rating_gate_shown` in its `postFrameCallback`. We keep both: `onboarding_step_viewed` is the consistent funnel event used for cohort step-conversion analysis; `rating_gate_shown` is the screen-specific event paired with `rating_gate_prompt_triggered` and `rating_gate_continue_tapped` so the rating-gate sub-funnel can be analyzed in isolation. Document this in the Mixpanel lexicon when adding the new events.

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEARED-WITH-CONCERNS | Vanity-metric trap addressed via forward instrumentation (pre-launch, no baseline to measure against — instrumented the rating-gate → paywall funnel so first-100-users data is queryable). Copy reframed from generic SaaS "rate us" to personalized service-to-Muslims framing (reads `signUpName` + `intention` from `onboardingProvider`), preserving Sakina's tranquility brand positioning. Kill-switch flag (`Env.ratingGateEnabled`) added so the gate is reversible without an App Review cycle. "Cal-AI / Rise pattern" framing scrubbed from the plan body. Negative-feedback intercept surfaced as the top Phase 2 candidate. |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests | 1 | CLEAR-WITH-CHANGES (revised) | Fixed wrong provider name (`analyticsProvider`), swapped to `onNext`/`onBack` callback pattern, updated `stepNames` map for index shift, persisted `_rated` flag, added `os_prompt_available` analytics property, documented restore-mid-onboarding migration behavior. |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |
| DX Review | `/plan-devex-review` | Developer experience | 0 | — | — |

**UNRESOLVED:** 0
**VERDICT:** DRAFT — CEO + Eng cleared; awaiting Codex, Design, DX
