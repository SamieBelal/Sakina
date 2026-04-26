import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/launch_gate_state.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';

// ---------------------------------------------------------------------------
// Reward types
// ---------------------------------------------------------------------------

enum RewardType { tokens, streakFreeze, tierUpScroll }

/// Premium subscribers receive base token / scroll amounts multiplied by this
/// value. Streak freeze rewards are not multiplied (the slot remains binary).
const int premiumRewardMultiplier = 5;

class DayReward {
  final int day;
  final RewardType type;
  final int tokenAmount;
  final int scrollAmount;
  final String label;
  final String icon; // semantic icon name for UI

  const DayReward({
    required this.day,
    required this.type,
    this.tokenAmount = 0,
    this.scrollAmount = 0,
    required this.label,
    required this.icon,
  });
}

const List<DayReward> rewardSchedule = [
  DayReward(
      day: 1,
      type: RewardType.tokens,
      tokenAmount: 5,
      label: '5 Tokens',
      icon: 'token'),
  DayReward(
      day: 2,
      type: RewardType.tokens,
      tokenAmount: 10,
      label: '10 Tokens',
      icon: 'token'),
  DayReward(
      day: 3,
      type: RewardType.tokens,
      tokenAmount: 15,
      label: '15 Tokens',
      icon: 'token'),
  DayReward(
      day: 4,
      type: RewardType.streakFreeze,
      label: 'Streak Freeze',
      icon: 'freeze'),
  DayReward(
      day: 5,
      type: RewardType.tokens,
      tokenAmount: 20,
      label: '20 Tokens',
      icon: 'token'),
  DayReward(
      day: 6,
      type: RewardType.tierUpScroll,
      scrollAmount: 5,
      label: '5 Scrolls',
      icon: 'scroll'),
  DayReward(
      day: 7,
      type: RewardType.tokens,
      tokenAmount: 30,
      label: '30 Tokens',
      icon: 'token'),
];

