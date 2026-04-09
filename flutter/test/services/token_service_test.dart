import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';

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

  test('syncTokenCacheFromSupabase hydrates balance and total spent', () async {
    fakeSync.rows['user_tokens:user-1'] = {
      'balance': 145,
      'total_spent': 30,
    };

    await syncTokenCacheFromSupabase();

    expect((await getTokens()).balance, 145);
    expect(await getTotalTokensSpent(), 30);
  });

  test('earnTokens uses RPC result', () async {
    fakeSync.rpcHandlers['earn_tokens'] = (params) async => 110;

    final state = await earnTokens(10);

    expect(state.balance, 110);
    expect((await getTokens()).balance, 110);
  });

  test('spendTokens success updates balance and total spent', () async {
    SharedPreferences.setMockInitialValues({'sakina_tokens': 100});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    fakeSync.rpcHandlers['spend_tokens'] = (params) async => 80;
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await spendTokens(20);

    expect(result.success, isTrue);
    expect(result.newBalance, 80);
    expect((await getTokens()).balance, 80);
    expect(await getTotalTokensSpent(), 20);
  });

  test('spendTokens fails early for insufficient balance', () async {
    SharedPreferences.setMockInitialValues({'sakina_tokens': 5});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await spendTokens(10);

    expect(result.success, isFalse);
    expect(result.newBalance, 5);
    expect(fakeSync.rpcCalls, isEmpty);
  });

  test('RPC failure does not mutate cached values', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tokens': 100,
      'sakina_total_tokens_spent': 12,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await spendTokens(20);

    expect(result.success, isFalse);
    expect((await getTokens()).balance, 100);
    expect(await getTotalTokensSpent(), 12);
  });
}
