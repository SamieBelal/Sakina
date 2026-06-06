import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart'
    show onboardingTourSeenFlag;
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/onboarding_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

AppSessionNotifier buildSession({
  bool isAuthenticated = true,
  String? uid = 'user-1',
  bool premium = false,
  bool flowEnabled = true,
}) {
  return AppSessionNotifier(
    initialOnboarded: true,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => isAuthenticated,
    currentUserIdProvider: () => uid,
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => true,
    isPremiumReader: () async => premium,
    hardPaywallFlowReader: () async => flowEnabled,
    notificationService: _FakeNotificationService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('flags default to ungated before hydration', () {
    final session = buildSession();
    expect(session.tourCompleted, true);
    expect(session.paywallCleared, true);
    expect(session.hardPaywallFlowEnabled, false);
    session.dispose();
  });

  test('hydrateOnboardingGate loads real values from caches + readers',
      () async {
    // New user mid-gate: tour not seen, latch explicitly false.
    SharedPreferences.setMockInitialValues({
      onboardingTourSeenFlag('user-1'): false,
      'onboarding_paywall_cleared:user-1': false,
    });
    final session = buildSession(premium: false);

    await session.hydrateOnboardingGate();

    expect(session.tourCompleted, false);
    expect(session.paywallCleared, false);
    expect(session.isPremiumCached, false);
    expect(session.hardPaywallFlowEnabled, true);
    session.dispose();
  });

  test('hydrate treats absent latch as cleared (grandfather guard)', () async {
    SharedPreferences.setMockInitialValues({}); // nothing set
    final session = buildSession();

    await session.hydrateOnboardingGate();

    // Tour seen flag absent → tourCompleted false, BUT latch absent → cleared.
    expect(session.paywallCleared, true);
    session.dispose();
  });

  test('enterOnboardingGate puts a new user into the gate + persists latch',
      () async {
    final session = buildSession();
    var notified = 0;
    session.addListener(() => notified++);

    await session.enterOnboardingGate();

    expect(session.tourCompleted, false);
    expect(session.paywallCleared, false);
    expect(await OnboardingGateService().isPaywallCleared(), false);
    expect(notified, greaterThan(0));
    session.dispose();
  });

  test('markTourCompleted + markPaywallCleared flip flags and notify', () async {
    final session = buildSession();
    await session.enterOnboardingGate(); // both false now

    var notified = 0;
    session.addListener(() => notified++);

    session.markTourCompleted();
    expect(session.tourCompleted, true);

    session.markPaywallCleared();
    expect(session.paywallCleared, true);

    expect(notified, 2);
    session.dispose();
  });

  test('premium reader populates the cached premium flag', () async {
    final session = buildSession(premium: true);
    await session.hydrateOnboardingGate();
    expect(session.isPremiumCached, true);
    session.dispose();
  });

  test(
      'latch written during onboarding survives to the NEXT session hydrate '
      '(cold-relaunch determinism — no batch-sync race)', () async {
    // Session 1: new user finishes onboarding → enterOnboardingGate persists
    // the latch=false locally (this is what completeOnboarding now does).
    final s1 = buildSession();
    await s1.enterOnboardingGate();
    s1.dispose();

    // Session 2: cold relaunch. hydrateOnboardingGate reads the persisted
    // latch BEFORE any economy batch sync. It must come back gated (false), so
    // the synchronous redirect + one-shot tour-start see the real value — not
    // the ungated default that caused the legacy-skippable-tour race.
    final s2 = buildSession();
    await s2.hydrateOnboardingGate();
    expect(s2.paywallCleared, false,
        reason: 'persisted latch must gate the user on the next launch');
    s2.dispose();
  });
}

class _FakeNotificationService extends NotificationService {
  @override
  Future<void> identifyUser(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> syncTimezone() async {}
  @override
  Future<void> requestPermissionIfPreviouslyEnabled() async {}
}
