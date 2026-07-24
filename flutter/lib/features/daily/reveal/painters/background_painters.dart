// lib/features/daily/reveal/painters/background_painters.dart
//
// The full-screen atmosphere + FX layers behind the reveal card: darken/pool
// vignette, lantern god-rays, aurora fan, burst (flash + shafts + rings), sparks,
// halo ring, and floating rest motes. All are widget-free CustomPainters driven
// by explicit color/intensity params (no reach into State), and share the
// ray-fan idiom + particle field from reveal_geometry.dart.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sakina/features/daily/reveal/reveal_geometry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Atmosphere — darken + a warm emerald pool the card rests in + focus vignette.
// ─────────────────────────────────────────────────────────────────────────────

class AtmospherePainter extends CustomPainter {
  AtmospherePainter({
    required this.darken,
    required this.pool,
    required this.breath,
    required this.color,
  });
  final double darken; // 0→1
  final double pool; // 0→1 tier-coloured glow behind the card
  final double breath;
  final Color color; // tier signature colour for the pool

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = Offset(size.width / 2, size.height / 2);

    canvas.drawRect(
      rect,
      Paint()..color = Color.lerp(revealCanvas, Colors.black, darken * 0.72)!,
    );

    if (pool > 0.01) {
      final r = size.shortestSide * (0.62 + 0.03 * breath);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.16 * pool),
              color.withValues(alpha: 0.05 * pool),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    if (darken > 0.01) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.5 * darken),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(
              Rect.fromCircle(center: c, radius: size.longestSide * 0.72)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant AtmospherePainter old) =>
      old.darken != darken || old.pool != pool || old.breath != breath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Halo — a slow, faint emerald/gold ring behind the settled card (emerald flex).
// ─────────────────────────────────────────────────────────────────────────────

class HaloPainter extends CustomPainter {
  HaloPainter(
      {required this.rotation, required this.opacity, required this.bright});
  final double rotation;
  final double opacity;
  final Color bright;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.46;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = bright.withValues(alpha: 0.22 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      c,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = goldBright.withValues(alpha: 0.12 * opacity),
    );
    // A ring of ticks turning slowly around the card.
    const ticks = 16;
    final tick = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = goldBright.withValues(alpha: 0.28 * opacity)
      ..blendMode = BlendMode.plus;
    for (var i = 0; i < ticks; i++) {
      final a = i * 2 * math.pi / ticks + rotation * 0.3;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 1.02, c + dir * r * 1.06, tick);
    }
  }

  @override
  bool shouldRepaint(covariant HaloPainter old) =>
      old.rotation != rotation || old.opacity != opacity;
}

// ─────────────────────────────────────────────────────────────────────────────
// Motes — floating embers/kirakira around the rested card (persistent life).
// ─────────────────────────────────────────────────────────────────────────────

class MotePainter extends CustomPainter {
  MotePainter(
      {required this.motes,
      required this.phase,
      required this.opacity,
      required this.bright});
  final List<Mote> motes;
  final double phase;
  final double opacity;
  final Color bright; // tier accent (alternated with the warm gold accent)

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final spread = size.shortestSide * 0.5;

    for (final m in motes) {
      final rise = (phase * m.speed + m.seed) % 1.0; // 0→1 slow drift up
      final twinkle = 0.5 + 0.5 * math.sin(phase * 2 * math.pi * 2 + m.seed * 6);
      final x = c.dx + m.x * spread + math.sin(phase * 6 + m.seed * 6) * 6;
      final y = c.dy + m.y * spread - rise * size.shortestSide * 0.25;
      final a = opacity * (0.25 + 0.6 * twinkle) * (1 - rise * 0.6);
      canvas.drawCircle(
        Offset(x, y),
        m.size * (0.7 + 0.5 * twinkle),
        Paint()
          ..color = (m.seed > 0.5 ? goldBright : bright)
              .withValues(alpha: a.clamp(0.0, 0.7))
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MotePainter old) =>
      old.phase != phase || old.opacity != opacity;
}

// ─────────────────────────────────────────────────────────────────────────────
// Lantern god-rays — soft tier-coloured wedges that GROW out of the lantern
// during the extended ignite, then fade as the burst hits.
// ─────────────────────────────────────────────────────────────────────────────

class LanternRaysPainter extends CustomPainter {
  LanternRaysPainter({
    required this.grow,
    required this.fade,
    required this.rotation,
    required this.color,
    required this.rayCount,
  });
  final double grow;
  final double fade;
  final double rotation;
  final Color color;
  final int rayCount; // spec-driven: Emerald 16, lower tiers fewer

