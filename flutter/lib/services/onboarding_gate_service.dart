import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_sync_service.dart';

/// Persists the two pieces of state the post-onboarding gate needs that did not
/// already exist:
///   * `onboarding_paywall_cleared` — the one-time entry latch. Set TRUE when
///     the user starts a trial, is already premium, or the offerings-fail valve
///     is NOT used. Once true the router stops sending them to the hard wall.
///   * `onboarding_tour_step_index` — the resume cursor so a force-kill mid-tour
///     reopens at the abandoned step instead of restarting at 0.
///
/// (The "tour completed" signal reuses the tour's existing per-user seen flag —
/// see `onboardingTourSeenFlag` — so there is exactly one source of truth for
/// completion.)
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
  static const String tourStepIndexBaseKey = 'onboarding_tour_step_index';

  String get _paywallClearedKey =>
      supabaseSyncService.scopedKey(paywallClearedBaseKey);
  String get _tourStepIndexKey =>
      supabaseSyncService.scopedKey(tourStepIndexBaseKey);

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

  /// Reads the resume cursor. Defaults to `0` (start of tour) when absent.
  Future<int> tourStepIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tourStepIndexKey) ?? 0;
  }

  /// Persists the resume cursor. Local-only on the hot path (called on every
  /// tour advance); the server mirror happens lazily and is non-critical, so we
  /// keep this cheap and synchronous-ish.
  Future<void> setTourStepIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tourStepIndexKey, index < 0 ? 0 : index);
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

    // Server JSON key is `tour_step_index` (see the sync_all_user_data RPC in
    // 20260603000000_onboarding_gate_columns.sql) — NOT the local prefs base
    // key. Resume is prefs-only today (the cursor is not written server-side),
    // so this read is forward-compat: it stays correct if a server write is
    // ever added, instead of silently reading the wrong key.
    final stepRaw = profile['tour_step_index'];
    if (stepRaw is num) {
      final v = stepRaw.toInt();
      await prefs.setInt(_tourStepIndexKey, v < 0 ? 0 : v);
    }
  }
}