/// Returns the reward for [day] (1-indexed) with token / scroll amounts and
/// label scaled for premium subscribers when [isPremium] is true. Streak
/// freeze rewards are returned unchanged because the underlying storage is a
/// single boolean — premium users receive the same one-freeze slot.
DayReward scaledRewardForDay(int day, {required bool isPremium}) {
  final base = rewardSchedule[day - 1];
  if (!isPremium) return base;
  switch (base.type) {
    case RewardType.tokens:
      final amount = base.tokenAmount * premiumRewardMultiplier;
      return DayReward(
        day: base.day,
        type: base.type,
        tokenAmount: amount,
        label: '$amount Tokens',
        icon: base.icon,
      );
    case RewardType.tierUpScroll:
      final amount = base.scrollAmount * premiumRewardMultiplier;
      return DayReward(
        day: base.day,
        type: base.type,
        scrollAmount: amount,
        label: '$amount Scrolls',
        icon: base.icon,
      );
    case RewardType.streakFreeze:
      return base;
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DailyRewardsState {
  /// 0 = no days claimed yet this cycle, 1-7 = last claimed day
  final int currentDay;

  /// ISO date (YYYY-MM-DD) of last claimed reward
  final String? lastClaimDate;

  /// Whether user owns an unused streak freeze
  final bool streakFreezeOwned;

  /// Whether today's reward has already been claimed
  final bool claimedToday;

  const DailyRewardsState({
    this.currentDay = 0,
    this.lastClaimDate,
    this.streakFreezeOwned = false,
    this.claimedToday = false,
  });

  DailyRewardsState copyWith({
    int? currentDay,
    String? lastClaimDate,
    bool? streakFreezeOwned,
    bool? claimedToday,
  }) {
    return DailyRewardsState(
      currentDay: currentDay ?? this.currentDay,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      streakFreezeOwned: streakFreezeOwned ?? this.streakFreezeOwned,
      claimedToday: claimedToday ?? this.claimedToday,
    );
  }

  /// The next day that will be claimed (1-7), or 1 if starting fresh
  int get nextClaimDay => currentDay >= 7 ? 1 : currentDay + 1;

  /// Get the reward for a given day (1-indexed)
  DayReward rewardForDay(int day) => rewardSchedule[day - 1];
}

// ---------------------------------------------------------------------------
// Claim result
// ---------------------------------------------------------------------------

class DailyRewardClaimResult {
  final int day;
  final int tokensAwarded;
  final int scrollsAwarded;
  final bool earnedStreakFreeze;
  final bool earnedTierUpScroll;
  final bool alreadyClaimed;
  final int? newTokenBalance;
  final int? newScrollBalance;

  /// Server-authoritative premium state at the moment of claim. Sourced from
  /// `has_active_premium_entitlement(auth.uid())` in the RPC, not from the
  /// client — so a tampered client can't fake the premium celebration.
  /// `null` when the result came from the offline fallback path.
  final bool? isPremium;

  /// Multiplier applied to the base reward amount. `1` for free users,
  /// `5` for premium. `null` on the offline fallback path.
  final int? multiplier;

  const DailyRewardClaimResult({
    required this.day,
    this.tokensAwarded = 0,
    this.scrollsAwarded = 0,
    this.earnedStreakFreeze = false,
    this.earnedTierUpScroll = false,
    this.alreadyClaimed = false,
    this.newTokenBalance,
    this.newScrollBalance,
    this.isPremium,
    this.multiplier,
  });
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

const String _rewardsKey = 'sakina_daily_rewards';

int _readRpcInt(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value is num) return value.toInt();
  return value as int;
}

Future<String?> _getCachedRewardsRaw(SharedPreferences prefs) async {
  return supabaseSyncService.migrateLegacyStringCache(prefs, _rewardsKey);
}

String _today() {
  final now = DateTime.now().toUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _yesterday() {
  final y = DateTime.now().toUtc().subtract(const Duration(days: 1));
  return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
}

Future<DailyRewardsState> getDailyRewards() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = await _getCachedRewardsRaw(prefs);

  if (raw == null) {
    return const DailyRewardsState();
  }

  final data = jsonDecode(raw) as Map<String, dynamic>;
  final lastClaim = data['lastClaimDate'] as String?;
  final currentDay = data['currentDay'] as int? ?? 0;
  final freezeOwned = data['streakFreezeOwned'] as bool? ?? false;

  final today = _today();
  final yesterday = _yesterday();

  // Check if calendar should reset
  if (lastClaim != null && lastClaim != today && lastClaim != yesterday) {
    // Missed more than a day — reset calendar (but keep freeze if owned)
    return DailyRewardsState(
      currentDay: 0,
      lastClaimDate: lastClaim,
      streakFreezeOwned: freezeOwned,
      claimedToday: false,
    );
  }

  return DailyRewardsState(
    currentDay: currentDay,
    lastClaimDate: lastClaim,
    streakFreezeOwned: freezeOwned,
    claimedToday: lastClaim == today,
  );
}

Future<void> _persist(DailyRewardsState state) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey(_rewardsKey),
    jsonEncode({
      'currentDay': state.currentDay,
      'lastClaimDate': state.lastClaimDate,
      'streakFreezeOwned': state.streakFreezeOwned,
    }),
  );
}

Future<void> prepareDailyRewardsCacheForHydration() async {
  await getDailyRewards();
}

/// Wipes the server-side `user_daily_rewards` row for the current user so a
/// dev/QA reset on Settings actually re-triggers the daily-launch overlay
/// across devices. Without this, "Reset Daily Loop" only clears local
/// SharedPrefs while the server still says "claimed today" — and the next
/// reconcile would re-hydrate the local cache from that stale server state.
///
/// No-op for unauthenticated users.
Future<void> resetDailyRewardsOnServer() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;
  // Intentionally does NOT touch `streak_freeze_owned` — that's paid /
  // earned inventory and a dev reset shouldn't wipe it.
  await supabaseSyncService.upsertRow(
    'user_daily_rewards',
    userId,
    {
      'current_day': 0,
      'last_claim_date': null,
    },
  );
}

