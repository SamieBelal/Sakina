/// The user's own calendar day, resolved from the **same** timezone source the
/// server uses (W3 plan §7a).
///
/// `unseal_next_name` is idempotent per *user-local* day, derived server-side
/// from `user_notification_preferences.timezone` via `safe_user_tz`. Anything on
/// the client that has to agree with that boundary — today only the discover-name
/// free-cap key — must resolve the day the same way, or a UTC-7 user who revealed
/// at 20:00 Monday local finds their Tuesday reveal blocked until 17:00 Tuesday
/// while the server unsealed their Tuesday Name at 00:00.
///
/// Fallback ladder, in order:
///   1. the process memo / scoped-prefs cache of a previously resolved zone
///   2. `user_notification_preferences.timezone` (server truth, client-written,
///      validated by W1 Migration A)
///   3. the device zone via `flutter_timezone`
///   4. UTC
///
/// Steps 2 and 3 agree in practice — `NotificationService.syncTimezoneToSupabase`
/// is what writes the server value, and it writes exactly the device zone — so
/// caching whichever resolves first cannot pin a wrong answer for long.
///
/// The clock is injectable, mirroring `debugDailyUsageClock` / `debugDailyLoopClock`
/// so day-boundary tests can pin a literal UTC instant instead of computing one.
library;

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:sakina/services/supabase_sync_service.dart';

/// Scoped prefs key holding the resolved IANA zone name.
const String userTimeZonePrefBaseKey = 'user_local_timezone';

/// Test seam mirroring `debugDailyUsageClock`. Always interpreted as UTC.
/// Production callers leave this null.
@visibleForTesting
DateTime Function()? debugUserLocalDayClock;

/// Test seam that short-circuits the whole resolution ladder with an IANA zone
/// name (e.g. `'America/Los_Angeles'`). Requires the tz database to have been
/// initialised — `initializeTimeZones()` from `package:timezone/data/latest_all.dart`,
/// which `main.dart` already calls on boot.
@visibleForTesting
String? debugUserTimeZoneOverride;

String? _memoZone;

/// The user [_memoZone] was resolved for.
///
/// Without this the process-global memo outlives the account. Both
/// [_readCachedZone] and [cacheUserTimeZone] re-check `currentUserId` around
/// their async prefs hop, but the memo short-circuits ahead of them — so on a
/// sign-out → sign-in-as-someone-else within one process (a routine QA flow, and
/// the reason `auth_service_signout_clear_prefs_test.dart` exists) the second
/// user inherited the first user's zone. Clearing prefs on sign-out does not
/// help, because a process global is not prefs, and `debugResetUserLocalDay` has
/// no production caller. Every consumer of the resolved zone — the daily-cap key,
/// `planQueueReveal(localUtcOffset:)`, and rule 2's same-local-day comparison —
/// would then compute in the wrong timezone, silently, and America/Los_Angeles to
/// Asia/Karachi is far enough to be a whole day out.
String? _memoUserId;

/// The user's calendar day plus the offset that produced it.
class UserLocalDay {
  const UserLocalDay({
    required this.day,
    required this.utcOffset,
    required this.timeZoneName,
  });

  /// Date-only, expressed as `DateTime.utc(y, m, d)` so it compares and prints
  /// deterministically. This is a *calendar date*, not an instant.
  final DateTime day;

  /// The zone's offset from UTC in effect at the resolving instant. Fed to
  /// `planQueueReveal(localUtcOffset:)` so it can map a row's UTC `unsealed_at`
  /// onto [day].
  final Duration utcOffset;

  /// The resolved IANA zone, or `'UTC'` when nothing better was available.
  final String timeZoneName;

