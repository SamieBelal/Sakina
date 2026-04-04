import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Reward types
// ---------------------------------------------------------------------------

enum RewardType { tokens, streakFreeze, guaranteedTierUp, tokensPlusTitle }

class DayReward {
  final int day;
  final RewardType type;
  final int tokenAmount;
  final String label;
  final String icon; // semantic icon name for UI

  const DayReward({
    required this.day,
    required this.type,
    this.tokenAmount = 0,
    required this.label,
    required this.icon,
  });
}

const List<DayReward> rewardSchedule = [
  DayReward(day: 1, type: RewardType.tokens, tokenAmount: 2, label: '2 Tokens', icon: 'token'),
  DayReward(day: 2, type: RewardType.tokens, tokenAmount: 3, label: '3 Tokens', icon: 'token'),
  DayReward(day: 3, type: RewardType.tokens, tokenAmount: 4, label: '4 Tokens', icon: 'token'),
  DayReward(day: 4, type: RewardType.streakFreeze, label: 'Streak Freeze', icon: 'freeze'),
  DayReward(day: 5, type: RewardType.tokens, tokenAmount: 5, label: '5 Tokens', icon: 'token'),
  DayReward(day: 6, type: RewardType.guaranteedTierUp, label: 'Tier Up', icon: 'card'),
  DayReward(day: 7, type: RewardType.tokensPlusTitle, tokenAmount: 8, label: '8 + Title', icon: 'star'),
];

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

  /// Next check-in will force a Rare+ card
  final bool guaranteedTierUpFlag;

  /// Whether today's reward has already been claimed
  final bool claimedToday;

  const DailyRewardsState({
    this.currentDay = 0,
    this.lastClaimDate,
    this.streakFreezeOwned = false,
    this.guaranteedTierUpFlag = false,
    this.claimedToday = false,
  });

  DailyRewardsState copyWith({
    int? currentDay,
    String? lastClaimDate,
    bool? streakFreezeOwned,
    bool? guaranteedTierUpFlag,
    bool? claimedToday,
  }) {
    return DailyRewardsState(
      currentDay: currentDay ?? this.currentDay,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      streakFreezeOwned: streakFreezeOwned ?? this.streakFreezeOwned,
      guaranteedTierUpFlag: guaranteedTierUpFlag ?? this.guaranteedTierUpFlag,
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
  final bool earnedStreakFreeze;
  final bool earnedGuaranteedRare;
  final bool earnedProfileTitle;
  final bool alreadyClaimed;

  const DailyRewardClaimResult({
    required this.day,
    this.tokensAwarded = 0,
    this.earnedStreakFreeze = false,
    this.earnedGuaranteedRare = false,
    this.earnedProfileTitle = false,
    this.alreadyClaimed = false,
  });
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

const String _rewardsKey = 'sakina_daily_rewards';

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
  final raw = prefs.getString(_rewardsKey);

  if (raw == null) {
    return const DailyRewardsState();
  }

  final data = jsonDecode(raw) as Map<String, dynamic>;
  final lastClaim = data['lastClaimDate'] as String?;
  final currentDay = data['currentDay'] as int? ?? 0;
  final freezeOwned = data['streakFreezeOwned'] as bool? ?? false;
  final rareFlag = data['guaranteedTierUpFlag'] as bool? ?? false;

  final today = _today();
  final yesterday = _yesterday();

  // Check if calendar should reset
  if (lastClaim != null && lastClaim != today && lastClaim != yesterday) {
    // Missed more than a day — reset calendar (but keep freeze/rare if owned)
    return DailyRewardsState(
      currentDay: 0,
      lastClaimDate: lastClaim,
      streakFreezeOwned: freezeOwned,
      guaranteedTierUpFlag: rareFlag,
      claimedToday: false,
    );
  }

  return DailyRewardsState(
    currentDay: currentDay,
    lastClaimDate: lastClaim,
    streakFreezeOwned: freezeOwned,
    guaranteedTierUpFlag: rareFlag,
    claimedToday: lastClaim == today,
  );
}

Future<void> _persist(DailyRewardsState state) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _rewardsKey,
    jsonEncode({
      'currentDay': state.currentDay,
      'lastClaimDate': state.lastClaimDate,
      'streakFreezeOwned': state.streakFreezeOwned,
      'guaranteedTierUpFlag': state.guaranteedTierUpFlag,
    }),
  );
}

Future<DailyRewardClaimResult> claimDailyReward() async {
  final state = await getDailyRewards();
  final today = _today();

  // Already claimed today
  if (state.lastClaimDate == today) {
    return DailyRewardClaimResult(
      day: state.currentDay,
      alreadyClaimed: true,
    );
  }

  // Determine next day
  final nextDay = state.nextClaimDay;
  final reward = rewardSchedule[nextDay - 1];

  // Build new state
  var newState = DailyRewardsState(
    currentDay: nextDay,
    lastClaimDate: today,
    streakFreezeOwned: state.streakFreezeOwned,
    guaranteedTierUpFlag: state.guaranteedTierUpFlag,
    claimedToday: true,
  );

  // Apply reward-specific state changes
  bool earnedFreeze = false;
  bool earnedRare = false;
  bool earnedTitle = false;

  switch (reward.type) {
    case RewardType.streakFreeze:
      newState = newState.copyWith(streakFreezeOwned: true);
      earnedFreeze = true;
      break;
    case RewardType.guaranteedTierUp:
      newState = newState.copyWith(guaranteedTierUpFlag: true);
      earnedRare = true;
      break;
    case RewardType.tokensPlusTitle:
      earnedTitle = true;
      break;
    case RewardType.tokens:
      break;
  }

  await _persist(newState);

  return DailyRewardClaimResult(
    day: nextDay,
    tokensAwarded: reward.tokenAmount,
    earnedStreakFreeze: earnedFreeze,
    earnedGuaranteedRare: earnedRare,
    earnedProfileTitle: earnedTitle,
  );
}

Future<bool> consumeStreakFreeze() async {
  final state = await getDailyRewards();
  if (!state.streakFreezeOwned) return false;

  final newState = state.copyWith(streakFreezeOwned: false);
  await _persist(newState);
  return true;
}

Future<void> clearGuaranteedTierUp() async {
  final state = await getDailyRewards();
  if (!state.guaranteedTierUpFlag) return;

  final newState = state.copyWith(guaranteedTierUpFlag: false);
  await _persist(newState);
}
