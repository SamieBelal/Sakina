import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/router.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Builds a session and drives it into an exact gate state. Hydration sets the
/// kill switch + premium; enter/mark place the user at a precise (tour, cleared)
/// combination so each branch is deterministic.
Future<AppSessionNotifier> sessionInState({
  bool auth = true,
  bool onboarded = true,
  bool flow = true,
  bool tourDone = false,
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
  await s.enterOnboardingGate(); // tour=false, cleared=false
  if (tourDone) s.markTourCompleted();
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
    final s = await sessionInState(flow: false, tourDone: false, cleared: false);
    expect(redirect('/', s), isNull);
  });

  group('flow ON', () {
    test('new user, tour not done → stays in app shell (tour overlay drives)',
        () async {
      final s = await sessionInState(tourDone: false, cleared: false);
      expect(redirect('/', s), isNull);
    });

    test('tour-stage user sitting on the wall → sent home', () async {
      final s = await sessionInState(tourDone: false, cleared: false);
      expect(redirect(kOnboardingPaywallPath, s), '/');
    });

    test('tour done, not cleared → forced to the hard wall', () async {
      final s = await sessionInState(tourDone: true, cleared: false);
      expect(redirect('/', s), kOnboardingPaywallPath);
      expect(redirect('/collection', s), kOnboardingPaywallPath);
    });

    test('already on the wall → stays (no redirect loop)', () async {
      final s = await sessionInState(tourDone: true, cleared: false);
      expect(redirect(kOnboardingPaywallPath, s), isNull);
    });

    test('cleared latch → app, and bounced off the wall', () async {
      final s = await sessionInState(tourDone: true, cleared: true);
      expect(redirect('/', s), isNull);
      expect(redirect(kOnboardingPaywallPath, s), '/');
    });

    test('premium → app even before tour done', () async {
      final s = await sessionInState(tourDone: false, premium: true);
      expect(redirect('/', s), isNull);
    });

    test('valve bypass → app for this session even when tour done + uncleared',
        () async {
      final s = await sessionInState(tourDone: true, cleared: false, valve: true);
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
