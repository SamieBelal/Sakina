import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// §12 finding 4 — the beginner-quest grant paths for `onReflectCompleted`
/// and `onBuiltDuaCompleted` symmetrize the coverage that
/// `multi_grant_test.dart` already provides for `onMuhasabahCompleted`.
///
/// The risk surface: a refactor swaps the wrong `BeginnerQuestId`, drops the
/// `_markBeginnerComplete` call entirely, or reorders the daily/beginner
/// pair so a failure on the daily side prevents the beginner grant. Each
/// test pins the contract for one entry point.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    // Working RPC handlers so the grant pipeline isn't aborted by sync
    // failures (which would cause early-return before the beginner mark).
    int xpTotal = 0;
    int tokenBalance = 0;
    int scrollBalance = 0;
    fakeSync.rpcHandlers['award_xp'] = (params) async {
      xpTotal += (params?['amount'] as num?)?.toInt() ?? 0;
      return {
        'total_xp': xpTotal,
        'token_balance': null,
        'scroll_balance': null,
      };
    };
    fakeSync.rpcHandlers['earn_tokens'] = (params) async {
      tokenBalance += (params?['amount'] as num?)?.toInt() ?? 0;
      return tokenBalance;
    };
    fakeSync.rpcHandlers['earn_scrolls'] = (params) async {
      scrollBalance += (params?['amount'] as num?)?.toInt() ?? 0;
      return scrollBalance;
    };
  });

  tearDown(SupabaseSyncService.debugReset);

  void seedFirstStepsEligible() {
    SharedPreferences.setMockInitialValues({
      'first_steps_eligible_v1:user-1': true,
      'first_steps_anchor_date_v1:user-1': '2026-04-22',
    });
  }

  test('onReflectCompleted marks the firstReflect beginner quest', () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    expect(notifier.state.firstStepsCompleted, isNot(contains(
          BeginnerQuestId.firstReflect,
        )));

    await notifier.onReflectCompleted();

    expect(notifier.state.firstStepsCompleted,
        contains(BeginnerQuestId.firstReflect),
        reason: 'onReflectCompleted must mark the firstReflect beginner '
            'quest — refactor guard');
    // Must NOT mark a sibling beginner ID by accident.
    expect(notifier.state.firstStepsCompleted,
        isNot(contains(BeginnerQuestId.firstBuiltDua)));
    expect(notifier.state.firstStepsCompleted,
        isNot(contains(BeginnerQuestId.firstMuhasabah)));

    notifier.dispose();
  });

  test('onBuiltDuaCompleted marks the firstBuiltDua beginner quest',
      () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier.onBuiltDuaCompleted();

    expect(notifier.state.firstStepsCompleted,
        contains(BeginnerQuestId.firstBuiltDua),
        reason: 'onBuiltDuaCompleted must mark the firstBuiltDua beginner '
            'quest — refactor guard');
    expect(notifier.state.firstStepsCompleted,
        isNot(contains(BeginnerQuestId.firstReflect)));

    notifier.dispose();
  });

  test(
      'beginner-grant hooks are idempotent: second call to either '
      '`onReflectCompleted` or `onBuiltDuaCompleted` issues zero new earn_* '
      'RPCs', () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier.onReflectCompleted();
    await notifier.onBuiltDuaCompleted();

    final xpCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'award_xp').length;
    final scrollCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_scrolls').length;
    final tokenCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_tokens').length;

    // Re-fire both. Neither should mutate.
    await notifier.onReflectCompleted();
    await notifier.onBuiltDuaCompleted();

    expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'award_xp').length,
        xpCalls,
        reason: 'second invocation must not re-grant XP for either hook');
    expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_scrolls').length,
        scrollCalls,
        reason: 'second invocation must not re-grant scrolls');
    expect(fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_tokens').length,
        tokenCalls,
        reason: 'second invocation must not re-grant tokens');

    notifier.dispose();
  });

  test(
      'when first-steps is NOT eligible, beginner-grant hooks short-circuit '
      'and do not mark the beginner quest', () async {
    // Explicitly empty prefs — eligibility flag absent. (setMockInitialValues
    // is only set inside `seedFirstStepsEligible`; without an explicit empty
    // call here, prefs may inherit a flag from a prior test in this file.)
    SharedPreferences.setMockInitialValues({});
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier.onReflectCompleted();
    await notifier.onBuiltDuaCompleted();

    expect(notifier.state.firstStepsCompleted, isEmpty,
        reason: 'beginner grants must require first-steps eligibility — '
            'returning users (post-onboarding window) should not retro-grant');

    notifier.dispose();
  });
}
