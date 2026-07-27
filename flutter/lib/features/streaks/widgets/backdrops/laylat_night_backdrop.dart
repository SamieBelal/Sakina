// Laylat Night — the city keeping vigil. A great mosque and the town around it
// silhouetted against a night sky that still has an ember of dusk left in it,
// under a waning crescent. The counterpart to Desert Night's emptiness: this is
// the scene with *architecture* in it.
//
// Depth planes, back to front (this is also the paint order):
//   1. sky          — twelve-stop ramp, indigo zenith → violet → ember horizon
//   2. sky bands    — five thin stratification layers, so the ramp isn't a wash
//   3. khatam wash  — 4% lattice, upper third only, fading out
//   4. star field   — 220 static stars: varied size, colour temperature, and
//                     atmospheric extinction toward the horizon
//   5. bright stars — seven fixed crisp four-point sparkles (STATIC, so the eye
//                     always has something sharp to lock onto)
//   6. moon         — wash + halo + earthshine disc + crisp-limbed crescent
//   7. ember glow   — the last of dusk, biased LEFT so it counterweights the moon
//   8. far skyline  — a hazier, lifted town a district away
//   9. near skyline — the hero: mosque (dome, ribbed, drum arcade, half-domes,
//                     prayer-hall arcade), two galleried minarets, town blocks
//                     with lit windows, and a merloned courtyard wall
//  10. plaza        — perspective paving, reflected window light, lantern pool
//  11. vignette
//
// WHY IT LOOKS THE WAY IT DOES. The scene it replaces read "blurry" because
// nothing in it had a hard edge: every silhouette outline was a `MaskFilter`ed
// stroke, the buildings were featureless rectangles, all the stars lived in the
// animated layer, and a huge additive ground glow sat straight over the skyline.
// So here: blur is reserved for genuine light (halos, blooms, reflections) and
// every structural line is a crisp stroke or a filled path. Rim-light is always
// painted twice — a wide blurred aura *under* a hairline — which is what makes
// an edge glow instead of smear.
//
// Code-drawn only (paths / gradients / blurs — no assets), architecture and sky
// only (no figurative imagery), and fully deterministic: every position is a
// literal or comes from the seeded `_r` hash, never `Random()`. Repaints are
// therefore pixel-identical and the static layer raster-caches cleanly.
//
// Self-contained by design — the helpers are duplicated rather than shared with
// `backdrop_painter.dart` so each scene can be tuned without cross-scene
// regressions.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ── Scene constants ─────────────────────────────────────────────────────────
// Vertical positions are fractions of height, horizontal of width. Named once
// here so the layers stay in register when any one of them is tuned.

/// The plaza line: where the near skyline stands and the ground begins.
const double _kGroundY = 0.742;

/// The far town's foot — tucked just behind the courtyard wall's parapet.
const double _kFarBaseY = 0.720;

/// Courtyard wall: merlon tops, wall top, and it runs down to [_kGroundY].
const double _kMerlonY = 0.700;
const double _kWallY = 0.712;

/// Grand mosque massing.
const double _kHallTopY = 0.640; // prayer-hall roofline
const double _kDrumTopY = 0.560; // where the dome springs
const double _kDomeApexY = 0.415;
const double _kHallHalf = 0.215; // fraction of width
const double _kDrumHalf = 0.125;
const double _kDomeHalf = 0.118;

/// The two minarets, mirrored about centre.
const double _kMinaretDx = 0.248;

/// The crescent.
const double _kMoonX = 0.775;
const double _kMoonY = 0.150;

/// Where the last of dusk sits on the horizon. Deliberately LEFT of centre:
/// the ember and the moon then sit on a diagonal, the brightest sky is nowhere
/// near the middle, and the lantern's column of the frame stays mid-value.
const double _kEmberX = 0.340;

// ── Palette ─────────────────────────────────────────────────────────────────

const Color _kNear = Color(0xFF08060F); // near silhouette, top
const Color _kNearLow = Color(0xFF0D0A15); // near silhouette, at the ground
const Color _kFar = Color(0xFF251E3A); // far town — lifted, hazy, cooler
const Color _kRim = Color(0xFFF6B478); // warm rim off the ember horizon
const Color _kMoonRim = Color(0xFFBFCDE8); // cool rim off the moon
const Color _kWindow = Color(0xFFF7C079); // lamplight in a window
const Color _kMoonLit = Color(0xFFFDF5DE);
const Color _kMoonDim = Color(0xFFDCC79C);

// ── Public entry points ─────────────────────────────────────────────────────

/// Everything geometrically fixed. Painted once and raster-cached.
void paintLaylatNightStatic(Canvas canvas, Size size) {
  _sky(canvas, size);
  _skyBands(canvas, size);
  _skyLattice(canvas, size);
  _starField(canvas, size);
  _brightStars(canvas, size);
  _moon(canvas, size);
  _emberGlow(canvas, size);
  _farSkyline(canvas, size);
  _townBlocks(canvas, size);
  _minaret(canvas, size, 0.5 - _kMinaretDx, 1);
  _minaret(canvas, size, 0.5 + _kMinaretDx, 2);
  _grandMosque(canvas, size);
  _courtyardWall(canvas, size);
  _plaza(canvas, size);
  _vignette(canvas, size, 0.34);
}

/// ONLY the pulse-driven pieces. [pulse] is 0..1, looping.
///
/// Two cheap additive passes: a few dozen stars twinkling, and the warm pool on
/// the plaza breathing. All the sky's *texture* is static underneath, so this
/// layer only has to carry the scene's life, not its detail.
void paintLaylatNightAnimated(Canvas canvas, Size size, double pulse) {
  final phase = pulse * 2 * math.pi;
  _twinkle(canvas, size, phase);
  _groundDrift(canvas, size, phase);
}

// ── Deterministic noise ─────────────────────────────────────────────────────

