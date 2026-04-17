import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/resonant_name_screen.dart';

void main() {
  testWidgets('tapping a name sets it and enables continue', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ResonantNameScreen(
          onNext: () => advanced++,
          onBack: () {},
        ),
      ),
    ));
    await tester.tap(find.text('Ar-Rahman').first);
    await tester.pump();
    expect(container.read(onboardingProvider).resonantNameId, 'ar-rahman');
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
  });
}
