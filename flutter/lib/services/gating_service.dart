import 'package:flutter/foundation.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart' as tokens;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Gating Service
//
// Single source of truth for "can the user use AI feature X right now?".
// Consolidates premium-vs-free, warmup-budget, daily-cap, and lapsed-trialer
// rules so callers (reflect / built-dua / discover-name providers) ask one
// question instead of stitching policy together themselves.
//
// Decision tree (see spec 2026-05-09-free-premium-tier-redesign-design):
//   1. Premium → 30/day fair-use ceiling.
//   2. Free + had_trial==true → skip warmup, apply 1/day cap.
//   3. Free + had_trial==false → consume warmup budget; cap kicks in at 0.
// ---------------------------------------------------------------------------

enum GatedFeature { reflect, builtDua, discoverName }

enum GateReason {
  ok,
  premiumFairUse,
  warmupRemaining,
  dailyCap,
  hadTrialNoBudget,
}

/// Outcome of a successful [GatingService.markUsed] call. Most calls return
/// [ok]. The transition moment when a free user's warmup counter decrements
/// from 1 to 0 returns [warmupJustExhausted] so the UI can fire the dedicated
/// "you've completed your free reflections" sheet exactly once per feature.
enum UsageOutcome { ok, warmupJustExhausted }

class GateResult {
  final bool allowed;
  final GateReason reason;
  final int? remaining;
  const GateResult({
    required this.allowed,
    required this.reason,
    this.remaining,
  });
}

/// Successful response from [GatingService.reserveBypass]. Caller must hold
/// [reservationId] for the lifetime of the AI call and pass it to either
/// [GatingService.commitBypass] (on success) or [GatingService.cancelBypass]
/// (on failure / abandonment). If neither fires, the server-side orphan-
/// cleanup cron will cancel the reservation after 15 minutes.
class BypassReservation {
  final String reservationId;
  final int newBalance;
  final int bypassesUsedToday;

  const BypassReservation({
    required this.reservationId,
    required this.newBalance,
    required this.bypassesUsedToday,
  });
}

class GatingService {
  GatingService._();

  static final GatingService instance = GatingService._();

  @visibleForTesting
  GatingService.test();

  factory GatingService() => _debugOverride ?? instance;

  static GatingService? _debugOverride;

  @visibleForTesting
  static void debugSetOverride(GatingService service) {
    _debugOverride = service;
  }

  @visibleForTesting
  static void debugClearOverride() {
    _debugOverride = null;
  }

  /// Premium fair-use ceiling per feature per day. Silent — UI must surface
  /// a "take a breath" message, NOT route to a paywall (the user is already
  /// paying).
  static const int premiumDailyFairUseCap = 30;

  /// Token cost to bypass the daily cap for one extra AI use. Mirrors the
  /// server's `app_config.bypass_token_cost` seed value (PR 1 migration
  /// `20260523000000_ai_bypass_reservations_and_rpcs.sql`). Server is the
  /// source of truth — the constant here is a defensive fallback used by
  /// the DailyCapSheet copy when the server value hasn't been hydrated yet.
  static const int bypassTokenCost = 25;

  /// Maximum number of bypass spends per feature per day. Matches the
  /// server's `app_config.max_bypasses_per_day` seed value. Same fallback
  /// rationale as [bypassTokenCost].
  static const int maxBypassesPerDayPerFeature = 2;

  /// Lifetime warmup budgets per feature.
  static const Map<GatedFeature, int> warmupBudget = {
    GatedFeature.reflect: 10,
    GatedFeature.builtDua: 10,
    GatedFeature.discoverName: 5,
  };

  /// [isPremiumHint] lets the caller skip a duplicate RevenueCat round-trip
  /// when premium status was already resolved upstream. Pair with
  /// [markUsed]'s identical hint to keep the whole submit cycle to a single
  /// `PurchaseService().isPremium()` call.
  Future<GateResult> canUse(
    GatedFeature feature, {
    bool? isPremiumHint,
  }) async {
    final isPremium = isPremiumHint ?? await PurchaseService().isPremium();
    if (isPremium) {
      final usedToday = await _getUsageToday(feature);
      if (usedToday >= premiumDailyFairUseCap) {
        return const GateResult(
          allowed: false,
          reason: GateReason.premiumFairUse,
        );
      }
      return const GateResult(allowed: true, reason: GateReason.ok);
    }

    // Free user.
    final hadTrial = await _readHadTrial();
    if (hadTrial) {
      // Skip warmup; apply daily cap immediately.
      return _applyDailyCap(feature, hadTrial: true);
    }

    final warmup = await _readWarmupRemaining(feature);
    if (warmup > 0) {
      return GateResult(
        allowed: true,
        reason: GateReason.warmupRemaining,
        remaining: warmup,
      );
    }

    return _applyDailyCap(feature, hadTrial: false);
  }

