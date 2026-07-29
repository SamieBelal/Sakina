import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

// Trimmed-flow refactor (2026-05-25, Option α): page indices recomputed
// for the 20-screen trimmed flow. Legacy 27-screen constants kept under
// the `onboardingLegacy*` names for the kill-switch rollback path.
void main() {
  group('onboarding page-index constants (pinned by 2026-05-25 trim)', () {
    test('onboardingLastPageIndex is 19 (paywall at 19 in trimmed flow)', () {
      // Rating gate is always present, so paywall sits at index 19.
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

    // --- REEL flow (One Ship W2-E1), the shipping default -------------------

    test('onboardingReelLastPageIndex is 18 (paywall gate at 18)', () {
      expect(onboardingReelLastPageIndex, 18);
    });

    test('the reel hook and reveal are pages 0 and 1', () {
      expect(onboardingReelHookPageIndex, 0);
      expect(onboardingReelRevealPageIndex, 1);
    });

    test('onboardingReelNoBackBeforeIndex is 2 (first page past the reveal)',
        () {
      expect(onboardingReelNoBackBeforeIndex, 2);
      expect(
        onboardingReelNoBackBeforeIndex,
        onboardingReelRevealPageIndex + 1,
        reason: 'the latch must start immediately after the reveal — a gap '
            'would leave a page that can still back into a burnt deck',
      );
    });

    test('the reel signup trio sits at 16/17 with the gate at 18', () {
      expect(onboardingReelEmailPageIndex, 16);
      expect(onboardingReelPasswordPageIndex, 17);
      expect(onboardingReelPostSignupPageIndex, 18);
    });

    test('onboardingReelTotalSegments is 14 (19 pages minus the 5 bar-less)',
        () {
      expect(onboardingReelTotalSegments, 14);
      expect(
        onboardingReelTotalSegments,
        (onboardingReelLastPageIndex + 1) - 5,
        reason: 'bar hidden on hook, reveal, queue plan and paywall',
      );
    });

    test('lastPageIndexForFlow resolves all three flows', () {
      expect(lastPageIndexForFlow(OnboardingFlowKind.reel),
          onboardingReelLastPageIndex);
      expect(lastPageIndexForFlow(OnboardingFlowKind.trimmed),
          onboardingLastPageIndex);
      expect(lastPageIndexForFlow(OnboardingFlowKind.legacy),
          onboardingLegacyLastPageIndex);
    });

    test('onboardingFlowValueFor maps the kind to the profile column value',
        () {
      // Both fallbacks are `legacy`: the column names the EXPERIENCE, and
      // neither kill-switch flow is the reel one.
      expect(
          onboardingFlowValueFor(OnboardingFlowKind.reel), onboardingFlowReel);
      expect(onboardingFlowValueFor(OnboardingFlowKind.trimmed),
          onboardingFlowLegacy);
      expect(onboardingFlowValueFor(OnboardingFlowKind.legacy),
          onboardingFlowLegacy);
    });

    test('the reel kill-switch flag key is the one the plan names', () {
      expect(reelFirstOnboardingFlag, 'reel_first_onboarding_enabled');
    });

    test('OnboardingState schema version is 8', () {
      const s = OnboardingState();
      expect(s.toJson()['version'], 8);
    });

    test('fromJson discards blobs older than version 8', () {
      // A v7 blob with a stored currentPage should be dropped, returning a
      // fresh state — the reel flow renumbered the pages (One Ship W2-B3).
      final old = OnboardingState.fromJson({
        'version': 7,
        'currentPage': 17,
        'intention': 'spiritual-growth',
      });
      expect(old.currentPage, 0);
      expect(old.intention, isNull);
    });

    test('fromJson preserves v8 blobs', () {
      const original = OnboardingState(currentPage: 5, intention: 'curious');
      final restored = OnboardingState.fromJson(original.toJson());
      expect(restored.currentPage, 5);
      expect(restored.intention, 'curious');
    });
  });
}
