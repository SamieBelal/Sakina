import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

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

  test('hydrateXpCache writes scoped cache', () async {
    await prepareXpCacheForHydration();
    await hydrateXpCache(totalXp: 42);

    final xp = await getXp();
    expect(xp.totalXp, 42);
  });

  test('awardXp uses RPC result and updates cache', () async {
    fakeSync.rpcHandlers['award_xp'] = (params) async => {
          'total_xp': 75,
          'old_level': 1,
          'new_level': 1,
          'reward_tokens': 0,
          'reward_scrolls': 0,
          'token_balance': 50,
          'scroll_balance': 0,
        };

    final result = await awardXp(25);

    expect(result.newTotal, 75);
    // gained reflects the realized server delta (newTotal - oldTotal), not
    // the requested amount. Server bumped the total to 75 from 0, so the
    // user actually gained 75 — even though they only asked for 25. This
    // matches the contract added when XpAwardResult.gained was switched
    // from `amount` to `newTotal - oldTotal`.
    expect(result.gained, 75);
    expect(fakeSync.rpcCalls.single['fn'], 'award_xp');
    expect((await getXp()).totalXp, 75);
  });

  test('awardXp failure does not overwrite cached total', () async {
    SharedPreferences.setMockInitialValues({'sakina_total_xp': 50});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final result = await awardXp(25);

    expect(result.newTotal, 50);
    expect(result.gained, 0);
    expect((await getXp()).totalXp, 50);
  });
}