  /// `YYYY-MM-DD`, the shape every date-keyed pref in the repo uses.
  String get dateString =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

/// Resolves the user's current calendar day and the offset behind it.
Future<UserLocalDay> resolveUserLocalDay({DateTime Function()? clock}) async {
  final nowUtc = _nowUtc(clock);
  final zone = await resolveUserTimeZone();
  return _localDayIn(zone, nowUtc);
}

/// The user's current calendar day, date-only. Thin wrapper over
/// [resolveUserLocalDay] for callers that don't need the offset.
Future<DateTime> userLocalDay({DateTime Function()? clock}) async =>
    (await resolveUserLocalDay(clock: clock)).day;

/// `YYYY-MM-DD` of [userLocalDay].
Future<String> userLocalDayString({DateTime Function()? clock}) async =>
    (await resolveUserLocalDay(clock: clock)).dateString;

/// Walks the fallback ladder once and memoises the result for the process.
/// Returns `'UTC'` when no zone could be resolved.
Future<String> resolveUserTimeZone() async {
  final override = debugUserTimeZoneOverride;
  if (override != null && override.isNotEmpty) return override;

  // Scoped to the account that produced it — see [_memoUserId].
  final uid = supabaseSyncService.currentUserId;
  final memo = _memoZone;
  if (memo != null && _memoUserId == uid) return memo;

  final cached = await _readCachedZone();
  if (cached != null && cached.isNotEmpty) {
    _memoZone = cached;
    _memoUserId = uid;
    return cached;
  }

  final serverZone = await _readServerZone();
  if (serverZone != null && serverZone.isNotEmpty) {
    _memoZone = serverZone;
    _memoUserId = uid;
    await cacheUserTimeZone(serverZone);
    return serverZone;
  }

  final deviceZone = await _readDeviceZone();
  if (deviceZone != null && deviceZone.isNotEmpty) {
    _memoZone = deviceZone;
    _memoUserId = uid;
    await cacheUserTimeZone(deviceZone);
    return deviceZone;
  }

  // Not memoised: UTC is a "couldn't resolve" answer, not a resolution, and the
  // next call may well succeed (a signed-out boot, a cold plugin channel).
  return 'UTC';
}

/// Writes the resolved zone to scoped prefs. Call after syncing the device zone
/// to `user_notification_preferences` so the two never disagree.
Future<void> cacheUserTimeZone(String zoneName) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return;
  await prefs.setString('$userTimeZonePrefBaseKey:$userId', zoneName);
  _memoZone = zoneName;
  _memoUserId = userId;
}

@visibleForTesting
void debugResetUserLocalDay() {
  _memoZone = null;
  _memoUserId = null;
  debugUserLocalDayClock = null;
  debugUserTimeZoneOverride = null;
}

DateTime _nowUtc(DateTime Function()? clock) {
  final resolved = clock ?? debugUserLocalDayClock;
  return (resolved == null ? DateTime.now() : resolved()).toUtc();
}

UserLocalDay _localDayIn(String zoneName, DateTime nowUtc) {
  if (zoneName != 'UTC') {
    try {
      final local = tz.TZDateTime.from(nowUtc, tz.getLocation(zoneName));
      return UserLocalDay(
        day: DateTime.utc(local.year, local.month, local.day),
        utcOffset: local.timeZoneOffset,
        timeZoneName: zoneName,
      );
    } catch (e) {
      // Unknown zone, or the tz database was never initialised (a unit test, or
      // a boot path that skipped `initializeTimeZones()`). Degrade to UTC —
      // which is exactly today's behaviour — rather than fail a reveal.
      debugPrint('[user_local_day] zone "$zoneName" unusable, using UTC: $e');
    }
  }
  return UserLocalDay(
    day: DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day),
    utcOffset: Duration.zero,
    timeZoneName: 'UTC',
  );
}

Future<String?> _readCachedZone() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return null;
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return null;
  return prefs.getString('$userTimeZonePrefBaseKey:$userId');
}

Future<String?> _readServerZone() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return null;
  try {
    final row = await supabaseSyncService.fetchRow(
      'user_notification_preferences',
      userId,
      columns: 'timezone',
    );
    return row?['timezone'] as String?;
  } catch (e) {
    debugPrint('[user_local_day] server timezone read failed: $e');
    return null;
  }
}

Future<String?> _readDeviceZone() async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (e) {
    // MissingPluginException under `flutter test`, and a genuine platform
    // failure on device. Either way the ladder continues to UTC.
    debugPrint('[user_local_day] device timezone read failed: $e');
    return null;
  }
}
