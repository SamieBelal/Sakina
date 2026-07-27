// Emerald Mihrab — the prayer-hall INTERIOR backdrop for the Companion stage.
//
// This scene exists to be an *interior* alongside the exterior/night scenes:
// you are standing inside a generic, reverent prayer hall looking down a
// three-bay arcade toward a warm, lit niche. The lantern stands centre-lower,
// directly in front of that niche, so it reads as backlit.
//
// Depth planes, far → near (this is also the paint order):
//   1. atmosphere      — vertical emerald gradient, ceiling shadow → floor
//   2. carpet plane    — perspective prayer-rug grid receding to the horizon
//   3. niche (arch 3)  — back wall + radiating semi-dome ribs + warm pool
//   4. bay 2 (arch 2)  — dark cool soffit ring with vault ribs
//   5. bay 1 (arch 1)  — mid ring, muqarnas honeycomb in the arch head, piers
//   6. near wall       — girih wash, dado, pilasters, spandrel roundels
//   7. hanging lamps   — two silhouetted Mamluk-style lamps on chains
//   8. vignette
//
// Everything is code-drawn (paths / gradients / blurs — no assets) and fully
// deterministic: geometry is derived from a single vanishing point plus a
// per-bay perspective scale, with no RNG anywhere, so repaints are identical.
//
// Architecture and geometry only — no figurative imagery, and deliberately not
// modelled on any specific real mosque.
//
// The file is intentionally self-contained (helpers duplicated rather than
// shared) so sibling backdrop scenes can be authored in parallel.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ── Scene geometry ───────────────────────────────────────────────────────────
// One vanishing point at eye level; every bay is the same arch scaled by its
// depth factor. Because half-width, apex rise, springline rise and base drop
// all scale together, the three arches genuinely converge instead of merely
// being "three arcs of different sizes".

/// Eye level / vanishing point, as a fraction of height.
const double _kHorizonY = 0.660;

/// Near-bay arch half-width, as a fraction of width.
const double _kArchHalf = 0.360;

/// Near-bay apex / springline height above the horizon (fraction of height).
const double _kApexRise = 0.600;
const double _kSpringRise = 0.360;

/// Near-bay floor line below the horizon (fraction of height).
const double _kBaseDrop = 0.300;

/// Perspective scale of the middle and far bays.
const double _kScale2 = 0.70;
const double _kScale3 = 0.49;

/// Where the far wall meets the carpet — the deepest visible floor line.
const double _kFloorTopY = 0.715;

/// Centre of the warm pool inside the niche (what backlights the lantern).
const double _kNicheGlowY = 0.615;

/// Hanging-lamp placement: horizontal inset from centre, body centre height.
const double _kLampX = 0.322;
const double _kLampY = 0.400;

/// The horizontal unit every piece of the architecture is measured in.
///
/// Vertical geometry is a fraction of height, so on a wide, short canvas a
/// width-based arch would stretch until its point flattened into a tunnel
/// mouth. Capping the unit against the height keeps the arcade's proportions —
/// the hall simply sits in a wider room. In portrait this is exactly `width`,
/// so the tuned portrait composition is untouched.
double _unit(double w, double h) => math.min(w, h * 0.62);

/// Centre x of the [i]-th hanging lamp (0 = left, 1 = right).
double _lampX(double w, double h, int i) =>
    w / 2 + (i == 0 ? -1 : 1) * _unit(w, h) * _kLampX;

// ── Palette ──────────────────────────────────────────────────────────────────
// Deep sacred emeralds for the architecture, warm matte gold for light and for
// the decorative accents (the design system's gold, used as accent only).

const Color _kWallDark = Color(0xFF042017);
const Color _kWallMid = Color(0xFF0A3526);
const Color _kBay1 = Color(0xFF042317);
const Color _kBay2 = Color(0xFF021610); // cooler + darker as it recedes
const Color _kNicheWall = Color(0xFF05261A);
const Color _kGold = Color(0xFFC8985E);
const Color _kGoldLit = Color(0xFFE7C88A);
const Color _kNicheLight = Color(0xFFF0AE50); // warm candle-gold, not lime
const Color _kNicheCore = Color(0xFFFFE6B4);
const Color _kSilhouette = Color(0xFF010805);

// ── Public entry points ──────────────────────────────────────────────────────

