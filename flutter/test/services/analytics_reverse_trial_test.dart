import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/paywall/paywall_experiment.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_service.dart';

/// Spy mirroring bootstrap_analytics_test's harness — captures track /
/// setSuperProperties / setUserProperties without a live Mixpanel.
class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];
  final superProps = <String, dynamic>{};
  final userProps = <String, dynamic>{};

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));

  @override
  void setSuperProperties(Map<String, dynamic> props) =>
      superProps.addAll(props);

  @override
  void setUserProperties(Map<String, dynamic> props) => userProps.addAll(props);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reverse-trial event-name + property constants', () {
    test('event names match the ADR analytics-table wire strings', () {
      expect(AnalyticsEvents.experimentAssigned, 'experiment_assigned');
      expect(AnalyticsEvents.trialActivated, 'trial_activated');
      expect(AnalyticsEvents.trialExpired, 'trial_expired');
      expect(AnalyticsEvents.trialPaywallSurfaced, 'trial_paywall_surfaced');
      expect(AnalyticsEvents.dailyCapHit, 'daily_cap_hit');
      expect(AnalyticsEvents.softGateDismissed, 'soft_gate_dismissed');
    });

    test('property-name + super-property constants', () {
      expect(AnalyticsEvents.propArm, 'arm');
      expect(AnalyticsEvents.paywallExpArm, 'paywall_exp_arm');
      expect(AnalyticsEvents.flagReverseTrialExp, 'flag_reverse_trial_exp');
      expect(AnalyticsEvents.armUnassigned, 'unassigned');
      expect(AnalyticsEvents.experimentReverseTrial, 'reverse_trial');
    });

    test('PaywallArm.analyticsValue matches the wire contract', () {
      expect(PaywallArm.controlNoTrial.analyticsValue, 'control_no_trial');
      expect(
        PaywallArm.treatmentReverseTrial.analyticsValue,
        'treatment_reverse_trial',
      );
    });
  });

  group('bootstrap registers flag_reverse_trial_exp super property', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('the flag value flows into super properties', () async {
      final spy = _SpyAnalytics();
      final prefs = await SharedPreferences.getInstance();
      await registerBootstrapAnalytics(
        analytics: spy,
        prefs: prefs,
        platform: 'iOS',
        appVersion: '1.2.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagTourAb: false,
        flagGuidedTour: true,
        flagReverseTrialExp: true,
        isPremium: false,
      );
      expect(spy.superProps[AnalyticsEvents.flagReverseTrialExp], true);
    });

    test('defaults to false when the named arg is omitted (back-compat)',
        () async {
      final spy = _SpyAnalytics();
      final prefs = await SharedPreferences.getInstance();
      await registerBootstrapAnalytics(
        analytics: spy,
        prefs: prefs,
        platform: 'iOS',
        appVersion: '1.2.0+1',
        flagOnboardingTrim: true,
        flagHardPaywall: false,
        flagTourAb: false,
        flagGuidedTour: true,
        isPremium: false,
      );
      expect(spy.superProps[AnalyticsEvents.flagReverseTrialExp], false);
    });
  });

  group('recordPaywallArm sets paywall_exp_arm on BOTH super + people', () {
    test('mirrors the _recordVariant super+people pattern', () {
      final spy = _SpyAnalytics();
      spy.recordPaywallArm(PaywallArm.treatmentReverseTrial);

      expect(spy.superProps[AnalyticsEvents.paywallExpArm],
          'treatment_reverse_trial',
          reason: 'super property so every downstream event segments by arm');
      expect(spy.userProps[AnalyticsEvents.paywallExpArm],
          'treatment_reverse_trial',
          reason: 'people property for user-level analysis');
    });

    test('control arm records the control wire value', () {
      final spy = _SpyAnalytics();
      spy.recordPaywallArm(PaywallArm.controlNoTrial);
      expect(spy.superProps[AnalyticsEvents.paywallExpArm], 'control_no_trial');
      expect(spy.userProps[AnalyticsEvents.paywallExpArm], 'control_no_trial');
    });
  });
}
