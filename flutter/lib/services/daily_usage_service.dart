import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Daily Usage Service
//
// Tracks how many times the user has used Reflect, Build-a-Dua, and
// Discover-Name today, plus how many AI-bypass spends they've made on each
// feature. Counts reset at midnight (date-keyed in SharedPreferences).
//
// Free limit: 1 use/day per AI feature (post-warm-up).
// See `gating_service.dart` for the policy layer that consults these counts.
//
// Daily counter semantics (after 2026-05-23 AI-bypass plan):
//
//   reflect_uses_today       = free_used + bypasses_consumed_today  (cap 1 + 2 = 3)
//   reflect_bypasses_used    = bypasses_consumed_today only         (cap 2)
//   free_remaining_today     = 1 - min(reflect_uses_today, 1)
//   bypasses_remaining_today = 2 - reflect_bypasses_used
//
// Same shape for built_dua and discover_name. The two counters are related
// but distinct — the bypass counter is a strict subset of total uses, and
// reservations that get cancelled (AI failure, orphan-cron rescue) decrement
// BOTH counters via the cancel_ai_bypass RPC.
// ---------------------------------------------------------------------------

const int dailyFreeReflects = 1;
const int dailyFreeBuiltDuas = 1;
const int dailyFreeDiscoverNames = 1;

/// Debug seam mirroring `debugRewardsClock` and `debugLaunchGateClock` so
/// tests can pin a known UTC instant. Always returns UTC.
///
/// Production callers should leave this null. The default reads
/// `DateTime.now().toUtc()` to match the server (Supabase stores
/// user_daily_usage.usage_date in UTC, set via `timezone('utc', now())`).
///
/// Previously this used `DateTime.now()` (local), which caused the
/// client cap state to disagree with the server near local-but-not-UTC
/// midnight (e.g. 11pm EDT). Same regression class as the
/// daily-launch overlay UTC fix in PR #8 — see CLAUDE.md Known Bugs.
@visibleForTesting
DateTime Function()? debugDailyUsageClock;

DateTime _nowUtc() =>
    (debugDailyUsageClock ?? () => DateTime.now().toUtc())();

String _today() {
  final now = _nowUtc();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _todayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_usage_${feature}_${_today()}',
  );
}

String _bypassTodayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_bypass_${feature}_${_today()}',
  );
}

Future<int> getReflectUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_todayKey('reflect')) ?? 0;
}

Future<int> getBuiltDuaUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_todayKey('built_dua')) ?? 0;
}

Future<int> getDiscoverNameUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_todayKey('discover_name')) ?? 0;
}

Future<int> getReflectBypassesUsedToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_bypassTodayKey('reflect')) ?? 0;
}

Future<int> getBuiltDuaBypassesUsedToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_bypassTodayKey('built_dua')) ?? 0;
}

Future<int> getDiscoverNameBypassesUsedToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_bypassTodayKey('discover_name')) ?? 0;
}

Future<int> incrementReflectUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _todayKey('reflect');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  await _upsertToday(prefs);
  return updated;
}

Future<int> incrementBuiltDuaUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _todayKey('built_dua');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  await _upsertToday(prefs);
  return updated;
}

Future<int> incrementDiscoverNameUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _todayKey('discover_name');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  await _upsertToday(prefs);
  return updated;
}

// Bypass counter increment / decrement are LOCAL-CACHE mirrors. The server
// is the source of truth — `reserve_ai_bypass` / `cancel_ai_bypass` RPCs
// mutate the underlying user_daily_usage row atomically with the token
// debit/refund. These helpers exist so the DailyCapSheet renders the
// updated CTA state without waiting for a sync_all round-trip.
Future<int> incrementReflectBypassUsage() =>
    _incrementBypass('reflect');
Future<int> incrementBuiltDuaBypassUsage() =>
    _incrementBypass('built_dua');
Future<int> incrementDiscoverNameBypassUsage() =>
    _incrementBypass('discover_name');

Future<int> decrementReflectBypassUsage() =>
    _decrementBypass('reflect');
Future<int> decrementBuiltDuaBypassUsage() =>
    _decrementBypass('built_dua');
Future<int> decrementDiscoverNameBypassUsage() =>
    _decrementBypass('discover_name');

Future<int> _incrementBypass(String feature) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _bypassTodayKey(feature);
  final updated = (prefs.getInt(key) ?? 0) + 1;
  await prefs.setInt(key, updated);
  return updated;
}

Future<int> _decrementBypass(String feature) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _bypassTodayKey(feature);
  final current = prefs.getInt(key) ?? 0;
  final updated = (current - 1).clamp(0, current);
  await prefs.setInt(key, updated);
  return updated;
}

