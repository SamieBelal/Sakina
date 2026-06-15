import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

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

  group('tour_variant super property', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-1'),
      );
    });
    tearDown(SupabaseSyncService.debugReset);

    test('resumeForGate registers tour_variant as a super property', () async {
      final spy = _SpyAnalytics();
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(spy),
        // forTest() → getBool returns the fallback (tour_ab off) → slim, with
        // no Supabase.instance access.
        appConfigServiceProvider.overrideWithValue(AppConfigService.forTest()),
      ]);
      addTearDown(container.dispose);

      await container
          .read(onboardingTourControllerProvider.notifier)
          .resumeForGate();

      expect(spy.superProps[AnalyticsEvents.tourVariant], 'slim',
          reason: 'every downstream event must be segmentable by tour arm');
      expect(spy.userProps[AnalyticsEvents.tourVariant], 'slim',
          reason: 'also set on the people profile for user-level analysis');
    });

    test('resumeForGate fires tour_offered exactly once (carries variant)',
        () async {
      // tour_offered closes the onboarding_completed→tour_started gap: the
      // mandatory gate always offers the tour, so this must fire once per
      // gate entry (the offered→started funnel denominator).
      final spy = _SpyAnalytics();
      final container = ProviderContainer(overrides: [
        analyticsProvider.overrideWithValue(spy),
        appConfigServiceProvider.overrideWithValue(AppConfigService.forTest()),
      ]);
      addTearDown(container.dispose);

      await container
          .read(onboardingTourControllerProvider.notifier)
          .resumeForGate();

      final offered =
          spy.events.where((e) => e.event == AnalyticsEvents.tourOffered);
      expect(offered, hasLength(1),
          reason: 'one offer per mandatory-gate entry');
      expect(offered.single.props?[AnalyticsEvents.propVariant], 'slim',
          reason: 'tour_offered carries the resolved variant');
    });
  });
}
