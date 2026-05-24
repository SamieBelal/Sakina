import 'package:flutter/foundation.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart' as tokens;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

  /// Telemetry hook for the AI-bypass funnel (PR 3 of plan 2026-05-23).
  /// Set once at app startup in `main.dart` to bridge to `AnalyticsService`.
  /// Left null in tests so no real Mixpanel hits fire; widget/unit tests can
  /// install a spy to assert on emitted events.
  ///
  /// Fires `ai_bypass_purchased` after a successful reservation and
  /// `ai_bypass_rejected` when the RPC returns `ok=false` or null. The
  /// matching `ai_bypass_offered` fires from [DailyCapSheet.show].
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  /// Fires after [hydrateFromProfile] finishes writing all per-user
  /// SharedPreferences keys from a `sync_all_user_data` payload. Wired in
  /// `AppLifecycleObserver` to `ref.invalidate(iapToSubBannerStateProvider)`
  /// so the home-screen banner re-reads its eligibility predicates against
  /// the freshly-hydrated cache. Without this signal, the banner's
  /// FutureProvider would evaluate once at first widget mount — typically
  /// BEFORE sync completes — see a default `lifetime_bypasses_purchased=0`,
  /// resolve to "hidden", and never re-render for the rest of the session.
  ///
  /// Left null in tests so widget tests don't take a dependency on Riverpod
  /// container plumbing. Production wires it exactly once in
  /// `AppLifecycleObserver.initState`.
  static void Function()? onProfileHydrated;

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

    final featureKey = _bypassFeatureKey(feature);
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'reserve_ai_bypass',
      {
        'p_feature': featureKey,
        'p_idempotency_key': const Uuid().v4(),
      },
    );
    if (result == null) {
      onAnalyticsEvent?.call('ai_bypass_rejected', {
        'feature': featureKey,
        'reason': 'network',
      });
      return null;
    }
    if (result['ok'] != true) {
      onAnalyticsEvent?.call('ai_bypass_rejected', {
        'feature': featureKey,
        'reason': result['reason'] ?? 'unknown',
      });
      return null;
    }

    final reservationId = result['reservation_id'] as String?;
    final balance = (result['balance'] as num?)?.toInt();
    final bypassesUsed = (result['bypasses_used'] as num?)?.toInt();
    if (reservationId == null || balance == null || bypassesUsed == null) {
      onAnalyticsEvent?.call('ai_bypass_rejected', {
        'feature': featureKey,
        'reason': 'malformed_response',
      });
      return null;
    }

    // Mirror server state into local caches so the next DailyCapSheet build
    // sees the debited balance + incremented counter without a round-trip.
    await tokens.hydrateTokenCache(balance: balance);
    await _incrementBypassCache(feature);

    onAnalyticsEvent?.call('ai_bypass_purchased', {
      'feature': featureKey,
      'token_balance_after': balance,
      'bypasses_used_today': bypassesUsed,
    });

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

  // ---- Day-1 freebie (EXP-2 / PR 4 of plan 2026-05-23) -------------------

  /// True when the user is within 24h of signup AND hasn't yet consumed
  /// the global one-shot Day-1 freebie. Drives DailyCapSheet STATE D —
  /// the "One more on us, {name}" gold-accent variant that lets a brand-
  /// new user blow past their first cap-hit without spending tokens.
  ///
  /// Server is the final arbiter — `claim_first_bypass` re-checks the
  /// same predicates inside a `FOR UPDATE` lock so a client whose cache
  /// is stale or has been tampered with cannot double-claim. The cached
  /// flag exists only to render the sheet variant without a round-trip.
  ///
  /// Returns false for: premium users (they never see DailyCapSheet),
  /// users whose signup is unknown (defense against profile corruption),
  /// users past the 24h window, and anyone who has already claimed.
  Future<bool> firstBypassEligible() async {
    if (await PurchaseService().isPremium()) return false;

    final prefs = await SharedPreferences.getInstance();
    final consumed = prefs.getBool(
          supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
        ) ??
        false;
    if (consumed) return false;

    final signupAtIso = prefs.getString(
      supabaseSyncService.scopedKey(_signupAtBaseKey),
    );
    if (signupAtIso == null) return false;

    final signupAt = DateTime.tryParse(signupAtIso);
    if (signupAt == null) return false;

    return signupAt.isAfter(_nowUtc().subtract(const Duration(hours: 24)));
  }

  /// Returns the cached display_name set on `user_profiles`, falling back
  /// to `AuthService.defaultDisplayName` ("Friend"). STATE D renders the
  /// "One more on us, {name}" headline when this is NOT the default —
  /// otherwise it shows "One more on us" so we don't greet someone as
  /// "Friend".
  Future<String> displayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
          supabaseSyncService.scopedKey(_displayNameBaseKey),
        ) ??
        defaultDisplayName;
  }

  /// One-shot per-user, atomic on the server. Increments the per-feature
  /// bypass counter WITHOUT debiting tokens, flips the consumed latch.
  /// Different shape from [reserveBypass] — no reservation flow because
  /// nothing is at stake (no token spend → nothing to refund on AI failure;
  /// the user just retries the freebie, which is now ineligible — so they
  /// fall back to the normal token-spend bypass on retry).
  ///
  /// Returns true on success (server flipped the flag + incremented the
  /// counter; client caches mirrored). Returns false on any rejection —
  /// the [GatingService.onAnalyticsEvent] hook fires with the typed
  /// reason for funnel attribution.
  Future<bool> claimFirstBypass(GatedFeature feature) async {
    if (await PurchaseService().isPremium()) return false;

    final featureKey = _bypassFeatureKey(feature);
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'claim_first_bypass',
      {'p_feature': featureKey},
    );
    if (result == null) {
      onAnalyticsEvent?.call('first_bypass_rejected', {
        'feature': featureKey,
        'reason': 'network',
      });
      return false;
    }
    if (result['ok'] != true) {
      onAnalyticsEvent?.call('first_bypass_rejected', {
        'feature': featureKey,
        'reason': result['reason'] ?? 'unknown',
      });
      return false;
    }

    final bypassesUsed = (result['bypasses_used'] as num?)?.toInt();
    if (bypassesUsed == null) {
      onAnalyticsEvent?.call('first_bypass_rejected', {
        'feature': featureKey,
        'reason': 'malformed_response',
      });
      return false;
    }

    // Mirror server state. Flip the consumed latch so the very next
    // DailyCapSheet render across the app shows STATE A/B/C (not STATE D
    // again), and increment the local bypass counter so the bypass-cap
    // arithmetic stays consistent with the server.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
      true,
    );
    await _incrementBypassCache(feature);

    onAnalyticsEvent?.call('first_bypass_claimed', {
      'feature': featureKey,
      'bypasses_used_today': bypassesUsed,
    });

    return true;
  }

  /// Lifetime count of COMMITTED bypass purchases (cancelled reservations
  /// never increment). Mirrors `user_profiles.lifetime_bypasses_purchased`
  /// hydrated from `sync_all_user_data`. Used by the IAP→sub upsell banner
  /// to decide whether the user has demonstrated enough IAP velocity to be
  /// worth converting to subscription.
  Future<int> lifetimeBypassesPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(
          supabaseSyncService.scopedKey(_lifetimeBypassesPurchasedBaseKey),
        ) ??
        0;
  }

  /// Returns the cached dismissal timestamp for the IAP→sub upsell banner,
  /// or null if never dismissed. Server is the source of truth (the close-
  /// tap writes via `dismiss_iap_upsell_banner` RPC); this cache exists
  /// only so the banner can decide whether to render without a round-trip.
  Future<DateTime?> iapBannerDismissedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(
      supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
    );
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Returns true when the IAP→sub upsell banner should render. ALL of:
  ///
  ///   * user is NOT premium (premium users are already on the destination
  ///     surface — the banner would be insulting), AND
  ///   * lifetime_bypasses_purchased >= 6 (demonstrated IAP intent), AND
  ///   * days_since_signup >= 7 (don't harass brand-new heavy users), AND
  ///   * (never dismissed OR dismissed > 14 days ago) — re-prompt cadence.
  ///
  /// Defensive: returns false if signup_at is missing or unparseable —
  /// same posture as `firstBypassEligible`. A corrupted profile must not
  /// silently qualify for the upsell.
  Future<bool> iapToSubBannerEligible() async {
    if (await PurchaseService().isPremium()) return false;

    final lifetime = await lifetimeBypassesPurchased();
    if (lifetime < iapToSubBannerLifetimeBypassesThreshold) return false;

    final prefs = await SharedPreferences.getInstance();
    final signupAtIso = prefs.getString(
      supabaseSyncService.scopedKey(_signupAtBaseKey),
    );
    if (signupAtIso == null) return false;
    final signupAt = DateTime.tryParse(signupAtIso);
    if (signupAt == null) return false;

    final now = _nowUtc();
    final daysSinceSignup = now.difference(signupAt).inDays;
    if (daysSinceSignup < iapToSubBannerMinDaysSinceSignup) return false;

    final dismissedAt = await iapBannerDismissedAt();
    if (dismissedAt != null) {
      final age = now.difference(dismissedAt);
      if (age < iapToSubBannerDismissalSuppression) return false;
    }

    return true;
  }

  /// Writes the dismissal timestamp server-side via `dismiss_iap_upsell_banner`
  /// RPC and mirrors it locally. Returns true on RPC success (banner will
  /// suppress for 14 days), false on network/RPC failure (banner stays —
  /// the user can dismiss again on next render).
  ///
  /// Premium users short-circuit to true with no RPC call — the banner is
  /// already hidden for them; nothing to persist.
  Future<bool> dismissIapToSubBanner() async {
    if (await PurchaseService().isPremium()) return true;

    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'dismiss_iap_upsell_banner',
      const {},
    );
    if (result == null || result['ok'] != true) return false;

    final dismissedAtIso = result['dismissed_at'];
    if (dismissedAtIso is! String) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
      dismissedAtIso,
    );
    return true;
  }

  static const String _firstBypassConsumedBaseKey = 'first_bypass_consumed';
  static const String _signupAtBaseKey = 'signup_at';
  static const String _displayNameBaseKey = 'display_name';
  static const String _lifetimeBypassesPurchasedBaseKey =
      'lifetime_bypasses_purchased';
  static const String _iapBannerDismissedAtBaseKey =
      'iap_upsell_banner_dismissed_at';

  /// IAP→sub upsell threshold — the banner appears once a free user has
  /// committed 6+ paid bypasses lifetime. Pinned in plan; encoded here so a
  /// dashboard tune can move it via constant-flip rather than RPC redeploy.
  static const int iapToSubBannerLifetimeBypassesThreshold = 6;

  /// Days-since-signup floor — don't harass brand-new heavy IAP users. A user
  /// who hits 6 bypasses in their first week is already on the consideration
  /// path; surfacing the upsell on Day 8 lets the natural friction land first.
  static const int iapToSubBannerMinDaysSinceSignup = 7;

  /// Suppression window after the user dismisses the banner. Re-shows after
  /// 14 days if they're still ineligible-by-IAP-velocity for premium. CEO
  /// review's cadence — long enough not to annoy, short enough not to forget.
  static const Duration iapToSubBannerDismissalSuppression =
      Duration(days: 14);

  /// Fallback display name — mirrors `AuthService.defaultDisplayName`.
  /// Kept in lockstep here so gating_service doesn't take a dependency on
  /// auth_service for a single 6-char string. Pinned by widget test.
  static const String defaultDisplayName = 'Friend';

  /// Test seam for the 24h Day-1 window. Production reads UTC `now()`.
  @visibleForTesting
  static DateTime Function()? debugNowUtc;
  DateTime _nowUtc() => (debugNowUtc ?? () => DateTime.now().toUtc())();

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

    // Day-1 freebie hydration (PR 4 of plan 2026-05-23). Server is the
    // source of truth for both fields; absence in the payload means a
    // pre-PR4 backend — leave the cache untouched so the gate falls
    // back to "ineligible" (default false) rather than silently flipping
    // a flag the server can't validate.
    final firstBypassConsumedRaw = profile['first_bypass_consumed'];
    if (firstBypassConsumedRaw is bool) {
      await prefs.setBool(
        supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
        firstBypassConsumedRaw,
      );
    }

    final createdAtRaw = profile['created_at'];
    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_signupAtBaseKey),
        createdAtRaw,
      );
    }

    final displayNameRaw = profile['display_name'];
    if (displayNameRaw is String && displayNameRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_displayNameBaseKey),
        displayNameRaw,
      );
    }

    // EXP-3 IAP→sub upsell banner hydration (PR 5 of plan 2026-05-23). Server
    // is the source of truth: `lifetime_bypasses_purchased` is incremented by
    // `commit_ai_bypass` RPC; `iap_upsell_banner_dismissed_at` by the
    // `dismiss_iap_upsell_banner` RPC.
    final lifetimeBypassesRaw = profile['lifetime_bypasses_purchased'];
    if (lifetimeBypassesRaw is num) {
      await prefs.setInt(
        supabaseSyncService.scopedKey(_lifetimeBypassesPurchasedBaseKey),
        lifetimeBypassesRaw.toInt(),
      );
    }

    final iapDismissedAtRaw = profile['iap_upsell_banner_dismissed_at'];
    if (iapDismissedAtRaw is String && iapDismissedAtRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
        iapDismissedAtRaw,
      );
    } else if (iapDismissedAtRaw == null) {
      // Server says never dismissed (or pre-PR5 backend): clear the local
      // cache so a stale dismissal can't keep the banner suppressed forever
      // after an admin reset.
      await prefs.remove(
        supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
      );
    }

    // Signal listeners (currently: the IAP→sub banner provider) that the
    // per-user cache is fresh and they should re-evaluate. See the
    // [onProfileHydrated] docstring for the why.
    onProfileHydrated?.call();
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
    await prefs.remove(
      supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
    );
    await prefs.remove(supabaseSyncService.scopedKey(_signupAtBaseKey));
    await prefs.remove(supabaseSyncService.scopedKey(_displayNameBaseKey));
    await prefs.remove(
      supabaseSyncService.scopedKey(_lifetimeBypassesPurchasedBaseKey),
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
    );
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
