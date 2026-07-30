import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/content/daily_question_copy.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip.dart';
import 'package:sakina/features/daily/widgets/daily_question_defer_link.dart';
import 'package:sakina/features/daily/widgets/daily_question_field.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';

// The daily question surface (W4 Wave 2 — plan §4/§11, spec M2/M4).

/// iOS's largest accessibility text size (AX5). The old tests called
/// `TextScaler.linear(2.0)` "the largest Dynamic Type step"; it is not close.
const double axLargest = 3.1;

/// Asserts the answer-set caption renders in full — every line of it, with no
/// ellipsis.
///
/// Measured rather than eyeballed: lay the string out unconstrained in the
/// caption's own resolved style at the caption's own render width, and require
/// the rendered box to be at least as tall. A truncated caption is shorter than
/// its own text, which is precisely the failure `hintMaxLines: 3` produced and
/// which "no exception was thrown" could never have caught.
///
/// **If you extend this rig to a scrolling surface, do not loop the scales
/// inside one `testWidgets`.** A lazy `ListView` keeps its scroll offset across
/// `pumpWidget` calls in the same test, so the second and third scale passes
/// start part-way down the list and downward-only scrolling can never reach
/// what is above them. Measuring the live hook screen that way reported three
/// chips "unreachable at AX5" that were on screen the whole time — a false
/// positive against the highest-stakes surface in the product, caught only
/// because the missing chips were the *first* three, which is not a plausible
/// failure for a top-anchored list. Reset the position, or split the test.
/// This caption lives in a `Column`, so the trap does not apply here — it
/// applies the moment someone reuses the approach.
void expectCaptionIsWhole(WidgetTester t, double scale) {
  final finder = find.text(DailyQuestionCopy.answerSetCaption);
  expect(finder, findsOneWidget, reason: 'caption missing at scale $scale');
  final widget = t.widget<Text>(finder);
  final box = t.getSize(finder);

  final unconstrained = TextPainter(
    text: TextSpan(
        text: DailyQuestionCopy.answerSetCaption, style: widget.style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(scale),
  )..layout(maxWidth: box.width);

  expect(box.height, greaterThanOrEqualTo(unconstrained.height - 0.5),
      reason: 'the caption is clipped at scale $scale — it needs '
          '${unconstrained.height.toStringAsFixed(1)}pt and was given '
          '${box.height.toStringAsFixed(1)}pt. This line is the only thing '
          'telling the user a grateful answer is permitted; truncated, the '
          'question silently means "what\'s wrong".');

  final painterAtMaxLines = TextPainter(
    text: TextSpan(
        text: DailyQuestionCopy.answerSetCaption, style: widget.style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(scale),
    maxLines: widget.maxLines,
  )..layout(maxWidth: box.width);
  expect(painterAtMaxLines.didExceedMaxLines, isFalse,
      reason: 'maxLines=${widget.maxLines} ellipsizes the caption at scale '
          '$scale');
}

/// The escape hatch has to be *on screen*, not merely mounted somewhere below
/// the fold (plan §2 rule 7).
void expectDeferIsOnScreen(WidgetTester t) {
  final finder = find.byType(DailyQuestionDeferLink);
  expect(finder, findsOneWidget);
  final rect = t.getRect(finder);
  final screen = t.view.physicalSize / t.view.devicePixelRatio;
  expect(rect.bottom, lessThanOrEqualTo(screen.height),
      reason: 'the exit must not sit below the bottom edge');
  expect(rect.top, greaterThanOrEqualTo(0.0));
}

void main() {
  /// Records what the surface handed back, so every test can assert on the
  /// exact shape Wave 3 will consume.
  late List<({String text, String? chipKey})> submissions;
  late int defers;

  setUp(() {
    submissions = [];
    defers = 0;
  });

  Widget host({
    TextScaler textScaler = TextScaler.noScaling,
    double keyboardInset = 0,
    String? initialText,
    bool isReAsk = false,
  }) =>
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: textScaler,
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: DailyQuestionPrompt(
              // No beat in tests — the fill-then-commit pause is UX, not
              // behaviour, and waiting on it would only slow every case.
              commitBeat: Duration.zero,
              initialText: initialText,
              isReAsk: isReAsk,
              onSubmit: (text, {String? chipKey}) =>
                  submissions.add((text: text, chipKey: chipKey)),
              onDefer: () => defers++,
            ),
          ),
        ),
      );

  testWidgets('asks the approved question and keeps the answer-set caption',
      (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    expect(find.text(DailyQuestionCopy.header), findsOneWidget);
    // The caption is the ONLY thing telling the user a grateful answer is
    // permitted (spec M4). If a redesign drops it, the question silently means
    // "what's wrong" — so it is pinned by its exact text, not by its presence.
    expect(find.text(DailyQuestionCopy.answerSetCaption), findsOneWidget);
    expect(
      DailyQuestionCopy.answerSetCaption.contains('thanks'),
      isTrue,
      reason: 'the caption must span worry → thanks',
    );
  });

  testWidgets('does not teach muḥāsabah — the CTA one tap earlier already did',
      (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    // The density pass removed the gloss from THIS surface. The home CTA the
    // user tapped to arrive already carries `DailyLoopCtaCopy.notStartedGloss`,
    // so rendering it here put the same definition on two consecutive screens —
    // and this was the copy the user had least earned, arriving before they had
    // done anything.
    expect(find.text(DailyQuestionCopy.gloss), findsNothing);

    // The rule the gloss existed to satisfy is unchanged and still pinned:
    // muḥāsabah is a taught word, never an action label. If the word ever
    // returns to this screen it must not arrive as a button.
    expect(DailyQuestionCopy.defer.toLowerCase().contains('muh'), isFalse,
        reason: 'muḥāsabah is the taught word, never the CTA label');
  });

  testWidgets('renders the seven approved chip labels, verbatim and in order',
      (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    final chips = t
        .widgetList<DailyQuestionChip>(find.byType(DailyQuestionChip))
        .toList();
    expect(chips.length, problemChips.length);
    expect(
      chips.map((c) => c.chip.label).toList(),
      problemChips.map((c) => c.label).toList(),
      reason: 'the taxonomy is shared with onboarding, never re-worded here',
    );
    for (final chip in problemChips) {
      expect(find.text(chip.label), findsOneWidget);
    }
  });

  testWidgets('a chip fills the field and submits its own key', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    const chip = 'Everything feels heavy';
    await t.tap(find.text(chip));
    await t.pumpAndSettle();

    expect(submissions, hasLength(1));
    expect(submissions.single.text, chip);
    expect(submissions.single.chipKey, 'heavy');
    // Filled, not bypassed — the chip is a shortcut through the field.
    expect(find.widgetWithText(TextField, chip), findsOneWidget);
  });

  testWidgets('typed text submits itself, with no chip key', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField), 'my brother is unwell');
    await t.pumpAndSettle();
    await t.tap(find.byKey(DailyQuestionField.sendButtonKey));
    await t.pumpAndSettle();

    expect(submissions, hasLength(1));
    expect(submissions.single.text, 'my brother is unwell');
    expect(submissions.single.chipKey, isNull);
  });

  testWidgets('an empty field cannot be submitted', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField), '   ');
    await t.pumpAndSettle();
    await t.tap(find.byKey(DailyQuestionField.sendButtonKey), warnIfMissed: false);
    await t.pumpAndSettle();

    expect(submissions, isEmpty);
  });

  testWidgets('the send control is present before a single character is typed',
      (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    // The whole reason the arrow lives inside the field rather than appearing
    // on first keystroke: while someone is deciding what to say, a screen with
    // no visible submit affordance gives them no answer to "how do I send
    // this?". Hiding it until there is text was mocked and rejected for
    // exactly this. If it ever regresses to appear-on-input, this fails.
    expect(find.byKey(DailyQuestionField.sendButtonKey), findsOneWidget);
  });

  testWidgets('commits exactly once, however hard it is tapped', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    await t.tap(find.text('Everything feels heavy'));
    // Second tap on a DIFFERENT chip, before the first commit has settled.
    await t.tap(find.text('I feel far from Allah'), warnIfMissed: false);
    await t.pumpAndSettle();

    expect(submissions, hasLength(1));
    expect(submissions.single.chipKey, 'heavy');
  });

  testWidgets('"Not right now" defers and submits nothing', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    await t.tap(find.byType(DailyQuestionDeferLink));
    await t.pumpAndSettle();

    expect(defers, 1);
    expect(submissions, isEmpty,
        reason: 'a defer is not an answer — nothing may reach the loop');
  });

  testWidgets('every tap target clears 44pt', (t) async {
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    for (final finder in [
      find.byType(DailyQuestionChip),
      find.byType(DailyQuestionDeferLink),
      // The send control's VISIBLE circle is 34pt so it does not crowd the text
      // beside it, but its tap target is a transparent 44pt box around that
      // circle — so it is held to the same floor as everything else here, not
      // excused from it.
      find.byKey(DailyQuestionField.sendButtonKey),
    ]) {
      for (final element in finder.evaluate()) {
        final size = t.getSize(find.byElementPredicate((e) => e == element));
        expect(size.height, greaterThanOrEqualTo(44.0),
            reason: '${element.widget.runtimeType} is under Apple\'s floor');
      }
    }
  });

  testWidgets('the keyboard cannot overflow a small screen', (t) async {
    // iPhone SE, with a keyboard up — the case the house
    // LayoutBuilder → SingleChildScrollView → ConstrainedBox → IntrinsicHeight
    // pattern exists for.
    t.view.physicalSize = const Size(320 * 3, 568 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.pumpWidget(host(keyboardInset: 300));
    await t.pumpAndSettle();

    expect(t.takeException(), isNull);
    expect(find.text(DailyQuestionCopy.header), findsOneWidget);
    // The exit is pinned outside the scroll view precisely so it survives
    // this case — visible, hit-testable, and above the keyboard.
    expectDeferIsOnScreen(t);
  });

  testWidgets('the answer-set caption is never truncated, up to AX5',
      (t) async {
    // This test used to be called "nothing clips at the largest Dynamic Type
    // step" and asserted only that no exception was thrown — which read as
    // coverage that did not exist, and is how the caption shipped ellipsized.
    // It now asserts the thing it claims, at a scale that really is the
    // largest: iOS AX5 is ≈3.1, not the 2.0 this used.
    t.view.physicalSize = const Size(320 * 3, 568 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    for (final scale in [1.0, 2.0, axLargest]) {
      await t.pumpWidget(host(textScaler: TextScaler.linear(scale)));
      await t.pumpAndSettle();

      expect(t.takeException(), isNull, reason: 'at scale $scale');
      expect(find.text(DailyQuestionCopy.header), findsOneWidget);
      expectCaptionIsWhole(t, scale);
      expectDeferIsOnScreen(t);
    }
  });

  testWidgets('the caption survives the first keystroke', (t) async {
    // The hole underneath the truncation: a `hintText` disappears the moment
    // the field is non-empty, so the one line telling the user a grateful
    // answer is permitted used to vanish as they started answering.
    await t.pumpWidget(host());
    await t.pumpAndSettle();
    expect(find.text(DailyQuestionCopy.answerSetCaption), findsOneWidget);

    await t.enterText(find.byType(TextField), 'a');
    await t.pumpAndSettle();

    expect(find.text(DailyQuestionCopy.answerSetCaption), findsOneWidget,
        reason: 'the answer set is not a placeholder — it stays while they '
            'type');
  });

  testWidgets('the caption is shown on a re-ask, where the field is pre-filled',
      (t) async {
    // The sharpest case: after "Say a little more?" the field opens holding
    // the user's own words, so a hint would never render at all — at exactly
    // the moment they most need to know what kind of answer is permitted.
    await t.pumpWidget(host(initialText: 'how do i bake bread', isReAsk: true));
    await t.pumpAndSettle();

    expect(find.text(DailyQuestionCopy.answerSetCaption), findsOneWidget);
  });

  testWidgets('VoiceOver reads the question as a header and the caption '
      'as part of the field', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(host());
    await t.pumpAndSettle();

    expect(
      find.bySemanticsLabel(DailyQuestionCopy.header),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(DailyQuestionCopy.answerSetCaption),
      findsAtLeastNWidgets(1),
    );
    expect(find.bySemanticsLabel(DailyQuestionCopy.defer), findsOneWidget);
    handle.dispose();
  });
}
