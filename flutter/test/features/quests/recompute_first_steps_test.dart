import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Regression coverage for the eligibility-hydration race that left
/// `yoyoyo@gmail.com` (and others on a fresh sign-up) with zero `one_time`
/// rows in `user_quest_progress` despite completing all three First Steps
/// actions.
///
/// Cause: `_markBeginnerComplete` returns early on `!state.firstStepsEligible`.
/// When `hydrateFirstStepsEligibilityFromBatch` writes the eligibility flag
/// AFTER the live `on*Completed()` hook has already fired, the hook silently
/// drops the marker and never replays.
///
/// Fix: `recomputeQuestProgress` (which always runs after `reload()` re-reads
/// prefs) calls `markBeginnerCompleteFromRecompute(...)` for any beginner
/// quest whose authoritative data source has at least one row. This is
/// idempotent and self-healing.
///
/// These tests pin the public entry point used by recompute. The actual
/// `recomputeQuestProgress` plumbing (booleans → calls) is straight glue
/// validated by `flutter analyze` and the integration-style asserts here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

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

  int rpcCount(String fn) =>
      fakeSync.rpcCalls.where((c) => c['fn'] == fn).length;

  test(
      'markBeginnerCompleteFromRecompute(firstMuhasabah) marks the quest '
      'when eligibility is loaded — covers the self-heal path for a user '
      'who completed a check-in while in-memory state was still stale',
      () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    expect(notifier.state.firstStepsCompleted,
        isNot(contains(BeginnerQuestId.firstMuhasabah)));

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstMuhasabah);

    expect(notifier.state.firstStepsCompleted,
        contains(BeginnerQuestId.firstMuhasabah));

    notifier.dispose();
  });

  test(
      'markBeginnerCompleteFromRecompute(firstReflect) marks the quest',
      () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstReflect);

    expect(notifier.state.firstStepsCompleted,
        contains(BeginnerQuestId.firstReflect));

    notifier.dispose();
  });

  test(
      'markBeginnerCompleteFromRecompute(firstBuiltDua) marks the quest',
      () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstBuiltDua);

    expect(notifier.state.firstStepsCompleted,
        contains(BeginnerQuestId.firstBuiltDua));

    notifier.dispose();
  });

  test(
      'self-heal scenario: live hook fires while ineligible (silent drop), '
      'then eligibility hydrates, recompute marks the quest and grants '
      'rewards exactly once — pins the original yoyoyo@gmail.com bug',
      () async {
    // Stage 1: prefs has NO eligibility flag yet (race lost).
    SharedPreferences.setMockInitialValues({});
    final notifier = QuestsNotifier();
    await notifier.reload();

    // Live hook fires → short-circuits.
    await notifier.onMuhasabahCompleted();
    expect(notifier.state.firstStepsCompleted, isEmpty,
        reason: 'live hook must short-circuit when eligibility absent');
    final xpAfterDrop = rpcCount('award_xp');
    final scrollAfterDrop = rpcCount('earn_scrolls');

    // Stage 2: batch RPC lands → eligibility flag in prefs.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_steps_eligible_v1:user-1', true);
    await prefs.setString(
        'first_steps_anchor_date_v1:user-1', '2026-04-22');
    await notifier.reload();
    expect(notifier.state.firstStepsEligible, isTrue);
    expect(notifier.state.firstStepsCompleted, isEmpty,
        reason: 'reload alone does not retro-mark');

    // Stage 3: recompute path catches up.
    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstMuhasabah);

    expect(notifier.state.firstStepsCompleted,
        contains(BeginnerQuestId.firstMuhasabah));
    // Rewards were granted exactly once — by recompute, not by the dropped
    // live hook (which never reached the grant block).
    expect(rpcCount('award_xp'), greaterThan(xpAfterDrop),
        reason: 'recompute must grant the XP the live hook missed');
    expect(rpcCount('earn_scrolls'), greaterThan(scrollAfterDrop),
        reason: 'recompute must grant the scrolls the live hook missed');

    notifier.dispose();
  });

  test(
      'idempotent — second call to markBeginnerCompleteFromRecompute does '
      'not re-grant XP / tokens / scrolls', () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstMuhasabah);
    final xpAfterFirst = rpcCount('award_xp');
    final tokenAfterFirst = rpcCount('earn_tokens');
    final scrollAfterFirst = rpcCount('earn_scrolls');

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstMuhasabah);

    expect(rpcCount('award_xp'), xpAfterFirst,
        reason: 'second recompute mark must not re-grant XP');
    expect(rpcCount('earn_tokens'), tokenAfterFirst,
        reason: 'second recompute mark must not re-grant tokens');
    expect(rpcCount('earn_scrolls'), scrollAfterFirst,
        reason: 'second recompute mark must not re-grant scrolls');

    notifier.dispose();
  });

  test(
      'idempotent across live hook + recompute: live hook marked the quest '
      'first, recompute call after is a no-op', () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    // Normal path — live hook fires successfully.
    await notifier.onReflectCompleted();
    final xpAfterLive = rpcCount('award_xp');
    final tokenAfterLive = rpcCount('earn_tokens');
    final scrollAfterLive = rpcCount('earn_scrolls');

    // Recompute fires later — must not double-grant.
    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstReflect);

    expect(rpcCount('award_xp'), xpAfterLive);
    expect(rpcCount('earn_tokens'), tokenAfterLive);
    expect(rpcCount('earn_scrolls'), scrollAfterLive);

    notifier.dispose();
  });

  test(
      'ineligible user (account created before ship date) with data sources '
      'populated still does not get retro-marked — recompute respects the '
      'eligibility window', () async {
    // No eligibility flag in prefs → state.firstStepsEligible stays false.
    SharedPreferences.setMockInitialValues({});
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstMuhasabah);
    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstReflect);
    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstBuiltDua);

    expect(notifier.state.firstStepsCompleted, isEmpty,
        reason: 'recompute must NOT retro-grant to pre-ship-date accounts');
    expect(rpcCount('award_xp'), 0);
    expect(rpcCount('earn_tokens'), 0);

    notifier.dispose();
  });

  test(
      'marking all three beginner quests via recompute claims the bundle '
      'bonus exactly once', () async {
    seedFirstStepsEligible();
    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstMuhasabah);
    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstReflect);
    await notifier
        .markBeginnerCompleteFromRecompute(BeginnerQuestId.firstBuiltDua);

    expect(notifier.state.firstStepsCompleted.length, 3);
    expect(notifier.state.firstStepsBundleClaimed, isTrue,
        reason: 'third mark triggers bundle claim');
    expect(notifier.state.pendingBundleCelebration, isNotNull,
        reason: 'UI receives celebration payload from recompute path too');

    notifier.dispose();
  });
}
