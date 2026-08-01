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

  group('the compound extra (placement + trigger value line)', () {
    const line = 'Your reflections for this week are used — '
        'Premium is unlimited.';

    test('round-trips BOTH the placement and the line', () {
      const extra = PaywallRouteExtra(
        placement: PaywallPlacement.softInApp,
        valueLine: line,
      );
      final encoded = paywallPlacementExtraCodec.encode(extra);
      expect(encoded, isA<String>(),
          reason: 'every encoded extra stays a single primitive, so nothing '
              'depends on how a map survives the platform hop');

      final decoded = paywallPlacementExtraCodec.decode(encoded);
      expect(decoded, isA<PaywallRouteExtra>());
      expect(placementFromRouteExtra(decoded), PaywallPlacement.softInApp);
      expect(valueLineFromRouteExtra(decoded), line);
    });

    test('a line-less compound collapses to the bare encoding', () {
      // One encoding per logical value — otherwise two different strings mean
      // the same thing and any future comparison on the wire form is wrong.
      const extra = PaywallRouteExtra(placement: PaywallPlacement.softInApp);
      expect(
        paywallPlacementExtraCodec.encode(extra),
        paywallPlacementExtraCodec.encode(PaywallPlacement.softInApp),
      );
    });

    test('a bare placement still decodes to a bare placement', () {
      // The 13 entry points that carry no line must be untouched by this.
      final encoded =
          paywallPlacementExtraCodec.encode(PaywallPlacement.postTrialSoft);
      expect(paywallPlacementExtraCodec.decode(encoded),
          PaywallPlacement.postTrialSoft);
      expect(valueLineFromRouteExtra(paywallPlacementExtraCodec.decode(encoded)),
          isNull);
    });

    test('malformed compound JSON decodes to null, never throws', () {
      // A throw here would escape from inside GoRouter's re-parse and take
      // down the whole route rather than one attribution.
      expect(() => paywallPlacementExtraCodec.decode('{not json'),
          returnsNormally);
      expect(paywallPlacementExtraCodec.decode('{not json'), isNull);
      expect(paywallPlacementExtraCodec.decode('{"placement":"nope"}'), isNull);
    });

    test('a line containing JSON metacharacters survives intact', () {
      // Copy is authored by humans; an em-dash, a quote or a brace must not
      // corrupt the envelope.
      const nasty = 'Your "duas" {this week} are used — Premium is unlimited.';
      const extra = PaywallRouteExtra(
        placement: PaywallPlacement.softInApp,
        valueLine: nasty,
      );
      final decoded = paywallPlacementExtraCodec.decode(
        paywallPlacementExtraCodec.encode(extra),
      );
      expect(valueLineFromRouteExtra(decoded), nasty);
    });
  });

  testWidgets('a bare re-parse keeps the placement AND the value line',
      (tester) async {
    // The point of the whole exercise: a design that keeps the placement but
    // drops the line is the same bug wearing a different hat.
    const line = 'Your duʿās for this week are used — Premium is unlimited.';
    final refresh = ChangeNotifier();
    addTearDown(refresh.dispose);
    final placements = <PaywallPlacement>[];
    final lines = <String?>[];

    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: refresh,
      extraCodec: paywallPlacementExtraCodec,
      routes: [
        GoRoute(path: '/', builder: (c, s) => const Text('home')),
        GoRoute(
          path: paywallRoutePath,
          builder: (c, s) {
            placements.add(placementFromRouteExtra(s.extra));
            lines.add(valueLineFromRouteExtra(s.extra));
            return const Text('paywall');
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    pushPaywallOn(router,
        placement: PaywallPlacement.softInApp, valueLine: line);
    await tester.pumpAndSettle();
    expect(placements, [PaywallPlacement.softInApp]);
    expect(lines, [line]);

    refresh.notifyListeners();
    await tester.pumpAndSettle();

    expect(placements.length, greaterThan(1),
        reason: 'the notification must have re-parsed and rebuilt the route');
    expect(placements.last, PaywallPlacement.softInApp);
    expect(lines.last, line,
        reason: 'the value line must survive the re-parse, not just the '
            'placement');
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

  testWidgets('the REAL router keeps the value line across a session notify',
      (tester) async {
    // The end-to-end version: pushed through buildRouter, read off the live
    // PaywallScreen, and survives an AppSessionNotifier notification — the same
    // event (Supabase token refresh, hydration, sign-out, gate latches) that
    // used to drop the placement entirely.
    const line = 'Your reflections for this week are used — '
        'Premium is unlimited.';
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

    pushPaywallOn(router,
        placement: PaywallPlacement.softInApp, valueLine: line);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    PaywallScreen rendered() =>
        tester.widget<PaywallScreen>(find.byType(PaywallScreen));

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(rendered().placement, PaywallPlacement.softInApp);
    expect(rendered().softValueLine, line);

    session.bypassGateForSession();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(rendered().placement, PaywallPlacement.softInApp,
        reason: 'placement must survive, as before');
    expect(rendered().softValueLine, line,
        reason: 'and so must the line — keeping one but dropping the other is '
            'the same bug wearing a different hat');
  });

  testWidgets('a bare push leaves the paywall on its default line',
      (tester) async {
    // The 13 entry points that carry no trigger must be unaffected: null here
    // means PaywallCondensedPage keeps its period-agnostic default.
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

    pushPaywallOn(router, placement: PaywallPlacement.softInApp);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(
      tester.widget<PaywallScreen>(find.byType(PaywallScreen)).softValueLine,
      isNull,
    );
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