/// Everything geometrically fixed. Painted once and raster-cached.
void paintEmeraldMihrabStatic(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final rect = Offset.zero & size;

  // 1. Atmosphere — the hall's ambient light falls off toward the ceiling and
  //    toward the viewer's feet, and lifts around the niche.
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        const [
          Color(0xFF020D09), // ceiling shadow
          Color(0xFF04211A),
          Color(0xFF072E22),
          Color(0xFF083425), // ambient band at eye level
          Color(0xFF03180F),
          Color(0xFF010806), // floor, nearest the viewer
        ],
        const [0.0, 0.20, 0.42, 0.62, 0.82, 1.0],
      ),
  );

  // The three bay openings. `_arch` is the visible opening; `_shaft` is the
  // same opening with its base dropped to the canvas floor, which is what we
  // subtract so a nearer ring never paints over the carpet behind it.
  final a1 = _arch(w, h, 1.0);
  final a2 = _arch(w, h, _kScale2);
  final a3 = _arch(w, h, _kScale3);
  final shaft2 = _arch(w, h, _kScale2, baseOverride: h);
  final shaft3 = _arch(w, h, _kScale3, baseOverride: h);

  // 2. Carpet plane, drawn before the architecture so every arch stands on it.
  _carpet(canvas, size);

  // 3. Far bay: the niche itself. Its back wall stops short of the arch base so
  //    a sliver of carpet stays visible inside the recess — cheap real depth.
  canvas.save();
  canvas.clipPath(a3);
  canvas.clipRect(Rect.fromLTRB(0, 0, w, h * 0.745));
  _niche(canvas, size);
  canvas.restore();

  // 4. Middle bay ring — darkest and coolest, with vault ribs across the soffit.
  canvas.save();
  canvas.clipPath(Path.combine(ui.PathOperation.difference, a2, shaft3));
  _bayFill(canvas, size, _kBay2, const Color(0xFF010B08));
  _vaultRibs(canvas, size, _kScale2, 7);
  canvas.restore();

  // 5. Near bay ring — the muqarnas head and the piers live here.
  canvas.save();
  canvas.clipPath(Path.combine(ui.PathOperation.difference, a1, shaft2));
  _bayFill(canvas, size, _kBay1, const Color(0xFF02120C));
  _vaultRibs(canvas, size, 1.0, 3); // recessed orders on the front reveal
  _muqarnas(canvas, size);
  _piers(canvas, size);
  canvas.restore();

  // 6. Near wall — everything outside the front arch, minus the two floor
  //    wedges where the side walls recede past the viewer.
  final shaft1 = _arch(w, h, 1.0, baseOverride: h * 1.02);
  final legX = w / 2 - _unit(w, h) * _kArchHalf;
  final legY = h * _kHorizonY + h * _kBaseDrop;
  var wall = Path.combine(
    ui.PathOperation.difference,
    Path()..addRect(rect),
    shaft1,
  );
  wall = Path.combine(ui.PathOperation.difference, wall, _wedge(legX, legY, h));
  wall = Path.combine(
      ui.PathOperation.difference, wall, _wedge(w - legX, legY, h, mirror: w));
  canvas.save();
  canvas.clipPath(wall);
  _nearWall(canvas, size, legY);
  canvas.restore();

  // A crisp gold keel line on each arch, dimming as it recedes.
  _archKeel(canvas, a1, w, h, 0.46, 0.0060);
  _archKeel(canvas, a2, w, h, 0.26, 0.0042);
  _archKeel(canvas, a3, w, h, 0.34, 0.0034);

  // 7. Hanging lamps, in front of everything architectural.
  _lamp(canvas, size, _lampX(w, h, 0));
  _lamp(canvas, size, _lampX(w, h, 1));

  // 8. Seat the whole scene.
  _vignette(canvas, size, 0.44);
}

/// ONLY the pulse-driven pieces. [pulse] is 0..1, looping.
///
/// Two cheap additive passes: the niche breathing, and the lamps' warm halos
/// swaying a hair. The lamp bodies themselves are static — the sway is carried
/// by their light, which is all that is perceptible at this amplitude.
void paintEmeraldMihrabAnimated(Canvas canvas, Size size, double pulse) {
  final w = size.width, h = size.height;
  final phase = pulse * 2 * math.pi;
  final breath = math.sin(phase); // -1 → 1

  // Niche glow — the tall pool of light the lantern is backlit by.
  final rx = w * (0.230 + 0.010 * breath);
  _glowEllipse(
    canvas,
    Offset(w / 2, h * _kNicheGlowY),
    rx,
    rx * 1.60,
    [
      _kNicheLight.withValues(alpha: 0.15 + 0.028 * breath),
      _kNicheLight.withValues(alpha: 0.045),
      _kNicheLight.withValues(alpha: 0.0),
    ],
    const [0.0, 0.50, 1.0],
  );

  // A tighter, hotter core so the niche has a source rather than a haze.
  final coreR = w * (0.085 + 0.007 * breath);
  _glowEllipse(
    canvas,
    Offset(w / 2, h * (_kNicheGlowY - 0.025)),
    coreR,
    coreR * 1.75,
    [
      _kNicheCore.withValues(alpha: 0.22 + 0.045 * breath),
      _kNicheCore.withValues(alpha: 0.0),
    ],
    const [0.0, 1.0],
  );

  // Lamp halos, swaying out of phase with each other.
  for (var i = 0; i < 2; i++) {
    final baseX = _lampX(w, h, i);
    final sway = w * 0.006 * math.sin(phase + i * 1.9);
    final c = Offset(baseX + sway, h * _kLampY);
    final r = w * (0.098 + 0.006 * math.sin(phase + i * 1.9));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [
          _kGoldLit.withValues(alpha: 0.20),
          _kGoldLit.withValues(alpha: 0.05),
          _kGoldLit.withValues(alpha: 0.0),
        ], const [
          0.0,
          0.45,
          1.0
        ])
        ..blendMode = BlendMode.plus,
    );
  }
}

