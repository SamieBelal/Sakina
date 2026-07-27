// Draws the Desert Night backdrop — the scene behind the lantern on the
// Companion stage. Solitude and vastness: the Milky Way arcing over empty
// dunes, deliberately architecture-free so it reads as the counterpoint to
// Laylat Night's city. Pure code (paths + gradients + blurs, ~0 KB of assets).
//
// Layered back-to-front for depth:
//   sky gradient → faint khatam wash → horizon airglow → Milky Way haze →
//   band stars → dust rift → bright cores → ambient star field → low crescent
//   + halo → three receding dunes → moonlight spill → wind-carved crest +
//   sand ripples → ground sheen → vignette
//
// Everything is index-seeded (no RNG), so repaints are pixel-identical and the
// static layer raster-caches cleanly. Self-contained by design: the helpers are
// duplicated rather than shared with `backdrop_painter.dart` so each scene can
// be tuned without cross-scene regressions.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ── Public entry points ──────────────────────────────────────────────────────

/// Everything geometrically fixed. Painted once and raster-cached.
void paintDesertNightStatic(Canvas canvas, Size size) {
  final band = _milkyWayBand(size);

  _sky(canvas, size);
  _skyPattern(canvas, size);
  _airglow(canvas, size);

  // Milky Way, in three passes so the dust lane can occlude its own stars.
  _milkyWayHaze(canvas, band);
  _bandStars(canvas, size, band);
  _milkyWayRift(canvas, band);
  _milkyWayCores(canvas, band);

  _ambientStars(canvas, size);

  // Low crescent sitting just above the far ridge, plus the sky wash it throws.
  final moonC = Offset(size.width * 0.775, size.height * 0.500);
  final moonR = size.width * 0.055;
  _moonWash(canvas, size, moonC);
  _moonHalo(canvas, moonC, moonR);
  _crescent(canvas, moonC, moonR);

  _dunes(canvas, size, moonC);
  _groundSheen(canvas, size);
  _vignette(canvas, size, 0.36);
}

/// ONLY the pulse-driven pieces. [pulse] is 0..1, looping.
void paintDesertNightAnimated(Canvas canvas, Size size, double pulse) {
  _twinkle(canvas, size, pulse);
  _crestShimmer(canvas, size, pulse);
}

// ── Deterministic noise ──────────────────────────────────────────────────────

// Small deterministic "random" in [0,1) from an index + salt. Same trick the
// other scenes use — cheap, stable across repaints and across platforms.
double _r(int i, double salt) {
  final v = math.sin((i + 1) * 12.9898 + salt * 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

// Star colours: mostly neutral, with a scatter of hot-blue and warm-amber ones
// so the field doesn't read as a uniform sprinkle of white dots.
Color _starColour(int i) {
  final k = _r(i, 31.7);
  if (k > 0.87) return const Color(0xFFC3D6F7); // hot blue-white
  if (k > 0.73) return const Color(0xFFF7DCB0); // warm amber
  return const Color(0xFFF4F1E6); // neutral
}

// The sky ends here; nothing celestial is drawn below it (the far ridge crest
// tops out around 0.548h, so this leaves a hair of overlap).
double _skyFloor(Size size) => size.height * 0.540;

// ── Milky Way band geometry ──────────────────────────────────────────────────

/// An oriented strip: a centre point, a rotation, a length along the axis and a
/// half-width across it. `point(t, u)` maps band-local coordinates (t along
/// 0..1, u across -1..1) back into canvas space.
class _Band {
  const _Band(this.centre, this.angle, this.length, this.halfWidth);

  final Offset centre;
  final double angle;
  final double length;
  final double halfWidth;

  Offset point(double t, double u) {
    final lx = (t - 0.5) * length;
    final ly = u * halfWidth;
    final ca = math.cos(angle), sa = math.sin(angle);
    return Offset(
      centre.dx + lx * ca - ly * sa,
      centre.dy + lx * sa + ly * ca,
    );
  }
}

// A rising diagonal: it enters low on the left, crosses the centre high above
// where the lantern stands, and exits off the top-right corner. Both ends run
// past the canvas edge so the band never appears to "start" on screen.
_Band _milkyWayBand(Size size) {
  final w = size.width, h = size.height;
  final a = Offset(-0.20 * w, 0.60 * h);
  final b = Offset(1.20 * w, -0.04 * h);
  final d = b - a;
  return _Band(
    Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
    math.atan2(d.dy, d.dx),
    d.distance,
    w * 0.20,
  );
}

// Runs [body] with the canvas rotated into band-local space, where the band's
// axis is +x and "across the band" is +y — which makes every haze lump a plain
// axis-aligned oval.
void _inBandSpace(Canvas canvas, _Band band, void Function() body) {
  canvas.save();
  canvas.translate(band.centre.dx, band.centre.dy);
  canvas.rotate(band.angle);
  body();
  canvas.restore();
}

// ── Sky ──────────────────────────────────────────────────────────────────────

// Six stops: near-black indigo overhead, easing through deep blue into a
// slightly warmer, lifted band at the horizon where the dunes will sit.
void _sky(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        const [
          Color(0xFF02030C), // zenith — nearly black indigo
          Color(0xFF06091A),
          Color(0xFF0A1028),
          Color(0xFF122442),
          Color(0xFF203C51),
          Color(0xFF34505C), // horizon — warmed, desaturated
        ],
        const [0.0, 0.16, 0.34, 0.48, 0.57, 0.64],
      ),
  );
}

