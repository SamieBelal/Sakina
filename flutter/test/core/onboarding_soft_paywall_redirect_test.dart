import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/router.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Phase A — the soft post-tour paywall routing seam. Pins that a tour-done,
/// uncleared user in `soft` mode is routed to the dismissible soft paywall (not
/// the no-X hard wall), and that the route is NOT a navigation trap.
Future<AppSessionNotifier> softSession({
  bool tourDone = true,
  bool cleared = false,
  bool premium = false,
}) async {
  final s = AppSessionNotifier(
    initialOnboarded: true,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => true,
    currentUserIdProvider: () => 'u1',
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => true,
    isPremiumReader: () async => premium,
    // Force the post-tour mode to `soft` for these tests.
    postTourPaywallModeReader: () async => PostTourPaywallMode.soft,
    notificationService: _FakeNotif(),
  );
  await s.hydrateOnboardingGate();
  await s.enterOnboardingGate();
  if (tourDone) s.markTourCompleted();
  if (cleared) s.markPaywallCleared();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDisablePaywallAnimations = true;
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });
  tearDown(() {
    debugDisablePaywallAnimations = false;
    SupabaseSyncService.debugReset();
  });

  String? redirect(String path, AppSessionNotifier s) =>
      onboardingGateRedirect(currentPath: path, appSession: s);

  test('post-tour mode resolves to soft on the session', () async {
    final s = await softSession();
    expect(s.postTourPaywallMode, PostTourPaywallMode.soft);
  });

  test(
      'soft mode, tour done, uncleared → presented from ANY in-app route '
      '(incl. /duas, the real tour-exit route)', () async {
    final s = await softSession(tourDone: true, cleared: false);
    // Regression for the '/'-only pull that silently skipped the wall: the slim
    // tour completes on /duas (duaBuildComplete), so the gate MUST present the
    // soft paywall from there, not just from home.
    expect(redirect('/', s), kOnboardingSoftPaywallPath);
    expect(redirect('/duas', s), kOnboardingSoftPaywallPath,
        reason: 'slim tour ends on /duas — wall must fire there');
    expect(redirect('/collection', s), kOnboardingSoftPaywallPath);
  });

  test('soft paywall is dismissible — clearing is the exit, not lenient '
      'routing', () async {
    final s = await softSession(tourDone: true, cleared: false);
    // While on the soft paywall itself the redirect leaves you put (no bounce);
    // "soft" is enforced by the X → markPaywallCleared (see the cleared test
    // below), NOT by the redirect declining to present it.
    expect(redirect(kOnboardingSoftPaywallPath, s), isNull);
  });

  test('cleared (dismissed) → app, bounced off the soft paywall path',
      () async {
    final s = await softSession(tourDone: true, cleared: true);
    expect(redirect('/', s), isNull);
    expect(redirect(kOnboardingSoftPaywallPath, s), '/');
  });

  test('premium short-circuits the soft gate', () async {
    final s = await softSession(tourDone: true, premium: true);
    expect(redirect('/', s), isNull);
  });

  testWidgets(
      'router presents a DISMISSIBLE soft paywall, and dismiss routes to app',
      (tester) async {
    final s = await softSession(tourDone: true, cleared: false);
    addTearDown(s.dispose);
    final router = buildRouter(appSession: s);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [appSessionProvider.overrideWithValue(s)],
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // The gate redirect lands the user on the soft paywall route.
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // reveal the close X

    expect(find.byType(PaywallScreen), findsOneWidget,
        reason: 'soft paywall route must render the paywall');
    // Dismissible: the close X is present (unlike the hard wall).
    expect(find.byIcon(Icons.close_rounded), findsOneWidget,
        reason: 'soft paywall must be dismissible (has the X)');

    // Tapping X dismisses → onComplete marks cleared + routes home. Use bounded
    // pumps (not pumpAndSettle): the home shell has repeating loaders/animations
    // that never settle.
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(s.paywallCleared, isTrue,
        reason: 'dismiss must clear the latch so the stage flips to app');
    expect(find.byType(PaywallScreen), findsNothing,
        reason: 'after dismiss the user is routed off the paywall into the app');
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
