import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/starter_name_cache.dart';

/// Loads the user's starter Name from the local SharedPreferences cache (set
/// by [seedStarterCard] at signup or [hydrateStarterNameFromSupabase] on
/// sign-in). Falls back to a Supabase query if the cache is empty (e.g. an
/// older user signed in before the cache was wired up). Returns null when no
/// user is signed in or no starter Name was recorded.
///
/// `.autoDispose` so signing out + back in as a different user re-fetches
/// instead of leaking the prior user's starter Name through the cache.
///
/// Used by [DailyLaunchOverlay] to surface the user's starter Name on day 0
/// before the daily rotation takes over.
final starterNameProvider =
    FutureProvider.autoDispose<CollectibleName?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  // Fast path: scoped pref. Hydrated on sign-in by the batch RPC, so this
  // is populated for any user who signed in this session.
  var id = await readCachedStarterNameId();

  // Slow path: query Supabase. Only fires if pref was missing — happens for
  // users who signed up before this caching layer existed, or if the batch
  // hydration hasn't completed yet. Deliberately does NOT write the result
  // back to the pref: a sign-out + sign-in racing with the round-trip would
  // make `writeCachedStarterNameId` resolve `currentUserId` to the NEW user
  // and pollute their cache with the OLD user's id. The batch hydration
  // (`hydrateStarterNameFromSupabase`) is the single race-safe writer, and
  // it'll back-fill on the next sign-in regardless.
  if (id == null) {
    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select('starter_name_id')
          .eq('id', userId)
          .maybeSingle();
      if (Supabase.instance.client.auth.currentUser?.id != userId) return null;
      id = (row?['starter_name_id'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  if (id == null) return null;
  for (final n in allCollectibleNames) {
    if (n.id == id) return n;
  }
  return null;
});