// Small deterministic "random" in [0,1) from an index + salt. Same trick the
// sibling scenes use — cheap, stable across repaints and across platforms.
double _r(int i, double salt) {
  final v = math.sin((i + 1) * 12.9898 + salt * 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

// Star colours: mostly neutral, with a scatter of hot-blue and warm-amber ones.
// A field of identical white dots is one of the things that reads as "flat"; a
// spread of colour temperature is what makes it read as a sky.
Color _starColour(int i) {
  final k = _r(i, 31.7);
  if (k > 0.86) return const Color(0xFFC2D5F8); // hot blue-white
  if (k > 0.71) return const Color(0xFFF8DCAE); // warm amber
  return const Color(0xFFF5F1E4); // neutral
}

// Nothing celestial is drawn below this — the ember band takes over.
double _skyFloor(Size size) => size.height * 0.640;

// ── 1. Sky ──────────────────────────────────────────────────────────────────
// Twelve stops. Night holds on through the top two thirds, then violet gives
// way to plum and the ember happens fast in the last few percent above the
// roofline. The last three stops are almost entirely occluded by the skyline —
// they exist so the slivers of sky *between* buildings don't jump in value.
void _sky(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        const [
          Color(0xFF04061A), // zenith — near-black indigo
          Color(0xFF080C28),
          Color(0xFF0F1338),
          Color(0xFF181848),
          Color(0xFF241D4E),
          Color(0xFF33224F),
          Color(0xFF4A2851),
          Color(0xFF6E3450),
          Color(0xFF9C4A3F),
          Color(0xFFC46B3C), // ember — the hottest line of the sky
          Color(0xFF5E332C),
          Color(0xFF150E16), // below the plaza line
        ],
        const [
          0.00,
          0.11,
          0.24,
          0.36,
          0.46,
          0.545,
          0.615,
          0.672,
          0.702,
          0.722,
          0.775,
          0.90,
        ],
      ),
  );
}

// ── 2. Sky stratification ───────────────────────────────────────────────────
// Five thin, slightly blurred bars lying across the dusk band. A pure vertical
// ramp is perfectly smooth, and perfectly smooth reads as an airbrush; real
// twilight is layered. These are the *only* soft-edged things in the upper
// scene, and at 5–7% they register as depth rather than as banding artefacts.
void _skyBands(Canvas canvas, Size size) {
  final w = size.width, h = size.height;

  void band(double cy, double thickness, Color c, double a) {
    canvas.drawRect(
      Rect.fromLTRB(0, h * (cy - thickness / 2), w, h * (cy + thickness / 2)),
      Paint()
        ..color = c.withValues(alpha: a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.006)
        ..blendMode = BlendMode.plus,
    );
  }

  band(0.548, 0.010, const Color(0xFF6C68A6), 0.045);
  band(0.598, 0.008, const Color(0xFF8A68A0), 0.050);
  band(0.640, 0.012, const Color(0xFFB07A74), 0.055);
  band(0.676, 0.007, const Color(0xFFD08E62), 0.060);
  band(0.706, 0.009, const Color(0xFFEBA566), 0.070);
}

// ── 3. Khatam lattice ───────────────────────────────────────────────────────
// The design system's decorative accent, at 5% and only where the sky is dark
// enough for a hairline to read as pattern rather than noise. Its alpha ramps
// to zero so it dissolves instead of stopping on a row.
void _skyLattice(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final step = w * 0.165;
  final fadeTo = h * 0.30;
  for (var gy = 0.0; gy < fadeTo; gy += step) {
    final t = (1.0 - gy / fadeTo).clamp(0.0, 1.0);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0014
      ..color = Colors.white.withValues(alpha: 0.040 * t);
    for (var gx = 0.0; gx < w + step; gx += step) {
      _star8(canvas, Offset(gx, gy), step * 0.34, p);
    }
  }
}

/// An 8-point khatam rosette outline.
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

// ── 4. Star field ───────────────────────────────────────────────────────────
// 220 stars, STATIC. Keeping the field in the static layer is what lets it be
// this dense (it costs nothing per frame) and it means the sky has texture even
// at the trough of the twinkle. Radius squares the seed so most stars are
// pinpricks and a few are properly bright; alpha falls off cubically toward the
// horizon, which is the atmospheric extinction that makes a sky read as deep.
void _starField(Canvas canvas, Size size) {
  final w = size.width;
  final floor = _skyFloor(size);

  for (var i = 0; i < 220; i++) {
    final x = _r(i, 11.3) * w;
    final y = _r(i, 12.7) * floor;
    final k = y / floor;
    final ext = 1.0 - 0.80 * k * k * k;
    final s = _r(i, 13.9);
    final rad = w * (0.0007 + 0.0022 * s * s);
    final a = ((0.14 + 0.52 * _r(i, 15.1)) * ext).clamp(0.0, 0.85);
    // srcOver rather than additive: at this density `plus` stacks the overlaps
    // into pale grey smudges, which is exactly the softness we're removing.
    canvas.drawCircle(
      Offset(x, y),
      rad,
      Paint()..color = _starColour(i).withValues(alpha: a),
    );
  }
}

// ── 5. Bright stars ─────────────────────────────────────────────────────────
// Seven fixed positions, chosen to keep clear of the moon and of the frame's
// centre column. Each is a soft bloom (a gradient, not a blur) with a hard
// four-point sparkle and a hard core drawn on top — so the brightest things in
// the sky are also the sharpest, which is what sells the whole scene as crisp.
const List<Offset> _kBrightStars = [
  Offset(0.092, 0.068),
  Offset(0.246, 0.186),
  Offset(0.412, 0.096),
  Offset(0.548, 0.248),
  Offset(0.918, 0.322),
  Offset(0.646, 0.058),
  Offset(0.158, 0.374),
];

void _brightStars(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  for (var i = 0; i < _kBrightStars.length; i++) {
    final p = _kBrightStars[i];
    final o = Offset(w * p.dx, h * p.dy);
    final rad = w * (0.0020 + 0.0016 * _r(i, 17.3));
    final a = 0.52 + 0.34 * _r(i, 19.7);
    _sparkle(canvas, o, rad * 5.2, a, _starColour(i * 7 + 3));
  }
}

/// A four-point diffraction sparkle: bloom, crisp spikes, crisp core.
void _sparkle(Canvas canvas, Offset o, double r, double a, Color c) {
  // Bloom — a radial gradient, so it falls off smoothly without a blur pass.
  canvas.drawCircle(
    o,
    r * 1.30,
    Paint()
      ..shader = ui.Gradient.radial(o, r * 1.30, [
        c.withValues(alpha: a * 0.34),
        c.withValues(alpha: 0.0),
      ])
      ..blendMode = BlendMode.plus,
  );
  final p = Paint()
    ..color = c.withValues(alpha: a)
    ..blendMode = BlendMode.plus;
  // The spikes: two needles crossing, the horizontal one shorter. Quadratics
  // through the centre pinch each arm to a point without any blur.
  canvas.drawPath(
    Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 0.58, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 0.58, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close(),
    p,
  );
  canvas.drawCircle(o, r * 0.13, p);
}

