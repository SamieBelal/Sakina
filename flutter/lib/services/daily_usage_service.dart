import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Daily Usage Service
//
// Tracks how many times the user has used Reflect, Build-a-Dua, and
// Discover-Name today. Counts reset at midnight (date-keyed in
// SharedPreferences).
//
// Free limit: 1 use/day per AI feature (post-warm-up).
// See `gating_service.dart` for the policy layer that consults these counts.
// ---------------------------------------------------------------------------

const int dailyFreeReflects = 1;
const int dailyFreeBuiltDuas = 1;
const int dailyFreeDiscoverNames = 1;

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _todayKey(String feature) {
  return supabaseSyncService.scopedKey(
    'daily_usage_${feature}_${_today()}',
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

Future<void> _upsertToday(SharedPreferences prefs) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null) return;

  final reflectUses = prefs.getInt(_todayKey('reflect')) ?? 0;
  final builtDuaUses = prefs.getInt(_todayKey('built_dua')) ?? 0;
  final discoverNameUses = prefs.getInt(_todayKey('discover_name')) ?? 0;

  // Composite unique key: (user_id, usage_date). onConflict must name both
  // columns or PostgREST falls back to the PK and silently fails every
  // write after the first row for today's date.
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
