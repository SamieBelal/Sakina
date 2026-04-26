// Regression test for finding 2026-04-26-answercheckin-no-reentry-guard.md.
//
// `DailyLoopNotifier.answerCheckin` previously had no protection against
// concurrent invocation. On the final question, two rapid taps would both
// pass `currentIndex == 3`, both append to `checkinAnswers`, both call the
// AI service, and both call `saveCheckinRecord` → producing duplicate
// `user_checkin_history` rows + double streak marks.
//
// Fix at top of `answerCheckin`:
//
//     if (state.checkinLoading) return;
//
// This test pins that guard. The notifier exposes `debugSetCheckinLoading`
// (`@visibleForTesting`) so we can put it into the loading state without
// driving the full AI flow (the AI call is a top-level import — no DI seam
// available today; the debug setter is the lightest viable substitute).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-A'),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test('answerCheckin early-returns when checkinLoading is true', () async {
    final notifier = DailyLoopNotifier();

    // Let _initialize finish (it fetches streak/xp/tokens via the fake sync,
    // all of which return null → defaults). 200ms is plenty.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    notifier.debugSetCheckinLoading(true);

    final preAnswers = List<String>.from(notifier.state.checkinAnswers);
    final preIndex = notifier.state.checkinQuestionIndex;
    final preLoading = notifier.state.checkinLoading;

    await notifier.answerCheckin('blocked-answer');

    expect(
      notifier.state.checkinAnswers,
      preAnswers,
      reason: 'Guard must prevent appending when checkinLoading=true',
    );
    expect(
      notifier.state.checkinQuestionIndex,
      preIndex,
      reason: 'Guard must prevent index advancement when checkinLoading=true',
    );
    expect(
      notifier.state.checkinLoading,
      preLoading,
      reason: 'Guard must not toggle the loading flag',
    );

    notifier.dispose();
  });

  test('answerCheckin advances normally when checkinLoading is false',
      () async {
    final notifier = DailyLoopNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(notifier.state.checkinLoading, isFalse);
    expect(notifier.state.checkinQuestionIndex, 0);

    await notifier.answerCheckin('q0_answer');

    // Index advanced, answer appended, no loading flip (only Q4 sets loading).
    expect(notifier.state.checkinQuestionIndex, 1);
    expect(notifier.state.checkinAnswers, ['q0_answer']);
    expect(notifier.state.checkinLoading, isFalse);

    notifier.dispose();
  });
}
