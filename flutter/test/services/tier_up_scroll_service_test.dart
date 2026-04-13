import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

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

  test('hydrateTierUpScrollCache writes hydrated balance', () async {
    await prepareTierUpScrollCacheForHydration();
    await hydrateTierUpScrollCache(balance: 7);

    expect((await getTierUpScrolls()).balance, 7);
  });

  test('earnTierUpScrolls uses RPC result for authenticated users', () async {
    fakeSync.rpcHandlers['earn_scrolls'] = (params) async => 12;

    final result = await earnTierUpScrolls(4);

    expect(result.success, isTrue);
    expect(result.newBalance, 12);
    expect(result.failureReason, isNull);
    expect((await getTierUpScrolls()).balance, 12);
  });

  test('earnTierUpScrolls reports sync failure without mutating cache',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tier_up_scrolls': 9,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await earnTierUpScrolls(3);

    expect(result.success, isFalse);
    expect(result.newBalance, 9);
    expect(result.failureReason, TierUpScrollFailureReason.syncFailed);
    expect((await getTierUpScrolls()).balance, 9);
  });

  test('earnTierUpScrollsOrThrow throws on sync failure', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tier_up_scrolls': 9,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    expect(
      () => earnTierUpScrollsOrThrow(3),
      throwsA(isA<TierUpScrollEarnException>()),
    );
  });

  test('spendTierUpScrolls uses RPC result for authenticated users', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tier_up_scrolls': 10,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    fakeSync.rpcHandlers['spend_scrolls'] = (params) async => 6;
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await spendTierUpScrolls(4);

    expect(result.success, isTrue);
    expect(result.newBalance, 6);
    expect(result.failureReason, isNull);
    expect((await getTierUpScrolls()).balance, 6);
  });

  test('spendTierUpScrolls fails early for insufficient balance', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tier_up_scrolls': 2,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await spendTierUpScrolls(5);

    expect(result.success, isFalse);
    expect(result.newBalance, 2);
    expect(
      result.failureReason,
      TierUpScrollFailureReason.insufficientBalance,
    );
    expect(fakeSync.rpcCalls, isEmpty);
  });

  test('spendTierUpScrolls reports sync failure without mutating cache',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tier_up_scrolls': 10,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await spendTierUpScrolls(4);

    expect(result.success, isFalse);
    expect(result.newBalance, 10);
    expect(result.failureReason, TierUpScrollFailureReason.syncFailed);
    expect((await getTierUpScrolls()).balance, 10);
  });

  test('signed-out users use local fallback for read earn and spend', () async {
    fakeSync = FakeSupabaseSyncService(userId: null);
    SupabaseSyncService.debugSetInstance(fakeSync);

    expect((await getTierUpScrolls()).balance, 0);

    final earnResult = await earnTierUpScrolls(5);
    expect(earnResult.success, isTrue);
    expect(earnResult.newBalance, 5);
    expect((await getTierUpScrolls()).balance, 5);

    final spendResult = await spendTierUpScrolls(3);
    expect(spendResult.success, isTrue);
    expect(spendResult.newBalance, 2);
    expect((await getTierUpScrolls()).balance, 2);
    expect(fakeSync.rpcCalls, isEmpty);
  });

  test('markScrollUsed writes a user-scoped key', () async {
    await markScrollUsed();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(fakeSync.scopedKey('sakina_has_used_scroll')),
      isTrue,
    );
    expect(prefs.getBool('sakina_has_used_scroll'), isNull);
  });

  test('hasEverUsedScroll reads the user-scoped key', () async {
    expect(await hasEverUsedScroll(), isFalse);

    await markScrollUsed();

    expect(await hasEverUsedScroll(), isTrue);
  });

  test('clearSession pattern removes the scoped scroll-usage flag', () async {
    await markScrollUsed();

    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.endsWith(':user-1')) {
        await prefs.remove(key);
      }
    }

    expect(await hasEverUsedScroll(), isFalse);
  });
}
