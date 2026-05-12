import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugDailyLoopClock = () => DateTime.utc(2026, 5, 13, 4, 30);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    debugDailyLoopClock = () => DateTime.now().toUtc();
  });

  test(
    'daily-loop SharedPrefs key uses UTC date even when local time is the previous day',
    () async {
      // Simulates 11:30 PM EST on 2026-05-12 (= 04:30 UTC on 2026-05-13).
      // After the fix, the key must use UTC (2026-05-13), not local (2026-05-12).
      final notifier = DailyLoopNotifier();
      // Let _initialize finish so the notifier is settled before we mutate.
      // Mirrors the pattern used by daily_loop_reset_today_test.dart.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // skipAll() calls _persistTodayState() internally, which writes to _todayKey.
      await notifier.skipAll();

      final prefs = await SharedPreferences.getInstance();
      final scopedKey =
          SupabaseSyncService.instance.scopedKey('daily_loop_2026-05-13');
      expect(
        prefs.getString(scopedKey),
        isNotNull,
        reason:
            'SharedPrefs key must be keyed by UTC date 2026-05-13, not local 2026-05-12',
      );

      final localKey =
          SupabaseSyncService.instance.scopedKey('daily_loop_2026-05-12');
      expect(
        prefs.getString(localKey),
        isNull,
        reason: 'Stale local-date key must NOT be written',
      );
    },
  );
}