// ── Arch geometry ────────────────────────────────────────────────────────────

/// A two-centred pointed arch for the bay at perspective scale [s].
///
/// Left leg → vertical tangent at the springline → a genuine point at the apex
/// → mirrored down the right leg. Left open: filling and clipping treat it as
/// closed, while stroking it skips the base line (which is floor, not stone).
Path _arch(double w, double h, double s, {double? baseOverride}) {
  final cx = w / 2;
  final yv = h * _kHorizonY;
  final half = _unit(w, h) * _kArchHalf * s;
  final apexY = yv - h * _kApexRise * s;
  final springY = yv - h * _kSpringRise * s;
  final baseY = baseOverride ?? (yv + h * _kBaseDrop * s);
  final rise = springY - apexY;

  return Path()
    ..moveTo(cx - half, baseY)
    ..lineTo(cx - half, springY)
    ..cubicTo(
      cx - half, springY - rise * 0.55, // keeps the leg vertical off the spring
      cx - half * 0.42, apexY + rise * 0.26, // pulls the curve to a point
      cx, apexY,
    )
    ..cubicTo(
      cx + half * 0.42,
      apexY + rise * 0.26,
      cx + half,
      springY - rise * 0.55,
      cx + half,
      springY,
    )
    ..lineTo(cx + half, baseY);
}

/// The triangular sliver of carpet visible beside a receding side wall.
Path _wedge(double legX, double legY, double h, {double? mirror}) {
  final edgeX = mirror ?? 0.0;
  return Path()
    ..moveTo(edgeX, h * 1.02)
    ..lineTo(legX, legY)
    ..lineTo(legX, h * 1.02)
    ..close();
}

void _archKeel(
    Canvas canvas, Path arch, double w, double h, double alpha, double weight) {
  // The keel fades down the legs: the arch head is what catches the eye, while
  // the piers below sink into shadow. A vertical gradient on the stroke paint
  // does this in one pass instead of splitting the path.
  ui.Gradient fade(double a) => ui.Gradient.linear(
        Offset.zero,
        Offset(0, h),
        [
          _kGoldLit.withValues(alpha: a),
          _kGoldLit.withValues(alpha: a),
          _kGoldLit.withValues(alpha: a * 0.30),
          _kGoldLit.withValues(alpha: a * 0.10),
        ],
        const [0.0, 0.30, 0.62, 1.0],
      );

  // Soft aura first so the line glows rather than cuts.
  canvas.drawPath(
    arch,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * weight * 4.5
      ..shader = fade(alpha * 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.016),
  );
  canvas.drawPath(
    arch,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * weight
      ..strokeJoin = StrokeJoin.round
      ..shader = fade(alpha),
  );
}

// ── Bay interiors ────────────────────────────────────────────────────────────

/// Flat-ish fill for a bay ring: lit a little at eye level, dark at the vault.
void _bayFill(Canvas canvas, Size size, Color top, Color bottom) {
  final w = size.width, h = size.height;
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        [bottom, top, bottom],
        const [0.0, 0.58, 1.0],
      ),
  );
}

/// Concentric ribs across a bay soffit — the barrel of the vault seen end-on.
void _vaultRibs(Canvas canvas, Size size, double s, int count) {
  final w = size.width, h = size.height;
  final p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0022
    ..color = _kGoldLit.withValues(alpha: 0.055);
  for (var i = 1; i <= count; i++) {
    canvas.drawPath(_arch(w, h, s * (1 - i * 0.055)), p);
  }
}

