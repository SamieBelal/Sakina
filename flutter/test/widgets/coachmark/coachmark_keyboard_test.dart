import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

/// Pins the keyboard-hide behavior on text-entry tour steps (Duas "Build a
/// Dua"). When the soft keyboard is up there is no room above it for both the
/// cutout and the tooltip without covering the field being typed in, so the
/// overlay fades out (opacity 0) and stops absorbing pointers — taps fall
/// through to the underlying field + Build button. When the keyboard dismisses
/// the overlay fades back in.
void main() {
  Future<void> pumpWithInsets(
    WidgetTester tester, {
    required double bottomInset,
  }) async {
    const size = Size(393, 852);
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
            viewInsets: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Material(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
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
                    message: "Type a need, then tap Build.",
                    interactive: true,
                    cutoutPaddingTop: 280,
                  ),
                  stepIndex: 8,
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('overlay is fully visible while the keyboard is closed',
      (tester) async {
    await pumpWithInsets(tester, bottomInset: 0);
    final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity.opacity, 1.0);
    expect(tester.takeException(), isNull);
    expect(find.text('Type a need, then tap Build.'), findsOneWidget);
  });

  testWidgets('overlay fades out + stops absorbing pointers when keyboard opens',
      (tester) async {
    await pumpWithInsets(tester, bottomInset: 336);
    final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity.opacity, 0.0,
        reason: 'coachmark must fade out while the keyboard is up');

    // The wrapping IgnorePointer must let taps through to the field below.
    final ignorePointer = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byType(AnimatedOpacity),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignorePointer.ignoring, true,
        reason: 'overlay must not absorb taps while hidden for the keyboard');
    expect(tester.takeException(), isNull);
  });
}
