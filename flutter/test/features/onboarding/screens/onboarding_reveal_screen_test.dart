import 'dart:io';

import 'package:flutter/material.dart';
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
    await tester.pumpWidget(MaterialApp(
      home: OnboardingRevealScreen(
        pairNameIds: pair,
        stories: stories(),
        loaderBeat: Duration.zero,
        // The hint pulses forever; pumpAndSettle would never return.
        showFirstRunHint: false,
        onBack: onBack,
        onDone: done.add,
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
    await tester.pumpWidget(MaterialApp(
      home: OnboardingRevealScreen(
        pairNameIds: anxietyPair,
        stories: stories(),
        loaderBeat: const Duration(milliseconds: 400),
        showFirstRunHint: false,
        onDone: (_) {},
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
    // No countdown clock anywhere on the tease (approved UX spec).
    expect(find.textContaining(':'), findsNothing);

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

  testWidgets('an unresolvable Name₁ shows the in-canvas error, not a blank',
      (tester) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(MaterialApp(
      home: OnboardingRevealScreen(
        pairNameIds: const [999], // no deck teaches this id
        stories: stories(),
        loaderBeat: Duration.zero,
        showFirstRunHint: false,
        onDone: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining("couldn't prepare"), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });
}
