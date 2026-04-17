import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/personalized_plan_screen.dart';

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

  testWidgets('renders selected resonant Name when set', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setResonantNameId('as-salam');
    container.read(onboardingProvider.notifier).toggleStruggle('anxiety');

    await tester.pumpWidget(harness(container));

    expect(find.textContaining('As-Salam'), findsOneWidget);
    // fallback text should NOT appear
    expect(find.textContaining('Ar-Rahman'), findsNothing);
  });

  testWidgets('falls back to Ar-Rahman when resonantNameId is null',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));

    expect(find.textContaining('Ar-Rahman'), findsOneWidget);
  });

  testWidgets('plan card renders commitment minutes, reminder time, intention',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingProvider.notifier);
    notifier.setResonantNameId('al-wadud');
    notifier.setDailyCommitmentMinutes(5);
    notifier.setReminderTime('07:30');
    notifier.setIntention('spiritual-growth');
    notifier.toggleStruggle('loneliness');

    await tester.pumpWidget(harness(container));

    // Commitment + reminder rendered together
    expect(find.textContaining('5 min'), findsOneWidget);
    expect(find.textContaining('07:30'), findsOneWidget);
    // Intention phrase rendered
    expect(find.textContaining('spiritual-growth'), findsOneWidget);
    // Struggle rendered
    expect(find.text('loneliness'), findsOneWidget);
    // Name translit rendered
    expect(find.textContaining('Al-Wadud'), findsOneWidget);
  });

  testWidgets('continue is always enabled (reveal screen)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;

    await tester.pumpWidget(harness(container, onNext: () => advanced++));

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });

  test('translitForId maps known ids and falls back to Ar-Rahman', () {
    expect(PersonalizedPlanScreen.translitForId('ar-rahman'), 'Ar-Rahman');
    expect(PersonalizedPlanScreen.translitForId('ar-rahim'), 'Ar-Rahim');
    expect(PersonalizedPlanScreen.translitForId('as-salam'), 'As-Salam');
    expect(PersonalizedPlanScreen.translitForId('al-wadud'), 'Al-Wadud');
    expect(PersonalizedPlanScreen.translitForId('al-hafiz'), 'Al-Hafiz');
    expect(PersonalizedPlanScreen.translitForId('al-karim'), 'Al-Karim');
    expect(PersonalizedPlanScreen.translitForId(null), 'Ar-Rahman');
    expect(PersonalizedPlanScreen.translitForId('unknown'), 'Ar-Rahman');
  });
}
