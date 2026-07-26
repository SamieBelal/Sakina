import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
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
}
