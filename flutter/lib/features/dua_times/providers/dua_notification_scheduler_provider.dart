import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_notification_scheduler.dart';
import 'package:sakina/services/dua_precise_sync_service.dart';
import 'package:sakina/services/dua_precise_sync_state_store.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/notification_service.dart';

/// Minimum spacing between server-push precise SYNCS — mirrors the local
/// scheduler's throttle idea (`kDuaRescheduleThrottle`). The gate's [apply]
/// fires on every card rebuild (foreground-resume / date-rollover / location
/// change); re-computing the 30-day precise horizon and round-tripping Supabase
/// that often is wasteful, so within this window a non-forced sync is skipped.
/// A forced [apply] (opt-in toggle, Dev Tools) bypasses it.
const Duration kDuaPreciseSyncThrottle = Duration(hours: 6);

/// Retry spacing after a FAILED sync. A Supabase blip should be retried on the
/// next foreground, not sat out for six hours — but not hammered either.
const Duration kDuaPreciseSyncRetryThrottle = Duration(minutes: 15);

/// Builds the precise-sync service from the app-wide engine/location services.
/// Null when the local scheduler is unavailable (web / tests without the
/// plugin) so the gate degrades to calendar-only, matching the scheduler
/// provider's own null-gating.
final duaPreciseSyncServiceProvider = Provider<DuaPreciseSyncService?>((ref) {
  final scheduler = ref.watch(duaNotificationSchedulerProvider);
  if (scheduler == null) return null;
  final repository = DuaWindowRepository();
  final locationService = LocationService();
  final engine = DuaWindowEngine(
    repository: repository,
    locationService: locationService,
  );
  return DuaPreciseSyncService(
    engine: engine,
    locationService: locationService,
  );
});

/// The app-wide [FlutterLocalNotificationsPlugin] instance.
///
/// `main.dart` initializes the plugin (tz DB + Darwin init) once at cold launch
/// and overrides this provider with that instance. When the override is absent
/// (web, or a test that doesn't wire it) this resolves to `null` and the
/// scheduler provider yields `null` — every caller no-ops safely.
final localNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin?>((ref) => null);

/// The calendar-window local scheduler, built over the app-wide plugin.
///
/// Null when the plugin is unavailable (web / not overridden) so callers can
/// short-circuit. The scheduler itself is a plain service (no Riverpod) — this
/// provider only wires it to the plugin, mirroring how `duaWindowProvider`
/// constructs the engine.
final duaNotificationSchedulerProvider =
    Provider<DuaNotificationScheduler?>((ref) {
  final plugin = ref.watch(localNotificationsPluginProvider);
  if (plugin == null) return null;
  return DuaNotificationScheduler(plugin: plugin);
});

/// Coordinates the opt-in gate between the built schedule and the local
/// scheduler. Kept as a plain, testable object: given a schedule, it reschedules
/// the calendar band ONLY when the `notify_dua_windows` preference is ON AND the
/// user is opted in to push; otherwise it clears the reserved band.
///
/// This is the single place the "should we schedule?" decision lives, reused by
/// both the [duaWindowProvider] rebuild hook and the Dev Tools test button.
class DuaNotificationGate {
  DuaNotificationGate({
    required DuaNotificationScheduler scheduler,
    required NotificationService notificationService,
    DuaPreciseSyncService? preciseSync,
    Duration preciseSyncThrottle = kDuaPreciseSyncThrottle,
    Duration preciseRetryThrottle = kDuaPreciseSyncRetryThrottle,
    DuaPreciseSyncStateStore? syncStateStore,
    DateTime Function()? clock,
  })  : _scheduler = scheduler,
        _notificationService = notificationService,
        _preciseSync = preciseSync,
        _preciseThrottle = preciseSyncThrottle,
        _retryThrottle = preciseRetryThrottle,
        _syncState =
            syncStateStore ?? SharedPreferencesDuaPreciseSyncStateStore(),
        _clock = clock ?? DateTime.now;

  /// Static analytics hook (mirrors [DuaWindowNotifier.onAnalyticsEvent]). Wired
  /// in `main.dart` to `analytics.track`; null in tests. Emits `dua_notif_synced`
  /// — the client-side denominator for the server `notification_sent{dua_window}`
  /// (so a drop in sends can be attributed to the cron vs. clients not syncing).
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  final DuaNotificationScheduler _scheduler;
  final NotificationService _notificationService;

  /// The server-push precise sync. Null when unavailable (web / no plugin) so
  /// the gate degrades to the local calendar path only.
  final DuaPreciseSyncService? _preciseSync;
  final Duration _preciseThrottle;
  final Duration _retryThrottle;
  final DuaPreciseSyncStateStore _syncState;
  final DateTime Function() _clock;

