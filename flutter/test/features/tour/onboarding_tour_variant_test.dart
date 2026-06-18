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

  group('tourBucket + assignTourVariant', () {
    test('bucket is deterministic and in 0..99', () {
      expect(tourBucket('user-abc'), tourBucket('user-abc'));
      for (final id in ['', 'a', 'user-1', 'a-much-longer-uuid-1234-5678']) {
        final b = tourBucket(id);
        expect(b, inInclusiveRange(0, 99), reason: 'bucket for "$id" out of range');
      }
    });

    test('assignment is stable per user across calls', () {
      const id = '6f1d2c3a-aaaa-bbbb-cccc-1234567890ab';
      expect(assignTourVariant(id), assignTourVariant(id));
    });

    test('splits a population of ids roughly 50/50 (both arms represented)', () {
      var slim = 0;
      var full = 0;
      for (var i = 0; i < 2000; i++) {
        final v = assignTourVariant('user-uuid-seed-$i');
        v == TourVariant.slim ? slim++ : full++;
      }
      // Both arms must be non-trivially represented; allow a wide band so the
      // test is about "the split works", not exact balance.
      expect(slim, greaterThan(700));
      expect(full, greaterThan(700));
      expect(slim + full, 2000);
    });
  });

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
