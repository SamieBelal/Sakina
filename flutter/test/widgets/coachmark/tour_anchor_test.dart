import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';

/// Forces the controller into an active state at a given step index without
/// the SharedPreferences / Supabase / dailyLoop machinery `start()` requires.
class _TestController extends OnboardingTourController {
  _TestController(super.ref, int stepIndex) {
    state = OnboardingTourState(
      index: stepIndex,
      status: TourStatus.active,
    );
  }

  String? lastAdvanceVia;

  @override
  Future<void> advance({required String via}) async {
    lastAdvanceVia = via;
    super.state = OnboardingTourState(
      index: state.index + 1,
      status: TourStatus.active,
    );
  }
}

/// Builds the harness and exposes the controller created by the override.
Future<_TestController> _pumpHarness(
  WidgetTester tester, {
  required int stepIndex,
  required TourSurface surface,
  required String anchorId,
}) async {
  late _TestController controller;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingTourControllerProvider.overrideWith(
          (ref) => controller = _TestController(ref, stepIndex),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: TourAnchor(
              surface: surface,
              anchorId: anchorId,
              child: Container(
                width: 100,
                height: 50,
                color: Colors.green,
                key: const ValueKey('btn'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Touch the provider so the override factory runs and `controller` is bound.
  final container = ProviderScope.containerOf(
    tester.element(find.byType(TourAnchor)),
    listen: false,
  );
  container.read(onboardingTourControllerProvider);
  return controller;
}

void main() {
  group('TourAnchor pointer-up gating', () {
    testWidgets('tap advances the tour when step matches', (tester) async {
      final controller = await _pumpHarness(
        tester,
        stepIndex: 0, // home.beginMuhasabah
        surface: TourSurface.home,
        anchorId: 'beginMuhasabahCta',
      );

      await tester.tap(find.byKey(const ValueKey('btn')));
      await tester.pump();

      expect(controller.lastAdvanceVia, 'target_tap');
    });

    testWidgets('drag (scroll-release) does NOT advance the tour',
        (tester) async {
      final controller = await _pumpHarness(
        tester,
        stepIndex: 0,
        surface: TourSurface.home,
        anchorId: 'beginMuhasabahCta',
      );

      // Press down on the anchor, drag well beyond the tap-slop, then release.
      // Simulates a scroll gesture whose release lands on the anchor —
      // the historical failure mode for step 10 (firstRelatedHeart).
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('btn'))));
      await gesture.moveBy(const Offset(60, 0));
      await gesture.up();
      await tester.pump();

      expect(controller.lastAdvanceVia, isNull);
    });

    testWidgets('tap on anchor of OTHER surface does not advance',
        (tester) async {
      // Step 0 is home.beginMuhasabah; the anchor below is duas.firstRelatedHeart.
      final controller = await _pumpHarness(
        tester,
        stepIndex: 0,
        surface: TourSurface.duas,
        anchorId: 'firstRelatedHeart',
      );

      await tester.tap(find.byKey(const ValueKey('btn')));
      await tester.pump();

      expect(controller.lastAdvanceVia, isNull);
    });
  });
}
