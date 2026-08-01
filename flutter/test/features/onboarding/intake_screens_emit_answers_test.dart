import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/screens/carrying_duration_screen.dart';
import 'package:sakina/features/onboarding/screens/daily_time_screen.dart';
import 'package:sakina/features/onboarding/screens/heaviest_time_screen.dart';
import 'package:sakina/features/onboarding/screens/help_chips_screen.dart';
import 'package:sakina/features/onboarding/screens/intake_note_screen.dart';
import 'package:sakina/features/onboarding/screens/names_known_screen.dart';
import 'package:sakina/features/onboarding/screens/told_anyone_screen.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/_test_utils.dart';

/// W6 Wave F — the seven silent intake screens (One Ship W2-H).
///
/// Before this test file, `grep -cE "track\(|AnalyticsEvents\.|trackOnboardingAnswer"`
/// returned 0 for every one of these seven screens: a third of the live
/// onboarding flow told Mixpanel nothing about what the user answered. Each
/// case here pumps the real screen, answers it, and asserts exactly one
/// `onboarding_answer_captured` fires with the screen's chosen `key` and a
/// bucketed/categorical `value` — never free text (see
/// `intake_note_never_sends_text_test.dart` for that guarantee's own test).
///
/// MUTATION each case guards against: deleting the `trackOnboardingAnswerWithRef`
/// call from that one screen. Run inline per case below and confirmed to fail
/// before being reverted.
class _TrackingSpy extends AnalyticsService {
  final List<(String, Map<String, dynamic>?)> tracked = [];
  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<(String, Map<String, dynamic>?)> answerEvents(_TrackingSpy spy) => spy
      .tracked
      .where((e) => e.$1 == AnalyticsEvents.onboardingAnswerCaptured)
      .toList();

  testWidgets('carrying_duration_screen emits key=carrying_duration',
      (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: CarryingDurationScreen(
          onNext: () => advanced++,
          commitBeat: Duration.zero,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Years'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'carrying_duration'));
    expect(events.single.$2, containsPair('value', 'years'));
    expect(advanced, 1);
  });

  testWidgets('heaviest_time_screen emits key=heaviest_time', (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: HeaviestTimeScreen(
          onNext: () => advanced++,
          commitBeat: Duration.zero,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('At night'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'heaviest_time'));
    expect(events.single.$2, containsPair('value', 'nights'));
    expect(advanced, 1);
  });

  testWidgets('told_anyone_screen emits key=told_anyone', (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: ToldAnyoneScreen(
          onNext: () => advanced++,
          commitBeat: Duration.zero,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No one'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'told_anyone'));
    expect(events.single.$2, containsPair('value', 'no_one'));
    expect(advanced, 1);
  });

  testWidgets('names_known_screen emits key=names_known', (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: NamesKnownScreen(
          onNext: () => advanced++,
          commitBeat: Duration.zero,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maybe ten'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'names_known'));
    expect(events.single.$2, containsPair('value', 'ten'));
    expect(advanced, 1);
  });

  testWidgets('daily_time_screen emits key=daily_time', (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: DailyTimeScreen(
          onNext: () => advanced++,
          commitBeat: Duration.zero,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A few minutes'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'daily_time'));
    expect(events.single.$2, containsPair('value', 'few_minutes'));
    expect(advanced, 1);
  });

  testWidgets(
      'help_chips_screen emits key=help_chips with the ordered selection',
      (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: HelpChipsScreen(onNext: () => advanced++),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Strength to keep going'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Words to turn to'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'help_chips'));
    expect(events.single.$2, containsPair('value', ['strength', 'words']));
    expect(advanced, 1);
  });

  testWidgets('intake_note_screen emits key=intake_note with a length bucket',
      (tester) async {
    useOnboardingViewport(tester);
    final spy = _TrackingSpy();
    var advanced = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [analyticsProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: IntakeNoteScreen(onNext: () => advanced++),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a short note');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final events = answerEvents(spy);
    expect(events, hasLength(1));
    expect(events.single.$2, containsPair('key', 'intake_note'));
    expect(events.single.$2, containsPair('value', 'short'));
    expect(advanced, 1);
  });
}
