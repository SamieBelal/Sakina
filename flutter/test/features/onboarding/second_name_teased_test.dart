import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/features/onboarding/widgets/sealed_name_tease.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';

import 'screens/_test_utils.dart';

/// `second_name_teased` (W6 Wave B / W3 §9) — the promise the seven-day queue
/// is made of. Fires from the onboarding reveal screen's own static hook,
/// latched (mirrors `kindledFired`'s reasoning) so a re-mount cannot re-fire
/// it: one tease per user, ever.
///
/// Mirrors `onboarding_reveal_screen_test.dart`'s harness exactly (the real
/// shipped decks, no fixtures — the per-kind field mapping is what the deck
/// content actually is).
void main() {
  const anxietyPair = [6, 35]; // As-Salam (Name₁) + Al-Wakeel (Name₂)

  late List<({String name, Map<String, Object?> props})> events;

  NameStoriesService stories() => NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      );

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    events = [];
    OnboardingRevealScreen.onAnalyticsEvent =
        (name, props) => events.add((name: name, props: props));
  });

  tearDown(() => OnboardingRevealScreen.onAnalyticsEvent = null);

  Future<void> pumpReveal(
    WidgetTester tester, {
    List<int> pair = anxietyPair,
    String? contract,
    OnboardingRevealLatch? latch,
  }) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: pair,
          stories: stories(),
          contract: contract,
          latch: latch,
          loaderBeat: Duration.zero,
          showFirstRunHint: false,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> walkToLastBeat(WidgetTester tester) async {
    final size = tester.getSize(find.byType(BeatRevealFlow));
    while (find.text('Ameen').evaluate().isEmpty) {
      await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapAmeenThroughToTease(WidgetTester tester) async {
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();
  }

  testWidgets('fires once, carrying Name₂ (not Name₁), deck_id and contract',
      (tester) async {
    await pumpReveal(tester, contract: HookContract.problem);
    await tapAmeenThroughToTease(tester);

    expect(find.byType(SealedNameTease), findsOneWidget);

    final teased = events
        .where((e) => e.name == AnalyticsEvents.secondNameTeased)
        .toList();
    expect(teased, hasLength(1));
    expect(teased.single.props[AnalyticsEvents.propNameId], 35);
    expect(teased.single.props[AnalyticsEvents.propDeckId], isNotEmpty);
    expect(teased.single.props[AnalyticsEvents.propNameId], isNot(6),
        reason: 'must carry Name₂, not the _emit helper\'s default Name₁');
    expect(
        teased.single.props[AnalyticsEvents.propContract], HookContract.problem);
    expect(teased.single.props[AnalyticsEvents.propSurface],
        AnalyticsEvents.surfaceOnboardingReveal);
  });

  testWidgets('null contract omits the key rather than emitting null',
      (tester) async {
    await pumpReveal(tester); // no contract passed
    await tapAmeenThroughToTease(tester);

    final teased = events
        .where((e) => e.name == AnalyticsEvents.secondNameTeased)
        .single;
    expect(teased.props.containsKey(AnalyticsEvents.propContract), isFalse);
  });

  testWidgets(
      // MUTATION: remove the `_latch.secondNameTeasedFired` guard in
      // `_scheduleSecondNameTeased` (or call the emit directly from `build()`
      // instead of scheduling it once) — this must fail: `build()` re-runs on
      // every rebuild while the tease is on screen, unlike `_onAmeen` (which
      // guards itself via `_latch.completed` and can't be re-entered at all).
      'a parent rebuild while the tease is on screen does not re-fire',
      (tester) async {
    await pumpReveal(tester);
    await tapAmeenThroughToTease(tester);
    expect(find.byType(SealedNameTease), findsOneWidget);
    expect(
      events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
      hasLength(1),
    );

    // Same shape as the deckless-tease "hands back exactly once, not per
    // frame" regression this file already guards against for `_finish`: a
    // fresh (non-const) widget at the SAME tree position reconciles onto the
    // existing State (`didUpdateWidget`, not a re-mount) and re-runs `build`.
    await pumpReveal(tester);
    await tester.pump();
    await pumpReveal(tester);
    await tester.pump();

    expect(
      events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
      hasLength(1),
      reason: 'one tease per user, ever',
    );
  });

  testWidgets('a deckless Name₂ (comfort pair also fails) never teases',
      (tester) async {
    // Empty catalog: no Name₁ at all, so the in-canvas error shows and Ameen
    // is unreachable — the tease can never fire.
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: const [6, 35],
          stories: NameStoriesService(loadAsset: (_) async => '[]'),
          loaderBeat: Duration.zero,
          showFirstRunHint: false,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining("couldn't prepare"), findsOneWidget);
    expect(
      events.where((e) => e.name == AnalyticsEvents.secondNameTeased),
      isEmpty,
    );
    // Let flutter_animate's staggered timers elapse before teardown.
    await tester.pump(const Duration(seconds: 1));
  });
}
