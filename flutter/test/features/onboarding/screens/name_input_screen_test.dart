import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/name_input_screen.dart';

void main() {
  testWidgets('continue enabled only after typing a name', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: NameInputScreen(onNext: () => advanced++, onBack: () {}),
      ),
    ));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(advanced, 0);

    await tester.enterText(find.byType(TextField), 'Ibrahim');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1);

    // Drain the autofocus timer scheduled by OnboardingAutofocusTextField.
    await tester.pump(const Duration(milliseconds: 400));
  });
}
