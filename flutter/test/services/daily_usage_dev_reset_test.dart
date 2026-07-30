// The day-scoped reset boundary (W4 Wave 1 review, F2).
//
// A "reset the daily loop" that leaves the day's ALLOWANCE behind is lying
// about what it does: the day-open re-arms and then serves a metered reveal,
// which on device reads as the free-first-reveal split being broken when it is
// working correctly. So the developer reset clears it.
//
// The far more important half is the other direction. **Settings → Danger Zone
// → "Reset Daily Loop" ships** — it sits outside the `kDebugMode` block — so if
// it ever cleared the allowance, any user could reset their way to unlimited
// free reveals and skip the 25-token AI-bypass economy entirely. That is a
// one-line mistake away at all times, which is why it is pinned here rather
// than left to a comment.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/settings/screens/settings_screen.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-1'),
    );
    debugDailyUsageClock = () => DateTime.utc(2026, 8, 4, 9);
  });

  tearDown(() {
    debugDailyUsageClock = null;
    SupabaseSyncService.debugReset();
  });

  /// Spend the day: the free reveal is taken and a metered use is recorded, so
  /// both halves of the split have something to clear.
  Future<void> spendTheDay() async {
    await markFreeDailyRevealTaken();
    await incrementDiscoverNameUsage();
    expect(await hasTakenFreeDailyRevealToday(), isTrue);
    expect(await getDiscoverNameUsageToday(), 1);
  }

  group('devResetDailyUsageToday', () {
    test('clears the free-reveal marker and the free-cap counters', () async {
      await spendTheDay();

      await devResetDailyUsageToday();

      expect(await hasTakenFreeDailyRevealToday(), isFalse,
          reason: 'a developer reset means a fresh day, and on a fresh day the '
              'first reveal is free — otherwise the re-armed day-open serves a '
              'metered reveal and looks like the split is broken');
      expect(await getDiscoverNameUsageToday(), 0);
    });

    test('clears every feature, not just discover_name', () async {
      await incrementReflectUsage();
      await incrementBuiltDuaUsage();
      await incrementDiscoverNameUsage();

      await devResetDailyUsageToday();

      expect(await getReflectUsageToday(), 0);
      expect(await getBuiltDuaUsageToday(), 0);
      expect(await getDiscoverNameUsageToday(), 0);
    });

    test('is idempotent on a day that was never spent', () async {
      await devResetDailyUsageToday();
      await devResetDailyUsageToday();

      expect(await hasTakenFreeDailyRevealToday(), isFalse);
      expect(await getDiscoverNameUsageToday(), 0);
    });
  });

  group('the SHIPPING reset must not touch the allowance', () {
    // This is the economy guard. `performCardCollectionDangerReset` backs the
    // user-facing "Clear Card Collection" button, and `_resetDailyLoop` backs
    // the user-facing "Reset Daily Loop" button; neither is behind kDebugMode.
    test('performCardCollectionDangerReset leaves the day spent', () async {
      await spendTheDay();

      await performCardCollectionDangerReset(
        resetDailyLoopState: () async {},
      );

      expect(await hasTakenFreeDailyRevealToday(), isTrue,
          reason: 'if a shipping reset cleared this, any user could tap '
              'Settings → Danger Zone repeatedly for unlimited free reveals');
      expect(await getDiscoverNameUsageToday(), 1,
          reason: 'and would also get a fresh daily allowance, skipping the '
              '25-token AI bypass entirely');
    });
  });
}
