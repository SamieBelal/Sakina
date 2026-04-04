import 'package:shared_preferences/shared_preferences.dart';

class XpLevel {
  final int level;
  final String title;
  final String titleArabic;
  final int minXp;

  const XpLevel({
    required this.level,
    required this.title,
    required this.titleArabic,
    required this.minXp,
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

class XpAwardResult {
  final int gained;
  final int newTotal;
  final bool leveledUp;
  final XpState state;

  const XpAwardResult({
    required this.gained,
    required this.newTotal,
    required this.leveledUp,
    required this.state,
  });
}

const List<XpLevel> xpLevels = [
  XpLevel(level: 1, title: 'Seeker', titleArabic: 'طَالِب', minXp: 0),
  XpLevel(level: 2, title: 'Reflector', titleArabic: 'مُتَفَكِّر', minXp: 50),
  XpLevel(level: 3, title: 'Devoted', titleArabic: 'مُخْلِص', minXp: 150),
  XpLevel(level: 4, title: 'Enlightened', titleArabic: 'مُنَوَّر', minXp: 350),
  XpLevel(level: 5, title: 'Sage', titleArabic: 'حَكِيم', minXp: 700),
];

// XP Awards
const int xpReflectionComplete = 25;
const int xpStoryRead = 10;
const int xpDuaRead = 10;
const int xpDailyStreak = 5;
const int xpDailyQuestionAnswered = 5;
const int xpBuiltDuaCompleted = 15;

const String _xpKey = 'sakina_total_xp';

XpState _calculateState(int total) {
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
    // Max level — no next level
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

Future<XpState> getXp() async {
  final prefs = await SharedPreferences.getInstance();
  final total = prefs.getInt(_xpKey) ?? 0;
  return _calculateState(total);
}

Future<XpAwardResult> awardXp(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final oldTotal = prefs.getInt(_xpKey) ?? 0;
  final oldState = _calculateState(oldTotal);
  final newTotal = oldTotal + amount;
  await prefs.setInt(_xpKey, newTotal);
  final newState = _calculateState(newTotal);

  return XpAwardResult(
    gained: amount,
    newTotal: newTotal,
    leveledUp: newState.level > oldState.level,
    state: newState,
  );
}