/// The niche: back wall, a radiating semi-dome (conch) in its head, a shallow
/// inner arch, and a resting warm wash that the animated layer breathes over.
void _niche(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w / 2;
  final yv = h * _kHorizonY;
  final apexY = yv - h * _kApexRise * _kScale3;
  final springY = yv - h * _kSpringRise * _kScale3;
  final half = _unit(w, h) * _kArchHalf * _kScale3;

  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, apexY),
        Offset(cx, h * 0.745),
        // Warms as it descends: this is plaster lit by a candle standing in
        // the niche, so the stone itself has to turn gold, not green. Additive
        // light over a green wall only ever reads lime.
        const [Color(0xFF031710), _kNicheWall, Color(0xFF2C2110)],
        const [0.0, 0.42, 1.0],
      ),
  );

  // Conch: thin ribs fanning from the niche apex down to the springline.
  final ribs = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0022
    ..color = _kGoldLit.withValues(alpha: 0.16);
  const ribCount = 11;
  for (var i = 0; i <= ribCount; i++) {
    final t = i / ribCount;
    final a = math.pi * (1 + t); // 180° → 360°, i.e. the upper half
    final o = Offset(
      cx + half * 0.94 * math.cos(a),
      springY + (springY - apexY) * 0.90 * math.sin(a),
    );
    canvas.drawLine(Offset(cx, apexY + (springY - apexY) * 0.12), o, ribs);
  }
  // The arc that closes the conch off from the niche's flat back wall.
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(cx, springY),
      width: half * 1.88,
      height: (springY - apexY) * 1.80,
    ),
    math.pi,
    math.pi,
    false,
    ribs..color = _kGoldLit.withValues(alpha: 0.22),
  );

  // A shallow inner arch outline, inset — the mihrab's own moulding.
  canvas.drawPath(
    _arch(w, h, _kScale3 * 0.80),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0026
      ..color = _kGold.withValues(alpha: 0.20),
  );

  // Resting warm wash so the niche is never fully dark between breaths. Painted
  // srcOver rather than additive so it *replaces* the green with gold instead
  // of summing into yellow-green; the animated layer adds the additive sparkle.
  _glowEllipse(
    canvas,
    Offset(cx, h * _kNicheGlowY),
    w * 0.24,
    w * 0.40,
    [
      _kNicheLight.withValues(alpha: 0.60),
      _kNicheLight.withValues(alpha: 0.18),
      _kNicheLight.withValues(alpha: 0.0),
    ],
    const [0.0, 0.52, 1.0],
    blend: BlendMode.srcOver,
  );
}

/// A radial glow squashed into an ellipse — `drawCircle` under a scaled canvas,
/// so the falloff stays smooth instead of clipping a circular shader to an oval.
void _glowEllipse(Canvas canvas, Offset c, double rx, double ry,
    List<Color> colors, List<double> stops,
    {BlendMode blend = BlendMode.plus}) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(1.0, ry / rx);
  canvas.drawCircle(
    Offset.zero,
    rx,
    Paint()
      ..shader = ui.Gradient.radial(Offset.zero, rx, colors, stops)
      ..blendMode = blend,
  );
  canvas.restore();
}

// ── Muqarnas ─────────────────────────────────────────────────────────────────

/// Four corbelled rows of honeycomb cells packed into the head of the front
/// arch — the stalactite vaulting that makes an Islamic interior unmistakable.
/// Each row widens, gains two cells and steps forward on its own ledge; because
/// the only light in the hall comes from the niche *below*, every cell is dark
/// in its recess and catches a bright lip along its lower edge. That inversion
/// is what makes the rows read as hanging stone rather than as painted arches.
void _muqarnas(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w / 2;
  final yv = h * _kHorizonY;
  final apexY = yv - h * _kApexRise; // front arch apex
  final half = _unit(w, h) * _kArchHalf;

  // A carved boss at the very apex, crowning the vaulting.
  final bossC = Offset(cx, apexY + h * 0.026);
  canvas.drawCircle(
    bossC,
    w * 0.020,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0020
      ..color = _kGold.withValues(alpha: 0.26),
  );
  _star8(
    canvas,
    bossC,
    w * 0.014,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0016
      ..color = _kGoldLit.withValues(alpha: 0.24),
  );

  final bandTop = apexY + h * 0.046;
  final rowH = h * 0.038;
  // The last row overruns the arch and is cropped by the ring clip, which tucks
  // the vaulting into the curve instead of leaving a floating rectangle.
  const spans = [0.30, 0.56, 0.82, 1.06];

  for (var r = 0; r < 4; r++) {
    final y0 = bandTop + r * rowH;
    final y1 = y0 + rowH;
    final count = 3 + 2 * r; // 3, 5, 7, 9
    final spanHalf = half * spans[r];
    final cellW = 2 * spanHalf / count;

    for (var i = 0; i < count; i++) {
      final ccx = cx - spanHalf + cellW * (i + 0.5);
      final cell = _cellPath(ccx, cellW * 0.98, y0, y1);

      // Recess: dark at the top, warming toward the lit lower lip.
      canvas.drawPath(
        cell,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(ccx, y0),
            Offset(ccx, y1),
            const [Color(0xFF020F0A), Color(0xFF0B3A27)],
          ),
      );
      // The lip itself, catching the niche light.
      canvas.drawLine(
        Offset(ccx - cellW * 0.44, y1),
        Offset(ccx + cellW * 0.44, y1),
        Paint()
          ..strokeWidth = w * 0.0022
          ..color = _kGoldLit.withValues(alpha: 0.30),
      );
      canvas.drawPath(
        cell,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.0014
          ..color = _kGold.withValues(alpha: 0.16),
      );
    }

    // The corbel course the row stands on, plus its cast shadow.
    canvas.drawLine(
      Offset(cx - spanHalf, y1),
      Offset(cx + spanHalf, y1),
      Paint()
        ..strokeWidth = w * 0.0026
        ..color = _kGold.withValues(alpha: 0.20),
    );
    canvas.drawRect(
      Rect.fromLTRB(cx - spanHalf, y1, cx + spanHalf, y1 + h * 0.003),
      Paint()..color = const Color(0xFF010806).withValues(alpha: 0.30),
    );

    // Small pendants hanging where two cells of the row above meet.
    if (r > 0) {
      final upper = 3 + 2 * (r - 1);
      final upperHalf = half * spans[r - 1];
      final upperW = 2 * upperHalf / upper;
      for (var i = 1; i < upper; i++) {
        final px = cx - upperHalf + upperW * i;
        canvas.drawPath(
          Path()
            ..moveTo(px - w * 0.008, y0)
            ..lineTo(px + w * 0.008, y0)
            ..lineTo(px, y0 + h * 0.011)
            ..close(),
          Paint()..color = _kGold.withValues(alpha: 0.18),
        );
      }
    }
  }
}

