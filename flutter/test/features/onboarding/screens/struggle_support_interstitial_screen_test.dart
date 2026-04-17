import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/struggle_support_interstitial_screen.dart';

void main() {
  testWidgets('struggle support names a picked struggle', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).toggleStruggle('anxiety');

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
    expect(find.textContaining('anxiety'), findsOneWidget);
  });

  testWidgets('struggle support continue advances', (tester) async {
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
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
