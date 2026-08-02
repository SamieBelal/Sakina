import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/onboarding/screens/source_question_screen.dart';
import 'package:sakina/features/onboarding/widgets/reel_option_card.dart';
import 'package:sakina/features/onboarding/widgets/reel_skip_link.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_test_utils.dart';

/// One Ship W2-D3 — "Where did you find us?" (measurement only, skippable).
void main() {
  late List<({String name, Map<String, Object?> props})> events;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = [];
    SourceQuestionScreen.onAnalyticsEvent =
        (name, props) => events.add((name: name, props: props));
  });

  tearDown(() => SourceQuestionScreen.onAnalyticsEvent = null);

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    VoidCallback? onNext,
    Duration commitBeat = Duration.zero,
  }) async {
    useOnboardingViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: SourceQuestionScreen(
            onNext: onNext ?? () {},
            commitBeat: commitBeat,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the question and all four sources', (tester) async {
    await pump(tester);

    expect(find.text(SourceQuestionScreen.headlineLabel), findsOneWidget);
    expect(find.byType(ReelOptionCard), findsNWidgets(4));
    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('A friend told me'), findsOneWidget);
    expect(find.text('Somewhere else'), findsOneWidget);
  });

  testWidgets('a single tap stores the source key and advances once',
      (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).reelSource, 'instagram');
    expect(advanced, 1);
  });

  testWidgets('"Rather not say" advances without storing anything',
      (tester) async {
    var advanced = 0;
    final container = await pump(tester, onNext: () => advanced++);

    expect(find.byType(ReelSkipLink), findsOneWidget);
    await tester.ensureVisible(find.text(SourceQuestionScreen.skipLabel));
    await tester.tap(find.text(SourceQuestionScreen.skipLabel));
    await tester.pumpAndSettle();

    expect(advanced, 1);
    expect(container.read(onboardingProvider).reelSource, isNull);
  });

  testWidgets('the tap emits reel_source_selected — the screen\'s whole point',
      (tester) async {
    await pump(tester);

    await tester.tap(find.text('TikTok'));
    await tester.pumpAndSettle();

    expect(events, hasLength(1));
    expect(events.single.name, AnalyticsEvents.reelSourceSelected);
    expect(events.single.props[AnalyticsEvents.propSource], 'tiktok');
  });

  testWidgets('a decline emits nothing — that is what declining means',
      (tester) async {
    await pump(tester);

    await tester.ensureVisible(find.text(SourceQuestionScreen.skipLabel));
    await tester.tap(find.text(SourceQuestionScreen.skipLabel));
    await tester.pumpAndSettle();

    expect(events, isEmpty);
  });

  testWidgets('the answer is written before the beat, not after',
      (tester) async {
    // The beat is visual only. A page change or a backgrounding during it must
    // not be able to cost the user the tap they already made.
    var advanced = 0;
    final container = await pump(
      tester,
      onNext: () => advanced++,
      commitBeat: const Duration(milliseconds: 450),
    );

    await tester.tap(find.text('Instagram'));
    await tester.pump(); // the beat is running; nothing has navigated

    expect(container.read(onboardingProvider).reelSource, 'instagram');
    expect(events, hasLength(1));
    expect(advanced, 0);

    // An explicit elapse, not pumpAndSettle: the beat is a bare
    // `Future.delayed`, which schedules no frame for pumpAndSettle to wait on.
    await tester.pump(const Duration(milliseconds: 500));
    expect(advanced, 1);
  });

  testWidgets('a second tap during the beat is swallowed', (tester) async {
    // The guard is held from the tap until AFTER the commit is handed off —
    // including across the rebuild this screen's own answer triggers, which is
    // what would otherwise re-open the window mid-beat.
    var advanced = 0;
    final container = await pump(
      tester,
      onNext: () => advanced++,
      commitBeat: const Duration(milliseconds: 450),
    );

    await tester.tap(find.text('TikTok'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Instagram'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(advanced, 1);
    expect(events, hasLength(1));
    expect(container.read(onboardingProvider).reelSource, 'tiktok');
  });

  testWidgets('the skip link is a 44pt target', (tester) async {
    await pump(tester);

    final size = tester.getSize(find.byType(ReelSkipLink));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  test('source keys are stable snake_case and unique', () {
    final keys = SourceQuestionScreen.options.map((o) => o.key).toList();
    expect(keys, ['tiktok', 'instagram', 'friend', 'other']);
    expect(keys.toSet(), hasLength(keys.length));
  });
}