/// Reads the canonical daily-rewards row from Supabase and writes it back to
/// the local SharedPrefs cache. Server is the source of truth — this fixes
/// the "DB reset doesn't re-trigger the launch overlay" bug (F1/F5 in
/// docs/qa/findings/2026-04-22-core-loop-fixes.md). Called from
/// shouldShowDailyLaunch() and DailyRewardsNotifier.reload() so the local
/// cache is always reconciled with what the server thinks before any UI
/// gate reads it.
///
/// Important: the launch gate is only reset when there is a clear conflict —
/// local cache previously thought the user had claimed today, but the
/// server now says otherwise. Without that check we'd clobber the gate on
/// every cold launch where the user merely dismissed the overlay without
/// claiming, re-triggering it every time. (Regression caught by
/// test/services/launch_gate_service_test.dart.)
///
/// No-op for unauthenticated users.
Future<void> reconcileDailyRewardsFromServer() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  // Read what the local cache currently thinks before fetching server,
  // so we can detect a real conflict.
  final localBefore = await getDailyRewards();

  final row = await supabaseSyncService.fetchRow(
    'user_daily_rewards',
    userId,
    columns: 'current_day,last_claim_date,streak_freeze_owned',
  );

  // No row on server. Clear the local rewards cache so the next read
  // returns a fresh state. Only reset the launch gate if the local cache
  // previously believed the user had claimed today — that's the genuine
  // "server got wiped while we still think we claimed" case.
  if (row == null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(supabaseSyncService.scopedKey(_rewardsKey));
    if (localBefore.claimedToday) {
      await resetDailyLaunchGate();
    }
    return;
  }

  final serverDay = row['current_day'] as int? ?? 0;
  final serverLastClaim = row['last_claim_date'] as String?;
  final serverFreeze = row['streak_freeze_owned'] as bool? ?? false;

  await _persist(
    DailyRewardsState(
      currentDay: serverDay,
      lastClaimDate: serverLastClaim,
      streakFreezeOwned: serverFreeze,
      claimedToday: serverLastClaim == _today(),
    ),
  );

  // Conflict: local thought today was claimed but server disagrees.
  // Reset the launch gate so the overlay can fire again on this cold
  // launch — admin reset, multi-device claim rollback, etc.
  if (localBefore.claimedToday && serverLastClaim != _today()) {
    await resetDailyLaunchGate();
  }
}

Future<void> hydrateDailyRewardsCache({
  required int currentDay,
  String? lastClaimDate,
  required bool streakFreezeOwned,
}) async {
  await _persist(
    DailyRewardsState(
      currentDay: currentDay,
      lastClaimDate: lastClaimDate,
      streakFreezeOwned: streakFreezeOwned,
      claimedToday: lastClaimDate == _today(),
    ),
  );
}

Future<void> grantStreakFreeze() async {
  final state = await getDailyRewards();
  final userId = supabaseSyncService.currentUserId;

  if (userId != null) {
    final ok = await supabaseSyncService.upsertRow(
      'user_daily_rewards',
      userId,
      {'streak_freeze_owned': true},
    );
    if (!ok) return; // Server failed — don't update local either
  }

  final newState = state.copyWith(streakFreezeOwned: true);
  await _persist(newState);
}

