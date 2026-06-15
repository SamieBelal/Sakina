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

    test('last step is the dua build (tour ends on the user\'s own dua)', () {
      expect(kOnboardingTourSteps.last.id, 'duas.buildCta');
      expect(kOnboardingTourSteps.last.interactive, true,
          reason: 'Final step is the Build tap; tour completes when the user '
              'taps Build');
    });

    test('exactly 7 steps (slim Muhasabah → Duas tour, 2026-06-15)', () {
      expect(kOnboardingTourLength, 7);
      expect(kOnboardingTourSteps.length, 7);
    });

    test('canonical slim-tour order', () {
      expect(kOnboardingTourSteps.map((s) => s.id).toList(), [
        'home.beginMuhasabah',
        'muhasabah.goDeeper',
        'muhasabah.readStory',
        'muhasabah.ameen',
        'muhasabah.returnHome',
        'appShell.tabDuas',
        'duas.buildCta',
      ]);
    });

    test('tourism + streak/return-home steps were cut', () {
      final ids = kOnboardingTourSteps.map((s) => s.id).toSet();
      for (final cut in const [
        'appShell.tabCollection',
        'appShell.tabDuasFromCollection',
        'duas.firstRelatedHeart',
        'appShell.tabJournalFromDuas',
        'journal.firstEntry',
        'duaDetail.done',
        // Streak beat + the return-home hop it required: dropped because the
        // evening streak push carries the "come back tomorrow" hook.
        'appShell.tabHome',
        'home.streakPill',
      ]) {
        expect(ids.contains(cut), false, reason: '$cut should be cut');
      }
      // No journal-, duaDetail- or collection-surface steps remain.
      expect(
        kOnboardingTourSteps.any((s) =>
            s.surface == TourSurface.journal ||
            s.surface == TourSurface.duaDetail ||
            s.surface == TourSurface.collection),
        false,
        reason: 'slim tour visits home → muhasabah → duas only',
      );
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

    test('appShell-surface steps are the single nav-tab hop to Duas', () {
      final appShellSteps = kOnboardingTourSteps
          .where((s) => s.surface == TourSurface.appShell)
          .toList();
      expect(appShellSteps.map((s) => s.id).toList(), ['appShell.tabDuas'],
          reason: 'slim tour: one hop out to Duas, no return-home hop');
      for (final step in appShellSteps) {
        expect(step.interactive, true,
            reason: 'Tab-target steps must be interactive (user taps the tab)');
        expect(step.trigger, TourAdvanceTrigger.navigate,
            reason: 'Tab steps advance on the route change, not a pointer tap');
      }
    });

    test('the nav-tab step advances on /duas', () {
      final byId = {for (final s in kOnboardingTourSteps) s.id: s};
      expect(byId['appShell.tabDuas']!.navigateRoute, '/duas');
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

    test('bottom-nav tab step grows the cutout into the full tab cell', () {
      // The tab anchor wraps the ICON only; without horizontal + downward
      // padding the cutout would spotlight just the glyph and leave the tab
      // label greyed under the scrim. Pin that the tab step requests the
      // full-cell expansion so a future edit can't silently regress it.
      const tabAnchorIds = {'tabDuas'};
      final tabSteps = kOnboardingTourSteps
          .where((s) => tabAnchorIds.contains(s.anchorId))
          .toList();
      expect(tabSteps.length, 1, reason: 'expected 1 bottom-nav tab step');
      for (final step in tabSteps) {
        expect(step.cutoutPaddingX, greaterThan(0),
            reason: '${step.id} must widen the cutout to cover the tab label');
        expect(step.cutoutPaddingBottom, greaterThan(0),
            reason: '${step.id} must extend the cutout down over the label');
      }
    });

    test('non-tab steps do not use tab-cell cutout padding', () {
      const tabAnchorIds = {'tabDuas'};
      for (final step in kOnboardingTourSteps) {
        if (tabAnchorIds.contains(step.anchorId)) continue;
        expect(step.cutoutPaddingX, 0,
            reason: '${step.id} unexpectedly expands horizontally');
        expect(step.cutoutPaddingBottom, 0,
            reason: '${step.id} unexpectedly expands downward');
      }
    });
  });
}
