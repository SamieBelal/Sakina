import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/services/dua_notification_scheduler.dart';
import 'package:sakina/services/notification_service.dart';

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
  })  : _scheduler = scheduler,
        _notificationService = notificationService;

  final DuaNotificationScheduler _scheduler;
  final NotificationService _notificationService;

  /// Reschedule the calendar band from [schedule] when opted in AND the
  /// `notify_dua_windows` category is on; otherwise clear the band. Never
  /// throws — every branch degrades silently.
  Future<void> apply(DuaWindowSchedule schedule, {bool force = false}) async {
    try {
      final enabled = await _isEnabled();
      if (!enabled) {
        await _scheduler.cancelAllDuaNotifications();
        return;
      }
      await _scheduler.reschedule(
        schedule,
        localTzName: schedule.computedAt.tz,
        force: force,
      );
    } catch (error) {
      debugPrint('[DuaNotificationGate] apply failed: $error');
    }
  }

  Future<bool> _isEnabled() async {
    if (!_notificationService.isOptedIn) return false;
    final prefs = await _notificationService.getNotificationPreferences();
    return prefs[notifyDuaWindowsTagKey] ?? true;
  }

  /// Clear the reserved dua band unconditionally (toggle-off / opt-out).
  Future<void> clear() => _scheduler.cancelAllDuaNotifications();
}

/// The gate over the current scheduler + notification service. Null when the
/// scheduler is unavailable (plugin not wired), so callers short-circuit.
final duaNotificationGateProvider = Provider<DuaNotificationGate?>((ref) {
  final scheduler = ref.watch(duaNotificationSchedulerProvider);
  if (scheduler == null) return null;
  return DuaNotificationGate(
    scheduler: scheduler,
    notificationService: ref.watch(notificationServiceProvider),
  );
});
