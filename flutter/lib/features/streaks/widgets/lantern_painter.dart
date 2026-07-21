// The lantern (fānūs) companion painter — the production home of the code-drawn
// avatar. Extracted from `lib/prototypes/lantern_companion_prototype.dart`
// (Phase 0 of the streaks + companion plan, 2026-07-18).
//
// Pure `CustomPainter` (+ the optional `shaders/khatam_glow.frag` ambient aura).
// The full geometric khatam sequence is ALWAYS drawn; the streak drives
// brightness (`glow`), not a piece-by-piece reveal. `wear` is decoupled from
// `glow` so a brand-new / just-lit lamp stays faint-but-clean — never a
// cobwebbed "cold Day 0" (reverence guardrail, plan §1).
//
// The medallion widget (`companion_medallion.dart`) lerps `glow`/`wear` on state
// change and feeds `pulse` from a bounded animation controller.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _outline = Color(0xFF241810); // thick warm-dark outline (illustrated look)
const _goldTop = Color(0xFFF0D8A0);
const _goldMid = Color(0xFFD9A968);
const _goldBot = Color(0xFFB07E45);
const _goldDark = Color(0xFF6E4F28);
const _glass = Color(0xFF0C3120);
const _lightGold = Color(0xFFFBE7BE);
const _amber = Color(0xFFE8A154);
const _shield = Color(0xFFAFD8EC);
const _muted = Color(0xFF5C5A50);
// Negative-state palette (dormant/lapsed) — cold, drained of warmth.
const _coldMetalTop = Color(0xFF48525C);
const _coldMetalBot = Color(0xFF262E36);
const _coldGlow = Color(0xFF6B8AA6); // faint cold haze clinging to a dead lamp
const _dreadHaze = Color(0xFF0A131C); // vignette that drains the edges
const _dread = Color(0xFF05090E); // cold shadow pooling beneath
const _smoke = Color(0xFF9AA6B2); // wisp from the snuffed wick
const _coldOutline = Color(0xFF11171D);
// Positive-state accent — rising embers on a strong streak.
const _ember = Color(0xFFFFD089);
// Worn/dusty gold — the metal tarnishes as the light weakens (neglect), short
// of the fully-cold dormant palette.
const _dustyGoldTop = Color(0xFFAFA07C);
const _dustyGoldBot = Color(0xFF6B5F44);
// Flame layers.
const _flameBlue = Color(0xFF6FA0C8); // cool base of a real flame
const _flameCore = Color(0xFFFFF6E2); // hot white-gold core

/// Draws the lantern companion. Stateless per-frame: [pulse] (0→1, looped) drives
/// the living motion, [glow] the streak brightness, [wear] the dust/tarnish,
/// [dormant] the cold-dead lapse treatment, [protected] the shield overlay.
class LanternPainter extends CustomPainter {
  LanternPainter({
    required this.illumination,
    required this.glow,
    required this.dormant,
    required this.protected,
    required this.pulse,
    this.wear,
    this.ambientShader,
    this.ambient = true,
  });

  final double illumination;
  final double glow;
  final bool dormant;
  final bool protected;
  final double pulse;

  /// Whether to paint the full-canvas ambient background (the lit aura / the
  /// dormant cold vignette). True on immersive dark surfaces (home, sacred
  /// canvas). Set false when the medallion sits on a light CARD — otherwise the
  /// dormant vignette's dark→transparent gradient renders as an ugly grey square
  /// behind the lantern (the object itself always draws regardless).
  final bool ambient;

  /// Dust/tarnish amount, 0 = pristine … 1 = grimy + cobwebbed. When null,
  /// falls back to the legacy glow-derived neglect (preserves the standalone
  /// prototype / render harness). The production resolver always passes it
  /// explicitly so faint states (endowed / pending) stay clean.
  final double? wear;
  final ui.FragmentShader? ambientShader;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = pulse * 2 * math.pi;
    final breath = 0.5 + 0.5 * math.sin(phase);
    final g = (glow * (0.9 + 0.2 * breath)).clamp(0.0, 1.1);

