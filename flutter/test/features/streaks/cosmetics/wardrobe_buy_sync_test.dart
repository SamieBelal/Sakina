// The wardrobe's Buy path contract (spec §6 store integration, §13 item 4).
//
// The locked ruling this pins: the CLIENT NEVER GRANTS. `grant_cosmetic_iap` is
// service_role-only (revoked from `authenticated`) and is called by the
// RevenueCat webhook. The client runs the RC purchase, then re-syncs — and the
// skin surfaces as owned only because the post-sync `cosmetics` section says so.
//
// DB-free: the sync service is faked, so every RPC the client would issue is
// observable in `fakeSync.rpcCalls`.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test(
      'buy re-syncs and surfaces ownership from the cosmetics section — '
      'the client issues NO grant RPC', () async {
    var synced = 0;

    // Stands in for the post-purchase `sync_all_user_data()` read: the webhook
    // has already granted server-side, so the payload comes back with the skin
    // in the `cosmetics` section.
    Future<void> fakeSyncNow() async {
      synced++;
      await hydrateCosmeticsFromSync(
        noorBalance: 40,
        equippedLanternSkin: defaultLanternSkin,
        equippedBackdrop: defaultBackdrop,
        owned: const [
          {
            'item_type': itemTypeLanternSkin,
            'item_id': 'obsidian_gold',
            'acquired_via': 'iap',
          },
        ],
      );
    }

    final res = await completeSkinIapPurchase(
      productId: 'sakina.skin.obsidian',
      syncNow: fakeSyncNow,
    );

    expect(res.success, isTrue);
    expect(synced, 1);

    final state = await getCosmeticsState();
    expect(state.owns(itemTypeLanternSkin, 'obsidian_gold'), isTrue);

    // The whole point: no client-side grant, by any name.
    final calledFns = fakeSync.rpcCalls.map((c) => c['fn']).toList();
    expect(calledFns, isNot(contains('grant_cosmetic_iap')));
    expect(calledFns, isEmpty);
  });

  test('an unrecognized SKU is refused without syncing', () async {
    var synced = false;
    final res = await completeSkinIapPurchase(
      productId: 'not.a.skin',
      syncNow: () async => synced = true,
    );

    expect(res.success, isFalse);
    expect(synced, isFalse);
    expect(fakeSync.rpcCalls, isEmpty);
  });

  test('a failed re-sync reports failure and grants nothing locally', () async {
    final res = await completeSkinIapPurchase(
      productId: 'sakina.skin.obsidian',
      syncNow: () async => throw StateError('network'),
    );

    expect(res.success, isFalse);
    final state = await getCosmeticsState();
    expect(state.owns(itemTypeLanternSkin, 'obsidian_gold'), isFalse);
    expect(fakeSync.rpcCalls.map((c) => c['fn']),
        isNot(contains('grant_cosmetic_iap')));
  });

  test('an unauthenticated caller is refused before any sync', () async {
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService());
    var synced = false;
    final res = await completeSkinIapPurchase(
      productId: 'sakina.skin.obsidian',
      syncNow: () async => synced = true,
    );

    expect(res.success, isFalse);
    expect(synced, isFalse);
  });
}
