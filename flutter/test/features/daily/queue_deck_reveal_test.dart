import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/muhasabah_screen.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// Pins the D1 deck reveal (W3 plan §4, §12 "Deck reveal").
///
/// Built against the REAL shipped decks — the wave's whole claim is that the
/// most important comeback moment in the funnel renders founder-approved content
/// with no OpenAI dependency, and a fixture would paper over exactly that.
///
/// **How "no AI call" is asserted.** `reflectWithOpenAI` is a top-level function
/// with no injection seam, but it logs every classifier decision to
/// `reflect_classifier_log` in debug builds *before* it can return, so an insert
/// on that table is a faithful one-to-one witness that the AI seam was entered —
/// and its `user_text` payload is the reflection context, which carries the
/// forced Name. Absence of the row is absence of the call.
class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  // 2026-08-04T03:00Z is 2026-08-03 20:00 America/Los_Angeles.
  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);

  /// Al-Wakeel — queue position 2's Name in the `anxiety` pair, and one of the
  /// 14 approved decks.
  const deckedNameId = 35;
  const deckedDeckId = 'al-wakeel@1';

  /// An aspiration-shaped Name: in the catalog, taught by no approved deck.
  const undeckedNameId = 50;

  final stories = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  late FakeSupabaseSyncService fakeSync;
  late List<Map<String, dynamic>> queueRows;
  late dynamic unsealResult;

  /// The collection cache, seeded directly so the gacha's random pick can be
  /// made deterministic (see [seedCollection]).
  void mockPrefs([Map<String, Object> extra = const {}]) =>
      SharedPreferences.setMockInitialValues({...extra});

  /// Every Name discovered at Gold except [undiscovered], so a free user's
  /// `pickNextCard` has exactly one candidate in its undiscovered bucket.
  Map<String, Object> seedCollection({
    Set<int> undiscovered = const {},
    Map<int, int> tiers = const {},
  }) {
    final ids = <int>[];
    final tierMap = <String, int>{};
    for (final name in currentCollectibleNames()) {
      if (undiscovered.contains(name.id)) continue;
      ids.add(name.id);
      tierMap['${name.id}'] = tiers[name.id] ?? 3;
    }
    return {
      'sakina_card_collection:user-1':
          jsonEncode({'ids': ids, 'dates': {}, 'tiers': tierMap}),
    };
  }

  setUp(() async {
    mockPrefs();
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugDailyLoopClock = () => nowUtc;
    queueRows = [];
    unsealResult = null;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    debugLastPickExclude = null;
    DailyLoopNotifier.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  DailyLoopNotifier makeNotifier({NameStoriesService? storiesOverride}) =>
      DailyLoopNotifier(
        storiesService: storiesOverride ?? stories,
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => queueRows,
          callRpc: (_, __) async => unsealResult,
        ),
      );

  Map<String, dynamic> serverRow(int position, int nameId,
          {DateTime? unsealedAt}) =>
      {
        'position': position,
        'name_id': nameId,
        'unsealed_at': unsealedAt?.toIso8601String(),
      };

  /// The queue shape that unseals [nameId] at position 2 today.
  void queueUnsealing(int nameId) {
    queueRows = [
      serverRow(1, 11, unsealedAt: DateTime.utc(2026, 7, 30, 15)),
      serverRow(2, nameId),
      serverRow(3, 33),
    ];
    unsealResult = [serverRow(2, nameId, unsealedAt: nowUtc)];
  }

  /// Let the fire-and-forget prefetch (and its classifier log) settle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  List<Map<String, dynamic>> aiCalls() => fakeSync.insertCalls
      .where((c) => c['table'] == 'reflect_classifier_log')
      .toList();

  group('the provider resolves the deck', () {
    test('a queue reveal of a decked Name parks the deck and never touches '
        'the AI seam', () async {
      queueUnsealing(deckedNameId);

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.error, isNull);
      expect(notifier.state.engagedCard!.id, deckedNameId);
      expect(notifier.state.revealSource, revealSourceQueue);
      expect(notifier.state.revealDeck?.deckId, deckedDeckId);
      expect(aiCalls(), isEmpty,
          reason: 'the D1 deck is the one reveal with no OpenAI dependency — a '
              'prefetch here spends a call whose result is thrown away and, '
              'post-W4, could consume an allowance');
    });

    test('a queue reveal of an undecked Name keeps the AI path, with the '
        "queue's Name forced", () async {
      queueUnsealing(undeckedNameId);

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      final queueName = findCollectibleById(undeckedNameId)!.transliteration;
      expect(notifier.state.engagedCard!.id, undeckedNameId);
      expect(notifier.state.revealSource, revealSourceQueue);
      expect(notifier.state.revealDeck, isNull);
      expect(notifier.state.checkinName, queueName);
      expect(aiCalls(), hasLength(1));
      // `_deeperContextText` builds the reflection context from the engaged
      // card, and `forceName` from `checkinName` — both the queue's Name.
      expect(aiCalls().single['data']['user_text'], contains(queueName));
    });

    test('a legacy gacha reveal never renders a deck, even when the picked '
        'Name has one', () async {
      // No queue rows at all → QueueAbsent → the untouched legacy path. The
      // collection leaves ONLY the decked Name undiscovered, so the gacha is
      // forced to hand it over.
      mockPrefs(seedCollection(undiscovered: {deckedNameId}));
      await hydrateTokenCache(balance: 100, totalSpent: 0);
      queueRows = const [];

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      expect(notifier.state.engagedCard!.id, deckedNameId,
          reason: 'the seeded collection forces the gacha onto the decked Name');
      expect(notifier.state.revealSource, revealSourceGacha);
      expect(notifier.state.revealDeck, isNull,
          reason: 'decks must not leak into the legacy path — a user with no '
              'queue gets exactly the experience they get today');
      expect(aiCalls(), hasLength(1));
    });

    test('the deck survives the copyWith that follows the reveal write',
        () async {
      queueUnsealing(deckedNameId);

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      // The streak/milestone writes land inside discoverName after the reveal.
      await settle();
      expect(notifier.state.revealDeck?.deckId, deckedDeckId);

      // And any later unrelated write — the deck has to live from the reveal
      // until DailyLoopStep.deeper renders it.
      notifier.refreshTokenBalance(7);
      expect(notifier.state.revealDeck?.deckId, deckedDeckId);
      expect(notifier.state.tokenBalance, 7);
    });

    test('startDeeper crosses to the canvas without an AI call', () async {
      queueUnsealing(deckedNameId);

      final notifier = makeNotifier();
      addTearDown(notifier.dispose);
      await notifier.discoverName();
      await settle();

      await notifier.startDeeper();
      await settle();

      expect(notifier.state.currentStep, DailyLoopStep.deeper);
      expect(notifier.state.reflectLoading, isFalse);
      expect(notifier.state.reflectResult, isNull);
      expect(aiCalls(), isEmpty,
          reason: 'Go Deeper must not fire the call discoverName skipped — '
              'otherwise the reveal still fails on an OpenAI outage');
    });
  });

  group('the screen renders the deck', () {
    /// Drives the real screen from a cold mount through the reveal to the
    /// sacred canvas. The queue Name is seeded at Gold so a free user's
    /// re-encounter is a duplicate: `cardEngageResult` stays null and the
    /// CardRevealOverlay (whose looping animations cannot be settled) never
    /// pushes, leaving the beat flow as the only thing under test.
    Future<DailyLoopNotifier> pumpToCanvas(
      WidgetTester t, {
      NameStoriesService? storiesOverride,
      // False only for the undrawable-deck case: the provider now drops such a
      // deck before it reaches state, so asserting it landed would contradict
      // the behaviour under test.
      bool expectDeck = true,
    }) async {
      mockPrefs({
        ...seedCollection(tiers: {deckedNameId: 3}),
        // Past the first-run hint, whose pulse repeats forever and would make
        // every `pumpAndSettle` on the canvas time out.
        'beat_hint_advances': 3,
      });
      await hydrateTokenCache(balance: 100, totalSpent: 0);
      queueUnsealing(deckedNameId);

      // No `addTearDown(dispose)` here: the ProviderScope owns the overridden
      // notifier and disposes it when the tree unmounts.
      final notifier = makeNotifier(storiesOverride: storiesOverride);
      await t.pumpWidget(
        ProviderScope(
          overrides: [dailyLoopProvider.overrideWith((_) => notifier)],
          child: const MaterialApp(home: MuhasabahScreen()),
        ),
      );
      // W4 Wave 2 removed the screen's mount-time auto-trigger — landing on
      // /muhasabah now shows the question, and the reveal starts from the
      // user's answer. These tests are about what the reveal RENDERS, not about
      // how it was started, so the answer is stood in for by calling the
      // provider directly (which is exactly what Wave 3's submit will do).
      unawaited(notifier.discoverName());
      // `ReflectLoading` breathes on a repeating controller, so the reveal is
      // driven with explicit frames rather than settled.
      for (var i = 0; i < 80 && !notifier.state.checkinDone; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(notifier.state.checkinDone, isTrue);
      await t.pumpAndSettle();

      if (expectDeck) {
        expect(notifier.state.revealDeck?.deckId, deckedDeckId);
      }
      expect(notifier.state.cardEngageResult, isNull,
          reason: 'a maxed re-encounter is a duplicate — no reveal overlay');

      await t.tap(find.text('Go Deeper'));
      await t.pumpAndSettle();
      return notifier;
    }

    testWidgets('the beat flow gets the deck screens, not a response',
        (t) async {
      await pumpToCanvas(t);

      final flow = t.widget<BeatRevealFlow>(find.byType(BeatRevealFlow));
      expect(flow.status, BeatFlowStatus.ready,
          reason: 'the deck itself is the readiness signal — there is no '
              'reflectResult behind it and there never will be');
      expect(flow.response, isNull);
      final deck = await stories.deckForName(deckedNameId);
      expect(
        flow.screens!.map((s) => s.kind).toList(),
        buildBeatScreensFromDeck(deck!).map((s) => s.kind).toList(),
        reason: "the deck's own beat list is the final order",
      );
      // The opening beat is on screen, so this is a rendered deck and not just
      // a well-formed argument list.
      expect(find.text(flow.screens!.first.primary), findsOneWidget);
    });

    testWidgets('beat events carry surface daily_unseal', (t) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));

      await pumpToCanvas(t);
      // Advance one beat (the right half of the canvas moves forward).
      final size = t.getSize(find.byType(BeatRevealFlow));
      await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await t.pumpAndSettle();

      final advanced = events
          .where((e) => e.$1 == AnalyticsEvents.reflectBeatAdvanced)
          .toList();
      expect(advanced, isNotEmpty);
      expect(
        advanced.every((e) =>
            e.$2[AnalyticsEvents.propSurface] ==
            AnalyticsEvents.surfaceDailyUnseal),
        isTrue,
        reason: 'folding D1 into `onboarding_reveal` would corrupt the '
            'onboarding deck-completion health metric',
      );
    });

    testWidgets('leaving the canvas mid-deck abandons it, on the same surface',
        (t) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));

      final notifier = await pumpToCanvas(t);
      final size = t.getSize(find.byType(BeatRevealFlow));
      await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await t.pumpAndSettle();

      // Unmount the screen — the route unwinding is the general case the
      // explicit back tap is only one instance of.
      await t.pumpWidget(
        ProviderScope(
          overrides: [dailyLoopProvider.overrideWith((_) => notifier)],
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );

      final abandoned = events
          .where((e) => e.$1 == AnalyticsEvents.revealDeckAbandoned)
          .toList();
      expect(abandoned, hasLength(1));
      expect(abandoned.single.$2[AnalyticsEvents.propSurface],
          AnalyticsEvents.surfaceDailyUnseal);
      expect(abandoned.single.$2[AnalyticsEvents.propBeatIndex], 1);
      expect(abandoned.single.$2['deck_id'], deckedDeckId);
    });

    testWidgets('Ameen completes the deck once, on the daily_unseal surface',
        (t) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));

      final notifier = await pumpToCanvas(t);
      final beats = notifier.state.revealDeck!.beats.length;
      final size = t.getSize(find.byType(BeatRevealFlow));
      // Tap through every beat, then the Ameen pill.
      for (var i = 0; i < beats; i++) {
        await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
        await t.pumpAndSettle();
      }
      await t.tap(find.text('Ameen'));
      // The pill holds for ~1.1s before firing onAmeen; a bare pumpAndSettle
      // returns as soon as the tree is idle, which is before that timer.
      await t.pump(const Duration(milliseconds: 1200));
      await t.pumpAndSettle();

      final completed = events
          .where((e) => e.$1 == AnalyticsEvents.revealDeckCompleted)
          .toList();
      expect(completed, hasLength(1));
      expect(completed.single.$2[AnalyticsEvents.propSurface],
          AnalyticsEvents.surfaceDailyUnseal);
      expect(completed.single.$2['deck_id'], deckedDeckId);
      expect(notifier.state.currentStep, DailyLoopStep.completed,
          reason: 'the quest/XP/streak hooks behind Ameen are unchanged');
      expect(
          events.where((e) => e.$1 == AnalyticsEvents.revealDeckAbandoned),
          isEmpty,
          reason: 'a finished deck must never also count as abandoned');
    });

    testWidgets('a throwing analytics hook cannot swallow the Ameen',
        (t) async {
      // `_emitDeckCompleted` runs inside `onAmeen` BEFORE `completeDeeper()`, so
      // an uncaught throw from the hook took the whole completion with it: no
      // `deeperDone`, no persist, no daily Noor — the user's tap did nothing.
      var hookThrew = false;
      DailyLoopNotifier.onAnalyticsEvent = (e, _) {
        if (e != AnalyticsEvents.revealDeckCompleted) return;
        hookThrew = true;
        throw StateError('analytics transport is down');
      };

      final notifier = await pumpToCanvas(t);
      final beats = notifier.state.revealDeck!.beats.length;
      final size = t.getSize(find.byType(BeatRevealFlow));
      for (var i = 0; i < beats; i++) {
        await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
        await t.pumpAndSettle();
      }
      await t.tap(find.text('Ameen'));
      // The pill holds ~1.1s on a real timer before firing onAmeen.
      await t.pump(const Duration(milliseconds: 1200));
      await t.pumpAndSettle();

      expect(hookThrew, isTrue,
          reason: 'the hook has to have actually thrown, or this pins nothing');
      expect(notifier.state.currentStep, DailyLoopStep.completed,
          reason: 'telemetry is best-effort — it must never sit between the '
              'tap and the state change it causes');
    });

    /// A deck for the same Name and id as the real one whose every beat carries
    /// a kind `buildBeatScreensFromDeck` does not know — its `default: continue`
    /// arm drops the beat, so the deck renders to zero screens. Approved
    /// (`review_verdict: good`) so the service still hands it over: the case
    /// under test is a deck that reaches the screen and renders to nothing.
    NameStoriesService unrenderableStories() => NameStoriesService(
          loadAsset: (_) async => jsonEncode([
            {
              'deck_id': deckedDeckId,
              'name_id': deckedNameId,
              'transliteration': 'Al-Wakeel',
              'chip_keys': ['anxiety'],
              'position_in_pair': 2,
              'review_verdict': 'good',
              'beats': [
                {'kind': 'not_a_beat_kind', 'primary': 'dropped'},
                {'kind': 'also_not_a_beat_kind', 'primary': 'dropped'},
              ],
              'sources': const [],
            }
          ]),
        );

    testWidgets('a deck that renders to zero beats is not treated as a deck',
        (t) async {
      final events = <(String, Map<String, dynamic>)>[];
      DailyLoopNotifier.onAnalyticsEvent = (e, p) => events.add((e, p));

      final notifier =
          await pumpToCanvas(t,
              storiesOverride: unrenderableStories(), expectDeck: false);

      // The drop now happens in the PROVIDER, not the screen. That is the
      // difference between "the dead end is dressed up better" and "there is no
      // dead end": `startDeeper` short-circuits on `revealDeck != null`, so as
      // long as an undrawable deck sat in state the AI reflection was
      // unreachable and the only offered action was a retry into the same
      // state. Dropping it upstream restores the fallback the deck path was
      // always supposed to have.
      expect(notifier.state.revealDeck, isNull,
          reason: 'an undrawable deck must never reach DailyLoopState — it is '
              'what makes startDeeper short-circuit away from the AI path');

      final flow = t.widget<BeatRevealFlow>(find.byType(BeatRevealFlow));
      expect(flow.screens, isNull,
          reason: 'one deck signal feeds every branch — an empty screen list '
              'must not be handed over as though it were a deck');
      expect(aiCalls(), isNotEmpty,
          reason: 'the reveal fell through to the AI reflection, which is the '
              'whole point: an approved-but-undrawable deck degrades to the '
              'ordinary path instead of stranding the user');

      // And it never counts as an abandoned deck when the route unwinds — a
      // deck that could not be completed would skew the completion rate.
      await t.pumpWidget(
        ProviderScope(
          overrides: [dailyLoopProvider.overrideWith((_) => notifier)],
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      expect(events.where((e) => e.$1 == AnalyticsEvents.revealDeckAbandoned),
          isEmpty);
    });
  });
}
