import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';

void main() {
  Widget harness(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PaywallScreen(onComplete: () {}),
      ),
    );
  }

  testWidgets('paywall headline references top aspiration and commitment',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingProvider.notifier)
        .toggleAspiration('closerToAllah');
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('closer to Allah'), findsOneWidget);
    expect(find.textContaining('5 min'), findsOneWidget);
  });

  testWidgets('different intention -> different headline (morePatient)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingProvider.notifier)
        .toggleAspiration('morePatient');
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(3);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(find.textContaining('more patient'), findsOneWidget);
    expect(find.textContaining('3 min'), findsOneWidget);
  });

  testWidgets('fallback headline when no aspiration selected', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(harness(container));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('the person you want to be'),
      findsOneWidget,
    );
    // Default commitment fallback.
    expect(find.textContaining('3 min'), findsOneWidget);
  });
}
