import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/features/onboarding/content/help_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/help_chips_screen.dart';
import 'package:sakina/features/onboarding/widgets/intake_chip.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_continue_button.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-H §5 — the capped multi-select chip cloud.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    VoidCallback? onNext,
    VoidCallback? onBack,
    int? progressSegment,
    ProviderContainer? container,
    bool reduceMotion = false,
  }) async {
    useOnboardingViewport(tester);
    final scope = container ?? ProviderContainer();
    if (container == null) addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: HelpChipsScreen(
              onNext: onNext ?? () {},
              onBack: onBack,
              progressSegment: progressSegment,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scope;
  }

  IntakeChip chipFor(WidgetTester tester, String label) => tester
      .widgetList<IntakeChip>(find.byType(IntakeChip))
      .firstWhere((c) => c.label == label);

  testWidgets('renders the question, the cap copy and all seven chips',
      (tester) async {
    await pump(tester);

    expect(find.text(helpChipsQuestionLabel), findsOneWidget);
    expect(find.text(helpChipsSublineLabel), findsOneWidget);
    expect(find.byType(IntakeChip), findsNWidgets(helpChips.length));
    for (final chip in helpChips) {
      expect(find.text(chip.label), findsOneWidget, reason: chip.key);
    }
  });

  testWidgets('Continue is gated at one selection', (tester) async {
    var advanced = 0;
    await pump(tester, onNext: () => advanced++);

    expect(
      tester.widget<OnboardingContinueButton>(
        find.byType(OnboardingContinueButton),
      ),
      isA<OnboardingContinueButton>()
          .having((b) => b.enabled, 'enabled', isFalse),
    );
    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle();
    expect(advanced, 0);

    await tester.tap(find.text('Making sense of it'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<OnboardingContinueButton>(
        find.byType(OnboardingContinueButton),
      ),
      isA<OnboardingContinueButton>()
          .having((b) => b.enabled, 'enabled', isTrue),
    );
    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });

  testWidgets('records the selection in tap order', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.text('Strength to keep going'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Words to turn to'));
    await tester.pumpAndSettle();

    // Order is the blend's weighting input, so it must be the order tapped.
    expect(container.read(onboardingProvider).helpWith, ['strength', 'words']);
  });

  testWidgets('a fourth selection is refused without disturbing the first three',
      (tester) async {
    final container = await pump(tester);

    for (final label in const [
      'Words to turn to',
      'Making sense of it',
      'Something small each day',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(container.read(onboardingProvider).helpWith,
        ['words', 'sense', 'daily']);

    // At the cap the unselected chips recede and stop responding — the refusal
    // is legible before the tap, not a silent no-op after it.
    expect(chipFor(tester, 'Learning His Names').dimmed, isTrue);
    expect(chipFor(tester, 'Words to turn to').dimmed, isFalse);

    await tester.tap(find.text('Learning His Names'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).helpWith,
        ['words', 'sense', 'daily']);
  });

  testWidgets('a held chip can always be traded out at the cap',
      (tester) async {
    final container = await pump(tester);

    for (final label in const [
      'Words to turn to',
      'Making sense of it',
      'Something small each day',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Making sense of it'));
    await tester.pumpAndSettle();
    expect(container.read(onboardingProvider).helpWith, ['words', 'daily']);

    await tester.tap(find.text('Learning His Names'));
    await tester.pumpAndSettle();
    // Re-entering goes to the END of the order — the honest reading of what the
    // user just did.
    expect(container.read(onboardingProvider).helpWith,
        ['words', 'daily', 'names']);
  });

  testWidgets('shows a returning user their own selection', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier)
      ..toggleHelpWith('closer')
      ..toggleHelpWith('names');

    await pump(tester, container: container);

    final selected = tester
        .widgetList<IntakeChip>(find.byType(IntakeChip))
        .where((c) => c.selected)
        .map((c) => c.label)
        .toSet();
    expect(selected, {'Feeling closer to Allah', 'Learning His Names'});
  });

  testWidgets('reduce-motion flattens the chip stagger to a fade',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: HelpChipsScreen(onNext: _noop),
          ),
        ),
      ),
    );

    // Mid-stagger: with reduce-motion on there is no vertical travel to catch a
    // chip part-way through, so every chip sits at its final offset from the
    // first frame.
    await tester.pump(const Duration(milliseconds: 340));
    final offsets = tester
        .widgetList<IntakeChip>(find.byType(IntakeChip))
        .map((c) => tester.getTopLeft(find.byWidget(c)).dy)
        .toList();
    await tester.pumpAndSettle();
    final settled = tester
        .widgetList<IntakeChip>(find.byType(IntakeChip))
        .map((c) => tester.getTopLeft(find.byWidget(c)).dy)
        .toList();
    expect(offsets, settled);
  });

  testWidgets('no progress bar unless the caller supplies a segment',
      (tester) async {
    await pump(tester);
    expect(find.byType(OnboardingProgressBar), findsNothing);

    await pump(tester, onBack: () {}, progressSegment: 6);
    expect(find.byType(OnboardingProgressBar), findsOneWidget);
    expect(find.text(helpChipsQuestionLabel), findsOneWidget);
  });
}

void _noop() {}
