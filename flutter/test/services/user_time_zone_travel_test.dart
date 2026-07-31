// What happens to the client's cached zone when the user travels.
//
// `resolveUserTimeZone` walks memo → scoped prefs → server → device, and the
// first hit wins. That ordering is right — it keeps the hot path off the
// network — but it means the CACHE, once written, is authoritative forever
// unless something refreshes it.
//
// `NotificationService.syncTimezone()` is the thing that notices travel: it
// reads the device zone on every app open and writes it to
// `user_notification_preferences`, which is what `safe_user_tz` (and therefore
// `unseal_next_name`'s local-day rule, and the push schedule) reads. It was
// updating the server and leaving the client's cache alone, so after a flight
// the two halves of the app ran on different days: the server on the new zone,
// `planQueueReveal` / the daily-cap key / the local-day blob on the old one.
// Near a date boundary that suppresses a legitimate unseal — the client sits on
// a day the server has already moved past.
//
// `cacheUserTimeZone`'s own doc has said "Call after syncing the device zone to
// `user_notification_preferences` so the two never disagree" since it was
// written. Nothing called it.
//
// These tests exercise `cacheUserTimeZone` directly rather than
// `syncTimezone()`, which needs a OneSignal binding and a live
// `FlutterTimezone` channel. What they pin is the property the fix depends on:
// that writing the cache actually re-points the resolver, memo included.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('caching a new zone re-points the resolver, memo and all', () async {
    await cacheUserTimeZone('America/Los_Angeles');
    expect(await resolveUserTimeZone(), 'America/Los_Angeles');

    // The flight. This is the write `syncTimezone` now performs.
    await cacheUserTimeZone('Asia/Dubai');

    expect(
      await resolveUserTimeZone(),
      'Asia/Dubai',
      reason: 'the process memo must not outlive the zone that produced it — '
          'if it does, the client stays on the departure zone for the whole '
          'session no matter what the server was told',
    );
  });

  test('travel moves the local day across a date boundary', () async {
    // 2026-08-04T03:00Z. In Los Angeles that is still Aug 3 (20:00); in Dubai
    // it is already Aug 4 (07:00). This is the disagreement in its sharpest
    // form: same instant, two different answers to "what day is it", and the
    // server has been told the second one.
    const instant = '2026-08-04T03:00Z';
    DateTime clock() => DateTime.parse(instant);

    await cacheUserTimeZone('America/Los_Angeles');
    expect((await resolveUserLocalDay(clock: clock)).dateString, '2026-08-03');

    await cacheUserTimeZone('Asia/Dubai');
    expect(
      (await resolveUserLocalDay(clock: clock)).dateString,
      '2026-08-04',
      reason: 'the client must land on the same day the server derives from '
          'the zone it was just given, or the unseal it holds back is one the '
          'server was ready to grant',
    );
  });

  test('a sign-out mid-write does not stamp one account onto another',
      () async {
    // `cacheUserTimeZone` re-reads `currentUserId` after its await for exactly
    // this. Pinned because the call now happens on every app open, in a
    // fire-and-forget from app_session — the window is real, not theoretical.
    await cacheUserTimeZone('America/Los_Angeles');

    fakeSync.userId = null;
    await cacheUserTimeZone('Asia/Dubai');

    fakeSync.userId = 'user-1';
    expect(
      await resolveUserTimeZone(),
      'America/Los_Angeles',
      reason: 'a zone resolved while signed out belongs to nobody',
    );
  });
}
