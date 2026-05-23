import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'analytics_events.dart';
import 'analytics_provider.dart';
import 'analytics_service.dart';
import 'purchase_service.dart';

/// SharedPreferences key for the inbound referral code, set by the deep-link
/// capture in [main] and consumed by [ReferralService.applyPendingReferralIfAny].
/// Kept in sync with `lib/main.dart`'s `pendingReferralPrefsKey` constant.
const String referralPendingReferralPrefsKey = 'pending_referral';

/// SharedPreferences key for the SOURCE of the inbound referral code. Set
/// alongside [referralPendingReferralPrefsKey] so the post-signup analytics
/// can correctly attribute the funnel (deep_link vs onboarding_field).
/// Settings → Redeem path bypasses prefs entirely and calls apply_referral
/// directly with the `settings_redeem` source.
const String referralPendingReferralSourcePrefsKey = 'pending_referral_source';

/// Thin client wrapper around the refer-to-unlock SQL RPCs:
///   * `ensure_referral_code` — populates the user's referral code on signup.
///   * `apply_referral`       — consumes a `pending_referral` on signup.
///   * `confirm_referral_if_pending` — fires at onboarding-complete; the SQL
///     side handles the 30d window + gold card grant when the referrer
///     crosses 3 confirmed referees.
///
/// Each successful RPC fires a Mixpanel event (forward-instrumentation per
/// the CEO review — Task 5 Step 3 of
/// docs/superpowers/plans/2026-05-14-refer-unlock.md) and refreshes the
/// PurchaseService referral-premium cache so the next isPremium() call sees
/// any grant immediately.
class ReferralService {
  ReferralService(this._supabase, {AnalyticsService? analytics})
      : _analytics = analytics;

  final SupabaseClient _supabase;
  final AnalyticsService? _analytics;

  /// Drains `pending_referral` from SharedPreferences and submits it via the
  /// `apply_referral` RPC. Kill-resilient: prefs are cleared ONLY after the
  /// RPC returns. If the RPC throws, prefs stay set and the
  /// [AppSessionNotifier] defensive cold-launch hook will retry.
  ///
  /// Idempotent on the server side via the `(referee_id)` unique constraint —
  /// calling twice is safe.
  ///
  /// Analytics: emits `refereeSignedUpWithReferral` with `source` =
  /// `deep_link` for codes that originated from `sakina://r/<code>`, or
  /// `onboarding_field` for codes typed into the new in-onboarding field
  /// (PR #18). The disambiguation is best-effort and based on whether a
  /// `pending_referral_source` prefs key was set alongside the code.
  Future<void> applyPendingReferralIfAny(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(referralPendingReferralPrefsKey);
    if (code == null || code.isEmpty) return;
    // Default to deep_link for pre-PR-18 codes that were captured before the
    // source key existed. The onboarding-field path writes both keys; deep
    // link path writes only the code key.
    final source = prefs.getString(referralPendingReferralSourcePrefsKey) ??
        AnalyticsEvents.referralSourceDeepLink;
    final Map<String, dynamic>? result;
    try {
      final raw = await _supabase.rpc<dynamic>(
        'apply_referral',
        params: <String, dynamic>{'p_code': code, 'p_referee': userId},
      );
      result = raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (e) {
      debugPrint('[ReferralService] apply_referral RPC failed: $e');
      // Leave prefs in place — defensive cold-launch path retries.
      rethrow;
    }

    // Only remove prefs AFTER the RPC succeeded.
    await prefs.remove(referralPendingReferralPrefsKey);
    await prefs.remove(referralPendingReferralSourcePrefsKey);

    if (result != null) {
      final ok = result['ok'] == true;
      if (ok) {
        _analytics?.track(AnalyticsEvents.refereeSignedUpWithReferral,
            properties: {'source': source});
        if (result['granted_referee_7d'] == true) {
          _analytics?.track(AnalyticsEvents.refereeGranted7dWindow,
              properties: {'source': source});
        }
      }
    }

    // Refresh the cache so isPremium() picks up any 7d window granted here.
    await PurchaseService().refreshReferralPremiumCache();
  }

  /// Ensures the user has a `referral_code` populated. Calls
  /// `ensure_referral_code` which is idempotent on the server side
  /// (returns the existing code if one is already set).
  Future<void> ensureReferralCode(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _supabase.rpc<dynamic>('ensure_referral_code',
          params: <String, dynamic>{'p_user': userId});
    } catch (e) {
      debugPrint('[ReferralService] ensure_referral_code RPC failed: $e');
    }
  }