Future<void> _upsertToday(SharedPreferences prefs) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final reflectUses = prefs.getInt(_todayKey('reflect')) ?? 0;
  final builtDuaUses = prefs.getInt(_todayKey('built_dua')) ?? 0;
  final discoverNameUses = prefs.getInt(_todayKey('discover_name')) ?? 0;

  // Composite unique key: (user_id, usage_date). onConflict must name both
  // columns or PostgREST falls back to the PK and silently fails every
  // write after the first row for today's date.
  //
  // Bypass counters are NOT written here. They are owned exclusively by the
  // reserve_ai_bypass / cancel_ai_bypass RPCs (server-side, transactional).
  // Including them in this client-side upsert would race those RPCs and
  // clobber the server's authoritative count.
  await supabaseSyncService.upsertRow(
    'user_daily_usage',
    userId,
    {
      'usage_date': _today(),
      'reflect_uses': reflectUses,
      'built_dua_uses': builtDuaUses,
      'discover_name_uses': discoverNameUses,
    },
    onConflict: 'user_id,usage_date',
  );
}

Future<void> hydrateDailyUsageCacheFromPayload(
  Map<String, dynamic> section,
) async {
  final prefs = await SharedPreferences.getInstance();
  final serverReflect = (section['reflect_uses'] as num?)?.toInt();
  final serverBuiltDua = (section['built_dua_uses'] as num?)?.toInt();
  final serverDiscoverName = (section['discover_name_uses'] as num?)?.toInt();
  if (serverReflect != null) {
    await prefs.setInt(_todayKey('reflect'), serverReflect);
  }
  if (serverBuiltDua != null) {
    await prefs.setInt(_todayKey('built_dua'), serverBuiltDua);
  }
  if (serverDiscoverName != null) {
    await prefs.setInt(_todayKey('discover_name'), serverDiscoverName);
  }
  // TEST-B regression-pin (plan 2026-05-23): without bypass-counter
  // hydration, a multi-device user (or a fresh reinstall) would see a stale
  // DailyCapSheet — the bypass CTA could render as enabled when the server
  // already shows bypasses_used >= 2.
  final serverReflectBypass =
      (section['reflect_bypasses_used'] as num?)?.toInt();
  final serverBuiltDuaBypass =
      (section['built_dua_bypasses_used'] as num?)?.toInt();
  final serverDiscoverNameBypass =
      (section['discover_name_bypasses_used'] as num?)?.toInt();
  if (serverReflectBypass != null) {
    await prefs.setInt(_bypassTodayKey('reflect'), serverReflectBypass);
  }
  if (serverBuiltDuaBypass != null) {
    await prefs.setInt(_bypassTodayKey('built_dua'), serverBuiltDuaBypass);
  }
  if (serverDiscoverNameBypass != null) {
    await prefs.setInt(
      _bypassTodayKey('discover_name'),
      serverDiscoverNameBypass,
    );
  }
}

Map<String, dynamic>? _findTodayUsageRow(List<Map<String, dynamic>> rows) {
  final today = _today();
  return rows.cast<Map<String, dynamic>?>().firstWhere(
        (row) => row?['usage_date'] == today,
        orElse: () => null,
      );
}

Future<void> hydrateDailyUsageCacheFromRows(
  List<Map<String, dynamic>> rows,
) async {
  final todayRow = _findTodayUsageRow(rows);
  if (todayRow == null) return;
  await hydrateDailyUsageCacheFromPayload(todayRow);
}

Future<void> seedDailyUsageToSupabaseFromLocalCache() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final prefs = await SharedPreferences.getInstance();
  final reflectUses = prefs.getInt(_todayKey('reflect')) ?? 0;
  final builtDuaUses = prefs.getInt(_todayKey('built_dua')) ?? 0;
  final discoverNameUses = prefs.getInt(_todayKey('discover_name')) ?? 0;
  if (reflectUses <= 0 && builtDuaUses <= 0 && discoverNameUses <= 0) return;

  await supabaseSyncService.upsertRow(
    'user_daily_usage',
    userId,
    {
      'usage_date': _today(),
      'reflect_uses': reflectUses,
      'built_dua_uses': builtDuaUses,
      'discover_name_uses': discoverNameUses,
    },
    onConflict: 'user_id,usage_date',
  );
}

/// Hydrate local daily usage cache from Supabase for today's date.
/// If server has data, it becomes source of truth. If server empty and
/// local has counts, seed server from local.
Future<void> syncDailyUsageFromSupabase() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  // Server row keyed by user_id AND usage_date. fetchRow only supports user_id,
  // so we use fetchRows + filter by usage_date client-side.
  final rows = await supabaseSyncService.fetchRows(
    'user_daily_usage',
    userId,
    orderBy: 'usage_date',
  );

  if (_findTodayUsageRow(rows) == null) {
    await seedDailyUsageToSupabaseFromLocalCache();
    return;
  }
  await hydrateDailyUsageCacheFromRows(rows);
}
