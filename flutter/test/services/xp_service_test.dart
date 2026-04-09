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

  test('syncXpCacheFromSupabase hydrates scoped cache', () async {
    fakeSync.rows['user_xp:user-1'] = {'total_xp': 42};

    await syncXpCacheFromSupabase();

    final xp = await getXp();
    expect(xp.totalXp, 42);
  });

  test('awardXp uses RPC result and updates cache', () async {
    fakeSync.rpcHandlers['award_xp'] = (params) async => 75;

    final result = await awardXp(25);

    expect(result.newTotal, 75);
    expect(result.gained, 25);
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
