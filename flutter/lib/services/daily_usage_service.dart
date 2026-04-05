import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Daily Usage Service
//
// Tracks how many times the user has used Reflect and Build-a-Dua today.
// Counts reset at midnight (date-keyed in SharedPreferences).
// Free limit: 3 uses/day each. Beyond that costs 1 token.
// ---------------------------------------------------------------------------

const int dailyFreeReflects = 3;
const int dailyFreeBuiltDuas = 3;

String _todayKey(String feature) {
  final now = DateTime.now();
  final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return 'daily_usage_${feature}_$date';
}

Future<int> getReflectUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_todayKey('reflect')) ?? 0;
}

Future<int> getBuiltDuaUsageToday() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_todayKey('built_dua')) ?? 0;
}

Future<bool> canReflectFree() async {
  final used = await getReflectUsageToday();
  return used < dailyFreeReflects;
}

Future<bool> canBuildDuaFree() async {
  final used = await getBuiltDuaUsageToday();
  return used < dailyFreeBuiltDuas;
}

Future<int> incrementReflectUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _todayKey('reflect');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  return updated;
}

Future<int> incrementBuiltDuaUsage() async {
  final prefs = await SharedPreferences.getInstance();
  final key = _todayKey('built_dua');
  final current = prefs.getInt(key) ?? 0;
  final updated = current + 1;
  await prefs.setInt(key, updated);
  return updated;
}

/// Returns how many free uses remain today for reflect.
Future<int> reflectFreeRemaining() async {
  final used = await getReflectUsageToday();
  return (dailyFreeReflects - used).clamp(0, dailyFreeReflects);
}

/// Returns how many free uses remain today for build-a-dua.
Future<int> builtDuaFreeRemaining() async {
  final used = await getBuiltDuaUsageToday();
  return (dailyFreeBuiltDuas - used).clamp(0, dailyFreeBuiltDuas);
}
