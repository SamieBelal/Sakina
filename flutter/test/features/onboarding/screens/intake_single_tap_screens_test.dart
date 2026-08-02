import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/intake_questions.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/daily_time_screen.dart';
import 'package:sakina/features/onboarding/screens/heaviest_time_screen.dart';
import 'package:sakina/features/onboarding/screens/names_known_screen.dart';
import 'package:sakina/features/onboarding/screens/told_anyone_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:sakina/features/onboarding/widgets/reel_option_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-H — H2, H3, H4 and H6.
///
/// The four are thin `ReelSingleTapQuestion` wrappers whose only job is to
/// render their option list and record the tap, so they are covered together
/// rather than in four near-identical files. The behaviour of the surface itself
/// (double-tap guard, commit beat, back affordance) is already pinned by
/// `carrying_duration_screen_test.dart`; what is tested here is that each screen
/// shows the right question and writes to the right state field.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// One row of the table below: a screen builder plus everything needed to
  /// assert its copy, its options and where its answer lands.
  final cases = <_IntakeCase>[
    _IntakeCase(
      name: 'H2 heaviest',
      headline: heaviestQuestionLabel,
      subline: heaviestSublineLabel,
      options: heaviestTimes,
      tapLabel: 'At night',
      expectedKey: 'nights',
      read: (s) => s.heaviestTime,
      build: (onNext, onBack, segment) => HeaviestTimeScreen(
        onNext: onNext,
        onBack: onBack,
        progressSegment: segment,
        commitBeat: Duration.zero,
      ),
    ),
    _IntakeCase(
      name: 'H3 told anyone',
      headline: toldAnyoneQuestionLabel,
      subline: toldAnyoneSublineLabel,
      options: toldAnyoneOptions,
      tapLabel: 'No one',
      expectedKey: 'no_one',
      read: (s) => s.toldAnyone,
      build: (onNext, onBack, segment) => ToldAnyoneScreen(
        onNext: onNext,
        onBack: onBack,
        progressSegment: segment,
        commitBeat: Duration.zero,
      ),
    ),
    _IntakeCase(
      name: 'H4 Names known',
      headline: namesKnownQuestionLabel,
      subline: namesKnownSublineLabel,
      options: namesKnownOptions,
      tapLabel: 'Maybe ten',
      expectedKey: 'ten',
      read: (s) => s.namesKnown,
      build: (onNext, onBack, segment) => NamesKnownScreen(
        onNext: onNext,
        onBack: onBack,
        progressSegment: segment,
        commitBeat: Duration.zero,
      ),
    ),
    _IntakeCase(
      name: 'H6 daily time',
      headline: dailyTimeQuestionLabel,
      subline: dailyTimeSublineLabel,
      options: dailyTimeOptions,
      tapLabel: 'As long as I need',
      expectedKey: 'as_long',
      read: (s) => s.dailyTime,
      build: (onNext, onBack, segment) => DailyTimeScreen(
        onNext: onNext,
        onBack: onBack,
        progressSegment: segment,
        commitBeat: Duration.zero,
      ),
    ),
  ];

  Future<ProviderContainer> pump(
    WidgetTester tester,
    _IntakeCase testCase, {
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
          home: testCase.build(onNext ?? () {}, onBack, progressSegment),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scope;
  }

  for (final testCase in cases) {
    group(testCase.name, () {
      testWidgets('renders the question and every option', (tester) async {
        await pump(tester, testCase);

        expect(find.text(testCase.headline), findsOneWidget);
        expect(find.text(testCase.subline), findsOneWidget);
        expect(
          find.byType(ReelOptionCard),
          findsNWidgets(testCase.options.length),
        );
        for (final option in testCase.options) {
          expect(find.text(option.label), findsOneWidget, reason: option.key);
        }
      });

      testWidgets('a single tap records the answer and advances once',
          (tester) async {
        var advanced = 0;
        final container =
            await pump(tester, testCase, onNext: () => advanced++);

        await tester.tap(find.text(testCase.tapLabel));
        await tester.pumpAndSettle();

        expect(testCase.read(container.read(onboardingProvider)),
            testCase.expectedKey);
        expect(advanced, 1);
      });

      testWidgets('pre-selects the stored answer for a returning user',
          (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await pump(tester, testCase, container: container);
        await tester.tap(find.text(testCase.tapLabel));
        await tester.pumpAndSettle();

        // Rebuild from scratch against the same container — what backing up
        // into the screen does.
        await pump(tester, testCase, container: container);

        final selected = tester
            .widgetList<ReelOptionCard>(find.byType(ReelOptionCard))
            .where((card) => card.selected)
            .toList();
        expect(selected, hasLength(1));
        expect(selected.single.label, testCase.tapLabel);
      });

      testWidgets('no progress bar unless the caller supplies a segment',
          (tester) async {
        await pump(tester, testCase);
        expect(find.byType(OnboardingProgressBar), findsNothing);

        await pump(tester, testCase, onBack: () {}, progressSegment: 4);
        expect(find.byType(OnboardingProgressBar), findsOneWidget);
        expect(find.text(testCase.headline), findsOneWidget);
      });
    });
  }

  testWidgets('H2 schedules the reminder its answer derives', (tester) async {
    // The reason H2 is allowed to replace the reminder-time screen rather than
    // sit beside it: the answer IS the schedule by the time the user moves on.
    final container = await pump(tester, cases.first);

    await tester.tap(find.text('At night'));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).reminderTime, '21:00');
  });
}

class _IntakeCase {
  _IntakeCase({
    required this.name,
    required this.headline,
    required this.subline,
    required this.options,
    required this.tapLabel,
    required this.expectedKey,
    required this.read,
    required this.build,
  });

  final String name;
  final String headline;
  final String subline;
  final List<IntakeOption> options;
  final String tapLabel;
  final String expectedKey;
  final String? Function(OnboardingState) read;
  final Widget Function(VoidCallback onNext, VoidCallback? onBack, int? segment)
      build;
}
