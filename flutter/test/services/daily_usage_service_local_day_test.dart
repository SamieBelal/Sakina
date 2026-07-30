import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_usage_service.dart' as dus;
import 'package:sakina/services/name_queue_cache.dart';
import 'package:sakina/services/name_queue_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fake_supabase_sync_service.dart';

/// Pins the cohort-scoped day key on the free-cap counters (W3 plan §7a, §12
/// "Day boundary").
///
/// The canonical case, with **literal pinned clocks**: at `2026-08-04T03:00Z`
/// with tz `America/Los_Angeles` the local day is 2026-08-03, so a queue-cohort
/// user's cap key ends `_2026-08-03` while a legacy user's ends `_2026-08-04`.
///
/// The narrowness is the point: `usage_date` on the server row and the bypass
/// counter keys stay UTC. `daily_usage_service_utc_test.dart` pins the legacy
/// half and must stay green untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    // 2026-08-04T03:00Z = 2026-08-03 20:00 America/Los_Angeles.
    dus.debugDailyUsageClock = () => DateTime.utc(2026, 8, 4, 3, 0);
  });

  tearDown(() {
    dus.debugDailyUsageClock = null;
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  Future<void> makeQueueCohort() async {
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    await writeCachedNameQueue([
      const NameQueueRow(position: 1, nameId: 11),
      const NameQueueRow(position: 2, nameId: 22),
    ]);
  }

  Iterable<String> capKeys(SharedPreferences prefs) =>
      prefs.getKeys().where((k) => k.startsWith('daily_usage_'));

  test('LEGACY (no queue rows): the cap key stays UTC-dated', () async {
    // Even with a resolvable non-UTC zone, no queue rows means no re-key.
    debugUserTimeZoneOverride = 'America/Los_Angeles';

    await dus.incrementDiscoverNameUsage();
    expect(await dus.getDiscoverNameUsageToday(), 1);

    final prefs = await SharedPreferences.getInstance();
    expect(capKeys(prefs), [
      'daily_usage_discover_name_2026-08-04:user-1',
    ]);
  });

  test('QUEUE COHORT: the cap key is the user-local day', () async {
    await makeQueueCohort();

    await dus.incrementDiscoverNameUsage();
    expect(await dus.getDiscoverNameUsageToday(), 1);

    final prefs = await SharedPreferences.getInstance();
    expect(capKeys(prefs), [
      'daily_usage_discover_name_2026-08-03:user-1',
    ]);
    expect(
      prefs.getKeys().any((k) => k.startsWith('daily_usage_') && k.contains('2026-08-04')),
      isFalse,
      reason: 'the queue user must not also write the UTC-day cap key',
    );
  });

  test('the server row keeps its UTC usage_date even for the queue cohort',
      () async {
    await makeQueueCohort();
    await dus.incrementDiscoverNameUsage();

    final upserts = fakeSync.upsertCalls
        .where((c) => c['table'] == 'user_daily_usage')
        .toList();
    expect(upserts, hasLength(1));
    final data = upserts.single['data'] as Map<String, dynamic>;
    expect(data['usage_date'], '2026-08-04',
        reason: 'the (user_id, usage_date) row is UTC-keyed server-side; '
            're-keying it would desynchronise the server-owned bypass counters');
    expect(data['discover_name_uses'], 1);
    expect(upserts.single['onConflict'], 'user_id,usage_date');
  });

  test('the bypass counter key stays UTC for the queue cohort', () async {
    await makeQueueCohort();
    await dus.incrementDiscoverNameBypassUsage();
    expect(await dus.getDiscoverNameBypassesUsedToday(), 1);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.startsWith('daily_bypass_')),
      ['daily_bypass_discover_name_2026-08-04:user-1'],
      reason: 'reserve_ai_bypass / cancel_ai_bypass own this counter in UTC',
    );
  });

  test('all three free-cap counters move together onto the local key', () async {
    await makeQueueCohort();
    await dus.incrementReflectUsage();
    await dus.incrementBuiltDuaUsage();
    await dus.incrementDiscoverNameUsage();

    expect(await dus.getReflectUsageToday(), 1);
    expect(await dus.getBuiltDuaUsageToday(), 1);
    expect(await dus.getDiscoverNameUsageToday(), 1);

    final prefs = await SharedPreferences.getInstance();
    expect(
      capKeys(prefs).toSet(),
      {
        'daily_usage_reflect_2026-08-03:user-1',
        'daily_usage_built_dua_2026-08-03:user-1',
        'daily_usage_discover_name_2026-08-03:user-1',
      },
    );
  });

  test('a UTC-zoned queue user is indistinguishable from legacy', () async {
    debugUserTimeZoneOverride = 'UTC';
    await writeCachedNameQueue([const NameQueueRow(position: 1, nameId: 11)]);

    await dus.incrementDiscoverNameUsage();
    final prefs = await SharedPreferences.getInstance();
    expect(capKeys(prefs), ['daily_usage_discover_name_2026-08-04:user-1']);
  });

  test('hydration writes the server UTC count into the local key — the '
      'accepted one-use drift', () async {
    await makeQueueCohort();

    // The sync payload's daily_usage section is a UTC-day count. Documented,
    // bounded cost: for a queue user on a boundary day it lands in the
    // local-day key, so a multi-device user can drift by at most one use.
    await dus.hydrateDailyUsageCacheFromPayload({
      'discover_name_uses': 1,
      'discover_name_bypasses_used': 2,
    });

    expect(await dus.getDiscoverNameUsageToday(), 1);
    final prefs = await SharedPreferences.getInstance();
    expect(capKeys(prefs), ['daily_usage_discover_name_2026-08-03:user-1']);
    // The bypass half of the same payload stays on the UTC key.
    expect(
      prefs.getInt('daily_bypass_discover_name_2026-08-04:user-1'),
      2,
    );
  });

  test('an ahead-of-UTC queue user rolls forward, not back', () async {
    debugUserTimeZoneOverride = 'Asia/Tokyo';
    await writeCachedNameQueue([const NameQueueRow(position: 1, nameId: 11)]);
    // 2026-08-03T20:00Z = 2026-08-04 05:00 Tokyo.
    dus.debugDailyUsageClock = () => DateTime.utc(2026, 8, 3, 20, 0);

    await dus.incrementDiscoverNameUsage();
    final prefs = await SharedPreferences.getInstance();
    expect(capKeys(prefs), ['daily_usage_discover_name_2026-08-04:user-1']);
  });
}
