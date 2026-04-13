import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

// ---------------------------------------------------------------------------
// Achievement definition
// ---------------------------------------------------------------------------

enum AchievementCategory { collection, reflection, dua, streak, growth }

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final Color color;
  final int scrollReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.color,
    this.scrollReward = 0,
  });
}

// ---------------------------------------------------------------------------
// 25 Achievements
// ---------------------------------------------------------------------------

const allAchievements = <Achievement>[
  // ── Collection (6) ─────────────────────────────────────────────────────────

  Achievement(
    id: 'first_name',
    title: 'First Encounter',
    description: 'Discover your first Name of Allah.',
    icon: Icons.spa_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFF1B6B4A),
    scrollReward: 1,
  ),
  Achievement(
    id: 'bronze_10',
    title: 'Seeker of Names',
    description: 'Discover 10 Names of Allah.',
    icon: Icons.grid_view_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFCD7F32),
    scrollReward: 2,
  ),
  Achievement(
    id: 'bronze_all',
    title: 'The 99',
    description: 'Discover all 99 Names of Allah.',
    icon: Icons.stars_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFCD7F32),
    scrollReward: 10,
  ),
  Achievement(
    id: 'silver_10',
    title: 'Silver Scholar',
    description: 'Unlock Silver tier on 10 Names.',
    icon: Icons.military_tech_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFC0C0C0),
    scrollReward: 3,
  ),
  Achievement(
    id: 'gold_first',
    title: 'Golden Light',
    description: 'Unlock Gold tier on your first Name.',
    icon: Icons.emoji_events_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFD4A44C),
    scrollReward: 2,
  ),
  Achievement(
    id: 'gold_all',
    title: 'Master of the Names',
    description: 'Unlock Gold tier on all 99 Names.',
    icon: Icons.workspace_premium_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFD4A44C),
    scrollReward: 15,
  ),

  // ── Reflection (5) ─────────────────────────────────────────────────────────

  Achievement(
    id: 'reflect_first',
    title: 'First Reflection',
    description: 'Complete your first Reflect session.',
    icon: Icons.auto_stories_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF1B6B4A),
    scrollReward: 1,
  ),
  Achievement(
    id: 'reflect_10',
    title: 'Deep Thinker',
    description: 'Complete 10 Reflect sessions.',
    icon: Icons.auto_stories_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF1B6B4A),
    scrollReward: 2,
  ),
  Achievement(
    id: 'reflect_50',
    title: 'Heart of a Muhasib',
    description: 'Complete 50 Reflect sessions.',
    icon: Icons.favorite_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF1B6B4A),
    scrollReward: 5,
  ),
  Achievement(
    id: 'emotions_all',
    title: 'Full Spectrum',
    description: 'Check in with all 6 emotional states.',
    icon: Icons.palette_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF6B4E9B),
    scrollReward: 3,
  ),
  Achievement(
    id: 'unique_names_10',
    title: 'Many Facets',
    description: 'Receive 10 different Names across your reflections.',
    icon: Icons.auto_awesome,
    category: AchievementCategory.reflection,
    color: Color(0xFFC8985E),
    scrollReward: 2,
  ),

  // ── Dua (4) ────────────────────────────────────────────────────────────────

  Achievement(
    id: 'dua_first',
    title: 'First Supplication',
    description: 'Build your first personal dua.',
    icon: Icons.auto_awesome,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 1,
  ),
  Achievement(
    id: 'dua_10',
    title: 'Dua Maker',
    description: 'Build 10 personal duas.',
    icon: Icons.auto_awesome,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 2,
  ),
  Achievement(
    id: 'dua_50',
    title: 'Whisperer to Allah',
    description: 'Build 50 personal duas.',
    icon: Icons.brightness_3_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 5,
  ),
  Achievement(
    id: 'dua_100',
    title: 'Devoted Caller',
    description: 'Build 100 personal duas.',
    icon: Icons.all_inclusive_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 8,
  ),

  // ── Names Invoked (4) ──────────────────────────────────────────────────────

  Achievement(
    id: 'invoked_1',
    title: 'First Call',
    description: 'Call upon a Name of Allah in a dua.',
    icon: Icons.record_voice_over_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 1,
  ),
  Achievement(
    id: 'invoked_10',
    title: 'Ten Names Invoked',
    description: 'Call upon 10 different Names of Allah in your duas.',
    icon: Icons.record_voice_over_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 2,
  ),
  Achievement(
    id: 'invoked_50',
    title: 'Half the Names',
    description: 'Call upon 50 different Names of Allah in your duas.',
    icon: Icons.record_voice_over_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
    scrollReward: 5,
  ),
  Achievement(
    id: 'invoked_99',
    title: 'All 99 Invoked',
    description: 'Call upon all 99 Names of Allah in your duas.',
    icon: Icons.record_voice_over_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFD4A44C),
    scrollReward: 15,
  ),

  // ── Streak (5) ─────────────────────────────────────────────────────────────

  Achievement(
    id: 'streak_7',
    title: 'One Week Strong',
    description: 'Maintain a 7-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 1,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Month of Devotion',
    description: 'Maintain a 30-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 3,
  ),
  Achievement(
    id: 'streak_100',
    title: 'Century of Faith',
    description: 'Maintain a 100-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 5,
  ),
  Achievement(
    id: 'streak_365',
    title: 'Year of Remembrance',
    description: 'Maintain a 365-day streak.',
    icon: Icons.whatshot_rounded,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 10,
  ),
  Achievement(
    id: 'comeback',
    title: 'The Return',
    description: 'Come back after a broken streak and start again.',
    icon: Icons.replay_rounded,
    category: AchievementCategory.streak,
    color: Color(0xFF1B6B4A),
    scrollReward: 1,
  ),

  // ── Growth & Levels ─────────────────────────────────────────────────────────

  Achievement(
    id: 'level_5',
    title: 'Grateful',
    description: 'Reach Level 5 — Grateful.',
    icon: Icons.trending_up_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
    scrollReward: 1,
  ),
  Achievement(
    id: 'level_10',
    title: 'Humble',
    description: 'Reach Level 10 — Humble.',
    icon: Icons.trending_up_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
    scrollReward: 2,
  ),
  Achievement(
    id: 'level_15',
    title: 'Contented',
    description: 'Reach Level 15 — Contented.',
    icon: Icons.trending_up_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
    scrollReward: 3,
  ),
  Achievement(
    id: 'level_20',
    title: 'Beloved',
    description: 'Reach Level 20 — Beloved.',
    icon: Icons.trending_up_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFFD4A44C),
    scrollReward: 5,
  ),
  Achievement(
    id: 'level_25',
    title: 'Friend of Allah',
    description: 'Reach Level 25 — the highest rank.',
    icon: Icons.workspace_premium_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFFD4A44C),
    scrollReward: 10,
  ),
  Achievement(
    id: 'journal_25',
    title: 'Faithful Scribe',
    description: 'Save 25 entries to your Journal.',
    icon: Icons.bookmark_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF6B4E9B),
    scrollReward: 2,
  ),
  Achievement(
    id: 'all_quests_day',
    title: 'Perfect Day',
    description: 'Complete all daily quests in a single day.',
    icon: Icons.check_circle_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
    scrollReward: 2,
  ),

  // ── Scrolls & Upgrading ───────────────────────────────────────────────────

  Achievement(
    id: 'first_upgrade',
    title: 'First Upgrade',
    description: 'Use a Tier Up Scroll for the first time.',
    icon: Icons.receipt_long,
    category: AchievementCategory.collection,
    color: Color(0xFF3B82F6),
    scrollReward: 1,
  ),
  Achievement(
    id: 'silver_5',
    title: 'Silver Collector',
    description: 'Own 5 Silver cards.',
    icon: Icons.military_tech_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFC0C0C0),
    scrollReward: 2,
  ),
  Achievement(
    id: 'gold_5',
    title: 'Gold Collector',
    description: 'Own 5 Gold cards.',
    icon: Icons.emoji_events_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFD4A44C),
    scrollReward: 3,
  ),
  Achievement(
    id: 'complete_set',
    title: 'Complete Set',
    description: 'Own bronze, silver, and gold of the same Name.',
    icon: Icons.collections_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFC8985E),
    scrollReward: 3,
  ),

  // ── Titles ────────────────────────────────────────────────────────────────

  Achievement(
    id: 'custom_title',
    title: 'Identity',
    description: 'Select a custom title for the first time.',
    icon: Icons.badge_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF6B4E9B),
    scrollReward: 1,
  ),
  Achievement(
    id: 'titles_5',
    title: 'Title Collector',
    description: 'Unlock 5 titles.',
    icon: Icons.badge_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF6B4E9B),
    scrollReward: 3,
  ),

  // ── Quests ────────────────────────────────────────────────────────────────

  Achievement(
    id: 'weekly_quest',
    title: 'Weekly Warrior',
    description: 'Complete a weekly quest.',
    icon: Icons.emoji_events_outlined,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
    scrollReward: 2,
  ),
  Achievement(
    id: 'monthly_quest',
    title: 'Monthly Master',
    description: 'Complete a monthly quest.',
    icon: Icons.emoji_events_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFFD4A44C),
    scrollReward: 3,
  ),

  // ── Extended Streaks ──────────────────────────────────────────────────────

  Achievement(
    id: 'streak_14',
    title: 'Two Weeks Strong',
    description: 'Maintain a 14-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 1,
  ),
  Achievement(
    id: 'streak_60',
    title: 'Sixty Days of Light',
    description: 'Maintain a 60-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 3,
  ),
  Achievement(
    id: 'streak_180',
    title: 'Half a Year',
    description: 'Maintain a 180-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
    scrollReward: 5,
  ),

  // ── Spending ──────────────────────────────────────────────────────────────

  Achievement(
    id: 'tokens_spent_100',
    title: 'Generous Spender',
    description: 'Spend 100 tokens.',
    icon: Icons.toll,
    category: AchievementCategory.growth,
    color: Color(0xFFC8985E),
    scrollReward: 2,
  ),
  Achievement(
    id: 'tokens_spent_500',
    title: 'Big Spender',
    description: 'Spend 500 tokens.',
    icon: Icons.toll,
    category: AchievementCategory.growth,
    color: Color(0xFFC8985E),
    scrollReward: 5,
  ),
];

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

