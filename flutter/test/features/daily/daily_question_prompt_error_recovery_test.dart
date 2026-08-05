// P0 — the question screen died silently on any transient failure.
//
// `_submitTyped` sets `_committing = true` and NOTHING ever set it back. On the
// happy path that is invisible: the reveal replaces the widget. On a failure it
// is a dead end, because `discoverName()` catches into `state.error`, clears
// `checkinLoading`, and returns normally — so the question surface rebuilds with
// the SAME State object, `_committing` still true.
//
// What the user experiences: they type how they feel — the most personal input
// this app ever asks for — tap send, and the screen stops responding. The field
// is disabled (`enabled: !_committing`), the send button is inert, "Not right
// now" no-ops (`if (_committing) return`), and no message appears anywhere,
// because this widget never read `state.error` at all. The only escape is the
// OS back gesture, which is not an in-app affordance.
//
// Reachable by: airplane mode, a Supabase 5xx, a slow network timing out, an
// `unsealNext()` failure. Not contrived — the plan's own device-test list says
// "airplane mode at the daily reveal shows retry, not a wrong Name", and the
// spec calls the escape hatch non-negotiable.
//
// This is the app's highest-traffic new surface, and the failure lands at the
// exact moment a user has just disclosed something.
//
// MUTATION: delete the `_committing = false` reset in `didUpdateWidget` → every
// recovery case below fails.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/features/daily/widgets/daily_question_defer_link.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? errorText,
    required void Function(String, {String? chipKey}) onSubmit,
    required VoidCallback onDefer,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DailyQuestionPrompt(
              onSubmit: onSubmit,
              onDefer: onDefer,
              errorText: errorText,
              commitBeat: Duration.zero,
            ),
          ),
        ),
      );

  // Drives the latch the way a submit does, without depending on the field's
  // internal `_hasText` wiring — the bug is about what happens AFTER the latch
  // is set, and this reaches that state deterministically.
  Future<void> latchThenFail(WidgetTester tester,
      {required void Function(String, {String? chipKey}) onSubmit,
      required VoidCallback onDefer}) async {
    await pump(tester, onSubmit: onSubmit, onDefer: onDefer, errorText: null);
    final state = tester.state<DailyQuestionPromptState>(
        find.byType(DailyQuestionPrompt));
    state.debugSetCommittingForTest(true);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse,
        reason: 'precondition: the latch is what disables the field');

    await pump(tester,
        onSubmit: onSubmit,
        onDefer: onDefer,
        errorText: 'Something went wrong. Try again.');
    await tester.pump();
  }

  testWidgets('an error re-enables the field so the user can retry',
      (tester) async {
    await latchThenFail(tester, onSubmit: (_, {chipKey}) {}, onDefer: () {});

    expect(
      tester.widget<TextField>(find.byType(TextField)).enabled,
      isTrue,
      reason: 'a user who just disclosed something and hit a network blip must '
          'be able to try again without killing the app',
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the error is actually SHOWN, not just recovered from',
      (tester) async {
    await pump(tester,
        onSubmit: (_, {chipKey}) {},
        onDefer: () {},
        errorText: 'Something went wrong. Try again.');
    await tester.pump();

    expect(find.text('Something went wrong. Try again.'), findsOneWidget,
        reason: 'silently re-enabling the field tells the user nothing about '
            'why their answer vanished — they would assume it was received');
    await tester.pumpAndSettle();
  });

  testWidgets('the defer escape hatch works again after an error',
      (tester) async {
    // "Not right now" is the documented, non-negotiable escape hatch — and it
    // no-opped too, so the user could neither retry NOR leave.
    var deferred = 0;
    await latchThenFail(tester,
        onSubmit: (_, {chipKey}) {}, onDefer: () => deferred++);

    // By type, not by text: `warnIfMissed` would silently swallow a miss if
    // the link sat below the fold, and a test that cannot fail is not a test.
    await tester.ensureVisible(find.byType(DailyQuestionDeferLink));
    await tester.pump();
    await tester.tap(find.byType(DailyQuestionDeferLink));
    await tester.pump();

    expect(deferred, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('with NO error the latch HOLDS, so a double-tap cannot re-fire',
      (tester) async {
    // The guard must not become a blanket unlatch: on the happy path this
    // widget is about to be replaced by the reveal, and re-enabling would let a
    // second discoverName fire.
    await pump(tester,
        onSubmit: (_, {chipKey}) {}, onDefer: () {}, errorText: null);
    tester
        .state<DailyQuestionPromptState>(find.byType(DailyQuestionPrompt))
        .debugSetCommittingForTest(true);
    await tester.pump();

    await pump(tester,
        onSubmit: (_, {chipKey}) {}, onDefer: () {}, errorText: null);
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets('a SECOND error does not re-unlatch mid-retry', (tester) async {
    // Only the null→non-null edge releases. A rebuild that still carries the
    // same error must not clobber a retry the user has already started.
    await latchThenFail(tester, onSubmit: (_, {chipKey}) {}, onDefer: () {});
    tester
        .state<DailyQuestionPromptState>(find.byType(DailyQuestionPrompt))
        .debugSetCommittingForTest(true);
    await tester.pump();

    await pump(tester,
        onSubmit: (_, {chipKey}) {},
        onDefer: () {},
        errorText: 'Something went wrong. Try again.');
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.pumpAndSettle();
  });
}