/// One muqarnas cell: a small pointed niche, apex up.
Path _cellPath(double cx, double cw, double y0, double y1) {
  final hw = cw / 2;
  final rise = (y1 - y0) * 0.72;
  return Path()
    ..moveTo(cx - hw, y1)
    ..lineTo(cx - hw, y0 + rise)
    ..cubicTo(
        cx - hw, y0 + rise * 0.40, cx - hw * 0.46, y0 + rise * 0.26, cx, y0)
    ..cubicTo(cx + hw * 0.46, y0 + rise * 0.26, cx + hw, y0 + rise * 0.40,
        cx + hw, y0 + rise)
    ..lineTo(cx + hw, y1)
    ..close();
}

// ── Piers, wall, floor ───────────────────────────────────────────────────────

/// The two piers carrying the front arch: a lit shaft edge and a stepped
/// capital at the springline, so the arch lands on something.
void _piers(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final yv = h * _kHorizonY;
  final springY = yv - h * _kSpringRise;
  final baseY = yv + h * _kBaseDrop;
  final half = _unit(w, h) * _kArchHalf;
  final cx = w / 2;

  for (final sign in const [-1.0, 1.0]) {
    final x = cx + sign * half;
    final inner = x - sign * w * 0.030;

    // Shaft: a soft gradient from the lit inner edge into the pier.
    canvas.drawRect(
      Rect.fromLTRB(
        math.min(x, inner),
        springY,
        math.max(x, inner),
        baseY,
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(inner, 0),
          Offset(x, 0),
          [
            _kGoldLit.withValues(alpha: 0.055),
            _kGoldLit.withValues(alpha: 0.0),
          ],
        ),
    );

    // Capital + base: two thin stepped bands.
    for (final band in [springY, baseY - h * 0.012]) {
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(x, inner) - w * 0.006,
          band,
          math.max(x, inner) + w * 0.006,
          band + h * 0.010,
        ),
        Paint()..color = _kGold.withValues(alpha: 0.14),
      );
    }
  }
}

