import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
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
    final silverCount = collection.tiers.values.where((t) => t >= 2).length;
    final goldCount = collection.tiers.values.where((t) => t >= 3).length;

    // Journal entries
    final journalEntries = reflections.length + builtDuas.length;

    // Daily quests completed today
    final dailyCompleted = questsState.dailyCompletedCount;
    final totalDaily = questsState.daily.length;

    // Comeback detection: had a broken streak (longest > current means broke at some point)
    final hadBrokenStreak = streak.longestStreak > streak.currentStreak &&
        streak.currentStreak >= 1;

    // Check for complete set (bronze+silver+gold of same name = tier >= 3)
    final hasCompleteSet = collection.tiers.values.any((t) => t >= 3);

    // Scroll/title/spending data
    final prefs = await SharedPreferences.getInstance();
    final hasUsedScroll = await hasEverUsedScroll();
    final totalTokensSpent = await getTotalTokensSpent();

    // Title data
    final displayTitle = await getDisplayTitle(xp.level);
    final unlockedTitles = getUnlockedTitles(
      currentLevel: xp.level,
      longestStreak: streak.longestStreak,
    );

    // Names invoked in duas
    final namesInvoked = prefs.getStringList(
          supabaseSyncService.scopedKey('sakina_names_invoked'),
        ) ??
        [];

    // Quest completion counts
    final weeklyCompleted = questsState.weekly
        .where((q) => questsState.completedIds.contains(q.id))
        .length;
    final monthlyCompleted = questsState.monthly
        .where((q) => questsState.completedIds.contains(q.id))
        .length;

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
      hasUsedScroll: hasUsedScroll,
      hasCompleteSet: hasCompleteSet,
      hasSelectedTitle: !displayTitle.isAuto,
      unlockedTitleCount: unlockedTitles.length,
      weeklyQuestsCompleted: weeklyCompleted,
      monthlyQuestsCompleted: monthlyCompleted,
      totalTokensSpent: totalTokensSpent,
      namesInvokedCount: namesInvoked.length,
    );

    debugPrint('[AchievementChecker] discoveredNames=${data.discoveredNames}, '
        'level=${data.level}, streak=${data.longestStreak}, '
        'reflections=${data.reflectionCount}, duas=${data.builtDuaCount}');

    final newlyUnlocked = await checkAndUnlockAchievements(data);
    debugPrint('[AchievementChecker] newlyUnlocked=$newlyUnlocked');

    // Show toast for each new achievement
    for (final id in newlyUnlocked) {
      final achievement = allAchievements.firstWhere((a) => a.id == id);
      showAchievementToast(achievement);
    }
  } catch (e, st) {
    debugPrint('[AchievementChecker] FAILED: $e\n$st');
  }
}
