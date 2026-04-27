import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// §12 case 5 — multi-quest fan-out from a single user action.
///
/// `onMuhasabahCompleted` triggers two SEPARATE grant code paths:
///   1. `_tryComplete(QuestCadence.daily, 4)` → `completeQuest()` →
///      grants via `earnTierUpScrolls` + `awardXp` + `earnTokens`.
///      Only fires when daily pool slot 4 (the muhasabah quest) is in
///      today's rotation. The rotation picks 3 of 9 indices keyed off
///      day-of-year, so this is non-deterministic across run dates.
///
///   2. `_markBeginnerComplete(BeginnerQuestId.firstMuhasabah)` →
///      grants directly (does NOT route through `completeQuest()`),
///      requires `firstStepsEligible == true`. Always fires regardless
///      of rotation.
///
/// These tests pin invariants that hold on any run date:
///   - Beginner path always grants on first call.
///   - Both paths are idempotent on repeat — second invocation
///     issues zero new earn_* RPC calls.
///   - When the scroll RPC fails, NEITHER path mutates completion
///     state (early-return before XP/token grants).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    // Working RPC handlers. Without these, callRpc returns null and the
    // grant services treat the call as a sync failure (early-return).
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

  /// Counts the number of RPC calls matching `fn`.
  int rpcCount(String fn) =>
      fakeSync.rpcCalls.where((c) => c['fn'] == fn).length;

  /// Sum of `params.amount` for calls matching `fn` — useful for asserting
  /// total reward delivered without assuming call ordering.
  int rpcAmountSum(String fn) {
    return fakeSync.rpcCalls
        .where((c) => c['fn'] == fn)
        .map((c) => (c['params'] as Map<String, dynamic>?)?['amount'])
        .whereType<num>()
        .fold<int>(0, (a, b) => a + b.toInt());
  }

  /// Seeds first-steps eligibility so the beginner path is reachable.
  /// The anchor date keeps the user inside the eligibility window.
  void seedFirstStepsEligible() {
    SharedPreferences.setMockInitialValues({
      'first_steps_eligible_v1:user-1': true,
      'first_steps_anchor_date_v1:user-1': '2026-04-22',
    });
  }

  test(
      'onMuhasabahCompleted grants the beginner First-Steps quest exactly '
      'once with the expected XP/token/scroll amounts (case 5 invariant)',
      () async {
    seedFirstStepsEligible();

    final notifier = QuestsNotifier();
    await notifier.reload();

    final beginner = beginnerQuests
        .firstWhere((q) => q.id == BeginnerQuestId.firstMuhasabah);
    final dailyHit = notifier.state.daily
        .where((q) => q.poolIndex == 4)
        .cast<Quest?>()
        .firstWhere((_) => true, orElse: () => null);

    final xpBefore = rpcCount('award_xp');
    final tokensBefore = rpcCount('earn_tokens');
    final scrollsBefore = rpcCount('earn_scrolls');

    await notifier.onMuhasabahCompleted();

    // Beginner path always fires.
    expect(
      notifier.state.firstStepsCompleted,
      contains(BeginnerQuestId.firstMuhasabah),
      reason: 'Beginner First Steps quest must mark complete',
    );

    // Daily path fires only if today's rotation includes slot 4.
    final dailyCompleted = dailyHit != null &&
        notifier.state.completedIds.contains(dailyHit.id);
    if (dailyHit != null) {
      expect(dailyCompleted, isTrue,
          reason: 'When daily pool slot 4 is in today\'s rotation, the '
              'daily quest must complete');
    }

    // Reward total = beginner reward (+ daily reward iff rotation hit).
    final expectedXp =
        beginner.xpReward + (dailyHit?.xpReward ?? 0);
    final expectedTokens =
        beginner.tokenReward + (dailyHit?.tokenReward ?? 0);
    final expectedScrolls =
        beginner.scrollReward + (dailyHit?.scrollReward ?? 0);

    final xpDeltaCount = rpcCount('award_xp') - xpBefore;
    final tokensDeltaCount = rpcCount('earn_tokens') - tokensBefore;
    final scrollsDeltaCount = rpcCount('earn_scrolls') - scrollsBefore;

    final expectedCalls = (dailyHit != null) ? 2 : 1;
    if (beginner.xpReward > 0 && (dailyHit?.xpReward ?? 1) > 0) {
      expect(xpDeltaCount, expectedCalls,
          reason: 'award_xp must fire once per granting path');
    }
    if (beginner.tokenReward > 0 && (dailyHit?.tokenReward ?? 1) > 0) {
      expect(tokensDeltaCount, expectedCalls,
          reason: 'earn_tokens must fire once per granting path');
    }
    if (beginner.scrollReward > 0 && (dailyHit?.scrollReward ?? 1) > 0) {
      expect(scrollsDeltaCount, expectedCalls,
          reason: 'earn_scrolls must fire once per granting path');
    }

    // Pin exact reward amounts. Count-only assertions miss the regression
    // where a future change drops a reward to 0 — `if (xpReward > 0)`
    // guards skip the call and the count still matches.
    expect(rpcAmountSum('award_xp'), expectedXp,
        reason: 'Sum of awarded XP must equal beginner + daily rewards');
    expect(rpcAmountSum('earn_tokens'), expectedTokens,
        reason: 'Sum of granted tokens must equal beginner + daily rewards');
    expect(rpcAmountSum('earn_scrolls'), expectedScrolls,
        reason: 'Sum of granted scrolls must equal beginner + daily rewards');

    notifier.dispose();
  });

  test(
      'second call to onMuhasabahCompleted issues zero new earn_* RPCs '
      '(idempotent across both grant paths)', () async {
    seedFirstStepsEligible();

    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier.onMuhasabahCompleted();

    final xpAfterFirst = rpcCount('award_xp');
    final tokensAfterFirst = rpcCount('earn_tokens');
    final scrollsAfterFirst = rpcCount('earn_scrolls');

    await notifier.onMuhasabahCompleted();

    expect(rpcCount('award_xp'), xpAfterFirst,
        reason: 'Second invocation must not re-grant XP');
    expect(rpcCount('earn_tokens'), tokensAfterFirst,
        reason: 'Second invocation must not re-grant tokens');
    expect(rpcCount('earn_scrolls'), scrollsAfterFirst,
        reason: 'Second invocation must not re-grant scrolls');

    notifier.dispose();
  });

  test(
      'when earn_scrolls fails, NEITHER grant path advances completion '
      'state — daily and beginner both early-return before XP/tokens',
      () async {
    seedFirstStepsEligible();
    // Override the working scroll handler to always fail (returns null →
    // earnTierUpScrolls returns success=false → both paths early-return).
    fakeSync.rpcHandlers['earn_scrolls'] = (_) async => null;

    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier.onMuhasabahCompleted();

    expect(notifier.state.firstStepsCompleted, isEmpty,
        reason: 'Beginner state must not advance when scroll grant fails');
    final dailyHit = notifier.state.daily
        .where((q) => q.poolIndex == 4)
        .cast<Quest?>()
        .firstWhere((_) => true, orElse: () => null);
    if (dailyHit != null) {
      expect(notifier.state.completedIds.contains(dailyHit.id), isFalse,
          reason:
              'Daily quest must not mark complete when scroll grant fails');
    }
    expect(rpcCount('award_xp'), 0,
        reason: 'XP must not be granted on the scroll-failure branch');
    expect(rpcCount('earn_tokens'), 0,
        reason: 'Tokens must not be granted on the scroll-failure branch');

    notifier.dispose();
  });
}
