import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/features/onboarding/widgets/sealed_name_tease.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

import '_test_utils.dart';

/// One Ship W2-C1 — the reveal sequence, driven by the REAL shipped decks.
///
/// Fixtures are deliberately avoided: the whole point of this screen is that it
/// renders founder-approved deck content, and the per-kind field mapping (see
/// the table on `NameStoryBeat`) is exactly what a fixture would paper over.
void main() {
  /// The anxiety pair: As-Salam (Name₁) + Al-Wakeel (Name₂).
  const anxietyPair = [6, 35];

  /// The sign pair: Ar-Rahman (Name₁, opens on `recognition`) + Al-Lateef.
  const signPair = [2, 36];

  late List<({String name, Map<String, Object?> props})> events;

  NameStoriesService stories() => NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      );

  setUp(() {
    events = [];
    OnboardingRevealScreen.onAnalyticsEvent =
        (name, props) => events.add((name: name, props: props));
  });

  tearDown(() => OnboardingRevealScreen.onAnalyticsEvent = null);

  Future<List<OnboardingRevealResult>> pumpReveal(
    WidgetTester tester, {
    List<int> pair = anxietyPair,
    VoidCallback? onBack,
  }) async {
    useOnboardingViewport(tester);
    final done = <OnboardingRevealResult>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: pair,
          stories: stories(),
          loaderBeat: Duration.zero,
          // The hint pulses forever; pumpAndSettle would never return.
          showFirstRunHint: false,
          onBack: onBack,
          onDone: done.add,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return done;
  }

  /// Taps through to the last beat, where the Ameen pill lives.
  Future<void> walkToLastBeat(WidgetTester tester) async {
    final size = tester.getSize(find.byType(BeatRevealFlow));
    while (find.text('Ameen').evaluate().isEmpty) {
      await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('opens on the loader beat, then renders the real Name₁ deck',
      (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: anxietyPair,
          stories: stories(),
          loaderBeat: const Duration(milliseconds: 400),
          showFirstRunHint: false,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pump(); // first frame — deck not resolved yet

    expect(find.text('Preparing your reflection…'), findsOneWidget);

    await tester.pumpAndSettle();
    // As-Salam's bridge line opens the deck.
    expect(find.textContaining('there is a Name'), findsOneWidget);
  });

  testWidgets('the sign contract opens on recognition — deck order, untouched',
      (tester) async {
    await pumpReveal(tester, pair: signPair);

    // The deck builder prepends recognition + comfort_verse for the sign pair;
    // the screen must not reorder or re-prepend anything of its own.
    expect(find.textContaining("You didn't find this"), findsOneWidget);

    final flow = tester.widget<BeatRevealFlow>(find.byType(BeatRevealFlow));
    expect(flow.screens!.take(2).map((s) => s.kind),
        [BeatKind.recognition, BeatKind.comfortVerse]);
  });

  testWidgets('Ameen → Silver card reveal → Name₂ tease → onDone, once',
      (tester) async {
    final done = await pumpReveal(tester);
    await walkToLastBeat(tester);

    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200)); // completion beat
    await tester.pump(const Duration(milliseconds: 400)); // route transition

    // The card reveal is pushed at a DETERMINISTIC Silver spec — no tier roll.
    final overlay =
        tester.widget<CardRevealOverlay>(find.byType(CardRevealOverlay));
    expect(overlay.spec.tier, CardTier.silver);
    expect(overlay.card.id, anxietyPair.first);
    expect(done, isEmpty, reason: 'onDone must wait for the tease');

    // Dismissing the overlay lands on Name₂, sealed.
    overlay.onContinue!();
    await tester.pumpAndSettle();

    expect(find.byType(SealedNameTease), findsOneWidget);
    expect(find.text(SealedNameTease.sealedLabel.toUpperCase()), findsOneWidget);
    expect(find.text('Al-Wakeel'), findsOneWidget);
    // No countdown clock anywhere on the tease (approved UX spec) — a duration
    // or a wall clock, not merely the colon character, which any copy edit
    // could reintroduce innocently.
    expect(find.textContaining(RegExp(r'\d+\s*(h|hr|hour|:\d\d)')), findsNothing);

    await tester.tap(find.text(SealedNameTease.continueLabel));
    await tester.pumpAndSettle();

    expect(done, hasLength(1));
    expect(done.single.name1Id, 6);
    expect(done.single.name2Id, 35);
    expect(done.single.awardedTier, CardTier.silver);
  });

  testWidgets('reveal_deck_completed fires once, on Ameen', (tester) async {
    await pumpReveal(tester);
    await walkToLastBeat(tester);

    expect(events, isEmpty, reason: 'nothing completes before Ameen');

    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    // No pumpAndSettle while the card reveal is up: its rest state (breathing
    // aurora + embers) animates forever by design. Dismiss it, then settle on
    // the tease so no overlay animation is left running at teardown.
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();

    final completed = events
        .where((e) => e.name == AnalyticsEvents.revealDeckCompleted)
        .toList();
    expect(completed, hasLength(1));
    expect(completed.single.props[AnalyticsEvents.propSurface],
        AnalyticsEvents.surfaceOnboardingReveal);
    expect(completed.single.props['name_id'], 6);
    expect(completed.single.props['deck_id'], 'as-salam@1');
    expect(events.where((e) => e.name == AnalyticsEvents.revealDeckAbandoned),
        isEmpty);
  });

  testWidgets('leaving mid-deck emits reveal_deck_abandoned with the beat index',
      (tester) async {
    await pumpReveal(tester);

    final size = tester.getSize(find.byType(BeatRevealFlow));
    await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox()); // the PageView moves on
    await tester.pumpAndSettle();

    final abandoned = events
        .where((e) => e.name == AnalyticsEvents.revealDeckAbandoned)
        .toList();
    expect(abandoned, hasLength(1));
    expect(abandoned.single.props[AnalyticsEvents.propBeatIndex], 1);
    expect(abandoned.single.props[AnalyticsEvents.propSurface],
        AnalyticsEvents.surfaceOnboardingReveal);
  });

  testWidgets('backing out of beat 0 calls onBack and abandons exactly once',
      (tester) async {
    var backs = 0;
    await pumpReveal(tester, onBack: () => backs++);

    final size = tester.getSize(find.byType(BeatRevealFlow));
    await tester.tapAt(Offset(size.width * 0.2, size.height * 0.5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox()); // dispose must not re-emit
    await tester.pumpAndSettle();

    expect(backs, 1);
    expect(
      events.where((e) => e.name == AnalyticsEvents.revealDeckAbandoned),
      hasLength(1),
    );
  });

  testWidgets('a completed reveal never emits abandoned on dispose',
      (tester) async {
    await pumpReveal(tester);
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(events.where((e) => e.name == AnalyticsEvents.revealDeckAbandoned),
        isEmpty);
  });

  testWidgets('an empty pair falls back to the comfort pair, not the error',
      (tester) async {
    // The kill-switched / skipped hook. The screen owes this user a reveal, and
    // the comfort pair is the one every other surface falls back to.
    final done = await pumpReveal(tester, pair: const []);

    expect(find.textContaining("couldn't prepare"), findsNothing);
    // Ar-Rahman's deck opens on its recognition beat.
    expect(find.textContaining("You didn't find this"), findsOneWidget);

    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();

    // …and the tease is the comfort pair's Name₂, not a dead end.
    expect(find.text('Al-Lateef'), findsOneWidget);
    await tester.tap(find.text(SealedNameTease.continueLabel));
    await tester.pumpAndSettle();
    expect(done.single.name1Id, 2);
    expect(done.single.name2Id, 36);
  });

  testWidgets('an unresolvable Name₁ falls back to the comfort pair too',
      (tester) async {
    await pumpReveal(tester, pair: const [999]); // no deck teaches this id

    expect(find.textContaining("You didn't find this"), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });

  testWidgets('an unresolvable Name₂ takes BOTH halves to the comfort pair',
      (tester) async {
    // Half a pair is not a reveal: a length-2 pair whose Name₂ no approved deck
    // teaches (a deep link's name_ids, a retired deck) used to reveal Name₁ and
    // then tease nothing, which is the deckless-tease dead end.
    final done = await pumpReveal(tester, pair: const [6, 999]);

    // Ar-Rahman's recognition beat — the comfort pair, not As-Salam's deck.
    expect(find.textContaining("You didn't find this"), findsOneWidget);
    expect(find.textContaining('there is a Name'), findsNothing);

    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    final overlay =
        tester.widget<CardRevealOverlay>(find.byType(CardRevealOverlay));
    expect(overlay.card.id, 2, reason: 'the card is the Name they were shown');
    overlay.onContinue!();
    await tester.pumpAndSettle();

    expect(find.byType(SealedNameTease), findsOneWidget);
    expect(find.text('Al-Lateef'), findsOneWidget);
    await tester.tap(find.text(SealedNameTease.continueLabel));
    await tester.pumpAndSettle();

    expect(done.single.name1Id, 2);
    expect(done.single.name2Id, 36);
  });

  testWidgets('a deckless Name₂ tease hands back exactly once, not per frame',
      (tester) async {
    // The tease phase with no Name₂ deck finishes from a post-frame callback in
    // `build`, so every rebuild while it is on screen scheduled another one.
    // Only reachable when even the comfort pair cannot supply a Name₂.
    useOnboardingViewport(tester);
    final done = <OnboardingRevealResult>[];
    final allDecks = jsonDecode(
      File(NameStoriesService.assetPath).readAsStringSync(),
    ) as List<dynamic>;
    final singleDeckAsset = jsonEncode([
      allDecks.firstWhere(
        (deck) => (deck as Map<String, dynamic>)['name_id'] == 6,
      ),
    ]);

    Future<void> pumpFrame() => tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: Padding(
              // A prop that changes on rebuild, so the child really is rebuilt.
              padding: EdgeInsets.only(top: done.length.toDouble()),
              child: OnboardingRevealScreen(
                pairNameIds: const [6],
                stories:
                    NameStoriesService(loadAsset: (_) async => singleDeckAsset),
                loaderBeat: Duration.zero,
                showFirstRunHint: false,
                onDone: done.add,
              ),
            ),
          ),
        ));

    await pumpFrame();
    await tester.pumpAndSettle();
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();

    expect(done, hasLength(1));

    // The parent rebuilds while the tease phase is still mounted.
    await pumpFrame();
    await tester.pump();
    await pumpFrame();
    await tester.pump();

    expect(done, hasLength(1),
        reason: 'a rebuild is not a second completion of the reveal');
  });

  testWidgets('the in-canvas error is what is left when even comfort fails',
      (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: const [6, 35],
          // An empty catalog: no Name₁, and no comfort pair to fall back to.
          stories: NameStoriesService(loadAsset: (_) async => '[]'),
          loaderBeat: Duration.zero,
          showFirstRunHint: false,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining("couldn't prepare"), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('a shared latch survives a re-mount — no second award, no re-emit',
      (tester) async {
    // Wave E owns one latch per onboarding run. Back-nav into the reveal must
    // not re-award the card or re-fire the deck telemetry. (Wave E must STILL
    // forbid that back-nav — this is the belt, not the braces.)
    final latch = OnboardingRevealLatch();
    Future<void> pumpWithLatch() async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: OnboardingRevealScreen(
            pairNameIds: anxietyPair,
            stories: stories(),
            latch: latch,
            loaderBeat: Duration.zero,
            showFirstRunHint: false,
            onDone: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    useOnboardingViewport(tester);
    await pumpWithLatch();
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();
    expect(events.where((e) => e.name == AnalyticsEvents.revealDeckCompleted),
        hasLength(1));

    // Re-entered: a fresh State, the same run.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await pumpWithLatch();
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    // Fixed pumps, not pumpAndSettle: the flow's completion beat stays up
    // (nothing navigates away from it this time, which is the point).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CardRevealOverlay), findsNothing,
        reason: 'the card was already awarded');
    expect(events.where((e) => e.name == AnalyticsEvents.revealDeckCompleted),
        hasLength(1));
    expect(events.where((e) => e.name == AnalyticsEvents.revealDeckAbandoned),
        isEmpty);
  });
}
