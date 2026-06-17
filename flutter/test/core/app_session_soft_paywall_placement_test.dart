import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';
import 'package:sakina/features/paywall/paywall_experiment.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Pins the arm-aware soft-paywall placement seam (Lane C, review fix #2): the
/// session resolves `post_trial_soft` for a treatment-arm user whose 3-day
/// reverse trial has expired, and `post_tour_soft` for everyone else (incl. the
/// control arm). The router/PaywallScreen read these getters to pick the
/// placement + arm props WITHOUT giving the Riverpod-free services experiment
/// access.
AppSessionNotifier buildSession({
  String? uid = 'u1',
  bool trialExpired = false,
  PaywallArm? arm,
}) {
  return AppSessionNotifier(
    initialOnboarded: true,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => true,
    currentUserIdProvider: () => uid,
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => true,
    isPremiumReader: () async => false,
    postTourPaywallModeReader: () async => PostTourPaywallMode.soft,
    trialExpiredReader: () async => trialExpired,
    paywallArmReader: () async => arm,
    notificationService: _FakeNotif(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });
  tearDown(SupabaseSyncService.debugReset);

  test('defaults to post_tour_soft + unassigned before hydration', () {
    final s = buildSession();
    expect(s.softPaywallPlacement, AnalyticsEvents.placementPostTourSoft);
    expect(s.paywallArm, AnalyticsEvents.armUnassigned);
    s.dispose();
  });

  test('treatment user whose trial expired → post_trial_soft', () async {
    final s = buildSession(
      trialExpired: true,
      arm: PaywallArm.treatmentReverseTrial,
    );
    await s.hydrateOnboardingGate();
    expect(s.softPaywallPlacement, AnalyticsEvents.placementPostTrialSoft,
        reason: 'expired reverse trial = treatment Day-3 soft gate');
    expect(s.paywallArm, 'treatment_reverse_trial');
    s.dispose();
  });

  test('control user (no trial) → post_tour_soft', () async {
    final s = buildSession(
      trialExpired: false,
      arm: PaywallArm.controlNoTrial,
    );
    await s.hydrateOnboardingGate();
    expect(s.softPaywallPlacement, AnalyticsEvents.placementPostTourSoft,
        reason: 'control arm keeps the generic post-tour soft placement');
    expect(s.paywallArm, 'control_no_trial');
    s.dispose();
  });

  test('sign-out resets the placement back to the post_tour_soft default',
      () async {
    final s = buildSession(
      trialExpired: true,
      arm: PaywallArm.treatmentReverseTrial,
    );
    await s.hydrateOnboardingGate();
    expect(s.softPaywallPlacement, AnalyticsEvents.placementPostTrialSoft);

    // Mirror the signedOut reset path used by the other gate flags so the next
    // user on a shared device isn't tagged with the previous user's arm/expiry.
    s.resetSoftPaywallPlacementForSignOut();
    expect(s.softPaywallPlacement, AnalyticsEvents.placementPostTourSoft);
    expect(s.paywallArm, AnalyticsEvents.armUnassigned);
    s.dispose();
  });
}

class _FakeNotif extends NotificationService {
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}
