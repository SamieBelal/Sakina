import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Streak Milestones — one-time rewards for reaching streak thresholds
// ---------------------------------------------------------------------------

class StreakMilestone {
  final int days;
  final int xpReward;
  final int scrollReward;
  final String? titleUnlock; // English title to unlock, or null
  final String? titleUnlockArabic;

  const StreakMilestone({
    required this.days,
    required this.xpReward,
    required this.scrollReward,
    this.titleUnlock,
    this.titleUnlockArabic,
  });
}

const List<StreakMilestone> streakMilestones = [
  StreakMilestone(
      days: 7,
      xpReward: 100,
      scrollReward: 2,
      titleUnlock: 'Consistent',
      titleUnlockArabic: 'مُوَاظِب'),
  StreakMilestone(days: 14, xpReward: 150, scrollReward: 3),
  StreakMilestone(
      days: 30,
      xpReward: 300,
      scrollReward: 5,
      titleUnlock: 'Unwavering',
      titleUnlockArabic: 'رَاسِخ'),
  StreakMilestone(days: 60, xpReward: 500, scrollReward: 5),
  StreakMilestone(
      days: 90,
      xpReward: 750,
      scrollReward: 10,
      titleUnlock: 'Steadfast Soul',
      titleUnlockArabic: 'صَاحِبُ العَزْم'),
  StreakMilestone(days: 180, xpReward: 1000, scrollReward: 10),
  StreakMilestone(
      days: 365,
      xpReward: 2000,
      scrollReward: 15,
      titleUnlock: 'Guardian of Light',
      titleUnlockArabic: 'حَارِسُ النُّور'),
];

class StreakMilestoneResult {
  final StreakMilestone milestone;
  final bool isNew; // true if just claimed for the first time

  const StreakMilestoneResult({required this.milestone, required this.isNew});
}

const String _claimedMilestonesKey = 'sakina_streak_milestones_claimed';

Future<Set<int>> _getScopedClaimedMilestones(SharedPreferences prefs) async {
  final raw = await supabaseSyncService.migrateLegacyStringCache(
      prefs, _claimedMilestonesKey);
  if (raw == null) return {};
  return (jsonDecode(raw) as List<dynamic>).cast<int>().toSet();
}

/// Check which milestones were just reached. Returns only newly claimed ones.
Future<List<StreakMilestoneResult>> checkStreakMilestones(
    int currentStreak) async {
  final prefs = await SharedPreferences.getInstance();
  final claimed = await _getScopedClaimedMilestones(prefs);

  final newlyReached = <StreakMilestoneResult>[];
  for (final milestone in streakMilestones) {
    if (currentStreak >= milestone.days && !claimed.contains(milestone.days)) {
      claimed.add(milestone.days);
      newlyReached
          .add(StreakMilestoneResult(milestone: milestone, isNew: true));
    }
  }

  if (newlyReached.isNotEmpty) {
    await prefs.setString(
      supabaseSyncService.scopedKey(_claimedMilestonesKey),
      jsonEncode(claimed.toList()),
    );
  }

  return newlyReached;
}