  @override
  void paint(Canvas canvas, Size size) {
    final vis = grow * fade;
    if (vis <= 0.01) return;
    final c = Offset(size.width / 2, size.height / 2);
    final maxLen = size.longestSide * 0.5;
    final reach = Curves.easeOutCubic.transform(grow);

    paintRayFan(
      canvas,
      c,
      rays: rayCount,
      baseRotation: rotation,
      lenFor: (i) => maxLen * (i.isEven ? 0.95 : 0.62) * reach,
      halfWidthFor: (i) => size.shortestSide * (i.isEven ? 0.05 : 0.035),
      shaderFor: (i, halfW, len) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28 * vis),
          color.withValues(alpha: 0.10 * vis),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(-halfW, 0, halfW * 2, len)),
      maskFor: (i, halfW) => MaskFilter.blur(BlurStyle.normal, halfW * 0.7),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.drawCircle(
      Offset.zero,
      size.shortestSide * 0.22 * reach,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.30 * vis),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
              center: Offset.zero, radius: size.shortestSide * 0.22 * reach),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LanternRaysPainter old) =>
      old.grow != grow ||
      old.fade != fade ||
      old.rotation != rotation ||
      old.rayCount != rayCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Aurora rays — a rotating radial fan of emerald/gold light behind the card.
// ─────────────────────────────────────────────────────────────────────────────

class AuroraPainter extends CustomPainter {
  AuroraPainter(
      {required this.rotation, required this.opacity, required this.bright});
  final double rotation;
  final double opacity;
  final Color bright; // tier accent, alternated with the warm gold accent

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final len = size.longestSide;

    paintRayFan(
      canvas,
      c,
      rays: 12,
      baseRotation: rotation,
      lenFor: (i) => len,
      halfWidthFor: (i) => len * 0.06,
      shaderFor: (i, halfW, rayLen) {
        final color = i.isEven ? bright : goldBright;
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.10 * opacity),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(-halfW, 0, halfW * 2, rayLen));
      },
    );
  }

  @override
  bool shouldRepaint(covariant AuroraPainter old) =>
      old.rotation != rotation || old.opacity != opacity;
}

// ─────────────────────────────────────────────────────────────────────────────
// Burst — central flash + hard radial shafts (percussive) + expanding rings.
// ─────────────────────────────────────────────────────────────────────────────

class BurstPainter extends CustomPainter {
  BurstPainter({
    required this.rings,
    required this.flash,
    required this.shafts,
    required this.rotation,
    required this.color,
    required this.glow,
    required this.shaftCount,
  });
  final double rings;
  final double flash;
  final double shafts; // 0→1→0 sharp light shafts at the impact
  final double rotation;
  final Color color; // tier accent (flash + shafts)
  final Color glow; // tier additive glow accent (rings)
  final int shaftCount; // spec-driven: Emerald 20, lower tiers fewer

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.longestSide * 0.6;

    if (flash > 0) {
      final r = maxR * (0.1 + flash * 0.6);
      final paint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9 * flash),
            color.withValues(alpha: 0.4 * flash),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    // Hard, thin light-shafts snapping out at the impact — the "crack".
    if (shafts > 0.01) {
      final len = maxR * (0.4 + 0.7 * shafts);
      paintRayFan(
        canvas,
        c,
        rays: shaftCount,
        baseRotation: rotation * 0.5,
        lenFor: (i) => len,
        halfWidthFor: (i) => size.shortestSide * (i.isEven ? 0.012 : 0.006),
        shaderFor: (i, w, rayLen) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55 * shafts),
            color.withValues(alpha: 0.25 * shafts),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromLTWH(-w, 0, w * 2, rayLen)),
      );
    }

    if (rings > 0 && rings < 1) {
      for (final delay in [0.0, 0.18, 0.36]) {
        final p = (rings - delay).clamp(0.0, 1.0);
        if (p <= 0) continue;
        final radius = maxR * p;
        final alpha = (1 - p) * 0.6;
        canvas.drawCircle(
          c,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 * (1 - p) + 0.5
            ..color = glow.withValues(alpha: alpha)
            ..blendMode = BlendMode.plus,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BurstPainter old) =>
      old.rings != rings ||
      old.flash != flash ||
      old.shafts != shafts ||
      old.rotation != rotation ||
      old.shaftCount != shaftCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparks — small motes flung radially outward with a motion trail, fading out.
// ─────────────────────────────────────────────────────────────────────────────

class SparkPainter extends CustomPainter {
  SparkPainter(
      {required this.sparks, required this.progress, required this.bright});
  final List<Spark> sparks;
  final double progress;
  final Color bright; // tier accent (alternated with the warm gold accent)

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final c = Offset(size.width / 2, size.height / 2);
    final half = size.longestSide * 0.5;

    for (final s in sparks) {
      final p = (progress * s.speed).clamp(0.0, 1.0);
      final dir = Offset(math.cos(s.angle), math.sin(s.angle));
      final dist = half * s.distance * Curves.easeOut.transform(p);
      final pos = c + dir * dist;
      final alpha = (1 - p) * 0.9;
      final color =
          (s.size > 3 ? goldBright : bright).withValues(alpha: alpha);

      // Motion trail — a short streak behind the head, longer while fast.
      final trail = dir * (12 + 26 * (1 - p)) * s.size * 0.25;
      canvas.drawLine(
        pos - trail,
        pos,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..strokeWidth = s.size * 0.6 * (1 - p * 0.4)
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
      );
      canvas.drawCircle(
        pos,
        s.size * (1 - p * 0.5),
        Paint()
          ..color = color
          ..blendMode = BlendMode.plus
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter old) => old.progress != progress;
}
