import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/paywall/lapsed_soft_gate_analytics.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_service.dart';

class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));
}

void main() {
  group('recordLapsedSoftGateSurfaced', () {
    test('emits trial_paywall_surfaced with placement, arm and hard_gate', () {
      final spy = _SpyAnalytics();
      recordLapsedSoftGateSurfaced(
        spy,
        placement: AnalyticsEvents.placementPostTrialSoft,
        arm: 'treatment_reverse_trial',
      );

      expect(spy.events, hasLength(1));
      final e = spy.events.single;
      expect(e.event, AnalyticsEvents.trialPaywallSurfaced);
      expect(e.props, isNotNull);
      // F1: the arm MUST ride on the event (matches paywall_screen.dart).
      expect(e.props![AnalyticsEvents.propArm], 'treatment_reverse_trial');
      expect(e.props![AnalyticsEvents.propPlacement],
          AnalyticsEvents.placementPostTrialSoft);
      expect(e.props![AnalyticsEvents.propHardGate], false);
    });
  });

  group('recordLapsedSoftGateDismissed', () {
    test('emits soft_gate_dismissed with placement and arm', () {
      final spy = _SpyAnalytics();
      recordLapsedSoftGateDismissed(
        spy,
        placement: AnalyticsEvents.placementPostTrialSoft,
        arm: 'treatment_reverse_trial',
      );

      expect(spy.events, hasLength(1));
      final e = spy.events.single;
      expect(e.event, AnalyticsEvents.softGateDismissed);
      expect(e.props, isNotNull);
      // F1: the arm MUST ride on the dismissal event too.
      expect(e.props![AnalyticsEvents.propArm], 'treatment_reverse_trial');
      expect(e.props![AnalyticsEvents.propPlacement],
          AnalyticsEvents.placementPostTrialSoft);
    });
  });
}