const _achievementsKey = 'sakina_achievements_unlocked';

Future<Set<String>> getUnlockedAchievements() async {
  final raw = await migrateAchievementsCacheForHydration();
  if (raw == null) return {};
  try {
    return (jsonDecode(raw) as List).cast<String>().toSet();
  } catch (_) {
    return {};
  }
}

Future<String?> migrateAchievementsCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  return supabaseSyncService.migrateLegacyStringCache(prefs, _achievementsKey);
}

Future<void> hydrateAchievementsCacheFromRows(
  List<Map<String, dynamic>> rows,
) async {
  final prefs = await SharedPreferences.getInstance();
  final ids = rows
      .map((row) => row['achievement_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();
  await prefs.setString(
    supabaseSyncService.scopedKey(_achievementsKey),
    jsonEncode(ids),
  );
}

Future<void> seedAchievementsToSupabaseFromLocalCache() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final localIds = await getUnlockedAchievements();
  if (localIds.isEmpty) return;

  await supabaseSyncService.batchInsertRows(
    'user_achievements',
    localIds.map((id) => {'user_id': userId, 'achievement_id': id}).toList(),
  );
}

Future<Set<String>> unlockAchievement(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await getUnlockedAchievements();
  if (current.contains(id)) return current;
  final updated = {...current, id};
  await prefs.setString(
    supabaseSyncService.scopedKey(_achievementsKey),
    jsonEncode(updated.toList()),
  );

  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    await supabaseSyncService.insertRow('user_achievements', {
      'user_id': userId,
      'achievement_id': id,
    });
  }

  return updated;
}