// A barely-there 8-point khatam lattice high in the sky (~3%). It reads as
// texture rather than pattern, and ties the scene back to the design system.
void _skyPattern(Canvas canvas, Size size) {
  final w = size.width;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0014
    ..color = Colors.white.withValues(alpha: 0.017);
  final step = w * 0.18;
  for (var gx = 0.0; gx < size.width + step; gx += step) {
    for (var gy = 0.0; gy < size.height * 0.42; gy += step) {
      _miniStar(canvas, Offset(gx, gy), step * 0.34, p);
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

// The faint teal airglow that sits on a real desert horizon — a wide, heavily
// blurred ellipse riding just above the far ridge. Cheap, and it does more for
// the sense of distance than another gradient stop would.
void _airglow(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.66, h * 0.568),
      width: w * 1.7,
      height: h * 0.10,
    ),
    Paint()
      ..color = const Color(0xFF6FA6B0).withValues(alpha: 0.075)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.10)
      ..blendMode = BlendMode.plus,
  );
}

// ── Milky Way ────────────────────────────────────────────────────────────────

// The luminous haze behind the band: one broad base wash plus eleven lumps of
// varying size so the glow is clumpy rather than a clean airbrushed streak.
// Both taper at the ends via sin(pi*t), so the band dissolves off-canvas.
void _milkyWayHaze(Canvas canvas, _Band band) {
  final hw = band.halfWidth;
  final len = band.length;

  _inBandSpace(canvas, band, () {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: len * 0.98,
        height: hw * 1.15,
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -hw * 0.58),
          Offset(0, hw * 0.58),
          [
            const Color(0xFF8FA8D8).withValues(alpha: 0.0),
            const Color(0xFFBFC8E8).withValues(alpha: 0.070),
            const Color(0xFFE6E2D6).withValues(alpha: 0.100),
            const Color(0xFFBFC8E8).withValues(alpha: 0.062),
            const Color(0xFF8FA8D8).withValues(alpha: 0.0),
          ],
          const [0.0, 0.30, 0.50, 0.70, 1.0],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.26)
        ..blendMode = BlendMode.plus,
    );

    // Lumps do most of the work — the base wash alone gives clean parallel
    // edges, which is exactly what makes a painted Milky Way look like a decal.
    for (var i = 0; i < 15; i++) {
      final t = (i + 0.5) / 15.0;
      final lx = (t - 0.5) * len * 0.94;
      final ly = (_r(i, 11.3) - 0.5) * hw * 0.52;
      final lw = len * (0.07 + 0.09 * _r(i, 12.7));
      final lh = hw * (0.26 + 0.46 * _r(i, 13.9));
      // Warmer lumps toward the galactic centre (mid-band), cooler at the ends.
      final warm = _r(i, 14.5) > 0.55;
      final a = (0.050 + 0.075 * _r(i, 15.1)) * math.sin(math.pi * t);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lx, ly), width: lw, height: lh),
        Paint()
          ..color = (warm ? const Color(0xFFF0DFC2) : const Color(0xFFCBD6F2))
              .withValues(alpha: a)
          // Sigma is capped rather than proportional: the widest lumps would
          // otherwise cost far more to raster than they add visually.
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, math.min(lh * 0.55, hw * 0.30))
          ..blendMode = BlendMode.plus,
      );
    }
  });
}

