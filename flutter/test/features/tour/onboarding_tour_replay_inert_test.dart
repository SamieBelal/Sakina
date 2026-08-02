import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';

/// `replay()` must never make the tour active again (Wave F1a).
///
/// This pins a regression that would be **silent and expensive** if it returned.
/// `OnboardingTourOverlayHost` was unmounted with the tour, so an active tour
/// has nothing to render — but an active-but-invisible tour is worse than a
/// useless one:
///
///   * `shouldDeferCelebrations` keys off `isActive`, and
///   * `app_shell._maybeDrainDeferredCelebrations` bails while it is true.
///
/// So a replay would swallow every rank-up, quest, achievement and First Steps
/// celebration for the rest of the session — and nothing could clear it, since
/// no overlay exists to advance, skip or complete the tour. The user's only
/// escape is force-quitting the app.
///
/// The Settings row that called this is gone, but the method itself cannot be
/// deleted: the E5 win-back deep link `sakina://settings?action=replay_tour`
/// may already be scheduled inside OneSignal automations we cannot retract, so
/// the entry point has to be SAFE WHEN IT FIRES rather than merely unreachable
/// from our own UI. That is what this test guards.
void main() {
  test('replay() leaves the tour inactive, so celebrations still drain', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(onboardingTourControllerProvider.notifier);
    final before = container.read(onboardingTourControllerProvider);
    expect(before.isActive, isFalse, reason: 'precondition: no tour exists');

    notifier.replay();

    final after = container.read(onboardingTourControllerProvider);
    expect(
      after.isActive,
      isFalse,
      reason: 'an active tour with no overlay mounted permanently blocks the '
          'celebration drain — see this file header',
    );
  });

  test('repeated replays cannot accumulate into an active state', () {
    // The deep link can fire more than once (a re-tapped push, a retried
    // notification). Idempotence matters more here than usual.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(onboardingTourControllerProvider.notifier);
    for (var i = 0; i < 5; i++) {
      notifier.replay();
    }

    expect(container.read(onboardingTourControllerProvider).isActive, isFalse);
  });
}
