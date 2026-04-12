import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

class XpLevel {
  final int level;
  final String title;
  final String titleArabic;
  final int minXp;
  final int tokenReward;
  final int scrollReward;
  final bool unlocksTitle;

  const XpLevel({
    required this.level,
    required this.title,
    required this.titleArabic,
    required this.minXp,
    this.tokenReward = 5,
    this.scrollReward = 0,
    this.unlocksTitle = false,
  });
}

class XpState {
  final int totalXp;
  final int level;
  final String title;
  final String titleArabic;
  final int xpForNextLevel;
  final int xpIntoCurrentLevel;

  const XpState({
    required this.totalXp,
    required this.level,
    required this.title,
    required this.titleArabic,
    required this.xpForNextLevel,
    required this.xpIntoCurrentLevel,
  });
}

class LevelUpRewards {
  /// Number of levels gained in this single award. ≥ 1 when leveledUp is true.
  /// May be > 1 if a single XP grant spans multiple level thresholds.
  final int levelsGained;
  final int tokensAwarded;
  final int scrollsAwarded;
  final bool titleUnlocked;
  final String? unlockedTitle;
  final String? unlockedTitleArabic;

  const LevelUpRewards({
    this.levelsGained = 1,
    required this.tokensAwarded,
    required this.scrollsAwarded,
    required this.titleUnlocked,
    this.unlockedTitle,
    this.unlockedTitleArabic,
  });
}

class XpAwardResult {
  final int gained;
  final int newTotal;
  final bool leveledUp;
  final XpState state;
  final LevelUpRewards? rewards;

  const XpAwardResult({
    required this.gained,
    required this.newTotal,
    required this.leveledUp,
    required this.state,
    this.rewards,
  });
}

