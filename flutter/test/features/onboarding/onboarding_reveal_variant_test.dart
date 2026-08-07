// Deck personalisation Wave 5 — the ONBOARDING surface, wired.
//
// This is the shipped flow, so the bar here is not "personalisation works" but
// "personalisation cannot break the reveal". Four of the seven tests below are
// about the second thing.
//
// What is pinned:
//   1. The reveal opens on the line written for the category the hook resolved.
//   2. A CHIP KEY passed where a category belongs does NOT half-match — the
//      exact mistake §5/Wave 5 warns about, and the one that would look like it
//      worked. `far-from-allah` and `far_from_allah` are different strings.
//   3. `onboarding_screen.dart` reads `problemCategory` off the provider, not
//      `chipKey`. The state carries both, one line apart.
//   4. A throwing selector renders EXACTLY the pre-personalisation reveal.
//   5. A selector that never answers renders it too — bounded, not hung. This
//      is the failure a try/catch cannot see, and the reason the screen has a
//      budget: before Wave 5 this screen reached its first beat with no
//      `SharedPreferences` dependency at all.
//   6. `markCompleted` fires on Ameen and never on the abandon path.
//   7. Completion advances the rotation: the second encounter is a new line.
//
// Driven against the REAL shipped decks, like every other test in this
// directory. `as-salam@1` (name_id 6) is the anxiety pair's Name₁, and it is
// one of the seven chip-echo decks — the ones whose `primary` reads a chip
// label back — which is what makes the unmatched cases here meaningful.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:sakina/features/daily/widgets/card_reveal_overlay.dart';
import 'package:sakina/features/onboarding/screens/onboarding_reveal_screen.dart';
import 'package:sakina/services/deck_variant_selector.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

import '../../support/fake_supabase_sync_service.dart';
import 'screens/_test_utils.dart';

/// A store that never answers — a prefs read that hangs rather than throws.
class _HangingStore implements DeckVariantStore {
  @override
  Future<DeckVariantDeckState> read(String deckId) =>
      Completer<DeckVariantDeckState>().future;
  @override
  Future<void> write(String deckId, DeckVariantDeckState state) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The anxiety pair: As-Salam (Name₁) + Al-Wakeel (Name₂).
  const anxietyPair = [6, 35];

  /// The `far-from-allah` CHIP's category. The two strings differ by one
  /// character class, and that is the whole test.
  const farCategory = 'far_from_allah';
  const farChipKey = 'far-from-allah';

  /// `as-salam@1`'s authored lines, verbatim from the shipped asset.
  const farVariantLine =
      'The distance is loud. This is the Name for the stillness on the other '
      'side of it.';
  const defaultLine =
      'Whatever you came in carrying tonight, this is the Name for what is '
      'meant to sit underneath it.';
  const chipEchoPrimary =
      "For the weight you named — a mind that won't stop racing — there is a "
      'Name.';

  late InMemoryDeckVariantStore store;

