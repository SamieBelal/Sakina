// The daily loop's persisted state is keyed by the user's LOCAL day.
//
// It used to be keyed by the UTC date, which was a daily, user-facing bug for
// everyone west of UTC: a Californian who did their muḥāsabah at 4pm wrote
// `daily_loop_<Jul 30>`, and by 5pm the UTC date had rolled to Jul 31, so the
// key no longer resolved. The state loaded as fresh and the home CTA went back
// to inviting them to a muḥāsabah they had already done — the same evening,
// with the card already in their collection. East of UTC it fires in the
// morning instead, which is worse: that is prime muḥāsabah time.
//
// Found on device (founder, 2026-07-30, 6:27pm PDT) after the check-in row for
// that day was confirmed present on the server. The app had the reveal; it had
// just lost the key to it.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  /// 2026-07-31 01:27 UTC. In Los Angeles that is still **6:27pm on Jul 30** —
  /// the exact instant the bug was reported from a device.
  final afterUtcMidnight = DateTime.utc(2026, 7, 31, 1, 27);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-A'),
    );
    debugResetUserLocalDay();
    debugDailyLoopClock = () => afterUtcMidnight;
  });

  tearDown(() {
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugUserTimeZoneOverride = null;
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  /// Reset clears `debugUserTimeZoneOverride`, so the order matters — setting
  /// the zone first and resetting after silently puts you back on UTC, which is
  /// the same value the bug produces and would have made every assertion here
  /// pass for the wrong reason.
  void useZone(String zone) {
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = zone;
  }

  Future<Set<String>> loopKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.contains('daily_loop_')).toSet();
  }

  test('the key is the local day, not the UTC day, west of UTC', () async {
    useZone('America/Los_Angeles');

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.debugPersistTodayState();

    final keys = await loopKeys();
    expect(keys.any((k) => k.contains('daily_loop_2026-07-30')), isTrue,
        reason: 'the user is living in Jul 30 — that is the day they did it in');
    expect(keys.any((k) => k.contains('daily_loop_2026-07-31')), isFalse,
        reason: 'the UTC date has rolled, but the user has not gone to bed');
  });

  test('the key is the local day east of UTC too', () async {
    // Tokyo at this instant is already 10:27am on Jul 31 — the opposite
    // disagreement, and the one that lands in the morning.
    useZone('Asia/Tokyo');

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);

    await notifier.debugPersistTodayState();

    final keys = await loopKeys();
    expect(keys.any((k) => k.contains('daily_loop_2026-07-31')), isTrue);
  });

  test('state written before the UTC rollover is still found after it',
      () async {
    // The regression itself, end to end: persist at 4pm local (Jul 30 UTC),
    // then read at 6:27pm local — which is already Jul 31 in UTC.
    useZone('America/Los_Angeles');

    debugDailyLoopClock = () => DateTime.utc(2026, 7, 30, 23, 0); // 4pm PDT
    final before = DailyLoopNotifier(skipInitForTests: true);
    before.debugSetState(
      const DailyLoopState(loaded: true, checkinDone: true),
    );
    await before.debugPersistTodayState();
    before.dispose();

    debugDailyLoopClock = () => afterUtcMidnight; // 6:27pm PDT, same local day
    useZone('America/Los_Angeles');

    final after = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(after.dispose);
    await after.debugLoadTodayState();

    expect(after.state.checkinDone, isTrue,
        reason: 'the muḥāsabah happened this local day — the home CTA must not '
            'go back to inviting the user to do it again');
  });

  test('a blob left under the OLD UTC key is migrated, not abandoned',
      () async {
    // Whoever is mid-loop when they update must not meet the very bug being
    // fixed, once, on the update itself. For legacy (non-queue) users a
    // forgotten state can mean a second reveal in one local day.
    useZone('America/Los_Angeles');

    final sync = SupabaseSyncService.instance;
    SharedPreferences.setMockInitialValues({
      // The pre-fix key: UTC date at this instant.
      sync.scopedKey('daily_loop_2026-07-31'):
          '{"checkinDone":true,"currentStep":1}',
    });

    final notifier = DailyLoopNotifier(skipInitForTests: true);
    addTearDown(notifier.dispose);
    await notifier.debugLoadTodayState();

    expect(notifier.state.checkinDone, isTrue,
        reason: 'the legacy blob must be read once, not thrown away');

    final keys = await loopKeys();
    expect(keys.any((k) => k.contains('daily_loop_2026-07-30')), isTrue,
        reason: 'and rewritten under the local-day key');
    expect(keys.any((k) => k.contains('daily_loop_2026-07-31')), isFalse,
        reason: 'the legacy key is consumed, so it cannot be re-read tomorrow');
  });
}
