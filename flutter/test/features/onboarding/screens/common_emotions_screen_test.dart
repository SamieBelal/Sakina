import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/common_emotions_screen.dart';

// Trimmed-flow refactor (2026-05-25, Option α): the commonEmotions field
// was removed from OnboardingState. The legacy screen is now stateless and
// Continue is always enabled. PR-2b will delete this screen + test.
void main() {
  testWidgets('legacy common emotions screen advances on Continue (stateless)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var advanced = 0;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: CommonEmotionsScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));

    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 1);
  });
}
