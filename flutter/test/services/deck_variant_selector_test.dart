import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/deck_variant_selector.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

import '../support/fake_supabase_sync_service.dart';

/// Wave 5 — the deterministic variant selector.
///
/// Driven against the **REAL shipped asset** (99 decks, 778 variants) wherever
/// a test can be. The whole point of the service is to choose between lines
/// that were actually authored; a fixture would let the algorithm agree with
/// itself about content that does not exist, and the two cases that most nearly
/// broke the design — `al-qahhar@1`'s two different `guilt` sentences (D8) and
/// the seven chip-echo decks' `default` (Wave 2, finding 2) — are properties of
/// the shipped JSON, not of any fixture.
///
/// Synthetic decks appear exactly twice, for the two shapes the asset does not
/// contain: a bridge with no variants, and a deck with no bridge at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  late List<NameStoryDeck> allDecks;
  late List<(String event, Map<String, dynamic> props)> events;

  setUpAll(() async {
    allDecks = await service.decks();
  });

  setUp(() {
    DeckVariantSelector.store = InMemoryDeckVariantStore();
    events = [];
    DeckVariantSelector.onAnalyticsEvent = (e, p) => events.add((e, p));
  });

  tearDown(() {
    DeckVariantSelector.onAnalyticsEvent = null;
    DeckVariantSelector.store = const SharedPreferencesDeckVariantStore();
    SupabaseSyncService.instance = SupabaseSyncService();
  });

  NameStoryDeck deck(String id) =>
      allDecks.firstWhere((d) => d.deckId == id, orElse: () {
        throw StateError('no deck $id in the shipped asset');
      });

  NameStoryBeat? beatOf(NameStoryDeck d, String kind) {
    for (final b in d.beats) {
      if (b.kind == kind) return b;
    }
    return null;
  }

  List<String> bridgeIds(NameStoryDeck d) =>
      (beatOf(d, deckBeatKindBridge)?.variants ?? const [])
          .map((v) => v.id)
          .toList();

  /// The selector's priority order for [category], re-derived independently
  /// here rather than read off the implementation.
  List<String> expectedOrder(NameStoryDeck d, String? category) {
    final ids = bridgeIds(d);
    final hasDefault = ids.contains(defaultVariantId);
    if (category != null && liveProblemCategories.contains(category)) {
      return [
        if (ids.contains(category)) category,
        primaryVariantId,
        if (hasDefault) defaultVariantId,
        for (final id in ids)
          if (id != category && id != defaultVariantId) id,
      ];
    }
    return [
      if (hasDefault) defaultVariantId,
      primaryVariantId,
      for (final id in ids)
        if (id != defaultVariantId) id,
    ];
  }

  /// Every member of the priority list, which is the same set for any category.
  List<String> poolOf(NameStoryDeck d) => expectedOrder(d, null);

  NameStoryDeck synthetic(List<NameStoryBeat> beats, {String id = 'synth@1'}) =>
      NameStoryDeck(
        deckId: id,
        nameId: 999,
        transliteration: 'Synthetic',
        chipKeys: const [],
        positionInPair: 1,
        beats: beats,
        sources: const [],
        author: 'test',
        reviewedBy: 'test',
        reviewedAt: '2026-08-05',
        reviewVerdict: 'good',
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // The §4.3 resolution ladder — one test per branch
  // ═══════════════════════════════════════════════════════════════════════════

  group('§4.3 branch — chip (onboarding)', () {
    test('a live category the bridge carries wins, and reports source=chip',
        () async {
      final d = deck('al-qahhar@1');
      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.onboarding,
        problemCategory: 'guilt',
      );

      expect(s.variantId, 'guilt');
      expect(s.source, AnalyticsEvents.deckVariantSourceChip);
      expect(s.isPrimary, isFalse);
      expect(s.categoryUnmatched, isFalse);
      expect(s.selection[deckBeatKindBridge], 'guilt');
    });
  });

  group('§4.3 branch — category (daily)', () {
    test('same resolution, different source label (D13)', () async {
      final d = deck('al-qahhar@1');
      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(s.variantId, 'guilt');
      expect(s.source, AnalyticsEvents.deckVariantSourceCategory);
    });

    test('the surface changes ONLY the source label, never the choice',
        () async {
      for (final d in allDecks) {
        for (final category in liveProblemCategories) {
          final onboarding = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.onboarding,
            problemCategory: category,
          );
          final daily = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.daily,
            problemCategory: category,
          );
          expect(onboarding.variantId, daily.variantId,
              reason: '${d.deckId} / $category');
          expect(onboarding.selection, daily.selection);
        }
      }
    });
  });

  group('§4.3 branch — rotation', () {
    test('rotation is a REPEAT-visit branch — a first encounter never lands '
        'here', () async {
      // A category with no variant of its own gets `primary` (the text written
      // for it), not another category's line. Rotation only starts once those
      // exact answers are used up.
      final d = deck('al-qahhar@1');
      expect(bridgeIds(d), isNot(contains('anxiety')),
          reason: 'the fixture-free premise of this test');

      final first = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'anxiety',
      );
      expect(first.isPrimary, isTrue);
      expect(first.source, AnalyticsEvents.deckVariantSourceCategory);
      await DeckVariantSelector.markCompleted(first);

      final second = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'anxiety',
      );
      expect(second.source, AnalyticsEvents.deckVariantSourceRotation);
      expect(second.variantId, bridgeIds(d).first);
    });

    test('`unmatched` never enters the category branch', () async {
      final d = deck('al-qahhar@1');
      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: problemCategoryUnmatched,
      );

      expect(s.source, AnalyticsEvents.deckVariantSourceFallback,
          reason: 'there was no category to answer — this IS the miss the '
              'alarm is meant to count');
      expect(s.problemCategory, problemCategoryUnmatched);
      expect(s.categoryUnmatched, isTrue);
    });

    test('no category at all falls back and records `none`', () async {
      final s = await DeckVariantSelector.select(
        deck: deck('al-qahhar@1'),
        surface: DeckVariantSurface.daily,
      );

      expect(s.source, AnalyticsEvents.deckVariantSourceFallback);
      expect(s.isPrimary, isTrue,
          reason: 'al-qahhar@1 carries no `default`, so `primary` answers');
      expect(s.problemCategory, AnalyticsEvents.deckVariantCategoryNone);
      expect(s.categoryUnmatched, isTrue);
    });

    test('an already-seen category variant rotates past itself', () async {
      final d = deck('al-qahhar@1');
      final first = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(first);

      final second = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      // `primary` is the SECOND exact answer for a known category, so it comes
      // before anyone else's line.
      expect(second.variantId, primaryVariantId);
      expect(second.source, AnalyticsEvents.deckVariantSourceCategory);
      await DeckVariantSelector.markCompleted(second);

      final third = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(third.source, AnalyticsEvents.deckVariantSourceRotation);
      expect(third.variantId, bridgeIds(d).first);
    });

    test(
        'the seven chip-echo decks hand an uncategorised reader `default` '
        'BEFORE the chip line — the live bug Wave 2 authored it for', () async {
      // `as-salam@1`'s primary opens *"For the weight you named"*. Onboarding
      // picks that deck BY the chip so it is true there; the daily loop picks
      // it by the drawn card, and a reader whose answer matched nothing never
      // named a weight. For an UNMATCHED reader `default` outranks `primary`
      // by priority — not because an author happened to list it first.
      for (final id in const [
        'as-salam@1',
        'al-jabbar@1',
        'al-ghaffar@1',
        'ar-razzaq@1',
        'al-fattah@1',
        'al-wadud@1',
        'al-baseer@1',
      ]) {
        final d = deck(id);
        expect(bridgeIds(d), contains(defaultVariantId), reason: id);

        final s = await DeckVariantSelector.select(
          deck: d,
          surface: DeckVariantSurface.daily,
          problemCategory: problemCategoryUnmatched,
        );
        expect(s.variantId, defaultVariantId, reason: id);
        expect(s.isPrimary, isFalse, reason: id);
        expect(s.source, AnalyticsEvents.deckVariantSourceFallback, reason: id);
      }
    });
  });

  group('§4.3 branch — fallback (`variants.isEmpty → primary`)', () {
    test('a bridge with no variants selects nothing at all', () async {
      final d = synthetic(const [
        NameStoryBeat(kind: 'bridge', primary: 'the authored opener'),
        NameStoryBeat(kind: 'reflection', primary: 'the authored closer'),
      ]);

      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(s.source, AnalyticsEvents.deckVariantSourceFallback);
      expect(s.isPrimary, isTrue);
      expect(s.selection, isEmpty);
      expect(s.reflectionMatched, isFalse);
      expect(s.seenKeys, isEmpty,
          reason: 'nothing was selected, so nothing can be marked seen');
    });

    test('a fallback deck never accumulates seen state, however many '
        'encounters complete', () async {
      final d = synthetic(const [
        NameStoryBeat(kind: 'bridge', primary: 'the authored opener'),
      ]);

      for (var i = 0; i < 4; i++) {
        final s = await DeckVariantSelector.select(
          deck: d,
          surface: DeckVariantSurface.daily,
        );
        expect(s.source, AnalyticsEvents.deckVariantSourceFallback);
        expect(s.encounterIndex, i, reason: 'the counter still counts');
        await DeckVariantSelector.markCompleted(s);
      }
      final state = await DeckVariantSelector.store.read(d.deckId);
      expect(state.seen, isEmpty);
      expect(state.completedEncounters, 4);
    });

    test('a deck with no bridge beat at all degrades, it does not throw',
        () async {
      final d = synthetic(const [
        NameStoryBeat(kind: 'takeaway', primary: 'only a takeaway'),
      ]);

      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.onboarding,
        problemCategory: 'anxiety',
      );

      expect(s.source, AnalyticsEvents.deckVariantSourceFallback);
      expect(s.selection, isEmpty);
    });

    test('NO shipped deck reaches the no-pool shape — §4.3 calls it the main '
        'path and it is already dead content', () async {
      for (final d in allDecks) {
        final s = DeckVariantSelector.resolve(
          deck: d,
          surface: DeckVariantSurface.daily,
        );
        expect(s.hasPool, isTrue, reason: d.deckId);
        expect(s.seenKeys, isNotEmpty, reason: d.deckId);
      }
    });

    test('`source: fallback` on a deck WITH a pool still advances rotation — '
        'it is a real choice, not a no-op', () async {
      // The distinction hasPool draws. An unmatched reader gets `default` (a
      // fallback) and must not get the same line on every visit forever.
      final d = deck('as-salam@1');
      final first = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: problemCategoryUnmatched,
      );
      expect(first.source, AnalyticsEvents.deckVariantSourceFallback);
      expect(first.seenKeys, isNotEmpty);
      await DeckVariantSelector.markCompleted(first);

      final second = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: problemCategoryUnmatched,
      );
      expect(second.variantId, isNot(first.variantId));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // The authoring contract: no variant for C means `primary` IS the text for C
  // ═══════════════════════════════════════════════════════════════════════════

  group('99 decks × 7 categories — the no-variant-means-primary contract', () {
    test('a first encounter with a category the deck has no variant for ALWAYS '
        'serves primary, never another category\'s line', () {
      final offenders = <String>[];
      var uncovered = 0;
      var total = 0;

      for (final d in allDecks) {
        final ids = bridgeIds(d).toSet();
        for (final category in liveProblemCategories) {
          total++;
          if (ids.contains(category)) continue;
          uncovered++;

          final s = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.daily,
            problemCategory: category,
          );
          if (!s.isPrimary || s.selection.isNotEmpty) {
            offenders.add('${d.deckId}/$category → ${s.variantId}');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'a category with nothing distinctive to say carries NO '
              'variant and falls through to `primary` DELIBERATELY — `primary` '
              'is the authored text for it. Serving some other category\'s '
              'line there is the Wave 2 contract inverted.');
      expect(total, 693);
      expect(uncovered, 195,
          reason: 'the founder-measured figure on 2026-08-05. If content '
              'changes this legitimately, re-measure and update — do not '
              'loosen the assertion above.');
    });

    test('the exact cases that caught the bug', () {
      // Each: the deck has no variant for the category, and its `primary` is
      // recognisably the text written for a reader like that.
      for (final (deckId, category) in const [
        ('allah@1', 'rizq'),
        ('al-quddus@1', 'guilt'),
        ('as-salam@1', 'anxiety'),
      ]) {
        final d = deck(deckId);
        expect(bridgeIds(d), isNot(contains(category)), reason: deckId);

        final s = DeckVariantSelector.resolve(
          deck: d,
          surface: DeckVariantSurface.daily,
          problemCategory: category,
        );
        expect(s.isPrimary, isTrue, reason: '$deckId / $category');
        expect(s.source, AnalyticsEvents.deckVariantSourceCategory,
            reason: 'an exact answer is a hit, not a miss — lumping these into '
                '`fallback` would fire the >35% alarm on ~28% of normal '
                'traffic');
      }

      // The specific mis-serve the flat pool produced.
      final allah = deck('allah@1');
      final bridge = beatOf(allah, deckBeatKindBridge)!;
      expect(
        DeckVariantSelector.resolve(
          deck: allah,
          surface: DeckVariantSurface.daily,
          problemCategory: 'rizq',
        ).selection,
        isEmpty,
        reason: 'a rizq reader must NOT be handed the anxiety variant '
            '"${bridge.textForVariant('anxiety')}"',
      );
    });

    test('for a KNOWN category, `primary` outranks `default`; for an UNMATCHED '
        'reader it is the other way round', () {
      // `as-salam@1` is the only shape where both exist and can disagree.
      final d = deck('as-salam@1');
      expect(bridgeIds(d), contains(defaultVariantId));
      expect(bridgeIds(d), isNot(contains('anxiety')));

      expect(
        DeckVariantSelector.resolve(
          deck: d,
          surface: DeckVariantSurface.daily,
          problemCategory: 'anxiety',
        ).variantId,
        primaryVariantId,
        reason: "as-salam@1's primary IS the anxiety text — `default` is for "
            'the reader who named nothing',
      );
      expect(
        DeckVariantSelector.resolve(
          deck: d,
          surface: DeckVariantSurface.daily,
          problemCategory: problemCategoryUnmatched,
        ).variantId,
        defaultVariantId,
      );
    });

    test('the unmatched preference for `default` does NOT depend on authoring '
        'order', () {
      // Re-order the variants so `default` is LAST. The old flat pool got the
      // right answer only because authors happened to put it first.
      final real = deck('as-salam@1');
      final bridge = beatOf(real, deckBeatKindBridge)!;
      final shuffled = synthetic(
        [
          NameStoryBeat(
            kind: deckBeatKindBridge,
            primary: bridge.primary,
            variants: [
              ...bridge.variants.where((v) => v.id != defaultVariantId),
              bridge.variants.firstWhere((v) => v.id == defaultVariantId),
            ],
          ),
        ],
        id: 'reordered@1',
      );

      expect(
        DeckVariantSelector.resolve(
          deck: shuffled,
          surface: DeckVariantSurface.daily,
          problemCategory: problemCategoryUnmatched,
        ).variantId,
        defaultVariantId,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // D9 — paired selection
  // ═══════════════════════════════════════════════════════════════════════════

  group('D9 — the reflection mirrors the bridge, never rotates on its own', () {
    test('one id resolves both beats when the reflection carries it', () async {
      final d = deck('al-qahhar@1');
      expect(beatOf(d, deckBeatKindReflection)!.variants.map((v) => v.id),
          contains('guilt'));

      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(s.reflectionMatched, isTrue);
      expect(s.selection, {
        deckBeatKindBridge: 'guilt',
        deckBeatKindReflection: 'guilt',
      });
    });

    test('a reflection that lacks the chosen id falls through to its primary',
        () async {
      final d = deck('al-qahhar@1');
      final reflection = beatOf(d, deckBeatKindReflection)!;
      expect(reflection.variants.map((v) => v.id), isNot(contains('rizq')),
          reason: 'the premise: the bridge covers rizq and the reflection does '
              'not — uneven coverage is by design (D9)');

      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'rizq',
      );

      expect(s.variantId, 'rizq');
      expect(s.reflectionMatched, isFalse);
      expect(s.selection, {deckBeatKindBridge: 'rizq'});

      // …and the builder actually renders the reflection's own line.
      final screens = buildBeatScreensFromDeck(d, selection: s.selection);
      expect(screens.last.primary, reflection.primary);
      expect(screens.first.primary,
          beatOf(d, deckBeatKindBridge)!.textForVariant('rizq'));
    });

    test('the 8 synergy-closers have no reflection and never claim a match',
        () async {
      final closers =
          allDecks.where((d) => beatOf(d, deckBeatKindReflection) == null);
      expect(closers.length, 8, reason: 'D1 — bridge only, by decision');

      for (final d in closers) {
        for (final category in liveProblemCategories) {
          final s = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.daily,
            problemCategory: category,
          );
          expect(s.reflectionMatched, isFalse, reason: d.deckId);
          expect(s.selection.containsKey(deckBeatKindReflection), isFalse);
        }
      }
    });

    test('`primary` never pairs — it is a pool member, not an id a reflection '
        'can carry', () async {
      final d = deck('al-qahhar@1');
      final s = DeckVariantSelector.resolve(
        deck: d,
        surface: DeckVariantSurface.daily,
        // Everything but `primary` already seen.
        seen: {
          for (final id in bridgeIds(d))
            deckVariantSeenKey(d.deckId, deckBeatKindBridge, id),
        },
      );

      expect(s.variantId, primaryVariantId);
      expect(s.isPrimary, isTrue);
      expect(s.reflectionMatched, isFalse);
      expect(s.selection, isEmpty,
          reason: '"render primary" is the ABSENCE of an entry, never an entry '
              'holding the sentinel');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // D8 — the composite key
  // ═══════════════════════════════════════════════════════════════════════════

  group('D8 — deck_id + beat_kind + variant_id', () {
    test('al-qahhar@1 really does carry two different `guilt` sentences',
        () async {
      final d = deck('al-qahhar@1');
      final bridge = beatOf(d, deckBeatKindBridge)!;
      final reflection = beatOf(d, deckBeatKindReflection)!;

      expect(bridge.textForVariant('guilt'), isNot(bridge.primary));
      expect(reflection.textForVariant('guilt'), isNot(reflection.primary));
      expect(bridge.textForVariant('guilt'),
          isNot(reflection.textForVariant('guilt')),
          reason: 'this is the whole reason the key is three parts and not two');
    });

    test('a paired encounter records BOTH keys — both lines were read',
        () async {
      final d = deck('al-qahhar@1');
      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(s);

      final state = await DeckVariantSelector.store.read(d.deckId);
      expect(state.seen, {
        deckVariantSeenKey(d.deckId, deckBeatKindBridge, 'guilt'),
        deckVariantSeenKey(d.deckId, deckBeatKindReflection, 'guilt'),
      });
    });

    test('an unpaired encounter records ONLY the bridge — a two-part key would '
        'burn a reflection line the reader never met', () async {
      final d = deck('al-qahhar@1');
      // `rizq` exists on the bridge and not on the reflection.
      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'rizq',
      );
      await DeckVariantSelector.markCompleted(s);

      final state = await DeckVariantSelector.store.read(d.deckId);
      expect(state.seen,
          {deckVariantSeenKey(d.deckId, deckBeatKindBridge, 'rizq')});
      expect(
        state.seen,
        isNot(contains(
            deckVariantSeenKey(d.deckId, deckBeatKindReflection, 'rizq'))),
      );
    });

    test('the key is never an array index', () {
      final key = deckVariantSeenKey('al-qahhar@1', deckBeatKindBridge, 'guilt');
      expect(key, 'al-qahhar@1|bridge|guilt');
      expect(key, isNot(matches(RegExp(r'\|\d+$'))));
    });

    test('bridge and reflection keys for one id are distinct on every deck '
        'that shares an id across both beats', () {
      var shared = 0;
      for (final d in allDecks) {
        final reflection = beatOf(d, deckBeatKindReflection);
        if (reflection == null) continue;
        final reflectionIds = reflection.variants.map((v) => v.id).toSet();
        for (final id in bridgeIds(d).where(reflectionIds.contains)) {
          shared++;
          expect(
            deckVariantSeenKey(d.deckId, deckBeatKindBridge, id),
            isNot(deckVariantSeenKey(d.deckId, deckBeatKindReflection, id)),
          );
        }
      }
      expect(shared, greaterThan(200),
          reason: 'the shared-id surface D8 exists for is large, not marginal');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // D12 — completion marks, abandonment does not; exhaustion cycles
  // ═══════════════════════════════════════════════════════════════════════════

  group('D12 — seen is marked on COMPLETION', () {
    test('selecting twice without completing returns the same id', () async {
      final d = deck('al-qahhar@1');
      final a = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      final b = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(b.variantId, a.variantId);
      expect(b.source, a.source);
      expect(b.encounterIndex, a.encounterIndex);
    });

    test('an abandoned flow leaves NO trace', () async {
      final d = deck('al-qahhar@1');
      await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      final state = await DeckVariantSelector.store.read(d.deckId);
      expect(state.seen, isEmpty);
      expect(state.completedEncounters, 0);
    });

    test('a completed flow advances the rotation', () async {
      final d = deck('al-qahhar@1');
      final a = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(a);

      final b = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(b.variantId, isNot(a.variantId));
      expect(b.encounterIndex, 1);
    });
  });

  group('D12 — exhaustion cycles rather than freezing on primary', () {
    test('one full cycle visits every pool member exactly once, then '
        'starts over', () async {
      final d = deck('al-qahhar@1');
      final pool = expectedOrder(d, null);
      final seenOrder = <String>[];

      for (var i = 0; i < pool.length; i++) {
        final s = await DeckVariantSelector.select(
          deck: d,
          surface: DeckVariantSurface.daily,
        );
        expect(s.cycled, isFalse, reason: 'encounter $i is still inside cycle 1');
        seenOrder.add(s.variantId);
        await DeckVariantSelector.markCompleted(s);
      }

      expect(seenOrder, pool,
          reason: 'priority order for an uncategorised reader: default (none '
              'here), primary, then the variants in asset order');

      final next = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
      );
      expect(next.cycled, isTrue);
      expect(next.variantId, pool.first);
      expect(next.encounterIndex, pool.length,
          reason: 'the encounter counter survives the cycle-clear');
    });

    test('the cycle CLEARS rather than appends, so cycle 2 repeats cycle 1',
        () async {
      final d = deck('al-qahhar@1');
      final pool = expectedOrder(d, null);

      final cycle1 = <String>[];
      final cycle2 = <String>[];
      for (final out in [cycle1, cycle2]) {
        for (var i = 0; i < pool.length; i++) {
          final s = await DeckVariantSelector.select(
            deck: d,
            surface: DeckVariantSurface.daily,
          );
          out.add(s.variantId);
          await DeckVariantSelector.markCompleted(s);
        }
      }

      expect(cycle2, cycle1);
      final state = await DeckVariantSelector.store.read(d.deckId);
      expect(state.completedEncounters, pool.length * 2);
      expect(state.seen.length, lessThanOrEqualTo(pool.length * 2),
          reason: 'the seen set is bounded — it is cleared, never appended to '
              'forever');
    });

    test('a cycled selection never freezes on primary', () async {
      final d = deck('al-qahhar@1');
      final pool = poolOf(d);
      final s = DeckVariantSelector.resolve(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
        seen: {
          for (final id in pool)
            deckVariantSeenKey(d.deckId, deckBeatKindBridge, id),
        },
      );

      expect(s.cycled, isTrue);
      expect(s.variantId, 'guilt',
          reason: 'after the clear, the category branch is live again');
      expect(s.source, AnalyticsEvents.deckVariantSourceCategory);
    });

    test('EVERY shipped deck completes a full cycle with no repeat and no '
        'fallback', () async {
      for (final d in allDecks) {
        DeckVariantSelector.store = InMemoryDeckVariantStore();
        final pool = expectedOrder(d, null);
        final visited = <String>[];
        for (var i = 0; i < pool.length; i++) {
          final s = await DeckVariantSelector.select(
            deck: d,
            surface: DeckVariantSurface.daily,
          );
          expect(s.hasPool, isTrue, reason: d.deckId);
          visited.add(s.variantId);
          await DeckVariantSelector.markCompleted(s);
        }
        expect(visited.toSet().length, pool.length, reason: d.deckId);
        expect(visited, pool, reason: d.deckId);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Determinism
  // ═══════════════════════════════════════════════════════════════════════════

  group('determinism', () {
    test('same deck + same seen-set + same category → same answer, always', () {
      for (final d in allDecks) {
        for (final category in [
          ...liveProblemCategories,
          problemCategoryUnmatched,
          null,
        ]) {
          final seen = {
            if (bridgeIds(d).isNotEmpty)
              deckVariantSeenKey(
                  d.deckId, deckBeatKindBridge, bridgeIds(d).first),
          };
          final a = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.daily,
            problemCategory: category,
            seen: seen,
          );
          final b = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.daily,
            problemCategory: category,
            seen: seen,
          );
          expect(a.variantId, b.variantId, reason: '${d.deckId} / $category');
          expect(a.source, b.source);
          expect(a.reflectionMatched, b.reflectionMatched);
          expect(a.selection, b.selection);
        }
      }
    });

    test('every id it ever emits exists on the beat it names', () {
      for (final d in allDecks) {
        for (final category in [
          ...liveProblemCategories,
          problemCategoryUnmatched,
          null,
        ]) {
          final s = DeckVariantSelector.resolve(
            deck: d,
            surface: DeckVariantSurface.daily,
            problemCategory: category,
          );
          s.selection.forEach((kind, id) {
            expect(const [deckBeatKindBridge, deckBeatKindReflection],
                contains(kind));
            final beat = beatOf(d, kind)!;
            expect(beat.variants.map((v) => v.id), contains(id),
                reason: '${d.deckId} $kind $id');
            // The builder must actually swap — never silently render primary.
            expect(beat.textForVariant(id), isNot(beat.primary));
          });
        }
      }
    });

    test('an empty selection is byte-identical to no personalisation at all',
        () {
      for (final d in allDecks) {
        final before = buildBeatScreensFromDeck(d);
        final after = buildBeatScreensFromDeck(d, selection: const {});
        expect(after.map((s) => s.primary).toList(),
            before.map((s) => s.primary).toList(),
            reason: d.deckId);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Persistence + account scoping
  // ═══════════════════════════════════════════════════════════════════════════

  group('SharedPreferences store', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      DeckVariantSelector.store = const SharedPreferencesDeckVariantStore();
    });

    test('round-trips through prefs', () async {
      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-a');
      final d = deck('al-qahhar@1');

      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(s);

      final reread = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(reread.variantId, isNot('guilt'));
      expect(reread.encounterIndex, 1);
    });

    test('the key is ACCOUNT-SCOPED — two accounts on one device do not '
        'inherit each other\'s rotation', () async {
      final d = deck('al-qahhar@1');

      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-a');
      final a = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(a);

      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-b');
      final b = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(b.variantId, 'guilt',
          reason: "user B's first encounter must not be user A's second");
      expect(b.encounterIndex, 0);

      final prefs = await SharedPreferences.getInstance();
      final key =
          '${SharedPreferencesDeckVariantStore.baseKeyPrefix}${d.deckId}';
      expect(prefs.getKeys(), contains('$key:user-a'));
      expect(prefs.getKeys(), isNot(contains('$key:user-b')),
          reason: 'user B never completed, so nothing was written');
      expect(prefs.getKeys(), isNot(contains(key)),
          reason: 'an unscoped key would be the shared-rotation bug itself');
    });

    test('user A\'s rotation survives a round trip through user B', () async {
      final d = deck('al-qahhar@1');

      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-a');
      final a = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(a);

      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-b');
      final b = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.markCompleted(b);

      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-a');
      final a2 = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(a2.encounterIndex, 1, reason: "user B's completion is not user A's");
    });

    test('a corrupt prefs value degrades to a first encounter', () async {
      final d = deck('al-qahhar@1');
      SupabaseSyncService.instance = FakeSupabaseSyncService(userId: 'user-a');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${SharedPreferencesDeckVariantStore.baseKeyPrefix}${d.deckId}:user-a',
        'not json at all',
      );

      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(s.variantId, 'guilt');
      expect(s.encounterIndex, 0);
    });
  });

  group('store failures never take the flow down', () {
    test('a throwing store still yields a usable selection', () async {
      DeckVariantSelector.store = _ThrowingStore();
      final s = await DeckVariantSelector.select(
        deck: deck('al-qahhar@1'),
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(s.variantId, 'guilt');
      // …and completing is a no-op rather than an exception.
      await DeckVariantSelector.markCompleted(s);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Instrumentation (D13 + §6)
  // ═══════════════════════════════════════════════════════════════════════════

  group('deck_variant_selected', () {
    test('one event per selection, with the full property set', () async {
      final d = deck('al-qahhar@1');
      final s = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.onboarding,
        problemCategory: 'guilt',
      );

      expect(events.length, 1);
      expect(events.single.$1, AnalyticsEvents.deckVariantSelected);
      expect(events.single.$2, {
        AnalyticsEvents.propDeckId: 'al-qahhar@1',
        AnalyticsEvents.propSource: AnalyticsEvents.deckVariantSourceChip,
        AnalyticsEvents.propVariantId: 'guilt',
        AnalyticsEvents.propReflectionMatched: true,
        AnalyticsEvents.propEncounterIndex: 0,
        AnalyticsEvents.propProblemCategory: 'guilt',
        AnalyticsEvents.propCategoryUnmatched: false,
      });
      expect(events.single.$2, s.analyticsProperties);
    });

    test('ONE event name on both surfaces, segmented by source (D13)',
        () async {
      final d = deck('al-qahhar@1');
      await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.onboarding,
        problemCategory: 'guilt',
      );
      await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(events.map((e) => e.$1).toSet(),
          {AnalyticsEvents.deckVariantSelected});
      expect(
        events.map((e) => e.$2[AnalyticsEvents.propSource]).toList(),
        [
          AnalyticsEvents.deckVariantSourceChip,
          AnalyticsEvents.deckVariantSourceCategory,
        ],
      );
    });

    test('problemCategoryUnmatched is instrumented from day one (§6)',
        () async {
      final d = deck('al-qahhar@1');
      await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: problemCategoryUnmatched,
      );
      await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
      );
      await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(
        events.map((e) => e.$2[AnalyticsEvents.propProblemCategory]).toList(),
        [
          problemCategoryUnmatched,
          AnalyticsEvents.deckVariantCategoryNone,
          'guilt',
        ],
      );
      expect(
        events.map((e) => e.$2[AnalyticsEvents.propCategoryUnmatched]).toList(),
        [true, true, false],
      );
    });

    test('encounter_index counts COMPLETED encounters and survives the cycle',
        () async {
      final d = deck('al-qahhar@1');
      final pool = poolOf(d);
      for (var i = 0; i < pool.length + 1; i++) {
        final s = await DeckVariantSelector.select(
          deck: d,
          surface: DeckVariantSurface.daily,
        );
        expect(s.encounterIndex, i);
        await DeckVariantSelector.markCompleted(s);
      }
      expect(
        events.map((e) => e.$2[AnalyticsEvents.propEncounterIndex]).toList(),
        [for (var i = 0; i < pool.length + 1; i++) i],
      );
    });

    test('the fallback branch reports the sentinel id, not a fake variant',
        () async {
      await DeckVariantSelector.select(
        deck: synthetic(const [NameStoryBeat(kind: 'bridge', primary: 'x')]),
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );

      expect(events.single.$2[AnalyticsEvents.propSource],
          AnalyticsEvents.deckVariantSourceFallback);
      expect(events.single.$2[AnalyticsEvents.propVariantId], primaryVariantId);
    });

    test('a null hook is a no-op', () async {
      DeckVariantSelector.onAnalyticsEvent = null;
      final s = await DeckVariantSelector.select(
        deck: deck('al-qahhar@1'),
        surface: DeckVariantSurface.daily,
        problemCategory: 'guilt',
      );
      expect(s.variantId, 'guilt');
      expect(events, isEmpty);
    });

    test('the source vocabulary is exactly the four §6 names', () {
      expect(
        {
          AnalyticsEvents.deckVariantSourceChip,
          AnalyticsEvents.deckVariantSourceCategory,
          AnalyticsEvents.deckVariantSourceRotation,
          AnalyticsEvents.deckVariantSourceFallback,
        },
        {'chip', 'category', 'rotation', 'fallback'},
      );
      expect(AnalyticsEvents.deckVariantSelected, 'deck_variant_selected');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Taxonomy coupling
  // ═══════════════════════════════════════════════════════════════════════════

  group('taxonomy', () {
    test('the live categories are read from problem_chips, not copied', () {
      expect(liveProblemCategories, {
        'anxiety',
        'heavy',
        'guilt',
        'far_from_allah',
        'rizq',
        'unseen',
        'unspoken',
      });
      expect(liveProblemCategories, isNot(contains(problemCategoryUnmatched)));
    });

    test('a chipKey is NOT a problemCategory — the selector takes the latter',
        () async {
      final d = deck('al-qahhar@1');
      final byChipKey = await DeckVariantSelector.select(
        deck: d,
        surface: DeckVariantSurface.onboarding,
        // `far-from-allah` is the CHIP key; `far_from_allah` is the category.
        problemCategory: 'far-from-allah',
      );
      expect(byChipKey.source, AnalyticsEvents.deckVariantSourceFallback,
          reason: 'a chip key must not resolve as a category — it is treated '
              'as unplaceable, exactly like `unmatched`');

      final byCategory = DeckVariantSelector.resolve(
        deck: d,
        surface: DeckVariantSurface.onboarding,
        problemCategory: 'far_from_allah',
      );
      expect(byCategory.source, AnalyticsEvents.deckVariantSourceChip);
      expect(byCategory.variantId, 'far_from_allah');
    });

    test('every variant id in the shipped asset is selectable', () {
      // Belt-and-braces against the ship gate: an id outside the taxonomy (plus
      // `default`) could only ever be reached by rotation, never by a category.
      final legal = {...liveProblemCategories, 'default'};
      for (final d in allDecks) {
        for (final beat in d.beats) {
          for (final v in beat.variants) {
            expect(legal, contains(v.id), reason: '${d.deckId} ${beat.kind}');
          }
        }
      }
    });
  });

  // The end-to-end invariant. Every other test here checks the selector against
  // ids; this one walks a reader through a whole rotation of all 99 decks and
  // checks what actually reaches the SCREEN. It is the only assertion that
  // spans the ship gate, the authored content, the ladder and the builder at
  // once — a duplicate could be introduced by any one of the four (a variant
  // whose text matches `primary`, a ladder that offers the same id twice, a
  // builder that ignores the selection) and no single-layer test would see it.
  //
  // Reads the bridge by BeatKind.keyLine rather than `screens.first`: the two
  // comfort decks prepend a `recognition` beat, so position 0 is not the bridge
  // there. Taking `first` reports every deck with a prepended beat as 6
  // duplicates — a false positive that cost a review pass to run down.
  group('rotation, end to end', () {
    test('one full cycle never shows the same sentence twice — 99 decks', () {
      final offenders = <String>[];
      for (final deck in allDecks) {
        // A reader the taxonomy placed, and one it could not.
        for (final category in ['guilt', problemCategoryUnmatched]) {
          final seen = <String>{};
          final rendered = <String>[];
          final ids = <String>[];
          for (var i = 0; i < 40; i++) {
            final s = DeckVariantSelector.resolve(
              deck: deck,
              surface: DeckVariantSurface.daily,
              problemCategory: category,
              seen: seen,
              encounterIndex: i,
            );
            // The cycle wrapping round is the end of this pass, not a failure.
            if (s.cycled) break;
            rendered.add(buildBeatScreensFromDeck(deck, selection: s.selection)
                .firstWhere((x) => x.kind == BeatKind.keyLine)
                .primary);
            ids.add(s.variantId);
            // A no-pool deck can never exhaust, so it would spin here forever.
            if (s.seenKeys.isEmpty) break;
            seen.addAll(s.seenKeys);
          }
          if (rendered.length != rendered.toSet().length) {
            offenders.add('${deck.deckId}/$category ids=$ids');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'a reader met the same bridge sentence twice inside one '
              'rotation, which is the thing rotation exists to prevent:\n'
              '${offenders.join('\n')}');
    });
  });
}

class _ThrowingStore implements DeckVariantStore {
  @override
  Future<DeckVariantDeckState> read(String deckId) async =>
      throw StateError('storage is on fire');

  @override
  Future<void> write(String deckId, DeckVariantDeckState state) async =>
      throw StateError('storage is on fire');
}
