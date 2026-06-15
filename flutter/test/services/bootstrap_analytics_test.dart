import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_service.dart';

/// Spy mirroring the harness in analytics_phase1_test.dart — captures
/// track / setSuperProperties / setUserProperties without a live Mixpanel.
class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];
  final superProps = <String, dynamic>{};
  final userProps = <String, dynamic>{};
  int resetCalls = 0;
  int flushCalls = 0;

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superProps.addAll(props);

  @override
  void setUserProperties(Map<String, dynamic> props) => userProps.addAll(props);

  @override
  void flush() => flushCalls++;

  // Simulate Mixpanel's real reset(): it clears ALL registered super properties
  // (and rotates distinct_id). That wipe is exactly what resetForSignOut must
  // recover the device props from.
  @override
  void reset() {
    resetCalls++;
    superProps.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registerBootstrapAnalytics (G-boot)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
        'registers all flag_* + platform/app_version + is_premium super '
        'properties from the passed values', () async {
      final spy = _SpyAnalytics();
      final prefs = await SharedPreferences.getInstance();

      await registerBootstrapAnalytics(
        analytics: spy,
        prefs: prefs,
        platform: 'iOS',
        appVersion: '1.2.3+45',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagTourAb: true,
        flagGuidedTour: false,
        isPremium: true,
      );

      expect(spy.superProps['platform'], 'iOS');
      expect(spy.superProps['app_version'], '1.2.3+45');
      expect(spy.superProps['flag_onboarding_trim'], true);
      expect(spy.superProps['flag_hard_paywall'], false);
      expect(spy.superProps['flag_tour_ab'], true);
      expect(spy.superProps['flag_guided_tour'], false);
      expect(spy.superProps[AnalyticsEvents.isPremium], true,
          reason: 'boot super property must reflect the passed premium state');
    });

    test('fires app_install exactly once on a fresh install', () async {
      final spy = _SpyAnalytics();
      final prefs = await SharedPreferences.getInstance();

      await registerBootstrapAnalytics(
        analytics: spy,
        prefs: prefs,
        platform: 'android',
        appVersion: '1.0.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagTourAb: false,
        flagGuidedTour: true,
        isPremium: false,
      );

      final installs =
          spy.events.where((e) => e.event == AnalyticsEvents.appInstall);
      expect(installs, hasLength(1),
          reason: 'app_install fires once on first bootstrap');
      expect(prefs.getBool(analyticsAppInstallFiredPrefsKey), true,
          reason: 'the guard flag must be persisted after firing');
    });

    test('does NOT re-fire app_install on a second bootstrap (prefs guard)',
        () async {
      // First bootstrap on a fresh install sets the guard flag.
      final firstSpy = _SpyAnalytics();
      final prefs = await SharedPreferences.getInstance();
      await registerBootstrapAnalytics(
        analytics: firstSpy,
        prefs: prefs,
        platform: 'iOS',
        appVersion: '1.0.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagTourAb: false,
        flagGuidedTour: true,
        isPremium: false,
      );
      expect(
          firstSpy.events.where((e) => e.event == AnalyticsEvents.appInstall),
          hasLength(1));

      // Second bootstrap (e.g. next launch) — same persisted prefs — must NOT
      // re-fire app_install, but MUST still set the super properties.
      final secondSpy = _SpyAnalytics();
      await registerBootstrapAnalytics(
        analytics: secondSpy,
        prefs: prefs,
        platform: 'iOS',
        appVersion: '1.0.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagTourAb: false,
        flagGuidedTour: true,
        isPremium: false,
      );

      expect(
          secondSpy.events.where((e) => e.event == AnalyticsEvents.appInstall),
          isEmpty,
          reason: 'app_install must fire exactly once in the app lifetime');
      expect(secondSpy.superProps['platform'], 'iOS',
          reason: 'super properties still re-register on every bootstrap');
    });
  });

  group('resetForSignOut (P0: super-property survival across sign-out)', () {
    test(
        'flushes, resets identity, then re-registers DEVICE props but not '
        'user-scoped ones', () {
      final spy = _SpyAnalytics();
      // Boot: device/experiment props are cached; is_premium is user-scoped.
      spy.cacheDeviceSuperProperties({
        'platform': 'iOS',
        'app_version': '1.2.3+45',
        'flag_tour_ab': true,
      });
      spy.setSuperProperties({AnalyticsEvents.isPremium: true});
      expect(spy.superProps['flag_tour_ab'], true);
      expect(spy.superProps[AnalyticsEvents.isPremium], true);

      spy.resetForSignOut();

      expect(spy.flushCalls, 1,
          reason: 'queued events flush under the outgoing distinct_id first');
      expect(spy.resetCalls, 1, reason: 'identity severed for the next user');
      // Device/experiment context survives the reset (re-registered) so the
      // next user on this device is still flag-segmentable.
      expect(spy.superProps['platform'], 'iOS');
      expect(spy.superProps['app_version'], '1.2.3+45');
      expect(spy.superProps['flag_tour_ab'], true);
      // User-scoped is_premium must NOT bleed into the next user.
      expect(spy.superProps.containsKey(AnalyticsEvents.isPremium), false,
          reason: 'is_premium belongs to the signed-out user, not the device');
    });
  });
}
