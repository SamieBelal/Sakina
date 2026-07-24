// test/features/daily/reveal_motion_test.dart
//
// Pure-function coverage for revealCardMotion — the widget-free choreography
// math. No pump: these assert tier escalation invariants and phase-boundary
// interlocks directly.
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/daily/reveal/reveal_geometry.dart';
import 'package:sakina/features/daily/reveal/reveal_spec.dart';
import 'package:sakina/services/card_collection_service.dart';

void main() {
  group('revealCardMotion — Bronze (spinTurns == 0)', () {
    final spec = revealSpecFor(CardTier.bronze);

    test('never shows the card back and never rotates across the sweep', () {
      for (var t = 0.0; t <= 1.0001; t += 0.02) {
        for (final ambient in const [0.0, 0.37, 0.83]) {
          final m = revealCardMotion(spec, t, ambient);
          expect(m.facingFront, isTrue,
              reason: 'Bronze must stay face-up at t=$t ambient=$ambient');
          expect(m.angle, 0.0,
              reason: 'Bronze must never rotate at t=$t ambient=$ambient');
        }
      }
    });

    test('foil phase tracks the ambient loop only (no spin drift)', () {
      // Bronze does not spin, so foilPhase is exactly the ambient input.
      expect(revealCardMotion(spec, 0.5, 0.42).foilPhase, 0.42);
      expect(revealCardMotion(spec, 0.9, 0.10).foilPhase, 0.10);
    });
  });

  group('revealCardMotion — spinning tiers flip then land face-up', () {
    for (final tier in const [CardTier.silver, CardTier.gold, CardTier.emerald]) {
      final spec = revealSpecFor(tier);

      test('${tier.label} shows its back at least once mid-reveal', () {
        var sawBack = false;
        for (var t = 0.0; t <= 1.0001; t += 0.01) {
          if (!revealCardMotion(spec, t, 0.0).facingFront) {
            sawBack = true;
            break;
          }
        }
        expect(sawBack, isTrue,
            reason: '${tier.label} spins, so the back must appear at least once');
      });

      test('${tier.label} settles face-up with ~zero angle at t=1.0', () {
        final m = revealCardMotion(spec, 1.0, 0.0);
        expect(m.facingFront, isTrue);
        // At t=1.0 the settle-wobble term is 0 (land=1 → (1-land)=0) and the
        // spin easing is complete, so the residual angle collapses to ~0.
        expect(m.angle.abs(), lessThan(0.001));
      });
    }
  });

  group('revealSpecFor escalation invariant', () {
    test('spin turns are 0/1/2/3 for bronze/silver/gold/emerald', () {
      expect(revealSpecFor(CardTier.bronze).spinTurns, 0);
      expect(revealSpecFor(CardTier.silver).spinTurns, 1);
      expect(revealSpecFor(CardTier.gold).spinTurns, 2);
      expect(revealSpecFor(CardTier.emerald).spinTurns, 3);
    });
  });

  group('phase-constant interlock sanity', () {
    final spec = revealSpecFor(CardTier.emerald);

    test('card appear is 0 at/before the swap and rises after it', () {
      // The card appear window is [kCardSwap, 0.58]; before/at the swap the
      // card has not begun fading in.
      expect(revealCardMotion(spec, kCardSwap, 0.0).appear, 0.0);
      expect(revealCardMotion(spec, kCardSwap - 0.05, 0.0).appear, 0.0);
      // Partway through the window it is climbing above zero…
      expect(revealCardMotion(spec, 0.55, 0.0).appear, greaterThan(0.0));
      // …and fully in by the end of the window (easeOutBack lands at 1.0).
      expect(revealCardMotion(spec, 0.58, 0.0).appear, closeTo(1.0, 1e-9));
    });

    test('pop and settleY reach their settled values by t=1.0', () {
      final m = revealCardMotion(spec, 1.0, 0.0);
      // pop is a 0→1→0 bell over [0.84, 0.94]; past the window it is back to 0.
      expect(m.pop, closeTo(0.0, 1e-9));
      // settleY finishes its rise (-8) once past [0.84, 0.94].
      expect(m.settleY, closeTo(-8.0, 1e-9));
    });

    test('pop peaks inside its bell window and settleY is mid-rise', () {
      final m = revealCardMotion(spec, 0.89, 0.0);
      // Midpoint of [0.84, 0.94] → bell peak → pop is at its max (~0.05).
      expect(m.pop, greaterThan(0.0));
      // settleY has begun rising but not fully arrived.
      expect(m.settleY, lessThan(0.0));
      expect(m.settleY, greaterThan(-8.0));
    });
  });
}
