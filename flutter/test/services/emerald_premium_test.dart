import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Fake premium/free users. `PurchaseService()` returns the debug override when
/// one is set, so overriding `isPremium()` steers `premiumTierCeiling()` and
/// `reconcilePremiumEmeralds()`.
class _PremiumUser extends PurchaseService {
  _PremiumUser() : super.test();
  @override
  Future<bool> isPremium() async => true;
}

class _FreeUser extends PurchaseService {
  _FreeUser() : super.test();
  @override
  Future<bool> isPremium() async => false;
}

/// Seed the scoped collection prefs JSON directly for precise tier control.
/// Shape mirrors production: {ids, dates, tiers, tierUpDates}, tiers keyed by
/// card-id-as-string → int. `seen` (optional) seeds the scoped seen list.
Map<String, Object> _seedPrefs({
  required Map<int, int> tiers,
  List<String> seen = const [],
}) {
  const date = '2026-05-01';
  return {
    'sakina_card_collection:user-1': jsonEncode({
      'ids': tiers.keys.toList(),
      'dates': {for (final id in tiers.keys) '$id': date},
      'tiers': {for (final e in tiers.entries) '${e.key}': e.value},
      'tierUpDates': {for (final id in tiers.keys) '$id': date},
    }),
    'sakina_card_seen:user-1': seen,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
    // reconcilePremiumEmeralds / hydrateCardCollectionCacheFromRows now publish
    // CardCollectionChanged; reset the bus so those events don't leak into a
    // later test's EconomyEvents subscribers.
    await EconomyEvents.resetForTest();
  });

  group('engageCard ceiling', () {
    test('free (maxTier:3): a Gold card does NOT tier up — stays Gold', () async {
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 3}, seen: ['5:1', '5:2', '5:3']),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      final result = await engageCard(5); // default maxTier = 3

      expect(result.newTier, 3);
      expect(result.tierChanged, isFalse);
      expect(result.isDuplicate, isTrue);

      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.gold);
      // No tier-up → no upsert to Supabase.
      expect(fakeSync.upsertCalls, isEmpty);
    });

    test('premium (maxTier:4): a Gold card tiers up to Emerald + unseen glow',
        () async {
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 3}, seen: ['5:1', '5:2', '5:3']),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      final result = await engageCard(5, maxTier: 4);

      expect(result.newTier, 4);
      expect(result.tierChanged, isTrue);
      expect(result.isDuplicate, isFalse);
      expect(result.tier, CardTier.emerald);

      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.emerald);
      // The new emerald tile is unseen → carries the new-card glow.
      expect(collection.isUnseen(5, CardTier.emerald), isTrue);

      // Tier-up persisted upstream as 'emerald'.
      expect(fakeSync.upsertCalls, hasLength(1));
      expect(fakeSync.upsertCalls.single['table'], 'user_card_collection');
      expect((fakeSync.upsertCalls.single['data'] as Map)['tier'], 'emerald');
    });

    test('emerald is the ceiling: an Emerald card does not exceed tier 4',
        () async {
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 4}, seen: ['5:1', '5:2', '5:3', '5:4']),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);

      final result = await engageCard(5, maxTier: 4);

      expect(result.newTier, 4);
      expect(result.tierChanged, isFalse);
      expect(result.isDuplicate, isTrue);

      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.emerald);
      expect(fakeSync.upsertCalls, isEmpty);
    });
  });

  group('pickNextCard ceiling', () {
    // Build a collection where EVERY discovered name is Gold (tier 3) and none
    // are undiscovered. This is the only state in which the gold-for-tierup
    // branch is reachable, so it isolates the maxTier gate.
    Future<CardCollectionState> allGoldCollection() async {
      final names = currentCollectibleNames();
      final tiers = {for (final n in names) n.id: 3};
      SharedPreferences.setMockInitialValues(_seedPrefs(tiers: tiers));
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      return getCardCollection();
    }

    test('free (maxTier:3): gold is NOT offered for tier-up (falls to random)',
        () async {
      final collection = await allGoldCollection();
      // With no undiscovered/bronze/silver and maxTier 3, the gold branch is
      // skipped. The fallback returns any random card — but every card is gold,
      // so the invariant we can assert is that the free path never claims a
      // tier-up is possible: engaging the returned card stays at Gold.
      final picked = pickNextCard(collection, maxTier: 3);
      expect(collection.tierFor(picked.id), 3);

      final result = await engageCard(picked.id); // default maxTier 3
      expect(result.tierChanged, isFalse);
      expect(result.isDuplicate, isTrue);
    });

    test('premium (maxTier:4): returns a Gold card so it can tier to Emerald',
        () async {
      final collection = await allGoldCollection();
      final picked = pickNextCard(collection, maxTier: 4);
      // Deterministic: all cards are gold, so any returned card is tier 3 and
      // is eligible to tier up to emerald under maxTier 4.
      expect(collection.tierFor(picked.id), 3);

      final result = await engageCard(picked.id, maxTier: 4);
      expect(result.newTier, 4);
      expect(result.tierChanged, isTrue);
    });
  });

  group('premiumTierCeiling', () {
    test('free user → 3', () async {
      PurchaseService.debugSetOverride(_FreeUser());
      expect(await premiumTierCeiling(), 3);
    });

    test('premium user → 4', () async {
      PurchaseService.debugSetOverride(_PremiumUser());
      expect(await premiumTierCeiling(), 4);
    });
  });

  group('reconcilePremiumEmeralds', () {
    test('free user: returns 0 and issues NO backfill rpc', () async {
      PurchaseService.debugSetOverride(_FreeUser());
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 3, 9: 3}),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      fakeSync.rpcHandlers['backfill_emerald_cards'] = (_) async => [5, 9];

      final count = await reconcilePremiumEmeralds();

      expect(count, 0);
      expect(
        fakeSync.rpcCalls.where((c) => c['fn'] == 'backfill_emerald_cards'),
        isEmpty,
      );
      // Collection untouched.
      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.gold);
      expect(collection.cardTierFor(9), CardTier.gold);
    });

    test('premium: promotes returned Gold cards to Emerald + marks them unseen',
        () async {
      PurchaseService.debugSetOverride(_PremiumUser());
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 3, 9: 3}, seen: ['5:1', '5:2', '5:3', '5:4']),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      fakeSync.rpcHandlers['backfill_emerald_cards'] = (_) async => [5, 9];

      final count = await reconcilePremiumEmeralds();

      expect(count, 2);
      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.emerald);
      expect(collection.cardTierFor(9), CardTier.emerald);
      // Newly promoted emerald tiles carry the new-card glow.
      expect(collection.isUnseen(5, CardTier.emerald), isTrue);
      expect(collection.isUnseen(9, CardTier.emerald), isTrue);
    });

    test(
        'premium: parses MAP-wrapped RPC rows ([{name_id: 5}, ...]) → promotes both',
        () async {
      // PostgREST can return a `setof int` RPC as scalar ints OR as
      // single-key map rows depending on driver/version. The other premium
      // test covers bare ints; this pins the `e is Map → e.values.first`
      // branch (the shape production may actually receive).
      PurchaseService.debugSetOverride(_PremiumUser());
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 3, 9: 3}),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      fakeSync.rpcHandlers['backfill_emerald_cards'] =
          (_) async => [
                {'name_id': 5},
                {'name_id': 9},
              ];

      final count = await reconcilePremiumEmeralds();

      expect(count, 2);
      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.emerald);
      expect(collection.cardTierFor(9), CardTier.emerald);
    });

    test('idempotency: premium, RPC returns [] → returns 0, no mutation',
        () async {
      PurchaseService.debugSetOverride(_PremiumUser());
      SharedPreferences.setMockInitialValues(
        _seedPrefs(tiers: {5: 3}),
      );
      fakeSync = FakeSupabaseSyncService(userId: 'user-1');
      SupabaseSyncService.debugSetInstance(fakeSync);
      fakeSync.rpcHandlers['backfill_emerald_cards'] = (_) async => <int>[];

      final count = await reconcilePremiumEmeralds();

      expect(count, 0);
      final collection = await getCardCollection();
      // Card seeded at Gold stays Gold — guards the launch-burst regression.
      expect(collection.cardTierFor(5), CardTier.gold);
    });
  });

  group('hydration round-trip', () {
    test('an emerald row survives hydrate → renders as CardTier.emerald',
        () async {
      await hydrateCardCollectionCacheFromRows([
        {
          'name_id': 5,
          'tier': 'emerald',
          'discovered_at': '2026-05-01',
          'last_engaged_at': '2026-05-02',
        },
      ]);

      final collection = await getCardCollection();
      expect(collection.cardTierFor(5), CardTier.emerald);
      expect(collection.tierFor(5), 4);
    });
  });

  group('unseenCount (Collection nav-tab badge source)', () {
    test('counts every unopened tier-card across the collection', () {
      // Card 5 → Emerald (tiers 1-4), bronze+silver already opened.
      // Card 9 → Gold (tiers 1-3), none opened.
      const state = CardCollectionState(
        discoveredIds: {5, 9},
        tiers: {5: 4, 9: 3},
        seenIds: {'5:1', '5:2'},
      );
      // card 5: tiers 3,4 unseen = 2; card 9: tiers 1,2,3 unseen = 3.
      expect(state.unseenCount, 5);
    });

    test('is zero when every unlocked tier has been opened', () {
      const state = CardCollectionState(
        discoveredIds: {5},
        tiers: {5: 3},
        seenIds: {'5:1', '5:2', '5:3'},
      );
      expect(state.unseenCount, 0);
    });
  });
}
