import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/reminder_time_screen.dart';

import '_test_utils.dart';

void main() {
  testWidgets('defaults to 08:00 and continue enabled', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final value = container.read(onboardingProvider).reminderTime;
    expect(value, isNotNull);
    expect(value, equals('08:00'));
    expect(advanced, 1);
  });

  testWidgets('pre-seeded half-hour value is normalized to whole hour on persist',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Pre-seed a half-hour value to simulate a corrupt or migrated row
    // from a pre-fix build.
    container.read(onboardingProvider.notifier).setReminderTime('08:30');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Both initState and onContinue clamp minute to 0. Even though the
    // user never touched the picker, the pre-seeded '08:30' is
    // normalized to '08:00' before persistence — the server cron and
    // the persisted value now agree on the hour.
    final value = container.read(onboardingProvider).reminderTime;
    expect(value, equals('08:00'));
  });

  testWidgets('picker enforces minuteInterval = 60', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ReminderTimeScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.minuteInterval, 60);
  });
}
