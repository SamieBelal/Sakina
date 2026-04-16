import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/achievement_toast.dart';
import 'supabase_sync_service.dart';

const String notifyDailyTagKey = 'notify_daily';
const String notifyStreakTagKey = 'notify_streak';
const String notifyReengagementTagKey = 'notify_reengagement';
const String notifyWeeklyTagKey = 'notify_weekly';
const String notifyUpdatesTagKey = 'notify_updates';

const List<String> notificationPreferenceTagKeys = <String>[
  notifyDailyTagKey,
  notifyStreakTagKey,
  notifyReengagementTagKey,
  notifyWeeklyTagKey,
  notifyUpdatesTagKey,
];

const String _pushEnabledCacheKey = 'sakina_notifications_push_enabled';
const String _preferenceCachePrefix = 'sakina_notification_pref_';

typedef NotificationRouteNavigator = void Function(String route);

class NotificationClickEventData {
  const NotificationClickEventData({required this.additionalData});

  final Map<String, dynamic>? additionalData;
}

class NotificationForegroundEventData {
  const NotificationForegroundEventData({
    required this.additionalData,
    required this.preventDefault,
    required this.display,
  });

  final Map<String, dynamic>? additionalData;
  final VoidCallback preventDefault;
  final VoidCallback display;
}

abstract class OneSignalClient {
  Future<void> initialize(String appId);
  Future<void> login(String userId);
  Future<void> logout();
  Future<bool> requestPermission(bool fallbackToSettings);
  bool get isPermissionGranted;
  Future<void> optIn();
  Future<void> optOut();
  bool? get isOptedIn;
  void addForegroundListener(
    void Function(NotificationForegroundEventData event) listener,
  );
  void addClickListener(
      void Function(NotificationClickEventData event) listener);
}

class RealOneSignalClient implements OneSignalClient {
  @override
  Future<void> initialize(String appId) => OneSignal.initialize(appId);

  @override
  Future<void> login(String userId) => OneSignal.login(userId);

  @override
  Future<void> logout() => OneSignal.logout();

  @override
  Future<bool> requestPermission(bool fallbackToSettings) {
    return OneSignal.Notifications.requestPermission(fallbackToSettings);
  }

  @override
  bool get isPermissionGranted => OneSignal.Notifications.permission;

  @override
  Future<void> optIn() => OneSignal.User.pushSubscription.optIn();

  @override
  Future<void> optOut() => OneSignal.User.pushSubscription.optOut();

  @override
  bool? get isOptedIn => OneSignal.User.pushSubscription.optedIn;

  @override
  void addForegroundListener(
    void Function(NotificationForegroundEventData event) listener,
  ) {
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      listener(
        NotificationForegroundEventData(
          additionalData: event.notification.additionalData,
          preventDefault: event.preventDefault,
          display: event.notification.display,
        ),
      );
    });
  }

  @override
  void addClickListener(
      void Function(NotificationClickEventData event) listener) {
    OneSignal.Notifications.addClickListener((event) {
      listener(
        NotificationClickEventData(
          additionalData: event.notification.additionalData,
        ),
      );
    });
  }
}

class NotificationService {
  NotificationService({
    OneSignalClient? client,
    Future<SharedPreferences> Function()? sharedPreferencesLoader,
    NotificationRouteNavigator? routeNavigator,
  })  : _client = client ?? RealOneSignalClient(),
        _sharedPreferencesLoader =
            sharedPreferencesLoader ?? SharedPreferences.getInstance,
        _routeNavigator = routeNavigator ?? _defaultRouteNavigator;

  final OneSignalClient _client;
  final Future<SharedPreferences> Function() _sharedPreferencesLoader;
  final NotificationRouteNavigator _routeNavigator;

  bool _initialized = false;
  bool _foregroundListenerAdded = false;
  bool _clickListenerAdded = false;
  bool _cachedOptedIn = false;
  String? _identifiedUserId;

  Future<void> initialize(String appId) async {
    _cachedOptedIn = await _readCachedPushEnabled();
    if (appId.isEmpty) return;

    await _client.initialize(appId);
    _initialized = true;
    _cachedOptedIn = _client.isOptedIn ?? _cachedOptedIn;
    await _writeCachedPushEnabled(_cachedOptedIn);
  }

  Future<void> identifyUser(String userId) async {
    if (!_initialized || userId.isEmpty) return;
    if (_identifiedUserId == userId) return;

    try {
      await _client.login(userId);
      _identifiedUserId = userId;
    } catch (error) {
      debugPrint('notification identifyUser failed: $error');
      rethrow;
    }
  }

