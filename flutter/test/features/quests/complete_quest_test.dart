import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Tests for the quest/celebration regressions identified against commit
/// `1443ba5` — specifically the double scroll payout in [completeQuest] and
/// the non-deterministic beginner/bundle pending-flag combination.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    // Default xp / tokens RPC handlers — return something non-null so earn
    // paths don't spuriously fail the test. completeQuest() awaits these.
    // award_xp must return the {total_xp, token_balance, scroll_balance}
    // shape that xp_service.awardXp parses; otherwise the function early-
    // returns with gained=0 and silently skips the level-up branch.
    fakeSync.rpcHandlers['award_xp'] = (_) async => {
          'total_xp': 0,
          'token_balance': null,
          'scroll_balance': null,
        };
    fakeSync.rpcHandlers['earn_tokens'] = (_) async => 0;
  });

  tearDown(SupabaseSyncService.debugReset);

  /// Seeds a scroll-RPC handler that counts invocations and returns
  /// `previousBalance + amount` each time.
  int _installScrollHandler() {
    int balance = 0;
    fakeSync.rpcHandlers['earn_scrolls'] = (params) async {
      final amount = (params?['amount'] as num?)?.toInt() ?? 0;
      balance += amount;
      return balance;
    };
    return balance;
  }

  int _scrollRpcCallCount() {
    return fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_scrolls').length;
  }

  test(
      'REGRESSION: completeQuest grants scrollReward exactly once '
      '(was double-paying as of commit 1443ba5)', () async {
    _installScrollHandler();

    final notifier = QuestsNotifier();
    await notifier.reload();

    // Pick a daily quest with a non-zero scroll reward.
    final quest = notifier.state.weekly.firstWhere((q) => q.scrollReward > 0);

    await notifier.completeQuest(quest.id);

    expect(
      _scrollRpcCallCount(),
      1,
      reason: 'earn_scrolls should fire exactly once per completed quest',
    );

    // And the one call that did fire should use the quest's scrollReward,
    // not a doubled value.
    final scrollCall = fakeSync.rpcCalls.firstWhere(
      (c) => c['fn'] == 'earn_scrolls',
    );
    expect(scrollCall['params']['amount'], quest.scrollReward);

    notifier.dispose();
  });

  test(
      'completeQuest bails early when scroll cap is rejected and does not '
      'mark the quest completed', () async {
    // Handler returns null → earnTierUpScrolls returns success=false.
    fakeSync.rpcHandlers['earn_scrolls'] = (_) async => null;

    final notifier = QuestsNotifier();
    await notifier.reload();

    final quest = notifier.state.weekly.firstWhere((q) => q.scrollReward > 0);

    await notifier.completeQuest(quest.id);

    expect(
      notifier.state.completedIds.contains(quest.id),
      isFalse,
      reason: 'Completion must not persist when scroll grant is rejected',
    );
    expect(
      fakeSync.rpcCalls.where((c) => c['fn'] == 'earn_xp'),
      isEmpty,
      reason: 'XP must not be awarded when completion was rejected',
    );

    notifier.dispose();
  });

  test(
      'final beginner quest suppresses pendingBeginnerCompletion so it '
      'does not overlap the bundle celebration overlay', () async {
    _installScrollHandler();

    // Seed: first_steps eligible; two of three beginner quests already done.
    SharedPreferences.setMockInitialValues({
      'first_steps_eligible_v1:user-1': true,
      'first_steps_completed_v1:user-1': jsonEncode([
        BeginnerQuestId.firstMuhasabah.key,
        BeginnerQuestId.firstReflect.key,
      ]),
      'first_steps_bundle_claimed_v1:user-1': false,
      'first_steps_anchor_date_v1:user-1': '2026-04-22',
    });

    final notifier = QuestsNotifier();
    await notifier.reload();

    // Completing the final beginner quest (build-a-dua) should fire the bundle.
    await notifier.onBuiltDuaCompleted();

    expect(
      notifier.state.pendingBundleCelebration,
      isNotNull,
      reason: 'Bundle celebration must fire when all 3 beginner quests done',
    );
    expect(
      notifier.state.pendingBeginnerCompletion,
      isNull,
      reason:
          'Individual beginner toast must be suppressed on bundle completion '
          'so the full-screen overlay plays cleanly',
    );

    notifier.dispose();
  });

  test(
      'non-final beginner quest stamps pendingBeginnerCompletion without '
      'firing the bundle celebration', () async {
    _installScrollHandler();

    SharedPreferences.setMockInitialValues({
      'first_steps_eligible_v1:user-1': true,
      'first_steps_anchor_date_v1:user-1': '2026-04-22',
    });

    final notifier = QuestsNotifier();
    await notifier.reload();

    await notifier.onMuhasabahCompleted();

    expect(notifier.state.pendingBundleCelebration, isNull);
    expect(notifier.state.pendingBeginnerCompletion, isNotNull);
    expect(
      notifier.state.pendingBeginnerCompletion!.id,
      BeginnerQuestId.firstMuhasabah,
    );

    notifier.dispose();
  });
}