const List<XpLevel> xpLevels = [
  // Levels 1-5: stretched so First Steps (~375 XP) lands exactly at L5.
  XpLevel(
      level: 1,
      title: 'Seeker',
      titleArabic: 'طَالِب',
      minXp: 0,
      tokenReward: 5,
      scrollReward: 0,
      unlocksTitle: true),
  XpLevel(
      level: 2,
      title: 'Listener',
      titleArabic: 'مُسْتَمِع',
      minXp: 75,
      tokenReward: 5,
      scrollReward: 0),
  XpLevel(
      level: 3,
      title: 'Repentant',
      titleArabic: 'تَائِب',
      minXp: 175,
      tokenReward: 5,
      scrollReward: 0),
  XpLevel(
      level: 4,
      title: 'Hopeful',
      titleArabic: 'رَاجٍ',
      minXp: 275,
      tokenReward: 5,
      scrollReward: 0),
  XpLevel(
      level: 5,
      title: 'Grateful',
      titleArabic: 'شَاكِر',
      minXp: 375,
      tokenReward: 5,
      scrollReward: 2,
      unlocksTitle: true),

  // Levels 6-10: original deltas carried forward from L5 = 375.
  XpLevel(
      level: 6,
      title: 'Patient',
      titleArabic: 'صَابِر',
      minXp: 445,
      tokenReward: 6,
      scrollReward: 0),
  XpLevel(
      level: 7,
      title: 'Mindful',
      titleArabic: 'مُتَأَمِّل',
      minXp: 545,
      tokenReward: 6,
      scrollReward: 0),
  XpLevel(
      level: 8,
      title: 'Devoted',
      titleArabic: 'مُخْلِص',
      minXp: 665,
      tokenReward: 7,
      scrollReward: 0),
  XpLevel(
      level: 9,
      title: 'Rememberer',
      titleArabic: 'ذَاكِر',
      minXp: 815,
      tokenReward: 7,
      scrollReward: 0),
  XpLevel(
      level: 10,
      title: 'Humble',
      titleArabic: 'خَاشِع',
      minXp: 995,
      tokenReward: 8,
      scrollReward: 5,
      unlocksTitle: true),

  // Levels 11-15
  XpLevel(
      level: 11,
      title: 'Steadfast',
      titleArabic: 'ثَابِت',
      minXp: 1195,
      tokenReward: 8,
      scrollReward: 0),
  XpLevel(
      level: 12,
      title: 'Reflective',
      titleArabic: 'مُتَفَكِّر',
      minXp: 1445,
      tokenReward: 9,
      scrollReward: 0),
  XpLevel(
      level: 13,
      title: 'Trusting',
      titleArabic: 'مُتَوَكِّل',
      minXp: 1745,
      tokenReward: 9,
      scrollReward: 0),
  XpLevel(
      level: 14,
      title: 'Generous',
      titleArabic: 'كَرِيم',
      minXp: 2095,
      tokenReward: 10,
      scrollReward: 0),
  XpLevel(
      level: 15,
      title: 'Contented',
      titleArabic: 'رَاضٍ',
      minXp: 2495,
      tokenReward: 10,
      scrollReward: 3,
      unlocksTitle: true),

  // Levels 16-20
  XpLevel(
      level: 16,
      title: 'Yearning',
      titleArabic: 'مُشْتَاق',
      minXp: 2945,
      tokenReward: 11,
      scrollReward: 0),
  XpLevel(
      level: 17,
      title: 'Awakened',
      titleArabic: 'مُتَيَقِّظ',
      minXp: 3495,
      tokenReward: 11,
      scrollReward: 0),
  XpLevel(
      level: 18,
      title: 'Purified',
      titleArabic: 'مُزَكَّى',
      minXp: 4145,
      tokenReward: 12,
      scrollReward: 0),
  XpLevel(
      level: 19,
      title: 'Luminous',
      titleArabic: 'مُنِير',
      minXp: 4895,
      tokenReward: 12,
      scrollReward: 0),
  XpLevel(
      level: 20,
      title: 'Beloved',
      titleArabic: 'مَحْبُوب',
      minXp: 5745,
      tokenReward: 13,
      scrollReward: 7,
      unlocksTitle: true),

  // Levels 21-25
  XpLevel(
      level: 21,
      title: 'Guided',
      titleArabic: 'مَهْدِيّ',
      minXp: 6695,
      tokenReward: 13,
      scrollReward: 0),
  XpLevel(
      level: 22,
      title: 'Surrendered',
      titleArabic: 'مُسْتَسْلِم',
      minXp: 7795,
      tokenReward: 14,
      scrollReward: 0),
  XpLevel(
      level: 23,
      title: 'Radiant',
      titleArabic: 'مُتَأَلِّق',
      minXp: 9095,
      tokenReward: 14,
      scrollReward: 0),
  XpLevel(
      level: 24,
      title: 'Intimate',
      titleArabic: 'قَرِيب',
      minXp: 10595,
      tokenReward: 15,
      scrollReward: 0),
  XpLevel(
      level: 25,
      title: 'Friend of Allah',
      titleArabic: 'وَلِيّ',
      minXp: 12195,
      tokenReward: 15,
      scrollReward: 10,
      unlocksTitle: true),
];

// =============================================================================
// XP Awards — single source of truth
// =============================================================================
//
// Only two things grant XP in this app:
//   1. Completing a quest (daily / weekly / monthly / First Steps)
//   2. Hitting a streak milestone
//
// Muhasabah, Reflect, Build a Dua, Find a Dua, Daily Question, story / dua
// reads, and every other in-flow micro-action grant zero XP on their own.
// The card pull at the end of a muhasabah is the reward for showing up; XP
// only flows through quest completion and streak milestones.
// =============================================================================

// Streak milestone XP is defined alongside scroll rewards on
// `StreakMilestone` in `services/streak_service.dart`.

const String _xpKey = 'sakina_total_xp';

Future<int> _getCachedXpTotal(SharedPreferences prefs) async {
  final migrated =
      await supabaseSyncService.migrateLegacyIntCache(prefs, _xpKey);
  return migrated ?? 0;
}

