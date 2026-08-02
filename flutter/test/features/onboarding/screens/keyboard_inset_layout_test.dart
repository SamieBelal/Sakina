import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/intake_note_screen.dart';
import 'package:sakina/features/onboarding/screens/name_input_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_email_screen.dart';
import 'package:sakina/features/onboarding/screens/sign_up_password_screen.dart';

import '_test_utils.dart';

/// Keyboard-open layout for every text-entry screen in the reel flow.
///
/// The iOS Simulator on this machine refuses to raise the software keyboard, so
/// the founder's "does anything get cut off when the keyboard is up?" question
/// cannot be answered by screenshot. It can be answered here, and more strictly:
/// a `RenderFlex` overflow throws during `pump`, so an overflowing screen fails
/// the test rather than merely looking wrong in a picture.
///
/// The keyboard is simulated the way the framework itself sees one — a bottom
/// `viewInsets` on the test view — which is exactly what `resizeToAvoidBottom
/// Inset` consumes.
void main() {
  /// A ~336pt iOS keyboard at DPR 3, matching an iPhone 17 Pro.
  const double keyboardLogical = 336;

  void raiseKeyboard(TestFlutterView view) {
    view.viewInsets = FakeViewPadding(bottom: keyboardLogical * 3);
    addTearDown(view.resetViewInsets);
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    useOnboardingViewport(tester);
    raiseKeyboard(tester.view);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// Every finder must sit fully inside the area the keyboard leaves behind.
  void expectAboveKeyboard(WidgetTester tester, Finder finder, String label) {
    final screenHeight = tester.view.physicalSize.height / 3;
    final safeBottom = screenHeight - keyboardLogical;
    final rect = tester.getRect(finder);
    expect(
      rect.bottom,
      lessThanOrEqualTo(safeBottom),
      reason: '$label is behind the keyboard '
          '(bottom ${rect.bottom.toStringAsFixed(1)} > '
          'available ${safeBottom.toStringAsFixed(1)})',
    );
  }

  testWidgets('H7 note: field and Continue stay above the keyboard',
      (tester) async {
    await pumpScreen(
      tester,
      IntakeNoteScreen(
        onNext: () {},
        onBack: () {},
        progressSegment: 8,
        totalSegments: 14,
      ),
    );

    expectAboveKeyboard(tester, find.byType(TextField), 'the note field');
    expectAboveKeyboard(tester, find.text('Continue'), 'Continue');
  });

  testWidgets('name input: field and Continue stay above the keyboard',
      (tester) async {
    await pumpScreen(
      tester,
      NameInputScreen(
        onNext: () {},
        onBack: () {},
        progressSegment: 12,
        totalSegments: 14,
      ),
    );

    expectAboveKeyboard(tester, find.byType(TextField), 'the name field');
  });

  testWidgets('email: the field is not stranded far below its prompt',
      (tester) async {
    // The real defect this pins: `sign_up_email_screen` still carries the
    // LEADING `Spacer()` that F-07 removed from `name_input_screen`, so with the
    // keyboard DOWN the field sits ~450pt under the headline with nothing
    // between them. Keyboard-up hides the symptom; keyboard-down is what the
    // user sees if they ever dismiss it.
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SignUpEmailScreen(
            onNext: () {},
            onBack: () {},
            progressSegment: 13,
            totalSegments: 14,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    final headline = tester.getRect(find.text("What's your email?"));
    final field = tester.getRect(find.byType(TextField));
    final gap = field.top - headline.bottom;

    expect(
      gap,
      lessThan(220),
      reason: 'the email field sits ${gap.toStringAsFixed(0)}pt below its '
          'headline — the leading Spacer() at sign_up_email_screen.dart:142 is '
          'the same one F-07 removed from name_input_screen.dart:109-114',
    );
  });

  testWidgets('password: the field is not stranded far below its prompt',
      (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SignUpPasswordScreen(
            onNext: () {},
            onBack: () {},
            progressSegment: 14,
            totalSegments: 14,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    final headline = tester.getRect(find.text('Create a password'));
    final field = tester.getRect(find.byType(TextField));
    final gap = field.top - headline.bottom;

    expect(
      gap,
      lessThan(220),
      reason: 'the password field sits ${gap.toStringAsFixed(0)}pt below its '
          'headline — same leading Spacer() at '
          'sign_up_password_screen.dart:255',
    );
  });
}
