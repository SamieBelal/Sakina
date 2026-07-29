import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/router.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart'
    show onboardingTourSeenFlag;
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/onboarding_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Builds a session and drives it into an exact gate state. Hydration sets the
/// kill switch + premium; enter/mark place the user at a precise `cleared`
/// value so each branch is deterministic.
///
/// The `tourDone` axis is gone: the guided tour was deleted 2026-07-28 (One
/// Ship W2 §F1a) and `OnboardingStage` has no `tour` branch, so "cleared" is
/// the only gate state left.
Future<AppSessionNotifier> sessionInState({
  bool auth = true,
  bool onboarded = true,
  bool flow = true,
  bool cleared = false,
  bool premium = false,
  bool valve = false,
}) async {
  final s = AppSessionNotifier(
    initialOnboarded: onboarded,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => auth,
    currentUserIdProvider: () => 'u1',
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => onboarded,
    isPremiumReader: () async => premium,
    hardPaywallFlowReader: () async => flow,
    notificationService: _FakeNotif(),
  );
  await s.hydrateOnboardingGate();
  // Place into the gate, then nudge to the requested combination.
  await s.enterOnboardingGate(); // cleared=false
  if (cleared) s.markPaywallCleared();
  if (valve) s.bypassGateForSession();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });
  tearDown(SupabaseSyncService.debugReset);

  String? redirect(String path, AppSessionNotifier s) =>
      onboardingGateRedirect(currentPath: path, appSession: s);

  group('pre-auth funnel always allowed', () {
    for (final p in ['/onboarding', '/onboarding/x', '/signin', '/welcome']) {
      test('$p → null even when unauthenticated', () async {
        final s = await sessionInState(auth: false, onboarded: false);
        expect(redirect(p, s), isNull);
      });
    }
  });

  test('unauthenticated on a protected path → /welcome', () async {
    final s = await sessionInState(auth: false, onboarded: false);
    expect(redirect('/', s), '/welcome');
  });

  test('kill switch OFF → app (legacy), no gating', () async {
    final s = await sessionInState(flow: false, cleared: false);
    expect(redirect('/', s), isNull);
  });

  // -------------------------------------------------------------------------
  // §F1a RELEASE PATH — the highest-value test in the wave.
  //
  // Before this change a user with `tour_seen = false` + `paywall_cleared =
  // false` resolved to stage `tour`. The router let tour-stage users roam and
  // the controller could decline to start (kill switch, cold-offline, checked-in
  // today), so they were parked in the app with no tour AND no paywall — the
  // §F0 stranding bug. These pin that the same on-disk state now falls THROUGH
  // to a real paywall surface, i.e. that we free those users rather than
  // re-trapping them.
  // -------------------------------------------------------------------------
  group('stuck mid-tour users are released', () {
    /// A user exactly as they exist on disk today: signed up after the gate
    /// shipped, abandoned inside the tour. Nothing about this session is
    /// synthesised — it hydrates from prefs the way a cold launch does.
    Future<AppSessionNotifier> stuckUser({
      bool premium = false,
      String mode = 'hard',
    }) async {
      SharedPreferences.setMockInitialValues({
        // The abandoned-mid-tour marker.
        onboardingTourSeenFlag('u1'): false,
      });
      await OnboardingGateService().setPaywallCleared(false);

      final s = AppSessionNotifier(
        initialOnboarded: true,
        authStateChanges: const Stream.empty(),
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'u1',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        isPremiumReader: () async => premium,
        hardPaywallFlowReader: () async => mode == 'hard',
        postTourPaywallModeReader: () async => switch (mode) {
          'soft' => PostTourPaywallMode.soft,
          'off' => PostTourPaywallMode.off,
          _ => PostTourPaywallMode.hard,
        },
        notificationService: _FakeNotif(),
      );
      await s.hydrateOnboardingGate();
      return s;
    }

    test('hard mode → pulled onto the hard wall, not left roaming', () async {
      final s = await stuckUser();
      addTearDown(s.dispose);
      expect(s.paywallCleared, isFalse,
          reason: 'precondition: this user never cleared the wall');
      expect(redirect('/', s), kOnboardingPaywallPath);
      expect(redirect('/collection', s), kOnboardingPaywallPath);
    });

    test('soft mode → pulled onto the dismissible wall', () async {
      final s = await stuckUser(mode: 'soft');
      addTearDown(s.dispose);
      expect(redirect('/', s), kOnboardingSoftPaywallPath);
    });

    test('post_tour_paywall_mode = off → straight into the app', () async {
      final s = await stuckUser(mode: 'off');
      addTearDown(s.dispose);
      expect(redirect('/', s), isNull);
    });

    test('premium stuck user → straight into the app (no wall)', () async {
      final s = await stuckUser(premium: true);
      addTearDown(s.dispose);
      expect(redirect('/', s), isNull);
    });

    test('the tour-seen flag no longer influences routing at all', () async {
      // Same session, opposite flag value → identical redirect. The flag is
      // inert, which is what makes the stage un-enterable rather than merely
      // unreached.
      final stuck = await stuckUser();
      addTearDown(stuck.dispose);
      final stuckTarget = redirect('/', stuck);

      SharedPreferences.setMockInitialValues({
        onboardingTourSeenFlag('u1'): true,
      });
      await OnboardingGateService().setPaywallCleared(false);
      final seen = await sessionInState(cleared: false);
      addTearDown(seen.dispose);

      expect(redirect('/', seen), stuckTarget);
    });
  });

  group('flow ON', () {
    test('new user, not cleared → forced to the hard wall', () async {
      final s = await sessionInState(cleared: false);
      expect(redirect('/', s), kOnboardingPaywallPath);
      expect(redirect('/collection', s), kOnboardingPaywallPath);
    });

    test('already on the wall → stays (no redirect loop)', () async {
      final s = await sessionInState(cleared: false);
      expect(redirect(kOnboardingPaywallPath, s), isNull);
    });

    test('cleared latch → app, and bounced off the wall', () async {
      final s = await sessionInState(cleared: true);
      expect(redirect('/', s), isNull);
      expect(redirect(kOnboardingPaywallPath, s), '/');
    });

    test('premium → app', () async {
      final s = await sessionInState(premium: true);
      expect(redirect('/', s), isNull);
    });

    test('valve bypass → app for this session even when uncleared', () async {
      final s = await sessionInState(cleared: false, valve: true);
      expect(redirect('/', s), isNull);
    });
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
