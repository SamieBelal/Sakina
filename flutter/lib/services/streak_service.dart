import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

/// Analytics seam for the streak economy. `markActiveToday` /
/// `checkStreakMilestones` are top-level service functions with no Riverpod
/// access, so they emit through this static hook (same pattern as
/// `GatingService.onAnalyticsEvent`). Wired once in `main.dart`; null in tests
/// and until wired, so emitting is a safe no-op.
class StreakAnalytics {
  StreakAnalytics._();

  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;
}

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
  final userId = supabaseSyncService.currentUserId;

  final newlyReached = <StreakMilestoneResult>[];
  var changed = false;
  for (final milestone in streakMilestones) {
    if (currentStreak < milestone.days) continue;
    if (claimed.contains(milestone.days)) continue; // already granted here

    // Server-authoritative claim (§2f): the server decides whether this is
    // genuinely new, so a cache-clear / new device can't re-fire + re-grant.
    // If the RPC is unavailable (offline / local-only), fall back to granting
    // — preserving the prior local-prefs behavior.
    bool isNew = true;
    if (userId != null) {
      final res = await supabaseSyncService.callRpc<Map<String, dynamic>>(
        'claim_streak_milestone',
        {'p_day': milestone.days},
      );
      isNew = res == null ? true : (res['newly_claimed'] as bool? ?? true);
    }

    claimed.add(milestone.days);
    changed = true;
    if (isNew) {
      newlyReached
          .add(StreakMilestoneResult(milestone: milestone, isNew: true));
    }
  }

  // Persist the local claimed-set whenever it grew (even for server-confirmed
  // already-claimed milestones) so we don't re-call the RPC next time.
  if (changed) {
    await prefs.setString(
      supabaseSyncService.scopedKey(_claimedMilestonesKey),
      jsonEncode(claimed.toList()),
    );
  }

  if (newlyReached.isNotEmpty) {
    // Emit AFTER the claimed-set persists (best-effort, wrapped). Emitting
    // inside the loop would report a milestone that a failing persist never
    // marked claimed → it would re-fire next call. Matches markActiveToday's
    // emit-after-commit discipline.
    try {
      for (final reached in newlyReached) {
        StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakMilestone, {
          'streak_day': reached.milestone.days,
        });
      }
    } catch (_) {}
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

  /// The streak value saved when the current streak EXPIRED (soft-decay), kept
  /// so the user can optionally buy it back (§2g). 0 when there's nothing to
  /// restore. Set by [markActiveToday] when a return reflection lands past the
  /// free 48h window with no freeze.
  final int preLapseStreak;

  /// ISO-8601 UTC instant of the first missed day (00:00 UTC), or null. Drives
  /// the 30-day buy-back window.
  final String? lapsedAt;

  const StreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActive,
    required this.todayActive,
    this.preLapseStreak = 0,
    this.lapsedAt,
  });

  /// True when the last reflection just expired a streak worth buying back
  /// (≥7 days) — the daily loop surfaces the paid rescue on this.
  bool get hasRestorableLapse => preLapseStreak >= 7;

  /// Server-authoritative pricing mirror (see `repair_streak_paid`): the token
  /// cost to buy back [preLapseStreak], or null if not offered (<7).
  int? get repairCostTokens {
    if (preLapseStreak < 7) return null;
    if (preLapseStreak <= 29) return 100;
    if (preLapseStreak <= 89) return 250;
    return 500;
  }
}

const String _currentStreakKey = 'sakina_current_streak';
const String _longestStreakKey = 'sakina_longest_streak';
const String _lastActiveKey = 'sakina_last_active';
const String _activityLogKey = 'sakina_activity_log';
const String _preLapseStreakKey = 'sakina_pre_lapse_streak';
const String _lapsedAtKey = 'sakina_lapsed_at';
const String _excusedDatesKey = 'sakina_excused_dates';

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

Future<int> _getCachedPreLapseStreak(SharedPreferences prefs) async =>
    prefs.getInt(supabaseSyncService.scopedKey(_preLapseStreakKey)) ?? 0;

Future<String?> _getCachedLapsedAt(SharedPreferences prefs) async =>
    prefs.getString(supabaseSyncService.scopedKey(_lapsedAtKey));

Future<Set<String>> _getCachedExcusedDates(SharedPreferences prefs) async =>
    (prefs.getStringList(supabaseSyncService.scopedKey(_excusedDatesKey)) ??
            const <String>[])
        .toSet();

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

/// Persist the lapse bookkeeping separately so [hydrateStreakCache] (which
/// reconciles current/longest/lastActive from the batch RPC) never wipes a
/// pending pre-lapse buy-back the batch RPC doesn't yet know about.
Future<void> _setCachedLapse(
  SharedPreferences prefs, {
  required int preLapseStreak,
  required String? lapsedAt,
}) async {
  await prefs.setInt(
      supabaseSyncService.scopedKey(_preLapseStreakKey), preLapseStreak);
  if (lapsedAt == null) {
    await prefs.remove(supabaseSyncService.scopedKey(_lapsedAtKey));
  } else {
    await prefs.setString(
        supabaseSyncService.scopedKey(_lapsedAtKey), lapsedAt);
  }
}

