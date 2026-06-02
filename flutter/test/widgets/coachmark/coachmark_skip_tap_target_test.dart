import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

/// F-05: the guided-tour "Skip tour" control had a ~24pt-tall tap target
/// (Text with vertical:6 / horizontal:2 padding), well under the 44pt minimum
/// touch target. This pins that the tappable area is now >= 44pt in both
/// dimensions. See docs/qa/findings/2026-06-01-guided-tour-skip-tap-target-narrow.md
void main() {
  testWidgets('Skip tour tap target is at least 44x44 (F-05)', (tester) async {
    const size = Size(393, 852);
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: Material(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    key: key,
                    onTap: () {},
                    child: Container(
                        width: 200, height: 56, color: Colors.amber),
                  ),
                ),
                CoachmarkOverlay(
                  step: CoachmarkStep(
                    target: key,
                    message: 'A tour step message for the banner.',
                  ),
                  stepIndex: 2,
                  totalSteps: 13,
                  onNext: () {},
                  onSkip: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Settle the reveal animation so the banner is laid out.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final skipText = find.text('Skip tour');
    expect(skipText, findsOneWidget);

    // The closest GestureDetector ancestor is the Skip tap area (Container with
    // the minHeight/minWidth 44 constraints).
    final tapArea =
        find.ancestor(of: skipText, matching: find.byType(GestureDetector));
    expect(tapArea, findsWidgets);
    final tapSize = tester.getSize(tapArea.first);

    expect(tapSize.height, greaterThanOrEqualTo(44.0),
        reason: 'Skip tour tap target must be >= 44pt tall');
    expect(tapSize.width, greaterThanOrEqualTo(44.0),
        reason: 'Skip tour tap target must be >= 44pt wide');
  });
}
