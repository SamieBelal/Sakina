import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets(
      'F-07: input sits under the prompt; flexible space is below it, not above',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: NameInputScreen(onNext: () {}, onBack: () {}),
      ),
    ));
    await tester.pump();

    final subtitleBottom =
        tester.getBottomLeft(find.text('Just your first name.')).dy;
    final fieldTop = tester.getTopLeft(find.byType(TextField)).dy;
    final fieldBottom = tester.getBottomLeft(find.byType(TextField)).dy;
    final continueTop = tester.getTopLeft(find.text('Continue')).dy;

    final gapAboveField = fieldTop - subtitleBottom;
    final gapBelowField = continueTop - fieldBottom;

    // Before F-07 a leading Spacer shoved the field to the bottom, leaving a
    // large blank area up top. The fix puts the field directly under the
    // prompt (small fixed gap) and moves the flexible space below it.
    expect(gapAboveField, greaterThan(0));
    expect(gapBelowField, greaterThan(gapAboveField * 2),
        reason: 'F-07: the flexible blank space must sit BELOW the input, not '
            'above it — the input should hug the prompt, not the Continue button.');

    // Drain the autofocus timer.
    await tester.pump(const Duration(milliseconds: 400));
  });
}