Future<void> _setCachedXpTotal(SharedPreferences prefs, int total) async {
  await prefs.setInt(supabaseSyncService.scopedKey(_xpKey), total);
}

XpState calculateXpState(int total) {
  XpLevel current = xpLevels.first;
  for (final level in xpLevels) {
    if (total >= level.minXp) {
      current = level;
    } else {
      break;
    }
  }

  final int xpIntoCurrentLevel = total - current.minXp;

  int xpForNextLevel;
  if (current.level < xpLevels.length) {
    xpForNextLevel = xpLevels[current.level].minXp - current.minXp;
  } else {
    xpForNextLevel = 0;
  }

  return XpState(
    totalXp: total,
    level: current.level,
    title: current.title,
    titleArabic: current.titleArabic,
    xpForNextLevel: xpForNextLevel,
    xpIntoCurrentLevel: xpIntoCurrentLevel,
  );
}

String nextLevelTitle(int totalXp) {
  final state = calculateXpState(totalXp);
  if (state.level < xpLevels.length) {
    return xpLevels[state.level].title;
  }
  return '';
}

Future<XpState> getXp() async {
  final prefs = await SharedPreferences.getInstance();
  final total = await _getCachedXpTotal(prefs);
  return calculateXpState(total);
}

Future<void> prepareXpCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await _getCachedXpTotal(prefs);
}

Future<void> hydrateXpCache({required int totalXp}) async {
  final prefs = await SharedPreferences.getInstance();
  await _setCachedXpTotal(prefs, totalXp);
}

Future<XpAwardResult> awardXp(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final oldTotal = await _getCachedXpTotal(prefs);
  final oldState = calculateXpState(oldTotal);
  final userId = supabaseSyncService.currentUserId;

  int newTotal;
  if (userId != null) {
    final remoteTotal = await supabaseSyncService.callRpc<int>(
      'award_xp',
      {'amount': amount},
    );
    if (remoteTotal == null) {
      return XpAwardResult(
        gained: 0,
        newTotal: oldTotal,
        leveledUp: false,
        state: oldState,
      );
    }
    newTotal = remoteTotal;
  } else {
    newTotal = oldTotal + amount;
  }

  await _setCachedXpTotal(prefs, newTotal);
  final newState = calculateXpState(newTotal);

  final didLevel = newState.level > oldState.level;
  LevelUpRewards? rewards;
  if (didLevel) {
    // Aggregate rewards across EVERY level crossed by this single grant.
    // Without this, intermediate levels' token/scroll rewards would be lost
    // when a big XP grant (e.g. First Steps bundle) skips past them.
    int tokensAwarded = 0;
    int scrollsAwarded = 0;
    bool titleUnlocked = false;
    String? unlockedTitle;
    String? unlockedTitleArabic;

    for (var lv = oldState.level + 1; lv <= newState.level; lv++) {
      final crossed = xpLevels[lv - 1];
      tokensAwarded += crossed.tokenReward;
      scrollsAwarded += crossed.scrollReward;
      // If multiple title-unlock levels are crossed, surface the highest
      // (last loop iteration wins) — UI only celebrates one title at a time.
      if (crossed.unlocksTitle) {
        titleUnlocked = true;
        unlockedTitle = crossed.title;
        unlockedTitleArabic = crossed.titleArabic;
      }
    }

    rewards = LevelUpRewards(
      levelsGained: newState.level - oldState.level,
      tokensAwarded: tokensAwarded,
      scrollsAwarded: scrollsAwarded,
      titleUnlocked: titleUnlocked,
      unlockedTitle: unlockedTitle,
      unlockedTitleArabic: unlockedTitleArabic,
    );
  }

  return XpAwardResult(
    gained: amount,
    newTotal: newTotal,
    leveledUp: didLevel,
    state: newState,
    rewards: rewards,
  );
}
