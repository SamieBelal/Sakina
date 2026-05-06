// Behavioral contract for `DailyLoopNotifier.resetToday`. After the
// muhasabah_screen race-fix refactor, the screen no longer re-triggers
// `discoverName()` from a build conditional when state.checkinDone goes
// false. Both call sites that want a fresh muhasabah cycle now chain
// `resetToday()` + `discoverName()` explicitly:
//
//   - "Seek Another Name" (in muhasabah_screen.dart, _buildCompleted)
//   - "Discover a New Name" home tile (in progress_screen.dart, completed
//     state — pushes /muhasabah which then auto-fires from initState)
//
// This test pins the contract that resetToday brings the notifier back to
// a state where the cold-load auto-trigger in initState will fire:
//
//   - state.checkinDone == false
//   - state.currentStep == DailyLoopStep.checkin
//   - state.cardEngageResult == null
//   - state.engagedCard == null
//
// If any of those leak across resetToday, the post-refactor flow breaks:
// "Seek Another Name" would fire discoverName explicitly (still works),
// but the next cold load via the home tile would skip the initState
// auto-trigger because the state would look "already done".

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

  test(
      'resetToday clears checkinDone, currentStep, cardEngageResult, '
      'engagedCard so initState auto-trigger fires on next mount', () async {
    final notifier = DailyLoopNotifier();

    // Let _initialize finish so we have a real baseline. The notifier
    // fetches streak/xp/tokens via the fake (all return null → defaults).
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Simulate a completed muhasabah cycle. Set the fields the screen
    // checks on cold load + the fields the new ref.listen gates on.
    notifier.debugSetCheckinDoneForReset(
      checkinName: 'Ar-Rahman',
      checkinNameArabic: 'الرَّحْمَن',
    );
    expect(notifier.state.checkinDone, isTrue,
        reason: 'baseline: cycle should look completed');

    await notifier.resetToday();

    expect(notifier.state.checkinDone, isFalse,
        reason:
            'resetToday must clear checkinDone — initState auto-trigger '
            'gates on `!state.checkinDone`');
    expect(notifier.state.currentStep, DailyLoopStep.checkin,
        reason:
            'resetToday must reset currentStep — _buildContent routes on '
            'this and the gacha render path expects checkin step');
    expect(notifier.state.cardEngageResult, isNull,
        reason:
            'resetToday must clear cardEngageResult — ref.listen uses '
            'identity comparison on this field to detect a fresh tier-up. '
            'A leaked result would suppress the next gacha overlay.');
    expect(notifier.state.engagedCard, isNull,
        reason:
            'resetToday must clear engagedCard — leaked card data would '
            'render in the Name reveal overlay for the WRONG cycle.');
  });
}
