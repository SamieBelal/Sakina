import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/onboarding_screen.dart';

// T11/T12: abandonment telemetry threshold logic (Task A10, 2026-05-25).
// The `onboarding_abandoned_at_page` event must fire ONLY when the app
// was paused mid-onboarding for >24 hours. Tests target the extracted
// `shouldFireAbandonment` helper for deterministic coverage without
// having to drive AppLifecycleState through the framework.
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

    test('T12: pause exactly 24h returns false (must be strictly greater)',
        () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt = pausedAt.add(const Duration(hours: 24));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isFalse,
      );
    });

    test('pause 24h + 1 minute returns true (just over threshold)', () {
      final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
      final resumedAt =
          pausedAt.add(const Duration(hours: 24, minutes: 1));
      expect(
        shouldFireAbandonment(pausedAt: pausedAt, resumedAt: resumedAt),
        isTrue,
      );
    });
  });

  group('M2: abandonment paywall-suppression gate uses active flow index', () {
    // The gate that decides whether a 24h+ pause counts as "abandoned at page"
    // is `_pausedAtPage == _activeLastPageIndex`. A pause on the paywall (last
    // page) is suppressed (they reached the funnel end, just didn't buy); a
    // pause on any earlier page fires onboarding_abandoned_at_page. The bug:
    // the gate compared against the trimmed last index (19) unconditionally,
    // so a legacy user pausing on the real paywall (26) fired a FALSE
    // abandonment, and a legacy user pausing on page 19 (a mid-flow survey)
    // would NOT (correctly) be treated as paywall. This pins the per-flow fix.
    bool isPaywallPause(int pausedPage, {required bool trimmed}) =>
        pausedPage == activeOnboardingLastPageIndex(trimmed: trimmed);

    test('legacy: pause on legacy paywall (26) is suppressed', () {
      expect(isPaywallPause(onboardingLegacyLastPageIndex, trimmed: false),
          isTrue);
    });

    test('legacy: pause on trimmed paywall index (19) is NOT suppressed', () {
      // Regression: under the old hardcoded gate this WOULD have been treated
      // as the paywall and wrongly suppressed in legacy.
      expect(isPaywallPause(onboardingLastPageIndex, trimmed: false), isFalse);
    });

    test('trimmed: pause on trimmed paywall is suppressed', () {
      expect(
          isPaywallPause(onboardingLastPageIndex, trimmed: true), isTrue);
    });

    test('trimmed: pause on a mid-flow page is NOT suppressed', () {
      expect(isPaywallPause(5, trimmed: true), isFalse);
    });
  });
}
