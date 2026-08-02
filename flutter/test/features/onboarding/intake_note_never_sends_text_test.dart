import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/intake_note_screen.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// W6 Wave F privacy guarantee — `IntakeNoteScreen` is the app's one free-text
/// intake screen (H7, "Anything you want to add?"). The instruction was:
/// record THAT a note was written and a length bucket, never the text, never a
/// prefix, never a hash. This file pins both halves of that:
///
///   * a behavioural test — type a distinctive string, submit, assert it
///     appears in NO emitted analytics property;
///   * a source-level grep of the intake screens' call sites, so a future edit
///     that pipes `.text` straight into an analytics call fails CI even if a
///     particular test run's string happens not to collide with anything.
class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('behavioural', () {
    testWidgets(
        'typed note text never appears in any emitted analytics property',
        (tester) async {
      useOnboardingViewport(tester);
      final spy = _TrackingSpy();
      const secret = 'UNMISTAKABLE_SECRET_PHRASE_38217_do_not_leak';
      await tester.pumpWidget(ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(spy)],
        child: MaterialApp(home: IntakeNoteScreen(onNext: () {})),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), secret);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Sanity: the screen did emit something — otherwise this test would pass
      // vacuously regardless of what the code does.
      expect(spy.tracked, isNotEmpty);

      for (final event in spy.tracked) {
        final serialized = event.$2.toString();
        // MUTATION: pass `_controller.text` (or any substring/prefix of it) as
        // the tracked value instead of `intakeNoteLengthBucket(...)` → fails.
        expect(serialized.contains(secret), isFalse,
            reason:
                'Event "${event.$1}" leaked the raw note text: $serialized');
      }
    });

    testWidgets('the length bucket is present and categorical, never the text',
        (tester) async {
      useOnboardingViewport(tester);
      final spy = _TrackingSpy();
      await tester.pumpWidget(ProviderScope(
        overrides: [analyticsProvider.overrideWithValue(spy)],
        child: MaterialApp(home: IntakeNoteScreen(onNext: () {})),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'x' * 90, // lands in the "medium" bucket (51-200 graphemes)
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final events = spy.tracked
          .where((e) => e.$2?['key'] == 'intake_note')
          .toList();
      expect(events, hasLength(1));
      expect(events.single.$2, containsPair('value', 'medium'));
    });
  });

  group('source-level: no `.text` reaches analytics unwrapped', () {
    // All seven Wave F screens, defensively — only intake_note_screen.dart has
    // a TextEditingController today, but a future H-screen edit that adds one
    // should trip this too rather than silently reopening the gap.
    const files = [
      'lib/features/onboarding/screens/carrying_duration_screen.dart',
      'lib/features/onboarding/screens/heaviest_time_screen.dart',
      'lib/features/onboarding/screens/told_anyone_screen.dart',
      'lib/features/onboarding/screens/names_known_screen.dart',
      'lib/features/onboarding/screens/help_chips_screen.dart',
      'lib/features/onboarding/screens/daily_time_screen.dart',
      'lib/features/onboarding/screens/intake_note_screen.dart',
    ];

    for (final path in files) {
      test(path, () {
        final source = File(path).readAsStringSync();
        // Every `trackOnboardingAnswer*(...)` call site, as the full statement
        // text (start of the call to its closing `;`) so a multi-line call is
        // captured whole and a nested call like `intakeNoteLengthBucket(...)`
        // doesn't truncate the match early.
        for (final match
            in RegExp(r'trackOnboardingAnswer\w*\(').allMatches(source)) {
          final end = source.indexOf(';', match.start);
          final call = source.substring(
            match.start,
            end == -1 ? source.length : end + 1,
          );
          // Every controller-derived value, not just a literal `.text` in the
          // call. The original guard only fired when `.text` appeared INSIDE
          // the call expression, so one level of indirection walked straight
          // past it:
          //
          //     final note = _controller.text;
          //     trackOnboardingAnswerWithRef(ref, 'intake_note', note);
          //
          // — no `.text` in the call, no assert, no leak caught. That is the
          // more likely shape the moment someone refactors for readability,
          // and it is exactly the case the behavioural test cannot cover on a
          // screen nobody wrote a widget test for.
          //
          // So: resolve local aliases of any `TextEditingController` first, and
          // treat a call carrying one as carrying `.text`.
          final aliases = RegExp(r'final\s+(\w+)\s*=\s*[\w.]*\.text\b')
              .allMatches(source)
              .map((m) => m.group(1)!)
              .toSet();
          final carriesText = call.contains('.text') ||
              aliases.any((a) => RegExp(r'(?<![\w.])' + a + r'(?![\w])')
                  .hasMatch(call));
          if (!carriesText) continue;
          // MUTATION: change the emit call to pass `_controller.text` directly
          // instead of `intakeNoteLengthBucket(_controller.text)` → this must
          // fail, because `.text` would then appear outside the bucket call.
          expect(call.contains('intakeNoteLengthBucket('), isTrue,
              reason: 'Found a `.text` value flowing into an analytics call '
                  'in $path that is not wrapped by a bucket function:\n$call');
        }
      });
    }
  });
}
