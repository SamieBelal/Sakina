import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/hook_problem_screen.dart';
import 'package:sakina/features/onboarding/widgets/hook_free_text_block.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_page_wrapper.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_progress_bar.dart';
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

  testWidgets('renders the question, the promise line and all 7 options',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text("What's weighing on you right now?"), findsOneWidget);
    // The promise line replaced "Take your time." on 2026-07-27: a first-time
    // user meets the most exposing question in the app here, and this is the
    // only thing on screen telling them what happens after they tap.
    expect(
      find.text("Whatever it is, there's a Name of Allah for it."),
      findsOneWidget,
    );
    expect(find.byType(ProblemChipCard), findsNWidgets(7));
    for (final chip in problemChips) {
      expect(find.text(chip.label), findsOneWidget, reason: chip.chipKey);
    }
  });

  testWidgets('no progress bar and no illustration on this screen',
      (tester) async {
    await pumpScreen(tester);

    // Spec ③: a step counter on screen one manufactures hurry. Assert against
    // the widgets this screen would actually have used — a bare
    // LinearProgressIndicator was never on the table, so pinning that was
    // pinning nothing.
    expect(find.byType(OnboardingProgressBar), findsNothing);
    expect(find.byType(OnboardingPageWrapper), findsNothing,
        reason: 'the wrapper always renders the progress bar');
    // Spec ④: no illustration. The onboarding art is SVG, so `Image` alone
    // could never have caught one.
    expect(find.byType(SvgPicture), findsNothing);
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

  /// The card's own minimum-height constraint — the thing that guarantees the
  /// tap target, rather than whatever the current label happens to measure.
  BoxConstraints cardConstraints(WidgetTester tester, ProblemChip chip) {
    final card = find.ancestor(
      of: find.text(chip.label),
      matching: find.byType(ProblemChipCard),
    );
    return tester
        .widget<AnimatedContainer>(
          find.descendant(of: card, matching: find.byType(AnimatedContainer)),
        )
        .constraints!;
  }

  testWidgets('every card is at least 64pt tall (44pt HIG minimum cleared)',
      (tester) async {
    await pumpScreen(tester);

    expect(ProblemChipCard.minHeight, greaterThanOrEqualTo(64));
    for (final chip in problemChips) {
      final size = tester.getSize(find.text(chip.label).hitTestable());
      expect(size.width, greaterThan(200), reason: '${chip.chipKey} full-width');
      final constraints = cardConstraints(tester, chip);
      expect(constraints.minHeight, greaterThanOrEqualTo(64),
          reason: chip.chipKey);
      expect(constraints.maxHeight, double.infinity,
          reason: '${chip.chipKey}: a minimum, never a fixed box');
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

  testWidgets('empty typed text cannot commit — the Continue slot is inert',
      (tester) async {
    final committed = await pumpScreen(tester);

    await openFreeText(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();

    // Reserved rather than absent: the 44pt slot is laid out from the start so
    // the field does not jump under the user's thumb on the first keystroke.
    final submit = find.text(HookFreeTextBlock.submitLabel);
    expect(submit, findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(of: submit, matching: find.byType(AnimatedOpacity))
                .first,
          )
          .opacity,
      0,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(of: submit, matching: find.byType(IgnorePointer))
                .first,
          )
          .ignoring,
      isTrue,
    );

    await tester.tap(submit, warnIfMissed: false);
    await tester.pumpAndSettle();
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
        // copyWith, not a fresh MediaQueryData: replacing the whole thing drops
        // the viewport, padding and device pixel ratio the rest of the screen
        // lays out against, so the test would be measuring a phantom device.
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
            child: HookProblemScreen(
              onCommitted: (_) {},
              resolver: resolver(),
              commitBeat: Duration.zero,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // No overflow exception, and the cards grew with the type rather than
    // clipping it (the list is lazy, so only the visible ones are built).
    expect(tester.takeException(), isNull);
    expect(find.byType(ProblemChipCard), findsAtLeastNWidgets(1));
    final card = find.byType(ProblemChipCard).first;
    final constraints = tester
        .widget<AnimatedContainer>(
          find.descendant(of: card, matching: find.byType(AnimatedContainer)),
        )
        .constraints!;
    expect(constraints.minHeight, greaterThanOrEqualTo(64),
        reason: 'still a floor, not a ceiling');
    expect(constraints.maxHeight, double.infinity);
    expect(tester.getSize(card).height, greaterThan(constraints.minHeight),
        reason: 'the doubled label grew the card past its floor');
  });

  testWidgets(
      'a failed deck lookup still commits, and the next tap resolves for real',
      (tester) async {
    useOnboardingViewport(tester);
    var failNext = true;
    final committed = <ChipSelection>[];
    await tester.pumpWidget(
      MaterialApp(
        home: HookProblemScreen(
          onCommitted: committed.add,
          commitBeat: Duration.zero,
          resolver: ProblemChipResolver(
            stories: NameStoriesService(
              loadAsset: (_) async {
                if (failNext) {
                  failNext = false;
                  throw const FileSystemException('asset unavailable');
                }
                return File(NameStoriesService.assetPath).readAsStringSync();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("My mind won't stop racing"));
    await tester.pumpAndSettle();

    // Tap 1: no pair, but everything the tap itself said survives, and no
    // exception escapes to the framework.
    expect(tester.takeException(), isNull);
    expect(committed, hasLength(1));
    expect(committed.single.chipKey, 'anxiety');
    expect(committed.single.contract, HookContract.problem);
    expect(committed.single.hookType, HookType.chip);
    expect(committed.single.pairNameIds, isEmpty,
        reason: 'the reveal reads an empty pair as the comfort fallback');

    // Tap 2: the guard was released, so the screen is not dead-ended.
    await tester.tap(find.text('Everything feels heavy'));
    await tester.pumpAndSettle();

    expect(committed, hasLength(2));
    expect(committed.last.chipKey, 'heavy');
    expect(committed.last.pairNameIds, hasLength(2));
  });
}