String _todayString() {
  final now = DateTime.now().toUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

DateTime _parseUtcDate(String isoDate) {
  final parsed = DateTime.parse(isoDate).toUtc();
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
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
    preLapseStreak: await _getCachedPreLapseStreak(prefs),
    lapsedAt: await _getCachedLapsedAt(prefs),
  );
}

/// Free-repair window: a return reflection within 48h of the first missed day
/// is forgiven for free (§2b). Measured from the first UNEXCUSED missed day at
/// 00:00 UTC, not app-open time (finding #4).
const Duration _freeRepairWindow = Duration(hours: 48);

/// Outcome of the gap check between [lastActive] and [today].
enum _LapseKind { continues, lapsed }

class _LapseResult {
  const _LapseResult(this.kind, {this.lapsedAt});
  final _LapseKind kind;
  final DateTime? lapsedAt; // first unexcused missed day, 00:00 UTC (lapsed only)
}

/// Decide whether the streak continues or has lapsed, honoring excused days.
/// A run of missed days that are ALL excused counts as continuous.
_LapseResult _computeLapse(
    String lastActive, String today, Set<String> excused) {
  final last = _parseUtcDate(lastActive);
  final now = _parseUtcDate(today);
  DateTime? firstUnexcused;
  for (var d = last.add(const Duration(days: 1));
      d.isBefore(now);
      d = d.add(const Duration(days: 1))) {
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (!excused.contains(key)) {
      firstUnexcused ??= d;
    }
  }
  if (firstUnexcused == null) return const _LapseResult(_LapseKind.continues);
  return _LapseResult(_LapseKind.lapsed, lapsedAt: firstUnexcused);
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

/// Clear the pending lapse cache (pre_lapse / lapsed_at). Used by dev tools to
/// reset a forced streak state so the next [markActiveToday] recomputes cleanly.
Future<void> clearLapseCache() async {
  final prefs = await SharedPreferences.getInstance();
  await _setCachedLapse(prefs, preLapseStreak: 0, lapsedAt: null);
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

  // Already active today — return current state (unchanged fast path).
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
      preLapseStreak: await _getCachedPreLapseStreak(prefs),
      lapsedAt: await _getCachedLapsedAt(prefs),
    );
  }

  // Endowed start: the very first reflection on a brand-new lamp.
  final bool isEndowedStart = lastActive == null && longestStreak == 0;

  // ── The repair ladder (§2b): free effort-repair → earned freeze → expire ──
  bool freezeConsumed = false;
  String repairMethod = ''; // '', effort, freeze; expired => streakExpired
  int preLapseStreak = 0; // set only on EXPIRED, for the paid buy-back
  String? lapsedAtIso;
  bool lapsedThisRun = false;

  if (lastActive != null) {
    final excused = await _getCachedExcusedDates(prefs);
    final lapse = _computeLapse(lastActive, today, excused);
    if (lapse.kind == _LapseKind.lapsed) {
      lapsedThisRun = true;
      final lapsedAt = lapse.lapsedAt!;
      final withinFreeWindow =
          DateTime.now().toUtc().isBefore(lapsedAt.add(_freeRepairWindow));
      if (withinFreeWindow) {
        // Free effort-repair: the return reflection forgives the gap.
        repairMethod = AnalyticsEvents.repairMethodEffort;
      } else if (await consumeStreakFreeze()) {
        freezeConsumed = true;
        repairMethod = AnalyticsEvents.repairMethodFreeze;
      } else {
        // EXPIRED — start fresh at 1, but remember what was lost for buy-back.
        preLapseStreak = currentStreak;
        lapsedAtIso = lapsedAt.toIso8601String();
        currentStreak = 0;
      }
    }
  }

  currentStreak += 1;

  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  // True when the increment is durable: local-only mode (no userId) is
  // authoritative; otherwise it requires a successful server upsert.
  bool streakPersisted = true;
  if (userId != null) {
    final ok = await supabaseSyncService.upsertRow('user_streaks', userId, {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active': today,
      'pre_lapse_streak': preLapseStreak == 0 ? null : preLapseStreak,
      'lapsed_at': lapsedAtIso,
    });
    if (!ok && !freezeConsumed) {
      // Server write failed and no side-effects committed — safe to return
      // stale cached state so callers don't see phantom progress.
      return getStreak();
    }
    // If the freeze was consumed (server-side commit already happened) but
    // the streak upsert failed, we must still cache the computed values
    // locally. Otherwise the user loses their freeze for nothing.
    streakPersisted = ok;
  }

  await _setCachedStreakState(
    prefs,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: today,
  );
  await _setCachedLapse(prefs,
      preLapseStreak: preLapseStreak, lapsedAt: lapsedAtIso);

  // Analytics (best-effort, wrapped — a telemetry throw must never break the
  // streak write). Runs once per real increment (already-active returned above).
  try {
    if (isEndowedStart) {
      StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.endowedStart, {});
    }
    if (lapsedThisRun) {
      StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakLapsed, {
        'pre_lapse_streak': preLapseStreak > 0 ? preLapseStreak : currentStreak - 1,
      });
    }
    if (repairMethod.isNotEmpty && streakPersisted) {
      StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakRepaired, {
        'method': repairMethod,
        'streak_day': currentStreak,
      });
    }
    if (preLapseStreak > 0) {
      StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakExpired, {
        'pre_lapse_streak': preLapseStreak,
      });
    }
    // `streak_extended` still fires on every durable increment (repair or not),
    // preserving the existing funnel; `streak_freeze_consumed` on freeze use.
    if (streakPersisted) {
      StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakExtended, {
        'streak_day': currentStreak,
      });
    }
    if (freezeConsumed) {
      StreakAnalytics.onAnalyticsEvent
          ?.call(AnalyticsEvents.streakFreezeConsumed, {
        'streak_day': currentStreak,
      });
    }
  } catch (_) {}

  return StreakState(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastActive: today,
    todayActive: true,
    preLapseStreak: preLapseStreak,
    lapsedAt: lapsedAtIso,
  );
}

