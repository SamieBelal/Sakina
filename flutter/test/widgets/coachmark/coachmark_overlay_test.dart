import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

/// Coach-banner overlay (2026-05-31 redesign): a compact top-left banner +
/// outline ring. No Continue/Done/step-dots — tap steps advance by tapping the
/// outlined target; read-only steps auto-advance (or show Continue under a
/// screen reader).
void main() {
  Widget harness({
    required GlobalKey targetKey,
    required CoachmarkStep step,
    required VoidCallback onNext,
    required VoidCallback onSkip,
    int stepIndex = 0,
    int totalSteps = 1,
    bool accessibleNavigation = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(393, 852))
            .copyWith(accessibleNavigation: accessibleNavigation),
        child: Material(
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
      ),
    );
  }

  // Entry animation is 600ms; the breathing pulse repeats (interactive steps),
  // so we use bounded pumps rather than pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('interactive step: banner message + Skip, no Continue/hint',
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
    await settle(tester);

    expect(find.text('Tap the button.'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);
    // Banner does NOT render the hint, nor any Continue/Done button.
    expect(find.text('Tap to continue ↗'), findsNothing);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('Skip tap calls onSkip', (tester) async {
    final key = GlobalKey();
    var skipped = 0;
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(target: key, message: 'Tap me.', interactive: true),
      onNext: () {},
      onSkip: () => skipped++,
    ));
    await settle(tester);
    await tester.tap(find.text('Skip tour'));
    await tester.pump();
    expect(skipped, 1);
  });

  testWidgets('read-only step auto-advances after its delay', (tester) async {
    final key = GlobalKey();
    var advanced = 0;
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: 'Your streak begins today.',
        interactive: false,
        autoAdvance: const Duration(milliseconds: 3500),
      ),
      onNext: () => advanced++,
      onSkip: () {},
      stepIndex: 5,
      totalSteps: 13,
    ));
    await settle(tester);
    expect(find.text('Your streak begins today.'), findsOneWidget);
    // No Continue on the non-accessible path — it advances on a timer.
    expect(find.text('Continue'), findsNothing);
    expect(advanced, 0, reason: 'must not advance before the delay');

    await tester.pump(const Duration(milliseconds: 3600));
    expect(advanced, 1, reason: 'auto-advance fires once after the delay');
  });

  testWidgets(
      'screen reader: auto-advance step shows Continue and does NOT auto-fire',
      (tester) async {
    final key = GlobalKey();
    var advanced = 0;
    await tester.pumpWidget(harness(
      targetKey: key,
      step: CoachmarkStep(
        target: key,
        message: 'Your streak begins today.',
        interactive: false,
        autoAdvance: const Duration(milliseconds: 3500),
      ),
      onNext: () => advanced++,
      onSkip: () {},
      accessibleNavigation: true,
    ));
    await settle(tester);
    // Under a screen reader the read-only step shows a deliberate Continue,
    // and the timer must NOT fire (no content-change-on-a-timer).
    expect(find.text('Continue'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 5000));
    expect(advanced, 0, reason: 'no auto-advance under accessibleNavigation');

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(advanced, 1, reason: 'Continue advances deliberately');
  });

  testWidgets('null target renders the banner with no cutout', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: CoachmarkOverlay(
          step: CoachmarkStep(
            target: null,
            message: 'Centered step copy.',
            interactive: false,
          ),
          stepIndex: 0,
          totalSteps: 1,
          onNext: _noop,
          onSkip: _noop,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Centered step copy.'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('hidden'), findsNothing);
    expect(find.text('Skip tour'), findsNothing);
  });

}

void _noop() {}
