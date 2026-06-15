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

  testWidgets(
      'stale tourSuppressed does NOT hide the coachmark when the anchor is '
      'already resolvable', (tester) async {
    // Host-level stale-suppression defense
    // (docs/qa/findings/2026-06-08-tour-suppression-stale-anchored-hang.md):
    // suppression is the Build-a-Dua "wait, the next anchor isn't reachable"
    // latch. It is honored ONLY while the step's anchor is ABSENT. If a stale
    // flag lingers while the anchor is on screen, it must be ignored — else the
    // step hangs (no timeout arms while suppressed). Here the beginMuhasabah
    // anchor is present, so a suppression flag is stale and the coachmark stays.
    final container = await pumpHost(tester);
    expect(find.textContaining('Begin Muh'), findsOneWidget);

    container.read(tourSuppressedProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Begin Muh'), findsOneWidget,
        reason: 'stale suppression (anchor present) must not hide the coachmark');
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

  testWidgets('tourSuppressed hides the coachmark while the anchor is ABSENT',
      (tester) async {
    // Legitimate suppression: the next step's anchor genuinely isn't on screen
    // yet (the real Build-a-Dua wait). Suppression must hide AND must not arm
    // the anchor-timeout. When the anchor later mounts the now-stale flag is
    // ignored and the coachmark reveals.
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
    final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingTourOverlayHost)));
    container.read(tourSuppressedProvider.notifier).state = true;
    // Pump so the suppression watch re-syncs the overlay (cancels the timeout
    // that the initial frame armed while the flag was still false).
    await tester.pump();

    // Anchor absent + suppressed → hidden, and (crucially) no auto-advance.
    await tester.pump(const Duration(seconds: 61));
    expect(find.textContaining('Begin Muh'), findsNothing);
    expect(container.read(onboardingTourControllerProvider).index, 0,
        reason: 'suppressed step must not arm the anchor-timeout');

    // Anchor appears → the now-stale flag is ignored; coachmark reveals once
    // the fixed settle (measured from the anchor appearing) elapses.
    showAnchor.value = true;
    await tester.pump(); // mount the anchor + register its key
    await tester.pump(); // ticker arms the settle timer now the anchor is drawable
    await tester.pump(const Duration(milliseconds: 450)); // settle elapses
    await tester.pump(); // markNeedsBuild → reveal
    expect(find.textContaining('Begin Muh'), findsOneWidget,
        reason: 'once the anchor is on screen the stale flag is ignored');
  });

  testWidgets(
      'an anchor that keeps moving still reveals after the fixed settle delay '
      '(no infinite motion wait)', (tester) async {
    // The revamped reveal is a single fixed delay measured from anchor
    // appearance — NOT a frame-to-frame motion wait. A perpetually-jittering
    // anchor (async-driven rebuild storm) used to be able to hang the reveal
    // forever; now it reveals on schedule. The ticker keeps the cutout glued to
    // the moving anchor, and CoachmarkOverlay degrades gracefully on a null rect.
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
    await tester.pump(); // arm settle timer + start ticker

    // Before the settle delay elapses: hidden, even though the anchor exists.
    top.value += 20;
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('Begin Muh'), findsNothing,
        reason: 'must stay hidden until the fixed settle delay elapses');

    // Keep jittering across the settle window — motion must NOT block reveal.
    for (var i = 0; i < 4; i++) {
      top.value += 20;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Begin Muh'), findsOneWidget,
        reason: 'reveals after the fixed delay regardless of ongoing motion');
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

  // ---------------------------------------------------------------------------
  // Bug 1: bottom-nav tab steps must advance on the actual ROUTE change, not on
  // a pointer Listener over the tab icon (which is disposed mid-tap when the
  // icon swaps to its active variant). The host watches `tourActiveRouteProvider`
  // (published by AppShell) and advances when it equals the step's navigateRoute.
  // ---------------------------------------------------------------------------
  testWidgets(
      'navigate-trigger tab step advances when the active route reaches its '
      'navigateRoute', (tester) async {
    // Index 5 = appShell.tabDuas, navigateRoute '/duas'.
    final navStep = kOnboardingTourSteps[5];
    expect(navStep.id, 'appShell.tabDuas');
    expect(navStep.navigateRoute, '/duas');
    expect(navStep.trigger, TourAdvanceTrigger.navigate);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingTourControllerProvider
              .overrideWith((ref) => _ActiveAtStep(ref, 5)),
        ],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const OnboardingTourOverlayHost(
            child: Scaffold(body: SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingTourOverlayHost)));

    // User is still on home (the source screen) — must NOT advance.
    container.read(tourActiveRouteProvider.notifier).state = '/';
    await tester.pump();
    expect(container.read(onboardingTourControllerProvider).index, 5,
        reason: 'on the source route the nav step must not advance');

    // User taps the Duas tab → AppShell publishes '/duas'.
    container.read(tourActiveRouteProvider.notifier).state = '/duas';
    await tester.pump();
    expect(container.read(onboardingTourControllerProvider).index, 6,
        reason: 'reaching the navigateRoute advances the nav step (Bug 1 fix)');
  });
}
