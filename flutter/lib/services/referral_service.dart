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
  Future<void> applyPendingReferralIfAny(String userId) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(referralPendingReferralPrefsKey);
    if (code == null || code.isEmpty) return;
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

    if (result != null) {
      final ok = result['ok'] == true;
      if (ok) {
        _analytics?.track(AnalyticsEvents.refereeSignedUpWithReferral);
        if (result['granted_referee_7d'] == true) {
          _analytics?.track(AnalyticsEvents.refereeGranted7dWindow);
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
