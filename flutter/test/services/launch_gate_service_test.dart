import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
  });

  test('markDailyLaunchShown writes a user-scoped key', () async {
    final fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await markDailyLaunchShown();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(fakeSync.scopedKey('sakina_launch_gate')),
      isNotNull,
    );
    expect(prefs.getString('sakina_launch_gate'), isNull);
  });

  test('shouldShowDailyLaunch reads the user-scoped key', () async {
    final fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);

    expect(await shouldShowDailyLaunch(), isTrue);

    await markDailyLaunchShown();
    resetLaunchGateMemoryGuard();

    expect(await shouldShowDailyLaunch(), isFalse);
  });

  test('clearSession-style cleanup removes the scoped launch gate key',
      () async {
    final fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await markDailyLaunchShown();

    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.endsWith(':user-A')) {
        await prefs.remove(key);
      }
    }

    resetLaunchGateMemoryGuard();
    expect(await shouldShowDailyLaunch(), isTrue);
  });
}