// The Great Rift: the dark dust lane that splits the band lengthwise. Painted
// AFTER the band stars so it genuinely occludes them — that occlusion is what
// stops the band reading as a flat sticker.
void _milkyWayRift(Canvas canvas, _Band band) {
  final hw = band.halfWidth;
  final len = band.length;

  _inBandSpace(canvas, band, () {
    for (var i = 0; i < 9; i++) {
      final t = (i + 0.5) / 9.0;
      final rx = (t - 0.5) * len * 0.92;
      // The lane weaves slowly across the axis rather than jumping side to
      // side, so the nine blobs join into one continuous ribbon of dust.
      final ry = hw * (0.30 * math.sin(t * 5.4 + 0.8) + 0.10 * _r(i, 21.5));
      final rw = len * (0.15 + 0.08 * _r(i, 22.9));
      final rh = hw * (0.13 + 0.11 * _r(i, 24.1));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: rw, height: rh),
        Paint()
          ..color = const Color(0xFF05081A)
              .withValues(alpha: 0.66 * math.sin(math.pi * t))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, rh * 0.62),
      );
    }
  });
}

// Three bright cores punched through the rift, so the band has hot spots the
// eye can land on. Drawn last of the band layers.
void _milkyWayCores(Canvas canvas, _Band band) {
  final hw = band.halfWidth;
  final len = band.length;
  const ts = [0.30, 0.54, 0.76];
  const alphas = [0.085, 0.115, 0.070];

  _inBandSpace(canvas, band, () {
    for (var i = 0; i < ts.length; i++) {
      final cx = (ts[i] - 0.5) * len;
      final cy = hw * (0.06 - 0.14 * _r(i, 26.3));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: len * 0.13,
          height: hw * 0.42,
        ),
        Paint()
          ..color = const Color(0xFFF6EFDD).withValues(alpha: alphas[i])
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, hw * 0.22)
          ..blendMode = BlendMode.plus,
      );
    }
  });
}

// 260 stars distributed in band-local coordinates. `u` is cubed so density
// piles up on the axis — that concentration, not the count, is what makes the
// band read as denser than the ambient field.
void _bandStars(Canvas canvas, Size size, _Band band) {
  final w = size.width;
  final floor = _skyFloor(size);

  for (var i = 0; i < 420; i++) {
    final t = _r(i, 1.1);
    final raw = _r(i, 2.3) * 2 - 1;
    final u = raw * raw * raw; // cubic bias toward the axis
    final o = band.point(t, u);
    if (o.dy > floor || o.dx < -w * 0.02 || o.dx > w * 1.02) continue;

    final s = _r(i, 3.7);
    final rad = w * (0.0009 + 0.0024 * s * s);
    final a = (0.32 + 0.58 * _r(i, 4.9)) * (1.0 - 0.45 * u.abs());
    canvas.drawCircle(
      o,
      rad,
      Paint()
        ..color = _starColour(i).withValues(alpha: a.clamp(0.0, 0.95))
        ..blendMode = BlendMode.plus,
    );
  }
}

// The scattered field everywhere else. Alpha falls off cubically toward the
// horizon to fake atmospheric extinction — stars near the ground are dimmer,
// which is a large part of why a night sky reads as deep.
void _ambientStars(Canvas canvas, Size size) {
  final w = size.width;
  final floor = _skyFloor(size);

  for (var i = 0; i < 160; i++) {
    final x = _r(i, 51.3) * w;
    final y = _r(i, 52.7) * floor;
    final k = y / floor;
    final ext = 1.0 - 0.72 * k * k * k;
    final s = _r(i, 53.9);
    final rad = w * (0.0007 + 0.0017 * s * s);
    final a = (0.12 + 0.36 * _r(i, 55.1)) * ext;
    canvas.drawCircle(
      Offset(x, y),
      rad,
      Paint()..color = _starColour(i + 900).withValues(alpha: a),
    );
  }
}

