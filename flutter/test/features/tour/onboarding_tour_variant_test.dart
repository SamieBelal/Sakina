import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';

void main() {
  group('full (control) tour arm', () {
    test('is the 14-step tour ending on the centered finale', () {
      // 13 original + the shared `duas.sectionNext` reader coachmark (added so
      // the first built-dua screen highlights the Next button in BOTH arms).
      expect(kFullOnboardingTourSteps, hasLength(14));
      expect(kFullOnboardingTourSteps.first.id, 'home.beginMuhasabah');
      expect(kFullOnboardingTourSteps.last.id, 'duaDetail.done');
      expect(kFullOnboardingTourSteps.last.anchorId, 'centered');
      expect(kFullOnboardingTourSteps.last.interactive, false);
    });

    test('duas.sectionNext sits right after the Build CTA in the full arm too',
        () {
      final ids = kFullOnboardingTourSteps.map((s) => s.id).toList();
      expect(ids.contains('duas.sectionNext'), true);
      expect(ids.indexOf('duas.sectionNext'), ids.indexOf('duas.buildCta') + 1);
      final step = kFullOnboardingTourSteps
          .firstWhere((s) => s.id == 'duas.sectionNext');
      expect(step.anchorId, 'duaSectionNext');
      expect(step.interactive, true);
    });

    test('restores the tourism steps the slim arm cut', () {
      final ids = kFullOnboardingTourSteps.map((s) => s.id).toSet();
      for (final id in const [
        'appShell.tabCollection',
        'appShell.tabDuasFromCollection',
        'duas.firstRelatedHeart',
        'appShell.tabJournalFromDuas',
        'journal.firstEntry',
        'home.streakPill',
      ]) {
        expect(ids.contains(id), true, reason: '$id should be in the full arm');
      }
    });

    test('step ids are unique', () {
      final ids = kFullOnboardingTourSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('the default alias is the slim arm', () {
      expect(kOnboardingTourSteps, same(kSlimOnboardingTourSteps));
      expect(kOnboardingTourLength, kSlimOnboardingTourSteps.length);
    });
  });

  group('tourStepsForVariant', () {
    test('maps each variant to its list', () {
      expect(tourStepsForVariant(TourVariant.slim),
          same(kSlimOnboardingTourSteps));
      expect(tourStepsForVariant(TourVariant.full),
          same(kFullOnboardingTourSteps));
    });
  });

  // The `tourBucket + assignTourVariant` group lived here. Both functions were
  // deleted with the reverse-trial close-out (W5 Wave A, 2026-08-01): the tour
  // A/B concluded 2026-07-25 and the salted bucket survived only because it
  // backed `assignPaywallArm`. Nothing assigns a variant any more — everyone
  // gets slim, which `tourStepsForVariant` above still pins.

  group('OnboardingTourState honors the variant', () {
    test('slim state indexes the slim list', () {
      const state = OnboardingTourState(
        index: 6,
        status: TourStatus.active,
        variant: TourVariant.slim,
      );
      expect(state.steps, same(kSlimOnboardingTourSteps));
      expect(state.currentStep?.id, 'duas.buildCta'); // slim step 6 (Build CTA)
    });

    test('full state indexes the full list', () {
      const state = OnboardingTourState(
        index: 13,
        status: TourStatus.active,
        variant: TourVariant.full,
      );
      expect(state.steps, same(kFullOnboardingTourSteps));
      expect(state.currentStep?.id, 'duaDetail.done'); // full step 13 (last)
    });

    test('defaults to the slim variant', () {
      const state = OnboardingTourState(index: 0, status: TourStatus.active);
      expect(state.variant, TourVariant.slim);
    });

    test('an index past the active variant length yields null', () {
      // Index 9 is out of range for slim (9 steps, 0-8) but the full arm has 14.
      const slim = OnboardingTourState(
        index: 9,
        status: TourStatus.active,
        variant: TourVariant.slim,
      );
      expect(slim.currentStep, isNull);
      const full = OnboardingTourState(
        index: 9,
        status: TourStatus.active,
        variant: TourVariant.full,
      );
      expect(full.currentStep, isNotNull);
    });
  });
}
