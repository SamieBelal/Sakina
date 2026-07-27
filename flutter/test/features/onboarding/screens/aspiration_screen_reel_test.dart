import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/aspirations.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/aspiration_screen_reel.dart';
import 'package:sakina/features/onboarding/widgets/reel_option_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-D1b — the aspiration question, in both registers.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String? contract,
    VoidCallback? onNext,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (contract != null) {
      container.read(onboardingProvider.notifier).applyHookSelection(
            ChipSelection(
              contract: contract,
              problemCategory: 'unspoken',
              hookType: HookType.chip,
              pairNameIds: const [2, 47],
              chipKey: contract == HookContract.sign ? 'sign' : 'anxiety',
            ),
          );
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AspirationScreenReel(
            onNext: onNext ?? () {},
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('problem contract gets the problem register', (tester) async {
    await pump(tester, contract: HookContract.problem);

    expect(find.text(aspirationQuestionLabel), findsOneWidget);
    expect(find.text(aspirationQuestionSignLabel), findsNothing);
    expect(find.byType(ReelOptionCard), findsNWidgets(aspirations.length));
    for (final aspiration in aspirations) {
      expect(find.text(aspiration.label), findsOneWidget,
          reason: aspiration.key);
      expect(find.text(aspiration.signLabel), findsNothing,
          reason: aspiration.key);
    }
  });

  testWidgets('sign contract gets the sign register, same keys',
      (tester) async {
    final container = await pump(tester, contract: HookContract.sign);

    expect(find.text(aspirationQuestionSignLabel), findsOneWidget);
    expect(find.text(aspirationQuestionLabel), findsNothing);
    for (final aspiration in aspirations) {
      expect(find.text(aspiration.signLabel), findsOneWidget,
          reason: aspiration.key);
    }

    // The register changes the words, never the Names.
    await tester.tap(find.text(aspirations.first.signLabel));
    await tester.pumpAndSettle();
    expect(
        container.read(onboardingProvider).aspiration, aspirations.first.key);
  });

  testWidgets('an unanswered hook still renders the problem register',
      (tester) async {
    await pump(tester);

    expect(find.text(aspirationQuestionLabel), findsOneWidget);
  });

  testWidgets('a single tap commits the key and advances once', (tester) async {
    var advanced = 0;
    final container = await pump(
      tester,
      contract: HookContract.problem,
      onNext: () => advanced++,
    );

    await tester.tap(find.text('To carry less noise inside'));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).aspiration, 'peace');
    expect(advanced, 1);
    // The answer is what fills queue rows 3-7.
    expect(aspirationQueueNameIds('peace'), hasLength(5));
  });

  testWidgets('pre-selects the stored answer', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setAspiration('guidance');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AspirationScreenReel(
            onNext: () {},
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<ReelOptionCard>(find.byType(ReelOptionCard))
        .where((card) => card.selected)
        .toList();
    expect(selected, hasLength(1));
    expect(selected.single.label, aspirationsByKey['guidance']!.label);
  });
}
