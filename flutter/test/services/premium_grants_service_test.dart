import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';

import '../support/fake_supabase_sync_service.dart';

class StubPurchaseService extends PurchaseService {
  StubPurchaseService(this.premium);

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

  test(
      'authenticated premium user skips grant when server reports current month already granted',
      () async {
    debugSetPremiumGrantPurchaseService(StubPurchaseService(true));
    fakeSync.rpcHandlers['grant_premium_monthly'] = (params) async => {
          'granted': false,
          'grant_month': currentMonth(),
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
          'new_token_balance': 160,
          'new_scroll_balance': 15,
        };

    final result = await checkPremiumMonthlyGrant();

    expect(result.granted, isTrue);
    expect(result.tokens, premiumMonthlyTokens);
    expect(result.scrolls, premiumMonthlyScrolls);
    expect((await getTokens()).balance, 160);
    expect((await getTierUpScrolls()).balance, 15);
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

  test('unauthenticated premium user is denied grant (requires server identity)',
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
