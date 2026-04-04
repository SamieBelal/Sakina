import 'package:shared_preferences/shared_preferences.dart';

class StreakState {
  final int currentStreak;
  final int longestStreak;
  final String? lastActive;
  final bool todayActive;

  const StreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActive,
    required this.todayActive,
  });
}

const String _currentStreakKey = 'sakina_current_streak';
const String _longestStreakKey = 'sakina_longest_streak';
const String _lastActiveKey = 'sakina_last_active';
const String _activityLogKey = 'sakina_activity_log';

String _todayString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

int _daysBetween(String dateA, String dateB) {
  final a = DateTime.parse(dateA);
  final b = DateTime.parse(dateB);
  return (a.difference(b).inDays).abs();
}

Future<StreakState> getStreak() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayString();

  int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
  final int longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
  final String? lastActive = prefs.getString(_lastActiveKey);

  bool todayActive = false;

  if (lastActive != null) {
    if (lastActive == today) {
      todayActive = true;
    } else if (_daysBetween(lastActive, today) > 1) {
      // Streak broken — reset
      currentStreak = 0;
      await prefs.setInt(_currentStreakKey, 0);
    }
  }

  return StreakState(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: lastActive,
    todayActive: todayActive,
  );
}

Future<StreakState> markActiveToday() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayString();
  final String? lastActive = prefs.getString(_lastActiveKey);

  // Already active today — return current state
  if (lastActive == today) {
    return getStreak();
  }

  int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
  int longestStreak = prefs.getInt(_longestStreakKey) ?? 0;

  // Check if streak continues (yesterday) or resets
  if (lastActive != null && _daysBetween(lastActive, today) > 1) {
    currentStreak = 0;
  }

  currentStreak += 1;

  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  await prefs.setInt(_currentStreakKey, currentStreak);
  await prefs.setInt(_longestStreakKey, longestStreak);
  await prefs.setString(_lastActiveKey, today);

  return StreakState(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: today,
    todayActive: true,
  );
}

Future<Set<String>> getActivityLog() async {
  final prefs = await SharedPreferences.getInstance();
  final List<String> log = prefs.getStringList(_activityLogKey) ?? [];
  return log.toSet();
}

Future<void> logActivity() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayString();
  final List<String> log = prefs.getStringList(_activityLogKey) ?? [];
  final logSet = log.toSet();

  if (!logSet.contains(today)) {
    logSet.add(today);
    await prefs.setStringList(_activityLogKey, logSet.toList());
  }
}
