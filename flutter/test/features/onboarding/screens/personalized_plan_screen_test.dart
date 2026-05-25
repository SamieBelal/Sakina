import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/personalized_plan_screen.dart';

import '_test_utils.dart';

void main() {
  Widget harness(ProviderContainer container,
      {VoidCallback? onNext, VoidCallback? onBack}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PersonalizedPlanScreen(
          onNext: onNext ?? () {},
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders selected starter Name when set', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 6 = As-Salam in collectible_names catalog.
    container.read(onboardingProvider.notifier).setStarterName(6);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('As-Salam'), findsOneWidget);
    // Fallback should NOT appear when a specific starter is set.
    expect(find.textContaining('Ar-Rahman'), findsNothing);
  });

  testWidgets('falls back to Ar-Rahman when starterNameId is null',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ar-Rahman'), findsOneWidget);
  });

  testWidgets('plan card renders commitment minutes, reminder time, intention',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingProvider.notifier);
    // 28 = Ash-Shakur in catalog.
    notifier.setStarterName(28);
    notifier.setDailyCommitmentMinutes(5);
    notifier.setReminderTime('07:30');
    notifier.setIntention('spiritual-growth');

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    // Commitment + reminder rendered together.
    expect(find.textContaining('5 min'), findsOneWidget);
    expect(find.textContaining('07:30'), findsOneWidget);
    // Intention phrase rendered.
    expect(find.textContaining('spiritual-growth'), findsOneWidget);
    // Trimmed-flow refactor (2026-05-25): commonEmotions removed; the
    // "You often feel" tile now always shows the fallback copy.
    expect(find.text('Whatever comes up'), findsOneWidget);
    // Name translit rendered.
    expect(find.textContaining('Ash-Shakur'), findsOneWidget);
  });

  testWidgets('continue is always enabled (reveal screen)', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;

    await tester.pumpWidget(harness(container, onNext: () => advanced++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });

  testWidgets('renders gold "Crafted for you" ribbon at top', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('✨ Crafted for you'), findsOneWidget);
  });

  testWidgets('uses Scaffold (no OnboardingQuestionScaffold)', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    // The screen should NOT contain an onboarding progress bar segment.
    // Tested indirectly: no LinearProgressIndicator should be in the tree.
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  test('translitForCatalogId maps known ids and falls back to Ar-Rahman', () {
    expect(PersonalizedPlanScreen.translitForCatalogId(2), 'Ar-Rahman');
    expect(PersonalizedPlanScreen.translitForCatalogId(6), 'As-Salam');
    expect(PersonalizedPlanScreen.translitForCatalogId(9), 'Al-Jabbar');
    expect(PersonalizedPlanScreen.translitForCatalogId(28), 'Ash-Shakur');
    expect(PersonalizedPlanScreen.translitForCatalogId(32), 'As-Sabur');
    expect(PersonalizedPlanScreen.translitForCatalogId(33), 'Al-Hadi');
    expect(PersonalizedPlanScreen.translitForCatalogId(35), 'Al-Wakeel');
    expect(PersonalizedPlanScreen.translitForCatalogId(null), 'Ar-Rahman');
    expect(PersonalizedPlanScreen.translitForCatalogId(99999), 'Ar-Rahman');
  });
}
