// lib/features/daily/reveal/reveal_geometry.dart
//
// Shared, widget-free geometry + choreography math for the card reveal. Kept out
// of the overlay widget so it's unit-testable (pure functions) and so painters
// and the overlay share one source of truth for tier accents, timeline windows,
// the ray-fan idiom, and the particle field.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sakina/features/daily/reveal/reveal_spec.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tier-neutral shared warm accents + canvas.
// ─────────────────────────────────────────────────────────────────────────────
const gold = Color(0xFFC8985E);
const goldBright = Color(0xFFEDD9A3);
const revealCanvas = Color(0xFF05100A);

// ─────────────────────────────────────────────────────────────────────────────
// Named phase constants — the INTERLOCKING timeline boundaries.
//
// These are the windows where two literals must stay in lockstep or a silent
// one-frame gap opens. Reference them from BOTH paired sites so tuning one number
// can't desync its partner. Purely-local one-off _seg windows stay as literals.
// ─────────────────────────────────────────────────────────────────────────────

/// Lantern → card swap — the Emerald/default burst point. Per-tier the swap is
/// now driven by `spec.burstAt` (lower tiers ignite earlier): the build gates
/// the vessel with `t < spec.burstAt` and the card's `appear` window opens at
/// exactly `spec.burstAt`, so the vessel never vanishes a frame before the card
/// fades in. This const is Emerald's value (`revealSpecFor(emerald).burstAt`),
/// kept as the shared default anchor + the interlock reference for the tests.
const double kCardSwap = 0.46;

/// Caption gate. The name/badge/continue stack is mounted only for
/// `t > kCaptionIn`; the badge stagger's first window (`aBadge`) also opens here,
/// so the caption never mounts before its first child has anything to show.
const double kCaptionIn = 0.85;

/// Spin-settle handoff. The decelerating Y-spin's easing window ENDS here and
/// the overshoot wobble window BEGINS here — they must match exactly or the
/// landing wobble either starts before the spin finishes or leaves a dead gap.
const double kSpinSettle = 0.86;

// ─────────────────────────────────────────────────────────────────────────────
// Timeline helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Normalised 0→1 progress of `t` within the window [a, b], clamped.
double seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

/// A 0→1→0 bell over a 0→1 input (for flashes).
double bell(double x) => math.sin(x.clamp(0.0, 1.0) * math.pi);

// ─────────────────────────────────────────────────────────────────────────────
// Card motion — the pure choreography math the overlay's _buildCard applies.
//
// Given the normalized reveal progress `t` and the ambient loop phase `ambient`
// (0→1), returns every value the card transform needs. Widget-free and
// deterministic, so tier escalation invariants are unit-testable without a pump.
// ─────────────────────────────────────────────────────────────────────────────

/// The computed transform inputs for a single reveal frame.
typedef RevealCardMotion = ({
  double appear, // 0→1 eased scale/opacity entrance
  double angle, // radians, Y-rotation (0 for non-spinning tiers)
  bool facingFront, // whether the front face shows this frame
  double spinTilt, // -1..1, drives the specular sweep
  double foilPhase, // 0→1 holographic hue drift
  double pop, // additive landing scale pop
  double settleY, // vertical settle offset (pre-bob)
});