/// Get set of already-claimed milestone day counts.
Future<Set<int>> getClaimedMilestones() async {
  final prefs = await SharedPreferences.getInstance();
  return _getScopedClaimedMilestones(prefs);
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

Future<int> _getCachedCurrentStreak(SharedPreferences prefs) async {
  final migrated =
      await supabaseSyncService.migrateLegacyIntCache(prefs, _currentStreakKey);
  return migrated ?? 0;
}

Future<int> _getCachedLongestStreak(SharedPreferences prefs) async {
  final migrated =
      await supabaseSyncService.migrateLegacyIntCache(prefs, _longestStreakKey);
  return migrated ?? 0;
}

Future<String?> _getCachedLastActive(SharedPreferences prefs) async {
  return supabaseSyncService.migrateLegacyStringCache(prefs, _lastActiveKey);
}

Future<Set<String>> _getCachedActivityLogSet(SharedPreferences prefs) async {
  final migrated = await supabaseSyncService.migrateLegacyStringListCache(
      prefs, _activityLogKey);
  return (migrated ?? const <String>[]).toSet();
}

Future<void> _setCachedStreakState(
  SharedPreferences prefs, {
  required int currentStreak,
  required int longestStreak,
  String? lastActive,
}) async {
  await prefs.setInt(
    supabaseSyncService.scopedKey(_currentStreakKey),
    currentStreak,
  );
  await prefs.setInt(
    supabaseSyncService.scopedKey(_longestStreakKey),
    longestStreak,
  );
  if (lastActive == null) {
    await prefs.remove(supabaseSyncService.scopedKey(_lastActiveKey));
  } else {
    await prefs.setString(
        supabaseSyncService.scopedKey(_lastActiveKey), lastActive);
  }
}

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

  final int currentStreak = await _getCachedCurrentStreak(prefs);
  final int longestStreak = await _getCachedLongestStreak(prefs);
  final String? lastActive = await _getCachedLastActive(prefs);

  bool todayActive = false;

  if (lastActive != null) {
    if (lastActive == today) {
      todayActive = true;
    }
  }

  return StreakState(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: lastActive,
    todayActive: todayActive,
  );
}

Future<void> prepareStreakCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await _getCachedCurrentStreak(prefs);
  await _getCachedLongestStreak(prefs);
  await _getCachedLastActive(prefs);
  await _getCachedActivityLogSet(prefs);
}

Future<void> hydrateStreakCache({
  required int currentStreak,
  required int longestStreak,
  String? lastActive,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await _setCachedStreakState(
    prefs,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: lastActive,
  );
}

Future<StreakState> markActiveToday() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayString();
  final userId = supabaseSyncService.currentUserId;
  String? lastActive = await _getCachedLastActive(prefs);
  int currentStreak = await _getCachedCurrentStreak(prefs);
  int longestStreak = await _getCachedLongestStreak(prefs);

  if (userId != null) {
    final row = await supabaseSyncService.fetchRow(
      'user_streaks',
      userId,
      columns: 'current_streak,longest_streak,last_active',
    );
    if (row != null) {
      currentStreak = row['current_streak'] as int? ?? currentStreak;
      longestStreak = row['longest_streak'] as int? ?? longestStreak;
      lastActive = row['last_active'] as String? ?? lastActive;
    }
  }

  // Already active today — return current state
  if (lastActive == today) {
    await _setCachedStreakState(
      prefs,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActive: lastActive,
    );
    return StreakState(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActive: lastActive,
      todayActive: true,
    );
  }

  // Check if streak continues (yesterday) or resets
  bool freezeConsumed = false;
  if (lastActive != null && _daysBetween(lastActive, today) > 1) {
    final frozeUsed = await consumeStreakFreeze();
    if (frozeUsed) {
      freezeConsumed = true;
    } else {
      currentStreak = 0;
    }
  }

  currentStreak += 1;

  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  if (userId != null) {
    final ok = await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active': today,
    });
    if (!ok && !freezeConsumed) {
      // Server write failed and no side-effects committed — safe to return
      // stale cached state so callers don't see phantom progress.
      return getStreak();
    }
    // If the freeze was consumed (server-side commit already happened) but
    // the streak upsert failed, we must still cache the computed values
    // locally. Otherwise the user loses their freeze for nothing.
  }

  await _setCachedStreakState(
    prefs,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: today,
  );

  return StreakState(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: today,
    todayActive: true,
  );
}

Future<Set<String>> getActivityLog() async {
  final prefs = await SharedPreferences.getInstance();
  return _getCachedActivityLogSet(prefs);
}

Future<void> logActivity() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayString();
  final logSet = await _getCachedActivityLogSet(prefs);

  if (!logSet.contains(today)) {
    logSet.add(today);
    await prefs.setStringList(
      supabaseSyncService.scopedKey(_activityLogKey),
      logSet.toList(),
    );
  }

  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;
  await supabaseSyncService.insertRow('user_activity_log', {
    'user_id': userId,
    'active_date': today,
  });
}
