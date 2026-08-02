import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/widgets/hook_free_text_block.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';
import 'package:sakina/services/name_stories_service.dart';

import '_test_utils.dart';

/// The hook list is **seven feelings and one action** (founder, 2026-07-29).
///
/// This file used to pin the opposite: a hairline break above the "sign" row,
/// which was itself lighter and greyer than its six siblings. Both were attempts
/// to mark that row as the way out, and together they lifted it out of the list
/// into an "other" bucket sitting directly above the free-text link — another way
/// out. Two escape hatches stacked, reading as duplicates.
///
/// They were never duplicates. "I can't put it into words" means *I don't want
/// to type*; "Or describe it yourself…" means *I do*. They are opposites, so the
/// row belongs in the list as the seventh feeling and the link below is the only
/// escape. Neither needs a visual distinction, because they are already visibly
/// different kinds of thing.
///
/// What these tests defend is that nobody re-introduces one. The failure mode is
/// gradual: someone decides the row "recedes", makes it grey again, then adds a
/// rule to compensate — and the duplication is back.
void main() {
  ProblemChipResolver resolver() => ProblemChipResolver(
        stories: NameStoriesService(
          loadAsset: (_) async =>
              File(NameStoriesService.assetPath).readAsStringSync(),
        ),
      );

  Future<void> pumpScreen(WidgetTester tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: HookProblemScreen(
          onCommitted: (_) {},
          resolver: resolver(),
          commitBeat: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The row's own text style, as actually resolved by the widget tree.
  TextStyle styleOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style!;

  AnimatedOpacity fadeOn(WidgetTester tester, String label) =>
      tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );

  testWidgets('all seven rows share one text style — the sign row included',
      (tester) async {
    await pumpScreen(tester);

    final signChip = problemChips.firstWhere((c) => c.isSign);
    final reference = styleOf(tester, problemChips.first.label);

    for (final chip in problemChips) {
      final style = styleOf(tester, chip.label);
      expect(style.fontWeight, reference.fontWeight, reason: chip.chipKey);
      expect(style.color, reference.color, reason: chip.chipKey);
      expect(style.fontSize, reference.fontSize, reason: chip.chipKey);
    }

    // Stated outright, because these two exact values are what used to single
    // the row out.
    expect(styleOf(tester, signChip.label).fontWeight, FontWeight.w400);
    expect(
      styleOf(tester, signChip.label).color,
      isNot(equals(const Color(0xFF6B7280))),
      reason: 'textSecondaryLight on this row is the old "quieter ink" '
          'treatment — it is what made the row read as an other-bucket',
    );
  });

  testWidgets('the list draws one uniform rule ladder, with no break',
      (tester) async {
    await pumpScreen(tester);

    final cards = tester
        .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
        .toList();
    expect(cards.length, problemChips.length);

    for (var i = 0; i < cards.length; i++) {
      final isLast = i == cards.length - 1;
      expect(
        cards[i].showRule,
        !isLast,
        // Every row but the last carries a rule — including the one before the
        // sign row, which used to surrender its rule so the break could be a
        // single line with air on both sides.
        reason: 'row $i (${cards[i].chip.chipKey}) rule',
      );
    }
  });

  testWidgets('the free-text link does not echo the row above it',
      (tester) async {
    final signChip = problemChips.firstWhere((c) => c.isSign);
    expect(signChip.label, contains('words'));
    expect(
      HookFreeTextBlock.promptLabel,
      isNot(contains('words')),
      reason: 'the row keeps "words" — the sign reveal answers it directly in '
          'assets/content/name_stories.json — so the link must not repeat it',
    );
  });

  testWidgets(
      'the sign row recedes with the list once an answer is in flight',
      (tester) async {
    await pumpScreen(tester);

    final signChip = problemChips.firstWhere((c) => c.isSign);
    expect(fadeOn(tester, signChip.label).opacity, 1);

    await tester.tap(find.text(problemChips.first.label));
    await tester.pump();

    // Being an ordinary row now means it dims like one, so the screen resolves
    // to the single line the user chose.
    expect(
      fadeOn(tester, signChip.label).opacity,
      ProblemChipCard.unselectedFade,
    );
    expect(fadeOn(tester, problemChips.first.label).opacity, 1);

    await tester.pumpAndSettle();
  });
}
