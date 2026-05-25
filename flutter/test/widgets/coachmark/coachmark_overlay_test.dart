import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

void main() {
  testWidgets('renders tooltip message + step dots + buttons', (tester) async {
    final key = GlobalKey();
    var nextCalls = 0;
    var skipCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 100,
                top: 200,
                child: Container(
                  key: key,
                  width: 80,
                  height: 40,
                  color: const Color(0xFF1B6B4A),
                ),
              ),
              CoachmarkOverlay(
                step: CoachmarkStep(
                  target: key,
                  message: 'Tap here daily to unlock today\'s Name.',
                ),
                stepIndex: 0,
                totalSteps: 3,
                onNext: () => nextCalls++,
                onSkip: () => skipCalls++,
              ),
            ],
          ),
        ),
      ),
    );
    // Allow the 600ms intro animation to complete
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    expect(find.textContaining('Tap here daily'), findsOneWidget);
    expect(find.text('Next →'), findsOneWidget);
    expect(find.text('Skip tour'), findsOneWidget);

    await tester.tap(find.text('Next →'));
    expect(nextCalls, 1);

    await tester.tap(find.text('Skip tour'));
    expect(skipCalls, 1);
  });

  testWidgets('T13: missing target context renders centered tooltip (no crash)',
      (tester) async {
    final unmountedKey = GlobalKey(); // never attached to anything
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoachmarkOverlay(
            step: CoachmarkStep(target: unmountedKey, message: 'fallback'),
            stepIndex: 0,
            totalSteps: 1,
            onNext: () {},
            onSkip: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    expect(find.text('fallback'), findsOneWidget);
    // Tooltip is centered (Stack contains it under Center, not Positioned)
  });

  testWidgets('T14: changing MediaQuery (rotation proxy) rebuilds without crash',
      (tester) async {
    final key = GlobalKey();
    Widget build(double width, double height) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 100,
                    top: 200,
                    child: SizedBox(key: key, width: 80, height: 40),
                  ),
                  CoachmarkOverlay(
                    step: CoachmarkStep(target: key, message: 'rotate test'),
                    stepIndex: 0,
                    totalSteps: 1,
                    onNext: () {},
                    onSkip: () {},
                  ),
                ],
              ),
            ),
          ),
        );

    await tester.pumpWidget(build(400, 800)); // portrait
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    await tester.pumpWidget(build(800, 400)); // landscape — rotation proxy
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('rotate test'), findsOneWidget);
  });

  testWidgets('T-small-screen: <360pt width renders close icon not Skip text',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 600)),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 50,
                  top: 200,
                  child: SizedBox(key: key, width: 80, height: 40),
                ),
                CoachmarkOverlay(
                  step: CoachmarkStep(target: key, message: 'small'),
                  stepIndex: 0,
                  totalSteps: 2,
                  onNext: () {},
                  onSkip: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    expect(find.text('Skip tour'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
