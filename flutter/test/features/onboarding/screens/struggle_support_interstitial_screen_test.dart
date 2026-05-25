import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/struggle_support_interstitial_screen.dart';

import '_test_utils.dart';

// Trimmed-flow refactor (2026-05-25, Option α): the commonEmotions field
// was removed from OnboardingState. The legacy screen now renders only the
// generic fallback copy. PR-2b will delete this screen + test.
void main() {
  testWidgets('legacy struggle support renders generic fallback (stateless)',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StruggleSupportInterstitialScreen(
            onNext: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining("what you're carrying"), findsOneWidget);
  });

  testWidgets('struggle support continue advances', (tester) async {
    useOnboardingViewport(tester);
    var advanced = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StruggleSupportInterstitialScreen(
            onNext: () => advanced++,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });
}