// ── 6. Moon ─────────────────────────────────────────────────────────────────
// A waning crescent opening down-left, toward the sunken sun that is also
// lighting the ember. Four passes: a broad sky wash, a tight halo, the full
// lunar disc in earthshine (which gives the moon a hard *circular* edge even
// where it isn't lit), then the crescent itself — a gradient body with a
// hairline limb and a handful of maria clipped inside it. No blur touches the
// body; the old version's blurred under-pass is precisely what made it a blob.
void _moon(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final c = Offset(w * _kMoonX, h * _kMoonY);
  final r = w * 0.078;

  // Broad wash: the sky around a bright moon is genuinely lifted.
  canvas.drawCircle(
    c,
    r * 8.0,
    Paint()
      ..shader = ui.Gradient.radial(c, r * 8.0, [
        const Color(0xFFB9CCE8).withValues(alpha: 0.085),
        const Color(0xFFB9CCE8).withValues(alpha: 0.024),
        const Color(0xFFB9CCE8).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.40,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );
  // Tight halo.
  canvas.drawCircle(
    c,
    r * 2.9,
    Paint()
      ..shader = ui.Gradient.radial(c, r * 2.9, [
        const Color(0xFFF4E9C8).withValues(alpha: 0.19),
        const Color(0xFFF4E9C8).withValues(alpha: 0.04),
        const Color(0xFFF4E9C8).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.42,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );

  // Earthshine: the unlit disc, just visible. One crisp circle — cheap, and it
  // is the difference between "a sliver" and "a moon with a sliver lit".
  canvas.drawCircle(
    c,
    r,
    Paint()..color = _kMoonDim.withValues(alpha: 0.055),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0010
      ..color = _kMoonDim.withValues(alpha: 0.105),
  );

  // The lit crescent. Inner circle offset up-and-right → the lit limb faces
  // down-left, at the ember, which is where the sun went.
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(Rect.fromCircle(
      center: c.translate(r * 0.42, -r * 0.30),
      radius: r * 0.92,
    ));
  final crescent = Path.combine(ui.PathOperation.difference, outer, inner);

  canvas.drawPath(
    crescent,
    Paint()
      ..shader = ui.Gradient.linear(
        c.translate(-r * 0.9, r * 0.9),
        c.translate(r * 0.6, -r * 0.6),
        const [_kMoonLit, Color(0xFFEFDFB4), _kMoonDim],
        const [0.0, 0.55, 1.0],
      ),
  );
  // Maria — three faint darker patches, clipped so they can only fall on the
  // lit sliver. Tiny, but they stop the crescent reading as a paper cut-out.
  canvas.save();
  canvas.clipPath(crescent);
  for (var i = 0; i < 3; i++) {
    canvas.drawCircle(
      c.translate(
        -r * (0.34 + 0.34 * _r(i, 23.1)),
        r * (0.55 * _r(i, 24.5) - 0.20),
      ),
      r * (0.10 + 0.12 * _r(i, 25.9)),
      Paint()..color = const Color(0xFF9E8E6A).withValues(alpha: 0.16),
    );
  }
  canvas.restore();

  // Hairline limb: the crisp edge the whole scene is calibrated against.
  canvas.drawPath(
    crescent,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0012
      ..color = const Color(0xFFFFFBEC).withValues(alpha: 0.55),
  );
}

// ── 7. Ember glow ───────────────────────────────────────────────────────────
// The last of dusk still burning on the horizon, behind everything built. This
// is one of the few places a blur is honest: it is light in air, not an edge.
void _emberGlow(Canvas canvas, Size size) {
  final w = size.width, h = size.height;

  // Wide, low scatter along the horizon.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * _kEmberX, h * 0.714),
      width: w * 1.55,
      height: h * 0.115,
    ),
    Paint()
      ..color = const Color(0xFFE2803A).withValues(alpha: 0.26)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.075)
      ..blendMode = BlendMode.plus,
  );
  // A hotter core, and a soft column of it bleeding upward — the shape dusk
  // actually makes when it is going out behind a city.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * _kEmberX, h * 0.712),
      width: w * 0.62,
      height: h * 0.052,
    ),
    Paint()
      ..color = const Color(0xFFFFB067).withValues(alpha: 0.32)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.045)
      ..blendMode = BlendMode.plus,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * _kEmberX, h * 0.660),
      width: w * 0.70,
      height: h * 0.140,
    ),
    Paint()
      ..color = const Color(0xFFD2703C).withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.038)
      ..blendMode = BlendMode.plus,
  );
}

// ── Rim light ───────────────────────────────────────────────────────────────

/// Peak rim alpha for something standing at [xFrac] — brightest where it is
/// backed by the ember, falling away toward the frame's edges.
double _rimAt(double xFrac, double peak) =>
    (peak - (xFrac - _kEmberX).abs() * peak * 0.85).clamp(peak * 0.26, peak);

/// The warm hairline where the ember backlights a silhouette's edge.
///
/// Painted twice on purpose: a wide, blurred aura first so the edge *glows*,
/// then a hairline on top so it also *cuts*. One pass alone gives either a
/// smear (blur only) or a sticker (line only) — the pair is what reads as light
/// wrapping around stone.
void _rimStroke(
  Canvas canvas,
  Size size,
  Path path,
  double peak, {
  double weight = 0.0016,
  Color colour = _kRim,
}) {
  final w = size.width;
  ui.Gradient fade(double a) => ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          colour.withValues(alpha: a * 0.34),
          colour.withValues(alpha: a),
          colour.withValues(alpha: a * 0.38),
        ],
        const [0.0, _kEmberX, 1.0],
      );

  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * weight * 4.2
      ..shader = fade(peak * 0.20)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.008)
      ..blendMode = BlendMode.plus,
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * weight
      ..strokeJoin = StrokeJoin.round
      ..shader = fade(peak)
      ..blendMode = BlendMode.plus,
  );
}

