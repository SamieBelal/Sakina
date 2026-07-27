import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';

// T11/T12: abandonment telemetry threshold logic (Task A10, 2026-05-25).
// The `onboarding_abandoned_at_page` event must fire ONLY when the app
// was paused mid-onboarding for >24 hours. Tests target the extracted
// `shouldFireAbandonment` helper for deterministic coverage without
// having to drive AppLifecycleState through the framework.
//
// Extended to three flows by One Ship W2-E1: the paywall-suppression gate now
// resolves against whichever of reel/trimmed/legacy is active.
void main() {
  group('shouldFireAbandonment threshold helper', () {
    test('T11: pause > 24h returns true', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 25));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });

    test('T11: pause = 7 days returns true', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(days: 7));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });

    test('T12: pause < 24h returns false (1h)', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 1));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isFalse,
      );
    });

    test('T12: pause exactly 24h returns false (must be strictly greater)', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 24));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isFalse,
      );
    });

    test('pause 24h + 1 minute returns true (just over threshold)', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 24, minutes: 1));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });
  });

  group('M2: abandonment paywall-suppression gate uses the ACTIVE flow index',
      () {
    // The gate that decides whether a 24h+ pause counts as "abandoned at page"
    // is `_pausedAtPage == _activeLastPageIndex`. A pause on the paywall (last
    // page) is suppressed — they reached the funnel end, they just didn't buy,
    // and `paywall_viewed` already carries that signal. A pause on any earlier
    // page fires `onboarding_abandoned_at_page`.
    //
    // The original bug compared against the trimmed last index (19)
    // unconditionally, so a legacy user pausing on their real paywall (26)
    // fired a FALSE abandonment. With the reel flow the same hazard runs the
    // other way: its paywall is at 12, which is a mid-flow survey page in both
    // kill-switch flows.
    bool isPaywallPause(int pausedPage, OnboardingFlowKind flow) =>
        pausedPage == activeOnboardingLastPageIndex(flow);

    test('each flow suppresses a pause on its OWN paywall', () {
      expect(
        isPaywallPause(onboardingReelLastPageIndex, OnboardingFlowKind.reel),
        isTrue,
      );
      expect(
        isPaywallPause(onboardingLastPageIndex, OnboardingFlowKind.trimmed),
        isTrue,
      );
      expect(
        isPaywallPause(
            onboardingLegacyLastPageIndex, OnboardingFlowKind.legacy),
        isTrue,
      );
    });

    test('no flow suppresses a pause on ANOTHER flow\'s paywall index', () {
      // Regression: under the old hardcoded gate these were wrongly suppressed.
      expect(
        isPaywallPause(onboardingLastPageIndex, OnboardingFlowKind.legacy),
        isFalse,
      );
      expect(
        isPaywallPause(onboardingReelLastPageIndex, OnboardingFlowKind.trimmed),
        isFalse,
        reason: 'trimmed page 12 is Social proof, a real mid-flow drop-off',
      );
      expect(
        isPaywallPause(onboardingLastPageIndex, OnboardingFlowKind.reel),
        isFalse,
        reason: 'the reel flow has no page 19 at all',
      );
    });

    test('a mid-flow pause is never suppressed in any flow', () {
      for (final flow in OnboardingFlowKind.values) {
        expect(isPaywallPause(5, flow), isFalse);
      }
    });
  });
}