RevealCardMotion revealCardMotion(RevealSpec spec, double t, double ambient) {
  // Card entrance is anchored to the tier's burst point (lower tiers ignite
  // earlier). Monotonic easeOutCubic so it owns NO overshoot — the settle
  // spring + landing pop are the single bounce owner (#004 / #005). Emerald
  // (burstAt 0.46) reproduces the original [0.46, 0.58] window.
  final appear =
      Curves.easeOutCubic.transform(seg(t, spec.burstAt, spec.burstAt + 0.12));

  // Motion is spec-gated. Spinning tiers (Silver/Gold/Emerald) run the tuned
  // decelerating Y-spin with a settle overshoot + front/back swap. Bronze
  // (spinTurns == 0) just scales/fades in from the burst — no rotation, its
  // back is never shown, and the foil phase drifts on the ambient loop only.
  double angle = 0;
  bool facingFront = true;
  double spinTilt = 0; // -1..1, drives the specular sweep
  double foilPhase = ambient;
  if (spec.spins) {
    // Spin window pivots on the burst point (Emerald 0.46 → [0.49, 0.86]).
    // easeOutQuint holds high speed longer then decelerates hard in the tail —
    // the "will-it-land" tension lives in that terminal decel (#004).
    final spinT =
        Curves.easeOutQuint.transform(seg(t, spec.burstAt + 0.03, kSpinSettle));
    // Settle overshoot — a SINGLE asymmetric damped overshoot in the spin
    // direction (a weighted landing, not a symmetric jelly rock). Overshoots
    // once past the final angle (negative = spin direction) then decays to ~0 by
    // land=1: sin(land·π) is one hump (no inner zero-crossing → one overshoot)
    // and is exactly 0 at land=1 so angle collapses to 0 at t=1.0 (#004).
    final land = seg(t, kSpinSettle, 1.0);
    final wobble = -math.sin(land * math.pi) * math.exp(-3.2 * land) * 0.13;
    angle = (1 - spinT) * spec.spinTurns * 2 * math.pi + wobble;
    facingFront = math.cos(angle) >= 0;
    spinTilt = math.sin(angle);
    foilPhase = ((angle / (2 * math.pi)) + ambient) % 1.0;
  }

  // Landing scale pop synced to the spin's face-arrival: the bell peaks at
  // kSpinSettle so the pop coincides with the card landing face-front (#004).
  // The rise + idle bob (bob stays in the widget since it depends only on the
  // ambient loop, not the reveal timeline) keep their original window.
  final pop = bell(seg(t, kSpinSettle - 0.06, kSpinSettle + 0.06)) * 0.05;
  final settleY = -seg(t, 0.84, 0.94) * 8;

  return (
    appear: appear,
    angle: angle,
    facingFront: facingFront,
    spinTilt: spinTilt,
    foilPhase: foilPhase,
    pop: pop,
    settleY: settleY,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Ray-fan helper — the shared "rotating triangular ray fan" idiom used by the
// lantern-rays, aurora, and burst-shafts painters. Each painter supplies only
// its per-ray closures; the save/translate/rotate/loop/restore scaffold is here
// so the visual output is byte-identical across the three.
// ─────────────────────────────────────────────────────────────────────────────

void paintRayFan(
  Canvas canvas,
  Offset center, {
  required int rays,
  required double baseRotation,
  required double Function(int i) lenFor,
  required double Function(int i) halfWidthFor,
  required Shader Function(int i, double halfW, double len) shaderFor,
  MaskFilter? Function(int i, double halfW)? maskFor,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(baseRotation);
  for (var i = 0; i < rays; i++) {
    final len = lenFor(i);
    final halfW = halfWidthFor(i);
    canvas.save();
    canvas.rotate(i * 2 * math.pi / rays);
    final paint = Paint()
      ..shader = shaderFor(i, halfW, len)
      ..blendMode = BlendMode.plus;
    final mask = maskFor?.call(i, halfW);
    if (mask != null) paint.maskFilter = mask;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(-halfW, len)
        ..lineTo(halfW, len)
        ..close(),
      paint,
    );
    canvas.restore();
  }
  canvas.restore();
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle field — sparks flung from the burst + rested embers/motes.
// ─────────────────────────────────────────────────────────────────────────────

class Spark {
  const Spark(this.angle, this.distance, this.size, this.speed);
  final double angle;
  final double distance;
  final double size;
  final double speed;
}

List<Spark> buildSparks(int n) {
  final rng = math.Random(7);
  return List.generate(n, (i) {
    final angle = (i / n) * 2 * math.pi + rng.nextDouble() * 0.5;
    return Spark(
      angle,
      0.28 + rng.nextDouble() * 0.5,
      1.5 + rng.nextDouble() * 3.0,
      0.7 + rng.nextDouble() * 0.6,
    );
  });
}

class Mote {
  const Mote(this.x, this.y, this.size, this.speed, this.seed);
  final double x; // -1..1 around centre (fraction of half-width)
  final double y; // -1..1 around centre (fraction of half-height)
  final double size;
  final double speed;
  final double seed;
}

List<Mote> buildMotes(int n) {
  final rng = math.Random(19);
  return List.generate(
    n,
    (i) => Mote(
      (rng.nextDouble() * 2 - 1) * 0.9,
      (rng.nextDouble() * 2 - 1) * 0.7,
      1.0 + rng.nextDouble() * 2.2,
      0.4 + rng.nextDouble() * 0.7,
      rng.nextDouble(),
    ),
  );
}