/// The near silhouette's fill: near-black, a hair warmer where it meets the
/// ground so the buildings don't flatten into one paper cut-out.
Paint _silhouette(Size size, double topY) {
  final h = size.height;
  return Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, topY),
      Offset(0, h * _kGroundY),
      const [_kNear, _kNearLow],
    );
}

// ── Arch geometry ───────────────────────────────────────────────────────────
// One two-centred pointed arch, reused at every scale in the scene. The second
// control point sits almost under the apex, which is what brings the crown to a
// genuine point instead of a dome.
Path _pointedArch(
  double cx,
  double hw,
  double yBase,
  double ySpring,
  double yApex,
) {
  final rise = ySpring - yApex;
  return Path()
    ..moveTo(cx - hw, yBase)
    ..lineTo(cx - hw, ySpring)
    ..cubicTo(
      cx - hw,
      ySpring - rise * 0.60,
      cx - hw * 0.18,
      yApex + rise * 0.30,
      cx,
      yApex,
    )
    ..cubicTo(
      cx + hw * 0.18,
      yApex + rise * 0.30,
      cx + hw,
      ySpring - rise * 0.60,
      cx + hw,
      ySpring,
    )
    ..lineTo(cx + hw, yBase)
    ..close();
}

/// Fills an arch opening with lamplight and traces its keel. Crisp on both
/// counts — the light is a path fill, not a blurred blob, so the arch keeps its
/// profile. [alpha] is the light at the head; it falls away toward the floor
/// because you are looking into a room, not at a lightbox.
void _litArch(Canvas canvas, Size size, Path arch, double yApex, double yBase,
    double alpha) {
  final w = size.width;
  canvas.drawPath(
    arch,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, yApex),
        Offset(0, yBase),
        [
          _kWindow.withValues(alpha: alpha),
          _kWindow.withValues(alpha: alpha * 0.55),
          _kWindow.withValues(alpha: alpha * 0.16),
        ],
        const [0.0, 0.55, 1.0],
      ),
  );
  canvas.drawPath(
    arch,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0012
      ..color = _kRim.withValues(alpha: alpha * 0.85)
      ..blendMode = BlendMode.plus,
  );
}

// ── Windows ─────────────────────────────────────────────────────────────────

/// A grid of lit windows across a building face. Roughly a third stay dark and
/// the lit ones vary in warmth, which is what makes a block read as inhabited
/// rather than as a perforated card. Panes are crisp rects; only the brightest
/// get a bloom, and the bloom is a separate pass so it never softens the pane.
void _windowGrid(
  Canvas canvas,
  Size size,
  Rect face,
  int cols,
  int rows,
  int seed,
) {
  final w = size.width;
  final cw = face.width / cols;
  final ch = face.height / rows;
  final pw = cw * 0.40;
  final ph = ch * 0.42;

  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final i = seed * 131 + row * 17 + col;
      if (_r(i, 71.3) < 0.36) continue; // dark window
      final centre = Offset(
        face.left + cw * (col + 0.5),
        face.top + ch * (row + 0.55),
      );
      final pane = Rect.fromCenter(center: centre, width: pw, height: ph);
      final a = 0.18 + 0.46 * _r(i, 72.7);
      if (a > 0.46) {
        canvas.drawRect(
          pane.inflate(pw * 0.55),
          Paint()
            ..color = _kWindow.withValues(alpha: a * 0.24)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.006)
            ..blendMode = BlendMode.plus,
        );
      }
      canvas.drawRect(pane, Paint()..color = _kWindow.withValues(alpha: a));
    }
  }
}

/// A course of stepped merlons along a parapet — the crenellation that tops
/// almost every wall in the tradition, and a row of crisp corners besides.
void _merlons(
  Canvas canvas,
  Size size,
  double left,
  double right,
  double topY,
  double baseY,
  Paint fill,
) {
  final mw = (right - left) /
      math.max(3, ((right - left) / (size.width * 0.026)).round());
  for (var x = left; x < right - mw * 0.5; x += mw * 2) {
    canvas.drawRect(
      Rect.fromLTRB(x, topY, math.min(x + mw, right), baseY),
      fill,
    );
  }
}

