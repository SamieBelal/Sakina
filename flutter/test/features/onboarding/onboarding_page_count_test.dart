import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('onboarding page-index constants (pinned by rating-gate insertion 2026-05-14)', () {
    test('onboardingLastPageIndex is 26 (rating gate at 25, paywall at 26)', () {
      // Assumes Env.ratingGateEnabled defaults to true. If the kill switch
      // ships in the off position via env.json, this expectation collapses
      // to 25 — see docs/superpowers/plans/2026-05-14-rating-gate.md.
      expect(onboardingLastPageIndex, 26);
    });

    test('onboardingPasswordPageIndex is 20', () {
      expect(onboardingPasswordPageIndex, 20);
    });

    test('onboardingEncouragementPageIndex is 21', () {
      expect(onboardingEncouragementPageIndex, 21);
    });

    test('OnboardingState schema version is 6', () {
      const s = OnboardingState();
      expect(s.toJson()['version'], 6);
    });

    test('fromJson discards blobs older than version 6', () {
      // A v5 blob with a stored currentPage should be dropped, returning a fresh state.
      final old = OnboardingState.fromJson({
        'version': 5,
        'currentPage': 17,
        'intention': 'spiritual-growth',
      });
      expect(old.currentPage, 0);
      expect(old.intention, isNull);
    });

    test('fromJson preserves v6 blobs', () {
      const original = OnboardingState(currentPage: 5, intention: 'curious');
      final restored = OnboardingState.fromJson(original.toJson());
      expect(restored.currentPage, 5);
      expect(restored.intention, 'curious');
    });
  });
}
