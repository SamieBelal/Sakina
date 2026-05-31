import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

// Trimmed-flow refactor (2026-05-25, Option α): page indices recomputed
// for the 20-screen trimmed flow. Legacy 27-screen constants kept under
// the `onboardingLegacy*` names for the kill-switch rollback path.
void main() {
  group('onboarding page-index constants (pinned by 2026-05-25 trim)', () {
    test('onboardingLastPageIndex is 19 (paywall at 19 in trimmed flow)', () {
      // Assumes Env.ratingGateEnabled defaults to true.
      expect(onboardingLastPageIndex, 19);
    });

    test('onboardingEmailPageIndex is 14', () {
      expect(onboardingEmailPageIndex, 14);
    });

    test('onboardingPasswordPageIndex is 15', () {
      expect(onboardingPasswordPageIndex, 15);
    });

    test('onboardingPostSignupPageIndex is 16', () {
      expect(onboardingPostSignupPageIndex, 16);
    });

    test('onboardingLegacyLastPageIndex is 26 (rollback path)', () {
      expect(onboardingLegacyLastPageIndex, 26);
    });

    test('onboardingLegacyEncouragementPageIndex is 21 (rollback path)', () {
      expect(onboardingLegacyEncouragementPageIndex, 21);
    });

    test('OnboardingState schema version is 7', () {
      const s = OnboardingState();
      expect(s.toJson()['version'], 7);
    });

    test('fromJson discards blobs older than version 7', () {
      // A v6 blob with a stored currentPage should be dropped, returning a fresh state.
      final old = OnboardingState.fromJson({
        'version': 6,
        'currentPage': 17,
        'intention': 'spiritual-growth',
      });
      expect(old.currentPage, 0);
      expect(old.intention, isNull);
    });

    test('fromJson preserves v7 blobs', () {
      const original = OnboardingState(currentPage: 5, intention: 'curious');
      final restored = OnboardingState.fromJson(original.toJson());
      expect(restored.currentPage, 5);
      expect(restored.intention, 'curious');
    });
  });
}
