// Draws a cosmetic backdrop — the scene behind the lantern on the Companion
// stage. Pure CustomPainter (code-drawn, ~0 KB). Layered for depth: sky gradient
// → stars → moon + halo → backlit skyline silhouette → warm horizon glow where
// the lantern sits → vignette. Deterministic (index-seeded, no RNG) so frames
// are stable; `pulse` (0→1 looped) can twinkle stars / drift the glow.
//
// PROTOTYPE (2026-07-25).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/backdrop.dart';

class BackdropPainter extends CustomPainter {
  BackdropPainter({required this.backdrop, this.pulse = 0.0});

  final Backdrop backdrop;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    switch (backdrop.theme) {
      case BackdropTheme.plain:
        _plain(canvas, size);
      case BackdropTheme.laylatNight:
        _laylatNight(canvas, size);
      case BackdropTheme.emeraldSanctuary:
        _emeraldSanctuary(canvas, size);
    }
  }

  // Small deterministic "random" in [0,1) from an index + salt.
  double _r(int i, double salt) {
    final v = math.sin((i + 1) * 12.9898 + salt * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  // ── Plain ─────────────────────────────────────────────────────────────────
  // The genuine "no backdrop": the app's warm cream surface with a soft warm
  // pool where the lantern stands. No scene — quiet, so it reads as "none".
  void _plain(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    // Warm cream base (light-mode canvas), a touch deeper toward the floor.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          const [Color(0xFFFBF7F2), Color(0xFFF3ECE1)],
        ),
    );
    // A soft warm pool under the lantern (no blend-plus needed on a light base).
    final glowC = Offset(w / 2, h * 0.66);
    canvas.drawCircle(
      glowC,
      w * 0.46,
      Paint()
        ..shader = ui.Gradient.radial(glowC, w * 0.46, [
          const Color(0xFFE9C88A).withValues(alpha: 0.16),
          const Color(0xFFE9C88A).withValues(alpha: 0.0),
        ]),
    );
    // Faint floor sheen so the lantern feels grounded, not floating.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.80), width: w * 0.5, height: h * 0.04),
      Paint()
        ..color = const Color(0xFFCBA76A).withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05),
    );
  }

  // ── Laylat Night ────────────────────────────────────────────────────────────
  void _laylatNight(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final phase = pulse * 2 * math.pi;
    final rect = Offset.zero & size;

    // 1. Sky: deep night → dusk → a warm horizon band → darker ground.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, 0),
          Offset(w / 2, h),
          const [
            Color(0xFF090E24), // deep night
            Color(0xFF141634),
            Color(0xFF272247),
            Color(0xFF4A2F4A), // dusk violet
            Color(0xFF824E3A), // warm horizon
            Color(0xFF3A2630), // ground
            Color(0xFF20161F),
          ],
          const [0.0, 0.34, 0.55, 0.70, 0.82, 0.90, 1.0],
        ),
    );

    // 2. Faint khatam wash high in the sky (5% — the design rule's decorative
    // accent), drifting almost imperceptibly.
    _skyPattern(canvas, size);

    // 3. Stars in the upper sky.
    final starTop = h * 0.62;
    for (var i = 0; i < 64; i++) {
      final x = _r(i, 1.3) * w;
      final y = _r(i, 2.7) * starTop;
      final base = 0.22 + 0.6 * _r(i, 3.9);
      final tw = 0.55 + 0.45 * math.sin(phase * 2 + i * 1.7);
      final rad = w * (0.0016 + 0.0026 * _r(i, 5.1));
      final a = (base * tw).clamp(0.0, 0.9);
      // A few larger stars get a soft cross-sparkle.
      if (_r(i, 6.3) > 0.86) {
        _starSparkle(canvas, Offset(x, y), rad * 4.2, a);
      } else {
        canvas.drawCircle(
          Offset(x, y),
          rad,
          Paint()..color = const Color(0xFFF3ECD8).withValues(alpha: a),
        );
      }
    }

    // 4. Crescent moon, upper area, with a broad soft halo.
    final moonC = Offset(w * 0.72, h * 0.185);
    final moonR = w * 0.10;
    canvas.drawCircle(
      moonC,
      moonR * 3.1,
      Paint()
        ..shader = ui.Gradient.radial(moonC, moonR * 3.1, [
          const Color(0xFFF4E8C6).withValues(alpha: 0.20),
          const Color(0xFFF4E8C6).withValues(alpha: 0.0),
        ])
        ..blendMode = BlendMode.plus,
    );
    _crescent(canvas, moonC, moonR);

    // 5. Backlit mosque skyline sitting on the warm horizon band.
    _skyline(canvas, size, h * 0.825);

    // 6. Warm ground-glow where the lantern will stand (centre, lower third).
    final glowC = Offset(w / 2, h * 0.72);
    canvas.drawCircle(
      glowC,
      w * (0.52 + 0.01 * math.sin(phase)),
      Paint()
        ..shader = ui.Gradient.radial(glowC, w * 0.52, [
          const Color(0xFFE7A24E).withValues(alpha: 0.26),
          const Color(0xFFE7A24E).withValues(alpha: 0.06),
          const Color(0xFFE7A24E).withValues(alpha: 0.0),
        ], const [0.0, 0.5, 1.0])
        ..blendMode = BlendMode.plus,
    );

    // 7. A faint reflective floor sheen under the lantern.
    final floorY = h * 0.80;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, floorY), width: w * 0.62, height: h * 0.05),
      Paint()
        ..color = const Color(0xFFE7A24E).withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04)
        ..blendMode = BlendMode.plus,
    );

    _vignette(canvas, size, 0.30);
  }

  // ── Emerald Sanctuary ────────────────────────────────────────────────────────
  void _emeraldSanctuary(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final phase = pulse * 2 * math.pi;
    final rect = Offset.zero & size;

    // Deep sacred-green radial wash, brightest around the niche centre.
    final centre = Offset(w / 2, h * 0.52);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF05201A));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(centre, h * 0.62, const [
          Color(0xFF0F4A34),
          Color(0xFF0A3324),
          Color(0xFF05201A),
        ], const [0.0, 0.55, 1.0]),
    );

    _skyPattern(canvas, size);

    // A large pointed mihrab arch framing the lantern, in faint gold.
    _mihrabArch(canvas, size);

    // Warm inner light where the lantern sits.
    final glowC = Offset(w / 2, h * 0.70);
    canvas.drawCircle(
      glowC,
      w * (0.5 + 0.01 * math.sin(phase)),
      Paint()
        ..shader = ui.Gradient.radial(glowC, w * 0.5, [
          const Color(0xFFE7C06A).withValues(alpha: 0.20),
          const Color(0xFFE7C06A).withValues(alpha: 0.0),
        ])
        ..blendMode = BlendMode.plus,
    );

    // Floor sheen.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.80), width: w * 0.6, height: h * 0.045),
      Paint()
        ..color = const Color(0xFFE7C06A).withValues(alpha: 0.10)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04)
        ..blendMode = BlendMode.plus,
    );

    _vignette(canvas, size, 0.42);
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  // A faint 8-point khatam lattice washed across the sky at ~5% opacity.
  void _skyPattern(Canvas canvas, Size size) {
    final w = size.width;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0016
      ..color = Colors.white.withValues(alpha: 0.04);
    final step = w * 0.16;
    for (var gx = 0.0; gx < size.width + step; gx += step) {
      for (var gy = 0.0; gy < size.height * 0.6; gy += step) {
        _miniStar(canvas, Offset(gx, gy), step * 0.36, p);
      }
    }
  }

  void _miniStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final rad = i.isEven ? r : r * 0.42;
      final a = i * math.pi / 8 - math.pi / 2;
      final o = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path..close(), p);
  }

  void _starSparkle(Canvas canvas, Offset o, double r, double a) {
    final p = Paint()
      ..color = const Color(0xFFFDF6E4).withValues(alpha: a)
      ..blendMode = BlendMode.plus;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 0.24, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 0.24, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
        ..close(),
      p,
    );
    canvas.drawCircle(o, r * 0.14, p);
  }

  void _crescent(Canvas canvas, Offset c, double r) {
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: c.translate(r * 0.46, -r * 0.20), radius: r * 0.90));
    final crescent = Path.combine(ui.PathOperation.difference, outer, inner);
    // Soft edge glow.
    canvas.drawPath(
      crescent,
      Paint()
        ..color = const Color(0xFFF6ECCC).withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.16)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = ui.Gradient.linear(
          c.translate(-r, -r),
          c.translate(r, r),
          const [Color(0xFFFBF3D8), Color(0xFFE9D3A0)],
        ),
    );
  }

  // A backlit silhouette of domes + minarets along the horizon.
  void _skyline(Canvas canvas, Size size, double baseY) {
    final w = size.width;
    const silhouette = Color(0xFF0B0A16);
    // Elements: (centreX fraction, kind, scale). kind: 0 dome cluster, 1 minaret,
    // 2 low building.
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.004
      ..color = const Color(0xFFC98A54).withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.003)
      ..blendMode = BlendMode.plus;
    final fill = Paint()..color = silhouette;

    // A soft dark base band grounding the city.
    canvas.drawRect(
      Rect.fromLTRB(0, baseY, w, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, baseY),
          Offset(0, size.height),
          [silhouette.withValues(alpha: 0.0), silhouette.withValues(alpha: 0.9)],
        ),
    );

    void dome(double cx, double r, {bool crescent = true}) {
      final path = Path()
        ..moveTo(cx - r, baseY)
        ..cubicTo(cx - r * 1.1, baseY - r * 0.7, cx - r * 0.5, baseY - r * 1.7,
            cx, baseY - r * 1.9)
        ..cubicTo(cx + r * 0.5, baseY - r * 1.7, cx + r * 1.1, baseY - r * 0.7,
            cx + r, baseY)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, rim);
      // spire + crescent
      canvas.drawLine(Offset(cx, baseY - r * 1.9),
          Offset(cx, baseY - r * 2.35), fill..strokeWidth = r * 0.12);
      if (crescent) {
        _tinyCrescent(canvas, Offset(cx, baseY - r * 2.5), r * 0.28, rim);
      }
    }

    void minaret(double cx, double bw, double hgt) {
      final r = Rect.fromLTRB(cx - bw / 2, baseY - hgt, cx + bw / 2, baseY);
      canvas.drawRect(r, fill..strokeWidth = 0);
      canvas.drawRect(r, rim);
      // little onion cap
      final cap = Path()
        ..moveTo(cx - bw * 0.7, baseY - hgt)
        ..cubicTo(cx - bw * 0.8, baseY - hgt - bw * 0.5, cx - bw * 0.35,
            baseY - hgt - bw * 1.2, cx, baseY - hgt - bw * 1.35)
        ..cubicTo(cx + bw * 0.35, baseY - hgt - bw * 1.2, cx + bw * 0.8,
            baseY - hgt - bw * 0.5, cx + bw * 0.7, baseY - hgt)
        ..close();
      canvas.drawPath(cap, fill);
      canvas.drawPath(cap, rim);
      _tinyCrescent(canvas, Offset(cx, baseY - hgt - bw * 1.7), bw * 0.34, rim);
    }

    void building(double cx, double bw, double hgt) {
      final r = Rect.fromLTRB(cx - bw / 2, baseY - hgt, cx + bw / 2, baseY);
      canvas.drawRect(r, fill);
      canvas.drawRect(r, rim);
    }

    // Layout across the horizon — a central mosque flanked by minarets + town.
    building(w * 0.08, w * 0.10, w * 0.09);
    minaret(w * 0.20, w * 0.028, w * 0.34);
    building(w * 0.30, w * 0.09, w * 0.12);
    dome(w * 0.40, w * 0.07, crescent: false);
    minaret(w * 0.335, w * 0.022, w * 0.30);
    // Central grand mosque.
    minaret(w * 0.365, w * 0.03, w * 0.42);
    dome(w * 0.5, w * 0.13);
    minaret(w * 0.635, w * 0.03, w * 0.42);
    dome(w * 0.60, w * 0.07, crescent: false);
    building(w * 0.70, w * 0.10, w * 0.11);
    minaret(w * 0.80, w * 0.028, w * 0.34);
    building(w * 0.91, w * 0.11, w * 0.08);
  }

  void _tinyCrescent(Canvas canvas, Offset c, double r, Paint rim) {
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: c.translate(r * 0.4, -r * 0.15), radius: r * 0.85));
    canvas.drawPath(
      Path.combine(ui.PathOperation.difference, outer, inner),
      Paint()..color = const Color(0xFFC98A54).withValues(alpha: 0.85),
    );
  }

  // A large pointed mihrab arch framing the centre (Emerald Sanctuary).
  void _mihrabArch(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final springY = h * 0.74; // where the arch legs meet the floor
    final apexY = h * 0.14;
    final half = w * 0.34;
    final arch = Path()
      ..moveTo(cx - half, springY)
      ..lineTo(cx - half, h * 0.40)
      ..quadraticBezierTo(cx - half, apexY + (springY - apexY) * 0.10, cx, apexY)
      ..quadraticBezierTo(
          cx + half, apexY + (springY - apexY) * 0.10, cx + half, h * 0.40)
      ..lineTo(cx + half, springY);
    // Outer soft gold aura.
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..color = const Color(0xFFC8985E).withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02),
    );
    // Crisp gold keel line.
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.006
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFD8AE6E).withValues(alpha: 0.55),
    );
    // A second inner arch line for depth.
    final inner = Path()
      ..moveTo(cx - half * 0.86, springY)
      ..lineTo(cx - half * 0.86, h * 0.42)
      ..quadraticBezierTo(
          cx - half * 0.86, apexY + (springY - apexY) * 0.16, cx, apexY + h * 0.05)
      ..quadraticBezierTo(cx + half * 0.86, apexY + (springY - apexY) * 0.16,
          cx + half * 0.86, h * 0.42)
      ..lineTo(cx + half * 0.86, springY);
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.003
        ..color = const Color(0xFFD8AE6E).withValues(alpha: 0.28),
    );
  }

  void _vignette(Canvas canvas, Size size, double strength) {
    final rect = Offset.zero & size;
    final c = Offset(size.width / 2, size.height * 0.52);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(c, size.height * 0.62, [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: strength),
        ], const [0.62, 1.0]),
    );
  }

  @override
  bool shouldRepaint(BackdropPainter old) =>
      old.backdrop != backdrop || old.pulse != pulse;
}