/// Buy back an EXPIRED streak with tokens (§2g). Server-authoritative and
/// atomic (`repair_streak_paid` debits + restores in one txn, and decides
/// premium-free vs paid server-side — the client never asserts premium).
/// Returns the outcome; on insufficient tokens, [PaidRepairResult.needsTokens]
/// is true so the caller can route to the Store.
Future<PaidRepairResult> repairStreakPaid() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) {
    return const PaidRepairResult(success: false);
  }
  try {
    final result = await Supabase.instance.client.rpc('repair_streak_paid');
    final map = (result as Map).cast<String, dynamic>();
    final restored = (map['current_streak'] as num).toInt();
    final method = map['method'] as String? ?? AnalyticsEvents.repairMethodPaid;
    final cost = (map['cost'] as num?)?.toInt() ?? 0;

    // Reconcile local caches: the streak is restored, the lapse cleared.
    final prefs = await SharedPreferences.getInstance();
    final longest = await _getCachedLongestStreak(prefs);
    await _setCachedStreakState(
      prefs,
      currentStreak: restored,
      longestStreak: restored > longest ? restored : longest,
      lastActive: _todayString(),
    );
    await _setCachedLapse(prefs, preLapseStreak: 0, lapsedAt: null);

    try {
      StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakRepaired, {
        'method': method,
        'streak_day': restored,
        'tokens_spent': cost,
      });
    } catch (_) {}

    return PaidRepairResult(
        success: true, restoredStreak: restored, tokensSpent: cost);
  } catch (e) {
    final msg = e.toString().toLowerCase();
    return PaidRepairResult(
        success: false, needsTokens: msg.contains('insufficient'));
  }
}

/// Record an excused day (menstruation / travel-illness) — capped server-side.
/// Returns true on success. Caches the date locally so the next
/// [markActiveToday] gap check honors it without a round-trip.
Future<bool> addExcusedDate(DateTime date) async {
  final iso =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final prefs = await SharedPreferences.getInstance();
  final userId = supabaseSyncService.currentUserId;
  if (userId != null) {
    final result =
        await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'add_excused_date',
      {'p_date': iso},
    );
    if (result == null) return false; // cap reached or error
  }
  final set = await _getCachedExcusedDates(prefs);
  set.add(iso);
  await prefs.setStringList(
      supabaseSyncService.scopedKey(_excusedDatesKey), set.toList());
  try {
    StreakAnalytics.onAnalyticsEvent?.call(AnalyticsEvents.streakExcusedUsed, {
      'excused_count_in_window': set.length,
    });
  } catch (_) {}
  return true;
}

/// Result of [repairStreakPaid].
class PaidRepairResult {
  const PaidRepairResult({
    required this.success,
    this.needsTokens = false,
    this.restoredStreak = 0,
    this.tokensSpent = 0,
  });
  final bool success;
  final bool needsTokens; // true → not enough tokens; route to Store
  final int restoredStreak;
  final int tokensSpent;
}

Future<Set<String>> getActivityLog() async {
  final prefs = await SharedPreferences.getInstance();
  return _getCachedActivityLogSet(prefs);
}

Future<void> logActivity() async {
  final prefs = await SharedPreferences.getInstance();
  final today = _todayString();
  final logSet = await _getCachedActivityLogSet(prefs);

  // Local cache is authoritative for "did this device already log today?"
  // — `_markStreakAndHandleMilestones` and the reflect flow both call this,
  // so a single check-in followed by a reflection on the same day would
  // otherwise re-write the row and 23505 on the (user_id, active_date)
  // unique constraint.
  if (logSet.contains(today)) return;

  logSet.add(today);
  await prefs.setStringList(
    supabaseSyncService.scopedKey(_activityLogKey),
    logSet.toList(),
  );

  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  // Upsert (not insert) so a stale local cache — fresh install on a new
  // device, signed-in-elsewhere, cleared prefs — still resolves cleanly
  // against an existing server row instead of throwing 23505.
  await supabaseSyncService.upsertRow(
    'user_activity_log',
    userId,
    {'active_date': today},
    onConflict: 'user_id,active_date',
  );
}
