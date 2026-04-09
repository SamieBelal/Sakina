import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';

// ---------------------------------------------------------------------------
// Streak Milestones — one-time rewards for reaching streak thresholds
// ---------------------------------------------------------------------------

class StreakMilestone {
  final int days;
  final int scrollReward;
  final String? titleUnlock; // English title to unlock, or null
  final String? titleUnlockArabic;

  const StreakMilestone({
    required this.days,
    required this.scrollReward,
    this.titleUnlock,
    this.titleUnlockArabic,
  });
}

const List<StreakMilestone> streakMilestones = [
  StreakMilestone(days: 7,   scrollReward: 2,  titleUnlock: 'Consistent',    titleUnlockArabic: 'مُوَاظِب'),
  StreakMilestone(days: 14,  scrollReward: 3),
  StreakMilestone(days: 30,  scrollReward: 5,  titleUnlock: 'Unwavering',    titleUnlockArabic: 'رَاسِخ'),
  StreakMilestone(days: 60,  scrollReward: 5),
  StreakMilestone(days: 90,  scrollReward: 10, titleUnlock: 'Steadfast Soul', titleUnlockArabic: 'صَاحِبُ العَزْم'),
  StreakMilestone(days: 180, scrollReward: 10),
  StreakMilestone(days: 365, scrollReward: 15, titleUnlock: 'Guardian of Light', titleUnlockArabic: 'حَارِسُ النُّور'),
];

class StreakMilestoneResult {
  final StreakMilestone milestone;
  final bool isNew; // true if just claimed for the first time

  const StreakMilestoneResult({required this.milestone, required this.isNew});
}

const String _claimedMilestonesKey = 'sakina_streak_milestones_claimed';

/// Check which milestones were just reached. Returns only newly claimed ones.
Future<List<StreakMilestoneResult>> checkStreakMilestones(int currentStreak) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_claimedMilestonesKey);
  final claimed = raw != null ? (jsonDecode(raw) as List<dynamic>).cast<int>().toSet() : <int>{};

  final newlyReached = <StreakMilestoneResult>[];
  for (final milestone in streakMilestones) {
    if (currentStreak >= milestone.days && !claimed.contains(milestone.days)) {
      claimed.add(milestone.days);
      newlyReached.add(StreakMilestoneResult(milestone: milestone, isNew: true));
    }
  }

  if (newlyReached.isNotEmpty) {
    await prefs.setString(_claimedMilestonesKey, jsonEncode(claimed.toList()));
  }

  return newlyReached;
}

/// Get set of already-claimed milestone day counts.
Future<Set<int>> getClaimedMilestones() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_claimedMilestonesKey);
  if (raw == null) return {};
  return (jsonDecode(raw) as List<dynamic>).cast<int>().toSet();
}

// ---------------------------------------------------------------------------
// Streak State
// ---------------------------------------------------------------------------

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
      // Try streak freeze before resetting
      final frozeUsed = await consumeStreakFreeze();
      if (frozeUsed) {
        // Freeze consumed — pretend yesterday was active
        final y = DateTime.now().subtract(const Duration(days: 1));
        final yesterday = '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
        await prefs.setString(_lastActiveKey, yesterday);
      } else {
        // Streak broken — reset
        currentStreak = 0;
        await prefs.setInt(_currentStreakKey, 0);
      }
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
    final frozeUsed = await consumeStreakFreeze();
    if (!frozeUsed) {
      currentStreak = 0;
    }
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
