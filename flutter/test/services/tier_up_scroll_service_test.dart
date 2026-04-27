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

  // §10 C2/C3/C4 — tier-up scroll spend invariants. Run on the local-only
  // branch (signed-out fake) so the lock + arithmetic are exercised without
  // RPC plumbing. Resets the module-level lock between cases via the
  // `debugResetTierUpScrollLock` test seam.
  group('§10 spend invariants (local branch)', () {
    setUp(() {
      SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService());
      debugResetTierUpScrollLock();
    });

    tearDown(debugResetTierUpScrollLock);

    test('C3 exact-balance spend succeeds with newBalance=0', () async {
      await hydrateTierUpScrollCache(balance: 5);

      final result = await spendTierUpScrolls(5);

      expect(result.success, isTrue);
      expect(result.newBalance, 0);
      expect(result.failureReason, isNull);
      expect((await getTierUpScrolls()).balance, 0);
    });

    test('C3 spend(0) on empty balance is a successful no-op', () async {
      await hydrateTierUpScrollCache(balance: 0);

      final result = await spendTierUpScrolls(0);

      // current(0) >= amount(0) passes the gate. Pinning the boundary so
      // callers know to guard 0-cost upgrades themselves.
      expect(result.success, isTrue);
      expect(result.newBalance, 0);
    });

    test(
        'C2 two concurrent spends serialize: first wins, second sees '
        'post-first balance and goes insufficient', () async {
      await hydrateTierUpScrollCache(balance: 3);

      // Fire both without awaiting between them. The lock loop on
      // `tier_up_scroll_service.dart:149` forces the second call to wait on
      // the first's Completer before reading the cache, so the second sees
      // newBalance=0.
      final results = await Future.wait([
        spendTierUpScrolls(3),
        spendTierUpScrolls(3),
      ]);

      final successes = results.where((r) => r.success).toList();
      final failures = results.where((r) => !r.success).toList();

      expect(successes.length, 1, reason: 'lock must serialize spends');
      expect(failures.length, 1);
      expect(failures.first.failureReason,
          TierUpScrollFailureReason.insufficientBalance);
      expect(failures.first.newBalance, 0,
          reason: 'second spend reads post-first cache');
      expect((await getTierUpScrolls()).balance, 0);
    });

    test(
        'C2 three concurrent spends from balance=10, cost=5 → exactly two '
        'succeed', () async {
      await hydrateTierUpScrollCache(balance: 10);

      final results = await Future.wait([
        spendTierUpScrolls(5),
        spendTierUpScrolls(5),
        spendTierUpScrolls(5),
      ]);

      final successes = results.where((r) => r.success).toList();
      expect(successes.length, 2);
      expect((await getTierUpScrolls()).balance, 0);
    });

    test('C4 insufficient-balance early-return clears the lock', () async {
      await hydrateTierUpScrollCache(balance: 0);

      // Early-return at line 159-164. The `finally` at line 189 must still
      // run; otherwise the next spend hangs on a stale Completer and times
      // out via flutter_test's default 30s ceiling.
      final first = await spendTierUpScrolls(5);
      expect(first.success, isFalse);

      await hydrateTierUpScrollCache(balance: 5);
      final second = await spendTierUpScrolls(5);
      expect(second.success, isTrue);
      expect(second.newBalance, 0);
    });
  });
}
