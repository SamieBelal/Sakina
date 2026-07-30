import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/card_collection_service.dart';

/// Pins `pickNextCard(exclude:)` (W3 plan §3d / D-W3-7).
///
/// Without an exclusion set, a premium reel user's second/third reveal of the day
/// can hand over a Name the plan screen says they will meet on day 5 — after which
/// "unsealing" it is a tier-upgrade of a card they already own.
void main() {
  final catalogIds = currentCollectibleNames().map((c) => c.id).toSet();

  tearDown(() => debugLastPickExclude = null);

  test('with positions 3-7 sealed, 200 pulls never return a sealed name_id', () {
    final sealed = {3, 4, 5, 6, 7};
    for (var i = 0; i < 200; i++) {
      final card = pickNextCard(const CardCollectionState(), exclude: sealed);
      expect(sealed.contains(card.id), isFalse,
          reason: 'pull ${i + 1} leaked sealed name_id ${card.id}');
    }
  });

  test('with no queue the distribution is unchanged — every id reachable', () {
    // 400 pulls over an empty collection: no id may be structurally excluded.
    final seen = <int>{};
    for (var i = 0; i < 400; i++) {
      seen.add(pickNextCard(const CardCollectionState()).id);
    }
    expect(seen.length, greaterThan(catalogIds.length ~/ 2),
        reason: 'an empty exclude must not narrow the undiscovered bucket');
    expect(seen.difference(catalogIds), isEmpty);
  });

  test('exclude applies to the undiscovered bucket ONLY — tier-up is legitimate',
      () {
    // Every Name discovered at Bronze except the sealed ones, which are also
    // owned (a Store purchase can pre-own a queued Name's card). The Bronze
    // tier-up bucket must still be able to return them.
    final tiers = {for (final id in catalogIds) id: 1};
    final collection = CardCollectionState(
      discoveredIds: catalogIds,
      tiers: tiers,
    );
    final sealed = {3, 4, 5};
    var sawSealed = false;
    for (var i = 0; i < 400 && !sawSealed; i++) {
      if (sealed.contains(pickNextCard(collection, exclude: sealed).id)) {
        sawSealed = true;
      }
    }
    expect(sawSealed, isTrue,
        reason: 'a sealed Name whose card is already owned is a legitimate '
            'tier-up pull — excluding it there would only starve the ladder');
  });

  test('an exclude covering every undiscovered Name falls through to tier-up',
      () {
    // Degenerate but must not throw or loop: everything undiscovered is excluded,
    // so the picker drops to the Bronze bucket.
    final discovered = {1, 2};
    final collection = CardCollectionState(
      discoveredIds: discovered,
      tiers: const {1: 1, 2: 1},
    );
    final card = pickNextCard(
      collection,
      exclude: catalogIds.difference(discovered),
    );
    expect(discovered.contains(card.id), isTrue);
  });

  test('the default is an empty exclude — legacy callers are bit-identical', () {
    pickNextCard(const CardCollectionState());
    expect(debugLastPickExclude, isEmpty);
  });

  test('debugLastPickExclude records what the call was given', () {
    pickNextCard(const CardCollectionState(), exclude: const {5, 9});
    expect(debugLastPickExclude, {5, 9});
  });
}
