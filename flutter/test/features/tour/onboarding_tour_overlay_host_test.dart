import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';
import 'package:sakina/features/tour/widgets/onboarding_tour_overlay_host.dart';
import 'package:sakina/widgets/achievement_toast.dart' show rootNavigatorKey;
import 'package:sakina/widgets/coachmark/tour_anchor.dart';

/// Forces the controller active at a step without the SharedPreferences /
/// Supabase / dailyLoop machinery that `start()` requires.
class _ActiveAtStep extends OnboardingTourController {
  _ActiveAtStep(super.ref, int index) {
    state = OnboardingTourState(index: index, status: TourStatus.active);
  }
}

void main() {
  // Step 0 = home.beginMuhasabah (interactive, anchored on beginMuhasabahCta).
  final step0 = kOnboardingTourSteps[0];

  Future<ProviderContainer> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingTourControllerProvider
              .overrideWith((ref) => _ActiveAtStep(ref, 0)),
        ],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: OnboardingTourOverlayHost(
            child: Scaffold(
              body: Center(
                child: TourAnchor(
                  surface: step0.surface,
                  anchorId: step0.anchorId,
                  child: Container(width: 200, height: 56, color: Colors.green),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Let the post-frame overlay insertion + 600ms entry animation run.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    return ProviderScope.containerOf(
        tester.element(find.byType(OnboardingTourOverlayHost)));
  }

  testWidgets('coachmark shows for an active step with a resolvable anchor',
      (tester) async {
    await pumpHost(tester);
    expect(find.text(step0.message), findsOneWidget);
  });

  testWidgets('tourSuppressedProvider hides the coachmark while true',
      (tester) async {
    final container = await pumpHost(tester);
    expect(find.text(step0.message), findsOneWidget);

    // Suppress (as the Duas build flow does) → coachmark must hide.
    container.read(tourSuppressedProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(step0.message), findsNothing);

    // Lift suppression → coachmark returns.
    container.read(tourSuppressedProvider.notifier).state = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(step0.message), findsOneWidget);
  });

  testWidgets('missing-anchor timeout re-arms after a blocking route pops',
      (tester) async {
    late BuildContext navigatorContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingTourControllerProvider
              .overrideWith((ref) => _ActiveAtStep(ref, 0)),
        ],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          navigatorObservers: [tourRouteObserver],
          home: OnboardingTourOverlayHost(
            child: Builder(
              builder: (context) {
                navigatorContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Navigator.of(navigatorContext).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'LapsedTrialSheet'),
        builder: (_) => const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    expect(tourRouteObserver.isBlockingRouteOnTop, true);

    Navigator.of(navigatorContext).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 61));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(OnboardingTourOverlayHost)),
    );
    expect(container.read(onboardingTourControllerProvider).index, 1);
  });
}