/// The near side walls: girih wash, a dado band, pilaster shading and a pair of
/// spandrel roundels. Clipped by the caller to the region outside the arch.
void _nearWall(Canvas canvas, Size size, double legY) {
  final w = size.width, h = size.height;
  // Where the front arch's leg lands — the inner boundary of this wall.
  final legX = w / 2 - _unit(w, h) * _kArchHalf;
  // Centre of each side wall, which is where its ornament belongs.
  final wallC = legX / 2;

  // Base tone — lighter toward eye level, sinking at ceiling and floor.
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        const [Color(0xFF04211A), _kWallDark, _kWallMid, Color(0xFF02120B)],
        const [0.0, 0.26, 0.46, 1.0],
      ),
  );

  // Girih lattice at ~5% — decorative accent only, per the design system.
  _girihWash(canvas, size, 0.050);

  // Dado: a waist-height band of slightly deeper stone with a gold hairline.
  final dadoY = h * 0.615;
  canvas.drawRect(
    Rect.fromLTRB(0, dadoY, w, h),
    Paint()..color = const Color(0xFF021711).withValues(alpha: 0.35),
  );
  canvas.drawLine(
    Offset(0, dadoY),
    Offset(w, dadoY),
    Paint()
      ..strokeWidth = w * 0.0022
      ..color = _kGold.withValues(alpha: 0.22),
  );

  // Pilasters: soft vertical light on the outermost slice of each wall.
  for (final sign in const [-1.0, 1.0]) {
    final edge = sign < 0 ? 0.0 : w;
    canvas.drawRect(
      Rect.fromLTRB(math.min(edge, edge + sign * w * 0.09), 0,
          math.max(edge, edge + sign * w * 0.09), h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(edge, 0),
          Offset(edge + sign * w * 0.09, 0),
          [
            Colors.white.withValues(alpha: 0.030),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
    );
  }

  // A cornice running across the top of the hall, with a course of small
  // stepped merlons above it — the crown the arcade hangs from.
  final corniceY = h * 0.052;
  canvas.drawRect(
    Rect.fromLTRB(0, corniceY, w, corniceY + h * 0.009),
    Paint()..color = _kGold.withValues(alpha: 0.20),
  );
  canvas.drawRect(
    Rect.fromLTRB(0, corniceY + h * 0.009, w, corniceY + h * 0.020),
    Paint()..color = const Color(0xFF010806).withValues(alpha: 0.40),
  );
  final merlon = Paint()..color = _kGold.withValues(alpha: 0.13);
  final mw = w * 0.030;
  for (var x = 0.0; x < w; x += mw * 2) {
    canvas.drawRect(
      Rect.fromLTRB(x, corniceY - h * 0.013, x + mw, corniceY),
      merlon,
    );
  }

  // A blind pointed-arch niche recessed into each side wall. Deliberately the
  // same arch profile as the arcade, at wall scale — a rounded rectangle here
  // would be the one shape in the scene that isn't architecture.
  for (final sign in const [-1.0, 1.0]) {
    // Centred on the wall between the arch leg and the canvas edge, so the
    // ornament tracks the arcade at any aspect ratio.
    final c = w / 2 + sign * (w / 2 - wallC);
    final hw = math.min(w * 0.052, wallC * 0.62);
    final blind = Path()
      ..moveTo(c - hw, h * 0.588)
      ..lineTo(c - hw, h * 0.320)
      ..cubicTo(c - hw, h * 0.276, c - hw * 0.42, h * 0.246, c, h * 0.228)
      ..cubicTo(c + hw * 0.42, h * 0.246, c + hw, h * 0.276, c + hw, h * 0.320)
      ..lineTo(c + hw, h * 0.588)
      ..close();
    canvas.drawPath(
      blind,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(c, h * 0.228),
          Offset(c, h * 0.588),
          [
            const Color(0xFF010806).withValues(alpha: 0.55),
            const Color(0xFF010806).withValues(alpha: 0.18),
          ],
        ),
    );
    canvas.drawPath(
      blind,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.0022
        ..color = _kGold.withValues(alpha: 0.20),
    );
    _star8(
      canvas,
      Offset(c, h * 0.360),
      w * 0.022,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.0016
        ..color = _kGoldLit.withValues(alpha: 0.16),
    );
  }

  // Spandrel roundels flanking the front arch.
  for (final sign in const [-1.0, 1.0]) {
    final c = Offset(w / 2 + sign * (w / 2 - wallC), h * 0.150);
    canvas.drawCircle(
      c,
      w * 0.052,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.0026
        ..color = _kGold.withValues(alpha: 0.26),
    );
    _star8(
        canvas,
        c,
        w * 0.038,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.0020
          ..color = _kGoldLit.withValues(alpha: 0.20));
  }

  // The wall's own base line, angled as it recedes toward the viewer.
  final plinth = Paint()
    ..strokeWidth = w * 0.0026
    ..color = _kGold.withValues(alpha: 0.16);
  canvas.drawLine(Offset(0, h * 1.02), Offset(legX, legY), plinth);
  canvas.drawLine(Offset(w, h * 1.02), Offset(w - legX, legY), plinth);
}