  NameStoriesService stories() => NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      );

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    store = InMemoryDeckVariantStore();
    DeckVariantSelector.store = store;
  });

  tearDown(() {
    DeckVariantSelector.store = const SharedPreferencesDeckVariantStore();
    DeckVariantSelector.onAnalyticsEvent = null;
    OnboardingRevealScreen.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
  });

  Future<void> pumpReveal(
    WidgetTester tester, {
    String? problemCategory,
    OnboardingRevealLatch? latch,
    VoidCallback? onBack,
  }) async {
    useOnboardingViewport(tester);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: OnboardingRevealScreen(
          pairNameIds: anxietyPair,
          stories: stories(),
          problemCategory: problemCategory,
          latch: latch,
          loaderBeat: Duration.zero,
          showFirstRunHint: false,
          onBack: onBack,
          onDone: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Tears the tree down between two `pumpReveal`s. Without it Flutter matches
  /// the two `OnboardingRevealScreen`s by type and position and REUSES the
  /// `State` — so the "second encounter" never remounts, `_load` never re-runs,
  /// and the test would pass by not testing anything.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  /// The bridge screen's text, read off the flow the screen actually built.
  String bridgeText(WidgetTester tester) {
    final flow = tester.widget<BeatRevealFlow>(find.byType(BeatRevealFlow));
    return flow.screens!.firstWhere((s) => s.kind == BeatKind.keyLine).primary;
  }

  Future<void> walkToLastBeat(WidgetTester tester) async {
    final size = tester.getSize(find.byType(BeatRevealFlow));
    while (find.text('Ameen').evaluate().isEmpty) {
      await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await tester.pumpAndSettle();
    }
  }

  /// Ameen, through the card reveal, back to a settled tree.
  Future<void> tapAmeen(WidgetTester tester) async {
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<CardRevealOverlay>(find.byType(CardRevealOverlay))
        .onContinue!();
    await tester.pumpAndSettle();
  }

  // -------------------------------------------------------------------------
  // 1-2. The category is threaded — and a chip key is NOT a category.
  // -------------------------------------------------------------------------

  testWidgets('the hook\'s problemCategory chooses the bridge line',
      (tester) async {
    await pumpReveal(tester, problemCategory: farCategory);

    expect(bridgeText(tester), farVariantLine,
        reason: 'the deck carries a `far_from_allah` bridge variant and the '
            'category names it exactly');
    expect(find.text(farVariantLine), findsOneWidget,
        reason: 'and it is the line actually on screen, not just in the list');
  });

  testWidgets('a chipKey passed where a category belongs does NOT match',
      (tester) async {
    // ⚠️ THE MISTAKE THIS TEST EXISTS FOR. `onboarding_provider` carries both
    // `chipKey` and `problemCategory`, five lines apart, and they differ by one
    // character class. The selector refuses the chip key rather than
    // half-matching it, so the symptom is silent: every reader quietly gets the
    // no-category text forever, and nothing throws, logs or alarms.
    await pumpReveal(tester, problemCategory: farChipKey);

    expect(bridgeText(tester), isNot(farVariantLine),
        reason: 'a chip key must never resolve a category variant — if this '
            'passes, someone taught the selector to normalise, and the two '
            'vocabularies have silently merged');
    expect(bridgeText(tester), defaultLine,
        reason: 'it degrades to the unmatched ladder, whose first rung on a '
            'chip-echo deck is `default`');
  });

  test('onboarding_screen threads problemCategory, never chipKey', () {
    final source =
        File('lib/features/onboarding/screens/onboarding_screen.dart')
            .readAsStringSync();
    // Argument lines only: the call site EXPLAINS the chipKey trap in a
    // comment, and a substring match over the comment would fail on the very
    // warning that keeps this right.
    final reveal = source
        .substring(
          source.indexOf('OnboardingRevealScreen('),
          source.indexOf('onDone: _onRevealDone'),
        )
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    expect(
        reveal.contains(
            'problemCategory: ref.read(onboardingProvider).problemCategory'),
        isTrue,
        reason: 'the reveal must be handed the CATEGORY off the provider, the '
            'same way `contract` already is — read from state, so it survives '
            'an app kill between the hook and this page');
    expect(reveal.contains('chipKey'), isFalse,
        reason: '`onboardingProvider.chipKey` is `far-from-allah` where the '
            'authored variant ids say `far_from_allah`. Passing it degrades '
            'every reader to the no-category text, silently and permanently.');
  });

  // -------------------------------------------------------------------------
  // 3-4. Failure-proofing. A personalisation failure may not cost the reveal.
  // -------------------------------------------------------------------------

  testWidgets('a THROWING selector leaves the reveal exactly as it was',
      (tester) async {
    // A throwing analytics bridge is the realistic version of this: `select`
    // emits `deck_variant_selected` outside its own try, so a hook that throws
    // takes the whole call down with it.
    DeckVariantSelector.onAnalyticsEvent =
        (_, __) => throw StateError('analytics is down');

    await pumpReveal(tester, problemCategory: farCategory);

    // Not "an error view" and not "a blank canvas" — the reveal that shipped.
    expect(find.byType(BeatRevealFlow), findsOneWidget);
    final flow = tester.widget<BeatRevealFlow>(find.byType(BeatRevealFlow));
    expect(flow.status, BeatFlowStatus.ready);

    final unpersonalised = buildBeatScreensFromDeck(
      (await stories().decks()).firstWhere((d) => d.nameId == 6),
    );
    expect(flow.screens!.map((s) => s.primary).toList(),
        unpersonalised.map((s) => s.primary).toList(),
        reason: 'byte-identical to `selection: null`, which is byte-identical '
            'to the reveal that shipped before Wave 5 existed');
    expect(bridgeText(tester), chipEchoPrimary);

    // And the flow still completes.
    await walkToLastBeat(tester);
    expect(find.text('Ameen'), findsOneWidget);
  });

  testWidgets('a selector that never answers is bounded, not fatal',
      (tester) async {
    // The failure a try/catch cannot see. Before Wave 5 this screen reached its
    // first beat without touching prefs; a prefs read that hangs would
    // otherwise hold the kindling beat forever and brick onboarding outright.
    DeckVariantSelector.store = _HangingStore();

    await pumpReveal(tester, problemCategory: farCategory);

    final flow = tester.widget<BeatRevealFlow>(find.byType(BeatRevealFlow));
    expect(flow.status, BeatFlowStatus.ready,
        reason: 'the reveal must arrive within '
            '${OnboardingRevealScreen.selectBudget.inMilliseconds}ms whatever '
            'the store is doing');
    expect(bridgeText(tester), chipEchoPrimary,
        reason: 'no selection means every `primary` — the pre-Wave-5 text');
    await walkToLastBeat(tester);
    expect(find.text('Ameen'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 5-6. Marking, and only on completion.
  // -------------------------------------------------------------------------

  testWidgets('Ameen marks the variant seen; abandoning marks nothing',
      (tester) async {
    // ── Abandon: one beat in, then the PageView moves on. ──
    await pumpReveal(tester, problemCategory: farCategory);
    final size = tester.getSize(find.byType(BeatRevealFlow));
    await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    var recorded = await store.read('as-salam@1');
    expect(recorded.seen, isEmpty,
        reason: 'an abandoned reveal leaves no trace (D12), so re-entering '
            'resolves to the same sentence rather than skipping it');
    expect(recorded.completedEncounters, 0);

    // ── Ameen. ──
    await unmount(tester);
    await pumpReveal(tester, problemCategory: farCategory);
    await walkToLastBeat(tester);
    await tapAmeen(tester);

    recorded = await store.read('as-salam@1');
    expect(recorded.completedEncounters, 1);
    expect(
      recorded.seen,
      contains(
          deckVariantSeenKey('as-salam@1', deckBeatKindBridge, farCategory)),
    );
  });

  testWidgets('the latch is what makes marking once-per-run', (tester) async {
    // `markCompleted` is deliberately NOT idempotent — it increments
    // `completedEncounters` — so the once-per-run guard has to be the latch
    // `_onAmeen` already sits behind. A shared latch across a re-mount is the
    // case that guard exists for.
    final latch = OnboardingRevealLatch();
    await pumpReveal(tester, problemCategory: farCategory, latch: latch);
    await walkToLastBeat(tester);
    await tapAmeen(tester);

    expect((await store.read('as-salam@1')).completedEncounters, 1);

    // A genuine re-mount — fresh State, same latch — and a second Ameen.
    await unmount(tester);
    await pumpReveal(tester, problemCategory: farCategory, latch: latch);
    await walkToLastBeat(tester);
    await tester.tap(find.text('Ameen'));
    await tester.pump();
    // Past the flow's own 1.1s completion beat — `_onAmeen` returns at the
    // latch, so no card reveal is pushed and there is nothing else to settle.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect((await store.read('as-salam@1')).completedEncounters, 1,
        reason: 'a re-mount behind a set latch must not increment again — '
            '`markCompleted` is not idempotent, so the latch IS the guard');
  });

  // -------------------------------------------------------------------------
  // 7. Completion advances the rotation — end to end, through the screen.
  // -------------------------------------------------------------------------

  testWidgets('a second encounter with the same category is a different line',
      (tester) async {
    await pumpReveal(tester, problemCategory: farCategory);
    expect(bridgeText(tester), farVariantLine);
    await walkToLastBeat(tester);
    await tapAmeen(tester);

    // A brand-new run — a fresh latch, a fresh State — against the same store.
    await unmount(tester);
    await pumpReveal(tester, problemCategory: farCategory);

    expect(bridgeText(tester), isNot(farVariantLine),
        reason: 'the completed encounter advanced the rotation; if this comes '
            'back the same line, `markCompleted` never reached the store');
    expect(bridgeText(tester), chipEchoPrimary,
        reason: 'rung 2 of the known-category ladder: `primary` is the '
            'author\'s answer, and it is a member of the pool rather than the '
            'absence of one');
  });
}
