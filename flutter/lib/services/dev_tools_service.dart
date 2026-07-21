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
  await clearLapseCache();
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': current,
      'longest_streak': longest,
      'last_active': current > 0 ? today : null,
      'pre_lapse_streak': null,
      'lapsed_at': null,
    });
  }
}

String _daysAgoString(int daysAgo) {
  final d = DateTime.now().toUtc().subtract(Duration(days: daysAgo));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Dev: put the streak into a state with `last_active` set [daysAgo] days back
/// (and no pending lapse), so the NEXT muḥāsabah completion exercises the
/// repair ladder. daysAgo=2 → one missed day, within 48h → free repair.
/// daysAgo=4 → past the window → EXPIRED → the paid rescue sheet.
Future<void> devSetStreakGap(int current, int longest, int daysAgo) async {
  final past = _daysAgoString(daysAgo);
  await hydrateStreakCache(
    currentStreak: current,
    longestStreak: longest,
    lastActive: past,
  );
  await clearLapseCache();
  // Clear any owned freeze so an EXPIRED test isn't silently bridged by it.
  await consumeStreakFreeze();
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': current,
      'longest_streak': longest,
      'last_active': past,
      'pre_lapse_streak': null,
      'lapsed_at': null,
    });
  }
}

/// Dev: set a 1-day gap (last_active 2 days ago) AND excuse yesterday, so the
/// next muḥāsabah should CONTINUE the streak (the only gap day is excused).
Future<void> devExcuseYesterdayGap(int current, int longest) async {
  await devSetStreakGap(current, longest, 2);
  await addExcusedDate(DateTime.now().toUtc().subtract(const Duration(days: 1)));
}

/// Dev (companion visual QA): streak ≥1 but NOT reflected today (last_active =
/// yesterday), so `resolveCompanionState` returns the UNLIT "waiting" lamp —
/// `pendingUnlit` before 8pm local, `atRiskUnlit` after. Both render the same
/// dark-glass / warm-housing lamp; the split is copy/cue only, driven by the
/// real clock. Does NOT arm a lapse (last_active is only 1 day back), so viewing
/// Home won't trigger the rescue sheet.
Future<void> devSetStreakUnlit(int current) async {
  final past = _daysAgoString(1);
  await hydrateStreakCache(
    currentStreak: current,
    longestStreak: current,
    lastActive: past,
  );
  await clearLapseCache();
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': current,
      'longest_streak': current,
      'last_active': past,
      'pre_lapse_streak': null,
      'lapsed_at': null,
    });
  }
}

/// Dev (companion visual QA): streak at 0 but WITH history (longest > 0), so
/// `resolveCompanionState` returns DORMANT (the cold, snuffed "resting" lamp) —
/// distinct from the endowed new-user lamp (which needs longest == 0). No pending
/// lapse is armed.
Future<void> devSetDormant() async {
  final past = _daysAgoString(5);
  await hydrateStreakCache(
    currentStreak: 0,
    longestStreak: 30,
    lastActive: past,
  );
  await clearLapseCache();
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': 0,
      'longest_streak': 30,
      'last_active': past,
      'pre_lapse_streak': null,
      'lapsed_at': null,
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
    // Clear existing rows first so the insert doesn't conflict on the
    // (user_id, achievement_id) unique constraint when run repeatedly or
    // when the user already has some unlocks.
    await supabaseSyncService.deleteRow('user_achievements', 'user_id', userId);
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
