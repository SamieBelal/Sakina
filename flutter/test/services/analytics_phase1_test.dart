import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_service.dart';

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

  group('onboarding_answer_captured (G1 fix)', () {
    test('carries key + step_index but NOT the corruptible step_name', () {
      final spy = _SpyAnalytics();
      // index 7 = daily_commitment in the live trimmed flow; the old code would
      // have emitted the LEGACY map name here (wrong).
      spy.trackOnboardingAnswer('daily_commitment', '10min', stepIndex: 7);

      final captured =
          spy.events.where((e) => e.event == 'onboarding_answer_captured');
      expect(captured, hasLength(1));
      final props = captured.single.props!;
      expect(props['key'], 'daily_commitment');
      expect(props['step_index'], 7);
      expect(props.containsKey('step_name'), isFalse,
          reason: 'step_name was wrongly mapped and is now dropped — key + '
              'flag_onboarding_trim disambiguate instead');
    });
  });

  // The `tour_variant super property` group tested `resumeForGate`, which was
  // deleted with the guided tour (§F1a). No code path resolves or stamps a tour
  // arm any more, so there is nothing left to assert here.
}