/// The floor: a perspective grid receding to the vanishing point, a suggested
/// runner rug with its own borders and motifs, and the niche light spilling
/// forward across it. Low contrast throughout — texture, not noise.
void _carpet(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w / 2;
  final yv = h * _kHorizonY;
  final top = h * _kFloorTopY;
  final u = _unit(w, h);

  canvas.save();
  canvas.clipRect(Rect.fromLTRB(0, top, w, h));

  // Ground tone: warmest where it meets the lit niche, sinking to near-black
  // in the foreground so nothing competes with the lantern.
  canvas.drawRect(
    Rect.fromLTRB(0, top, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, top),
        Offset(cx, h),
        // Warm where the niche light lands, cooling and darkening toward the
        // viewer's feet so the foreground never competes with the lantern.
        const [Color(0xFF25321D), Color(0xFF0A3324), Color(0xFF04190F)],
        const [0.0, 0.40, 1.0],
      ),
  );

  // Light spilling out of the niche onto the carpet.
  final spill = Offset(cx, top + h * 0.012);
  canvas.drawOval(
    Rect.fromCenter(center: spill, width: u * 0.86, height: (h - top) * 0.90),
    Paint()
      ..shader = ui.Gradient.radial(spill, u * 0.43, [
        _kNicheLight.withValues(alpha: 0.30),
        _kNicheLight.withValues(alpha: 0.0),
      ]),
  );

  final grid = Paint()
    ..strokeWidth = w * 0.0018
    ..color = _kGoldLit.withValues(alpha: 0.085);

  // Transverse rows. Screen y for the k-th row of an evenly spaced floor is
  // yv + K/k — the classic 1/depth falloff, so rows crowd toward the horizon.
  final k0 = h - yv;
  final rows = <double>[];
  for (var k = 1; k <= 12; k++) {
    final y = yv + k0 / k;
    if (y <= top) break;
    rows.add(y);
    canvas.drawLine(Offset(0, y), Offset(w, y), grid);
  }

  // Longitudinal lines, all converging on the vanishing point.
  for (var j = -8; j <= 8; j++) {
    final xb = cx + j * u * 0.145;
    canvas.drawLine(Offset(xb, h), Offset(cx, yv), grid);
  }

  // The runner rug: a narrower band with brighter borders, also converging.
  final rugOuter = u * 0.300, rugInner = u * 0.262;
  final border = Paint()
    ..strokeWidth = w * 0.0026
    ..color = _kGoldLit.withValues(alpha: 0.175);
  for (final s in const [-1.0, 1.0]) {
    canvas.drawLine(Offset(cx + s * rugOuter, h), Offset(cx, yv), border);
    canvas.drawLine(Offset(cx + s * rugInner, h), Offset(cx, yv), border);
  }

  // A motif per row band inside the rug: a centred 8-point star flanked by two
  // diamonds, scaled by that band's depth so it foreshortens with the grid.
  final motif = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0020
    ..color = _kGoldLit.withValues(alpha: 0.125);
  for (var i = 0; i + 1 < rows.length; i++) {
    final yMid = (rows[i] + rows[i + 1]) / 2;
    final band = (rows[i] - rows[i + 1]).abs();
    // Perspective width of the rug at this depth.
    final t = (yMid - yv) / (h - yv);
    final halfHere = rugInner * t;
    final r = math.min(band * 0.34, halfHere * 0.34);
    if (r < w * 0.004) continue;
    _star8(canvas, Offset(cx, yMid), r, motif);
    for (final s in const [-1.0, 1.0]) {
      _diamond(canvas, Offset(cx + s * halfHere * 0.60, yMid), r * 0.62, motif);
    }
  }

  // The rug's near end-band — two transverse lines closing the runner off, so
  // it reads as a woven object laid on the floor rather than an endless grid.
  if (rows.isNotEmpty) {
    for (final f in const [0.86, 0.90]) {
      final y = yv + (h - yv) * f;
      final halfHere = rugOuter * f;
      canvas.drawLine(
          Offset(cx - halfHere, y), Offset(cx + halfHere, y), border);
    }
  }

  // Damp the near foreground. The lantern stands over this band, so the rug is
  // allowed to be legible behind it but never busy under it.
  canvas.drawRect(
    Rect.fromLTRB(0, h * 0.80, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(cx, h * 0.80),
        Offset(cx, h),
        [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.55),
        ],
      ),
  );

  canvas.restore();
}

// ── Hanging lamps ────────────────────────────────────────────────────────────

