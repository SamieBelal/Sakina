import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/resonant_name_screen.dart';

import '_test_utils.dart';

void main() {
  testWidgets('tapping a name sets it and enables continue', (tester) async {
    useOnboardingViewport(tester);
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
    // Breathing halo uses `.animate(onPlay: (c) => c.repeat(reverse: true))`
    // which never settles. Pump a few frames to let entrance animations
    // resolve, then exercise the screen without pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Ar-Rahman').first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(onboardingProvider).resonantNameId, 'ar-rahman');
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(advanced, 1);
    // Unmount so the repeating animation controller is disposed before
    // teardown asserts on pending timers.
    await tester.pumpWidget(const SizedBox());
  });
}
