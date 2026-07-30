import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// The day-open gate's UTC/local seam (W4 Wave 4 — plan §6, §11 "Day boundary").
///
/// The launch gate is UTC because it must agree with `claim_daily_reward`; the
/// auto-entry marker is user-local because "have we already asked this person
/// today" is a question about their day. They disagree near midnight, and this
/// file pins which way that disagreement is allowed to fall.
///
/// The fixture is the one `queue_deck_reveal_test.dart` established:
/// `America/Los_Angeles`, where 2026-08-04T03:00Z is **Aug 3, 20:00 local** —
/// the UTC day has already rolled while the user's evening has not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  /// Mon 2026-08-03, 16:00 local (= 23:00 UTC Monday). Both clocks agree.
  final mondayAfternoon = DateTime.utc(2026, 8, 3, 23);

  /// Mon 2026-08-03, 18:00 local — but 01:00 UTC **Tuesday**. The clocks split.
  final mondayEvening = DateTime.utc(2026, 8, 4, 1);

  /// Tue 2026-08-04, 09:00 local (= 16:00 UTC Tuesday). A genuinely new day on
  /// both clocks.
  final tuesdayMorning = DateTime.utc(2026, 8, 4, 16);

  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    // Both clocks read the same instant; the point is that they map it onto
    // different calendar days.
    now = mondayAfternoon;
    debugLaunchGateClock = () => now;
    debugDailyQuestionGateClock = () => now;
    resetLaunchGateMemoryGuard();
  });

  tearDown(() {
    debugLaunchGateClock = () => DateTime.now().toUtc();
    debugDailyQuestionGateClock = null;
    debugResetUserLocalDay();
    resetLaunchGateMemoryGuard();
    SupabaseSyncService.debugReset();
  });

  test('the two clocks really do disagree at the instant under test', () async {
    now = mondayEvening;
    expect(launchGateTodayMarker(), '2026-08-04',
        reason: 'the UTC gate has already rolled into Tuesday');
    expect(await userLocalDayString(clock: debugDailyQuestionGateClock),
        '2026-08-03',
        reason: "the user's evening is still Monday");
  });

  test('a completed local day is not re-asked after UTC midnight', () async {
    // The user finishes their muḥāsabah on Monday afternoon. `completeDeeper()`
    // stamps both markers; this is that pair, called directly.
    await markDailyLaunchShown();
    await markDailyQuestionAutoEnteredToday();

    // Two hours later — same local evening, next UTC day.
    now = mondayEvening;
    resetLaunchGateMemoryGuard(); // a fresh app session, not the same process

    expect(await dailyQuestionAutoEnteredToday(), isTrue,
        reason: 'the local marker still covers this evening');
    expect(await shouldAutoEnterDailyQuestion(), isFalse,
        reason: 'the UTC gate has rolled and would re-fire on its own — the '
            'local marker is exactly what stops the question being asked '
            'twice in one evening');
  });

  test('the next local day asks again', () async {
    await markDailyLaunchShown();
    await markDailyQuestionAutoEnteredToday();

    now = tuesdayMorning;
    resetLaunchGateMemoryGuard();

    expect(await dailyQuestionAutoEnteredToday(), isFalse,
        reason: 'a new local day clears the marker — the suppression was for '
            'that day, not forever');
  });

  test('the marker alone suppresses, without consulting the UTC gate',
      () async {
    // Ordering matters for a reason worth pinning: `shouldShowDailyLaunch()`
    // does a network reconcile, so the cheap local read has to come first.
    await markDailyQuestionAutoEnteredToday();
    expect(await shouldAutoEnterDailyQuestion(), isFalse);
  });

  test('a fresh local day with a fresh UTC day does auto-enter', () async {
    expect(await shouldAutoEnterDailyQuestion(), isTrue,
        reason: 'nothing stamped, nothing claimed — this is the ordinary '
            'first open of the day');
  });

  test('an unreadable marker fails OPEN', () async {
    // No marker at all is the same shape as a marker that could not be read:
    // the user must never be locked out of the day's question by a prefs
    // problem. The worst case is one auto-entry they already declined.
    expect(await dailyQuestionAutoEnteredToday(), isFalse);
  });
}