// ── 8. Far skyline ──────────────────────────────────────────────────────────
// A district away: lifted, cooler and smaller. Against a lit horizon distance
// means *lighter*, not darker, so this run is drawn in the hazy `_kFar` and
// gets no windows at all — detail belongs to the near plane. It exists to put
// one more measurable step of depth behind the mosque.
void _farSkyline(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final base = h * _kFarBaseY;
  final fill = Paint()..color = _kFar.withValues(alpha: 0.80);

  // Low blocks with flat or stepped tops, spaced deterministically.
  for (var i = 0; i < 16; i++) {
    final cx = w * (0.02 + 0.063 * i + 0.018 * _r(i, 33.1));
    final bw = w * (0.038 + 0.036 * _r(i, 34.5));
    final hgt = h * (0.018 + 0.030 * _r(i, 35.9));
    canvas.drawRect(
      Rect.fromLTRB(cx - bw / 2, base - hgt, cx + bw / 2, base),
      fill,
    );
    // Every third block gets a small parapet step, which is enough to break
    // the run's silhouette without asking for real detail at this distance.
    if (i % 3 == 0) {
      canvas.drawRect(
        Rect.fromLTRB(
            cx - bw * 0.22, base - hgt - h * 0.006, cx + bw * 0.22, base - hgt),
        fill,
      );
    }
  }

  // Three small domes and four slim minarets scattered through the run.
  for (final f in const [0.115, 0.455, 0.860]) {
    final cx = w * f;
    final r = w * 0.024;
    final springY = base - h * 0.020;
    canvas.drawPath(_onionPath(cx, r, springY, springY - h * 0.030), fill);
    // The drum has to be at least as wide as the dome's widest point (1.22r) or
    // the pair reads as a mushroom rather than as a building.
    canvas.drawRect(
      Rect.fromLTRB(cx - r * 1.24, springY, cx + r * 1.24, base),
      fill,
    );
  }
  for (final f in const [0.062, 0.325, 0.590, 0.930]) {
    final cx = w * f;
    // Wider than feels right for the distance: a 12px stick with a 6px cap
    // reads as a TV aerial, not a minaret.
    final bw = w * 0.017;
    final topY = base - h * (0.070 + 0.014 * _r((f * 100).round(), 37.3));
    canvas.drawRect(Rect.fromLTRB(cx - bw / 2, topY, cx + bw / 2, base), fill);
    canvas.drawRect(
      Rect.fromLTRB(
          cx - bw * 1.5, topY + h * 0.014, cx + bw * 1.5, topY + h * 0.019),
      fill,
    );
    canvas.drawPath(
      _onionPath(cx, bw * 0.62, topY, topY - h * 0.016),
      fill,
    );
  }

  // One haze veil over the far run, warmest at the ember. It pushes the plane
  // back and keeps it from competing with the near silhouette's blacks.
  //
  // RADIAL, not a rect with a horizontal gradient: that version had a hard top
  // edge, and an additive layer with a hard edge draws a visible seam clean
  // across the sky. A radial anchored on the ember fades out in every direction.
  final veilC = Offset(w * _kEmberX, base);
  canvas.drawCircle(
    veilC,
    w * 0.95,
    Paint()
      ..shader = ui.Gradient.radial(veilC, w * 0.95, [
        const Color(0xFFE09258).withValues(alpha: 0.085),
        const Color(0xFFB0748C).withValues(alpha: 0.030),
        const Color(0xFFA8708A).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.45,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );
}

/// An onion profile: bulges past its springline, then draws in to a point.
Path _onionPath(double cx, double r, double springY, double apexY) {
  final rise = springY - apexY;
  return Path()
    ..moveTo(cx - r, springY)
    ..cubicTo(
      cx - r * 1.22,
      springY - rise * 0.40,
      cx - r * 0.74,
      apexY + rise * 0.17,
      cx - r * 0.055,
      apexY,
    )
    ..lineTo(cx + r * 0.055, apexY)
    ..cubicTo(
      cx + r * 0.74,
      apexY + rise * 0.17,
      cx + r * 1.22,
      springY - rise * 0.40,
      cx + r,
      springY,
    )
    ..close();
}

/// A finial: a short mast with a crescent on top. Filled in silhouette and then
/// rim-traced, so it stays a hard little shape against a bright sky.
void _finial(Canvas canvas, Size size, double cx, double apexY, double scale) {
  final w = size.width, h = size.height;
  final fill = Paint()..color = _kNear;
  canvas.drawRect(
    Rect.fromLTWH(
      cx - w * 0.0018 * scale,
      apexY - h * 0.020 * scale,
      w * 0.0036 * scale,
      h * 0.021 * scale,
    ),
    fill,
  );
  final c = Offset(cx, apexY - h * 0.0255 * scale);
  final r = w * 0.010 * scale;
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(Rect.fromCircle(
      center: c.translate(r * 0.40, -r * 0.16),
      radius: r * 0.86,
    ));
  final crescent = Path.combine(ui.PathOperation.difference, outer, inner);
  canvas.drawPath(crescent, fill);
  _rimStroke(canvas, size, crescent, 0.50, weight: 0.0011);
}

// ── 9a. Town blocks ─────────────────────────────────────────────────────────
// The ordinary city either side of the mosque: parapeted blocks carrying grids
// of lit windows. Every block is kept outside x ∈ [0.30, 0.70] so no window
// ever sits behind the lantern; the centre of the frame belongs to the mosque's
// dark mass.
void _townBlocks(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final ground = h * _kGroundY;

  // (cxFrac, widthFrac, topYFrac, cols, rows)
  const blocks = <List<double>>[
    [0.048, 0.118, 0.664, 3, 5],
    [0.148, 0.088, 0.628, 2, 6],
    [0.228, 0.070, 0.690, 2, 3],
    [0.792, 0.074, 0.686, 2, 3],
    [0.868, 0.098, 0.646, 3, 5],
    [0.960, 0.108, 0.676, 3, 4],
  ];

  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    final cx = w * b[0];
    final bw = w * b[1];
    final topY = h * b[2];
    final rect = Rect.fromLTRB(cx - bw / 2, topY, cx + bw / 2, ground);

    canvas.drawRect(rect, _silhouette(size, topY));

    // Parapet: a thin cap band plus a merlon course standing on it.
    final capTop = topY - h * 0.005;
    canvas.drawRect(
      Rect.fromLTRB(rect.left - bw * 0.03, capTop, rect.right + bw * 0.03,
          topY + h * 0.004),
      Paint()..color = _kNear,
    );
    _merlons(canvas, size, rect.left, rect.right, capTop - h * 0.010, capTop,
        Paint()..color = _kNear);

    // Rim: the parapet's top edge, and the block's ember-facing vertical.
    final emberSide = cx / w < _kEmberX ? rect.right : rect.left;
    _rimStroke(
      canvas,
      size,
      Path()
        ..moveTo(rect.left - bw * 0.03, capTop)
        ..lineTo(rect.right + bw * 0.03, capTop)
        ..moveTo(emberSide, topY)
        ..lineTo(emberSide, ground),
      _rimAt(b[0], 0.34),
      weight: 0.0013,
    );

    _windowGrid(
      canvas,
      size,
      // Stops at the courtyard wall — panes drawn below it are occluded, and a
      // grid that runs off behind a wall spaces its rows wrong.
      Rect.fromLTRB(
        rect.left + bw * 0.14,
        topY + h * 0.014,
        rect.right - bw * 0.14,
        h * _kWallY - h * 0.006,
      ),
      b[3].round(),
      b[4].round(),
      i + 1,
    );
  }
}

// ── 9b. Minarets ────────────────────────────────────────────────────────────
// The tallest things in the frame and the scene's vertical rhythm. Detail is
// what stops a minaret being a stick: a tapering shaft with a string course, a
// corbelled gallery on brackets with a railing, an arcaded lantern stage that
// is genuinely LIT, a second smaller gallery, an onion cap and a finial.
void _minaret(Canvas canvas, Size size, double cxFrac, int seed) {
  final w = size.width, h = size.height;
  final cx = w * cxFrac;
  final ground = h * _kGroundY;

  final lowW = w * 0.042;
  final midW = w * 0.032;
  final upW = w * 0.030;

  final gallery1 = h * 0.436; // main balcony
  final stageTop = h * 0.340; // top of the lantern stage
  final gallery2 = h * 0.322; // small upper balcony
  final capY = h * 0.304;
  final apexY = h * 0.266;

  final fill = Paint()..color = _kNear;

  // Tapering shaft.
  final shaft = Path()
    ..moveTo(cx - lowW / 2, ground)
    ..lineTo(cx - midW / 2, gallery1)
    ..lineTo(cx + midW / 2, gallery1)
    ..lineTo(cx + lowW / 2, ground)
    ..close();
  canvas.drawPath(shaft, _silhouette(size, gallery1));

  // A string course a third of the way up — one crisp horizontal on a long
  // vertical, which is all it takes for the shaft to have scale.
  final courseY = h * 0.598;
  final courseHalf = lowW * 0.54;
  canvas.drawRect(
    Rect.fromLTRB(
        cx - courseHalf, courseY, cx + courseHalf, courseY + h * 0.006),
    fill,
  );

  // Tall slit windows up the shaft — three, crisp, warm and dim.
  for (var i = 0; i < 3; i++) {
    final y = ground - (ground - gallery1) * (0.20 + 0.26 * i);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, y),
        width: w * 0.006,
        height: h * 0.016,
      ),
      Paint()
        ..color =
            _kWindow.withValues(alpha: 0.26 + 0.18 * _r(seed * 7 + i, 41.9)),
    );
  }

  // Main gallery: corbel brackets, the slab itself, and a railing of ticks.
  final brackets = Path();
  for (var i = -2; i <= 2; i++) {
    final bx = cx + i * midW * 0.42;
    brackets
      ..moveTo(bx - midW * 0.16, gallery1 + h * 0.014)
      ..lineTo(bx, gallery1 + h * 0.001)
      ..lineTo(bx + midW * 0.16, gallery1 + h * 0.014)
      ..close();
  }
  canvas.drawPath(brackets, fill);
  final slab = Rect.fromLTRB(
    cx - midW * 1.15,
    gallery1 - h * 0.008,
    cx + midW * 1.15,
    gallery1 + h * 0.002,
  );
  canvas.drawRect(slab, fill);
  final rail = Paint()
    ..color = _kNear
    ..strokeWidth = w * 0.0016;
  for (var i = -4; i <= 4; i++) {
    final rx = cx + i * midW * 0.26;
    canvas.drawLine(
      Offset(rx, slab.top - h * 0.010),
      Offset(rx, slab.top),
      rail,
    );
  }
  canvas.drawRect(
    Rect.fromLTRB(
        slab.left, slab.top - h * 0.012, slab.right, slab.top - h * 0.0105),
    fill,
  );

  // Lantern stage: ONE lit pointed opening — the muezzin's storey is the single
  // place a minaret is genuinely bright, and at this scale the shaft is only
  // ~30px across, so three openings became a bundle of gold needles. One
  // properly proportioned arch reads as architecture; three slivers do not.
  canvas.drawRect(
    Rect.fromLTRB(cx - upW / 2, stageTop, cx + upW / 2, slab.top - h * 0.012),
    _silhouette(size, stageTop),
  );
  final stageBase = slab.top - h * 0.019;
  _litArch(
    canvas,
    size,
    _pointedArch(
      cx,
      upW * 0.36,
      stageBase,
      stageBase - h * 0.015,
      stageBase - h * 0.026,
    ),
    stageBase - h * 0.026,
    stageBase,
    0.58,
  );
  // A crisp sill under it. Without one the opening's foot dissolves into the
  // shaft and the whole thing reads as a flame rather than a lit window.
  canvas.drawRect(
    Rect.fromLTRB(
        cx - upW * 0.46, stageBase, cx + upW * 0.46, stageBase + h * 0.0035),
    fill,
  );

  // Upper gallery, then a short crowning drum, then the onion cap. The drum
  // matters: without it the cap floats a hair clear of the gallery slab, which
  // is the sort of small disconnect that reads as "drawn" rather than "built".
  canvas.drawRect(
    Rect.fromLTRB(cx - upW * 0.95, gallery2 - h * 0.006, cx + upW * 0.95,
        gallery2 + h * 0.002),
    fill,
  );
  canvas.drawRect(
    Rect.fromLTRB(cx - upW * 0.60, capY, cx + upW * 0.60, gallery2 - h * 0.005),
    fill,
  );
  // Wide and shallow: an onion cap taller than it is broad reads as a bullet.
  final cap = _onionPath(cx, upW * 0.80, capY, apexY);
  canvas.drawPath(cap, fill);

  // Rim: the ember catches one vertical of the shaft and the cap's profile;
  // the moon (upper right) puts a cool line down the other side.
  final emberSide = cxFrac < _kEmberX ? 1.0 : -1.0;
  _rimStroke(
    canvas,
    size,
    Path()
      ..moveTo(cx + emberSide * lowW / 2, ground)
      ..lineTo(cx + emberSide * midW / 2, gallery1)
      ..moveTo(slab.left, slab.top)
      ..lineTo(slab.right, slab.top),
    _rimAt(cxFrac, 0.40),
    weight: 0.0014,
  );
  _rimStroke(canvas, size, cap, _rimAt(cxFrac, 0.30), weight: 0.0013);
  // Moonlight down the right-hand edge — a second, cooler light source, which
  // is what stops the silhouette reading as flat cardboard.
  canvas.drawLine(
    Offset(cx + midW / 2, gallery1),
    Offset(cx + lowW / 2, ground),
    Paint()
      ..strokeWidth = w * 0.0012
      ..color = _kMoonRim.withValues(alpha: 0.16)
      ..blendMode = BlendMode.plus,
  );
  _finial(canvas, size, cx, apexY, 1.0);
}

