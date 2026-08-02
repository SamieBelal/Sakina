// W6 Wave A — the boot half of the super-property set.
//
// Two things are pinned here and both were live defects:
//
//   1. `flag_hard_paywall` booted with `fallback: false` while the prod value
//      is `true` (main.dart, §2e.1). On a FIRST install there is no cached
//      app_config, so the analytics read returns the fallback while the
//      behavioural read — which happens later, after the fire-and-forget prime
//      lands — sees `true`. The result is a super property that disagrees with
//      the app's own behaviour on exactly the cohort being measured, at the
//      widest point of the funnel.
//
//   2. `onboarding_flow` is registered for RETURNING users at boot, from
//      AppSession. It must follow the `installId` precedent and be OMITTED when
//      unknown rather than registered null — a null super property looks like a
//      real value in a Mixpanel breakdown, an absent one does not.
//
// See docs/superpowers/plans/2026-08-01-one-ship-06-instrumentation.md §4 Wave A.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/install_id_service.dart' show installIdPropertyName;
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import 'package:sakina/core/app_session.dart';
import 'package:sakina/services/analytics_service.dart';

class _SpyAnalytics extends AnalyticsService {
  final devicePropCalls = <Map<String, dynamic>>[];
  final superPropCalls = <Map<String, dynamic>>[];
  final tracked = <String>[];

  @override
  void cacheDeviceSuperProperties(Map<String, dynamic> props) {
    devicePropCalls.add(Map<String, dynamic>.from(props));
    super.cacheDeviceSuperProperties(props);
  }

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superPropCalls.add(Map<String, dynamic>.from(props));

  @override
  void setSuperPropertiesOnce(Map<String, dynamic> props) {}

  @override
  void removeSuperProperty(String name) {}

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      tracked.add(event);

  Map<String, dynamic> get allDeviceProps => {
        for (final call in devicePropCalls) ...call,
      };
}

void main() {
  late _SpyAnalytics analytics;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    analytics = _SpyAnalytics();
  });

  Future<void> boot() => registerBootstrapAnalytics(
        analytics: analytics,
        prefs: prefs,
        platform: 'ios',
        appVersion: '1.3.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: true,
        flagGuidedTour: true,
        isPremium: false,
        installId: 'install-abc',
      );

  group('onboarding_flow is registered from the session hook', () {
    // NOT from registerBootstrapAnalytics: AppSessionNotifier is constructed
    // well after it, and a returning user's flow arrives with the first
    // sync_all_user_data. Reading it at boot would register null every launch
    // and call that a value.
    tearDown(() => AppSessionNotifier.onOnboardingFlowResolved = null);

    test('a resolved flow reaches the hook', () {
      String? seen;
      AppSessionNotifier.onOnboardingFlowResolved = (f) => seen = f;

      _session().setOnboardingFlow('reel_v1');

      expect(seen, 'reel_v1');
    });

    test('a NULL flow never reaches it', () {
      // mirrorServerOnboardingFlow documents why: null means "the server didn't
      // say", never "not the reel flow". Registering that would be a lie that
      // persists on-device forever.
      var calls = 0;
      AppSessionNotifier.onOnboardingFlowResolved = (_) => calls++;

      _session().setOnboardingFlow(null);

      expect(calls, 0);
    });

    test('an EMPTY flow never reaches it either', () {
      var calls = 0;
      AppSessionNotifier.onOnboardingFlowResolved = (_) => calls++;

      _session().setOnboardingFlow('');

      expect(calls, 0);
    });

    test('setting the SAME flow twice fires once', () {
      var calls = 0;
      AppSessionNotifier.onOnboardingFlowResolved = (_) => calls++;
      final session = _session();

      session.setOnboardingFlow('reel_v1');
      session.setOnboardingFlow('reel_v1');

      expect(calls, 1, reason: 'the early-return on an unchanged value already '
          'guards this; re-registering an identical super property is harmless '
          'but a duplicate hook call would hide a real double-write');
    });

    test('a THROWING hook cannot break the session', () {
      // setOnboardingFlow is read by the router redirect during a build.
      AppSessionNotifier.onOnboardingFlowResolved =
          (_) => throw StateError('reporter');

      expect(() => _session().setOnboardingFlow('reel_v1'),
          returnsNormally);
    });
  });

  group('the boot set still carries what it always did', () {
    test('platform, app_version, install_id and the three flags', () async {
      await boot();
      final props = analytics.allDeviceProps;

      expect(props['platform'], 'ios');
      expect(props['app_version'], '1.3.0+1');
      expect(props['flag_hard_paywall'], true);
      expect(props[installIdPropertyName], 'install-abc');
    });

    test('boot registration flips the ordering guard', () async {
      // Wave 0's assert depends on this: registerBootstrapAnalytics is what
      // makes every later track() legal.
      expect(analytics.bootPropertiesRegistered, isFalse);
      await boot();
      expect(analytics.bootPropertiesRegistered, isTrue);
    });
  });

  group('the flag_hard_paywall fallback matches production', () {
    test('main.dart reads the flag with fallback: true, not false', () async {
      // Source-level pin, because the defect is in the CALL SITE's default
      // rather than in any function this test could invoke. The prod value is
      // `true`; a `false` fallback mis-segments every first install.
      final source = File('lib/main.dart').readAsStringSync();
      final call = RegExp(
        r"getBool\(\s*'hard_paywall_after_tour_enabled'\s*,\s*fallback:\s*(\w+)\s*\)",
      ).firstMatch(source);

      expect(call, isNotNull,
          reason: 'the flag read moved — re-point this pin rather than '
              'deleting it');
      expect(call!.group(1), 'true',
          reason: 'prod app_config has hard_paywall_after_tour_enabled=true. '
              'A false fallback means a first install stamps '
              'flag_hard_paywall=false onto every event before the config '
              'prime lands, while the behavioural read later in the session '
              'sees true — the super property and the app disagree, silently, '
              'at the widest point of the funnel.');
    });
  });
}

/// Minimal session for the hook tests — no auth, no hydration, no network.
/// `setOnboardingFlow` is synchronous and touches none of it.
AppSessionNotifier _session() => AppSessionNotifier(
      initialOnboarded: false,
      authStateChanges: StreamController<AuthState>.broadcast().stream,
      isAuthenticatedProvider: () => false,
      currentUserIdProvider: () => null,
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => false,
    );