/// Hydrate local achievement cache from Supabase.
/// If server has data, it becomes the source of truth. If server is empty
/// and local has data, seed the server from local.
Future<void> syncAchievementsCacheFromSupabase() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;
  await migrateAchievementsCacheForHydration();

  final rows = await supabaseSyncService.fetchRows(
    'user_achievements',
    userId,
    orderBy: 'unlocked_at',
  );

  if (rows.isEmpty) {
    await seedAchievementsToSupabaseFromLocalCache();
    return;
  }
  await hydrateAchievementsCacheFromRows(rows);
}

// ---------------------------------------------------------------------------
// Check all achievements against current app state
// ---------------------------------------------------------------------------

class AchievementCheckData {
  final int discoveredNames;
  final int silverNames;
  final int goldNames;
  final int reflectionCount;
  final int uniqueEmotions;
  final int uniqueNamesInReflections;
  final int builtDuaCount;
  final int longestStreak;
  final int currentStreak;
  final bool hadBrokenStreak;
  final int xpTotal;
  final int level;
  final int journalEntries;
  final int dailyQuestsCompletedToday;
  final int totalDailyQuests;
  final bool hasUsedScroll;
  final bool hasCompleteSet; // bronze+silver+gold of same name
  final bool hasSelectedTitle;
  final int unlockedTitleCount;
  final int weeklyQuestsCompleted;
  final int monthlyQuestsCompleted;
  final int totalTokensSpent;
  final int namesInvokedCount;

