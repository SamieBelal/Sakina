import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';

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
    debugSetPremiumGrantPurchaseService(StubPurchaseService(false));
  });

  tearDown(() {
    debugResetPremiumGrantService();
    SupabaseSyncService.debugReset();
  });

  String currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  test('non-premium users do not request or receive a grant', () async {
    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isFalse);
    expect(fakeSync.rpcCalls, isEmpty);
    expect((await getTierUpScrolls()).balance, 0);
    expect((await getTokens()).balance, startingTokens);
  });

  test('premium client with server not_premium response does not grant locally',
      () async {
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async => {
          'granted': false,
          'reason': 'not_premium',
          'grant_month': currentMonth(),
          'tokens_granted': 0,
          'scrolls_granted': 0,
          'new_token_balance': 100,
          'new_scroll_balance': 0,
        };

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isFalse);
    expect(result.tokens, 0);
    expect(result.scrolls, 0);
    expect((await getTokens()).balance, 100);
    expect((await getTierUpScrolls()).balance, 0);
  });

  test(
      'authenticated premium user skips grant when server reports current month already granted',
      () async {
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async => {
          'granted': false,
          'grant_month': currentMonth(),
          'tokens_granted': 0,
          'scrolls_granted': 0,
          'new_token_balance': 120,
          'new_scroll_balance': 7,
        };

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isFalse);
    expect(result.tokens, 0);
    expect(result.scrolls, 0);
    expect((await getTokens()).balance, 120);
    expect((await getTierUpScrolls()).balance, 7);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('sakina_premium_last_grant:user-1'),
      currentMonth(),
    );
  });

  test('authenticated premium user hydrates caches from atomic RPC grant',
      () async {
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async => {
          'granted': true,
          'grant_month': currentMonth(),
          'tokens_granted': 50,
          'scrolls_granted': 15,
          'new_token_balance': 160,
          'new_scroll_balance': 15,
        };

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isTrue);
    expect(result.tokens, 50);
    expect(result.scrolls, 15);
    expect((await getTokens()).balance, 160);
    expect((await getTierUpScrolls()).balance, 15);
  });

  test('concurrent premium grant checks coalesce into one RPC call', () async {
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    final rpcStarted = Completer<void>();
    final releaseRpc = Completer<void>();
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async {
      rpcStarted.complete();
      await releaseRpc.future;
      return {
        'granted': true,
        'grant_month': currentMonth(),
        'tokens_granted': 50,
        'scrolls_granted': 15,
        'new_token_balance': 160,
        'new_scroll_balance': 15,
      };
    };

    final first = checkPremiumMonthlyGrant();
    await rpcStarted.future;
    final second = checkPremiumMonthlyGrant();

    releaseRpc.complete();

    final firstResult = await first;
    final secondResult = await second;

    expect(fakeSync.rpcCalls.length, 1);
    expect(secondResult, firstResult);
  });

  test('concurrent premium grant callers share RPC errors', () async {
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    final rpcStarted = Completer<void>();
    final releaseRpc = Completer<void>();
    final error = StateError('rpc failed');
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async {
      rpcStarted.complete();
      await releaseRpc.future;
      throw error;
    };

    final first = checkPremiumMonthlyGrant();
    await rpcStarted.future;
    final second = checkPremiumMonthlyGrant();

    releaseRpc.complete();

    await expectLater(first, throwsA(same(error)));
    await expectLater(second, throwsA(same(error)));
    expect(fakeSync.rpcCalls.length, 1);
  });

  test('authenticated RPC failure does not mutate local grant cache', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tokens:user-1': 80,
      'sakina_total_tokens_spent:user-1': 5,
      'sakina_tier_up_scrolls:user-1': 3,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isFalse);
    expect((await getTokens()).balance, 80);
    expect(await getTotalTokensSpent(), 5);
    expect((await getTierUpScrolls()).balance, 3);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sakina_premium_last_grant:user-1'), isNull);
  });

  test(
      'unauthenticated premium user is denied grant (requires server identity)',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tokens': 10,
      'sakina_tier_up_scrolls': 2,
    });
    fakeSync = FakeSupabaseSyncService(userId: null);
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isFalse);
    expect(result.tokens, 0);
    expect(result.scrolls, 0);
    // Balances must be untouched
    expect((await getTokens()).balance, 10);
    expect((await getTierUpScrolls()).balance, 2);
  });

  test('premium grant hydration preserves cached total tokens spent', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_total_tokens_spent:user-1': 42,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async => {
          'granted': true,
          'grant_month': currentMonth(),
          'tokens_granted': 50,
          'scrolls_granted': 15,
          'new_token_balance': 160,
          'new_scroll_balance': 15,
        };

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isTrue);
    expect((await getTokens()).balance, 160);
    expect(await getTotalTokensSpent(), 42);
  });

  test('hydratePremiumGrantCache writes the scoped grant month', () async {
    await preparePremiumGrantCacheForHydration();
    await hydratePremiumGrantCache(lastGrantMonth: '2026-04');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sakina_premium_last_grant:user-1'), '2026-04');
  });

  test('preparePremiumGrantCacheForHydration migrates legacy unscoped key',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_premium_last_grant': '2026-03',
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await preparePremiumGrantCacheForHydration();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sakina_premium_last_grant:user-1'), '2026-03');
    expect(prefs.getString('sakina_premium_last_grant'), isNull);
  });
}
