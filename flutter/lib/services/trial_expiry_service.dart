import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Trial Expiry Service
//
// Reverse-trial resume re-check (eng-review decision #1 of the 2026-06-14
// onboarding-paywall ADR). On app-resume + home-load the caller invokes
// [resolveTrialExpiry], which:
//   1. Refreshes the local `trial_premium_until` cache from the server
//      (best-effort; no-op without an auth user / network).
//   2. Detects the FIRST moment the cached trial timestamp has moved into the
//      past — the Day-3 boundary crossing — and reports `justExpired = true`
//      exactly once (guarded by a one-shot SharedPreferences flag, mirroring
//      the LapsedTrialSheet posture).
//
// Client-clock trust by design: like gift / referral, the hot gate path does
// NOT round-trip the server to decide expiry. Clock-rollback abuse is tolerated
// (a free 3-day trial is low stakes — the same risk gift/referral already
// accept). The caller emits `trial_expired` once on the transition and lets
// routing fall through to the soft gate; the genuine gating is enforced by the
// limited free tier, not by this signal.
// ---------------------------------------------------------------------------

/// One-shot flag base key: set once we've reported the trial as expired so the
/// next resume in the same lapsed state does not re-fire `trial_expired`.
const String trialExpiredEmittedBaseKey = 'trial_expired_emitted';

class TrialExpiryDecision {
  /// True only on the FIRST resolve after the cached trial crossed into the
  /// past. The caller emits `trial_expired` and routes to the soft gate when
  /// this is true; subsequent resolves return false.
  final bool justExpired;

  const TrialExpiryDecision({required this.justExpired});
}

/// Refreshes the trial cache, then reports whether the reverse trial JUST
/// expired (the one-shot transition). Safe to call on every app-resume +
/// home-load. Best-effort and exception-safe — a failure resolves to
/// `justExpired = false` and never throws into the lifecycle/home path.
Future<TrialExpiryDecision> resolveTrialExpiry() async {
  try {
    // Eng-review #1: force a cache refresh so a trial that lapsed server-side
    // while backgrounded is observed this session. No-op without auth/network.
    await PurchaseService().refreshTrialPremiumCache();

    final prefs = await SharedPreferences.getInstance();
    final trialKey = supabaseSyncService
        .scopedKey(PurchaseService.trialPremiumUntilPrefsBaseKey);
    final iso = prefs.getString(trialKey);
    // No cached trial timestamp → the user never had a reverse trial; nothing
    // to expire.
    if (iso == null || iso.isEmpty) {
      return const TrialExpiryDecision(justExpired: false);
    }

    final until = DateTime.tryParse(iso);
    if (until == null) return const TrialExpiryDecision(justExpired: false);

    // Still active → not expired.
    if (until.isAfter(DateTime.now().toUtc())) {
      return const TrialExpiryDecision(justExpired: false);
    }

    // Lapsed. Fire at most once (one-shot flag).
    final emittedKey = supabaseSyncService.scopedKey(trialExpiredEmittedBaseKey);
    final alreadyEmitted = prefs.getBool(emittedKey) ?? false;
    if (alreadyEmitted) {
      return const TrialExpiryDecision(justExpired: false);
    }
    await prefs.setBool(emittedKey, true);
    return const TrialExpiryDecision(justExpired: true);
  } catch (_) {
    return const TrialExpiryDecision(justExpired: false);
  }
}
