import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Pins the soft-paywall placement seam AFTER the reverse-trial close-out
/// (W5 Wave A, 2026-08-01).
///
/// This file used to pin the arm-aware resolution: `post_trial_soft` +
/// `treatment_reverse_trial` for a treatment user whose 3-day app-granted trial
/// had lapsed, `post_tour_soft` + `control_no_trial` for the control arm. The
/// experiment is retired and nothing grants that trial any more, so both
/// getters are frozen constants — and THAT is what needs pinning, because a
/// future reader who re-introduces per-user resolution here would silently
/// revive `paywall_exp_arm`, which is frozen as Mixpanel history and must never
/// be re-added or recycled.
AppSessionNotifier buildSession({
  String? uid = 'u1',
  bool isPremium = false,
}) {
  return AppSessionNotifier(
    initialOnboarded: true,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => true,
    currentUserIdProvider: () => uid,
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => true,
    isPremiumReader: () async => isPremium,
    postTourPaywallModeReader: () async => PostTourPaywallMode.soft,
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

  test('post_tour_soft + unassigned before hydration', () {
    final s = buildSession();
    expect(s.softPaywallPlacement, PaywallPlacement.postTourSoft);
    expect(s.paywallArm, AnalyticsEvents.armUnassigned);
    s.dispose();
  });

  test('hydration cannot move either off its frozen value', () async {
    final s = buildSession();
    await s.hydrateOnboardingGate();
    expect(s.softPaywallPlacement, PaywallPlacement.postTourSoft,
        reason: 'post_trial_soft was the lapsed-reverse-trial gate; retired');
    expect(s.paywallArm, AnalyticsEvents.armUnassigned,
        reason: 'paywall_exp_arm is frozen as history — never re-assigned');
    s.dispose();
  });

  test('a signed-out session reports the same frozen pair', () async {
    final s = buildSession(uid: null);
    await s.hydrateOnboardingGate();
    expect(s.softPaywallPlacement, PaywallPlacement.postTourSoft);
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
