import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_autofocus_text_field.dart';

void main() {
  testWidgets('autocorrect and enableSuggestions default to true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingAutofocusTextField(
            controller: TextEditingController(),
            shouldRequestFocus: false,
            decoration: const InputDecoration(),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autocorrect, isTrue);
    expect(field.enableSuggestions, isTrue);
  });

  testWidgets('autocorrect and enableSuggestions pass through when false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingAutofocusTextField(
            controller: TextEditingController(),
            shouldRequestFocus: false,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autocorrect, isFalse,
        reason: 'auth fields must disable autocorrect (F3)');
    expect(field.enableSuggestions, isFalse,
        reason: 'auth fields must disable suggestions (F3)');
  });
}
