import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/widgets/hook_screen_header.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';

/// Short screens must switch to the compact rhythm, so the seventh option —
/// "I can't put it into words" — stays above the fold.
///
/// **Why this matters (onboarding research, 2026-07-27).** NN/g eyetracking
/// puts >42% of viewing time in the top 20% of a screen, and content just
/// below the fold is viewed roughly half as often as content just above it.
/// That row is the escape hatch for the user who cannot name their state — the
/// highest preference-uncertainty user on the screen, and per the Chernev
/// choice-overload meta-analysis the one a dominant option exists to rescue.
/// If it drops below the fold on an iPhone SE, it fails precisely the people
/// it was built for.
///
/// **What this test can and cannot prove.** It asserts the compact METRICS are
/// applied at SE dimensions. It deliberately does not assert rendered pixel
/// fit: `flutter_test` draws every glyph as a full em square, so these labels
/// wrap about twice as much here as Outfit does on hardware, which makes any
/// measured height a fiction. Real fit is confirmed on a booted iPhone SE
/// simulator (see the W2 sim-pass record in the plan).
void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(top: 20),
          ),
          child: HookProblemScreen(
            onCommitted: (_) {},
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));
  }

  testWidgets('an iPhone SE viewport gets compact rows and a stepped-down '
      'question', (tester) async {
    await pumpAt(tester, const Size(375, 667));

    final rows = tester.widgetList<ProblemChipCard>(
      find.byType(ProblemChipCard),
    );
    expect(rows, isNotEmpty);
    for (final row in rows) {
      expect(row.rowHeight, ProblemChipCard.compactMinHeight,
          reason: 'SE rows must compact to 56pt to keep row 7 above the fold');
      expect(row.rowHeight, greaterThanOrEqualTo(44),
          reason: "compacting must never breach Apple's 44pt tap floor");
    }

    final header = tester.widget<HookScreenHeader>(
      find.byType(HookScreenHeader),
    );
    expect(header.compact, isTrue);
  });

  testWidgets('a modern phone keeps the roomy rhythm', (tester) async {
    await pumpAt(tester, const Size(393, 852)); // iPhone 15/17 Pro class

    final rows = tester.widgetList<ProblemChipCard>(
      find.byType(ProblemChipCard),
    );
    for (final row in rows) {
      expect(row.rowHeight, ProblemChipCard.minHeight);
    }
    expect(
      tester.widget<HookScreenHeader>(find.byType(HookScreenHeader)).compact,
      isFalse,
    );
  });
}
