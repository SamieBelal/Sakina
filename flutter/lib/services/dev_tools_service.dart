import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

// ---------------------------------------------------------------------------
// Tokens & Scrolls
// ---------------------------------------------------------------------------
// Both live in the `user_tokens` table (`balance` and `tier_up_scrolls`
// columns). They must be set together to avoid one upsert clobbering the
// other.

/// Set token balance without touching scrolls.
Future<void> devSetTokens(int amount) async {
  await hydrateTokenCache(balance: amount, totalSpent: 0);
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    // Read current scrolls so the upsert doesn't reset them.
    final currentScrolls = await getTierUpScrolls();
    await supabaseSyncService.upsertRow('user_tokens', userId, {
      'balance': amount,
      'tier_up_scrolls': currentScrolls.balance,
    });
  }
}

/// Set scroll balance without touching tokens.
Future<void> devSetScrolls(int amount) async {
  await hydrateTierUpScrollCache(balance: amount);
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    // Read current tokens so the upsert doesn't reset them.
    final currentTokens = await getTokens();
    await supabaseSyncService.upsertRow('user_tokens', userId, {
      'balance': currentTokens.balance,
      'tier_up_scrolls': amount,
    });
  }
}

/// Set both tokens and scrolls atomically.
Future<void> devSetTokensAndScrolls(int tokens, int scrolls) async {
  await hydrateTokenCache(balance: tokens, totalSpent: 0);
  await hydrateTierUpScrollCache(balance: scrolls);
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_tokens', userId, {
      'balance': tokens,
      'tier_up_scrolls': scrolls,
    });
  }
}

// ---------------------------------------------------------------------------
// XP
// ---------------------------------------------------------------------------

Future<void> devSetXp(int totalXp) async {
  await hydrateXpCache(totalXp: totalXp);
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_xp', userId, {
      'total_xp': totalXp,
    });
  }
}

// ---------------------------------------------------------------------------
// Streak
// ---------------------------------------------------------------------------

String _todayString() {
  final now = DateTime.now().toUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

Future<void> devSetStreak(int current, int longest) async {
  final today = _todayString();
  await hydrateStreakCache(
    currentStreak: current,
    longestStreak: longest,
    lastActive: current > 0 ? today : null,
  );
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': current,
      'longest_streak': longest,
      'last_active': current > 0 ? today : null,
    });
  }
}

// ---------------------------------------------------------------------------
// Daily Rewards
// ---------------------------------------------------------------------------

String _yesterdayString() {
  final y = DateTime.now().toUtc().subtract(const Duration(days: 1));
  return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
}

Future<void> devResetDailyRewards() async {
  await hydrateDailyRewardsCache(
    currentDay: 0,
    lastClaimDate: null,
    streakFreezeOwned: false,
  );
}

Future<void> devAdvanceDailyRewardDay(int day) async {
  await hydrateDailyRewardsCache(
    currentDay: day,
    lastClaimDate: _yesterdayString(),
    streakFreezeOwned: false,
  );
}

// ---------------------------------------------------------------------------
// Achievements
// ---------------------------------------------------------------------------

Future<void> devResetAchievements() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey('sakina_achievements_unlocked'),
    jsonEncode([]),
  );
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.deleteRow('user_achievements', 'user_id', userId);
  }
}

Future<void> devUnlockAllAchievements() async {
  final ids = allAchievements.map((a) => a.id).toList();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    supabaseSyncService.scopedKey('sakina_achievements_unlocked'),
    jsonEncode(ids),
  );
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.batchInsertRows(
      'user_achievements',
      ids.map((id) => {'user_id': userId, 'achievement_id': id}).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Quests
// ---------------------------------------------------------------------------

Future<void> devResetQuestProgress() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = [
    'quests_completed_v2',
    'quests_progress_v2',
  ];
  for (final key in keys) {
    await prefs.remove(supabaseSyncService.scopedKey(key));
  }
}

Future<void> devResetFirstSteps() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = [
    'first_steps_completed_v1',
    'first_steps_bundle_claimed_v1',
  ];
  for (final key in keys) {
    await prefs.remove(supabaseSyncService.scopedKey(key));
  }
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.deleteRow(
      'user_quest_progress',
      'user_id',
      userId,
    );
  }
}

// ---------------------------------------------------------------------------
// Soft Reset (everything except auth/onboarding)
// ---------------------------------------------------------------------------

Future<void> devSoftResetAll() async {
  await devSetTokensAndScrolls(startingTokens, 0);
  await devSetXp(0);
  await devSetStreak(0, 0);
  await devResetDailyRewards();
  await devResetAchievements();
  await devResetQuestProgress();
  await devResetFirstSteps();
  await clearCardCollection();
  await resetDailyLaunchGate();
}

// ---------------------------------------------------------------------------
// Re-hydrate from Supabase
// ---------------------------------------------------------------------------

Future<void> devRehydrateFromSupabase() async {
  await hydrateUserDataFromBatchRpc();
}
