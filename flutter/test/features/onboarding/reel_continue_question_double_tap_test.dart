// W6 Wave F, review finding P1 — a double-tapped Continue emitted twice.
//
// Five of the seven intake screens are `ReelSingleTapQuestion`, which has held a
// `_committing` / `_committed` re-entry guard since it was written. The other
// two — help_chips and intake_note — are `ReelContinueQuestion`, which had
// none, and Wave F put an analytics call inside their `onContinue` closures.
//
// The window is real and unnoticeable: tap 1 fires the emit, calls `onNext` →
// `_goToPage`, which updates state synchronously and starts a 300ms
// `animateToPage`. The outgoing page's button stays live for that animation.
// A second tap re-enters the same closure and emits again. `_goToPage`'s own
// `_navigating` flag stops the NAVIGATION, so the user sees nothing wrong — but
// it sits DOWNSTREAM of the analytics call and never protected it. Mixpanel
// gets two `onboarding_answer_captured` events for one screen visit, which
// inflates exactly the answer-distribution this wave exists to measure.
//
// Fixed in the shared widget rather than twice in the screens: `queue_plan_screen`
// is the third user of `ReelContinueQuestion` and would have inherited the same
// bug the moment anyone put an emit in its callback.
//
// MUTATION: delete the guard in `ReelContinueQuestion` → the double-tap cases
// below fail with 2 calls instead of 1.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/reel_continue_question.dart';

void main() {
  Future<void> pumpSubject(
    WidgetTester tester, {
    required VoidCallback onContinue,
    VoidCallback? onSkip,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          home: ReelContinueQuestion(
            headline: 'Anything you want to add?',
            subline: 'Optional.',
            body: const SizedBox.shrink(),
            continueLabel: 'Continue',
            onContinue: onContinue,
            skipLabel: onSkip == null ? null : 'Nothing to add',
            onSkip: onSkip,
          ),
        ),
      );

  testWidgets('a double-tapped Continue commits exactly once', (tester) async {
    var calls = 0;
    await pumpSubject(tester, onContinue: () => calls++);

    final button = find.text('Continue');
    await tester.tap(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();

    expect(calls, 1,
        reason: 'the second tap lands inside the page-transition animation, '
            'where the button is still live — without a guard it re-enters the '
            'closure and emits a duplicate answer event');
    await tester.pumpAndSettle();
  });

  testWidgets('three rapid taps still commit once', (tester) async {
    var calls = 0;
    await pumpSubject(tester, onContinue: () => calls++);

    final button = find.text('Continue');
    for (var i = 0; i < 3; i++) {
      await tester.tap(button, warnIfMissed: false);
    }
    await tester.pump();

    expect(calls, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('the skip link is blocked once Continue has committed',
      (tester) async {
    // Otherwise a Continue-then-Skip double tap emits the answer AND the
    // decline for one visit — two mutually exclusive facts about one user.
    var committed = 0;
    var skipped = 0;
    await pumpSubject(
      tester,
      onContinue: () => committed++,
      onSkip: () => skipped++,
    );

    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Nothing to add'), warnIfMissed: false);
    await tester.pump();

    expect(committed, 1);
    expect(skipped, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('a double-tapped Skip declines exactly once', (tester) async {
    var skipped = 0;
    await pumpSubject(tester, onContinue: () {}, onSkip: () => skipped++);

    final skip = find.text('Nothing to add');
    await tester.tap(skip);
    await tester.tap(skip, warnIfMissed: false);
    await tester.pump();

    expect(skipped, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('a DISABLED continue never commits', (tester) async {
    // help_chips gates Continue on at least one selection. The guard must not
    // change that: a null callback stays inert.
    await tester.pumpWidget(
      const MaterialApp(
        home: ReelContinueQuestion(
          headline: 'What would help?',
          subline: 'Pick up to three.',
          body: SizedBox.shrink(),
          continueLabel: 'Continue',
          onContinue: null,
        ),
      ),
    );

    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('a rebuild with a new callback releases the guard',
      (tester) async {
    // The release point matters: a user who navigates BACK to this screen must
    // be able to answer again. Same contract as ReelSingleTapQuestion's
    // didUpdateWidget release.
    var calls = 0;
    await pumpSubject(tester, onContinue: () => calls++);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(calls, 1);

    // A fresh mount of the same screen (back navigation) starts unguarded.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpSubject(tester, onContinue: () => calls++);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(calls, 2, reason: 'the guard is per-visit, not per-lifetime — '
        'otherwise going back and changing your answer silently records '
        'nothing');
    await tester.pumpAndSettle();
  });
}