  /// Records a successful AI call. Increments the daily counter when the
  /// user is in capped/premium phase, decrements the warmup counter when
  /// they're still in warmup. Never touches both.
  ///
  /// Returns [UsageOutcome.warmupJustExhausted] only on the transition moment
  /// when this call decrements warmup from 1 to 0 — the screen layer uses that
  /// signal to fire [WarmupExhaustedSheet] exactly once per feature. All other
  /// paths return [UsageOutcome.ok].
  ///
  /// [isPremiumHint] lets the caller skip a duplicate RevenueCat round-trip
  /// when premium status was already resolved during the same submit cycle
  /// (typically in [canUse]). Pass the boolean returned from there. Falls back
  /// to a fresh `PurchaseService().isPremium()` check when omitted.
  Future<UsageOutcome> markUsed(
    GatedFeature feature, {
    bool? isPremiumHint,
  }) async {
    final isPremium = isPremiumHint ?? await PurchaseService().isPremium();
    if (isPremium) {
      await _incrementDaily(feature);
      return UsageOutcome.ok;
    }

    final hadTrial = await _readHadTrial();
    if (hadTrial) {
      await _incrementDaily(feature);
      return UsageOutcome.ok;
    }

    final warmup = await _readWarmupRemaining(feature);
    if (warmup > 0) {
      await _decrementWarmup(feature, warmup);
      // The "1 → 0" transition is the one-shot moment the WarmupExhaustedSheet
      // fires on. Subsequent decrements are clamped to 0 in _decrementWarmup
      // and never re-trigger this signal because warmup will already be 0
      // before this branch runs.
      //
      // Critically, we ALSO increment the daily counter on this transition.
      // Without it, canUse() falls through to _applyDailyCap on the very next
      // attempt and — since the daily counter is still 0 — allows ONE MORE
      // same-day use. The user would get N+1 free uses instead of N. By
      // recording today's exhaust call against the daily cap, the next attempt
      // sees `used >= cap` and is blocked. Tomorrow rolls over via the per-day
      // key in daily_usage_service, restoring the normal 1/day allowance.
      if (warmup == 1) {
        await _incrementDaily(feature);
        return UsageOutcome.warmupJustExhausted;
      }
      return UsageOutcome.ok;
    }

    await _incrementDaily(feature);
    return UsageOutcome.ok;
  }

  // ---- helpers ------------------------------------------------------------

  Future<GateResult> _applyDailyCap(
    GatedFeature feature, {
    required bool hadTrial,
  }) async {
    final used = await _getUsageToday(feature);
    final cap = _dailyCap(feature);
    if (used >= cap) {
      return GateResult(
        allowed: false,
        reason: hadTrial ? GateReason.hadTrialNoBudget : GateReason.dailyCap,
      );
    }
    return const GateResult(allowed: true, reason: GateReason.ok);
  }

