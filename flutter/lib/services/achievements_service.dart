import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.color,
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
  ),
  Achievement(
    id: 'bronze_10',
    title: 'Seeker of Names',
    description: 'Discover 10 Names of Allah.',
    icon: Icons.grid_view_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFCD7F32),
  ),
  Achievement(
    id: 'bronze_all',
    title: 'The 99',
    description: 'Discover all 99 Names of Allah.',
    icon: Icons.stars_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFCD7F32),
  ),
  Achievement(
    id: 'silver_10',
    title: 'Silver Scholar',
    description: 'Unlock Silver tier on 10 Names.',
    icon: Icons.military_tech_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFC0C0C0),
  ),
  Achievement(
    id: 'gold_first',
    title: 'Golden Light',
    description: 'Unlock Gold tier on your first Name.',
    icon: Icons.emoji_events_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFD4A44C),
  ),
  Achievement(
    id: 'gold_all',
    title: 'Master of the Names',
    description: 'Unlock Gold tier on all 99 Names.',
    icon: Icons.workspace_premium_rounded,
    category: AchievementCategory.collection,
    color: Color(0xFFD4A44C),
  ),

  // ── Reflection (5) ─────────────────────────────────────────────────────────

  Achievement(
    id: 'reflect_first',
    title: 'First Reflection',
    description: 'Complete your first Reflect session.',
    icon: Icons.auto_stories_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF1B6B4A),
  ),
  Achievement(
    id: 'reflect_10',
    title: 'Deep Thinker',
    description: 'Complete 10 Reflect sessions.',
    icon: Icons.auto_stories_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF1B6B4A),
  ),
  Achievement(
    id: 'reflect_50',
    title: 'Heart of a Muhasib',
    description: 'Complete 50 Reflect sessions.',
    icon: Icons.favorite_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF1B6B4A),
  ),
  Achievement(
    id: 'emotions_all',
    title: 'Full Spectrum',
    description: 'Check in with all 6 emotional states.',
    icon: Icons.palette_rounded,
    category: AchievementCategory.reflection,
    color: Color(0xFF6B4E9B),
  ),
  Achievement(
    id: 'unique_names_10',
    title: 'Many Facets',
    description: 'Receive 10 different Names across your reflections.',
    icon: Icons.auto_awesome,
    category: AchievementCategory.reflection,
    color: Color(0xFFC8985E),
  ),

  // ── Dua (4) ────────────────────────────────────────────────────────────────

  Achievement(
    id: 'dua_first',
    title: 'First Supplication',
    description: 'Build your first personal dua.',
    icon: Icons.auto_awesome,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
  ),
  Achievement(
    id: 'dua_10',
    title: 'Dua Maker',
    description: 'Build 10 personal duas.',
    icon: Icons.auto_awesome,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
  ),
  Achievement(
    id: 'dua_50',
    title: 'Whisperer to Allah',
    description: 'Build 50 personal duas.',
    icon: Icons.brightness_3_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
  ),
  Achievement(
    id: 'dua_100',
    title: 'Devoted Caller',
    description: 'Build 100 personal duas.',
    icon: Icons.all_inclusive_rounded,
    category: AchievementCategory.dua,
    color: Color(0xFFC8985E),
  ),

  // ── Streak (5) ─────────────────────────────────────────────────────────────

  Achievement(
    id: 'streak_7',
    title: 'One Week Strong',
    description: 'Maintain a 7-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
  ),
  Achievement(
    id: 'streak_30',
    title: 'Month of Devotion',
    description: 'Maintain a 30-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
  ),
  Achievement(
    id: 'streak_100',
    title: 'Century of Faith',
    description: 'Maintain a 100-day streak.',
    icon: Icons.local_fire_department,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
  ),
  Achievement(
    id: 'streak_365',
    title: 'Year of Remembrance',
    description: 'Maintain a 365-day streak.',
    icon: Icons.whatshot_rounded,
    category: AchievementCategory.streak,
    color: Color(0xFFF59E0B),
  ),
  Achievement(
    id: 'comeback',
    title: 'The Return',
    description: 'Come back after a broken streak and start again.',
    icon: Icons.replay_rounded,
    category: AchievementCategory.streak,
    color: Color(0xFF1B6B4A),
  ),

  // ── Growth (5) ─────────────────────────────────────────────────────────────

  Achievement(
    id: 'level_5',
    title: 'Devoted',
    description: 'Reach Level 5 — Devoted.',
    icon: Icons.trending_up_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
  ),
  Achievement(
    id: 'level_10',
    title: 'Friend of Allah',
    description: 'Reach Level 10 — the highest rank.',
    icon: Icons.workspace_premium_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFFD4A44C),
  ),
  Achievement(
    id: 'xp_1000',
    title: 'Thousand Steps',
    description: 'Earn 1,000 total XP.',
    icon: Icons.bolt_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
  ),
  Achievement(
    id: 'journal_25',
    title: 'Faithful Scribe',
    description: 'Save 25 entries to your Journal.',
    icon: Icons.bookmark_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF6B4E9B),
  ),
  Achievement(
    id: 'all_quests_day',
    title: 'Perfect Day',
    description: 'Complete all daily quests in a single day.',
    icon: Icons.check_circle_rounded,
    category: AchievementCategory.growth,
    color: Color(0xFF1B6B4A),
  ),
];

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

const _achievementsKey = 'sakina_achievements_unlocked';

Future<Set<String>> getUnlockedAchievements() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_achievementsKey);
  if (raw == null) return {};
  try {
    return (jsonDecode(raw) as List).cast<String>().toSet();
  } catch (_) {
    return {};
  }
}

Future<Set<String>> unlockAchievement(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await getUnlockedAchievements();
  if (current.contains(id)) return current;
  final updated = {...current, id};
  await prefs.setString(_achievementsKey, jsonEncode(updated.toList()));
  return updated;
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
  final bool hadBrokenStreak; // streak was 0 but now > 0
  final int xpTotal;
  final int level;
  final int journalEntries;
  final int dailyQuestsCompletedToday;
  final int totalDailyQuests;

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
  });
}

/// Returns IDs of newly unlocked achievements.
Future<List<String>> checkAndUnlockAchievements(AchievementCheckData data) async {
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

    // Streak
    'streak_7': data.longestStreak >= 7,
    'streak_30': data.longestStreak >= 30,
    'streak_100': data.longestStreak >= 100,
    'streak_365': data.longestStreak >= 365,
    'comeback': data.hadBrokenStreak && data.currentStreak >= 1,

    // Growth
    'level_5': data.level >= 5,
    'level_10': data.level >= 10,
    'xp_1000': data.xpTotal >= 1000,
    'journal_25': data.journalEntries >= 25,
    'all_quests_day': data.dailyQuestsCompletedToday >= data.totalDailyQuests && data.totalDailyQuests > 0,
  };

  for (final entry in checks.entries) {
    if (entry.value && !unlocked.contains(entry.key)) {
      await unlockAchievement(entry.key);
      newlyUnlocked.add(entry.key);
    }
  }

  return newlyUnlocked;
}
