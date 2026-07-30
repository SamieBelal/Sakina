import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../../support/fake_supabase_sync_service.dart';

/// Completion stamps the day-open markers, by any entry path (W4 Wave 4 —
/// plan §6 item 3).
///
/// **The bug this closes only exists off the overlay path.** `markDailyLaunchShown()`
/// was written by `DailyLaunchOverlay.initState` and nowhere else, so a user who
/// entered through the home-screen widget — which routes straight to
/// `/muhasabah` and never touches the overlay — could finish the entire loop and
/// then meet the day-open an hour later on a day already done.
///
/// These tests deliberately never build a widget. `completeDeeper()` is the one
/// place every entry converges, and driving it directly is what demonstrates the
/// coverage is structural rather than a property of one screen's lifecycle.
class _Loop extends DailyLoopNotifier {
  _Loop() : super(skipInitForTests: true);

  void enter(DailyLoopStep step) {
    state = state.copyWith(loaded: true, currentStep: step, checkinDone: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  /// Mon 2026-08-03, 16:00 America/Los_Angeles.
  final now = DateTime.utc(2026, 8, 3, 23);

  late _Loop loop;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'America/Los_Angeles';
    debugLaunchGateClock = () => now;
    debugDailyQuestionGateClock = () => now;
    debugDailyLoopClock = () => now;
    resetLaunchGateMemoryGuard();
    loop = _Loop();
  });

  tearDown(() {
    loop.dispose();
    debugLaunchGateClock = () => DateTime.now().toUtc();
    debugDailyQuestionGateClock = null;
    debugDailyLoopClock = () => DateTime.now().toUtc();
    debugResetUserLocalDay();
    resetLaunchGateMemoryGuard();
    SupabaseSyncService.debugReset();
  });

  test('completing the loop stamps both day-open markers', () async {
    loop.enter(DailyLoopStep.deeper);
    expect(await readLaunchGateMarker(), isNull);
    expect(await dailyQuestionAutoEnteredToday(), isFalse);

    await loop.completeDeeper();

    // UTC — the widget-entry bug. Enter by widget, finish, reopen an hour
    // later: without this the day-open fired on a day already done.
    expect(await readLaunchGateMarker(), launchGateTodayMarker(),
        reason: 'completion must satisfy the UTC launch gate, whichever way '
            'the user got here');
    // User-local — the belt to that brace, since the UTC gate legitimately
    // reopens after UTC midnight on the same local evening.
    expect(await dailyQuestionAutoEnteredToday(), isTrue);
  });

  test('and the day-open then declines to fire', () async {
    loop.enter(DailyLoopStep.deeper);
    await loop.completeDeeper();
    resetLaunchGateMemoryGuard(); // a fresh session, not the same process

    expect(await shouldAutoEnterDailyQuestion(), isFalse,
        reason: 'the whole point of the stamps');
  });

  test('completeDeeper stays idempotent', () async {
    loop.enter(DailyLoopStep.deeper);
    await loop.completeDeeper();
    // The second call short-circuits on `currentStep == completed` before it
    // reaches the markers — it must neither throw nor change anything.
    await loop.completeDeeper();

    expect(loop.state.currentStep, DailyLoopStep.completed);
    expect(await dailyQuestionAutoEnteredToday(), isTrue);
  });

  test('a marker failure cannot swallow the completion', () async {
    // The user-visible contract is that "Ameen" completes the flow. The
    // markers are best-effort precisely so a prefs or clock problem downgrades
    // to one redundant day-open rather than to a tap that did nothing.
    debugDailyQuestionGateClock = () => throw StateError('clock exploded');
    loop.enter(DailyLoopStep.deeper);

    await loop.completeDeeper();

    expect(loop.state.currentStep, DailyLoopStep.completed);
    expect(loop.state.deeperDone, isTrue);
  });
}
