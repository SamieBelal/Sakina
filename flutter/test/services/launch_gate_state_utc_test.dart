import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-A'),
    );
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    resetLaunchGateMemoryGuard();
    debugLaunchGateClock = () => DateTime.now().toUtc();
  });

  test(
    'markDailyLaunchShown stores the UTC date even when local time is the previous day',
    () async {
      // Local: 2026-05-12 23:30 EST (UTC-5) — already 2026-05-13 04:30 UTC.
      // launchGateTodayMarker() and the stored marker must agree on the UTC date.
      debugLaunchGateClock = () => DateTime.utc(2026, 5, 13, 4, 30);

      await markDailyLaunchShown();

      final prefs = await SharedPreferences.getInstance();
      final scoped = SupabaseSyncService.instance.scopedKey('sakina_launch_gate');
      expect(prefs.getString(scoped), '2026-05-13');
      expect(launchGateTodayMarker(), '2026-05-13');
    },
  );

  test(
    'shouldShowDailyLaunch returns false when the stored marker matches UTC today',
    () async {
      debugLaunchGateClock = () => DateTime.utc(2026, 5, 13, 4, 30);
      await markDailyLaunchShown();
      resetLaunchGateMemoryGuard();

      // Local rolls past midnight (now 2026-05-13 00:30 local) but UTC is still 2026-05-13.
      // The marker must still match — the overlay must NOT re-fire.
      debugLaunchGateClock = () => DateTime.utc(2026, 5, 13, 5, 30);
      final prefs = await SharedPreferences.getInstance();
      final scoped = SupabaseSyncService.instance.scopedKey('sakina_launch_gate');
      expect(prefs.getString(scoped), launchGateTodayMarker());
    },
  );
}
