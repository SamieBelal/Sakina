import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';
import 'package:sakina/services/name_stories_service.dart';

import '_test_utils.dart';

/// Wave H 🟡 — the break above the sign row (2026-07-29).
///
/// The escape hatch stays LAST: reading the six problem chips does real
/// diagnostic work and one of them usually lands. What changed is that it is no
/// longer distinguished by typography alone, which made it recede exactly when
/// it should read as an obvious way out. These pin the break itself — air plus
/// ONE hairline, no tinted surface (rejected 2026-07-25: a tint reads as
/// pre-selected, and the selected state IS an emerald tint).
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

  testWidgets('draws exactly one break, and it sits above the sign row',
      (tester) async {
    await pumpScreen(tester);

    final separator = find.byKey(HookProblemScreen.signSeparatorKey);
    expect(separator, findsOneWidget);

    final signChip = problemChips.firstWhere((c) => c.isSign);
    expect(
      tester.getBottomLeft(separator).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text(signChip.label)).dy),
      reason: 'the break must introduce the sign row, not follow it',
    );
  });

  testWidgets('the row above the sign row gives up its own rule',
      (tester) async {
    await pumpScreen(tester);

    final cards = tester
        .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
        .toList();
    expect(cards.length, problemChips.length);

    for (var i = 0; i < cards.length; i++) {
      final isLast = i == cards.length - 1;
      final nextIsSign = !isLast && cards[i + 1].chip.isSign;
      expect(
        cards[i].showRule,
        !isLast && !nextIsSign,
        // Otherwise the break is two hairlines 8px apart instead of one line
        // with air on both sides.
        reason: 'row $i (${cards[i].chip.chipKey}) rule',
      );
    }
  });

  testWidgets('the break recedes with the list once an answer is in flight',
      (tester) async {
    await pumpScreen(tester);

    final separator = find.byKey(HookProblemScreen.signSeparatorKey);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: separator,
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      1,
    );

    await tester.tap(find.text(problemChips.first.label));
    await tester.pump();

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: separator,
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      ProblemChipCard.unselectedFade,
      reason: 'a rule left at full strength is the one thing still glowing on '
          'a screen that should resolve to the chosen line',
    );

    await tester.pumpAndSettle();
  });
}
