import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/social_proof_interstitial_screen.dart';

import '_test_utils.dart';

void main() {
  testWidgets('social proof interstitial shows count + continue advances',
      (tester) async {
    useOnboardingViewport(tester);
    var advanced = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SocialProofInterstitialScreen(
            onNext: () => advanced++,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('10,000'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });
}