// ── 9c. Grand mosque ────────────────────────────────────────────────────────
// The centrepiece, and deliberately the DARKEST mass in the frame: the lantern
// stands in front of it, so its job is to be a rich, detailed black rather than
// a bright thing. All its light is hairline — ribbing, keels, the drum arcade —
// with the prayer hall's own arcade dimmed through the centre three bays.
void _grandMosque(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w / 2;
  final ground = h * _kGroundY;
  final hallTop = h * _kHallTopY;
  final drumTop = h * _kDrumTopY;
  final apexY = h * _kDomeApexY;

  final hallHalf = w * _kHallHalf;
  final drumHalf = w * _kDrumHalf;
  final domeHalf = w * _kDomeHalf;

  // ── Prayer hall body ──
  final hall = Rect.fromLTRB(cx - hallHalf, hallTop, cx + hallHalf, ground);
  canvas.drawRect(hall, _silhouette(size, hallTop));

  // Cornice + merlon course along the hall roof.
  canvas.drawRect(
    Rect.fromLTRB(hall.left - w * 0.008, hallTop - h * 0.006,
        hall.right + w * 0.008, hallTop + h * 0.004),
    Paint()..color = _kNear,
  );
  _merlons(canvas, size, hall.left, hall.right, hallTop - h * 0.017,
      hallTop - h * 0.006, Paint()..color = _kNear);

  // ── Prayer-hall arcade ──
  // Nine bays. The three central bays are dimmed hard: that band of the frame
  // sits directly behind the lantern and has to stay quiet.
  // The arcade's foot is the courtyard wall's top, not the plaza: the wall
  // stands in front of it, so anything drawn below that line is simply thrown
  // away. Springing at 0.690 puts the whole head of every arch above the wall.
  const bays = 9;
  final bayW = (hallHalf * 2) / bays;
  final archBase = h * _kWallY;
  final archSpring = h * 0.690;
  final archApex = h * 0.660;
  for (var i = 0; i < bays; i++) {
    final bx = hall.left + bayW * (i + 0.5);
    final arch = _pointedArch(bx, bayW * 0.30, archBase, archSpring, archApex);
    final central = (i - (bays - 1) / 2).abs() <= 1;
    _litArch(
      canvas,
      size,
      arch,
      archApex,
      archBase,
      central ? 0.13 : 0.30 + 0.16 * _r(i, 43.7),
    );
  }
  // The impost line the whole arcade springs from — one crisp horizontal.
  _rimStroke(
    canvas,
    size,
    Path()
      ..moveTo(hall.left, archSpring)
      ..lineTo(hall.right, archSpring),
    0.16,
    weight: 0.0011,
  );

  // ── Half-domes flanking the drum, standing on the hall roof ──
  for (final s in const [-1.0, 1.0]) {
    final hx = cx + s * w * 0.162;
    final springY = hallTop - h * 0.002;
    final half = _onionPath(hx, w * 0.062, springY, springY - h * 0.070);
    canvas.drawPath(half, Paint()..color = _kNear);
    _rimStroke(canvas, size, half, _rimAt(hx / w, 0.26), weight: 0.0012);
  }

  // ── Drum ──
  final drum = Rect.fromLTRB(cx - drumHalf, drumTop, cx + drumHalf, hallTop);
  canvas.drawRect(drum, _silhouette(size, drumTop));
  // Seven arched drum windows. Warm but restrained — this band sits high enough
  // to be read as detail and low enough that it must not glare.
  const drumBays = 7;
  final dW = (drumHalf * 2) / drumBays;
  for (var i = 0; i < drumBays; i++) {
    final bx = drum.left + dW * (i + 0.5);
    final base = hallTop - h * 0.010;
    final arch =
        _pointedArch(bx, dW * 0.26, base, base - h * 0.026, base - h * 0.048);
    _litArch(canvas, size, arch, base - h * 0.048, base, 0.30);
  }
  // Cornice bands top and bottom of the drum.
  for (final y in [drumTop, hallTop - h * 0.004]) {
    canvas.drawRect(
      Rect.fromLTRB(
          drum.left - w * 0.006, y, drum.right + w * 0.006, y + h * 0.005),
      Paint()..color = _kNear,
    );
  }

  // ── Dome ──
  final dome = _onionPath(cx, domeHalf, drumTop + h * 0.004, apexY);
  canvas.drawPath(dome, Paint()..color = _kNear);

  // Ribbing: three meridian pairs drawn as crisp quadratics from the springline
  // to the crown. Faint, but they are what turn a black blob into a dome.
  final rib = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0013
    ..color = _kRim.withValues(alpha: 0.115)
    ..blendMode = BlendMode.plus;
  for (final f in const [0.30, 0.58, 0.82]) {
    for (final s in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx + s * domeHalf * f, drumTop + h * 0.004)
          ..quadraticBezierTo(
            cx + s * domeHalf * f * 0.94,
            apexY + (drumTop - apexY) * 0.34,
            cx + s * domeHalf * 0.035,
            apexY,
          ),
        rib,
      );
    }
  }
  // The crown ring where the ribs gather, and the dome's profile.
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(cx, apexY + h * 0.012),
      width: domeHalf * 0.44,
      height: h * 0.014,
    ),
    0,
    math.pi,
    false,
    rib,
  );
  _rimStroke(canvas, size, dome, 0.30, weight: 0.0016);
  _finial(canvas, size, cx, apexY, 1.35);
}

