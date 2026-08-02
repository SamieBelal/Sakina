import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/intake_questions.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/intake_note_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-H — H7, "Anything you want to add?".
///
/// The one intake screen that must be as easy to leave as to answer: it is a
/// payer-detection surface (payers do 3x the reflections), so it exists for the
/// depth-diver and must cost everyone else nothing.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    VoidCallback? onNext,
    VoidCallback? onBack,
    int? progressSegment,
    ProviderContainer? container,
  }) async {
    useOnboardingViewport(tester);
    final scope = container ?? ProviderContainer();
    if (container == null) addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          home: IntakeNoteScreen(
            onNext: onNext ?? () {},
            onBack: onBack,
            progressSegment: progressSegment,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scope;
  }

  testWidgets('renders the question, the hint and both ways forward',
      (tester) async {
    await pump(tester);

    expect(find.text(intakeNoteQuestionLabel), findsOneWidget);
    expect(find.text(intakeNoteSublineLabel), findsOneWidget);
    expect(find.text(intakeNoteHintLabel), findsOneWidget);
    expect(find.text(intakeNoteSubmitLabel), findsOneWidget);
    expect(find.text(intakeNoteSkipLabel), findsOneWidget);
  });

  testWidgets('typed text is recorded on Continue', (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    await tester.enterText(find.byType(TextField), '  my father died in March ');
    await tester.tap(find.text(intakeNoteSubmitLabel));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).intakeNote,
        'my father died in March');
    expect(advanced, 1);
  });

  testWidgets('the screen is skippable and writes nothing', (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    await tester.tap(find.text(intakeNoteSkipLabel));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).intakeNote, isNull);
    expect(advanced, 1);
  });

  testWidgets('Continue with an empty field is also a valid way forward',
      (tester) async {
    // Gating Continue on typed text would turn an optional question into a
    // required one.
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    await tester.tap(find.text(intakeNoteSubmitLabel));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).intakeNote, isNull);
    expect(advanced, 1);
  });

  testWidgets('a returning user meets their own words, and can erase them',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setIntakeNote('already said');

    await pump(tester, container: container);
    expect(find.text('already said'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text(intakeNoteSubmitLabel));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).intakeNote, isNull);
  });

  testWidgets('no progress bar unless the caller supplies a segment',
      (tester) async {
    await pump(tester);
    expect(find.byType(OnboardingProgressBar), findsNothing);

    await pump(tester, onBack: () {}, progressSegment: 8);
    expect(find.byType(OnboardingProgressBar), findsOneWidget);
    expect(find.text(intakeNoteQuestionLabel), findsOneWidget);
  });
}