// ── Moon ─────────────────────────────────────────────────────────────────────

// The broad, low wash a horizon moon throws across the sky around it. Wider
// and far fainter than the halo, so the two don't read as one hard disc.
void _moonWash(Canvas canvas, Size size, Offset c) {
  final w = size.width;
  final r = w * 0.85;
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = ui.Gradient.radial(c, r, [
        const Color(0xFFBFD2E8).withValues(alpha: 0.10),
        const Color(0xFFBFD2E8).withValues(alpha: 0.03),
        const Color(0xFFBFD2E8).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.42,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );
}

void _moonHalo(Canvas canvas, Offset c, double r) {
  canvas.drawCircle(
    c,
    r * 4.2,
    Paint()
      ..shader = ui.Gradient.radial(c, r * 4.2, [
        const Color(0xFFF2EAD2).withValues(alpha: 0.22),
        const Color(0xFFF2EAD2).withValues(alpha: 0.0),
      ])
      ..blendMode = BlendMode.plus,
  );
}

// A waning crescent, opening away from the band so the two hero elements read
// as separate. Soft blurred pass first, crisp gradient body on top.
void _crescent(Canvas canvas, Offset c, double r) {
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(Rect.fromCircle(
        center: c.translate(-r * 0.44, -r * 0.22), radius: r * 0.92));
  final crescent = Path.combine(ui.PathOperation.difference, outer, inner);

  canvas.drawPath(
    crescent,
    Paint()
      ..color = const Color(0xFFF6ECCC).withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18)
      ..blendMode = BlendMode.plus,
  );
  canvas.drawPath(
    crescent,
    Paint()
      ..shader = ui.Gradient.linear(
        c.translate(r, -r),
        c.translate(-r, r),
        const [Color(0xFFFCF5DE), Color(0xFFE4D2A6)],
      ),
  );
}

// ── Dunes ────────────────────────────────────────────────────────────────────

// Three overlapping ridges. Each crest is an open path; `_duneFill` closes it
// down to the bottom edge so the nearer ridge always covers the farther one.
// Value separation does the receding: far ridge hazy and lifted, near ridge
// nearly black.

Path _farCrest(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(-0.06 * w, 0.602 * h)
    ..cubicTo(0.13 * w, 0.562 * h, 0.25 * w, 0.548 * h, 0.41 * w, 0.567 * h)
    ..cubicTo(0.55 * w, 0.584 * h, 0.65 * w, 0.549 * h, 0.80 * w, 0.557 * h)
    ..cubicTo(0.92 * w, 0.563 * h, 0.99 * w, 0.589 * h, 1.06 * w, 0.598 * h);
}

Path _midCrest(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(-0.06 * w, 0.660 * h)
    ..cubicTo(0.10 * w, 0.618 * h, 0.30 * w, 0.601 * h, 0.46 * w, 0.627 * h)
    ..cubicTo(0.62 * w, 0.653 * h, 0.74 * w, 0.679 * h, 0.88 * w, 0.641 * h)
    ..cubicTo(0.96 * w, 0.619 * h, 1.01 * w, 0.630 * h, 1.06 * w, 0.639 * h);
}

Path _nearCrest(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(-0.06 * w, 0.788 * h)
    ..cubicTo(0.12 * w, 0.746 * h, 0.25 * w, 0.708 * h, 0.43 * w, 0.704 * h)
    ..cubicTo(0.60 * w, 0.700 * h, 0.70 * w, 0.719 * h, 0.84 * w, 0.695 * h)
    ..cubicTo(0.93 * w, 0.680 * h, 0.99 * w, 0.701 * h, 1.06 * w, 0.716 * h);
}

Path _duneFill(Path crest, Size s) => Path.from(crest)
  ..lineTo(s.width * 1.06, s.height * 1.02)
  ..lineTo(-s.width * 0.06, s.height * 1.02)
  ..close();