  const AchievementCheckData({
    required this.discoveredNames,
    required this.silverNames,
    required this.goldNames,
    required this.reflectionCount,
    required this.uniqueEmotions,
    required this.uniqueNamesInReflections,
    required this.builtDuaCount,
    required this.longestStreak,
    required this.currentStreak,
    required this.hadBrokenStreak,
    required this.xpTotal,
    required this.level,
    required this.journalEntries,
    required this.dailyQuestsCompletedToday,
    required this.totalDailyQuests,
    this.hasUsedScroll = false,
    this.hasCompleteSet = false,
    this.hasSelectedTitle = false,
    this.unlockedTitleCount = 0,
    this.weeklyQuestsCompleted = 0,
    this.monthlyQuestsCompleted = 0,
    this.totalTokensSpent = 0,
    this.namesInvokedCount = 0,
  });
}

/// Returns IDs of newly unlocked achievements.
Future<List<String>> checkAndUnlockAchievements(
    AchievementCheckData data) async {
  final unlocked = await getUnlockedAchievements();
  final newlyUnlocked = <String>[];

  final checks = <String, bool>{
    // Collection
    'first_name': data.discoveredNames >= 1,
    'bronze_10': data.discoveredNames >= 10,
    'bronze_all': data.discoveredNames >= 99,
    'silver_10': data.silverNames >= 10,
    'gold_first': data.goldNames >= 1,
    'gold_all': data.goldNames >= 99,
    'first_upgrade': data.hasUsedScroll,
    'silver_5': data.silverNames >= 5,
    'gold_5': data.goldNames >= 5,
    'complete_set': data.hasCompleteSet,

    // Reflection
    'reflect_first': data.reflectionCount >= 1,
    'reflect_10': data.reflectionCount >= 10,
    'reflect_50': data.reflectionCount >= 50,
    'emotions_all': data.uniqueEmotions >= 6,
    'unique_names_10': data.uniqueNamesInReflections >= 10,

    // Dua
    'dua_first': data.builtDuaCount >= 1,
    'dua_10': data.builtDuaCount >= 10,
    'dua_50': data.builtDuaCount >= 50,
    'dua_100': data.builtDuaCount >= 100,

    // Names Invoked
    'invoked_1': data.namesInvokedCount >= 1,
    'invoked_10': data.namesInvokedCount >= 10,
    'invoked_50': data.namesInvokedCount >= 50,
    'invoked_99': data.namesInvokedCount >= 99,

    // Streak
    'streak_7': data.longestStreak >= 7,
    'streak_14': data.longestStreak >= 14,
    'streak_30': data.longestStreak >= 30,
    'streak_60': data.longestStreak >= 60,
    'streak_100': data.longestStreak >= 100,
    'streak_180': data.longestStreak >= 180,
    'streak_365': data.longestStreak >= 365,
    'comeback': data.hadBrokenStreak && data.currentStreak >= 1,

    // Growth & Levels
    'level_5': data.level >= 5,
    'level_10': data.level >= 10,
    'level_15': data.level >= 15,
    'level_20': data.level >= 20,
    'level_25': data.level >= 25,
    'journal_25': data.journalEntries >= 25,
    'all_quests_day': data.dailyQuestsCompletedToday >= data.totalDailyQuests &&
        data.totalDailyQuests > 0,

    // Titles
    'custom_title': data.hasSelectedTitle,
    'titles_5': data.unlockedTitleCount >= 5,

    // Quests
    'weekly_quest': data.weeklyQuestsCompleted >= 1,
    'monthly_quest': data.monthlyQuestsCompleted >= 1,

    // Spending
    'tokens_spent_100': data.totalTokensSpent >= 100,
    'tokens_spent_500': data.totalTokensSpent >= 500,
  };

  for (final entry in checks.entries) {
    if (entry.value && !unlocked.contains(entry.key)) {
      final achievement =
          allAchievements.where((a) => a.id == entry.key).firstOrNull;
      // Unlock first so a transient scroll sync failure doesn't block the
      // achievement permanently. The scroll reward may be lost on failure,
      // but the user keeps the achievement.
      await unlockAchievement(entry.key);
      newlyUnlocked.add(entry.key);
      if (achievement != null && achievement.scrollReward > 0) {
        await earnTierUpScrolls(achievement.scrollReward);
      }
    }
  }

  return newlyUnlocked;
}
