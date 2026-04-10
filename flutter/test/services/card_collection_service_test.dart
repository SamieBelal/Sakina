import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('getCardCollection migrates legacy seen IDs into tier-aware entries',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_card_collection:user-1': jsonEncode({
        'ids': [5],
        'dates': {'5': '2026-04-01'},
        'tiers': {'5': 2},
        'tierUpDates': {'5': '2026-04-02'},
      }),
      'sakina_card_seen:user-1': ['5'],
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final collection = await getCardCollection();

    expect(collection.discoveredIds, contains(5));
    expect(collection.tierFor(5), 2);
    expect(collection.seenIds, containsAll({'5:1', '5:2'}));
    expect(collection.isUnseen(5, CardTier.bronze), isFalse);
    expect(collection.isUnseen(5, CardTier.silver), isFalse);
  });

  test(
      'engageCard progresses tiers, updates seen state, and avoids duplicate upserts',
      () async {
    final first = await engageCard(5);
    expect(first.isNew, isTrue);
    expect(first.newTier, 1);
    expect(first.tierChanged, isTrue);

    var collection = await getCardCollection();
    expect(collection.isUnseen(5), isTrue);
    expect(collection.cardTierFor(5), CardTier.bronze);

    await markCardSeen(5, tierNumber: 1);
    collection = await getCardCollection();
    expect(collection.isUnseen(5, CardTier.bronze), isFalse);

    final second = await engageCard(5);
    expect(second.isNew, isFalse);
    expect(second.newTier, 2);
    expect(second.tier, CardTier.silver);

    final third = await engageCard(5);
    expect(third.newTier, 3);
    expect(third.tier, CardTier.gold);

    final duplicate = await engageCard(5);
    expect(duplicate.isDuplicate, isTrue);
    expect(duplicate.tierChanged, isFalse);

    expect(fakeSync.upsertCalls, hasLength(3));
    expect(fakeSync.upsertCalls.last['table'], 'user_card_collection');
    expect((fakeSync.upsertCalls.last['data'] as Map)['tier'], 'gold');
  });

  test('engageCard migrates legacy unscoped collection before updating',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_card_collection': jsonEncode({
        'ids': [7],
        'dates': {'7': '2026-04-01'},
        'tiers': {'7': 1},
        'tierUpDates': {'7': '2026-04-01'},
      }),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await engageCard(7);
    final collection = await getCardCollection();
    final prefs = await SharedPreferences.getInstance();

    expect(result.isNew, isFalse);
    expect(result.newTier, 2);
    expect(collection.tierFor(7), 2);
    expect(prefs.getString('sakina_card_collection:user-1'), isNotNull);
  });

  test('seed and hydrate card collection map tiers and tolerate short dates',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_card_collection:user-1': jsonEncode({
        'ids': [5],
        'dates': {'5': '2026-04-01'},
        'tiers': {'5': 3},
        'tierUpDates': {'5': '2026-04-02'},
      }),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await seedCardCollectionToSupabaseFromLocalCache();
    expect(fakeSync.batchInsertCalls, hasLength(1));
    final seededRows = fakeSync.batchInsertCalls.single['rows'] as List;
    expect((seededRows.single as Map<String, dynamic>)['tier'], 'gold');

    await hydrateCardCollectionCacheFromRows([
      {
        'name_id': 5,
        'tier': 'silver',
        'discovered_at': '2026-04',
        'last_engaged_at': null,
      },
    ]);

    final collection = await getCardCollection();
    expect(collection.tierFor(5), 2);
    expect(collection.discoveryDates[5], '2026-04');
  });

  test('clearCardCollection wipes local state and deletes remote rows',
      () async {
    await engageCard(9);

    await clearCardCollection();

    final collection = await getCardCollection();
    expect(collection.discoveredIds, isEmpty);
    expect(collection.tiers, isEmpty);
    expect(fakeSync.deleteCalls, hasLength(1));
    expect(fakeSync.deleteCalls.single['table'], 'user_card_collection');
    expect(fakeSync.deleteCalls.single['column'], 'user_id');
    expect(fakeSync.deleteCalls.single['value'], 'user-1');
  });
}
