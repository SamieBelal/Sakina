import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

/// Phase 3 tour-funnel instrumentation: every tour event must carry `variant`,
/// drop-off events must carry `step_index`, and `tour_completed` must be
/// self-describing (`step_count` + `final_step_id`). These assertions guard the
/// funnel-completeness audit (2026-06-15).
class _TrackingAnalytics extends AnalyticsService {
  final tracked = <({String event, Map<String, dynamic>? props})>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event: event, props: properties));
  }

  Map<String, dynamic>? propsFor(String event) {
    for (final e in tracked) {
      if (e.event == event) return e.props;
    }
    return null;
  }

  int countOf(String event) => tracked.where((e) => e.event == event).length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tour funnel instrumentation', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    ProviderContainer makeContainer(_TrackingAnalytics analytics) {
      final container = ProviderContainer(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('tour_step_viewed carries variant + step_index', () {
      final analytics = _TrackingAnalytics();
      final container = makeContainer(analytics);
      container.read(onboardingTourControllerProvider.notifier).replay();

      final props = analytics.propsFor(AnalyticsEvents.tourStepViewed);
      expect(props, isNotNull);
      expect(props![AnalyticsEvents.propVariant], isA<String>());
      expect(props['step_index'], 0);
    });

    test('tour_step_advanced carries variant', () async {
      final analytics = _TrackingAnalytics();
      final container = makeContainer(analytics);
      final notifier =
          container.read(onboardingTourControllerProvider.notifier);
      notifier.replay();
      await notifier.advance(via: 'target_tap');

      final props = analytics.propsFor(AnalyticsEvents.tourStepAdvanced);
      expect(props, isNotNull);
      expect(props![AnalyticsEvents.propVariant], isA<String>());
    });

    test('tour_skipped carries variant + step_index + at_step_id', () async {
      final analytics = _TrackingAnalytics();
      final container = makeContainer(analytics);
      final notifier =
          container.read(onboardingTourControllerProvider.notifier);
      notifier.replay();
      await notifier.advance(via: 'target_tap');
      await notifier.skip();

      final props = analytics.propsFor(AnalyticsEvents.tourSkipped);
      expect(props, isNotNull);
      expect(props![AnalyticsEvents.propVariant], isA<String>());
      expect(props['step_index'], 1);
      expect(props['at_step_id'], isA<String>());
    });

    test(
        'tour_completed carries variant + step_count + final_step_id',
        () async {
      final analytics = _TrackingAnalytics();
      final container = makeContainer(analytics);
      final notifier =
          container.read(onboardingTourControllerProvider.notifier);
      notifier.replay();
      for (var i = 0; i < kOnboardingTourLength; i++) {
        await notifier.advance(via: 'continue');
      }

      expect(container.read(onboardingTourControllerProvider).status,
          TourStatus.completed);
      final props = analytics.propsFor(AnalyticsEvents.tourCompleted);
      expect(props, isNotNull);
      expect(props![AnalyticsEvents.propVariant], isA<String>());
      expect(props['step_count'], kOnboardingTourLength);
      // final_step_id is the last real step the user advanced from, never the
      // out-of-range completed index.
      expect(props['final_step_id'], isA<String>());
      expect(props['final_step_id'], isNot('unknown'));
    });
  });
}
