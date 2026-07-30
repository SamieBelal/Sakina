import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fake_supabase_sync_service.dart';

/// Pins the user-local calendar day used by the discover cap key (W3 plan §7a).
///
/// Every instant below is a **literal pinned UTC value** — no `DateTime.now()`,
/// no computed offsets. The canonical case from §12: at `2026-08-04T03:00Z` with
/// tz `America/Los_Angeles` the user's local day is 2026-08-03.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // main.dart calls this on boot; tests must too or tz.getLocation throws and
  // the ladder correctly degrades to UTC.
  tzdata.initializeTimeZones();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
  });

  tearDown(() {
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  group('local day resolution', () {
    test('2026-08-04T03:00Z in America/Los_Angeles is 2026-08-03', () async {
      debugUserTimeZoneOverride = 'America/Los_Angeles';
      final resolved = await resolveUserLocalDay(
        clock: () => DateTime.utc(2026, 8, 4, 3, 0),
      );
      expect(resolved.dateString, '2026-08-03');
      expect(resolved.day, DateTime.utc(2026, 8, 3));
      expect(resolved.utcOffset, const Duration(hours: -7));
      expect(resolved.timeZoneName, 'America/Los_Angeles');
    });

    test('the same instant is 2026-08-04 in UTC — the legacy answer', () async {
      debugUserTimeZoneOverride = 'UTC';
      expect(
        await userLocalDayString(clock: () => DateTime.utc(2026, 8, 4, 3, 0)),
        '2026-08-04',
      );
    });

    test('ahead-of-UTC zones roll the OTHER way', () async {
      // 2026-08-03T20:00Z is 2026-08-04 05:00 in Tokyo.
      debugUserTimeZoneOverride = 'Asia/Tokyo';
      final resolved = await resolveUserLocalDay(
        clock: () => DateTime.utc(2026, 8, 3, 20, 0),
      );
      expect(resolved.dateString, '2026-08-04');
      expect(resolved.utcOffset, const Duration(hours: 9));
    });

    test('midday never differs from UTC for a UTC-7 user', () async {
      debugUserTimeZoneOverride = 'America/Los_Angeles';
      expect(
        await userLocalDayString(clock: () => DateTime.utc(2026, 8, 4, 12, 0)),
        '2026-08-04',
      );
    });

    test('a non-UTC clock argument is normalised to UTC first', () async {
      debugUserTimeZoneOverride = 'America/Los_Angeles';
      // Same instant as 2026-08-04T03:00Z, expressed with a +02:00 offset.
      final resolved = await resolveUserLocalDay(
        clock: () => DateTime.parse('2026-08-04T05:00:00+02:00'),
      );
      expect(resolved.dateString, '2026-08-03');
    });

    test('an unknown zone degrades to UTC rather than throwing', () async {
      debugUserTimeZoneOverride = 'Mars/Olympus_Mons';
      final resolved = await resolveUserLocalDay(
        clock: () => DateTime.utc(2026, 8, 4, 3, 0),
      );
      expect(resolved.timeZoneName, 'UTC');
      expect(resolved.dateString, '2026-08-04');
      expect(resolved.utcOffset, Duration.zero);
    });

    test('the module-level clock seam is honoured when no argument is given',
        () async {
      debugUserTimeZoneOverride = 'America/Los_Angeles';
      debugUserLocalDayClock = () => DateTime.utc(2026, 8, 4, 3, 0);
      expect(await userLocalDayString(), '2026-08-03');
    });
  });

  group('the fallback ladder', () {
    test('the scoped-prefs cache is consulted before the server', () async {
      SharedPreferences.setMockInitialValues({
        '$userTimeZonePrefBaseKey:user-1': 'America/Los_Angeles',
      });
      fakeSync.rows['user_notification_preferences:user-1'] = {
        'timezone': 'Asia/Tokyo',
      };
      expect(await resolveUserTimeZone(), 'America/Los_Angeles');
    });

    test('the server value is used and then cached', () async {
      fakeSync.rows['user_notification_preferences:user-1'] = {
        'timezone': 'Asia/Tokyo',
      };
      expect(await resolveUserTimeZone(), 'Asia/Tokyo');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('$userTimeZonePrefBaseKey:user-1'), 'Asia/Tokyo');
    });

    test('nothing resolvable → UTC, and UTC is NOT memoised', () async {
      // No prefs, no server row, and `flutter_timezone` has no plugin under
      // `flutter test` — so the ladder bottoms out.
      expect(await resolveUserTimeZone(), 'UTC');

      // A later successful resolution must still win.
      fakeSync.rows['user_notification_preferences:user-1'] = {
        'timezone': 'Asia/Tokyo',
      };
      expect(await resolveUserTimeZone(), 'Asia/Tokyo');
    });

    test('an unauthenticated user resolves UTC and caches nothing', () async {
      fakeSync.userId = null;
      expect(await resolveUserTimeZone(), 'UTC');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith(userTimeZonePrefBaseKey)),
        isEmpty,
      );
    });

    test('cacheUserTimeZone overwrites the memo and the scoped key', () async {
      fakeSync.rows['user_notification_preferences:user-1'] = {
        'timezone': 'Asia/Tokyo',
      };
      expect(await resolveUserTimeZone(), 'Asia/Tokyo');
      await cacheUserTimeZone('America/Los_Angeles');
      expect(await resolveUserTimeZone(), 'America/Los_Angeles');
    });

    test('the cached zone is user-scoped', () async {
      await cacheUserTimeZone('Asia/Tokyo');
      fakeSync.userId = 'user-2';
      debugResetUserLocalDay();
      expect(await resolveUserTimeZone(), 'UTC');
    });
  });

  group('the memo does not outlive the account', () {
    /// A sign-out → sign-in-as-someone-else inside ONE process.
    ///
    /// `_readCachedZone` and `cacheUserTimeZone` both re-check `currentUserId`,
    /// but the process-global memo used to short-circuit ahead of them, so the
    /// second user inherited the first user's zone. Clearing prefs on sign-out
    /// cannot fix that (a global is not prefs) and `debugResetUserLocalDay` has
    /// no production caller — so the scoping has to live in the memo itself.
    ///
    /// It matters because every consumer of the resolved zone computes a DATE:
    /// the discover cap key, `planQueueReveal(localUtcOffset:)`, and rule 2's
    /// same-local-day comparison. Los Angeles to Karachi is 12 hours, so the
    /// inherited zone is not an approximation — it is a different day.
    test('a second user in the same process does not inherit the first zone',
        () async {
      // User 2's zone is seeded straight into their scoped prefs key rather than
      // through `cacheUserTimeZone`. That is load-bearing: calling the setter for
      // user 2 would overwrite `_memoZone` as a side effect, so the test would
      // pass even with an unscoped memo. Reading it back through the ladder is
      // the only way the memo is the thing under test.
      SharedPreferences.setMockInitialValues({
        '$userTimeZonePrefBaseKey:user-2': 'Asia/Karachi',
      });

      // User 1 resolves and memoises Los Angeles.
      await cacheUserTimeZone('America/Los_Angeles');
      expect(await resolveUserTimeZone(), 'America/Los_Angeles');

      // Sign out, sign in as someone else. Deliberately NOT calling
      // debugResetUserLocalDay() — production has no equivalent, so the memo
      // must invalidate itself off the uid.
      fakeSync.userId = 'user-2';
      expect(await resolveUserTimeZone(), 'Asia/Karachi');

      final resolved = await resolveUserLocalDay(
        clock: () => DateTime.utc(2026, 8, 4, 3, 0),
      );
      expect(resolved.utcOffset, const Duration(hours: 5));
      // 03:00Z is 08:00 Karachi — the same instant that is still 2026-08-03 in
      // Los Angeles. Inheriting user 1's zone would put this a day earlier.
      expect(resolved.dateString, '2026-08-04');
    });

    test('the same user keeps the memo across repeated calls', () async {
      await cacheUserTimeZone('Asia/Karachi');
      expect(await resolveUserTimeZone(), 'Asia/Karachi');
      // Prefs go away but the memo still answers — the caching is the point.
      SharedPreferences.setMockInitialValues({});
      expect(await resolveUserTimeZone(), 'Asia/Karachi');
    });

    test('a signed-out session does not inherit the last signed-in zone',
        () async {
      await cacheUserTimeZone('America/Los_Angeles');
      expect(await resolveUserTimeZone(), 'America/Los_Angeles');

      fakeSync.userId = null;
      // No uid, so no scoped prefs to read: the ladder must fall past the memo
      // to the device zone, and to UTC when that is unavailable in tests.
      expect(await resolveUserTimeZone(), 'UTC');
    });
  });
}