void _dunes(Canvas canvas, Size size, Offset moonC) {
  final w = size.width, h = size.height;

  final far = _farCrest(size);
  final mid = _midCrest(size);
  final near = _nearCrest(size);
  final nearFill = _duneFill(near, size);

  // Far ridge — hazy, lifted, almost the colour of the sky above it.
  canvas.drawPath(
    _duneFill(far, size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.545),
        Offset(0, h * 0.70),
        const [Color(0xFF2A3D54), Color(0xFF1B2942)],
      ),
  );
  _crestRim(canvas, size, far, const Color(0xFF9FBAD4), 0.16);

  // Mid ridge.
  canvas.drawPath(
    _duneFill(mid, size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.598),
        Offset(0, h * 0.80),
        const [Color(0xFF16203A), Color(0xFF0D1428)],
      ),
  );
  _crestRim(canvas, size, mid, const Color(0xFF8FA8C6), 0.13);

  // Near ridge — darkest, so the lantern reads as standing in front of it.
  canvas.drawPath(
    nearFill,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.690),
        Offset(0, h),
        const [Color(0xFF0A0E1E), Color(0xFF05060F)],
      ),
  );

  // Moonlight spilling down the near dune's right flank, clipped to the dune.
  canvas.save();
  canvas.clipPath(nearFill);
  final spillC = Offset(moonC.dx + w * 0.02, h * 0.72);
  canvas.drawCircle(
    spillC,
    w * 0.62,
    Paint()
      ..shader = ui.Gradient.radial(spillC, w * 0.62, [
        const Color(0xFFA8C0DC).withValues(alpha: 0.085),
        const Color(0xFFA8C0DC).withValues(alpha: 0.0),
      ])
      ..blendMode = BlendMode.plus,
  );
  canvas.restore();

  // The wind-carved crest: a soft bloom plus a crisp hairline along the top of
  // the near dune. This is the edge that reads as "sand", not "hill".
  canvas.drawPath(
    near,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.010
      ..color = const Color(0xFFBDD0E6).withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012)
      ..blendMode = BlendMode.plus,
  );
  canvas.drawPath(
    near,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0026
      ..color = const Color(0xFFD8E4F2).withValues(alpha: 0.20)
      ..blendMode = BlendMode.plus,
  );

  // One long secondary slipface line giving the near dune internal form, and
  // wind ripples confined to the outer thirds (the centre stays calm).
  canvas.save();
  canvas.clipPath(nearFill);
  canvas.drawPath(
    Path()
      ..moveTo(-0.04 * w, 0.860 * h)
      ..cubicTo(0.26 * w, 0.806 * h, 0.58 * w, 0.772 * h, 1.04 * w, 0.792 * h),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0030
      ..color = const Color(0xFFA6BCD8).withValues(alpha: 0.065)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.003)
      ..blendMode = BlendMode.plus,
  );
  canvas.restore();

  // Deliberately no fourth "foreground shoulder" plane down here. Every version
  // of it cut a hard diagonal across the bottom corners — at this value range a
  // near-black silhouette against the moonlit near dune reads as a crop, not as
  // ground. The ripples and the slipface line carry the lower frame instead.
  _sandRipples(canvas, size, nearFill);
}

// A blurred pale stroke riding a crest — the moonlit rim that separates one
// ridge from the next.
void _crestRim(
    Canvas canvas, Size size, Path crest, Color colour, double alpha) {
  final w = size.width;
  canvas.drawPath(
    crest,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0055
      ..color = colour.withValues(alpha: alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.005)
      ..blendMode = BlendMode.plus,
  );
}