  Future<void> logout() async {
    if (!_initialized) return;

    try {
      await _client.logout();
      _identifiedUserId = null;
    } catch (error) {
      debugPrint('notification logout failed: $error');
      rethrow;
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    try {
      final granted = await _client.requestPermission(true);
      if (granted) {
        _cachedOptedIn = true;
        await _writeCachedPushEnabled(true);
      }
      return granted;
    } catch (error) {
      debugPrint('notification requestPermission failed: $error');
      return false;
    }
  }

  bool get isPermissionGranted => _client.isPermissionGranted;

  /// Enable push delivery for this user. Server-side only — does NOT call
  /// OneSignal's pushSubscription.optOut/optIn. The OneSignal SDK's opt-out
  /// cycle orphans the external_id alias in a way we can't reliably recover
  /// from in-session, so we keep the subscription permanently opted in and
  /// gate delivery via the `push_enabled` column in Supabase.
  ///
  /// If the OS push permission isn't granted, this triggers the iOS prompt.
  Future<bool> optIn() async {
    if (!_initialized) return false;

    var granted = _client.isPermissionGranted;
    if (!granted) {
      granted = await requestPermission();
      if (!granted) {
        _cachedOptedIn = false;
        await _writeCachedPushEnabled(false);
        await _writePushEnabledToSupabase(false);
        return false;
      }
    }

    _cachedOptedIn = true;
    await _writeCachedPushEnabled(true);
    await _writePushEnabledToSupabase(true);
    return true;
  }

  /// Disable push delivery for this user. Writes `push_enabled = false` to
  /// Supabase. The edge function's RPC filters on `push_enabled`, so no
  /// scheduled notifications reach this user. Dashboard-sent messages can
  /// still reach the device unless they target a segment that filters on
  /// `push_enabled` or similar.
  Future<bool> optOut() async {
    _cachedOptedIn = false;
    await _writeCachedPushEnabled(false);
    await _writePushEnabledToSupabase(false);
    return false;
  }

  bool get isOptedIn => _cachedOptedIn;

  Future<void> _writePushEnabledToSupabase(bool enabled) async {
    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;
    await supabaseSyncService.upsertRow(
      'user_notification_preferences',
      userId,
      <String, dynamic>{'push_enabled': enabled},
    );
  }

  Future<void> setNotificationPreference(String key, bool enabled) async {
    if (!notificationPreferenceTagKeys.contains(key)) {
      throw ArgumentError.value(
          key, 'key', 'Unsupported notification preference');
    }

    // Write to local cache first (always works, even offline)
    final prefs = await _sharedPreferencesLoader();
    await prefs.setBool(
      _scopedPreferenceCacheKey(key),
      enabled,
    );

    // Sync to Supabase (server-side truth for edge function targeting)
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      await supabaseSyncService.upsertRow(
        'user_notification_preferences',
        userId,
        <String, dynamic>{key: enabled},
      );
    }
  }

  Future<Map<String, bool>> getNotificationPreferences() async {
    final cached = await _readCachedNotificationPreferences();

    // Try Supabase first (server truth), then fall back to local cache.
    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      try {
        final row = await supabaseSyncService.fetchRow(
          'user_notification_preferences',
          userId,
          columns: [
            'push_enabled',
            notifyDailyTagKey,
            notifyStreakTagKey,
            notifyReengagementTagKey,
            notifyWeeklyTagKey,
            notifyUpdatesTagKey,
          ].join(','),
        );
        if (row != null) {
          final serverPushEnabled = row['push_enabled'] as bool? ?? true;
          _cachedOptedIn = serverPushEnabled;
          await _writeCachedPushEnabled(serverPushEnabled);

          final preferences = <String, bool>{
            notifyDailyTagKey: row[notifyDailyTagKey] as bool? ?? true,
            notifyStreakTagKey: row[notifyStreakTagKey] as bool? ?? true,
            notifyReengagementTagKey:
                row[notifyReengagementTagKey] as bool? ?? true,
            notifyWeeklyTagKey: row[notifyWeeklyTagKey] as bool? ?? true,
            notifyUpdatesTagKey: row[notifyUpdatesTagKey] as bool? ?? true,
          };
          // Update local cache
          final prefs = await _sharedPreferencesLoader();
          for (final entry in preferences.entries) {
            await prefs.setBool(
                _scopedPreferenceCacheKey(entry.key), entry.value);
          }
          return preferences;
        }
      } catch (error) {
        debugPrint('notification getPreferences from Supabase failed: $error');
      }
    }

