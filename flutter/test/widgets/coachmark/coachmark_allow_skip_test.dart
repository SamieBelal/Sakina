import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

/// The mandatory onboarding gate forces the tour to completion before the hard
/// paywall (decision C2), so "Skip tour" must be HIDDEN when allowSkip is false.
/// The legacy/replay tour keeps it (default allowSkip: true).
Widget _host({required bool allowSkip, required GlobalKey targetKey}) {
  const size = Size(393, 852);
  return MaterialApp(
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
                key: targetKey,
                onTap: () {},
                child: Container(width: 200, height: 56, color: Colors.amber),
              ),
            ),
            CoachmarkOverlay(
              step: CoachmarkStep(
                target: targetKey,
                message: 'A tour step message for the banner.',
              ),
              stepIndex: 2,
              totalSteps: 13,
              onNext: () {},
              onSkip: () {},
              allowSkip: allowSkip,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Skip tour is shown when allowSkip is true (legacy/replay)',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(allowSkip: true, targetKey: GlobalKey()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Skip tour'), findsOneWidget);
  });

  testWidgets('Skip tour is HIDDEN when allowSkip is false (forced gate tour)',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(allowSkip: false, targetKey: GlobalKey()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Skip tour'), findsNothing);
    // The step message still renders — only the skip affordance is gone.
    expect(find.text('A tour step message for the banner.'), findsOneWidget);
  });
}
