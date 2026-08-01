// The guided tour must never quote the home CTA's label.
//
// This exists because it already happened. The tour said "Tap Begin Muhāsabah
// to start"; W4 Wave 5 renamed the CTA to the job, and W4 Wave 5's follow-up
// renamed it again to the question — two renames in one day. The tour kept
// instructing users to tap a control that no longer went by that name.
//
// That is worse than a stale comment and worse than no hint at all: a coachmark
// spotlighting a button while naming a different one reads as the app being
// broken. And it was live — the forced tour was killed for the reel flow on
// 2026-07-28, but the flag-off path retains it, and W4 ships to all users, so a
// legacy user would have met it.
//
// The string edit was the symptom. The fix is structural, and it is two halves,
// both enforced here:
//
//   1. The CTA's labels live in exactly one place (`DailyLoopCtaCopy`) and the
//      widget renders them — so the constant cannot itself go stale.
//   2. Nothing pointing AT the CTA may quote those labels. The tour spotlights
//      its anchor, so it refers to the control by position ("tap here"), which
//      is both truer and cannot drift.
//
// Anyone reaching for "just mention the button name" will land on test 2.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/progress/widgets/daily_loop_cta_card.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';

void main() {
  /// Every CTA label a tour step could be tempted to quote, plus the retired
  /// ones, so a revert to the old wording is caught as loudly as a new quote.
  const ctaLabels = <String>[
    DailyLoopCtaCopy.notStarted,
    DailyLoopCtaCopy.inProgress,
    DailyLoopCtaCopy.notStartedGloss,
    DailyLoopCtaCopy.inProgressGloss,
  ];
  const retiredLabels = <String>[
    'Begin Muhāsabah',
    'Begin Muḥāsabah',
    'Continue Muhāsabah',
    'Name what you\'re carrying',
  ];

  Iterable<OnboardingTourStepDef> allSteps() sync* {
    yield* kSlimOnboardingTourSteps;
    yield* kFullOnboardingTourSteps;
  }

  group('half 1 — the labels have one source of truth', () {
    testWidgets('the CTA renders DailyLoopCtaCopy.notStarted verbatim',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DailyLoopCtaCard(
            state: DailyLoopCtaState.notStarted,
            onStart: () {},
          ),
        ),
      ));

      expect(find.text(DailyLoopCtaCopy.notStarted), findsOneWidget,
          reason: 'if the widget stops rendering the constant, the constant '
              'becomes a lie and every drift check below is checking nothing');
      expect(find.text(DailyLoopCtaCopy.notStartedGloss), findsOneWidget);
    });

    testWidgets('the CTA renders DailyLoopCtaCopy.inProgress verbatim',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DailyLoopCtaCard(
            state: DailyLoopCtaState.inProgress,
            onStart: () {},
          ),
        ),
      ));

      expect(find.text(DailyLoopCtaCopy.inProgress), findsOneWidget);
      expect(find.text(DailyLoopCtaCopy.inProgressGloss), findsOneWidget);
    });
  });

  group('half 2 — no tour step may name the control', () {
    test('the step anchored on the CTA exists in both arms', () {
      // If this fails the drift checks below would pass vacuously.
      for (final steps in [kSlimOnboardingTourSteps, kFullOnboardingTourSteps]) {
        expect(
          steps.where((s) => s.anchorId == 'beginMuhasabahCta'),
          isNotEmpty,
          reason: 'both tour arms must still anchor a step on the home CTA',
        );
      }
    });

    test('no tour step quotes a current CTA label', () {
      for (final step in allSteps()) {
        for (final label in ctaLabels) {
          expect(
            step.message.contains(label),
            isFalse,
            reason: 'Tour step "${step.id}" quotes the CTA label "$label". '
                'Refer to the control by position instead — the step '
                'spotlights its anchor, so "tap here" works and cannot go '
                'stale when the label changes. Copy that names a control the '
                'user cannot find reads as a broken app.',
          );
        }
      }
    });

    test('no tour step resurrects a retired CTA label', () {
      for (final step in allSteps()) {
        for (final label in retiredLabels) {
          expect(
            step.message.contains(label),
            isFalse,
            reason: 'Tour step "${step.id}" names "$label", which is not what '
                'the button says any more. This is the exact regression this '
                'file exists for.',
          );
        }
      }
    });

    test('the CTA step still points somewhere, positionally', () {
      final steps =
          allSteps().where((s) => s.anchorId == 'beginMuhasabahCta').toList();
      expect(steps, hasLength(2));
      for (final step in steps) {
        expect(step.message.toLowerCase(), contains('here'),
            reason: 'the replacement for the label must actually direct the '
                'user — dropping the name without a positional reference '
                'leaves the coachmark saying nothing');
        expect(step.interactive, isTrue,
            reason: '"tap here" is only true while the step spotlights the '
                'anchor and waits for the tap');
      }
    });
  });
}
