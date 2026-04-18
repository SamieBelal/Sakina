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
    expect(container.read(onboardingProvider).reminderTime, isNotNull);
    expect(advanced, 1);
  });
}
