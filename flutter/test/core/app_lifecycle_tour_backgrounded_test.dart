import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/app_lifecycle_observer.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

/// Spy mirroring the harness in analytics_phase1_test.dart.
class _SpyAnalytics extends AnalyticsService {
  final events = <({String event, Map<String, dynamic>? props})>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) =>
      events.add((event: event, props: properties));

  @override
  void setSuperProperties(Map<String, dynamic> props) {}

  @override
  void flush() {}
}

/// Forces the tour controller active at a known step without the
/// SharedPreferences / Supabase machinery `start()` requires. Mirrors the
/// `_ActiveAtStep` pattern in onboarding_tour_overlay_host_test.dart.
class _ActiveAtStep extends OnboardingTourController {
  _ActiveAtStep(super.ref, int index) {
    state = OnboardingTourState(index: index, status: TourStatus.active);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_SpyAnalytics> pumpObserver(
    WidgetTester tester, {
    required OnboardingTourController Function(Ref) controller,
  }) async {
    final spy = _SpyAnalytics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsProvider.overrideWithValue(spy),
          onboardingTourControllerProvider.overrideWith(controller),
          // Keep the resume-path premium read off the live RevenueCat SDK.
          premiumStateProvider.overrideWith(
            (ref) async => (isPremium: false, billingIssueAt: null),
          ),
        ],
        child: const AppLifecycleObserver(child: SizedBox()),
      ),
    );
    await tester.pump();
    return spy;
  }

  testWidgets(
      'backgrounding while the tour is ACTIVE fires tour_backgrounded with '
      'step_id / step_index / variant', (tester) async {
    final spy = await pumpObserver(
      tester,
      controller: (ref) => _ActiveAtStep(ref, 0),
    );

    // Drive a background transition.
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    final backgrounded =
        spy.events.where((e) => e.event == AnalyticsEvents.tourBackgrounded);
    expect(backgrounded, hasLength(1),
        reason: 'active tour + background == silent mid-tour abandonment');
    final props = backgrounded.single.props!;
    expect(props.containsKey('step_id'), isTrue);
    expect(props['step_index'], 0);
    expect(props.containsKey(AnalyticsEvents.propVariant), isTrue,
        reason: 'must carry the variant so the exit is segmentable by arm');
  });

  testWidgets('backgrounding while the tour is IDLE does NOT fire it',
      (tester) async {
    // Default controller → idle (status: idle, index: -1).
    final spy = await pumpObserver(
      tester,
      controller: OnboardingTourController.new,
    );

    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(
      spy.events.where((e) => e.event == AnalyticsEvents.tourBackgrounded),
      isEmpty,
      reason: 'no tour in progress means no silent-abandonment signal',
    );
  });
}
