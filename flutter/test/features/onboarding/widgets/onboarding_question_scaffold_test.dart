import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_question_scaffold.dart';

void main() {
  testWidgets('renders headline, subtitle, body and a disabled continue button',
      (tester) async {
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingQuestionScaffold(
        progressSegment: 5,
        headline: 'How often do you pray?',
        subtitle: 'No judgement.',
        body: const Text('BODY'),
        continueEnabled: false,
        onContinue: () => continued++,
        onBack: () {},
      ),
    ));
    expect(find.text('How often do you pray?'), findsOneWidget);
    expect(find.text('No judgement.'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    // Tapping the disabled continue should do nothing.
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await tester.pump();
    expect(continued, 0);
  });

  testWidgets('continue button fires when enabled', (tester) async {
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingQuestionScaffold(
        progressSegment: 5,
        headline: 'H',
        body: const SizedBox(),
        continueEnabled: true,
        onContinue: () => continued++,
        onBack: () {},
      ),
    ));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(continued, 1);
  });
}