Future<DailyRewardClaimResult> claimDailyReward() async {
  var state = await getDailyRewards();
  final today = _today();
  final userId = supabaseSyncService.currentUserId;

  // For authenticated users, refresh from server to prevent cross-device
  // double-claims (Device A claims day 4, Device B still sees day 3).
  if (userId != null) {
    final row = await supabaseSyncService.fetchRow(
      'user_daily_rewards',
      userId,
      columns: 'current_day,last_claim_date,streak_freeze_owned',
    );
    if (row != null) {
      final serverDay = row['current_day'] as int? ?? state.currentDay;
      final serverLastClaim =
          row['last_claim_date'] as String? ?? state.lastClaimDate;
      final serverFreeze =
          row['streak_freeze_owned'] as bool? ?? state.streakFreezeOwned;

      // Apply the same calendar reset logic as getDailyRewards():
      // if lastClaimDate is older than yesterday, reset to day 0.
      final yesterday = _yesterday();
      final needsReset = serverLastClaim != null &&
          serverLastClaim != today &&
          serverLastClaim != yesterday;

      state = DailyRewardsState(
        currentDay: needsReset ? 0 : serverDay,
        lastClaimDate: serverLastClaim,
        streakFreezeOwned: serverFreeze,
        claimedToday: serverLastClaim == today,
      );
    }
  }

  // Already claimed today
  if (state.lastClaimDate == today && userId == null) {
    return DailyRewardClaimResult(
      day: state.currentDay,
      alreadyClaimed: true,
    );
  }

  if (userId != null) {
    final rpcResult = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'claim_daily_reward',
    );
    if (rpcResult == null) {
      return DailyRewardClaimResult(
          day: state.currentDay, alreadyClaimed: true);
    }

    final newState = DailyRewardsState(
      currentDay: rpcResult['current_day'] == null
          ? state.currentDay
          : _readRpcInt(rpcResult, 'current_day'),
      lastClaimDate: rpcResult['last_claim_date'] as String? ?? today,
      streakFreezeOwned:
          rpcResult['streak_freeze_owned'] as bool? ?? state.streakFreezeOwned,
      claimedToday: true,
    );

    final tokenValue = rpcResult['token_balance'];
    final scrollValue = rpcResult['scroll_balance'];
    final tokenBalance =
        tokenValue is num ? tokenValue.toInt() : tokenValue as int?;
    final scrollBalance =
        scrollValue is num ? scrollValue.toInt() : scrollValue as int?;

    await _persist(newState);
    if (tokenBalance != null) {
      await hydrateTokenCache(
        balance: tokenBalance,
        totalSpent: await getTotalTokensSpent(),
      );
    }
    if (scrollBalance != null) {
      await hydrateTierUpScrollCache(balance: scrollBalance);
    }

    return DailyRewardClaimResult(
      day: rpcResult['day'] == null
          ? newState.currentDay
          : _readRpcInt(rpcResult, 'day'),
      tokensAwarded: rpcResult['tokens_awarded'] == null
          ? 0
          : _readRpcInt(rpcResult, 'tokens_awarded'),
      scrollsAwarded: rpcResult['scrolls_awarded'] == null
          ? 0
          : _readRpcInt(rpcResult, 'scrolls_awarded'),
      earnedStreakFreeze: rpcResult['earned_streak_freeze'] as bool? ?? false,
      earnedTierUpScroll: rpcResult['earned_tier_up_scroll'] as bool? ?? false,
      alreadyClaimed: rpcResult['already_claimed'] as bool? ?? false,
      newTokenBalance: tokenBalance,
      newScrollBalance: scrollBalance,
      isPremium: rpcResult['is_premium'] as bool?,
      multiplier: rpcResult['multiplier'] == null
          ? null
          : _readRpcInt(rpcResult, 'multiplier'),
    );
  }

  final nextDay = state.nextClaimDay;
  final reward = rewardSchedule[nextDay - 1];
  var newState = DailyRewardsState(
    currentDay: nextDay,
    lastClaimDate: today,
    streakFreezeOwned: state.streakFreezeOwned,
    claimedToday: true,
  );

  bool earnedFreeze = false;
  bool earnedScroll = false;

  switch (reward.type) {
    case RewardType.streakFreeze:
      newState = newState.copyWith(streakFreezeOwned: true);
      earnedFreeze = true;
      break;
    case RewardType.tierUpScroll:
      earnedScroll = true;
      break;
    case RewardType.tokens:
      break;
  }

  final currentTokens = await getTokens();
  final currentScrolls = await getTierUpScrolls();
  final newTokenBalance = currentTokens.balance + reward.tokenAmount;
  final newScrollBalance = currentScrolls.balance + reward.scrollAmount;

  await _persist(newState);
  await hydrateTokenCache(
    balance: newTokenBalance,
    totalSpent: await getTotalTokensSpent(),
  );
  await hydrateTierUpScrollCache(balance: newScrollBalance);

  return DailyRewardClaimResult(
    day: nextDay,
    tokensAwarded: reward.tokenAmount,
    scrollsAwarded: reward.scrollAmount,
    earnedStreakFreeze: earnedFreeze,
    earnedTierUpScroll: earnedScroll,
    newTokenBalance: newTokenBalance,
    newScrollBalance: newScrollBalance,
  );
}

Future<bool> consumeStreakFreeze() async {
  final state = await getDailyRewards();
  final userId = supabaseSyncService.currentUserId;

  if (userId != null) {
    final consumed = await supabaseSyncService.callRpc<bool>(
      'consume_streak_freeze',
    );
    if (consumed != true) return false;

    final newState = state.copyWith(streakFreezeOwned: false);
    await _persist(newState);
    return true;
  }

  if (!state.streakFreezeOwned) return false;

  final newState = state.copyWith(streakFreezeOwned: false);
  await _persist(newState);
  return true;
}
