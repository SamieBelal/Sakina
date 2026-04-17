import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/social_proof_interstitial_screen.dart';

void main() {
  testWidgets('social proof interstitial shows count + continue advances',
      (tester) async {
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
    expect(find.textContaining('40,000'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);
  });
}
