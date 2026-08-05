// Deck personalisation Wave 5 — the DAILY surface, wired.
//
// The service itself (the ladder, the seen set, the cycle) is pinned by
// `test/services/deck_variant_selector_test.dart`. This suite pins the WIRING,
// which is where the design can be undone without the service noticing:
//
//   1. The selection is resolved ONCE, where the deck is resolved, and latched
//      on state. `muhasabah_screen` builds its screens inside `build()`, and
//      `select` is async — resolving there would render `primary` for a frame
//      and then swap the bridge sentence out from under a reader mid-sentence,
//      which is the failure §4.3 names by name.
//   2. A cold-restart resume re-resolves to the IDENTICAL id. That is only true
//      because `select` is pure and `markCompleted` runs on completion (D12);
//      if anyone ever moved the write into `select`, a resumed reveal would
//      hand the user a different sentence than the one they were reading.
//   3. `markCompleted` fires on "Ameen" and on nothing else. It is deliberately
//      not idempotent, so a second caller — or the abandon path — would burn a
//      pool member the reader never met.
//   4. Completion actually advances the rotation, end to end, through the real
//      `SharedPreferences`-backed store.
//
// Driven against the REAL shipped asset. `al-qahhar@1` (name_id 22) is the deck
// the existing queue suite already reveals, and it carries both a bridge and a
// reflection with a `guilt` variant — so it exercises D9's pairing too.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/deck_variant_selector.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final nowUtc = DateTime.utc(2026, 8, 4, 3, 0);

  /// The chip whose `problemCategory` is `guilt` — `al-qahhar@1` carries a
  /// `guilt` variant on BOTH its bridge and its reflection, which is exactly
  /// the D8 case a two-part seen key would have broken.
  const guiltChipKey = 'guilt';

  late FakeSupabaseSyncService fakeSync;
  late List<(String, Map<String, dynamic>)> variantEvents;

  final stories = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    PurchaseService.debugSetOverride(_FreeUser());
    await hydrateTokenCache(balance: 100, totalSpent: 0);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugDailyLoopClock = () => nowUtc;
    variantEvents = [];
    DeckVariantSelector.onAnalyticsEvent =
        (event, props) => variantEvents.add((event, props));
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    DailyLoopNotifier.onAnalyticsEvent = null;
    DeckVariantSelector.onAnalyticsEvent = null;
    DeckVariantSelector.store = const SharedPreferencesDeckVariantStore();
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  /// Let the fire-and-forget deeper-reflection prefetch settle.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  /// A queue whose position 2 carries name_id 22 — `al-qahhar@1`, an approved
  /// deck, on the D1–D7 window where the queue owns the Name.
  DailyLoopNotifier queueNotifier() => DailyLoopNotifier(
        nameQueueService: NameQueueService(
          currentUserId: () => fakeSync.userId,
          selectRows: (_) async => [
            {
              'position': 1,
              'name_id': 11,
              'unsealed_at': DateTime.utc(2026, 8, 1, 15).toIso8601String(),
            },
            {'position': 2, 'name_id': 22, 'unsealed_at': null},
          ],
          callRpc: (_, __) async => [
            {
              'position': 2,
              'name_id': 22,
              'unsealed_at': nowUtc.toIso8601String(),
            },
          ],
        ),
      );

  /// The text `muhasabah_screen` would put on the bridge screen for [state] —
  /// built exactly the way the screen builds it, so a change to either side
  /// shows up here.
  String bridgeTextFor(DailyLoopState state) {
    final screens = buildBeatScreensFromDeck(
      state.revealDeck!,
      meaningAlreadyShown: state.engagedCard?.english,
      selection: state.revealVariant?.selection,
    );
    return screens.firstWhere((s) => s.kind == BeatKind.keyLine).primary;
  }

  Future<String> authoredVariantText(String variantId) async {
    final deck = (await stories.decks()).firstWhere((d) => d.nameId == 22);
    final bridge = deck.beats.firstWhere((b) => b.kind == deckBeatKindBridge);
    return bridge.textForVariant(variantId);
  }

  // -------------------------------------------------------------------------
  // 1. Latched once, at the reveal — never re-derived per build.
  // -------------------------------------------------------------------------

  test('the selection is resolved once, beside the deck, and latched on state',
      () async {
    DeckVariantSelector.store = InMemoryDeckVariantStore();
    final notifier = queueNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();

    expect(notifier.state.checkinProblemCategory, 'guilt');
    expect(notifier.state.revealDeck?.deckId, 'al-qahhar@1');

    final latched = notifier.state.revealVariant;
    expect(latched, isNotNull,
        reason: 'a deck reveal must carry its selection, or the screen has '
            'nothing to render but `primary`');
    expect(latched!.variantId, 'guilt');
    expect(latched.source, AnalyticsEvents.deckVariantSourceCategory,
        reason: 'the daily surface reports `category` (D13) — the deck and the '
            'category were resolved independently there');
    expect(latched.reflectionMatched, isTrue,
        reason: 'D9 — al-qahhar@1 carries a `guilt` reflection too, and the '
            'reflection mirrors the bridge id rather than rotating on its own');

    // Exactly ONE selection for one encounter. A screen that resolved in
    // `build()` would emit one per rebuild.
    expect(
      variantEvents.where((e) => e.$1 == AnalyticsEvents.deckVariantSelected),
      hasLength(1),
    );

    // Every subsequent state write carries the SAME instance through. This is
    // what "latched" means: not "recomputed to the same value", but never
    // recomputed at all.
    await notifier.startDeeper();
    notifier.setReflectStep(3);
    expect(identical(notifier.state.revealVariant, latched), isTrue);
    expect(
      variantEvents.where((e) => e.$1 == AnalyticsEvents.deckVariantSelected),
      hasLength(1),
    );
  });

  test('the same deck + category renders the same bridge text across rebuilds',
      () async {
    DeckVariantSelector.store = InMemoryDeckVariantStore();
    final notifier = queueNotifier();
    addTearDown(notifier.dispose);
    await settle();

    await notifier.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();

    final first = bridgeTextFor(notifier.state);
    await notifier.startDeeper();
    final second = bridgeTextFor(notifier.state);
    notifier.setReflectStep(2);
    final third = bridgeTextFor(notifier.state);

    expect(first, await authoredVariantText('guilt'));
    expect(second, first);
    expect(third, first,
        reason: 'the sentence a reader is part-way through may never change '
            'under them — that is the whole reason the selection is latched');
  });

  test('muhasabah_screen does no resolving of its own', () {
    final source =
        File('lib/features/daily/screens/muhasabah_screen.dart').readAsStringSync();

    // The import is the pin, not the identifier: the screen explains in a
    // comment WHY it does not resolve, and a substring match on the class name
    // would fail on the explanation itself. Without the import there is no
    // `select` call to make.
    expect(source.contains('services/deck_variant_selector.dart'), isFalse,
        reason: 'the screen builds inside `build()`, which is synchronous, and '
            'selection is not. Resolving here renders `primary` first and then '
            'swaps the text while the user is reading it. Latch it in '
            '`daily_loop_provider` next to the deck instead.');
    expect(source.contains('selection: state.revealVariant?.selection'), isTrue,
        reason: 'the screen must pass the ALREADY-resolved selection through '
            'to buildBeatScreensFromDeck');
  });

  // -------------------------------------------------------------------------
  // 2. A cold restart mid-flow re-resolves to the identical variant.
  // -------------------------------------------------------------------------

  test('a cold restart mid-flow re-resolves to the identical variant id',
      () async {
    DeckVariantSelector.store = InMemoryDeckVariantStore();
    final first = queueNotifier();
    addTearDown(first.dispose);
    await settle();

    await first.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();

    final before = first.state.revealVariant!;
    final textBefore = bridgeTextFor(first.state);

    // A brand-new notifier restores the day blob — the process-kill path.
    // (The first is left alive rather than disposed: `addTearDown` owns it,
    // and disposing twice is what a manual `dispose()` here would cost.)
    final resumed = queueNotifier();
    addTearDown(resumed.dispose);
    await settle();

    expect(resumed.state.revealDeck?.deckId, 'al-qahhar@1',
        reason: 'the resume rebuilds the deck from the persisted name id');
    expect(resumed.state.revealVariant?.variantId, before.variantId,
        reason: 'D12 is what makes this true: `select` never writes, so the '
            'seen set has not moved since the first resolve, and the same '
            'deck + seen-set + category is the same answer. Move the write '
            'into `select` and a resumed reader gets a different sentence '
            'than the one they had open.');
    expect(resumed.state.revealVariant?.reflectionMatched,
        before.reflectionMatched);
    expect(bridgeTextFor(resumed.state), textBefore);
  });

  test('the resumed category comes from the blob, not from a re-derivation',
      () async {
    DeckVariantSelector.store = InMemoryDeckVariantStore();
    final first = queueNotifier();
    addTearDown(first.dispose);
    await settle();

    await first.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();

    final resumed = queueNotifier();
    addTearDown(resumed.dispose);
    await settle();

    expect(resumed.state.checkinProblemCategory, 'guilt');
    expect(resumed.state.revealVariant?.problemCategory, 'guilt');
  });

  // -------------------------------------------------------------------------
  // 3. `markCompleted` fires on Ameen, and only there.
  // -------------------------------------------------------------------------

  test('Ameen marks the variant seen; abandoning marks nothing', () async {
    final store = InMemoryDeckVariantStore();
    DeckVariantSelector.store = store;

    // ── Abandon: reveal, then walk away without completing. ──
    final abandoned = queueNotifier();
    addTearDown(abandoned.dispose);
    await settle();
    await abandoned.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();
    await abandoned.startDeeper();

    var recorded = await store.read('al-qahhar@1');
    expect(recorded.seen, isEmpty,
        reason: 'a flow that was never finished leaves no trace (D12) — it is '
            'what lets a back-out re-resolve to the same sentence');
    expect(recorded.completedEncounters, 0);

    // ── Ameen. ──
    await abandoned.completeDeeper();

    recorded = await store.read('al-qahhar@1');
    expect(recorded.completedEncounters, 1);
    expect(
      recorded.seen,
      containsAll(<String>[
        deckVariantSeenKey('al-qahhar@1', deckBeatKindBridge, 'guilt'),
        deckVariantSeenKey('al-qahhar@1', deckBeatKindReflection, 'guilt'),
      ]),
      reason: 'D8 — the composite key records the two beats the reader '
          'actually met, and they are two different sentences',
    );

    // Idempotent at the flow level: `completeDeeper` short-circuits once the
    // step is `completed`, which is what stands between `markCompleted` (which
    // is NOT idempotent) and a double increment.
    await abandoned.completeDeeper();
    recorded = await store.read('al-qahhar@1');
    expect(recorded.completedEncounters, 1);
  });

  // -------------------------------------------------------------------------
  // 4. Completion advances the rotation — end to end, through the real store.
  // -------------------------------------------------------------------------

  test('a second encounter with the same deck + category is a different line',
      () async {
    // The REAL SharedPreferences-backed store on purpose: the account scoping
    // and the JSON round-trip are part of "end to end".
    DeckVariantSelector.store = const SharedPreferencesDeckVariantStore();

    final first = queueNotifier();
    addTearDown(first.dispose);
    await settle();
    await first.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();

    final firstText = bridgeTextFor(first.state);
    expect(first.state.revealVariant!.variantId, 'guilt');
    await first.completeDeeper();

    // A fresh day: the blob is cleared, so the next submit runs a real second
    // reveal of the same Name rather than resuming the first.
    final second = queueNotifier();
    addTearDown(second.dispose);
    await settle();
    await second.resetToday();
    await settle();
    await second.submitDailyAnswer('I keep going back to it',
        chipKey: guiltChipKey);
    await settle();

    expect(second.state.revealDeck?.deckId, 'al-qahhar@1');
    expect(second.state.revealVariant!.variantId, isNot('guilt'),
        reason: 'the completed encounter advanced the rotation — if this comes '
            'back `guilt`, `markCompleted` is not reaching the store');
    expect(second.state.revealVariant!.variantId, primaryVariantId,
        reason: 'the known-category ladder puts `primary` second: it is the '
            'author\'s answer for a category the deck carries no variant of, '
            'not a fallback');
    expect(second.state.revealVariant!.encounterIndex, 1);
    expect(bridgeTextFor(second.state), isNot(firstText));
  });

  // -------------------------------------------------------------------------
  // 5. The legacy / no-category path is passed through, never synthesised.
  // -------------------------------------------------------------------------

  test('a reveal with no category asks with none — nothing is invented',
      () async {
    DeckVariantSelector.store = InMemoryDeckVariantStore();
    final notifier = queueNotifier();
    addTearDown(notifier.dispose);
    await settle();

    // `discoverName` straight off the CTA — the legacy path, where
    // `checkinProblemCategory` is null and staying null is the honest answer.
    await notifier.discoverName();
    await settle();

    expect(notifier.state.checkinProblemCategory, isNull);
    expect(notifier.state.revealVariant?.problemCategory,
        AnalyticsEvents.deckVariantCategoryNone);
    expect(notifier.state.revealVariant?.categoryUnmatched, isTrue);
  });
}