// ── 9d. Courtyard wall ──────────────────────────────────────────────────────
// A merloned perimeter wall running the full width, in front of everything
// built. It hides every building's foot in one clean line, gives the composition
// a continuous crisp horizontal, and — being unbroken and dark — keeps the band
// immediately under the lantern calm.
void _courtyardWall(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final wallTop = h * _kWallY;
  final ground = h * _kGroundY;
  final fill = Paint()..color = _kNear;

  canvas.drawRect(Rect.fromLTRB(0, wallTop, w, ground), fill);
  _merlons(canvas, size, 0, w, h * _kMerlonY, wallTop, fill);

  // Blind pointed niches along the wall, unlit — texture, not light.
  final niche = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0011
    ..color = _kRim.withValues(alpha: 0.085)
    ..blendMode = BlendMode.plus;
  final step = w * 0.062;
  for (var x = step * 0.5; x < w; x += step) {
    canvas.drawPath(
      _pointedArch(
        x,
        step * 0.20,
        ground - h * 0.003,
        wallTop + h * 0.014,
        wallTop + h * 0.006,
      ),
      niche,
    );
  }

  // The wall's lit top edge — the single longest crisp line in the scene.
  _rimStroke(
    canvas,
    size,
    Path()
      ..moveTo(0, wallTop)
      ..lineTo(w, wallTop),
    0.34,
    weight: 0.0013,
  );
}

