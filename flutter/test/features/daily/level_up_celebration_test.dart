// §12 case 2: when XP crosses a level threshold, the daily loop notifier
// flips its level-up celebration state so the UI can render the overlay.
//
// `_handleXpAward` (`daily_loop_provider.dart:314`) reads `XpAwardResult` and,
// when `leveledUp == true`, copies the new level title, level number, and
// per-level rewards (token + scroll) into `DailyLoopState`. Without coverage,
// a future change that drops one of these field assignments would silently
// disable the level-up overlay — the user would still gain XP, but the
// celebration would never fire.
//
// We drive the seam `debugHandleXpAward` to bypass the muhasabah/discovery
// callsites (which require a card collection + AI mocks) and instead pin
// the precise state mutation against a controlled `award_xp` RPC return.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-A');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test(
      'XP crossing level 1 → level 2 threshold flips leveledUp and sets the '
      'new title / level / rewards on DailyLoopState (case 2 invariant)',
      () async {
    // Pre-seed cached XP just below the L2 threshold. Level 2 starts at
    // 75 XP per `xp_service.dart:98`.
    await hydrateXpCache(totalXp: 70);

    // Working award_xp handler. xp_service expects {total_xp, token_balance,
    // scroll_balance}. The grant of 30 XP pushes total to 100 → level 2.
    fakeSync.rpcHandlers['award_xp'] = (params) async => {
          'total_xp': 100,
          'token_balance': 5,
          'scroll_balance': 0,
        };
    fakeSync.rpcHandlers['earn_tokens'] = (_) async => 5;

    final notifier = DailyLoopNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(notifier.state.leveledUp, isFalse,
        reason: 'level-up flag must start false');

    await notifier.debugHandleXpAward(30);

    final s = notifier.state;
    expect(s.leveledUp, isTrue,
        reason: 'crossing 75 XP must flip leveledUp');
    expect(s.newLevelNumber, 2,
        reason: 'new level number must reflect the threshold crossed');
    expect(s.newLevelTitle, 'Listener',
        reason: 'L2 title (per xp_service xpLevels[1]) must propagate to '
            'state for the celebration overlay');
    expect(s.newLevelTitleArabic, 'مُسْتَمِع');
    expect(s.levelNumber, 2,
        reason: 'live level (not just celebration level) must update');
    expect(s.xpTotal, 100);
    expect(s.levelUpRewards, isNotNull,
        reason: 'rewards struct must be populated so the overlay can render '
            'token + scroll deltas');
    // L2 token reward is 5 (xp_service.dart:99), scrollReward 0.
    expect(s.levelUpRewards!.tokensAwarded, 5);
    expect(s.levelUpRewards!.scrollsAwarded, 0);
    expect(s.levelUpRewards!.levelsGained, 1);

    notifier.dispose();
  });

  test(
      'XP grant that does NOT cross a threshold leaves leveledUp false and '
      'does not write celebration fields', () async {
    await hydrateXpCache(totalXp: 10);

    fakeSync.rpcHandlers['award_xp'] = (_) async => {
          'total_xp': 30,
          'token_balance': null,
          'scroll_balance': null,
        };

    final notifier = DailyLoopNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await notifier.debugHandleXpAward(20);

    expect(notifier.state.leveledUp, isFalse,
        reason: '30 XP is still below L2 threshold (75) — celebration must '
            'NOT trigger');
    expect(notifier.state.xpTotal, 30,
        reason: 'XP total still updates even without level-up');
    expect(notifier.state.newLevelTitle, isNull,
        reason: 'celebration title must remain null when no level crossed');

    notifier.dispose();
  });

  test(
      'clearLevelUp resets leveledUp to false (so the overlay can be '
      'dismissed without leaking celebration state into next grant)',
      () async {
    await hydrateXpCache(totalXp: 70);
    fakeSync.rpcHandlers['award_xp'] = (_) async => {
          'total_xp': 100,
          'token_balance': 5,
          'scroll_balance': null,
        };
    fakeSync.rpcHandlers['earn_tokens'] = (_) async => 5;

    final notifier = DailyLoopNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await notifier.debugHandleXpAward(30);
    expect(notifier.state.leveledUp, isTrue);

    notifier.clearLevelUp();
    expect(notifier.state.leveledUp, isFalse);

    notifier.dispose();
  });
}
