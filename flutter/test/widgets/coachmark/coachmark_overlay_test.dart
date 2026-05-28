import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

void main() {
  /// Mounts the overlay over a single target widget at the screen center.
  Widget harness({
    required GlobalKey targetKey,
    required CoachmarkStep step,
    required VoidCallback onNext,
    required VoidCallback onSkip,
    int stepIndex = 0,
    int totalSteps = 1,
  }) {
    return MaterialApp(
      home: Material(
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                key: targetKey,
                onTap: () {},
                child: Container(width: 120, height: 48, color: Colors.amber),
              ),
            ),
            CoachmarkOverlay(
              step: step,
              stepIndex: stepIndex,
              totalSteps: totalSteps,
              onNext: onNext,
              onSkip: onSkip,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('renders tooltip message + Skip on interactive step',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: 'Tap the button.',
        hint: 'Tap to continue ↗',
        interactive: true,
      ),
      onNext: () {},
      onSkip: () {},
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Tap the button.'), findsOneWidget);
    expect(find.text('Tap to continue ↗'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);
    // Interactive mode: NO Continue/Next button — user taps the cutout to advance.
    expect(find.text('Continue →'), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('teach step shows Continue button + no hint', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: 'Your streak just started.',
        interactive: false,
      ),
      onNext: () {},
      onSkip: () {},
      stepIndex: 5, // mid-tour so isLast=false → "Continue →" text
      totalSteps: 13,
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Your streak just started.'), findsOneWidget);
    expect(find.text('Continue →'), findsOneWidget);
    expect(find.text('Tap to continue ↗'), findsNothing);
  });

  testWidgets('last step shows Done not Continue', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: "You're all set.",
        interactive: false,
      ),
      onNext: () {},
      onSkip: () {},
      stepIndex: 12,
      totalSteps: 13,
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Continue →'), findsNothing);
  });

  // Note: cutout tap detection moved to `TourAnchor` (wraps the target
  // widget) post-2026-05-26 live test. Previously the overlay had a
  // `Listener` over the cutout that called `onNext` on pointer-up, but it
  // was unreliable when stacked with overlay entries. The new model is
  // that `TourAnchor` watches its child's pointer-ups and advances the
  // tour when active. CoachmarkOverlay is purely visual now.

  testWidgets('Skip button calls onSkip', (tester) async {
    final key = GlobalKey();
    var skipped = 0;
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: 'Tap me.',
        interactive: true,
      ),
      onNext: () {},
      onSkip: () => skipped++,
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Skip tour'));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(skipped, 1);
  });

  testWidgets('null target renders centered tooltip with no cutout',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: CoachmarkOverlay(
          step: const CoachmarkStep(
            target: null,
            message: 'Centered tooltip.',
            interactive: false,
          ),
          stepIndex: 0,
          totalSteps: 1,
          onNext: () {},
          onSkip: () {},
        ),
      ),
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Centered tooltip.'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget); // last step (1/1)
  });

  testWidgets('hideUntilAnchorReady renders nothing', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: CoachmarkOverlay(
          step: CoachmarkStep(target: key, message: 'hidden'),
          stepIndex: 0,
          totalSteps: 1,
          onNext: () {},
          onSkip: () {},
          hideUntilAnchorReady: true,
        ),
      ),
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('hidden'), findsNothing);
    expect(find.text('Skip tour'), findsNothing);
  });

  testWidgets('step dots: active dot count matches totalSteps', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: 'msg',
        interactive: false,
      ),
      onNext: () {},
      onSkip: () {},
      stepIndex: 2,
      totalSteps: 5,
    ));
    // Advance past the 600ms entry animation; breathing pulse repeats so
    // we use bounded pump (pumpAndSettle deadlocks on infinite animations).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // VoiceOver label includes total — guards step-progress a11y.
    final semantics =
        tester.getSemantics(find.bySemanticsLabel('Step 3 of 5'));
    expect(semantics, isNotNull);
  });
}
