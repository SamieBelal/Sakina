import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

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

  const DailyRewardClaimResult({
    required this.day,
    this.tokensAwarded = 0,
    this.scrollsAwarded = 0,
    this.earnedStreakFreeze = false,
    this.earnedTierUpScroll = false,
    this.alreadyClaimed = false,
  });
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

const String _rewardsKey = 'sakina_daily_rewards';

Future<String?> _getCachedRewardsRaw(SharedPreferences prefs) async {
  return supabaseSyncService.migrateLegacyStringCache(prefs, _rewardsKey);
}

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _yesterday() {
  final y = DateTime.now().subtract(const Duration(days: 1));
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

Future<DailyRewardClaimResult> claimDailyReward({
  bool isPremium = false,
}) async {
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
  if (state.lastClaimDate == today) {
    return DailyRewardClaimResult(
      day: state.currentDay,
      alreadyClaimed: true,
    );
  }

  // Determine next day. Token / scroll amounts are scaled here so the result
  // returned to callers already reflects the user's premium status.
  final nextDay = state.nextClaimDay;
  final reward = scaledRewardForDay(nextDay, isPremium: isPremium);

  // Build new state
  var newState = DailyRewardsState(
    currentDay: nextDay,
    lastClaimDate: today,
    streakFreezeOwned: state.streakFreezeOwned,
    claimedToday: true,
  );

  // Apply reward-specific state changes
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

  // Persist to server first — if that fails, don't update local cache
  if (userId != null) {
    final ok = await supabaseSyncService.upsertRow(
      'user_daily_rewards',
      userId,
      {
        'current_day': newState.currentDay,
        'last_claim_date': today,
        'streak_freeze_owned': newState.streakFreezeOwned,
      },
    );
    if (!ok) {
      return DailyRewardClaimResult(
          day: state.currentDay, alreadyClaimed: true);
    }
  }

  await _persist(newState);
  // No separate grantStreakFreeze() call needed here — the server upsert above
  // already includes streak_freeze_owned, and newState has it set locally.

  return DailyRewardClaimResult(
    day: nextDay,
    tokensAwarded: reward.tokenAmount,
    scrollsAwarded: reward.scrollAmount,
    earnedStreakFreeze: earnedFreeze,
    earnedTierUpScroll: earnedScroll,
  );
}

Future<bool> consumeStreakFreeze() async {
  final state = await getDailyRewards();
  final userId = supabaseSyncService.currentUserId;

  if (userId != null) {
    final row = await supabaseSyncService.fetchRow(
      'user_daily_rewards',
      userId,
      columns: 'streak_freeze_owned',
    );
    final hasFreeze =
        row?['streak_freeze_owned'] as bool? ?? state.streakFreezeOwned;
    if (!hasFreeze) return false;

    final ok = await supabaseSyncService.upsertRow(
      'user_daily_rewards',
      userId,
      {'streak_freeze_owned': false},
    );
    if (!ok) return false; // Server failed — don't consume locally

    final newState = state.copyWith(streakFreezeOwned: false);
    await _persist(newState);
    return true;
  }

  if (!state.streakFreezeOwned) return false;

  final newState = state.copyWith(streakFreezeOwned: false);
  await _persist(newState);
  return true;
}
