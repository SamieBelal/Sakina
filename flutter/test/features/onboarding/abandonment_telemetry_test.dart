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
    // These drive `shouldEmitAbandonment` — the SAME function
    // `didChangeAppLifecycleState` calls — rather than a re-declared copy of
    // the gate, which could pass while the shipping predicate drifted.
    //
    // A pause on the paywall (last page) is suppressed: they reached the funnel
    // end, they just didn't buy, and `paywall_viewed` already carries that
    // signal. A pause on any earlier page fires `onboarding_abandoned_at_page`.
    //
    // The original bug compared against the trimmed last index (19)
    // unconditionally, so a legacy user pausing on their real paywall (26)
    // fired a FALSE abandonment. With the reel flow the same hazard runs the
    // other way: its paywall is at 12, which is a mid-flow survey page in both
    // kill-switch flows.
    final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);
    final resumedAt = pausedAt.add(const Duration(hours: 30));

    bool emits(int? pausedPage, OnboardingFlowKind flow,
            {bool completing = false}) =>
        shouldEmitAbandonment(
          pausedPage: pausedPage,
          pausedAt: pausedAt,
          resumedAt: resumedAt,
          flow: flow,
          completing: completing,
        );

    test('each flow suppresses a pause on its OWN paywall', () {
      expect(emits(onboardingReelLastPageIndex, OnboardingFlowKind.reel),
          isFalse);
      expect(
          emits(onboardingLastPageIndex, OnboardingFlowKind.trimmed), isFalse);
      expect(emits(onboardingLegacyLastPageIndex, OnboardingFlowKind.legacy),
          isFalse);
    });

    test('no flow suppresses a pause on ANOTHER flow\'s paywall index', () {
      // Regression: under the old hardcoded gate these were wrongly suppressed.
      expect(emits(onboardingLastPageIndex, OnboardingFlowKind.legacy), isTrue);
      expect(
        emits(onboardingReelLastPageIndex, OnboardingFlowKind.trimmed),
        isTrue,
        reason: 'trimmed page 12 is Social proof, a real mid-flow drop-off',
      );
      expect(
        emits(onboardingLastPageIndex, OnboardingFlowKind.reel),
        isTrue,
        reason: 'the reel flow has no page 19 at all',
      );
    });

    test('a mid-flow pause fires in every flow', () {
      for (final flow in OnboardingFlowKind.values) {
        expect(emits(5, flow), isTrue);
      }
    });

    test('the active last index still comes from the flow map', () {
      // The screen's `_next` bound reads the same helper; keeping the
      // assertion means a change to one is visible to the other.
      expect(activeOnboardingLastPageIndex(OnboardingFlowKind.reel),
          onboardingReelLastPageIndex);
      expect(activeOnboardingLastPageIndex(OnboardingFlowKind.trimmed),
          onboardingLastPageIndex);
      expect(activeOnboardingLastPageIndex(OnboardingFlowKind.legacy),
          onboardingLegacyLastPageIndex);
    });
  });

  group('the rest of the shipping predicate', () {
    final pausedAt = DateTime(2026, 5, 1, 12, 0, 0);

    test('a pause under the threshold never fires, paywall or not', () {
      expect(
        shouldEmitAbandonment(
          pausedPage: 5,
          pausedAt: pausedAt,
          resumedAt: pausedAt.add(const Duration(hours: 3)),
          flow: OnboardingFlowKind.reel,
          completing: false,
        ),
        isFalse,
      );
    });

    test('completion in flight suppresses it', () {
      // `_completing` flips on as soon as the paywall's onComplete fires; a
      // backgrounded app during that await chain would otherwise log both
      // "completed" and "abandoned".
      expect(
        shouldEmitAbandonment(
          pausedPage: 5,
          pausedAt: pausedAt,
          resumedAt: pausedAt.add(const Duration(days: 2)),
          flow: OnboardingFlowKind.reel,
          completing: true,
        ),
        isFalse,
      );
    });

    test('nothing recorded at pause time means nothing to report', () {
      expect(
        shouldEmitAbandonment(
          pausedPage: null,
          pausedAt: pausedAt,
          resumedAt: pausedAt.add(const Duration(days: 2)),
          flow: OnboardingFlowKind.reel,
          completing: false,
        ),
        isFalse,
      );
      expect(
        shouldEmitAbandonment(
          pausedPage: 5,
          pausedAt: null,
          resumedAt: pausedAt.add(const Duration(days: 2)),
          flow: OnboardingFlowKind.reel,
          completing: false,
        ),
        isFalse,
      );
    });
  });
}
