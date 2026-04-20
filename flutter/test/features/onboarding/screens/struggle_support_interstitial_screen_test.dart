import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/struggle_support_interstitial_screen.dart';

import '_test_utils.dart';

void main() {
  testWidgets('struggle support names a picked emotion', (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).toggleCommonEmotion('anxious');

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
    expect(find.textContaining('anxious'), findsOneWidget);
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
