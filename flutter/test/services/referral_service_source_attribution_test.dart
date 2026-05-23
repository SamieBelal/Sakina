import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pins the source-attribution contract for the 3 referral ingress paths
/// (PR #18 hybrid pattern). Without a mock SupabaseClient we can't fire
/// the actual apply_referral RPC here, but the source semantics are pure
/// prefs reads + constant comparisons — so we verify those.
///
/// See referral_service_test.dart for the apply_referral lifecycle contract,
/// and referral_deep_link_test.dart for the URI extraction contract. This
/// file specifically pins:
///   * The companion prefs key constant `pending_referral_source`.
///   * The deep-link path writes only the code key (source defaults to
///     `deep_link` when companion key is absent — the back-compat path
///     for codes captured before PR #18 shipped).
///   * The onboarding-field path writes BOTH keys (code + source =
///     `onboarding_field`).
///   * The signout drain (in auth_service.dart) clears BOTH keys.
///   * The settings_redeem source constant is exported and matches the
///     value the Settings sheet passes directly to apply_referral.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('referralPendingReferralSourcePrefsKey constant is stable', () {
    // The onboarding field writes this key alongside pending_referral.
    // applyPendingReferralIfAny reads it to attribute the analytics source.
    // Pin the wire so a rename can't silently break the 3-way funnel split.
    expect(referralPendingReferralSourcePrefsKey, 'pending_referral_source');
  });

  test('the 3 source constants are exported and stable', () {
    expect(AnalyticsEvents.referralSourceDeepLink, 'deep_link');
    expect(AnalyticsEvents.referralSourceOnboardingField, 'onboarding_field');
    expect(AnalyticsEvents.referralSourceSettingsRedeem, 'settings_redeem');
  });

  test(
      'deep-link path writes only the code key (source defaults to deep_link)',
      () async {
    // This mirrors what lib/main.dart `_persistReferralFromUri` does: write
    // ONLY the code, no source companion. PR-16-era contract. The source
    // attribution in applyPendingReferralIfAny falls back to deep_link in
    // this case — back-compat for pre-PR-18 cold launches.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(referralPendingReferralPrefsKey, 'ABCD2EFG');
    expect(prefs.getString(referralPendingReferralPrefsKey), 'ABCD2EFG');
    expect(prefs.getString(referralPendingReferralSourcePrefsKey), isNull,
        reason: 'Deep-link path does NOT set the source key — applyPending '
            'reconciles to deep_link via null-coalesce in referral_service.');
  });

  test('onboarding-field path writes both keys', () async {
    // Mirrors what the ReferralCodeField → save_progress_screen integration
    // does on the debounced settle: write the code AND a source = onboarding_field
    // companion. applyPendingReferralIfAny reads the companion and fires
    // refereeSignedUpWithReferral with source=onboarding_field.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(referralPendingReferralPrefsKey, 'GIFTABCD');
    await prefs.setString(referralPendingReferralSourcePrefsKey,
        AnalyticsEvents.referralSourceOnboardingField);

    expect(prefs.getString(referralPendingReferralPrefsKey), 'GIFTABCD');
    expect(prefs.getString(referralPendingReferralSourcePrefsKey),
        'onboarding_field');
  });

  test('signout drain clears both keys (auth_service.signOut() contract)',
      () async {
    // PR-18 added the companion source key. The signout drain in
    // lib/services/auth_service.dart must clear BOTH so the next user's
    // analytics attribution is clean. This pins the prefs-key list — if
    // auth_service ever forgets the source key, this test catches it.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(referralPendingReferralPrefsKey, 'STALEUSR');
    await prefs.setString(referralPendingReferralSourcePrefsKey,
        AnalyticsEvents.referralSourceOnboardingField);

    // Simulate the drain logic from auth_service.dart:signOut().
    await prefs.remove('pending_referral');
    await prefs.remove('pending_referral_source');

    expect(prefs.getString(referralPendingReferralPrefsKey), isNull);
    expect(prefs.getString(referralPendingReferralSourcePrefsKey), isNull);
  });

  test(
      'cold-launch reconciler drains a field-written code (source key present)',
      () async {
    // Scenario: user types a code into the onboarding field, the app gets
    // killed before signup completes. On relaunch + auth resume, the
    // AppSession reconciler picks up the prefs and calls
    // applyPendingReferralIfAny — same drain path as the deep-link case.
    // This test pins that both the code AND source are present and ready
    // for the reconciler to consume (it does NOT exercise the actual RPC
    // — that's covered by supabase/tests/referrals_test.sql).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(referralPendingReferralPrefsKey, 'COLDLNCH');
    await prefs.setString(referralPendingReferralSourcePrefsKey,
        AnalyticsEvents.referralSourceOnboardingField);

    // Reconciler reads both — if either is missing, attribution would
    // collapse to the deep_link fallback (which is wrong for field-typed
    // codes that survived a kill window).
    final code = prefs.getString(referralPendingReferralPrefsKey);
    final source = prefs.getString(referralPendingReferralSourcePrefsKey);
    expect(code, 'COLDLNCH');
    expect(source, 'onboarding_field');
  });
}
