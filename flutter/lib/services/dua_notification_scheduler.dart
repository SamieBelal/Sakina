import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:sakina/features/dua_times/data/dua_window_copy_book.dart';
import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_window_engine.dart';

/// Reserved id band for duʿā-window local notifications.
///
/// The plugin's integer id space is shared with OneSignal's own local
/// notifications (Risk 7) and any other feature that schedules locally. We carve
/// out a fixed band `[kDuaIdBase, kDuaIdBase + kDuaIdBandSize)` and NEVER touch
/// an id outside it — targeted cancel walks
/// [FlutterLocalNotificationsPlugin.pendingNotificationRequests] and cancels
/// only ids in this range (never `cancelAll`, which would nuke OneSignal's).
const int kDuaIdBase = 810000000;

/// Width of the reserved band. Bigger than [kDuaMaxScheduled] so distinct
/// `stableHash` outputs never collide *out of* the band, and so a future cap
/// bump stays inside it.
const int kDuaIdBandSize = 100000;

/// Hard cap on how many duʿā notifications may be scheduled at once (review
/// Issue: iOS silently drops pending locals past ~64/app; we stay well under and
/// share the budget with OneSignal). When more than this many windows are
/// eligible, the LOWEST-[DuaWindowEngine.priorityOf] windows are dropped.
const int kDuaMaxScheduled = 40;

/// Default local fire-hour (24h) for all-day calendar windows, which have no
/// intrinsic clock time — they open at local midnight. Firing at midnight is
/// useless, so we anchor the reminder to a civil morning hour.
///
/// TUNABLE (D-decisions D1/D2 still open): fire-point + cadence are not yet
/// locked. This is a sensible default, not a product decision.
const int kDuaAllDayFireHour = 9;

/// Minimum interval between reschedules — the throttle (review Issue 3). The
/// duʿā card / foreground path can call [reschedule] on every rebuild; churning
/// the OS scheduler that often is wasteful. Within this window a reschedule is a
/// no-op unless forced.
///
/// TUNABLE: chosen conservatively; safe to shorten if the card needs snappier
/// reflection of a just-changed calendar.
const Duration kDuaRescheduleThrottle = Duration(minutes: 30);

/// The notification channel (Android) the duʿā reminders post to. iOS ignores
/// the channel but still needs [NotificationDetails].
const String kDuaChannelId = 'dua_windows';
const String kDuaChannelName = 'Duʿā Times';
const String kDuaChannelDescription =
    'Reminders when a time of accepted duʿā is open.';

/// A single computed schedule entry: the reserved-band id, its fire instant, and
/// the window it came from. Extracted so the scheduling + hashing + cap logic is
/// pure and unit-testable in isolation from the plugin.
@immutable
class _PlannedNotification {
  const _PlannedNotification({
    required this.id,
    required this.fireUtc,
    required this.window,
  });

  final int id;
  final DateTime fireUtc;
  final DuaWindow window;
}

