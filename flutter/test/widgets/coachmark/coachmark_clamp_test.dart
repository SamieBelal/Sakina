import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/widgets/coachmark/coachmark_overlay.dart';
import 'package:sakina/widgets/coachmark/coachmark_step.dart';

/// Regression tests for the clamp-inversion hardening in [CoachmarkOverlay].
///
/// Before the fix, three sites called `num.clamp(lo, hi)` with bounds that
/// could invert (`lo > hi`) on adverse geometry — Dart's `clamp` throws
/// `ArgumentError` then, which surfaced either as an uncaught exception in
/// `build` (tooltip placement) or a silently-dropped cutout (upward extension,
/// swallowed by a bare catch). These tests pin that none of those geometries
/// throw and the overlay still builds.
void main() {
  /// Mounts the overlay over a target placed via [align], inside a MediaQuery
  /// with the given [size] and top safe-area [padTop]. Returns after the entry
  /// animation so any build-time clamp would already have thrown.
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required Alignment align,
    required CoachmarkStep Function(GlobalKey) buildStep,
    Size size = const Size(393, 852),
    double padTop = 47,
    double targetW = 120,
    double targetH = 48,
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: EdgeInsets.only(top: padTop, bottom: 34),
          ),
          child: Material(
            child: Stack(
              children: [
                Align(
                  alignment: align,
                  child: GestureDetector(
                    key: key,
                    onTap: () {},
                    child: Container(
                        width: targetW, height: targetH, color: Colors.amber),
                  ),
                ),
                CoachmarkOverlay(
                  step: buildStep(key),
                  stepIndex: 0,
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

  testWidgets(
      'top-docked anchor with large cutoutPaddingTop does not throw / keeps cutout',
      (tester) async {
    // Anchor sits at the very top, ABOVE the 47pt safe-area inset — this is the
    // raw.top < safeTop inversion at coachmark_overlay.dart:_targetRect.
    await pumpOverlay(
      tester,
      align: Alignment.topCenter,
      padTop: 47,
      buildStep: (key) => CoachmarkStep(
        target: key,
        message: 'Type a need, then tap Build.',
        interactive: true,
        cutoutPaddingTop: 280,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Type a need, then tap Build.'), findsOneWidget);
  });

  testWidgets('very short viewport does not throw on tooltip placement',
      (tester) async {
    // A short usable height makes `usableBottom - _estTooltipHeight < usableTop`
    // and `screenH - usableTop - _estTooltipHeight < screenH - usableBottom`,
    // inverting both tooltip-placement clamps.
    await pumpOverlay(
      tester,
      align: Alignment.center,
      size: const Size(740, 300),
      padTop: 24,
      buildStep: (key) => CoachmarkStep(
        target: key,
        message: 'Open the reflection.',
        interactive: true,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Open the reflection.'), findsOneWidget);
  });

  testWidgets('bottom-edge anchor on short viewport does not throw',
      (tester) async {
    // Forces the above-placement (tooltip rendered above a bottom-docked
    // anchor) clamp on a short screen.
    await pumpOverlay(
      tester,
      align: Alignment.bottomCenter,
      size: const Size(740, 320),
      padTop: 24,
      buildStep: (key) => CoachmarkStep(
        target: key,
        message: "You're done. Tap to return home.",
        interactive: true,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