  /// Reschedule the calendar band from [schedule] AND sync the server-push
  /// precise instants when opted in AND the `notify_dua_windows` category is on;
  /// otherwise clear BOTH. Never throws — every branch degrades silently.
  ///
  /// [force] bypasses both the local scheduler's throttle and the precise-sync
  /// throttle (used when the user just toggled the opt-in, or from Dev Tools).
  Future<void> apply(DuaWindowSchedule schedule, {bool force = false}) async {
    try {
      final enabled = await _isEnabled();
      if (!enabled) {
        await _scheduler.cancelAllDuaNotifications();
        await _clearPrecise();
        return;
      }
      await _scheduler.reschedule(
        schedule,
        localTzName: schedule.computedAt.tz,
        force: force,
      );
      final syncResult = await _syncPrecise(
        force: force,
        locationPresent: schedule.computedAt.lat != null,
      );
      // Emit only when a sync actually RAN and did something (null =
      // throttle-skipped / no plugin; `skipped` = signed-out no-op). Naturally
      // rate-limited to ~once/6h/user + on toggles — the synced-instant volume
      // (`synced`/`cleared`/`failed`) that is the counterpart to the server
      // `notification_sent{dua_window}`.
      if (syncResult != null &&
          syncResult.outcome != DuaPreciseSyncOutcome.skipped) {
        onAnalyticsEvent?.call(AnalyticsEvents.duaNotifSynced, {
          AnalyticsEvents.propCount: syncResult.count,
          AnalyticsEvents.propOutcome: syncResult.outcome.name,
          AnalyticsEvents.propLocationPresent: syncResult.locationPresent,
          // Splits `retained` into "the user's location lapsed" vs a copy-book
          // bug, and marks the rare genuine `cleared`.
          if (syncResult.reason != null)
            AnalyticsEvents.propReason: syncResult.reason,
          // Per-sync join key to the server `notification_sent{dua_window}`
          // (present only on a `synced` outcome).
          if (syncResult.syncVersion != null)
            AnalyticsEvents.propSyncVersion: syncResult.syncVersion,
        });
      }
    } catch (error) {
      debugPrint('[DuaNotificationGate] apply failed: $error');
    }
  }

  /// Run the precise sync, honoring the throttle unless [force] — or unless the
  /// user's location capability just came back.
  ///
  /// **The transition check is the fix for the grant that never reached the
  /// server.** The old throttle stamped itself BEFORE awaiting the sync, so a
  /// no-location run at cold launch armed the full 6h window just as hard as a
  /// success. The user then tapped "Turn on", granted, the card rebuilt — and
  /// this returned null. The reporter's every recorded sync was `cleared`,
  /// never once `synced`, across two days on which a located schedule was built.
  ///
  /// It lives here rather than in `DuaWindowNotifier.rebuild()` on purpose: the
  /// Settings and Dev Tools paths call [apply] directly with a schedule the
  /// notifier never rebuilt, so a detector in the notifier would miss them
  /// entirely — and a persisted flag is durable across cold launches in a way
  /// the notifier's in-memory schedule cannot be.
  ///
  /// Returns null when nothing ran (no precise-sync available, or throttled) so
  /// [apply] emits nothing.
  Future<DuaPreciseSyncResult?> _syncPrecise({
    required bool force,
    required bool locationPresent,
  }) async {
    final sync = _preciseSync;
    if (sync == null) return null;
    final now = _clock().toUtc();
    final state = await _syncState.read();

    final regained = locationPresent && state.lastLocationPresent == false;
    final neverSynced = state.lastSyncedAt == null;
    final mustRun = force || regained || neverSynced;

    if (!mustRun) {
      final elapsed = now.difference(state.lastSyncedAt!);
      if (elapsed < _preciseThrottle) return null;
    }

    final result = await sync.sync();
    await _syncState.write(DuaPreciseSyncState(
      lastSyncedAt: _armFor(result.outcome, now),
      lastLocationPresent: result.locationPresent,
    ));
    return result;
  }

  /// When to pretend the last sync happened, so the next one is spaced by the
  /// right amount. Armed AFTER the sync and keyed on what it actually did.
  DateTime? _armFor(DuaPreciseSyncOutcome outcome, DateTime now) =>
      switch (outcome) {
        // Signed out — sign-in should sync immediately, so arm nothing.
        DuaPreciseSyncOutcome.skipped => null,
        // Transient; retry after the short window rather than in six hours.
        // Clamped: the two durations are independent constructor params, and a
        // retry >= throttle would put `lastSyncedAt` in the FUTURE, making
        // `elapsed` negative and the sync unreachable until a force or a regain.
        DuaPreciseSyncOutcome.failed => _preciseThrottle > _retryThrottle
            ? now.subtract(_preciseThrottle - _retryThrottle)
            : now.subtract(_preciseThrottle),
        DuaPreciseSyncOutcome.synced ||
        DuaPreciseSyncOutcome.cleared ||
        DuaPreciseSyncOutcome.retained =>
          now,
      };

  Future<void> _clearPrecise() async {
    final sync = _preciseSync;
    if (sync == null) return;
    // Reset the throttle so a later re-enable syncs immediately.
    await _syncState.clear();
    await sync.clear();
  }

  Future<bool> _isEnabled() async {
    if (!_notificationService.isOptedIn) return false;
    final prefs = await _notificationService.getNotificationPreferences();
    return prefs[notifyDuaWindowsTagKey] ?? true;
  }

  /// Clear the reserved dua band AND the synced precise rows unconditionally
  /// (toggle-off / opt-out). Fulfils the toggle-off symmetry (plan §6) — this
  /// is what deletes the user's `dua_precise_notifications` rows.
  Future<void> clear() async {
    await _scheduler.cancelAllDuaNotifications();
    await _clearPrecise();
  }
}

/// The gate over the current scheduler + notification service. Null when the
/// scheduler is unavailable (plugin not wired), so callers short-circuit.
final duaNotificationGateProvider = Provider<DuaNotificationGate?>((ref) {
  final scheduler = ref.watch(duaNotificationSchedulerProvider);
  if (scheduler == null) return null;
  return DuaNotificationGate(
    scheduler: scheduler,
    notificationService: ref.watch(notificationServiceProvider),
    preciseSync: ref.watch(duaPreciseSyncServiceProvider),
  );
});
