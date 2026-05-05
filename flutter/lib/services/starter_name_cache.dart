import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sakina/services/supabase_sync_service.dart';

/// Scoped SharedPreferences key for the user's starter Name catalog id.
///
/// Cached locally so the home greeting (`DailyLaunchOverlay`) can render the
/// starter Name synchronously without waiting for a Supabase round-trip on
/// every overlay mount. Without this cache the FutureProvider's loading
/// state shows `getTodaysName()` as a fallback for a few hundred ms,
/// flickering to the correct Name once the query resolves.
const String starterNamePrefBaseKey = 'starter_name_id';

/// Returns the cached starter Name catalog id for the signed-in user, or
/// null if no user is signed in / no value was cached / value is corrupt.
///
/// Captures the uid before awaiting `getInstance()` and re-checks after, so a
/// sign-out racing with this read can't return another user's value.
Future<int?> readCachedStarterNameId() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return null;
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return null;
  return prefs.getInt('$starterNamePrefBaseKey:$userId');
}

/// Writes the starter Name catalog id to scoped prefs. Called immediately
/// after [AuthService.seedStarterCard] inserts the row in Supabase, and
/// from [hydrateStarterNameFromSupabase] on sign-in.
///
/// Captures the uid once at the top and builds the scoped key inline (instead
/// of re-resolving via [SupabaseSyncService.scopedKey]) so a sign-out racing
/// with the `getInstance()` await can't write an unscoped or wrong-uid key.
/// Aborts if the auth user changed mid-await.
Future<void> writeCachedStarterNameId(int catalogId) async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  if (supabaseSyncService.currentUserId != userId) return;
  await prefs.setInt('$starterNamePrefBaseKey:$userId', catalogId);
}

/// Pulls `user_profiles.starter_name_id` from Supabase and caches it locally.
/// Called from [hydrateUserDataFromBatchRpc] so signing in always primes the
/// pref, eliminating the day-0 home greeting flicker.
///
/// Captures uid once and writes via the same captured-uid scoped key as
/// [writeCachedStarterNameId] to stay race-safe across the network round-trip.
Future<void> hydrateStarterNameFromSupabase() async {
  final userId = supabaseSyncService.currentUserId;
  if (userId == null || userId.isEmpty) return;
  try {
    final row = await Supabase.instance.client
        .from('user_profiles')
        .select('starter_name_id')
        .eq('id', userId)
        .maybeSingle();
    if (supabaseSyncService.currentUserId != userId) return;
    final id = (row?['starter_name_id'] as num?)?.toInt();
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (supabaseSyncService.currentUserId != userId) return;
    await prefs.setInt('$starterNamePrefBaseKey:$userId', id);
  } catch (e, stack) {
    // Visible in dev so a missing column or RLS regression surfaces, but
    // doesn't crash — provider falls back to getTodaysName() in that case.
    debugPrint('[starter_name_cache] hydrate from Supabase failed: $e\n$stack');
  }
}