/// A silhouetted Mamluk-style mosque lamp on a chain: flared mouth, pinched
/// neck, bulbous body, small finial — plus three short suspension chains and a
/// resting warm glow (the animated layer adds the swaying halo on top).
void _lamp(Canvas canvas, Size size, double cx) {
  final w = size.width, h = size.height;
  final bodyH = h * 0.115;
  final bw = w * 0.098;
  final cy = h * _kLampY;
  final ty = cy - bodyH * 0.52;
  final by = ty + bodyH;

  final chain = Paint()
    ..strokeWidth = w * 0.0026
    ..color = _kSilhouette.withValues(alpha: 0.85);

  // Main chain from the ceiling down to a suspension ring.
  final ringY = ty - h * 0.052;
  canvas.drawLine(Offset(cx, -h * 0.01), Offset(cx, ringY), chain);
  // Link ticks so the chain is not a bare line.
  for (var y = 0.0; y < ringY; y += h * 0.020) {
    canvas.drawLine(Offset(cx - w * 0.005, y), Offset(cx + w * 0.005, y),
        chain..strokeWidth = w * 0.0018);
  }
  canvas.drawCircle(
    Offset(cx, ringY),
    w * 0.010,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0030
      ..color = _kSilhouette.withValues(alpha: 0.9),
  );
  // Three short chains fanning from the ring to the lamp's rim.
  for (final s in const [-1.0, 0.0, 1.0]) {
    canvas.drawLine(
      Offset(cx, ringY + w * 0.010),
      Offset(cx + s * bw * 0.46, ty),
      chain..strokeWidth = w * 0.0022,
    );
  }

  // Body: the classic mosque-lamp profile — a wide flared mouth, a pinched
  // neck, then a bulbous bowl on a small foot. Kept as three separate shapes
  // rather than one merged outline; unioning them smooths the waist away and
  // the whole thing collapses into an anonymous teardrop.
  double y(double f) => ty + bodyH * f;
  final mouth = Path()
    ..moveTo(cx - bw * 0.56, ty)
    ..lineTo(cx + bw * 0.56, ty)
    ..cubicTo(cx + bw * 0.50, y(0.10), cx + bw * 0.20, y(0.16), cx + bw * 0.13,
        y(0.28))
    ..lineTo(cx - bw * 0.13, y(0.28))
    ..cubicTo(
        cx - bw * 0.20, y(0.16), cx - bw * 0.50, y(0.10), cx - bw * 0.56, ty)
    ..close();
  final neck = Path()
    ..addRect(Rect.fromLTRB(cx - bw * 0.11, y(0.27), cx + bw * 0.11, y(0.40)));
  final bowl = Path()
    ..moveTo(cx - bw * 0.15, y(0.38))
    ..cubicTo(cx - bw * 0.50, y(0.48), cx - bw * 0.56, y(0.72), cx - bw * 0.34,
        y(0.90))
    ..cubicTo(cx - bw * 0.20, y(1.01), cx + bw * 0.20, y(1.01), cx + bw * 0.34,
        y(0.90))
    ..cubicTo(cx + bw * 0.56, y(0.72), cx + bw * 0.50, y(0.48), cx + bw * 0.15,
        y(0.38))
    ..close();

  // Resting glow behind the silhouette so it reads as lit, not as a hole.
  final gc = Offset(cx, y(0.72));
  canvas.drawCircle(
    gc,
    bw * 1.70,
    Paint()
      ..shader = ui.Gradient.radial(gc, bw * 1.70, [
        _kGoldLit.withValues(alpha: 0.26),
        _kGoldLit.withValues(alpha: 0.0),
      ])
      ..blendMode = BlendMode.plus,
  );

  final metal = Paint()..color = _kSilhouette.withValues(alpha: 0.90);
  final rim = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0026
    ..color = _kGold.withValues(alpha: 0.55);
  for (final part in [mouth, neck, bowl]) {
    canvas.drawPath(part, metal);
    canvas.drawPath(part, rim);
  }

  // Pierced glass: the flame showing through the bowl's lower half. Painted
  // srcOver in a warm amber then topped with a small additive spark, so it
  // reads as fire rather than as a grey smudge on the silhouette.
  canvas.save();
  canvas.clipPath(bowl);
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(cx, y(0.78)), width: bw * 0.60, height: bodyH * 0.36),
    Paint()
      ..color = const Color(0xFFD9821F).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.009),
  );
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(cx, y(0.76)), width: bw * 0.24, height: bodyH * 0.16),
    Paint()
      ..color = _kNicheCore.withValues(alpha: 0.70)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.005)
      ..blendMode = BlendMode.plus,
  );
  canvas.restore();
  // Small finial under the bowl.
  canvas.drawCircle(Offset(cx, by + bodyH * 0.03), bw * 0.055, metal);
}

// ── Ornament helpers ─────────────────────────────────────────────────────────

/// A khatam/girih lattice: 8-point stars on a square grid with interlocking
/// diamonds between them. Kept at ~5% alpha — decorative accent only.
void _girihWash(Canvas canvas, Size size, double alpha) {
  final w = size.width, h = size.height;
  final step = w * 0.150;
  final star = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0016
    ..color = _kGoldLit.withValues(alpha: alpha);
  final tie = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0014
    ..color = _kGoldLit.withValues(alpha: alpha * 0.62);

  for (var gy = -step; gy < h + step; gy += step) {
    for (var gx = -step; gx < w + step; gx += step) {
      _star8(canvas, Offset(gx, gy), step * 0.38, star);
      _diamond(canvas, Offset(gx + step / 2, gy + step / 2), step * 0.24, tie);
    }
  }
}

/// An 8-point khatam star.
void _star8(Canvas canvas, Offset c, double r, Paint p) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final rad = i.isEven ? r : r * 0.42;
    final a = i * math.pi / 8 - math.pi / 2;
    final o = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  canvas.drawPath(path..close(), p);
}

void _diamond(Canvas canvas, Offset c, double r, Paint p) {
  canvas.drawPath(
    Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.66, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.66, c.dy)
      ..close(),
    p,
  );
}

void _vignette(Canvas canvas, Size size, double strength) {
  final c = Offset(size.width / 2, size.height * 0.56);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.radial(c, size.height * 0.66, [
        Colors.black.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: strength),
      ], const [
        0.55,
        1.0
      ]),
  );
}
