import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/widgets/achievement_toast.dart';

/// Gather all app state and check for newly unlocked achievements.
/// Shows a toast for each new one. Safe to call frequently — idempotent.
Future<void> checkAchievements(WidgetRef ref) async {
  try {
    // Gather data from providers and services
    final reflections = ref.read(reflectProvider).savedReflections;
    final builtDuas = ref.read(duasProvider).savedBuiltDuas;
    final questsState = ref.read(questsProvider);

    final collection = await getCardCollection();
    final streak = await getStreak();
    final xp = await getXp();

    // Count unique emotions from check-in Q1 answers
    // We approximate from reflection user text keywords
    const emotionKeywords = {
      'heavy': 'Heavy',
      'anxious': 'Anxious',
      'grateful': 'Grateful',
      'disconnected': 'Disconnected',
      'hopeful': 'Hopeful',
      'okay': 'Okay',
    };
    final usedEmotions = <String>{};
    for (final r in reflections) {
      final lower = r.userText.toLowerCase();
      for (final entry in emotionKeywords.entries) {
        if (lower.contains(entry.key)) {
          usedEmotions.add(entry.value);
        }
      }
    }

    // Unique Names in reflections
    final uniqueNamesInReflections =
        reflections.map((r) => r.name).toSet().length;

    // Collection counts
    final discoveredCount = collection.discoveredIds.length;
    final silverCount =
        collection.tiers.values.where((t) => t >= 2).length;
    final goldCount =
        collection.tiers.values.where((t) => t >= 3).length;

    // Journal entries
    final journalEntries = reflections.length + builtDuas.length;

    // Daily quests completed today
    final dailyCompleted = questsState.dailyCompletedCount;
    final totalDaily = questsState.daily.length;

    // Comeback detection: had a broken streak (longest > current means broke at some point)
    final hadBrokenStreak =
        streak.longestStreak > streak.currentStreak && streak.currentStreak >= 1;

    final data = AchievementCheckData(
      discoveredNames: discoveredCount,
      silverNames: silverCount,
      goldNames: goldCount,
      reflectionCount: reflections.length,
      uniqueEmotions: usedEmotions.length,
      uniqueNamesInReflections: uniqueNamesInReflections,
      builtDuaCount: builtDuas.length,
      longestStreak: streak.longestStreak,
      currentStreak: streak.currentStreak,
      hadBrokenStreak: hadBrokenStreak,
      xpTotal: xp.totalXp,
      level: xp.level,
      journalEntries: journalEntries,
      dailyQuestsCompletedToday: dailyCompleted,
      totalDailyQuests: totalDaily,
    );

    final newlyUnlocked = await checkAndUnlockAchievements(data);

    // Show toast for each new achievement
    for (final id in newlyUnlocked) {
      final achievement = allAchievements.firstWhere((a) => a.id == id);
      showAchievementToast(achievement);
    }
  } catch (_) {
    // Non-critical — silently fail
  }
}
