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

    test('unknown item type does NOT pollute the skins set on cache add',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 200,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      // Server (untrustworthy for the client cache-side symmetry) claims
      // success for a malformed/unknown item_type. The read side
      // (hydrateCosmeticsFromSync) drops unknown types; the write side must
      // be symmetric and NOT silently file it under skins.
      fakeSync.rpcHandlers['unlock_cosmetic'] = (params) async => true;

      final result = await unlockCosmetic(
        itemType: 'not_a_real_type',
        itemId: 'weird_item',
        noorPrice: 10,
      );

      expect(result.success, isTrue); // RPC path still succeeds
      final state = await getCosmeticsState();
      // The unknown type is dropped — it must not land in skins OR backdrops.
      expect(state.ownedLanternSkins, isEmpty);
      expect(state.ownedBackdrops, isEmpty);
    });
  });

  group('creditMintedMilestoneNoor (mirrors a server-minted milestone grant)',
      () {
    test('credits the cache and emits noor_earned exactly once', () async {
      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      await creditMintedMilestoneNoor(day: 30, amount: 150);

      final state = await getCosmeticsState();
      expect(state.noorBalance, 150);
      expect(events, hasLength(1));
      expect(events.single.$1, 'noor_earned');
      // The property shape must stay identical to awardDailyNoor's emit so the
      // analytics schema does not fork.
      expect(events.single.$2, {'amount': 150, 'reason': 'milestone:30'});
    });

    test('mirrors ONLY — it never calls an RPC (the server already minted)',
        () async {
      await creditMintedMilestoneNoor(day: 7, amount: 25);
      expect(fakeSync.rpcCalls, isEmpty,
          reason: 'the credit path must not re-invoke claim_streak_milestone '
              '— that would issue the RPC a second time');
    });

    test('amount 0 (replay / already-claimed / non-mintable day) credits '
        'nothing and emits nothing', () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 60,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      await creditMintedMilestoneNoor(day: 30, amount: 0);

      expect((await getCosmeticsState()).noorBalance, 60); // untouched
      expect(events, isEmpty);
    });

    test('a negative amount is refused (the client never debits here)',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 60,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      await creditMintedMilestoneNoor(day: 30, amount: -50);

      expect((await getCosmeticsState()).noorBalance, 60);
      expect(events, isEmpty);
    });

    test('day 90 is the top mintable milestone (client mirror of the RPC set)',
        () async {
      // Pins the client-side mirror of the server mint arms against drift.
      // 100 was a stray no client could ever send; a real 90-day streak used to
      // be rejected server-side as 'unrecognized milestone day 90'.
      expect(awardableMilestoneDays, {7, 14, 30, 60, 90});
    });
  });

  group('awardDailyNoor (server-derived amount AND dedupe key)', () {
    test('calls award_daily_noor with NO params at all', () async {
      // THE REGRESSION THIS PINS: the old awardNoor(reason:, reasonKey:) hit
      // `award_noor(p_reason, p_reason_key)` directly, letting the caller pick
      // both the amount (via the reason) and the dedupe key — so any
      // authenticated user could mint unlimited Noor by looping
      // ('milestone:90', <fresh key>) and spend it on à-la-carte skins.
      // 20260726200600_lock_down_award_noor.sql revoked award_noor from
      // `authenticated`; the client must now send NOTHING and let the server
      // derive both halves. An empty params map is the assertion.
      fakeSync.rpcHandlers['award_daily_noor'] = (params) async => 10;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardDailyNoor();

      expect(granted, 10);
      expect(fakeSync.rpcCalls.single['fn'], 'award_daily_noor');
      expect(fakeSync.rpcCalls.single['params'], isEmpty);
      expect(events.single.$1, 'noor_earned');
      expect(events.single.$2, {'amount': 10, 'reason': 'daily'});
    });

    test('never calls the revoked award_noor RPC', () async {
      fakeSync.rpcHandlers['award_daily_noor'] = (params) async => 10;
      await awardDailyNoor();
      expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'award_noor'), isEmpty);
    });

    test('idempotent replay (returns 0) mints nothing + emits nothing',
        () async {
      // 0 is also what the server returns when the caller has no checkin
      // recorded for today — the anti-forgery path. Same client handling.
      fakeSync.rpcHandlers['award_daily_noor'] = (params) async => 0;
      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardDailyNoor();

      expect(granted, 0);
      expect(events, isEmpty);
    });

    test('unauthenticated: no RPC call', () async {
      fakeSync.userId = null;
      final granted = await awardDailyNoor();
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

    test('rejection (unowned → RPC raises → null): equipped cache unchanged, '
        'emits rejected exactly once', () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      // No handler → null (server raised "cannot equip unowned item").
      final result = await equipCosmetic(
        itemType: 'lantern_skin',
        itemId: 'obsidian_gold',
      );
      expect(result.success, isFalse);
      final state = await getCosmeticsState();
      expect(state.equippedLanternSkin, 'classic_gold');

      // A failed equip is observable — emits cosmetic_unlock_rejected once.
      final rejected =
          events.where((e) => e.$1 == 'cosmetic_unlock_rejected').toList();
      expect(rejected, hasLength(1));
      expect(rejected.single.$2, {
        'item_type': 'lantern_skin',
        'item_id': 'obsidian_gold',
        'reason': 'rpc_declined',
      });
    });

    test('success path does NOT emit the rejected event', () async {
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
      expect(events.where((e) => e.$1 == 'cosmetic_unlock_rejected'), isEmpty);
      expect(events.single.$1, 'cosmetic_equipped');
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

  group('syncPremiumCosmetics (deferred — OQ-2/§13.7)', () {
    test('non-premium: no RPC call, returns 0', () async {
      final n = await syncPremiumCosmetics(
        purchaseService: StubPurchaseService(false),
      );
      expect(n, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('premium but RPC absent (null): graceful 0, mirrors nothing',
        () async {
      // grant_premium_cosmetics not registered → callRpc returns null.
      final n = await syncPremiumCosmetics(
        purchaseService: StubPurchaseService(true),
      );
      expect(n, 0);
      final state = await getCosmeticsState();
      expect(state.ownedLanternSkins, isEmpty);
    });

    test('premium + RPC grants rows: mirrors granted skins into ownership cache',
        () async {
      fakeSync.rpcHandlers['grant_premium_cosmetics'] = (params) async => {
            'granted': [
              {'item_type': 'lantern_skin', 'item_id': 'ramadan_royal'},
            ],
          };
      final n = await syncPremiumCosmetics(
        purchaseService: StubPurchaseService(true),
      );
      expect(n, 1);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'ramadan_royal'), isTrue);
    });
  });
}
