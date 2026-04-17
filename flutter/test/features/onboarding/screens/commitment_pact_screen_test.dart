import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/commitment_pact_screen.dart';

void main() {
  testWidgets('includes reminder clause when notifications granted',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingProvider.notifier)
        .setNotificationPermission(true);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);
    container.read(onboardingProvider.notifier).setReminderTime('08:00');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CommitmentPactScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('reminder'), findsOneWidget);
  });

  testWidgets('omits reminder clause when notifications denied',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(onboardingProvider.notifier)
        .setNotificationPermission(false);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(5);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CommitmentPactScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    expect(find.textContaining('reminder'), findsNothing);
  });

  testWidgets('tapping commit enables continue', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setDailyCommitmentMinutes(3);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CommitmentPactScreen(onNext: () {}, onBack: () {}),
      ),
    ));

    expect(container.read(onboardingProvider).commitmentAccepted, isFalse);
    await tester.tap(find.text('Tap to commit'));
    await tester.pump();
    expect(container.read(onboardingProvider).commitmentAccepted, isTrue);
  });
}
