import 'package:flutter/foundation.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
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

  /// Lifetime warmup budgets per feature.
  static const Map<GatedFeature, int> warmupBudget = {
    GatedFeature.reflect: 10,
    GatedFeature.builtDua: 10,
    GatedFeature.discoverName: 5,
  };

  Future<GateResult> canUse(GatedFeature feature) async {
    final isPremium = await PurchaseService().isPremium();
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
  Future<UsageOutcome> markUsed(GatedFeature feature) async {
    final isPremium = await PurchaseService().isPremium();
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
      return warmup == 1
          ? UsageOutcome.warmupJustExhausted
          : UsageOutcome.ok;
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
    // Tolerant: column may not yet exist (Lane C migration). upsertRow
    // already swallows postgres errors and returns false — local cache
    // remains the source of truth until the column lands.
    await supabaseSyncService.upsertRow(
      'user_profiles',
      userId,
      {_warmupColumn(feature): next},
      onConflict: 'id',
    );
  }

  // ---- had_trial latch ----------------------------------------------------

  static const String _hadTrialBaseKey = 'had_trial';

  Future<bool> _readHadTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final scoped =
        supabaseSyncService.scopedKey(_hadTrialBaseKey);
    return prefs.getBool(scoped) ?? false;
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
