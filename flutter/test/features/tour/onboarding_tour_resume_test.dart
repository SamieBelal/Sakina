import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/onboarding_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-1'),
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test('advance() persists the resume cursor', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingTourControllerProvider.notifier);

    notifier.replay(); // active at index 0
    await notifier.advance(via: 'target_tap'); // → index 1

    expect(await OnboardingGateService().tourStepIndex(), 1);
  });

  test('resumeForGate() resumes at the persisted step', () async {
    await OnboardingGateService().setTourStepIndex(5);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingTourControllerProvider.notifier);

    await notifier.resumeForGate();

    final state = container.read(onboardingTourControllerProvider);
    expect(state.index, 5);
    expect(state.status, TourStatus.active);
  });

  test('resumeForGate() clamps an out-of-range saved index', () async {
    await OnboardingGateService().setTourStepIndex(9999);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingTourControllerProvider.notifier);

    await notifier.resumeForGate();

    expect(
      container.read(onboardingTourControllerProvider).index,
      kOnboardingTourLength - 1,
    );
  });

  test('completing the tour resets the resume cursor to 0', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingTourControllerProvider.notifier);

    notifier.replay();
    for (var i = 0; i < kOnboardingTourLength; i++) {
      await notifier.advance(via: 'target_tap');
    }

    expect(
      container.read(onboardingTourControllerProvider).status,
      TourStatus.completed,
    );
    expect(await OnboardingGateService().tourStepIndex(), 0);
  });

  test('resumeForGate() is a no-op while already active', () async {
    await OnboardingGateService().setTourStepIndex(3);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingTourControllerProvider.notifier);

    await notifier.resumeForGate(); // index 3, active
    await notifier.resumeForGate(); // should not reset

    expect(container.read(onboardingTourControllerProvider).index, 3);
  });
}