  int _dailyCap(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.dailyFreeReflects;
      case GatedFeature.builtDua:
        return daily.dailyFreeBuiltDuas;
      case GatedFeature.discoverName:
        return daily.dailyFreeDiscoverNames;
    }
  }

  Future<int> _getUsageToday(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.getReflectUsageToday();
      case GatedFeature.builtDua:
        return daily.getBuiltDuaUsageToday();
      case GatedFeature.discoverName:
        return daily.getDiscoverNameUsageToday();
    }
  }

  Future<int> _incrementDaily(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.incrementReflectUsage();
      case GatedFeature.builtDua:
        return daily.incrementBuiltDuaUsage();
      case GatedFeature.discoverName:
        return daily.incrementDiscoverNameUsage();
    }
  }

  String _warmupPrefsKey(GatedFeature feature) {
    return supabaseSyncService.scopedKey(
      'warmup_${feature.name}_remaining',
    );
  }

  String _warmupColumn(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return 'warmup_reflect_remaining';
      case GatedFeature.builtDua:
        return 'warmup_built_dua_remaining';
      case GatedFeature.discoverName:
        return 'warmup_discover_name_remaining';
    }
  }

  Future<int> _readWarmupRemaining(GatedFeature feature) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_warmupPrefsKey(feature));
    return stored ?? warmupBudget[feature]!;
  }

  Future<void> _decrementWarmup(GatedFeature feature, int current) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (current - 1).clamp(0, warmupBudget[feature]!);
    await prefs.setInt(_warmupPrefsKey(feature), next);

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;
    // user_profiles uses `id` (matching auth.uid()) as its primary key,
    // NOT `user_id`. Use upsertRawRow so `user_id` isn't auto-injected,
    // and pass `id` in the payload so the upsert matches the existing row.
    await supabaseSyncService.upsertRawRow(
      'user_profiles',
      {'id': userId, _warmupColumn(feature): next},
      onConflict: 'id',
    );
  }

  // ---- AI bypass (reserve / commit / cancel) ------------------------------

  /// Reads the local bypass-counter cache for [feature]. Server is the source
  /// of truth — the cache is hydrated on each `sync_all_user_data` and
  /// mutated optimistically by [reserveBypass] / [cancelBypass].
  Future<int> bypassesUsedToday(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.getReflectBypassesUsedToday();
      case GatedFeature.builtDua:
        return daily.getBuiltDuaBypassesUsedToday();
      case GatedFeature.discoverName:
        return daily.getDiscoverNameBypassesUsedToday();
    }
  }

  /// Reserves a bypass on [feature]. Calls the `reserve_ai_bypass` RPC which
  /// atomically debits [bypassTokenCost] tokens, increments the daily bypass
  /// counter, and inserts a pending row in `ai_bypass_reservations`. On
  /// success, returns a [BypassReservation] whose `reservationId` the caller
  /// MUST hold and pass to [commitBypass] (on AI success) or [cancelBypass]
  /// (on AI failure).
  ///
  /// Returns null when:
  /// - The user is premium ([PurchaseService.isPremium] short-circuit — the
  ///   bypass path is a free-tier mechanic).
  /// - The RPC rejects (insufficient tokens, bypass cap reached, bad feature).
  /// - The RPC call itself fails (network, auth). In that case the local
  ///   cache stays untouched — the user can retry.
  ///
  /// TEST-C (defense-in-depth, plan 2026-05-23 line 247): the premium
  /// short-circuit happens BEFORE the RPC fires. Premium users should never
  /// reach this surface — but pinning it at the service layer means a
  /// future UI bug that surfaces the bypass CTA to a premium user cannot
  /// accidentally debit their tokens.
  Future<BypassReservation?> reserveBypass(GatedFeature feature) async {
    if (await PurchaseService().isPremium()) return null;

    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'reserve_ai_bypass',
      {'p_feature': _bypassFeatureKey(feature)},
    );
    if (result == null) return null;
    if (result['ok'] != true) return null;

    final reservationId = result['reservation_id'] as String?;
    final balance = (result['balance'] as num?)?.toInt();
    final bypassesUsed = (result['bypasses_used'] as num?)?.toInt();
    if (reservationId == null || balance == null || bypassesUsed == null) {
      return null;
    }

    // Mirror server state into local caches so the next DailyCapSheet build
    // sees the debited balance + incremented counter without a round-trip.
    await tokens.hydrateTokenCache(balance: balance);
    await _incrementBypassCache(feature);

    return BypassReservation(
      reservationId: reservationId,
      newBalance: balance,
      bypassesUsedToday: bypassesUsed,
    );
  }

  /// Marks a reservation as committed. Fire-and-forget — failures here are
  /// not surfaced to the user because the server-side orphan-cleanup cron
  /// will NOT touch already-committed reservations, and the orphan window
  /// (15 min) only triggers cancel on `status='pending'` rows. So a missed
  /// commit means: the reservation stays pending in the DB for up to 15 min,
  /// then gets cancelled and tokens get refunded. The user already received
  /// the AI value at that point — they got a free use. Acceptable failure.
  Future<void> commitBypass(String reservationId) async {
    await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'commit_ai_bypass',
      {'p_reservation_id': reservationId},
    );
  }

  /// Cancels a pending reservation. Atomic on the server: flips status,
  /// refunds [bypassTokenCost] tokens, decrements the bypass counter. The
  /// returned bool lets the UI distinguish "cancel succeeded, show refunded
  /// toast" from "cancel failed (network) — orphan cron will rescue within
  /// 15 min, show 'reservation will refund shortly' toast".
  Future<bool> cancelBypass(
    String reservationId,
    GatedFeature feature,
  ) async {
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'cancel_ai_bypass',
      {'p_reservation_id': reservationId},
    );
    if (result == null) return false;
    if (result['ok'] != true) return false;

    final refundedBalance = (result['balance'] as num?)?.toInt();
    if (refundedBalance != null) {
      await tokens.hydrateTokenCache(balance: refundedBalance);
    }
    await _decrementBypassCache(feature);
    return true;
  }

  String _bypassFeatureKey(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return 'reflect';
      case GatedFeature.builtDua:
        return 'built_dua';
      case GatedFeature.discoverName:
        return 'discover_name';
    }
  }

  Future<void> _incrementBypassCache(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.incrementReflectBypassUsage();
      case GatedFeature.builtDua:
        return daily.incrementBuiltDuaBypassUsage();
      case GatedFeature.discoverName:
        return daily.incrementDiscoverNameBypassUsage();
    }
  }

  Future<void> _decrementBypassCache(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.decrementReflectBypassUsage();
      case GatedFeature.builtDua:
        return daily.decrementBuiltDuaBypassUsage();
      case GatedFeature.discoverName:
        return daily.decrementDiscoverNameBypassUsage();
    }
  }

  // ---- had_trial latch ----------------------------------------------------

  /// Shared SharedPreferences base key for the had_trial latch. Both
  /// [PurchaseService.hadTrial] (writer) and [_readHadTrial] (reader) MUST use
  /// the same key — declared here as the single source of truth.
  static const String hadTrialPrefsBaseKey = 'had_trial';

  static const String _hadTrialBaseKey = hadTrialPrefsBaseKey;

  Future<bool> _readHadTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final scoped =
        supabaseSyncService.scopedKey(_hadTrialBaseKey);
    return prefs.getBool(scoped) ?? false;
  }

  // ---- hydration ----------------------------------------------------------

  /// Hydrates the per-user warmup counters and `had_trial` latch from the
  /// `profile` section of the `sync_all_user_data` RPC payload. Called by
  /// `user_data_batch_sync_service` on app launch and any subsequent re-sync.
  ///
  /// Without this, fresh installs (or re-installs / multi-device users) would
  /// show their local default values (warmup=10/10/5, had_trial=false) even
  /// when the server says otherwise — letting a lapsed trialer get a fresh
  /// warmup budget by reinstalling the app.
  Future<void> hydrateFromProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();

    final warmupKeys = <GatedFeature, String>{
      GatedFeature.reflect: 'warmup_reflect_remaining',
      GatedFeature.builtDua: 'warmup_built_dua_remaining',
      GatedFeature.discoverName: 'warmup_discover_name_remaining',
    };
    for (final entry in warmupKeys.entries) {
      final raw = profile[entry.value];
      if (raw is num) {
        await prefs.setInt(_warmupPrefsKey(entry.key), raw.toInt());
      }
    }

    final hadTrialRaw = profile['had_trial'];
    if (hadTrialRaw is bool) {
      await prefs.setBool(
        supabaseSyncService.scopedKey(_hadTrialBaseKey),
        hadTrialRaw,
      );
    }
  }

  // ---- test helpers -------------------------------------------------------

  /// Resets per-user gating state. Test-only.
  @visibleForTesting
  Future<void> debugResetForUser() async {
    final prefs = await SharedPreferences.getInstance();
    for (final f in GatedFeature.values) {
      await prefs.remove(_warmupPrefsKey(f));
    }
    await prefs.remove(supabaseSyncService.scopedKey(_hadTrialBaseKey));
  }

  /// Force a specific warmup remaining count for tests.
  @visibleForTesting
  Future<void> debugSetWarmupRemaining(GatedFeature feature, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_warmupPrefsKey(feature), value);
  }

  /// Force the had_trial latch on (test-only).
  @visibleForTesting
  Future<void> debugSetHadTrial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      supabaseSyncService.scopedKey(_hadTrialBaseKey),
      value,
    );
  }
}
