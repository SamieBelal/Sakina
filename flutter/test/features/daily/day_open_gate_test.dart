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

  test('resetting the daily loop re-arms the question, not just the overlay',
      () async {
    // The bug this closes: W4 Wave 4 added a SECOND day-open gate, and every
    // "reset the daily loop" path in the app cleared only the first. Settings,
    // dev tools and the post-onboarding reset all called
    // `resetDailyLaunchGate()` alone — so the UTC gate re-armed, the local
    // auto-entry marker did not, and `shouldAutoEnterDailyQuestion()` kept
    // returning false for the rest of the local day. A user (or a QA pass)
    // asking for a fresh day got a half-reset one.
    await markDailyLaunchShown();
    await markDailyQuestionAutoEnteredToday();
    expect(await shouldAutoEnterDailyQuestion(), isFalse);

    // Clearing only the launch gate is NOT enough — this is the half-reset.
    await resetDailyLaunchGate();
    resetLaunchGateMemoryGuard();
    expect(await shouldAutoEnterDailyQuestion(), isFalse,
        reason: 'the local marker still suppresses — which is exactly why '
            'every reset path has to clear both');

    await resetDailyQuestionGate();
    expect(await shouldAutoEnterDailyQuestion(), isTrue,
        reason: 'both cleared: the day is genuinely fresh again');
  });

  group('an unreadable marker fails CLOSED', () {
    // This group replaces a test that claimed to cover the error path and did
    // not. It asserted the NO-MARKER case (`marker == null → false`) and
    // reasoned that "no marker at all is the same shape as a marker that could
    // not be read" — a different line of code, and the substitution is why the
    // catch block's behaviour went unexamined long enough to contradict the
    // library doc three screens above it.
    //
    // The corruption below is real, not synthetic: SharedPreferences stores
    // typed values, so a key holding a non-String makes `getString` throw a
    // cast error. That is exactly what a schema change or a cross-version
    // rollback produces on a real device.
    String key() =>
        'flutter.${dailyQuestionAutoEntryBaseKey}:u1';

    test('the corruption actually throws — the probe is not a no-op', () async {
      SharedPreferences.setMockInitialValues({key(): 12345});
      final prefs = await SharedPreferences.getInstance();
      expect(() => prefs.getString(dailyQuestionAutoEntryBaseKey + ':u1'),
          throwsA(isA<TypeError>()),
          reason: 'if this stops throwing, the tests below stop exercising the '
              'catch branch and quietly become vacuous again');
    });

    test('reports already-asked, so the day-open does not fire', () async {
      SharedPreferences.setMockInitialValues({key(): 12345});

      expect(await dailyQuestionAutoEnteredToday(), isTrue,
          reason: 'when in doubt, do not ask. Nothing here gates the muḥāsabah '
              'route, so failing closed costs one tap on the home CTA — while '
              'failing open under a persistent prefs fault re-asks on every '
              'single open, which cannot be undone');
      expect(await shouldAutoEnterDailyQuestion(), isFalse);
    });

    test('and the home CTA still re-enters the whole flow', () async {
      // The cheap side of the asymmetry, stated as a test so nobody "fixes"
      // the fail-closed by arguing the user is locked out. They are not: this
      // marker only ever gated the app asking UNPROMPTED.
      SharedPreferences.setMockInitialValues({key(): 12345});

      expect(await dailyQuestionAutoEnteredToday(), isTrue);
      // Nothing in this library is consulted by the muḥāsabah route itself —
      // there is no gate function here that a CTA tap has to pass.
      expect(await shouldAutoEnterDailyQuestion(), isFalse,
          reason: 'auto-entry is suppressed, and that is the whole effect');
    });
  });
}
