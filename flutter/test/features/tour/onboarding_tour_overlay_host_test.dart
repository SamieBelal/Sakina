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
    expect(find.textContaining('Begin Muh'), findsOneWidget);
  });

  testWidgets('tourSuppressedProvider hides the coachmark while true',
      (tester) async {
    final container = await pumpHost(tester);
    expect(find.textContaining('Begin Muh'), findsOneWidget);

    // Suppress (as the Duas build flow does) → coachmark must hide.
    container.read(tourSuppressedProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Begin Muh'), findsNothing);

    // Lift suppression → coachmark returns.
    container.read(tourSuppressedProvider.notifier).state = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.textContaining('Begin Muh'), findsOneWidget);
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

  // ---------------------------------------------------------------------------
  // Reveal-settle: the coachmark must wait for the destination transition to
  // come to rest instead of popping in over a still-animating screen.
  // ---------------------------------------------------------------------------

  Widget hostWith(Widget body, {bool reduceMotion = false}) {
    final app = MaterialApp(
      navigatorKey: rootNavigatorKey,
      home: OnboardingTourOverlayHost(child: Scaffold(body: body)),
    );
    if (!reduceMotion) return app;
    return MediaQuery(
      data: const MediaQueryData(
        size: Size(393, 852),
        disableAnimations: true,
      ),
      child: app,
    );
  }

  Widget staticAnchor() => Center(
        child: TourAnchor(
          surface: step0.surface,
          anchorId: step0.anchorId,
          child: Container(width: 200, height: 56, color: Colors.green),
        ),
      );

  ProviderScope withController(Widget child) => ProviderScope(
        overrides: [
          onboardingTourControllerProvider
              .overrideWith((ref) => _ActiveAtStep(ref, 0)),
        ],
        child: child,
      );

  testWidgets('coachmark waits for the min-settle delay before revealing',
      (tester) async {
    await tester.pumpWidget(withController(hostWith(staticAnchor())));
    // First frame inserts the overlay + arms the settle timer.
    await tester.pump();
    // Before the floor elapses, the coachmark stays hidden...
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('Begin Muh'), findsNothing,
        reason: 'must stay hidden until the min-settle delay elapses');
    // ...and reveals once it has (a static anchor is already "at rest").
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.textContaining('Begin Muh'), findsOneWidget);
  });

  testWidgets(
      'min-settle floor is measured from when the anchor appears, not step change',
      (tester) async {
    // Regression for the muhasabah "Ameen" step: the tour activates the step
    // while the anchor is still several silent taps away, so the anchor mounts
    // long after step-change. The floor must start at the anchor's appearance —
    // otherwise it elapses early and the coachmark pops in mid-transition.
    final showAnchor = ValueNotifier<bool>(false);
    addTearDown(showAnchor.dispose);

    await tester.pumpWidget(
      withController(
        hostWith(
          ValueListenableBuilder<bool>(
            valueListenable: showAnchor,
            builder: (_, show, __) => Center(
              child: show
                  ? TourAnchor(
                      surface: step0.surface,
                      anchorId: step0.anchorId,
                      child: Container(
                          width: 200, height: 56, color: Colors.green),
                    )
                  : const SizedBox(width: 200, height: 56),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Anchor is absent for a long time — well past the floor. Must stay hidden,
    // and the floor must NOT have started counting yet.
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Begin Muh'), findsNothing);

    // Anchor appears now → the floor starts from here.
    showAnchor.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('Begin Muh'), findsNothing,
        reason: 'still within the floor measured from the anchor appearing');

    await tester.pump(const Duration(milliseconds: 450));
    expect(find.textContaining('Begin Muh'), findsOneWidget,
        reason: 'reveals once the post-appearance floor elapses');
  });

  testWidgets(
      'coachmark stays hidden while the anchor is still moving, reveals once it settles',
      (tester) async {
    final top = ValueNotifier<double>(0);
    addTearDown(top.dispose);

    await tester.pumpWidget(
      withController(
        hostWith(
          ValueListenableBuilder<double>(
            valueListenable: top,
            builder: (_, value, child) =>
                Padding(padding: EdgeInsets.only(top: value), child: child),
            child: Align(
              alignment: Alignment.topCenter,
              child: TourAnchor(
                surface: step0.surface,
                anchorId: step0.anchorId,
                child:
                    Container(width: 200, height: 56, color: Colors.green),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // arm timer + start ticker

    // Keep the anchor moving across frames that extend well past the settle
    // floor — motion alone must keep the coachmark hidden.
    for (var i = 0; i < 6; i++) {
      top.value += 20;
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.textContaining('Begin Muh'), findsNothing,
        reason: 'coachmark must not reveal while the anchor is still moving');

    // Stop moving. The tracking ticker samples at frame-start (one frame behind
    // layout), so the first settled frame still compares against the last
    // moving position; two frames at rest confirm the motion has stopped.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.textContaining('Begin Muh'), findsOneWidget,
        reason: 'reveals once the anchor motion has stopped');
  });

  testWidgets('reduce-motion bypasses the settle delay (reveals immediately)',
      (tester) async {
    await tester.pumpWidget(
      withController(hostWith(staticAnchor(), reduceMotion: true)),
    );
    await tester.pump();
    // Well under the 400ms floor — reduce-motion must not wait.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Begin Muh'), findsOneWidget,
        reason: 'reduce-motion must bypass the reveal-settle gates');
  });
}