    return cached;
  }

  /// For returning users after reinstall: if the server shows they previously
  /// had notifications enabled but the device doesn't have permission, request it.
  Future<void> requestPermissionIfPreviouslyEnabled() async {
    if (!_initialized) return;
    if (_client.isPermissionGranted) return;

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;

    try {
      final row = await supabaseSyncService.fetchRow(
        'user_notification_preferences',
        userId,
        columns: [
          notifyDailyTagKey,
          notifyStreakTagKey,
          notifyReengagementTagKey,
          notifyWeeklyTagKey,
          notifyUpdatesTagKey,
        ].join(','),
      );
      if (row == null) return;

      final hadNotificationsOn = (row[notifyDailyTagKey] as bool? ?? false) ||
          (row[notifyStreakTagKey] as bool? ?? false) ||
          (row[notifyReengagementTagKey] as bool? ?? false) ||
          (row[notifyWeeklyTagKey] as bool? ?? false) ||
          (row[notifyUpdatesTagKey] as bool? ?? false);
      if (!hadNotificationsOn) return;

      await requestPermission();
    } catch (error) {
      debugPrint(
          'notification requestPermissionIfPreviouslyEnabled failed: $error');
    }
  }

  /// Sync the user's IANA timezone to Supabase for server-side scheduling.
  /// Call on app open / after auth.
  Future<void> syncTimezone() async {
    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;

    try {
      final timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
      await supabaseSyncService.upsertRow(
        'user_notification_preferences',
        userId,
        <String, dynamic>{'timezone': timezone},
      );
    } catch (error) {
      debugPrint('notification syncTimezone failed: $error');
    }
  }

  void addForegroundListener() {
    if (!_initialized || _foregroundListenerAdded) return;
    _foregroundListenerAdded = true;

    _client.addForegroundListener((event) {
      event.preventDefault();
      event.display();
    });
  }

  void addClickListener() {
    if (!_initialized || _clickListenerAdded) return;
    _clickListenerAdded = true;

    _client.addClickListener((event) {
      _routeNavigator(routeForNotificationType(_notificationTypeFromData(
        event.additionalData,
      )));
    });
  }

  @visibleForTesting
  static String routeForNotificationType(String? type) {
    switch (type) {
      case 'weekly_reflection':
        return '/journal';
      case 'daily_reminder':
      case 'streak_risk':
      case 'streak_milestone':
      case 'reengagement':
      case 'update':
      default:
        return '/';
    }
  }

  String? _notificationTypeFromData(Map<String, dynamic>? additionalData) {
    final rawType = additionalData?['type'];
    if (rawType is String && rawType.isNotEmpty) return rawType;
    if (rawType == null) return null;
    return rawType.toString();
  }

  Future<bool> _readCachedPushEnabled() async {
    final prefs = await _sharedPreferencesLoader();
    return prefs.getBool(_scopedPushEnabledKey) ?? false;
  }

  Future<void> _writeCachedPushEnabled(bool enabled) async {
    final prefs = await _sharedPreferencesLoader();
    await prefs.setBool(_scopedPushEnabledKey, enabled);
  }

  String get _scopedPushEnabledKey =>
      supabaseSyncService.scopedKey(_pushEnabledCacheKey);

  Future<Map<String, bool>> _readCachedNotificationPreferences() async {
    final prefs = await _sharedPreferencesLoader();
    return <String, bool>{
      notifyDailyTagKey:
          prefs.getBool(_scopedPreferenceCacheKey(notifyDailyTagKey)) ?? true,
      notifyStreakTagKey:
          prefs.getBool(_scopedPreferenceCacheKey(notifyStreakTagKey)) ?? true,
      notifyReengagementTagKey:
          prefs.getBool(_scopedPreferenceCacheKey(notifyReengagementTagKey)) ??
              true,
      notifyWeeklyTagKey:
          prefs.getBool(_scopedPreferenceCacheKey(notifyWeeklyTagKey)) ?? true,
      notifyUpdatesTagKey:
          prefs.getBool(_scopedPreferenceCacheKey(notifyUpdatesTagKey)) ?? true,
    };
  }

  String _scopedPreferenceCacheKey(String key) {
    return supabaseSyncService.scopedKey('$_preferenceCachePrefix$key');
  }

  static void _defaultRouteNavigator(String route) {
    void navigate() {
      final context = rootNavigatorKey.currentContext;
      if (context == null) return;
      GoRouter.of(context).go(route);
    }

    if (rootNavigatorKey.currentContext != null) {
      navigate();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigate();
    });
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
