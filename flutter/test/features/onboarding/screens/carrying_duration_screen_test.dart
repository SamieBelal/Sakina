import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/carrying_durations.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/carrying_duration_screen.dart';
import 'package:sakina/features/onboarding/widgets/onboarding_progress_bar.dart';
import 'package:sakina/features/onboarding/widgets/reel_option_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-D1a — "How long have you been carrying this?"
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    VoidCallback? onNext,
    VoidCallback? onBack,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CarryingDurationScreen(
            onNext: onNext ?? () {},
            onBack: onBack,
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the question and every option', (tester) async {
    await pump(tester);

    expect(find.text(carryingDurationQuestionLabel), findsOneWidget);
    expect(find.text(carryingDurationSublineLabel), findsOneWidget);
    expect(
        find.byType(ReelOptionCard), findsNWidgets(carryingDurations.length));
    for (final duration in carryingDurations) {
      expect(find.text(duration.label), findsOneWidget, reason: duration.key);
    }
  });

  testWidgets('a single tap commits the answer and advances once',
      (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    await tester.tap(find.text('Years'));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).carryingDuration, 'years');
    expect(advanced, 1);
  });

  testWidgets('a double tap during the beat still commits once',
      (tester) async {
    var advanced = 0;
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CarryingDurationScreen(
            onNext: () => advanced++,
            // A real beat, so the second tap lands inside it.
            commitBeat: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Years'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Months, on and off'));
    await tester.pumpAndSettle();

    expect(advanced, 1);
    expect(container.read(onboardingProvider).carryingDuration, 'years');
  });

  testWidgets('pre-selects the stored answer for a returning user',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(onboardingProvider.notifier).setCarryingDuration('always');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CarryingDurationScreen(
            onNext: () {},
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<ReelOptionCard>(find.byType(ReelOptionCard))
        .where((card) => card.selected)
        .toList();
    expect(selected, hasLength(1));
    expect(selected.single.label, 'As long as I can remember');
  });

  testWidgets('no back affordance and no progress bar by default',
      (tester) async {
    await pump(tester);

    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    expect(find.byType(OnboardingProgressBar), findsNothing);
  });

  testWidgets('back affordance appears when the caller supplies one',
      (tester) async {
    var backs = 0;
    await pump(tester, onBack: () => backs++);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(backs, 1);
  });

  testWidgets('renders the shared progress bar when a segment is given',
      (tester) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CarryingDurationScreen(
            onNext: () {},
            onBack: () {},
            progressSegment: 3,
            commitBeat: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingProgressBar), findsOneWidget);
    expect(find.text(carryingDurationQuestionLabel), findsOneWidget);
  });

  group('content', () {
    test('keys are unique and stable', () {
      final keys = carryingDurations.map((d) => d.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      expect(keys, ['days', 'months', 'years', 'always']);
      expect(carryingDurationsByKey.keys, containsAll(keys));
    });

    test('long-carry answers buy the gentle pacing line', () {
      // Shortened to one sentence on 2026-07-29 (founder). The playback half —
      // "You've carried this a long time." — told the user what they had just
      // tapped. What the branches MEAN is unchanged.
      const gentle = "We'll go gently — one Name a day.";
      expect(carryingPacingLine('months'), gentle);
      expect(carryingPacingLine('years'), gentle);
      expect(carryingPacingLine('always'), gentle);
      expect(carryingPacingLine('days'), isNot(gentle));
      // Unanswered gets the neutral line, never a guessed one.
      expect(carryingPacingLine(null), isNot(gentle));
      expect(carryingPacingLine(null), carryingPacingLine('nonsense'));
      // ...and every ANSWER differs from that neutral line, or the question is
      // one we ask and ignore. A first pass at the shortening let 'days'
      // collapse into the default.
      expect(carryingPacingLine('days'), isNot(carryingPacingLine(null)));
    });
  });
}
