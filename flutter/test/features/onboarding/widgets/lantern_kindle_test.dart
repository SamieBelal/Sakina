import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/widgets/lantern_kindle.dart';
import 'package:sakina/features/onboarding/widgets/lantern_kindle_beat.dart';

/// The kindling beat's motion contract (Wave G, spec §5).
///
/// The headline test here is the **flame-blink guard**, and it is worth
/// understanding before touching [kindleGlow]:
///
/// `LanternPainter` draws no flame below `g = 0.04`, and the breath pulse
/// modulates `g` by ±10% every 2.6s. So a glow that sits anywhere near 0.04
/// makes the flame wink on and off once per breath — which is precisely why
/// `CompanionBrightness.pendingUnlit` is pinned to a hard `0.0` instead of "a
/// small value". A kindle ramp that eases gently out of zero would spend
/// hundreds of milliseconds inside that band and read as a guttering, broken
/// lamp at the exact moment the copy says "Your lantern is lit."
///
/// The curve is asserted as a pure function rather than through pumped frames:
/// a widget test samples at the frame rate the test binding chooses, which is
/// far too coarse to catch a dwell of a few tens of milliseconds.
void main() {
  group('kindleGlow', () {
    // The flame's own threshold, and the value it must clear to stay lit at the
    // bottom of the breath cycle (g * 0.9 >= 0.04).
    const flameOn = 0.04;
    const flameOnAtBreathTrough = flameOn / 0.9;

    test('starts fully dark and settles at endowedDim', () {
      expect(kindleGlow(0), 0);
      expect(kindleGlow(1), closeTo(kindleRestGlow, 1e-9));
      // Clamped, not extrapolated — a controller that overshoots its bounds
      // must not drive the glow past the resting value.
      expect(kindleGlow(-0.5), 0);
      expect(kindleGlow(1.5), closeTo(kindleRestGlow, 1e-9));
    });

    test('crosses the flame threshold decisively — never dwells in the '
        'blink band', () {
      // Sample far finer than a frame so a real dwell cannot hide between
      // samples: 900ms / 2000 steps = 0.45ms resolution.
      const steps = 2000;
      const band = 0.06; // comfortably above the trough-adjusted threshold
      var msInBand = 0.0;
      final msPerStep = kindleDuration.inMilliseconds / steps;

      for (var i = 0; i <= steps; i++) {
        final glow = kindleGlow(i / steps);
        if (glow > 0 && glow < band) msInBand += msPerStep;
      }

      // One 60fps frame is ~16.7ms. Anything under that cannot produce a
      // visible blink even at the worst breath phase.
      expect(msInBand, lessThan(16.7),
          reason: 'the ramp lingered ${msInBand.toStringAsFixed(1)}ms inside '
              'the flame-threshold band; the flame will blink once per breath');
    });

    test('holds a hard zero before ignition, then takes in one step', () {
      // The pre-roll must be exactly 0, not "small". Anything in (0, 0.0445) is
      // the blink band, and a lamp that flickers while the copy says it is lit
      // is worse than one that was simply dark a moment longer.
      expect(kindleGlow(0), 0);
      expect(kindleGlow(kindleIgnitionAt / 2), 0);
      expect(kindleGlow(kindleIgnitionAt * 0.999), 0);
      // And the first lit sample is already unambiguously above the threshold
      // at the bottom of the breath cycle.
      expect(kindleGlow(kindleIgnitionAt), kindleIgnitionGlow);
      expect(kindleIgnitionGlow * 0.9, greaterThan(flameOn));
    });

    test('is monotonic up to the flare, then settles back without dipping '
        'below the resting glow', () {
      var previous = -1.0;
      for (var i = 0; i <= 100; i++) {
        final t = (i / 100) * kindleFlareAt;
        final glow = kindleGlow(t);
        expect(glow, greaterThanOrEqualTo(previous),
            reason: 'the rise must never reverse — a flame that dips while '
                'catching reads as failing to catch');
        previous = glow;
      }
      expect(kindleGlow(kindleFlareAt), closeTo(kindleFlarePeak, 1e-9));

      for (var i = 0; i <= 100; i++) {
        final t = kindleFlareAt + (i / 100) * (1 - kindleFlareAt);
        expect(kindleGlow(t), greaterThanOrEqualTo(kindleRestGlow - 1e-9),
            reason: 'the settle must never undershoot the resting glow');
        expect(kindleGlow(t), lessThanOrEqualTo(kindleFlarePeak + 1e-9));
      }
    });

    test('the flare is an overshoot in LUMINANCE, above the resting value', () {
      // Documents the founder-confirmed distinction: this is a brightness
      // overshoot, which the no-bounce rule does not cover, because nothing
      // moves. If someone ever converts this into a scale/translate, this test
      // is the note explaining why they must not.
      expect(kindleFlarePeak, greaterThan(kindleRestGlow));
      expect(kindleGlow(kindleFlareAt), greaterThan(kindleGlow(1)));
    });

    test('clears the breath-trough threshold well before the flare', () {
      // By a quarter of the way up the rise the lamp must be unambiguously lit,
      // so the flame is never in doubt while the copy is arriving.
      expect(kindleGlow(kindleIgnitionAt), greaterThan(flameOnAtBreathTrough));
      expect(kindleGlow(kindleFlareAt * 0.5),
          greaterThan(flameOnAtBreathTrough * 2));
    });
  });

  group('LanternKindleBeat', () {
    testWidgets('announces the whole beat as one label, not two fragments',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: LanternKindleBeat()),
      ));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(
        find.bySemanticsLabel(
          '${LanternKindleBeat.headline} ${LanternKindleBeat.subline}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reports the kindling exactly once', (tester) async {
      var kindled = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: LanternKindleBeat(onKindled: () => kindled++)),
      ));
      // A frame to let the post-frame start fire, then past the full ramp.
      await tester.pump();
      await tester.pump(kindleDuration);
      await tester.pump(const Duration(milliseconds: 100));
      expect(kindled, 1);

      // Extra frames must not re-report: the beat sits in the reveal's loading
      // slot, which rebuilds whenever its host does.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));
      expect(kindled, 1);
    });

    testWidgets('still lights the lamp when animations are disabled',
        (tester) async {
      // Reduce-motion drops the flare and the breath, never the lighting —
      // removing the state change would leave the user looking at a dark lamp
      // under copy claiming it is lit.
      await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LanternKindleBeat()),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byType(LanternKindle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
