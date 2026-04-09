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
  final int tokensAwarded;
  final int scrollsAwarded;
  final bool titleUnlocked;
  final String? unlockedTitle;
  final String? unlockedTitleArabic;

  const LevelUpRewards({
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
  // Levels 1-5: first week (fast)
  XpLevel(level: 1,  title: 'Seeker',           titleArabic: 'طَالِب',       minXp: 0,     tokenReward: 5,  scrollReward: 0,  unlocksTitle: true),
  XpLevel(level: 2,  title: 'Listener',         titleArabic: 'مُسْتَمِع',    minXp: 30,    tokenReward: 5,  scrollReward: 0),
  XpLevel(level: 3,  title: 'Repentant',        titleArabic: 'تَائِب',       minXp: 70,    tokenReward: 5,  scrollReward: 0),
  XpLevel(level: 4,  title: 'Hopeful',          titleArabic: 'رَاجٍ',        minXp: 120,   tokenReward: 5,  scrollReward: 0),
  XpLevel(level: 5,  title: 'Grateful',         titleArabic: 'شَاكِر',       minXp: 180,   tokenReward: 5,  scrollReward: 2,  unlocksTitle: true),

  // Levels 6-10: 1-2 weeks per level
  XpLevel(level: 6,  title: 'Patient',          titleArabic: 'صَابِر',       minXp: 250,   tokenReward: 6,  scrollReward: 0),
  XpLevel(level: 7,  title: 'Mindful',          titleArabic: 'مُتَأَمِّل',   minXp: 350,   tokenReward: 6,  scrollReward: 0),
  XpLevel(level: 8,  title: 'Devoted',          titleArabic: 'مُخْلِص',      minXp: 470,   tokenReward: 7,  scrollReward: 0),
  XpLevel(level: 9,  title: 'Rememberer',       titleArabic: 'ذَاكِر',       minXp: 620,   tokenReward: 7,  scrollReward: 0),
  XpLevel(level: 10, title: 'Humble',           titleArabic: 'خَاشِع',       minXp: 800,   tokenReward: 8,  scrollReward: 5,  unlocksTitle: true),

  // Levels 11-15: 2-3 weeks per level
  XpLevel(level: 11, title: 'Steadfast',        titleArabic: 'ثَابِت',       minXp: 1000,  tokenReward: 8,  scrollReward: 0),
  XpLevel(level: 12, title: 'Reflective',       titleArabic: 'مُتَفَكِّر',   minXp: 1250,  tokenReward: 9,  scrollReward: 0),
  XpLevel(level: 13, title: 'Trusting',         titleArabic: 'مُتَوَكِّل',   minXp: 1550,  tokenReward: 9,  scrollReward: 0),
  XpLevel(level: 14, title: 'Generous',         titleArabic: 'كَرِيم',       minXp: 1900,  tokenReward: 10, scrollReward: 0),
  XpLevel(level: 15, title: 'Contented',        titleArabic: 'رَاضٍ',        minXp: 2300,  tokenReward: 10, scrollReward: 3,  unlocksTitle: true),

  // Levels 16-20: monthly per level
  XpLevel(level: 16, title: 'Yearning',         titleArabic: 'مُشْتَاق',     minXp: 2750,  tokenReward: 11, scrollReward: 0),
  XpLevel(level: 17, title: 'Awakened',         titleArabic: 'مُتَيَقِّظ',   minXp: 3300,  tokenReward: 11, scrollReward: 0),
  XpLevel(level: 18, title: 'Purified',         titleArabic: 'مُزَكَّى',     minXp: 3950,  tokenReward: 12, scrollReward: 0),
  XpLevel(level: 19, title: 'Luminous',         titleArabic: 'مُنِير',       minXp: 4700,  tokenReward: 12, scrollReward: 0),
  XpLevel(level: 20, title: 'Beloved',          titleArabic: 'مَحْبُوب',     minXp: 5550,  tokenReward: 13, scrollReward: 7,  unlocksTitle: true),

  // Levels 21-25: months per level
  XpLevel(level: 21, title: 'Guided',           titleArabic: 'مَهْدِيّ',     minXp: 6500,  tokenReward: 13, scrollReward: 0),
  XpLevel(level: 22, title: 'Surrendered',      titleArabic: 'مُسْتَسْلِم',  minXp: 7600,  tokenReward: 14, scrollReward: 0),
  XpLevel(level: 23, title: 'Radiant',          titleArabic: 'مُتَأَلِّق',   minXp: 8900,  tokenReward: 14, scrollReward: 0),
  XpLevel(level: 24, title: 'Intimate',         titleArabic: 'قَرِيب',       minXp: 10400, tokenReward: 15, scrollReward: 0),
  XpLevel(level: 25, title: 'Friend of Allah',  titleArabic: 'وَلِيّ',       minXp: 12000, tokenReward: 15, scrollReward: 10, unlocksTitle: true),
];

// XP Awards
const int xpReflectionComplete = 25;
const int xpStoryRead = 10;
const int xpDuaRead = 10;
const int xpDailyStreak = 5;
const int xpDailyQuestionAnswered = 5;
const int xpBuiltDuaCompleted = 15;

const String _xpKey = 'sakina_total_xp';

Future<int> _getCachedXpTotal(SharedPreferences prefs) async {
  final migrated = await supabaseSyncService.migrateLegacyIntCache(prefs, _xpKey);
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

Future<void> syncXpCacheFromSupabase() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  await _getCachedXpTotal(prefs);
  final row = await supabaseSyncService.fetchRow('user_xp', userId);
  final total = row?['total_xp'] as int?;
  if (total == null) return;

  await _setCachedXpTotal(prefs, total);
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
    final newLevel = xpLevels[newState.level - 1];
    rewards = LevelUpRewards(
      tokensAwarded: newLevel.tokenReward,
      scrollsAwarded: newLevel.scrollReward,
      titleUnlocked: newLevel.unlocksTitle,
      unlockedTitle: newLevel.unlocksTitle ? newLevel.title : null,
      unlockedTitleArabic: newLevel.unlocksTitle ? newLevel.titleArabic : null,
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
