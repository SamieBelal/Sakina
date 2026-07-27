import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/widgets/hook_free_text_block.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';
import 'package:sakina/services/name_stories_service.dart';

import '_test_utils.dart';

/// One Ship W2-B2 — the hook screen against the founder-approved UX spec.
///
/// Note on geometry: `flutter_test` renders every glyph as a full em square, so
/// the sentence labels wrap far more here than in Outfit on a device and the
/// list overflows a 390×844 viewport. That is why the free-text affordance is
/// scrolled into view before it is tapped — it is not below the fold in
/// production.
void main() {
  /// The demoted free-text link sits under the cards; reveal it before tapping.
  Future<void> openFreeText(WidgetTester tester) async {
    await tester.ensureVisible(find.text(HookFreeTextBlock.promptLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(HookFreeTextBlock.promptLabel));
    await tester.pumpAndSettle();
  }

  ProblemChipResolver resolver() => ProblemChipResolver(
        stories: NameStoriesService(
          loadAsset: (_) async =>
              File(NameStoriesService.assetPath).readAsStringSync(),
        ),
      );

  Future<List<ChipSelection>> pumpScreen(WidgetTester tester) async {
    useOnboardingViewport(tester);
    final committed = <ChipSelection>[];
    await tester.pumpWidget(
      MaterialApp(
        home: HookProblemScreen(
          onCommitted: committed.add,
          resolver: resolver(),
          commitBeat: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return committed;
  }

  testWidgets('renders the approved header, subline and all 7 cards',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text("What's weighing on you right now?"), findsOneWidget);
    expect(find.text('Take your time.'), findsOneWidget);
    expect(find.byType(ProblemChipCard), findsNWidgets(7));
    for (final chip in problemChips) {
      expect(find.text(chip.label), findsOneWidget, reason: chip.chipKey);
    }
  });

  testWidgets('no progress bar and no illustration on this screen',
      (tester) async {
    await pumpScreen(tester);

    // Spec ③: a step counter on screen one manufactures hurry.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    // Spec ④: the illustration is replaced by a small ornament.
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the sign card is last and quieter, on the same surface',
      (tester) async {
    await pumpScreen(tester);

    final cards = tester
        .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
        .toList();
    expect(cards.last.chip.chipKey, 'sign');
    expect(cards.last.chip.contract, HookContract.sign);

    TextStyle styleOf(String label) =>
        tester.widget<Text>(find.text(label)).style!;
    final sign = styleOf(cards.last.chip.label);
    final problem = styleOf(cards.first.chip.label);
    expect(sign.fontWeight, FontWeight.w300);
    expect(problem.fontWeight, FontWeight.w400);
    expect(sign.fontSize, problem.fontSize,
        reason: 'distinction is weight/ink only — not size');
  });

  testWidgets('every card is at least 64pt tall (44pt HIG minimum cleared)',
      (tester) async {
    await pumpScreen(tester);

    for (final chip in problemChips) {
      final size = tester.getSize(find.text(chip.label).hitTestable());
      expect(size.width, greaterThan(200), reason: '${chip.chipKey} full-width');
      final card = tester.getSize(
        find.ancestor(
          of: find.text(chip.label),
          matching: find.byType(ProblemChipCard),
        ),
      );
      expect(card.height, greaterThanOrEqualTo(ProblemChipCard.minHeight),
          reason: chip.chipKey);
    }
  });

  testWidgets('tap commits once with the chip pair, and ignores double taps',
      (tester) async {
    final committed = await pumpScreen(tester);

    await tester.tap(find.text("My mind won't stop racing"));
    await tester.pump();
    // Second tap lands during the beat — it must be swallowed.
    await tester.tap(find.text('Everything feels heavy'));
    await tester.pumpAndSettle();

    expect(committed, hasLength(1));
    expect(committed.single.chipKey, 'anxiety');
    expect(committed.single.contract, HookContract.problem);
    expect(committed.single.hookType, HookType.chip);
    expect(committed.single.pairNameIds, [6, 35]);
  });

  testWidgets('the tapped card shows the selected emerald tint',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('I feel far from Allah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final selected = tester
        .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
        .where((c) => c.selected)
        .toList();
    expect(selected, hasLength(1));
    expect(selected.single.chip.chipKey, 'far-from-allah');
  });

  testWidgets('a pre-selected chip (deep link) starts selected', (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: HookProblemScreen(
          onCommitted: (_) {},
          resolver: resolver(),
          initialChipKey: 'rizq',
          commitBeat: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<ProblemChipCard>(find.byType(ProblemChipCard))
        .where((c) => c.selected);
    expect(selected.single.chip.chipKey, 'rizq');
  });

  testWidgets('expanding free text never hides the cards', (tester) async {
    await pumpScreen(tester);

    expect(find.text(HookFreeTextBlock.promptLabel), findsOneWidget);
    await openFreeText(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ProblemChipCard), findsNWidgets(7));
    for (final chip in problemChips) {
      expect(find.text(chip.label), findsOneWidget, reason: chip.chipKey);
    }
  });

  testWidgets('typed text commits through the keyword map', (tester) async {
    final committed = await pumpScreen(tester);

    await openFreeText(tester);
    await tester.enterText(find.byType(TextField), 'my exams start monday');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(HookFreeTextBlock.submitLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(HookFreeTextBlock.submitLabel));
    await tester.pumpAndSettle();

    expect(committed, hasLength(1));
    expect(committed.single.hookType, HookType.freeText);
    expect(committed.single.chipKey, 'anxiety');
    expect(committed.single.problemTextRaw, 'my exams start monday');
  });

  testWidgets('empty typed text cannot commit', (tester) async {
    final committed = await pumpScreen(tester);

    await openFreeText(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();

    expect(find.text(HookFreeTextBlock.submitLabel), findsNothing);
    expect(committed, isEmpty);
  });

  testWidgets('VoiceOver reads the full sentence on every card', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);

    for (final chip in problemChips) {
      expect(
        find.bySemanticsLabel(chip.label),
        findsOneWidget,
        reason: chip.chipKey,
      );
    }
    expect(
      find.bySemanticsLabel(HookFreeTextBlock.promptLabel),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('cards survive a large Dynamic Type setting', (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: HookProblemScreen(
            onCommitted: (_) {},
            resolver: resolver(),
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No overflow exception, and the cards grew with the type rather than
    // clipping it (the list is lazy, so only the visible ones are built).
    expect(tester.takeException(), isNull);
    expect(find.byType(ProblemChipCard), findsAtLeastNWidgets(1));
    final first = tester.getSize(find.byType(ProblemChipCard).first);
    expect(first.height, greaterThan(ProblemChipCard.minHeight));
  });
}
