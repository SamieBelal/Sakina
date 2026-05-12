import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugLaunchGateClock = () => DateTime.utc(2026, 5, 12, 14, 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugLaunchGateClock = () => DateTime.now().toUtc();
  });

  test(
    'fresh install: server says already claimed today => overlay suppressed and marker written',
    () async {
      // Simulate a delete+reinstall: SharedPrefs is empty, but the server
      // already knows the user claimed today.
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 4,
        'last_claim_date': '2026-05-12',
        'streak_freeze_owned': true,
      };

      final should = await shouldShowDailyLaunch();
      expect(should, isFalse,
          reason: 'overlay must not show on reinstall when server confirms a same-UTC-day claim');

      // The marker must be written so subsequent cold launches today also skip.
      expect(
        await readLaunchGateMarker(),
        launchGateTodayMarker(),
        reason: 'fresh-install suppression must persist the marker, not just return false this call',
      );
    },
  );

  test(
    'fresh install: server says NOT claimed today => overlay still shows',
    () async {
      // Server has a row, but last_claim_date is yesterday — overlay should fire.
      fakeSync.rows['user_daily_rewards:user-A'] = {
        'user_id': 'user-A',
        'current_day': 3,
        'last_claim_date': '2026-05-11',
        'streak_freeze_owned': false,
      };

      final should = await shouldShowDailyLaunch();
      expect(should, isTrue,
          reason: 'overlay must still fire when server says claim is pending');
      expect(await readLaunchGateMarker(), isNull,
          reason: 'we only write the marker when suppressing, not when firing');
    },
  );

  test(
    'fresh install: server has no row at all => overlay shows (new user)',
    () async {
      // No row exists for this user.
      expect(fakeSync.rows.containsKey('user_daily_rewards:user-A'), isFalse);

      final should = await shouldShowDailyLaunch();
      expect(should, isTrue);
      expect(await readLaunchGateMarker(), isNull);
    },
  );
}
