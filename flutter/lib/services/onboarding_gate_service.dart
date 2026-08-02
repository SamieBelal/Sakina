import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_sync_service.dart';

/// Persists the state the post-onboarding entry gate needs that did not already
/// exist: `onboarding_paywall_cleared` — the one-time entry latch. Set TRUE when
/// the user starts a trial, is already premium, or the offerings-fail valve is
/// NOT used. Once true the router stops sending them to the wall.
///
/// This class also held `onboarding_tour_step_index`, the guided tour's resume
/// cursor. The tour was deleted 2026-07-28 (One Ship W2 §F1a) — nothing resumes
/// a tour, so the cursor (and its `tour_step_index` server mirror) went with it.
/// Existing prefs/column values are simply left unread.
///
/// Keys are user-scoped via [SupabaseSyncService.scopedKey] so a shared device
/// doesn't bleed gate state across accounts. Server (`user_profiles`) is the
/// durable source for cross-device / reinstall; these prefs are the
/// synchronously-readable cache the router boots from. Server values are mirrored
/// in via [hydrateFromProfile].
class OnboardingGateService {
  OnboardingGateService._();

  static final OnboardingGateService instance = OnboardingGateService._();

  factory OnboardingGateService() => instance;

  static const String paywallClearedBaseKey = 'onboarding_paywall_cleared';

  String get _paywallClearedKey =>
      supabaseSyncService.scopedKey(paywallClearedBaseKey);

  /// Reads the entry latch. Defaults to `true` (cleared) when ABSENT — this is
  /// the grandfather guard: existing users (and anyone whose key was never
  /// written) are treated as already past the wall so they never flash into the
  /// gate. A brand-new user is put INTO the gate only by [setPaywallCleared]`(false)`
  /// from `completeOnboarding`. The server backfill + [hydrateFromProfile] is a
  /// cross-device belt-and-suspenders on top of this local default.
  Future<bool> isPaywallCleared() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paywallClearedKey) ?? true;
  }

  /// Sets the entry latch locally and best-effort mirrors it to `user_profiles`
  /// so a reinstall / second device doesn't re-wall a user who already entered.
  Future<void> setPaywallCleared(bool cleared) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_paywallClearedKey, cleared);

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;
    // user_profiles keys on `id` (= auth.uid()), not `user_id`. upsertRawRow
    // does not inject user_id; passing `id` lets the upsert match the row.
    await supabaseSyncService.upsertRawRow(
      'user_profiles',
      {'id': userId, 'onboarding_paywall_cleared': cleared},
      onConflict: 'id',
    );
  }

  /// Mirrors server `user_profiles` values into the local cache. Called from the
  /// same place as `GatingService.hydrateFromProfile` (batch sync on launch) so
  /// the router boots from server truth on a reinstall. Absent keys leave the
  /// cache untouched (pre-migration backend tolerance).
  Future<void> hydrateFromProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();

    final clearedRaw = profile['onboarding_paywall_cleared'];
    if (clearedRaw is bool) {
      await prefs.setBool(_paywallClearedKey, clearedRaw);
    }
    // The payload's `tour_step_index` is deliberately ignored — see the class
    // doc. The RPC still returns it; nothing consumes it.
  }
}
