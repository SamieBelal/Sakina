import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/daily_commitment_screen.dart';

import '_test_utils.dart';

void main() {
  testWidgets('picking 5 minutes enables continue', (tester) async {
    useOnboardingViewport(tester);
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: DailyCommitmentScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(advanced, 1);
  });
}