  /// Reads the user's referral code (does NOT generate one — call
  /// [ensureReferralCode] first if you need a code-on-demand).
  Future<String?> getMyReferralCode(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final row = await _supabase
          .from('user_profiles')
          .select('referral_code')
          .eq('id', userId)
          .maybeSingle();
      return row?['referral_code'] as String?;
    } catch (e) {
      debugPrint('[ReferralService] getMyReferralCode failed: $e');
      return null;
    }
  }

  /// Returns true iff the code matches a valid foreign referral_code on the
  /// server. Returns false for empty/short codes (no RPC fired), invalid
  /// codes, self-codes, and any RPC errors (swallowed so the widget UX
  /// stays soft-fail). Used by [ReferralCodeField] for live validation
  /// feedback on the in-onboarding "Did a friend send you a gift?" field
  /// and on the Settings → Redeem sheet (see PR #18 / Task 2 of
  /// docs/superpowers/plans/2026-05-23-onboarding-referral-code-entry.md).
  Future<bool> validateCode(String code) async {
    if (code.isEmpty || code.length < 8) return false;
    try {
      final raw = await _supabase.rpc<dynamic>('validate_referral_code',
          params: <String, dynamic>{'p_code': code});
      return raw == true;
    } catch (e) {
      debugPrint('[ReferralService] validateCode failed: $e');
      return false;
    }
  }

  /// Settings-path redeem. Bypasses the SharedPreferences drain because the
  /// user is already authenticated — calls apply_referral directly with the
  /// settings_redeem source. Returns a structured result the sheet UI can
  /// dispatch on (matches the exact reason strings emitted by
  /// supabase/migrations/20260514000000_referrals.sql + the 20260523000001
  /// reason-split patch).
  ///
  /// Analytics: on ok+granted, fires refereeSignedUpWithReferral and
  /// refereeGranted7dWindow with source='settings_redeem'. On ok without
  /// grant (idempotent same-code OR already-referred-other-code), fires
  /// only refereeSignedUpWithReferral. On !ok, fires no success events.
  Future<({bool ok, bool granted7d, String? reason})> redeemCodeNow(
      String userId, String code) async {
    if (userId.isEmpty || code.isEmpty) {
      return (ok: false, granted7d: false, reason: 'invalid');
    }
    try {
      final raw = await _supabase.rpc<dynamic>(
        'apply_referral',
        params: <String, dynamic>{'p_code': code, 'p_referee': userId},
      );
      final result = raw is Map ? Map<String, dynamic>.from(raw) : null;
      final ok = result?['ok'] == true;
      final granted = result?['granted_referee_7d'] == true;
      final reason = result?['reason'] as String?;
      if (ok) {
        _analytics?.track(AnalyticsEvents.refereeSignedUpWithReferral,
            properties: {'source': AnalyticsEvents.referralSourceSettingsRedeem});
        if (granted) {
          _analytics?.track(AnalyticsEvents.refereeGranted7dWindow,
              properties: {'source': AnalyticsEvents.referralSourceSettingsRedeem});
        }
        await PurchaseService().refreshReferralPremiumCache();
      }
      return (ok: ok, granted7d: granted, reason: reason);
    } catch (e) {
      debugPrint('[ReferralService] redeemCodeNow failed: $e');
      return (ok: false, granted7d: false, reason: 'network_error');
    }
  }

  /// Confirms a pending referral row for [userId] (flips status to
  /// `confirmed`). When that crosses the 3-confirmed threshold for the
  /// referrer, the SQL RPC handles the 30d window grant + gold card grant
  /// atomically; we just refresh the local cache.
  Future<void> confirmReferralIfPending(String userId) async {
    if (userId.isEmpty) return;
    try {
      final raw = await _supabase.rpc<dynamic>(
        'confirm_referral_if_pending',
        params: <String, dynamic>{'p_referee': userId},
      );
      final result = raw is Map ? Map<String, dynamic>.from(raw) : null;
      if (result != null && result['granted'] == true) {
        _analytics?.track(AnalyticsEvents.referrerGranted30dWindow);
      }
    } catch (e) {
      debugPrint('[ReferralService] confirm_referral_if_pending failed: $e');
    }
    await PurchaseService().refreshReferralPremiumCache();
  }

  /// Number of confirmed referrals for the given referrer. Used by
  /// ReferUnlockScreen for the "X of 3 friends joined" chip.
  Future<int> confirmedCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final rows = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', userId)
          .eq('status', 'confirmed');
      return (rows as List).length;
    } catch (e) {
      debugPrint('[ReferralService] confirmedCount failed: $e');
      return 0;
    }
  }
}

final referralServiceProvider = Provider<ReferralService>(
  (ref) => ReferralService(
    Supabase.instance.client,
    analytics: ref.read(analyticsProvider),
  ),
);
