// Two cross-user analytics leaks, found in review after W6 landed.
//
// Both have the same shape: a value that belongs to ONE USER surviving into
// another user's session on the same device. This project's QA device is
// explicitly shared across test accounts, so "shared device" is not a
// hypothetical here — it is the primary way the app is tested.
//
//   P1 — `AnalyticsService.identify()` was called from exactly three places,
//        all onboarding/signup screens. A RETURNING user signing into an
//        existing account never called it. So `names_met` — a People property
//        written during authenticated hydration — landed on whatever Mixpanel
//        identity happened to be current, which after a sign-out `reset()` is
//        the ANONYMOUS one. The property becomes unreliable for exactly the
//        users it describes best (returning ones), and pollutes anonymous
//        profiles on the way.
//
//   P2 — `onboarding_flow` was registered through `cacheDeviceSuperProperties`,
//        which is the DURABLE set `resetForSignOut` deliberately re-applies. So
//        the next user to sign in on that device inherited the previous user's
//        onboarding cohort — permanently, if their own profile has no flow to
//        overwrite it with.
//
//        That was my call and my reasoning was wrong: "which experience a user
//        ran is a fact about the install" is true on a single-user device and
//        false on a shared one. The flow is USER-scoped.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, AuthChangeEvent;
import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/notification_service.dart';

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

class _SpyAnalytics extends AnalyticsService {
  final identified = <String>[];
  final registered = <Map<String, dynamic>>[];
  var resets = 0;

  @override
  void identify(String userId) => identified.add(userId);

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      registered.add(Map<String, dynamic>.from(props));

  @override
  void reset() => resets++;
}

void main() {
  tearDown(() {
    AppSessionNotifier.onIdentifyUser = null;
    AppSessionNotifier.onAnalyticsReset = null;
    AppSessionNotifier.onOnboardingFlowResolved = null;
  });

  group('P1 — identity is established on the authenticated-session path', () {
    test('the hook exists and fires with the signed-in user id', () async {
      // The fix is a hook on the session rather than a fourth call site on a
      // screen: onboarding already had three, and adding a fourth for the
      // sign-in screen would leave `initialSession` (a relaunch with a live
      // token) still unidentified.
      final seen = <String>[];
      AppSessionNotifier.onIdentifyUser = seen.add;

      final controller = StreamController<AuthState>.broadcast();
      addTearDown(controller.close);
      AppSessionNotifier(
        initialOnboarded: true,
        authStateChanges: controller.stream,
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'user-returning',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        notificationService: _FakeNotificationService(),
      );

      controller.add(AuthState(AuthChangeEvent.signedIn, null));
      await Future<void>.delayed(Duration.zero);

      expect(seen, contains('user-returning'),
          reason: 'a returning user never passes through the signup screens '
              'that call identify(), so their People properties would attach '
              'to the anonymous profile');
    });

    test('a relaunch with a live token identifies too', () async {
      // `initialSession` is the ordinary "app opened, already signed in" case —
      // by far the most common authenticated event, and the one a signup-screen
      // call site can never cover.
      final seen = <String>[];
      AppSessionNotifier.onIdentifyUser = seen.add;

      final controller = StreamController<AuthState>.broadcast();
      addTearDown(controller.close);
      AppSessionNotifier(
        initialOnboarded: true,
        authStateChanges: controller.stream,
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'user-relaunch',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        notificationService: _FakeNotificationService(),
      );

      controller.add(AuthState(AuthChangeEvent.initialSession, null));
      await Future<void>.delayed(Duration.zero);

      expect(seen, contains('user-relaunch'));
    });

    test('a THROWING identify hook cannot break the session', () async {
      AppSessionNotifier.onIdentifyUser = (_) => throw StateError('mixpanel');

      final controller = StreamController<AuthState>.broadcast();
      addTearDown(controller.close);
      AppSessionNotifier(
        initialOnboarded: true,
        authStateChanges: controller.stream,
        isAuthenticatedProvider: () => true,
        currentUserIdProvider: () => 'user-1',
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => true,
        notificationService: _FakeNotificationService(),
      );

      controller.add(AuthState(AuthChangeEvent.signedIn, null));
      await expectLater(
          Future<void>.delayed(Duration.zero), completes);
    });

    test('an unauthenticated event identifies nobody', () async {
      final seen = <String>[];
      AppSessionNotifier.onIdentifyUser = seen.add;

      final controller = StreamController<AuthState>.broadcast();
      addTearDown(controller.close);
      AppSessionNotifier(
        initialOnboarded: false,
        authStateChanges: controller.stream,
        isAuthenticatedProvider: () => false,
        currentUserIdProvider: () => null,
        hydrateEconomyCache: () async {},
        hasCompletedOnboarding: () async => false,
        notificationService: _FakeNotificationService(),
      );

      controller.add(AuthState(AuthChangeEvent.signedIn, null));
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
    });
  });

  group('P2 — onboarding_flow is USER-scoped, not device-scoped', () {
    test('it does not survive a sign-out reset', () {
      // MUTATION: route it back through `cacheDeviceSuperProperties` → this
      // fails, because the durable set is re-applied verbatim after reset and
      // the next user inherits the previous user's cohort.
      final analytics = _SpyAnalytics();

      // Boot: the genuinely device-scoped set.
      analytics.cacheDeviceSuperProperties({
        'platform': 'ios',
        'app_version': '1.3.0+1',
      });
      // A user's flow resolves — user-scoped, so a plain registration.
      analytics.setSuperProperties({'onboarding_flow': 'reel_v1'});

      analytics.registered.clear();
      analytics.resetForSignOut();

      final reapplied = analytics.registered.single;
      expect(reapplied['platform'], 'ios',
          reason: 'build context genuinely belongs to the install');
      expect(reapplied['app_version'], '1.3.0+1');
      expect(
        reapplied.containsKey('onboarding_flow'),
        isFalse,
        reason: 'which onboarding a user ran is a fact about THAT USER. On a '
            'shared device — which is how this project QAs — re-applying it '
            'stamps the next user with the previous one\'s cohort, forever if '
            'their own profile has no flow to overwrite it.',
      );
    });

    test('main.dart registers the flow WITHOUT the durable cache', () {
      // Source pin: the defect was in which method the call site chose, not in
      // any function this test can invoke.
      final source = File('lib/main.dart').readAsStringSync();
      final hook = RegExp(
        r'onOnboardingFlowResolved\s*=\s*\(flow\)\s*=>\s*\n?\s*analytics\.(\w+)\(',
      ).firstMatch(source);

      expect(hook, isNotNull,
          reason: 'the wiring moved — re-point this pin, do not delete it');
      expect(hook!.group(1), 'setSuperProperties',
          reason: 'cacheDeviceSuperProperties puts it in the set that '
              'resetForSignOut re-applies to the NEXT user');
    });
  });
}
