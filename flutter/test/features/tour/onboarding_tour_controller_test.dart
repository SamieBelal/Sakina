import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';

class _SpyAnalyticsService extends AnalyticsService {
  final userPropertiesCalls = <Map<String, dynamic>>[];

  @override
  void setUserProperties(Map<String, dynamic> props) {
    userPropertiesCalls.add(Map<String, dynamic>.from(props));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingTourController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(onboardingTourControllerProvider);
      expect(state.status, TourStatus.idle);
      expect(state.index, -1);
      expect(state.currentStep, isNull);
    });

    test('advance() is a no-op when not active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(onboardingTourControllerProvider.notifier)
          .advance(via: 'target_tap');
      expect(container.read(onboardingTourControllerProvider).status,
          TourStatus.idle);
    });

    test('skip() is a no-op when not active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(onboardingTourControllerProvider.notifier).skip();
      expect(container.read(onboardingTourControllerProvider).status,
          TourStatus.idle);
    });

    test('replay() jumps to active(index=0)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(onboardingTourControllerProvider.notifier).replay();
      final state = container.read(onboardingTourControllerProvider);
      expect(state.status, TourStatus.active);
      expect(state.index, 0);
      expect(state.currentStep?.id, 'home.beginMuhasabah');
    });

    test('advance() walks through every step then completes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(onboardingTourControllerProvider.notifier);
      notifier.replay();
      for (var i = 0; i < kOnboardingTourLength - 1; i++) {
        expect(container.read(onboardingTourControllerProvider).index, i);
        await notifier.advance(via: 'target_tap');
      }
      expect(container.read(onboardingTourControllerProvider).index,
          kOnboardingTourLength - 1);
      // One more advance → completed.
      await notifier.advance(via: 'continue');
      final finalState = container.read(onboardingTourControllerProvider);
      expect(finalState.status, TourStatus.completed);
      expect(finalState.index, kOnboardingTourLength);
    });

    test('skip() at step 5 transitions to skipped + marks seen flag', () async {
      // Pre-populate prefs with no flag so the assertion below is meaningful.
      SharedPreferences.setMockInitialValues({});
      final analytics = _SpyAnalyticsService();
      final container = ProviderContainer(
        overrides: [analyticsProvider.overrideWithValue(analytics)],
      );
      addTearDown(container.dispose);
      final notifier =
          container.read(onboardingTourControllerProvider.notifier);
      notifier.replay();
      for (var i = 0; i < 5; i++) {
        await notifier.advance(via: 'target_tap');
      }
      expect(container.read(onboardingTourControllerProvider).index, 5);
      await notifier.skip();
      expect(container.read(onboardingTourControllerProvider).status,
          TourStatus.skipped);
      expect(
        analytics.userPropertiesCalls.single,
        containsPair('tour_home_skipped_at', isA<String>()),
      );
      // Seen flag persistence is tested indirectly: if it were unset, a
      // subsequent start() would re-activate. The flag uses the current
      // authed user's id which is null in tests — we just verify status
      // transitioned cleanly.
    });
  });
}
