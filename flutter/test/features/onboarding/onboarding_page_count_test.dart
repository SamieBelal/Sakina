import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  group('onboarding page-index constants (pinned by paywall flow redesign)', () {
    test('onboardingLastPageIndex is 25', () {
      expect(onboardingLastPageIndex, 25);
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