/// Local scheduler for the CALENDAR (all-day, location-independent) duʿā
/// windows only. Precise (location-dependent) windows are delivered by the
/// server-push path and are explicitly filtered out here (see the plan §4).
///
/// A plain service — NO Riverpod (per `CLAUDE.md`). The plugin and a clock are
/// injected so it is unit-testable against a fake plugin. Every public method
/// degrades silently on error: a failed reminder must never crash or surface to
/// the user.
///
/// Hardening carried from the eng review:
/// - **Reserved id band + targeted cancel** — ids live in `[kDuaIdBase, …)`;
///   cancel walks pending requests and removes only band members, never
///   `cancelAll` (which would kill OneSignal's own locals — Risk 7 / Issue 2).
/// - **Deterministic ids** — `id = kDuaIdBase + stableHash(type + localDate)`,
///   so re-running with the same windows produces the same ids and never
///   duplicates (Issue 2).
/// - **Hard cap ([kDuaMaxScheduled])** — over the cap, the lowest-priority
///   windows are dropped (Issue 2).
/// - **Throttle + skip-if-unchanged** — at most once per
///   [kDuaRescheduleThrottle]; a byte-identical computed set is a no-op,
///   mirroring `WidgetDataService`'s perf guard (Issue 3).
class DuaNotificationScheduler {
  DuaNotificationScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    DateTime Function()? clock,
    Duration rescheduleThrottle = kDuaRescheduleThrottle,
    int maxScheduled = kDuaMaxScheduled,
    int allDayFireHour = kDuaAllDayFireHour,
  })  : _plugin = plugin,
        _clock = clock ?? DateTime.now,
        _throttle = rescheduleThrottle,
        _maxScheduled = maxScheduled,
        _allDayFireHour = allDayFireHour;

  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;
  final Duration _throttle;
  final int _maxScheduled;
  final int _allDayFireHour;

  /// The last reschedule instant — throttle state.
  DateTime? _lastReschedule;

  /// Hash of the last computed schedule set written this process — the
  /// skip-if-unchanged guard (mirrors `WidgetDataService._lastWritten`). When
  /// the newly-computed set hashes identical we no-op without touching the OS.
  int? _lastScheduledHash;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Recompute + reschedule the calendar-window reminders from [schedule].
  ///
  /// - Filters to calendar windows only (drops location-dependent precise ones).
  /// - Applies the hard cap by [DuaWindowEngine.priorityOf].
  /// - Targeted-cancels the existing dua band, then schedules the new set.
  /// - Honors the throttle + skip-if-unchanged guard unless [force] is true.
  ///
  /// [force] bypasses the throttle (e.g. a user just toggled the opt-in); it
  /// still honors skip-if-unchanged so a forced call with an identical set is
  /// still cheap.
  ///
  /// Never throws — degrades silently.
  Future<void> reschedule(
    DuaWindowSchedule schedule, {
    required String localTzName,
    bool force = false,
  }) async {
    try {
      final now = _clock().toUtc();

      if (!force && _lastReschedule != null) {
        final since = now.difference(_lastReschedule!);
        if (since < _throttle) return;
      }

      final planned = _plan(schedule, localTzName: localTzName, nowUtc: now);

      // Skip-if-unchanged: hash the computed set (ids + fire instants) and no-op
      // when byte-identical to the last one written this process.
      final hash = _hashPlanned(planned);
      if (hash == _lastScheduledHash) {
        // Still advance the throttle clock so an unchanged set doesn't allow a
        // burst of full recomputes on the next N calls.
        _lastReschedule = now;
        return;
      }

      await _cancelDuaBand();

      final location = _resolveLocation(localTzName);
      for (final p in planned) {
        await _scheduleOne(p, location);
      }

      _lastScheduledHash = hash;
      _lastReschedule = now;
    } catch (error) {
      // Degrade silently — a reminder must never crash or surface (plan §4).
      debugPrint('[DuaNotificationScheduler] reschedule failed: $error');
    }
  }

  /// Cancel only the duʿā band (opt-out / sign-out). Never [cancelAll].
  /// Resets the guards so the next [reschedule] rebuilds from scratch.
  Future<void> cancelAllDuaNotifications() async {
    try {
      await _cancelDuaBand();
      _lastScheduledHash = null;
      _lastReschedule = null;
    } catch (error) {
      debugPrint('[DuaNotificationScheduler] cancel failed: $error');
    }
  }

  /// Count of currently-pending notifications inside the reserved dua band.
  /// Walks [FlutterLocalNotificationsPlugin.pendingNotificationRequests] and
  /// counts only band members (FOREIGN ids — OneSignal's etc. — are excluded).
  /// Used by Dev Tools to confirm a reschedule landed. Returns 0 on any error.
  Future<int> pendingDuaCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.where((req) => _isDuaId(req.id)).length;
    } catch (error) {
      debugPrint('[DuaNotificationScheduler] pendingDuaCount failed: $error');
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Planning (pure)
  // ---------------------------------------------------------------------------

  /// Compute the capped, deterministic-id set of notifications to schedule.
  /// Visible-for-test via [debugPlan].
  List<_PlannedNotification> _plan(
    DuaWindowSchedule schedule, {
    required String localTzName,
    required DateTime nowUtc,
  }) {
    final location = _resolveLocation(localTzName);

    // Calendar windows only. Precise (location-dependent) windows are the
    // server-push path — never schedule them locally (plan §2 / §4).
    final calendar = <DuaWindow>[
      for (final w in schedule.upcoming)
        if (!w.locationDependent) w,
    ];

    // Build one planned entry per window at its computed fire instant, keyed by
    // a deterministic reserved-band id. De-dup by id (day-walking can emit the
    // same window twice).
    final byId = <int, _PlannedNotification>{};
    for (final w in calendar) {
      final fire = _fireInstant(w, location, nowUtc);
      if (fire == null) continue; // already past → skip
      final id = _idFor(w, location);
      // Keep the earliest-firing entry on an id collision (deterministic).
      final existing = byId[id];
      if (existing == null || fire.isBefore(existing.fireUtc)) {
        byId[id] = _PlannedNotification(id: id, fireUtc: fire, window: w);
      }
    }

    final planned = byId.values.toList();

    // Hard cap: keep the highest-priority windows; drop the lowest.
    if (planned.length > _maxScheduled) {
      planned.sort((a, b) {
        final byPriority = DuaWindowEngine.priorityOf(b.window.type)
            .compareTo(DuaWindowEngine.priorityOf(a.window.type));
        if (byPriority != 0) return byPriority;
        // Tie-break by earliest fire, then id, for full determinism.
        final byFire = a.fireUtc.compareTo(b.fireUtc);
        if (byFire != 0) return byFire;
        return a.id.compareTo(b.id);
      });
      planned.removeRange(_maxScheduled, planned.length);
    }

    // Stable output order (by fire, then id) so hashing + tests are
    // deterministic regardless of map iteration order.
    planned.sort((a, b) {
      final byFire = a.fireUtc.compareTo(b.fireUtc);
      if (byFire != 0) return byFire;
      return a.id.compareTo(b.id);
    });
    return planned;
  }

  /// Visible-for-test: the pure planned set (ids, fire instants) for a schedule.
  @visibleForTesting
  List<MapEntry<int, DateTime>> debugPlan(
    DuaWindowSchedule schedule, {
    required String localTzName,
    DateTime? nowUtc,
  }) {
    final planned = _plan(
      schedule,
      localTzName: localTzName,
      nowUtc: (nowUtc ?? _clock()).toUtc(),
    );
    return [for (final p in planned) MapEntry(p.id, p.fireUtc)];
  }

  /// The UTC instant a window's reminder should fire.
  ///
  /// - All-day calendar windows have no clock time → anchor to
  ///   [_allDayFireHour] local on the window's local start day.
  /// - Non-all-day calendar windows (none exist today, but keep it correct) fire
  ///   at their own start instant.
  ///
  /// Returns null when the computed instant is already in the past.
  DateTime? _fireInstant(DuaWindow w, tz.Location loc, DateTime nowUtc) {
    final DateTime fireUtc;
    if (w.isAllDay) {
      // The window's startUtc is the device-local midnight of its start day
      // (engine contract). Convert to the target zone to recover that local
      // calendar day, then anchor the fire-hour in that zone.
      final localStart = tz.TZDateTime.from(w.startUtc, loc);
      final fire = tz.TZDateTime(
        loc,
        localStart.year,
        localStart.month,
        localStart.day,
        _allDayFireHour,
      );
      fireUtc = fire.toUtc();
    } else {
      fireUtc = w.startUtc.toUtc();
    }
    if (!fireUtc.isAfter(nowUtc)) return null;
    return fireUtc;
  }

  /// Deterministic reserved-band id: `kDuaIdBase + stableHash(type + localDate)`.
  ///
  /// The local date (not the UTC instant) is the key so the same calendar day in
  /// the same zone always maps to the same id across reschedules — idempotent,
  /// no duplicates.
  int _idFor(DuaWindow w, tz.Location loc) {
    final local = tz.TZDateTime.from(w.startUtc, loc);
    final localDate = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final key = '${w.type.wireName}|$localDate';
    return kDuaIdBase + _stableHash(key);
  }

  // ---------------------------------------------------------------------------
  // Plugin interaction
  // ---------------------------------------------------------------------------

  /// Cancel ONLY ids in the reserved dua band. Walks
  /// [FlutterLocalNotificationsPlugin.pendingNotificationRequests] so a FOREIGN
  /// pending id (OneSignal's, or any other feature's) SURVIVES. NEVER
  /// `cancelAll` (Issue 2 / Risk 7).
  Future<void> _cancelDuaBand() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final req in pending) {
      if (_isDuaId(req.id)) {
        await _plugin.cancel(req.id);
      }
    }
  }

  Future<void> _scheduleOne(_PlannedNotification p, tz.Location loc) async {
    final when = tz.TZDateTime.from(p.fireUtc, loc);
    // Resolve the seeded row's raw title *key* (e.g. `dua_window.white_days`)
    // into real, distinct display copy. The seed carries i18n keys, not
    // strings, so passing `titleKey` straight through would show the literal
    // key to the user. [DuaWindowCopyBook] is the single swap-point for a
    // localized lookup once the i18n slice lands (keyed by `type.wireName`).
    final copy = DuaWindowCopyBook.resolve(p.window.type);
    await _plugin.zonedSchedule(
      p.id,
      copy.title,
      copy.body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Route taps to /duas via the deep-link payload the click handler reads.
      payload: 'dua_window:${p.window.type.wireName}',
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        kDuaChannelId,
        kDuaChannelName,
        channelDescription: kDuaChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers (pure)
  // ---------------------------------------------------------------------------

  bool _isDuaId(int id) => id >= kDuaIdBase && id < kDuaIdBase + kDuaIdBandSize;

  tz.Location _resolveLocation(String localTzName) {
    try {
      return tz.getLocation(localTzName);
    } catch (_) {
      // Unknown/`local` label → fall back to the tz DB's local zone (set by
      // tz.setLocalLocation in main). Keeps scheduling correct if the caller
      // passes 'local' or a stale label.
      return tz.local;
    }
  }

  /// Hash the planned set (ids + fire instants) for the skip-if-unchanged guard.
  /// Order-independent-safe because [_plan] returns a stably-sorted list.
  int _hashPlanned(List<_PlannedNotification> planned) {
    return Object.hashAll([
      for (final p in planned) ...[p.id, p.fireUtc.millisecondsSinceEpoch],
    ]);
  }

  /// A deterministic, platform-independent 31-bit hash. `String.hashCode` is
  /// NOT stable across runs/isolates in Dart, so we roll a small FNV-1a variant
  /// masked to stay inside the band ([kDuaIdBandSize]).
  int _stableHash(String s) {
    var hash = 0x811c9dc5;
    for (final code in s.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash % kDuaIdBandSize;
  }
}
