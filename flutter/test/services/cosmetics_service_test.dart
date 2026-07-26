import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

class StubPurchaseService extends PurchaseService {
  StubPurchaseService(this.premium) : super.test();
  final bool premium;
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('fresh user reads defaults: 0 noor, classic_gold + default equipped, '
      'no owned', () async {
    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.equippedBackdrop, 'default');
    expect(state.ownedLanternSkins, isEmpty);
    expect(state.ownedBackdrops, isEmpty);
    expect(state.owns('lantern_skin', 'moonlit_silver'), isFalse);
  });

  test('hydrateCosmeticsFromSync writes balance, equipped, and owned caches',
      () async {
    await hydrateCosmeticsFromSync(
      noorBalance: 240,
      equippedLanternSkin: 'emerald_jade',
      equippedBackdrop: 'laylat_night',
      owned: const [
        {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'},
        {'item_type': 'lantern_skin', 'item_id': 'moonlit_silver'},
        {'item_type': 'backdrop', 'item_id': 'laylat_night'},
      ],
    );

    final state = await getCosmeticsState();
    expect(state.noorBalance, 240);
    expect(state.equippedLanternSkin, 'emerald_jade');
    expect(state.equippedBackdrop, 'laylat_night');
    expect(state.ownedLanternSkins,
        containsAll(<String>['emerald_jade', 'moonlit_silver']));
    expect(state.ownedBackdrops, contains('laylat_night'));
    expect(state.owns('lantern_skin', 'moonlit_silver'), isTrue);
    expect(state.owns('backdrop', 'emerald_sanctuary'), isFalse);
  });

  test('hydration is scoped per user (no cross-account bleed)', () async {
    await hydrateCosmeticsFromSync(
      noorBalance: 500,
      equippedLanternSkin: 'obsidian_gold',
      equippedBackdrop: 'default',
      owned: const [
        {'item_type': 'lantern_skin', 'item_id': 'obsidian_gold'},
      ],
    );

    // Switch to a different user — caches must not carry over.
    fakeSync.userId = 'user-2';
    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.ownedLanternSkins, isEmpty);
  });

  group('unlockCosmetic', () {
    test('success: mirrors ownership + debits noor cache + emits analytics',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 200,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      fakeSync.rpcHandlers['unlock_cosmetic'] = (params) async => true;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent =
          (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await unlockCosmetic(
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        noorPrice: 120,
      );

      expect(result.success, isTrue);
      expect(fakeSync.rpcCalls.single['fn'], 'unlock_cosmetic');
      expect(fakeSync.rpcCalls.single['params'],
          {'p_item_type': 'lantern_skin', 'p_item_id': 'moonlit_silver'});

      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'moonlit_silver'), isTrue);
      expect(state.noorBalance, 80); // 200 - 120

      expect(events.single.$1, 'cosmetic_unlocked');
      expect(events.single.$2,
          {'item_type': 'lantern_skin', 'item_id': 'moonlit_silver',
           'via': 'noor'});
    });

    test('rejection (RPC raises → null): no cache mutation, emits rejected',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 10,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      // No handler registered → FakeSupabaseSyncService.callRpc returns null,
      // exactly like callRpc swallowing a server RAISE.

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await unlockCosmetic(
        itemType: 'lantern_skin',
        itemId: 'masjid_brass',
        noorPrice: 300,
      );

      expect(result.success, isFalse);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'masjid_brass'), isFalse);
      expect(state.noorBalance, 10); // untouched
      expect(events.single.$1, 'cosmetic_unlock_rejected');
    });

    test('unauthenticated: returns failure without an RPC call', () async {
      fakeSync.userId = null;
      final result = await unlockCosmetic(
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        noorPrice: 120,
      );
      expect(result.success, isFalse);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });

  group('awardMilestoneNoor (ordered after claim_streak_milestone)', () {
    test('awards Noor ONLY after a confirmed claim; correct reason_key shape',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (params) async => {'newly_claimed': true};
      fakeSync.rpcHandlers['award_noor'] = (params) async => 150; // milestone:30

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardMilestoneNoor(30);

      expect(granted, 150);
      // Ordering: claim BEFORE award.
      final fns = fakeSync.rpcCalls.map((c) => c['fn']).toList();
      expect(fns, ['claim_streak_milestone', 'award_noor']);
      // Server-shaped reason_key.
      expect(fakeSync.rpcCalls[1]['params'],
          {'p_reason': 'milestone:30', 'p_reason_key': 'milestone:30'});
      // Analytics.
      expect(events.single.$1, 'noor_earned');
      expect(events.single.$2, {'amount': 150, 'reason': 'milestone:30'});
    });

    test('does NOT award when claim reports already-claimed (newly=false)',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (params) async => {'newly_claimed': false};
      fakeSync.rpcHandlers['award_noor'] = (params) async => 150;

      final granted = await awardMilestoneNoor(30);

      expect(granted, 0);
      final fns = fakeSync.rpcCalls.map((c) => c['fn']).toList();
      expect(fns, ['claim_streak_milestone']); // award_noor NEVER called
    });

    test('does NOT award when claim RPC fails (null)', () async {
      // No claim handler → returns null (RPC unavailable / raised).
      fakeSync.rpcHandlers['award_noor'] = (params) async => 150;

      final granted = await awardMilestoneNoor(7);

      expect(granted, 0);
      expect(fakeSync.rpcCalls.map((c) => c['fn']),
          isNot(contains('award_noor')));
    });

    test('idempotent-replay: award_noor returns 0 → no analytics, no crash',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (params) async => {'newly_claimed': true};
      fakeSync.rpcHandlers['award_noor'] = (params) async => 0; // deduped

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardMilestoneNoor(30);

      expect(granted, 0);
      expect(events, isEmpty); // a 0-amount replay emits nothing
    });

    test('unrecognized milestone day is refused client-side (no RPC calls)',
        () async {
      final granted = await awardMilestoneNoor(999);
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('unauthenticated: no RPC calls, returns 0', () async {
      fakeSync.userId = null;
      final granted = await awardMilestoneNoor(30);
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });

  group('awardNoor (daily / quest — reason vs reason_key split)', () {
    test('daily: coarse reason drives amount, scoped reason_key dedupes',
        () async {
      fakeSync.rpcHandlers['award_noor'] = (params) async => 10;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardNoor(
        reason: 'daily',
        reasonKey: 'daily:2026-07-25',
      );

      expect(granted, 10);
      expect(fakeSync.rpcCalls.single['params'],
          {'p_reason': 'daily', 'p_reason_key': 'daily:2026-07-25'});
      expect(events.single.$1, 'noor_earned');
      expect(events.single.$2, {'amount': 10, 'reason': 'daily'});
    });

    test('idempotent replay (returns 0) mints nothing + emits nothing',
        () async {
      fakeSync.rpcHandlers['award_noor'] = (params) async => 0;
      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted =
          await awardNoor(reason: 'daily', reasonKey: 'daily:2026-07-25');

      expect(granted, 0);
      expect(events, isEmpty);
    });

    test('refuses a reason the RPC does not recognize (no RPC call)', () async {
      final granted =
          await awardNoor(reason: 'bogus', reasonKey: 'bogus:1');
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('unauthenticated: no RPC call', () async {
      fakeSync.userId = null;
      final granted =
          await awardNoor(reason: 'daily', reasonKey: 'daily:2026-07-25');
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });

  group('equipCosmetic', () {
    test('success: mirrors equipped cache + emits analytics', () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [
          {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'},
        ],
      );
      fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await equipCosmetic(
        itemType: 'lantern_skin',
        itemId: 'emerald_jade',
      );

      expect(result.success, isTrue);
      expect(fakeSync.rpcCalls.single['params'],
          {'p_item_type': 'lantern_skin', 'p_item_id': 'emerald_jade'});
      final state = await getCosmeticsState();
      expect(state.equippedLanternSkin, 'emerald_jade');
      expect(events.single.$1, 'cosmetic_equipped');
      expect(events.single.$2,
          {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'});
    });

    test('backdrop success updates the backdrop slot, not the skin slot',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [
          {'item_type': 'backdrop', 'item_id': 'laylat_night'},
        ],
      );
      fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

      await equipCosmetic(itemType: 'backdrop', itemId: 'laylat_night');
      final state = await getCosmeticsState();
      expect(state.equippedBackdrop, 'laylat_night');
      expect(state.equippedLanternSkin, 'classic_gold'); // untouched
    });

    test('rejection (unowned → RPC raises → null): equipped cache unchanged',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      // No handler → null (server raised "cannot equip unowned item").
      final result = await equipCosmetic(
        itemType: 'lantern_skin',
        itemId: 'obsidian_gold',
      );
      expect(result.success, isFalse);
      final state = await getCosmeticsState();
      expect(state.equippedLanternSkin, 'classic_gold');
    });
  });

  group('canEquip (premium-exclusive resolution — OQ-1 conservative)', () {
    test('owned item is always equippable', () async {
      const state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {'moonlit_silver'},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        isPremiumExclusive: false,
        purchaseService: StubPurchaseService(false),
      );
      expect(can, isTrue);
    });

    test('premium-exclusive + premium user (not owned) IS equippable', () async {
      const state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'ramadan_royal',
        isPremiumExclusive: true,
        purchaseService: StubPurchaseService(true),
      );
      expect(can, isTrue);
    });

    test('premium-exclusive + NON-premium user (not owned) is NOT equippable',
        () async {
      const state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'ramadan_royal',
        isPremiumExclusive: true,
        purchaseService: StubPurchaseService(false),
      );
      expect(can, isFalse);
    });

    test('non-exclusive + not owned is NOT equippable (must unlock first)',
        () async {
      const state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        isPremiumExclusive: false,
        purchaseService: StubPurchaseService(true),
      );
      expect(can, isFalse);
    });
  });

  group('completeSkinIapPurchase (webhook-granted; purchase→sync, NO client '
      'grant RPC)', () {
    test('success: triggers a full sync that reflects webhook-granted ownership'
        ', emits analytics, calls NO grant RPC', () async {
      // Simulate the webhook having granted server-side: the injected sync
      // hydrates the cosmetics section WITH the new skin, exactly as the
      // post-purchase sync_all_user_data() would return it. (Named `fakeSyncNow`
      // to avoid confusion with the ambient `fakeSync` FakeSupabaseSyncService.)
      var syncCalls = 0;
      Future<void> fakeSyncNow() async {
        syncCalls += 1;
        await hydrateCosmeticsFromSync(
          noorBalance: 0,
          equippedLanternSkin: 'classic_gold',
          equippedBackdrop: 'default',
          owned: const [
            {'item_type': 'lantern_skin', 'item_id': 'obsidian_gold'},
          ],
        );
      }

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await completeSkinIapPurchase(
        productId: 'sakina.skin.obsidian',
        syncNow: fakeSyncNow,
      );

      expect(result.success, isTrue);
      expect(syncCalls, 1);
      // The client grants NOTHING — no grant_cosmetic_iap RPC anywhere.
      // (`fakeSync` is the ambient FakeSupabaseSyncService from setUp; the
      // injected fakeSync() closure above only writes caches, never an RPC.)
      expect(fakeSync.rpcCalls.map((c) => c['fn']),
          isNot(contains('grant_cosmetic_iap')));
      // Ownership is surfaced by the SYNC, not by a client grant.
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'obsidian_gold'), isTrue);
      // Fresh-purchase analytics (client-observed RC success + item label).
      expect(events.single.$1, 'cosmetic_iap_purchased');
      expect(events.single.$2,
          {'item_id': 'obsidian_gold', 'product_id': 'sakina.skin.obsidian'});
    });

    test('unknown product id is refused client-side (no sync, no analytics)',
        () async {
      var syncCalls = 0;
      Future<void> fakeSyncNow() async => syncCalls += 1;
      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await completeSkinIapPurchase(
        productId: 'sakina.tokens_100',
        syncNow: fakeSyncNow,
      );

      expect(result.success, isFalse);
      expect(syncCalls, 0);
      expect(events, isEmpty);
    });

    test('never calls grant_cosmetic_iap on the client (revoked contract)',
        () async {
      Future<void> fakeSyncNow() async {} // webhook grant not yet reflected
      await completeSkinIapPurchase(
        productId: 'sakina.skin.masjid',
        syncNow: fakeSyncNow,
      );
      // `fakeSync` here is the ambient FakeSupabaseSyncService from setUp.
      expect(fakeSync.rpcCalls.map((c) => c['fn']),
          isNot(contains('grant_cosmetic_iap')));
    });

    test('unauthenticated: no sync, returns failure', () async {
      fakeSync.userId = null;
      var syncCalls = 0;
      final result = await completeSkinIapPurchase(
        productId: 'sakina.skin.obsidian',
        syncNow: () async => syncCalls += 1,
      );
      expect(result.success, isFalse);
      expect(syncCalls, 0);
    });
  });

  test('skinIapProductToItem maps the three à-la-carte SKUs', () {
    expect(skinIapProductToItem['sakina.skin.obsidian'], 'obsidian_gold');
    expect(skinIapProductToItem['sakina.skin.masjid'], 'masjid_brass');
    expect(skinIapProductToItem['sakina.skin.crystal'], 'crystal_star');
    expect(skinIapProductToItem.containsKey('sakina.tokens_100'), isFalse);
  });

  group('restoreSkinIaps (restore→webhook→sync, NO client grant RPC)', () {
    test('runs restore then a full sync that surfaces restored ownership; '
        'client calls NO grant RPC', () async {
      var restoreCalls = 0;
      var syncCalls = 0;
      Future<void> fakeRestore() async => restoreCalls += 1;
      // The injected sync stands in for sync_all_user_data() AFTER the webhook
      // re-granted on the RC restore re-fire: the cosmetics section now carries
      // the restored skin.
      Future<void> fakeSyncNow() async {
        syncCalls += 1;
        await hydrateCosmeticsFromSync(
          noorBalance: 0,
          equippedLanternSkin: 'classic_gold',
          equippedBackdrop: 'default',
          owned: const [
            {'item_type': 'lantern_skin', 'item_id': 'crystal_star'},
          ],
        );
      }

      final result = await restoreSkinIaps(
        restore: fakeRestore,
        syncNow: fakeSyncNow,
      );

      expect(result.success, isTrue);
      expect(restoreCalls, 1);
      expect(syncCalls, 1);
      // Restore surfaces ownership VIA THE SYNC, not a client grant RPC.
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'crystal_star'), isTrue);
      expect(fakeSync.rpcCalls.map((c) => c['fn']),
          isNot(contains('grant_cosmetic_iap')));
    });

    test('unauthenticated: neither restore nor sync runs', () async {
      fakeSync.userId = null;
      var restoreCalls = 0;
      var syncCalls = 0;
      final result = await restoreSkinIaps(
        restore: () async => restoreCalls += 1,
        syncNow: () async => syncCalls += 1,
      );
      expect(result.success, isFalse);
      expect(restoreCalls, 0);
      expect(syncCalls, 0);
    });
  });
}