    // Ambient aura (lit) — or a cold, draining vignette (dormant). Both fill the
    // whole canvas, so they're skipped on light cards (see [ambient]).
    final shader = ambientShader;
    if (ambient && shader != null && !dormant) {
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, phase)
        ..setFloat(3, (0.3 + 0.95 * glow).clamp(0.0, 1.0));
      canvas.drawRect(Offset.zero & size,
          Paint()..shader = shader..blendMode = BlendMode.plus);
    } else if (ambient && dormant) {
      // A cold, ominous shadow pooled *behind* the lamp, dissolving to
      // transparent before the edges. NOT an edge vignette — a dark *outer*
      // stop fills the canvas corners and reads as a grey SQUARE on a light
      // page. Dark centre + transparent at radius 0.5 leaves the corners
      // (beyond the radius) clear, so no box forms — just a dead-grey presence.
      final c = Offset(size.width / 2, size.height * 0.5);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            size.shortestSide * 0.5,
            [
              _dreadHaze.withValues(alpha: 0.62),
              _dreadHaze.withValues(alpha: 0.34),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          ),
      );
      // A faint cold breath clinging to the dead lamp (slightly above centre).
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.46),
        size.shortestSide * (0.30 + 0.03 * breath),
        Paint()
          ..color = _coldGlow.withValues(alpha: 0.045 + 0.02 * breath)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, size.shortestSide * 0.13),
      );
    }

    canvas.translate(size.width / 2, size.height / 2 + size.shortestSide * 0.02);
    final s = size.shortestSide;

    // Posture — the companion's body language (Duolingo/Forest/Plant-Nanny
    // technique). The lantern SAGS and tilts when the light has gone out
    // (defeated), and lifts a touch when radiant (a proud perk-up). This is
    // the single most "alive" cue after the flame itself.
    final joy = ((glow - 0.85) / 0.15).clamp(0.0, 1.0);
    final sag = dormant ? s * 0.016 : -s * 0.008 * joy;
    final tilt = dormant ? 0.045 : 0.0; // ~2.6° defeated lean
    final bodyScale = dormant ? 0.96 : 1.0 + 0.03 * joy;

    // Per-state living MOTION — the whole housing emotes, not just the flame.
    // Integer harmonics of `phase` so every loop is seamless (no hitch at wrap).
    //   dormant  : a faint, slow, lifeless rock leaning from the base
    //   dim      : a tentative catch-to-life bob
    //   glowing  : a gentle content breathing sway
    //   fully-lit: an eager, bouncy up-bob (joy)
    //   protected: near-still (its ring rotates instead — below)
    double sway = 0, bob = 0, breathScale = 0;
    var pivotY = 0.0;
    if (dormant) {
      sway = math.sin(phase) * 0.02; // ±1.1°, ~2.6s
      pivotY = s * 0.24; // pivot at the base → a slumped lean
    } else if (protected) {
      breathScale = math.sin(phase) * 0.006; // serene, barely-there
    } else if (joy > 0.5) {
      bob = -(0.5 + 0.5 * math.sin(phase * 2)) * s * 0.014; // eager up-bob
      sway = math.sin(phase * 2 + 0.7) * 0.013;
      breathScale = math.sin(phase * 2) * 0.012;
    } else if (glow < 0.4) {
      bob = math.sin(phase) * s * 0.006; // tentative
      sway = math.sin(phase + 1.0) * 0.012;
    } else {
      sway = math.sin(phase) * 0.02; // content breathing sway
      breathScale = math.sin(phase + 1.5) * 0.01;
    }

    canvas.save();
    canvas.translate(0, sag + bob);
    canvas.translate(0, pivotY); // rotate about the pivot…
    canvas.rotate(tilt + sway);
    canvas.translate(0, -pivotY);
    canvas.scale(bodyScale + breathScale);

    // Neglect — dust + tarnish. Explicit `wear` when provided (so a faint-but-
    // fresh lamp stays clean); otherwise the legacy glow-derived fallback.
    // 1.0 = dormant/grimy, ~0.5 = worn, 0 = pristine.
    final neglect = wear ??
        (dormant
            ? 1.0
            : math.pow((1 - glow / 0.62).clamp(0.0, 1.0), 0.7).toDouble());

    // Geometry.
    final w = s * 0.19; // body half-width
    final bodyTop = -s * 0.10;
    final bodyBot = s * 0.22;
    final body = _barrel(w, bodyTop, bodyBot, s * 0.028, s * 0.04);
    final dome = _dome(s, w, bodyTop);
    final base = _base(s, w, bodyBot);
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTRB(-w * 0.66, bodyTop + s * 0.028, w * 0.66, bodyBot - s * 0.03),
      Radius.circular(s * 0.03),
    );

    // Grounding glow-pool + rays/embers (joy) or content halo (at ease).
    if (!dormant && g > 0.05) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, bodyBot + s * 0.11),
            width: s * (0.4 + 0.32 * g),
            height: s * 0.06),
        Paint()
          ..color = _amber.withValues(alpha: 0.26 * g)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
      );
      // JOY (fully-lit): radiating warmth — soft god-rays + rising embers.
      // Suppressed when protected — shelter is calm, not energetic. Threshold
      // 0.82 keeps rays exclusive to fully-lit (g≈0.90–1.1) now that the tier
      // glow values are brighter; glowing (g≈0.65–0.79) stays the cozy halo.
      if (g > 0.82 && !protected) {
        // Central radiant burst — a broad soft bloom so fully-lit reads as
        // genuinely LUMINOUS, not just a lit lamp. Scaled by joy (fully-lit
        // only) and breathes on the seamless sinusoid.
        canvas.drawCircle(
          Offset(0, s * 0.02),
          s * (0.34 + 0.06 * breath),
          Paint()
            ..color = _amber.withValues(alpha: 0.24 * joy)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.13)
            ..blendMode = BlendMode.plus,
        );
        _rays(canvas, s, g, phase);
        _embers(canvas, s, g, phase);
      }
      // CONTENT (glowing): a soft cozy halo instead of rays — reads "at ease",
      // clearly gentler than triumph. Mid band up to the ray threshold.
      if (!protected && g > 0.3 && g < 0.82) {
        for (final rr in [0.30, 0.42, 0.55]) {
          canvas.drawCircle(
            Offset(0, s * 0.02),
            s * rr,
            Paint()
              ..color = _amber.withValues(alpha: 0.13 * g)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.07)
              ..blendMode = BlendMode.plus,
          );
        }
      }
    }
    // Dread pooling — a cold shadow that SPREADS beneath the dead lamp (the
    // inverse of the warm glow-pool), so the negative state has weight.
    if (dormant) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, bodyBot + s * 0.12),
            width: s * (0.62 + 0.04 * breath),
            height: s * 0.11),
        Paint()
          ..color = _dread.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.055),
      );
    }
    // Soft contact shadow.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, bodyBot + s * 0.13),
          width: s * 0.34,
          height: s * 0.04),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.015),
    );

    // Bloom halo around the whole lantern (lit).
    if (!dormant && g > 0.05) {
      canvas.drawPath(
        body,
        Paint()
          ..color = _amber.withValues(alpha: 0.30 * g)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, s * (0.04 + 0.05 * g)),
      );
    }

    if (protected) {
      // SHELTER — a calm ENCLOSING boundary (the research's "containment ring"),
      // not radiating energy. Reads "held / safe", distinct from joy's rays.
      final centre = Offset(0, s * 0.02);
      // Soft silhouette shelter-glow hugging the lantern.
      canvas.drawPath(
        _outlinePath([dome, body, base]),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..color = _shield.withValues(alpha: 0.11 + 0.05 * breath)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05),
      );
      // The containment ring: a serene double ring that gently breathes.
      final rr = s * (0.40 + 0.008 * breath);
      canvas.drawCircle(
        centre,
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.007
          ..color = _shield.withValues(alpha: 0.40)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.004)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        centre,
        rr * 1.07,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.0035
          ..color = _shield.withValues(alpha: 0.20),
      );
      // A slowly rotating ring of ticks — a serene protective seal turning
      // around the lamp. Advances exactly one tick per phase loop → seamless.
      const ticks = 12;
      final tick = Paint()
        ..strokeWidth = s * 0.006
        ..strokeCap = StrokeCap.round
        ..color = _shield.withValues(alpha: 0.32)
        ..blendMode = BlendMode.plus;
      for (var i = 0; i < ticks; i++) {
        final a = i * 2 * math.pi / ticks + phase / ticks;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(centre + dir * rr * 1.02, centre + dir * rr * 1.06, tick);
      }
    }

    final outlineW = s * 0.013;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineW
      ..strokeJoin = StrokeJoin.round
      ..color = dormant ? _coldOutline : _outline;

    // Metal fill helper — warm gold when lit, cold tarnished blue-grey when
    // dormant (the gold has gone cold, not just dim).
    Paint metal(double topY, double botY) => Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topY),
        Offset(0, botY),
        dormant
            ? [_coldMetalTop, _coldMetalBot]
            : [
                Color.lerp(_goldTop, _dustyGoldTop, neglect)!,
                Color.lerp(_goldMid, _dustyGoldBot, neglect * 0.9)!,
                Color.lerp(_goldBot, _dustyGoldBot, neglect)!,
              ],
        dormant ? const [0.0, 1.0] : const [0.0, 0.55, 1.0],
      );

    // BASE, then DOME behind body, then BODY.
    canvas.drawPath(base, metal(bodyBot, bodyBot + s * 0.08));
    canvas.drawPath(base, outline);
    canvas.drawPath(dome, metal(-s * 0.30, bodyTop));
    canvas.drawPath(dome, outline);

    // Shoulder band between dome + body.
    final shoulder = Path()
      ..moveTo(-w, bodyTop)
      ..lineTo(w, bodyTop)
      ..lineTo(w * 0.7, bodyTop - s * 0.03)
      ..lineTo(-w * 0.7, bodyTop - s * 0.03)
      ..close();
    canvas.drawPath(shoulder, metal(bodyTop - s * 0.03, bodyTop));
    canvas.drawPath(shoulder, outline);

    canvas.drawPath(body, metal(bodyTop, bodyBot));

    // Glass panel — dark, holds the khatam light (lit) or a cold, cracked
    // ghost of it (dormant).
    canvas.save();
    canvas.clipRRect(panel);
    canvas.drawRRect(
        panel, Paint()..color = dormant ? const Color(0xFF0A1116) : _glass);
    if (!dormant) {
      // The FLAME — the lantern's living "face". Sits in the emblem's open
      // centre; its height/steadiness/colour carry the emotion, and the khatam
      // frames it. (Journey/Sky/candle technique: light IS the expression.)
      _flame(canvas, panel.outerRect, g, phase, breath);
      _khatamLight(canvas, panel.outerRect, g);
      // Glass reflection streak (a dead lamp reflects nothing).
      canvas.drawPath(
        Path()
          ..moveTo(panel.left + s * 0.02, panel.top)
          ..lineTo(panel.left + s * 0.08, panel.top)
          ..lineTo(panel.left + s * 0.02, panel.bottom)
          ..lineTo(panel.left - s * 0.04, panel.bottom)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.05),
      );
      // Worn but lit (dim / recovering) — dust settles, a faint web in the
      // corner. Fades out entirely as the streak strengthens.
      if (neglect > 0.05) {
        _dustFilm(canvas, panel.outerRect, neglect);
        _cobweb(canvas, panel.outerRect, neglect, phase);
        _dustMotes(canvas, panel.outerRect, neglect, phase);
      }
    } else {
      _coldGhost(canvas, panel.outerRect); // the form remains, cold and unlit
      _cracks(canvas, panel); // hairline fractures in the glass
      _dustFilm(canvas, panel.outerRect, 1.0); // heavy settled dust
      _cobweb(canvas, panel.outerRect, 1.0, phase); // full cobwebs
      _dustMotes(canvas, panel.outerRect, 1.0, phase);
    }
    canvas.restore();
    canvas.drawRRect(panel, outline);

    // Body outline + two facet lines flanking the panel (multi-panel hint).
    canvas.drawPath(body, outline);
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.006
      ..color = (dormant ? _muted : _goldDark).withValues(alpha: 0.6);
    for (final x in [-w * 0.82, w * 0.82]) {
      canvas.drawLine(Offset(x, bodyTop + s * 0.02),
          Offset(x, bodyBot - s * 0.02), facet);
    }

    // Rim light for dimensionality — warm when lit, a faint COLD rim when
    // dormant so the dead silhouette still reads against the dark vignette.
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.008
        ..color = (dormant ? _coldGlow : _lightGold)
            .withValues(alpha: dormant ? 0.28 : 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.004)
        ..blendMode = BlendMode.plus,
    );

    // Finial + hanging ring on top of the dome.
    final apex = -s * 0.30;
    canvas.drawCircle(Offset(0, apex + s * 0.012), s * 0.018,
        metal(apex, apex + s * 0.03));
    canvas.drawCircle(Offset(0, apex + s * 0.012), s * 0.018, outline);
    canvas.drawCircle(
      Offset(0, apex - s * 0.028),
      s * 0.022,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineW
        ..color = dormant ? _coldOutline : _goldMid,
    );

    // Particle layer — the object's aftermath / vitality.
    if (dormant) {
      // Smoke from the snuffed wick + a little falling ash: "the light went
      // out." (Avatar technique — the extinguish signature, not a symbol.)
      _smokeWisp(canvas, s, apex, phase);
      _fallingAsh(canvas, s, bodyBot, phase);
    } else if (g > 0.6 && !protected) {
      // Kirakira: joy-sparkles twinkling around a strong, radiant streak.
      _sparkles(canvas, s, g, phase);
    }

    canvas.restore(); // close posture transform
  }

  // A barrel body (rounded rect with slightly bulged sides).
  Path _barrel(double w, double t, double b, double bulge, double rad) {
    return Path()
      ..moveTo(-w, t + rad)
      ..quadraticBezierTo(-w, t, -w + rad, t)
      ..lineTo(w - rad, t)
      ..quadraticBezierTo(w, t, w, t + rad)
      ..quadraticBezierTo(w + bulge, (t + b) / 2, w, b - rad)
      ..quadraticBezierTo(w, b, w - rad, b)
      ..lineTo(-w + rad, b)
      ..quadraticBezierTo(-w, b, -w, b - rad)
      ..quadraticBezierTo(-w - bulge, (t + b) / 2, -w, t + rad)
      ..close();
  }

  // An onion dome tapering to a point.
  Path _dome(double s, double w, double baseY) {
    final dw = w * 0.82;
    final apex = -s * 0.30;
    return Path()
      ..moveTo(-dw, baseY)
      ..cubicTo(-dw * 1.18, baseY - s * 0.05, -s * 0.06, apex + s * 0.055, 0, apex)
      ..cubicTo(s * 0.06, apex + s * 0.055, dw * 1.18, baseY - s * 0.05, dw, baseY)
      ..close();
  }

  // A plinth base widening below the body.
  Path _base(double s, double w, double b) {
    final bw = w * 1.14;
    return Path()
      ..moveTo(-w, b - s * 0.01)
      ..lineTo(w, b - s * 0.01)
      ..lineTo(bw, b + s * 0.05)
      ..quadraticBezierTo(bw, b + s * 0.075, bw - s * 0.02, b + s * 0.075)
      ..lineTo(-bw + s * 0.02, b + s * 0.075)
      ..quadraticBezierTo(-bw, b + s * 0.075, -bw, b + s * 0.05)
      ..close();
  }

  Path _outlinePath(List<Path> ps) {
    final p = Path();
    for (final x in ps) {
      p.addPath(x, Offset.zero);
    }
    return p;
  }

  // Soft god-rays — thin, blurred wedges of warmth (not a hard sunburst).
  void _rays(Canvas canvas, double s, double g, double phase) {
    final ray = Paint()
      ..blendMode = BlendMode.plus
      ..color = _amber.withValues(alpha: 0.18 * g)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02);
    for (var k = 0; k < 12; k++) {
      // phase/6 advances exactly two ray slots (2·π/6) per loop → seamless
      // (the old fractional 0.15 snapped the whole burst back at the wrap).
      final a = phase / 6 + k * math.pi / 6;
      // Alternating long/short rays for a softer, less mechanical burst.
      final len = s * (k.isEven ? 0.62 : 0.48);
      final p = Path()
        ..moveTo(0, 0)
        ..lineTo(len * math.cos(a - 0.035), len * math.sin(a - 0.035))
        ..lineTo(len * math.cos(a + 0.035), len * math.sin(a + 0.035))
        ..close();
      canvas.drawPath(p, ray);
    }
  }

  // Rising embers — sparks of warmth drifting up from a strong streak. Seeded
  // per-index (no RNG) and driven by `phase` so they loop smoothly.
  void _embers(Canvas canvas, double s, double g, double phase) {
    const seeds = [0.13, 0.37, 0.61, 0.82, 0.5, 0.24, 0.71, 0.05];
    for (var i = 0; i < seeds.length; i++) {
      // phase/(2π) completes exactly one 0→1 rise per loop → seamless (the old
      // fractional 0.09 teleported every ember back at the wrap).
      final t = (phase / (2 * math.pi) + seeds[i]) % 1.0; // 0→1 rise cycle
      final x = (seeds[i] - 0.5) * s * 0.44 + math.sin(t * 6.283 + i) * s * 0.02;
      final y = s * 0.18 - t * s * 0.52;
      final a = ((1 - t) * t * 4) * 0.72 * g; // fade in then out
      canvas.drawCircle(
        Offset(x, y),
        s * 0.007 * (1 - t * 0.4),
        Paint()
          ..color = _ember.withValues(alpha: a.clamp(0.0, 0.72))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.004)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  // The FLAME — the lantern's living face. A proper layered candle flame:
  // soft glow halo → amber teardrop body → gold inner → white-gold hot core →
  // a cool blue base at the wick. Height/steadiness/colour encode the streak;
  // it leans + breathes, guttering (jittery) when weak, tall + calm when strong.
  void _flame(Canvas canvas, Rect panel, double g, double phase, double breath) {
    if (g < 0.04) return;
    final cx = panel.center.dx;
    final live = 0.9 + 0.1 * breath; // gentle breathing height
    final h = panel.height * (0.20 + 0.28 * g) * live;
    final w = panel.width * (0.05 + 0.028 * g);
    final baseY = panel.center.dy + h * 0.30;
    final steady = g.clamp(0.0, 1.0); // 1 = calm, 0 = guttering
    // Integer harmonics (3, 5) so the flicker returns to its exact start at the
    // 2π loop wrap — the old 2.6/5.3 harmonics snapped every ~2.6s (the "reset"
    // the user saw in every lit lantern).
    final lean = (math.sin(phase * 3) * 0.6 + math.sin(phase * 5) * 0.4) *
        (1 - steady * 0.85) *
        w *
        0.7;

    // A teardrop flame silhouette: rounded, bulging low, tapering to a leaning
    // tip. `sw`/`sh` scale the layers inward; `off` leans the tip.
    Path flame(double sw, double sh, double off) {
      final ww = w * sw, hh = h * sh;
      return Path()
        ..moveTo(cx, baseY)
        ..quadraticBezierTo(cx - ww * 1.02, baseY - hh * 0.32, cx - ww * 0.82,
            baseY - hh * 0.6)
        ..quadraticBezierTo(
            cx - ww * 0.62, baseY - hh * 0.9, cx + off, baseY - hh)
        ..quadraticBezierTo(
            cx + ww * 0.62, baseY - hh * 0.9, cx + ww * 0.82, baseY - hh * 0.6)
        ..quadraticBezierTo(cx + ww * 1.02, baseY - hh * 0.32, cx, baseY)
        ..close();
    }

    // 1. Soft glow halo behind the flame.
    canvas.drawCircle(
      Offset(cx, baseY - h * 0.42),
      h * (0.72 + 0.06 * breath),
      Paint()
        ..color = _amber.withValues(alpha: 0.32 * g)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.5)
        ..blendMode = BlendMode.plus,
    );
    // 2. Outer amber body (soft edge).
    canvas.drawPath(
      flame(1.0, 1.0, lean),
      Paint()
        ..color = _amber.withValues(alpha: 0.92)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.16),
    );
    // 3. Inner gold flame.
    canvas.drawPath(
      flame(0.6, 0.82, lean * 0.72),
      Paint()
        ..color = _lightGold.withValues(alpha: 0.95)
        ..blendMode = BlendMode.plus,
    );
    // 4. Hot white-gold core near the base (brighter with the streak).
    canvas.drawPath(
      flame(0.32, 0.55, lean * 0.5),
      Paint()
        ..color = _flameCore.withValues(alpha: 0.85 + 0.15 * g)
        ..blendMode = BlendMode.plus,
    );
    // 5. Cool blue base at the wick — the detail that makes it read as real.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, baseY - h * 0.03),
          width: w * 1.05,
          height: h * 0.18),
      Paint()
        ..color = _flameBlue.withValues(alpha: 0.32 * g)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.18)
        ..blendMode = BlendMode.plus,
    );
  }

  // Falling ash — a few grey motes drifting down from the snuffed lamp.
  void _fallingAsh(Canvas canvas, double s, double bodyBot, double phase) {
    const seeds = [0.2, 0.5, 0.78, 0.35, 0.63];
    for (var i = 0; i < seeds.length; i++) {
      final t = (phase / (2 * math.pi) + seeds[i]) % 1.0;
      final x = (seeds[i] - 0.5) * s * 0.3 + math.sin(t * 4 + i) * s * 0.015;
      final y = -s * 0.14 + t * (bodyBot + s * 0.18);
      final a = (1 - t) * 0.35;
      canvas.drawCircle(
        Offset(x, y),
        s * 0.005,
        Paint()..color = _smoke.withValues(alpha: a.clamp(0.0, 0.35)),
      );
    }
  }

  // Settled dust film across the glass — heavier at the bottom, pooling in the
  // corners. `strength` scales with neglect so a dim lamp is visibly dusty and
  // a dormant one is grimy.
  void _dustFilm(Canvas canvas, Rect panel, double strength) {
    canvas.drawRect(
      panel,
      Paint()
        ..shader = ui.Gradient.linear(
          panel.topCenter,
          panel.bottomCenter,
          [
            const Color(0xFFB0AA95).withValues(alpha: 0.10 * strength),
            const Color(0xFF9A9480).withValues(alpha: 0.30 * strength),
          ],
        ),
    );
    // Grime pooling into the two bottom corners.
    for (final corner in [panel.bottomLeft, panel.bottomRight]) {
      canvas.drawCircle(
        corner,
        panel.width * 0.34,
        Paint()
          ..shader = ui.Gradient.radial(corner, panel.width * 0.34, [
            const Color(0xFF8E8873).withValues(alpha: 0.28 * strength),
            const Color(0xFF8E8873).withValues(alpha: 0.0),
          ])
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, panel.width * 0.04),
      );
    }
  }

  // Cobwebs in BOTH top corners of the glass — radial struts + sagging rings +
  // a hanging thread with a little bob that sways on `phase`. Scales with
  // neglect, so a dim (worn) lamp is webbed and a dormant one is thick with it.
  void _cobweb(Canvas canvas, Rect panel, double strength, double phase) {
    final sway = math.sin(phase) * panel.width * 0.012;
    _cornerWeb(
        canvas, panel.topRight, -1.0, panel.width * 0.52, strength, sway, phase);
    _cornerWeb(canvas, panel.topLeft, 1.0, panel.width * 0.42, strength * 0.75,
        -sway, phase);
  }

  // One corner web. `dir` = -1 fans left (top-right corner), +1 fans right.
  void _cornerWeb(Canvas canvas, Offset o, double dir, double r, double strength,
      double sway, double phase) {
    const web = Color(0xFFD8DDE2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.013
      ..strokeCap = StrokeCap.round
      ..color = web.withValues(alpha: 0.46 * strength);
    const fracs = [0.06, 0.3, 0.55, 0.8, 0.97]; // 0 = horizontal inward → 1 = down
    final ends = <Offset>[];
    for (final f in fracs) {
      final a = f * math.pi / 2;
      ends.add(Offset(
          o.dx + dir * math.cos(a) * r, o.dy + math.sin(a) * r + sway * f));
    }
    for (final e in ends) {
      canvas.drawLine(o, e, p);
    }
    // Two sagging rings connecting the struts (the web itself).
    for (final ring in [0.42, 0.78]) {
      final path = Path();
      for (var i = 0; i < ends.length; i++) {
        final pt = Offset.lerp(o, ends[i], ring)!;
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          final prev = Offset.lerp(o, ends[i - 1], ring)!;
          final mid = Offset((prev.dx + pt.dx) / 2, (prev.dy + pt.dy) / 2);
          final sagPt = Offset(mid.dx - dir * r * 0.04, mid.dy + r * 0.06);
          path.quadraticBezierTo(sagPt.dx, sagPt.dy, pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, p);
    }
    // A hanging droop thread + a tiny bob at the end that sways.
    final anchor = Offset.lerp(o, ends[2], 0.62)!;
    final bob = Offset(
        anchor.dx + math.sin(phase) * r * 0.07, anchor.dy + r * 0.44);
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.008
      ..color = web.withValues(alpha: 0.22 * strength);
    canvas.drawLine(anchor, bob, thread);
    canvas.drawCircle(
        bob, r * 0.022, Paint()..color = web.withValues(alpha: 0.3 * strength));
  }

  // Slow-drifting dust motes caught in stale air — faint specks rising and
  // fading. Count + opacity scale with neglect; animated on `phase`.
  void _dustMotes(Canvas canvas, Rect panel, double strength, double phase) {
    final n = (7 * strength).round().clamp(0, 7);
    const sx = [0.18, 0.4, 0.62, 0.8, 0.3, 0.7, 0.52];
    const sy = [0.1, 0.55, 0.3, 0.75, 0.9, 0.45, 0.2];
    for (var i = 0; i < n; i++) {
      final t = (phase / (2 * math.pi) + sy[i]) % 1.0;
      final x = panel.left +
          panel.width * sx[i] +
          math.sin(phase + i * 2) * panel.width * 0.03;
      final y = panel.bottom - t * panel.height;
      final a = math.sin(t * math.pi) * 0.62 * strength;
      canvas.drawCircle(
        Offset(x, y),
        panel.width * 0.008,
        Paint()
          ..color = const Color(0xFFDED8C0).withValues(alpha: a.clamp(0.0, 0.6))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, panel.width * 0.004),
      );
    }
  }

  // Kirakira joy-sparkles — a few four-point stars twinkling around a radiant
  // streak (staggered by index so they shimmer, not blink in unison).
  void _sparkles(Canvas canvas, double s, double g, double phase) {
    const pts = [
      Offset(-0.27, -0.22), Offset(0.29, -0.15), Offset(-0.31, 0.03),
      Offset(0.25, 0.07), Offset(-0.15, -0.34), Offset(0.11, -0.31),
      Offset(0.33, -0.03),
    ];
    final strength = ((g - 0.6) / 0.4).clamp(0.0, 1.0);
    for (var i = 0; i < pts.length; i++) {
      final tw = 0.5 + 0.5 * math.sin(phase * 2 + i * 1.7); // twinkle (seamless)
      final r = s * (0.016 + 0.010 * tw);
      final a = (0.22 + 0.5 * tw) * strength;
      _sparkle(
        canvas,
        Offset(pts[i].dx * s, pts[i].dy * s),
        r,
        Paint()
          ..color = _lightGold.withValues(alpha: a.clamp(0.0, 0.85))
          ..blendMode = BlendMode.plus,
      );
    }
  }

  // A single four-point sparkle (concave diamond).
  void _sparkle(Canvas canvas, Offset o, double r, Paint p) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 0.28, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 0.28, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
        ..close(),
      p,
    );
  }

  // A thin, wavering column of smoke from the extinguished wick.
  void _smokeWisp(Canvas canvas, double s, double apex, double phase) {
    final path = Path()..moveTo(0, apex - s * 0.01);
    for (var i = 1; i <= 8; i++) {
      final t = i / 8.0;
      final y = apex - s * 0.01 - t * s * 0.26;
      final x = math.sin(phase + t * 5.0) * s * 0.035 * t;
      path.lineTo(x, y);
    }
    // Wide, faint halo pass, then the finer strand on top.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.026
        ..strokeCap = StrokeCap.round
        ..color = _smoke.withValues(alpha: 0.05)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.011
        ..strokeCap = StrokeCap.round
        ..color = _smoke.withValues(alpha: 0.14)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.008),
    );
  }

  // Hairline fractures across the dark glass — drawn inside the panel clip.
  void _cracks(Canvas canvas, RRect panel) {
    final r = panel.outerRect;
    final c = r.center;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.width * 0.006
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF04080B).withValues(alpha: 0.6);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r.width * 0.30, c.dy - r.height * 0.36)
        ..lineTo(c.dx - r.width * 0.04, c.dy - r.height * 0.02)
        ..lineTo(c.dx - r.width * 0.14, c.dy + r.height * 0.18)
        ..lineTo(c.dx + r.width * 0.12, c.dy + r.height * 0.42),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + r.width * 0.32, c.dy - r.height * 0.12)
        ..lineTo(c.dx + r.width * 0.05, c.dy + r.height * 0.05),
      p..strokeWidth = r.width * 0.004,
    );
  }

  // The cold ghost of the khatam — the sacred form is still there, unlit and
  // drained of color. Reuses the emblem geometry at a whisper.
  void _coldGhost(Canvas canvas, Rect panel) {
    canvas.save();
    canvas.translate(panel.center.dx, panel.center.dy);
    final r = panel.shortestSide * 0.40;
    final layers = [_poly(r * 0.42, 8, math.pi / 8), _khatam(r * 0.86, r * 0.40)];
    for (final layer in layers) {
      canvas.drawPath(
        layer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.03
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF7C8A96).withValues(alpha: 0.10),
      );
    }
    canvas.restore();
  }

  // The khatam light inside the glass panel. The FULL geometric sequence is
  // always drawn — the streak never reveals it piece-by-piece. Only brightness
  // scales with `g` (glow), so the complete emblem goes dim → fully lit as the
  // streak grows. Centre seed removed (cleaner middle); a very faint
  // arched-arcade ring stands in for the old outer glow — sacred architecture
  // framing the star.
  void _khatamLight(Canvas canvas, Rect panel, double g) {
    canvas.save();
    canvas.translate(panel.center.dx, panel.center.dy);
    final r = panel.shortestSide * 0.40;

    // Faint architecture: a ring of pointed-arch niches framing the star.
    canvas.drawPath(
      _archRing(r * 1.12, 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.016
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _lightGold.withValues(alpha: 0.05 + 0.08 * g),
    );

    // The full emblem (no central seed): inner octagon + 8-point khatam star —
    // drawn complete at every stage; only the light level rises with the streak.
    final layers = [
      _poly(r * 0.42, 8, math.pi / 8),
      _khatam(r * 0.86, r * 0.40),
    ];
    for (final layer in layers) {
      if (g > 0.02) {
        canvas.drawPath(
          layer,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.05
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.plus
            ..color = _amber.withValues(alpha: (0.5 * g).clamp(0.0, 0.85))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.06),
        );
      }
      // Core line: present but subdued at a low streak, bright at a strong one.
      canvas.drawPath(
        layer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.03
          ..strokeCap = StrokeCap.round
          ..color =
              _lightGold.withValues(alpha: (0.34 + 0.56 * g).clamp(0.0, 0.95)),
      );
    }
    canvas.restore();
  }

  // A faint ring of pointed (keel) arches, apex pointing inward — reads as an
  // arcade of arched niches around the star.
  Path _archRing(double r, int count) {
    final p = Path();
    final seg = 2 * math.pi / count;
    for (var k = 0; k < count; k++) {
      final a = k * seg - math.pi / 2;
      final a1 = a - seg * 0.44;
      final a2 = a + seg * 0.44;
      final b1 = Offset(r * math.cos(a1), r * math.sin(a1));
      final b2 = Offset(r * math.cos(a2), r * math.sin(a2));
      final apexR = r * 0.74;
      final apex = Offset(apexR * math.cos(a), apexR * math.sin(a));
      final cR = r * 0.9;
      final c1 = Offset(cR * math.cos(a1), cR * math.sin(a1));
      final c2 = Offset(cR * math.cos(a2), cR * math.sin(a2));
      p
        ..moveTo(b1.dx, b1.dy)
        ..quadraticBezierTo(c1.dx, c1.dy, apex.dx, apex.dy)
        ..quadraticBezierTo(c2.dx, c2.dy, b2.dx, b2.dy);
    }
    return p;
  }

  Path _starPoly(double outer, double inner, int pts, double rot) {
    final p = Path();
    for (var i = 0; i < pts * 2; i++) {
      final rad = i.isEven ? outer : inner;
      final a = rot + i * math.pi / pts;
      final o = Offset(rad * math.cos(a), rad * math.sin(a));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  Path _poly(double radius, int sides, double rot) {
    final p = Path();
    for (var i = 0; i < sides; i++) {
      final a = rot + i * 2 * math.pi / sides;
      final o = Offset(radius * math.cos(a), radius * math.sin(a));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  Path _khatam(double outer, double inner) {
    final p = _starPoly(outer, inner, 8, math.pi / 8);
    for (final rot in [0.0, math.pi / 4]) {
      p.addPath(_poly(outer * 0.86, 4, rot + math.pi / 4), Offset.zero);
    }
    return p;
  }

  @override
  bool shouldRepaint(LanternPainter old) =>
      old.illumination != illumination ||
      old.glow != glow ||
      old.dormant != dormant ||
      old.protected != protected ||
      old.pulse != pulse ||
      old.wear != wear ||
      old.ambientShader != ambientShader ||
      old.ambient != ambient;
}
