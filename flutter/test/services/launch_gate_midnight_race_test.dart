// The day-open markers must record the day the app ASKED, not the day the
// write happened to land on.
//
// `daily_launch_overlay.initState` starts both marker writes without awaiting
// them — deliberately, so the first frame is not blocked on storage. That makes
// the gap between "the overlay appeared" and "the marker was written" real and
// unbounded: a cold prefs channel, a first-resolve timezone lookup.
//
// `markDailyLaunchShown` used to resolve the date on the far side of
// `SharedPreferences.getInstance()`. An app opened at 23:59:59 could therefore
// stamp TOMORROW, marking a day as already-shown before it started — costing the
// user that whole day of the loop, including the question, since
// `shouldAutoEnterDailyQuestion` leans on the same gate.
//
// The companion helper `markDailyQuestionAutoEnteredToday` was NOT affected and
// is covered here too, so the asymmetry is recorded rather than rediscovered:
// it delegates to `resolveUserLocalDay`, which captures `_nowUtc(clock)`
// synchronously before its own first await.

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    debugResetUserLocalDay();
  });

  tearDown(() {
    debugLaunchGateClock = () => DateTime.now().toUtc();
    debugDailyQuestionGateClock = null;
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  // **Midnight passes WHILE the write is in flight.** Advancing the clock from
  // the test between starting the call and awaiting it is what makes these
  // tests discriminate — a clock that merely advances on each read does not,
  // because both the correct and the broken version read it exactly once. The
  // question is only ever *when*, and the only way to ask that is to move the
  // world between the two moments. (The first version of this test used a
  // read-counting clock and passed against the bug.)
  test('the launch marker records the opening instant, not the landing one',
      () async {
    var now = DateTime.utc(2026, 8, 3, 23, 59, 59);
    debugLaunchGateClock = () => now;

    // Not awaited yet — exactly how the overlay calls it. The body runs
    // synchronously up to its first await and then suspends on storage.
    final pending = markDailyLaunchShown();
    now = DateTime.utc(2026, 8, 4, 0, 0, 1); // the date turns while it waits
    await pending;

    expect(
      await readLaunchGateMarker(),
      '2026-08-03',
      reason: 'stamping 2026-08-04 here marks tomorrow as already-shown before '
          'it begins — the user silently loses the whole day: no overlay, and '
          'no question either',
    );
  });

  test('the question marker also records the opening instant', () async {
    // Not where the bug was — `markDailyQuestionAutoEnteredToday` delegates to
    // `resolveUserLocalDay`, which captures its instant before its own first
    // await — but the property has to hold for both or the two gates disagree
    // about which day it is, and their conjunction decides whether the user is
    // asked at all. Pinned so the asymmetry is recorded, not rediscovered.
    debugUserTimeZoneOverride = 'UTC';
    var now = DateTime.utc(2026, 8, 3, 23, 59, 59);
    debugDailyQuestionGateClock = () => now;

    final pending = markDailyQuestionAutoEnteredToday();
    now = DateTime.utc(2026, 8, 4, 0, 0, 1);
    await pending;

    // Same clock, now past midnight: "have we already asked today" must be
    // false for the NEW day, which holds only if the marker kept the old one.
    expect(
      await dailyQuestionAutoEnteredToday(),
      isFalse,
      reason: 'a marker stamped with tomorrow suppresses tomorrow\'s question',
    );
  });
}
