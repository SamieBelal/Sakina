import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/your_journey_screen.dart';

import '_test_utils.dart';

void main() {
  Widget harness(ProviderContainer container,
      {VoidCallback? onNext, VoidCallback? onBack}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: YourJourneyScreen(
          onNext: onNext ?? () {},
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders headline with signUpName', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setSignUpName('Sara');

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text("Where you'll be in 30 days, Sara."), findsOneWidget);
  });

  testWidgets('falls back to "friend" when signUpName is null', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text("Where you'll be in 30 days, friend."), findsOneWidget);
  });

  testWidgets('Day 1 milestone uses starterNameId via translit', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 6 = As-Salam in collectible_names catalog.
    container.read(onboardingProvider.notifier).setStarterName(6);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(
      find.text('As-Salam — your first Name in the collection'),
      findsOneWidget,
    );
  });

  testWidgets('Day 1 milestone falls back to Ar-Rahman when starterNameId is null',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(
      find.text('Ar-Rahman — your first Name in the collection'),
      findsOneWidget,
    );
  });

  testWidgets('footer line uses dailyCommitmentMinutes', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Built on 5 minutes a day.'), findsOneWidget);
  });

  testWidgets('footer line falls back to 3 minutes when minutes is null',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Built on 3 minutes a day.'), findsOneWidget);
  });

  testWidgets('CTA copy is "Begin my 30 days"', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Begin my 30 days'), findsOneWidget);
  });

  testWidgets('CTA tap fires onNext', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;

    await tester.pumpWidget(harness(container, onNext: () => advanced++));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Begin my 30 days'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });

  testWidgets('renders 3 day-labeled milestones in order', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.text('Day 1 — Today'), findsOneWidget);
    expect(find.text('Day 7 — One week in'), findsOneWidget);
    expect(find.text('Day 30 — One month'), findsOneWidget);
  });
}