// ── 10. Plaza ───────────────────────────────────────────────────────────────
// The foreground. Dark stone with perspective jointing, a reflected smear of
// the town's window light, and a gentle pool where the lantern stands. Values
// stay low throughout: the lantern brings its own warmth and the ground must
// not compete with it.
void _plaza(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final top = h * _kGroundY;

  canvas.drawRect(
    Rect.fromLTRB(0, top, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, top),
        Offset(0, h),
        const [
          Color(0xFF2A1B26), // damp stone right at the wall, catching the ember
          Color(0xFF150E19),
          Color(0xFF09070D),
          Color(0xFF030206), // effectively black by the bottom edge
        ],
        const [0.0, 0.18, 0.46, 0.86],
      ),
  );

  // A specular line where the plaza meets the wall — a wet-stone catchlight,
  // and the crisp horizontal that keeps the foreground from starting on a
  // gradient. Biased to the ember side so it never becomes a bar under the
  // lantern.
  canvas.drawRect(
    Rect.fromLTRB(0, top, w, top + h * 0.0016),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          _kRim.withValues(alpha: 0.10),
          _kRim.withValues(alpha: 0.34),
          _kRim.withValues(alpha: 0.09),
        ],
        const [0.0, _kEmberX, 1.0],
      )
      ..blendMode = BlendMode.plus,
  );

  // Perspective jointing: verticals converging on a vanishing point at the wall
  // line, horizontals spaced quadratically so they open up toward the viewer.
  // Deliberately sparse and very low contrast — a dense, even grid reads as a
  // game floor, and this plane's job is to be quietly *there* under the lantern.
  final vp = Offset(w * 0.5, top);
  final joint = Paint()
    ..strokeWidth = w * 0.0014
    ..color = Colors.white.withValues(alpha: 0.020);
  for (var i = -3; i <= 3; i++) {
    if (i == 0) continue;
    canvas.drawLine(vp, Offset(w * 0.5 + i * w * 0.62, h), joint);
  }
  for (var i = 1; i <= 4; i++) {
    final t = math.pow(i / 5.0, 1.9).toDouble();
    final y = top + (h - top) * t;
    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..strokeWidth = w * 0.0014
        ..color = Colors.white.withValues(alpha: 0.030 * (1 - t * 0.90)),
    );
  }

  // Reflected window light: short warm smears under the two town clusters,
  // strongest on the ember side. Reflections stretch and blur with distance
  // from the surface, so these fade fast and never reach the centre.
  for (final f in const [0.06, 0.15, 0.23, 0.79, 0.87, 0.96]) {
    final a = _rimAt(f, 0.16);
    canvas.drawRect(
      Rect.fromLTWH(w * f - w * 0.045, top, w * 0.09, h * 0.045),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, top + h * 0.045),
          [
            _kRim.withValues(alpha: a),
            _kRim.withValues(alpha: 0.0),
          ],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012)
        ..blendMode = BlendMode.plus,
    );
  }

  // The lantern's resting pool. Deliberately faint — the animated layer breathes
  // a little more warmth over it, and the lantern itself supplies the rest.
  final pool = Offset(w * 0.5, h * 0.790);
  canvas.drawCircle(
    pool,
    w * 0.44,
    Paint()
      ..shader = ui.Gradient.radial(pool, w * 0.44, [
        const Color(0xFFE9C88A).withValues(alpha: 0.075),
        const Color(0xFFE9C88A).withValues(alpha: 0.020),
        const Color(0xFFE9C88A).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.50,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );

  // A tight contact shadow so the lantern reads as standing, not floating.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.772),
      width: w * 0.34,
      height: h * 0.017,
    ),
    Paint()
      ..color = const Color(0xFF0A0710).withValues(alpha: 0.42)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035),
  );

  // Sink the very bottom of the frame. The plaza runs a quarter of the canvas
  // and there is nothing down there to look at, so it is allowed to go out —
  // which also pushes the eye back up to the lantern and the skyline.
  canvas.drawRect(
    Rect.fromLTRB(0, h * 0.86, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.86),
        Offset(0, h),
        [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.55),
        ],
      ),
  );
}

// ── 11. Vignette ────────────────────────────────────────────────────────────
void _vignette(Canvas canvas, Size size, double strength) {
  final c = Offset(size.width / 2, size.height * 0.52);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.radial(c, size.height * 0.64, [
        Colors.black.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: strength),
      ], const [
        0.60,
        1.0
      ]),
  );
}

// ── Animated: twinkle ───────────────────────────────────────────────────────
// 40 stars riding math.sin, drawn on salts the static field doesn't use so the
// two populations never collide. Six of them get the crisp sparkle instead of a
// disc — the sharp shapes are the ones worth animating.
void _twinkle(Canvas canvas, Size size, double phase) {
  final w = size.width;
  final floor = _skyFloor(size);

  for (var i = 0; i < 40; i++) {
    final x = _r(i, 81.3) * w;
    final y = _r(i, 82.7) * floor;
    final k = y / floor;
    final ext = 1.0 - 0.72 * k * k * k;
    final base = (0.26 + 0.50 * _r(i, 83.9)) * ext;
    final tw = 0.55 + 0.45 * math.sin(phase * 2 + i * 1.7);
    final rad = w * (0.0013 + 0.0022 * _r(i, 85.1));
    final a = (base * tw).clamp(0.0, 0.90);

    if (_r(i, 86.3) > 0.85) {
      _sparkle(canvas, Offset(x, y), rad * 4.4, a, _starColour(i + 500));
    } else {
      canvas.drawCircle(
        Offset(x, y),
        rad,
        Paint()
          ..color = _starColour(i + 300).withValues(alpha: a)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

// ── Animated: ground drift ──────────────────────────────────────────────────
// The warm pool on the plaza, breathing. One radial — the static plaza already
// carries the resting warmth, so this only has to add the movement.
void _groundDrift(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height;
  final breath = 0.5 + 0.5 * math.sin(phase);
  final c = Offset(w * 0.5, h * 0.780);
  final r = w * (0.46 + 0.012 * breath);
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = ui.Gradient.radial(c, r, [
        const Color(0xFFE7A24E).withValues(alpha: 0.085 + 0.030 * breath),
        const Color(0xFFE7A24E).withValues(alpha: 0.022),
        const Color(0xFFE7A24E).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.50,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );
}
