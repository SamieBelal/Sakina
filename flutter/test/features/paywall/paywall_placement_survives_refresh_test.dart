// W5 Wave C.1 regression — the placement must survive a router RE-PARSE.
//
// `pushPaywall` carries the placement as the route's `extra`, which is only
// half the story: GoRouter serializes `extra` every time it reports new route
// information and decodes it again whenever it re-parses that information —
// and it re-parses on every `refreshListenable` notification. The app's
// `refreshListenable` is `AppSessionNotifier`, which notifies on hydration,
// Supabase token refresh, sign-out and the gate latches.
//
// With GoRouter's default `json.encode` round trip an enum cannot be
// represented, so the decode yields `null` and the paywall comes back with NO
// placement — the `placementFromRouteExtra` assert in debug, a silent
// `soft_inapp` in release. `paywallPlacementExtraCodec` (wired in
// `buildRouter`) is what closes that hole; these tests pin it.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/router.dart';
import 'package:sakina/features/onboarding/onboarding_stage.dart';
import 'package:sakina/features/onboarding/screens/paywall_screen.dart';
import 'package:sakina/features/paywall/paywall_navigation.dart';
import 'package:sakina/features/paywall/paywall_placement.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

Future<AppSessionNotifier> clearedSession() async {
  final s = AppSessionNotifier(
    initialOnboarded: true,
    authStateChanges: const Stream.empty(),
    isAuthenticatedProvider: () => true,
    currentUserIdProvider: () => 'u1',
    hydrateEconomyCache: () async {},
    hasCompletedOnboarding: () async => true,
    isPremiumReader: () async => false,
    postTourPaywallModeReader: () async => PostTourPaywallMode.off,
    notificationService: _FakeNotif(),
  );
  await s.hydrateOnboardingGate();
  s.markPaywallCleared();
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

  group('paywallPlacementExtraCodec', () {
    test('round-trips every placement through a serializable primitive', () {
      for (final placement in PaywallPlacement.values) {
        final encoded = paywallPlacementExtraCodec.encode(placement);
        expect(encoded, isA<String>(),
            reason: 'the encoded form travels over the platform channel, so '
                'it must be a primitive');
        expect(paywallPlacementExtraCodec.decode(encoded), placement);
      }
    });

    test('a null extra (every other route) stays null', () {
      expect(paywallPlacementExtraCodec.encode(null), isNull);
      expect(paywallPlacementExtraCodec.decode(null), isNull);
    });

    test('the enum is NOT representable by the default json round trip', () {
      // This is the whole reason the codec exists — documenting the failure
      // mode so a future "do we still need this?" has an answer.
      expect(() => json.encode(PaywallPlacement.postTrialSoft),
          throwsA(isA<JsonUnsupportedObjectError>()));
    });
  });

  testWidgets('a bare GoRouter re-parse keeps the pushed placement',
      (tester) async {
    final refresh = ChangeNotifier();
    addTearDown(refresh.dispose);
    final seen = <PaywallPlacement>[];

    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: refresh,
      extraCodec: paywallPlacementExtraCodec,
      routes: [
        GoRoute(path: '/', builder: (c, s) => const Text('home')),
        GoRoute(
          path: paywallRoutePath,
          builder: (c, s) {
            seen.add(placementFromRouteExtra(s.extra));
            return const Text('paywall');
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    pushPaywallOn(router, placement: PaywallPlacement.postTrialSoft);
    await tester.pumpAndSettle();
    expect(seen, [PaywallPlacement.postTrialSoft]);

    // The re-parse. Without the codec this rebuild resolves to `null` →
    // assert (debug) / softInApp (release).
    refresh.notifyListeners();
    await tester.pumpAndSettle();

    expect(seen.length, greaterThan(1),
        reason: 'the notification must have re-parsed and rebuilt the route');
    expect(seen.last, PaywallPlacement.postTrialSoft,
        reason: 'the placement must survive the re-parse');
  });

  testWidgets('the real router keeps the placement across a session notify',
      (tester) async {
    final session = await clearedSession();
    addTearDown(session.dispose);
    final router = buildRouter(appSession: session);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [appSessionProvider.overrideWithValue(session)],
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    // A deliberately NON-default placement, so the release-mode fallback
    // (softInApp) would be visible as a wrong value rather than hiding behind
    // the value every in-app entry point happens to use today.
    pushPaywallOn(router, placement: PaywallPlacement.postTrialSoft);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // reveal the close X

    PaywallPlacement rendered() =>
        tester.widget<PaywallScreen>(find.byType(PaywallScreen)).placement;

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(rendered(), PaywallPlacement.postTrialSoft);

    // Any AppSessionNotifier notification reaches the router the same way —
    // hydration completing, a Supabase token refresh, sign-out, the gate
    // latches. `bypassGateForSession` is simply the one with no async setup.
    session.bypassGateForSession();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PaywallScreen), findsOneWidget,
        reason: 'the notification must not have routed the paywall away');
    expect(rendered(), PaywallPlacement.postTrialSoft,
        reason: 'a session notification re-parses the route information; the '
            'placement must not decay to softInApp');
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
