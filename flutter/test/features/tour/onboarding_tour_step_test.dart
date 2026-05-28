import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';

void main() {
  group('OnboardingTourStep registry', () {
    test('step ids are unique', () {
      final ids = kOnboardingTourSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate step IDs would confuse analytics');
    });

    test('first step is home.beginMuhasabah', () {
      expect(kOnboardingTourSteps.first.id, 'home.beginMuhasabah');
    });

    test('last step is duaDetail.done', () {
      expect(kOnboardingTourSteps.last.id, 'duaDetail.done');
      expect(kOnboardingTourSteps.last.interactive, false,
          reason: 'Final step is a teach moment with Done button, not '
              'an interactive target tap');
    });

    test('exactly 13 steps (post-CEO-review final count)', () {
      expect(kOnboardingTourLength, 13);
      expect(kOnboardingTourSteps.length, 13);
    });

    test('streak teach step (index 5) is post-Muhasabah habit beat', () {
      expect(kOnboardingTourSteps[5].id, 'home.streakPill');
      expect(kOnboardingTourSteps[5].interactive, false,
          reason: 'Streak pill is non-tappable; teach beat with Continue');
    });

    test('journal entry tap (index 11) is interactive', () {
      expect(kOnboardingTourSteps[11].id, 'journal.firstEntry');
      expect(kOnboardingTourSteps[11].interactive, true);
    });

    test('See the Dua step intentionally omitted from muhasabah deeper steps',
        () {
      final muhasabahStepIds = kOnboardingTourSteps
          .where((s) => s.surface == TourSurface.muhasabah)
          .map((s) => s.id)
          .toList();
      // Go Deeper, Read the Story, Ameen, Return to Home — 4 muhasabah anchors.
      expect(muhasabahStepIds, [
        'muhasabah.goDeeper',
        'muhasabah.readStory',
        'muhasabah.ameen',
        'muhasabah.returnHome',
      ]);
      // No "seeDua" step.
      expect(muhasabahStepIds.any((id) => id.contains('seeDua')), false);
    });

    test('appShell-surface steps target bottom-nav tabs', () {
      final appShellSteps = kOnboardingTourSteps
          .where((s) => s.surface == TourSurface.appShell)
          .toList();
      expect(appShellSteps.length, 3,
          reason: '3 nav-tab steps: Collection, Duas-from-Collection, '
              'Journal-from-Duas');
      for (final step in appShellSteps) {
        expect(step.interactive, true,
            reason: 'Tab-target steps must be interactive (user taps the tab)');
      }
    });

    test('all interactive steps have a hint', () {
      for (final step in kOnboardingTourSteps) {
        if (step.interactive) {
          expect(step.hint, isNotNull,
              reason: 'Step ${step.id} is interactive but has no hint — '
                  'user has no visual cue to tap');
        }
      }
    });

    test('Reflect tab is intentionally NOT in tour (CEO review cut)', () {
      final reflectSteps = kOnboardingTourSteps
          .where((s) => s.surface == TourSurface.reflect)
          .toList();
      expect(reflectSteps, isEmpty,
          reason: 'CEO review (2026-05-26) cut Reflect from the tour — it '
              'duplicates muhasabah\'s text-input + AI-response pattern');
    });
  });
}
