import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('hydrateDailyRewardsCache writes freeze ownership', () async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    SharedPreferences.setMockInitialValues({
      'sakina_daily_rewards': jsonEncode({
        'currentDay': 3,
        'lastClaimDate': todayStr,
        'streakFreezeOwned': false,
      }),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await prepareDailyRewardsCacheForHydration();
    await hydrateDailyRewardsCache(
      currentDay: 3,
      lastClaimDate: todayStr,
      streakFreezeOwned: true,
    );

    final state = await getDailyRewards();
    expect(state.currentDay, 3);
    expect(state.streakFreezeOwned, isTrue);
  });

  test('grantStreakFreeze updates local cache and remote row', () async {
    await grantStreakFreeze();

    final state = await getDailyRewards();
    expect(state.streakFreezeOwned, isTrue);
    expect(fakeSync.rows['user_daily_rewards:user-1']?['streak_freeze_owned'],
        isTrue);
  });

  test('consumeStreakFreeze clears remote-backed freeze via RPC', () async {
    // The consume_streak_freeze RPC returns true when a freeze was consumed.
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => true;

    final consumed = await consumeStreakFreeze();

    expect(consumed, isTrue);
    expect((await getDailyRewards()).streakFreezeOwned, isFalse);
    expect(
      fakeSync.rpcCalls.where((c) => c['fn'] == 'consume_streak_freeze'),
      hasLength(1),
    );
  });

  test('consumeStreakFreeze returns false when RPC says none owned', () async {
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

    final consumed = await consumeStreakFreeze();

    expect(consumed, isFalse);
  });

  // ───────────────────────────────────────────────────────────────────────
  // Server-authoritative premium multiplier (closes M8).
  //
  // Client NEVER passes isPremium to the RPC. Server reads
  // has_active_premium_entitlement(auth.uid()) and scales the reward.
  // These tests lock in that the client correctly surfaces whatever the
  // server returns, so a modified client cannot force a 5x claim.
  // ───────────────────────────────────────────────────────────────────────

  test('claimDailyReward surfaces base amount (multiplier=1) for free users',
      () async {
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'day': 1,
          'tokens_awarded': 5,
          'scrolls_awarded': 0,
          'earned_streak_freeze': false,
          'earned_tier_up_scroll': false,
          'already_claimed': false,
          'current_day': 1,
          'last_claim_date': '2026-04-17',
          'streak_freeze_owned': false,
          'token_balance': 5,
          'scroll_balance': 0,
          'is_premium': false,
          'multiplier': 1,
        };

    final result = await claimDailyReward();

    expect(result.tokensAwarded, 5);
    expect(result.scrollsAwarded, 0);
    expect(result.newTokenBalance, 5);
    expect(result.isPremium, isFalse);
    expect(result.multiplier, 1);
  });

  test('claimDailyReward surfaces 5x amount (multiplier=5) for premium users',
      () async {
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'day': 1,
          'tokens_awarded': 25, // 5 base × 5 premium multiplier
          'scrolls_awarded': 0,
          'earned_streak_freeze': false,
          'earned_tier_up_scroll': false,
          'already_claimed': false,
          'current_day': 1,
          'last_claim_date': '2026-04-17',
          'streak_freeze_owned': false,
          'token_balance': 25,
          'scroll_balance': 0,
          'is_premium': true,
          'multiplier': 5,
        };

    final result = await claimDailyReward();

    expect(result.tokensAwarded, 25);
    expect(result.newTokenBalance, 25);
    expect(result.isPremium, isTrue);
    expect(result.multiplier, 5);
  });

  test(
      'claimDailyReward surfaces 5x scroll amount on scroll day for premium users',
      () async {
    fakeSync.rpcHandlers['claim_daily_reward'] = (_) async => {
          'day': 6,
          'tokens_awarded': 0,
          'scrolls_awarded': 25, // 5 base × 5 premium multiplier
          'earned_streak_freeze': false,
          'earned_tier_up_scroll': true,
          'already_claimed': false,
          'current_day': 6,
          'last_claim_date': '2026-04-17',
          'streak_freeze_owned': false,
          'token_balance': 0,
          'scroll_balance': 25,
          'is_premium': true,
          'multiplier': 5,
        };

    final result = await claimDailyReward();

    expect(result.scrollsAwarded, 25);
    expect(result.earnedTierUpScroll, isTrue);
    expect(result.newScrollBalance, 25);
  });

  test(
      'claimDailyReward never sends isPremium to the RPC (server is authoritative)',
      () async {
    fakeSync.rpcHandlers['claim_daily_reward'] = (params) async {
      // If the client ever started passing isPremium, this assertion would
      // catch the regression. The whole point of M8 is that the server
      // decides, not the client.
      expect(params ?? const <String, dynamic>{}, isEmpty);
      return {
        'day': 1,
        'tokens_awarded': 5,
        'scrolls_awarded': 0,
        'earned_streak_freeze': false,
        'earned_tier_up_scroll': false,
        'already_claimed': false,
        'current_day': 1,
        'last_claim_date': '2026-04-17',
        'streak_freeze_owned': false,
        'token_balance': 5,
        'scroll_balance': 0,
      };
    };

    await claimDailyReward();

    expect(
      fakeSync.rpcCalls.where((c) => c['fn'] == 'claim_daily_reward'),
      hasLength(1),
    );
  });
}