// Shallow wind ripples across the near dune's face. Deliberately split into a
// left group and a right group with a gap through x ∈ [0.38, 0.62] so nothing
// busy sits directly behind the lantern.
void _sandRipples(Canvas canvas, Size size, Path nearFill) {
  final w = size.width, h = size.height;
  canvas.save();
  canvas.clipPath(nearFill);
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0022
    ..blendMode = BlendMode.plus;

  for (var i = 0; i < 14; i++) {
    final left = i.isEven;
    final row = i ~/ 2;
    final y = h * (0.740 + 0.031 * row + 0.016 * _r(i, 41.3));
    final x0 = left ? -0.05 * w : 0.62 * w;
    final x1 = left ? 0.38 * w : 1.05 * w;
    final sag = h * (0.004 + 0.014 * _r(i, 43.9)) * (left ? 1 : -0.6);
    // Each ripple also runs downhill, and by a different amount — perfectly
    // horizontal strokes at even spacing read as scan lines, not as sand.
    final tilt = h * (0.005 + 0.014 * _r(i, 47.3)) * (left ? -1 : 1);
    p
      ..color =
          const Color(0xFFAFC4E0).withValues(alpha: 0.030 + 0.034 * _r(i, 45.1))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.0022);
    canvas.drawPath(
      Path()
        ..moveTo(x0, y)
        ..quadraticBezierTo((x0 + x1) / 2, y - sag + tilt * 0.5, x1, y + tilt),
      p,
    );
  }
  canvas.restore();
}

// ── Ground + vignette ────────────────────────────────────────────────────────

// A cool sheen on the sand where the lantern will stand. Kept cool and quiet —
// the lantern brings its own warmth, and the backdrop must not compete.
void _groundSheen(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final c = Offset(w / 2, h * 0.782);
  canvas.drawOval(
    Rect.fromCenter(center: c, width: w * 0.62, height: h * 0.045),
    Paint()
      ..color = const Color(0xFFA9BFD8).withValues(alpha: 0.17)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.042)
      ..blendMode = BlendMode.plus,
  );
}

void _vignette(Canvas canvas, Size size, double strength) {
  final c = Offset(size.width / 2, size.height * 0.52);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.radial(c, size.height * 0.62, [
        Colors.black.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: strength),
      ], const [
        0.60,
        1.0
      ]),
  );
}

// ── Animated layer ───────────────────────────────────────────────────────────

// 48 brighter stars whose alpha rides math.sin. The dense field underneath is
// static, so this layer only has to carry the *life* of the sky, not its
// texture — which keeps the per-frame cost to a few dozen circles.
void _twinkle(Canvas canvas, Size size, double pulse) {
  final w = size.width;
  final floor = _skyFloor(size);
  final band = _milkyWayBand(size);
  final phase = pulse * 2 * math.pi;

  for (var i = 0; i < 48; i++) {
    // The first 18 ride the Milky Way so the band itself shimmers; the rest
    // scatter across the whole sky.
    final Offset o;
    if (i < 18) {
      final raw = _r(i, 62.1) * 2 - 1;
      o = band.point(_r(i, 61.3), raw * raw * raw);
    } else {
      o = Offset(_r(i, 63.7) * w, _r(i, 64.9) * floor);
    }
    if (o.dy > floor || o.dx < 0 || o.dx > w) continue;

    final base = 0.26 + 0.52 * _r(i, 65.1);
    final tw = 0.55 + 0.45 * math.sin(phase * 2 + i * 1.7);
    final rad = w * (0.0014 + 0.0024 * _r(i, 66.3));
    final a = (base * tw).clamp(0.0, 0.92);

    // The brightest few get a soft cross-sparkle instead of a plain disc.
    if (_r(i, 67.5) > 0.84) {
      _starSparkle(canvas, o, rad * 4.4, a);
    } else {
      canvas.drawCircle(
        o,
        rad,
        Paint()
          ..color = _starColour(i + 400).withValues(alpha: a)
          ..blendMode = BlendMode.plus,
      );
    }
  }
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

// A single glint travelling along the near dune's crest — one stroke, one
// gradient whose bright window slides with the pulse. The `p` range is chosen
// so every stop stays strictly increasing at both ends of the loop.
void _crestShimmer(Canvas canvas, Size size, double pulse) {
  final w = size.width;
  final p = 0.16 + 0.68 * pulse;
  const glint = Color(0xFFE2ECF8);
  const clear = Color(0x00E2ECF8);

  canvas.drawPath(
    _nearCrest(size),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0055
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.006)
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [clear, clear, glint.withValues(alpha: 0.30), clear, clear],
        [0.0, p - 0.12, p, p + 0.12, 1.0],
      ),
  );
}
