// Fajr Courtyard — the moment before sunrise, seen from inside a mosque
// courtyard. The emotional counterpart to Laylat Night: hope and beginning,
// tied to the app's daily muḥāsabah practice.
//
// Depth planes, back to front:
//   1. dawn sky        — deep indigo → violet → rose → peach → pale gold
//   2. khatam wash     — 3–4% geometric lattice, only in the dark upper sky
//   3. cloud wisps     — cool up high, warm and underlit near the horizon
//   4. horizon bloom   — the un-risen sun behind the architecture, bleeding up
//   5. far arcade      — hazier, lighter-walled, a whole courtyard away
//   6. minaret + dome  — offset LEFT so the centre stays clear for the lantern
//   7. near arcade     — the courtyard's near side: parapet, pointed arches,
//                        slender columns with capitals + bases, spandrel roundels
//   8. marble floor    — wet sheen, perspective jointing, mirrored arcade light
//   9. vignette        — seats the scene
//
// The lantern is warm gold and is centred on the stage (a 240pt medallion in a
// 360×680 frame → roughly y 0.32–0.68). Dawn is the hard case for that: the
// scene has to be bright and still leave the gold somewhere to read. Three
// things buy the contrast back:
//
//   · the horizon sits HIGH (near roofline at y 0.478), so the lantern's whole
//     lower half is backed by dark colonnade and dark marble, not by sky;
//   · the centre bay of the near arcade is an *opening* — `_nearBays` is odd
//     on purpose — so the gold sits against a near-black arch interior;
//   · `_dawnBias` pushes the brightness up and to the RIGHT (bloom at x 0.72),
//     cooling the pale-gold band back toward plum everywhere left of the sun.
//
// Change any of those three and check the composite again, not just the
// backdrop on its own.
//
// Fully self-contained: no shared helpers, no image assets, no RNG. Every
// position is a literal or derived from a fixed hash, so repaints are
// pixel-identical and the static layer can be raster-cached.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ── Public API ──────────────────────────────────────────────────────────────

/// Everything geometrically fixed. Painted once and raster-cached.
void paintFajrCourtyardStatic(Canvas canvas, Size size) {
  _sky(canvas, size);
  _skyLattice(canvas, size);
  _clouds(canvas, size);
  _dawnBias(canvas, size);
  _ghostCrescent(canvas, size);
  _horizonBloom(canvas, size);
  _farArcade(canvas, size);
  _distantMinaret(canvas, size);
  _minaret(canvas, size);
  _dome(canvas, size);
  _courtyardHaze(canvas, size);
  _nearArcade(canvas, size);
  _floor(canvas, size);
  _vignette(canvas, size, 0.36);
}

/// ONLY the pulse-driven pieces. [pulse] is 0..1, looping.
///
/// Two cheap things move: the last stars fading in and out, and the horizon
/// bloom breathing (a single extra radial). Nothing else.
void paintFajrCourtyardAnimated(Canvas canvas, Size size, double pulse) {
  final phase = pulse * 2 * math.pi;
  _lastStars(canvas, size, phase);
  _bloomBreath(canvas, size, phase);
}

// ── Scene constants ─────────────────────────────────────────────────────────
// All vertical positions are fractions of height, horizontal of width. Named
// once here so the layers stay in register when any one of them is tuned.

const double _farRoofY = 0.328; // parapet top, far arcade
const double _farCorniceY = 0.344;
const double _farApexY = 0.366;
const double _farSpringY = 0.412;
const double _farBaseY = 0.496; // foot hidden behind the near arcade

const double _roofY = 0.478; // parapet top, near arcade
const double _corniceY = 0.496;
const double _apexY = 0.520;
const double _springY = 0.576;
const double _baseY = 0.686; // where the arcade meets the marble

const int _nearBays = 7; // odd → the middle bay is centred on the lantern
const int _farBays = 13;

const double _sunX = 0.72; // the un-risen sun, offset RIGHT
const double _sunY = 0.336; // sitting just behind the far roofline

const Color _rim = Color(0xFFFFD9A0); // dawn rim-light on stone edges
const Color _stone = Color(0xFF2C2038); // near silhouette, top
const Color _stoneDeep = Color(0xFF1D1428); // near silhouette, bottom
const Color _mid = Color(0xFF473458); // minaret + dome (a plane further back)
const Color _haze = Color(0xFF4E3A5C); // far arcade (atmospheric)

// Small deterministic "random" in [0,1) from an index + salt. Same trick the
// house painter uses — no `Random()`, so frames are byte-identical.
double _r(int i, double salt) {
  final v = math.sin((i + 1) * 12.9898 + salt * 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

// ── 1. Dawn sky ─────────────────────────────────────────────────────────────
// The soul of the scene. Eight stops so the transition reads as *light*, not
// as a two-colour ramp: night holds on far longer than you'd expect, then the
// rose→peach→gold happens fast in the last 15% before the horizon.
void _sky(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        const [
          Color(0xFF0D1033), // deep indigo — night still holding
          Color(0xFF1A1848),
          Color(0xFF2E2258), // violet
          Color(0xFF4C2F62),
          Color(0xFF7B4568), // plum
          Color(0xFFB25E5D), // rose
          Color(0xFFE58B5D), // peach
          Color(0xFFFBDCA0), // pale gold at the horizon
          Color(0xFFEEB57E),
          Color(0xFFA96F5C), // (below the roofline — mostly occluded)
          Color(0xFF46343F),
        ],
        const [
          0.00,
          0.085,
          0.170,
          0.235,
          0.272,
          0.300,
          0.318,
          0.332,
          0.360,
          0.550,
          1.00,
        ],
      ),
  );
}

// ── 2. Khatam lattice ───────────────────────────────────────────────────────
// The design system's 5–8% decorative accent. Only in the dark upper third —
// below that the sky is too bright for it to read as anything but noise, and
// its alpha is ramped down so it dissolves rather than stopping abruptly.
void _skyLattice(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final step = w * 0.155;
  final fadeTo = h * 0.20;
  for (var gy = 0.0; gy < fadeTo; gy += step) {
    // 1 at the top of the sky → 0 at `fadeTo`.
    final t = (1.0 - gy / fadeTo).clamp(0.0, 1.0);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0015
      ..color = Colors.white.withValues(alpha: 0.055 * t);
    for (var gx = 0.0; gx < w + step; gx += step) {
      _miniStar(canvas, Offset(gx, gy), step * 0.34, p);
    }
  }
}

// Dawn does not arrive evenly across the sky — it arrives from where the sun
// is. Without this the pale-gold band runs the full width and the centre of
// the frame becomes the brightest thing in it, which is exactly where a warm
// gold lantern has to survive. So the bright band is cooled back toward deep
// plum everywhere left of the sun. Blurred, so it has no edge of its own.
void _dawnBias(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawRect(
    Rect.fromLTRB(-w * 0.1, h * 0.13, w * 1.1, h * 0.400),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          const Color(0xFF2A2054).withValues(alpha: 0.46),
          const Color(0xFF34215A).withValues(alpha: 0.34),
          const Color(0xFF4A2A56).withValues(alpha: 0.14),
          const Color(0xFF4A2A56).withValues(alpha: 0.0),
          const Color(0xFF3A2450).withValues(alpha: 0.10),
        ],
        const [0.0, 0.26, 0.52, _sunX, 1.0],
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.045),
  );
}

// An 8-point khatam rosette outline.
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

// ── 3. Cloud wisps ──────────────────────────────────────────────────────────
// Long, thin, heavily blurred ellipses. The two high ones stay cool violet;
// the two low ones are warm and get a bright underside line — clouds at fajr
// are lit from *below* by a sun that hasn't cleared the horizon yet.
void _clouds(Canvas canvas, Size size) {
  final w = size.width, h = size.height;

  void wisp(double cx, double cy, double rw, double rh, Color c, double a) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * cx, h * cy),
        width: w * rw,
        height: h * rh,
      ),
      Paint()
        ..color = c.withValues(alpha: a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.010),
    );
  }

  // Underside catch-light: a shorter, brighter sliver just below the wisp.
  void underlit(double cx, double cy, double rw, double a) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * cx, h * (cy + 0.006)),
        width: w * rw * 0.72,
        height: h * 0.005,
      ),
      Paint()
        ..color = _rim.withValues(alpha: a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.005)
        ..blendMode = BlendMode.plus,
    );
  }

  wisp(0.30, 0.128, 0.46, 0.010, const Color(0xFF6E5A86), 0.34);
  wisp(0.72, 0.160, 0.40, 0.008, const Color(0xFF7A6088), 0.30);
  wisp(0.38, 0.198, 0.62, 0.011, const Color(0xFF9A6479), 0.40);
  underlit(0.38, 0.198, 0.62, 0.10);
  wisp(0.16, 0.232, 0.50, 0.010, const Color(0xFFBE7268), 0.36);
  underlit(0.16, 0.232, 0.50, 0.13);
  wisp(0.76, 0.252, 0.46, 0.008, const Color(0xFFD48A6A), 0.34);
  underlit(0.76, 0.252, 0.46, 0.18);
}

// ── The last of the night's moon ────────────────────────────────────────────
// A waning crescent so pale it's nearly gone — the same "fading remnant" note
// as the stars, but static so the animated layer stays tiny.
void _ghostCrescent(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final c = Offset(w * 0.315, h * 0.058);
  final r = w * 0.048;
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(
      Rect.fromCircle(
        center: c.translate(-r * 0.52, -r * 0.16),
        radius: r * 0.92,
      ),
    );
  final crescent = Path.combine(ui.PathOperation.difference, outer, inner);
  canvas.drawPath(
    crescent,
    Paint()
      ..color = const Color(0xFFEDE3D2).withValues(alpha: 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.22)
      ..blendMode = BlendMode.plus,
  );
  canvas.drawPath(
    crescent,
    Paint()..color = const Color(0xFFE8DCC6).withValues(alpha: 0.22),
  );
}

// ── 4. Horizon bloom ────────────────────────────────────────────────────────
// The sun is BELOW the roofline and never drawn. What we get is the scatter:
// a broad radial centred on the far parapet plus a tall, soft ellipse of light
// bleeding straight up out of it.
void _horizonBloom(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final c = Offset(w * _sunX, h * _sunY);

  // Broad atmospheric scatter.
  canvas.drawCircle(
    c,
    w * 0.86,
    Paint()
      ..shader = ui.Gradient.radial(c, w * 0.86, [
        const Color(0xFFFFC98A).withValues(alpha: 0.26),
        const Color(0xFFFF9E6A).withValues(alpha: 0.10),
        const Color(0xFFFF8A5E).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.42,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );

  // Hot core hugging the horizon line. Squashed vertically (scale about the
  // centre) because the source is a *slice* of sky under the roofline, not a
  // point — that is what stops it reading as a lamp.
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(1.0, (h * 0.13) / (w * 0.72));
  canvas.translate(-c.dx, -c.dy);
  canvas.drawCircle(
    c,
    w * 0.36,
    Paint()
      ..shader = ui.Gradient.radial(c, w * 0.36, [
        const Color(0xFFFFE9C0).withValues(alpha: 0.40),
        const Color(0xFFFFE9C0).withValues(alpha: 0.0),
      ])
      ..blendMode = BlendMode.plus,
  );
  canvas.restore();

  // Light bleeding upward — a tall ellipse, not a circle, so it reads as a
  // shaft of dawn rather than a lamp.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * _sunX, h * 0.244),
      width: w * 0.74,
      height: h * 0.22,
    ),
    Paint()
      ..color = const Color(0xFFFFB477).withValues(alpha: 0.12)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.042)
      ..blendMode = BlendMode.plus,
  );
}

// ── Arch geometry ───────────────────────────────────────────────────────────
// One pointed (two-centred) arch, reused for every bay of both arcades. The
// second control point sits almost directly under the apex, which is what
// makes the crown come to a *point* instead of a dome.
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
      ySpring - rise * 0.62,
      cx - hw * 0.17,
      yApex + rise * 0.30,
      cx,
      yApex,
    )
    ..cubicTo(
      cx + hw * 0.17,
      yApex + rise * 0.30,
      cx + hw,
      ySpring - rise * 0.62,
      cx + hw,
      ySpring,
    )
    ..lineTo(cx + hw, yBase)
    ..close();
}

// ── 5. Far arcade ───────────────────────────────────────────────────────────
// A hazier colonnade a whole courtyard away: more bays (so it reads as
// further) and a lifted, desaturated silhouette — against a bright sky,
// distance means *lighter*, not darker.
//
// Its arches are open. You look straight through them at the dawn beyond, so
// the openings are a row of soft warm slots rather than dark voids — the near
// arcade owns the blacks. Fill them dark instead and the whole run reads as a
// line of tombstones sitting on the near parapet.
void _farArcade(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final bw = w / _farBays;
  final base = h * _farBaseY, spring = h * _farSpringY, apex = h * _farApexY;

  // Wall band, then the arches punched out of it.
  final wall = Path()..addRect(Rect.fromLTRB(0, h * _farCorniceY, w, base));
  final holes = Path();
  for (var i = 0; i < _farBays; i++) {
    final cx = (i + 0.5) * bw;
    // Slight, deterministic scale variation so the run isn't mechanical.
    final s = 1.0 + 0.035 * math.sin(i * 1.31);
    holes.addPath(
      _pointedArch(
          cx, bw * 0.34, base, spring, apex + (spring - apex) * (1 - s)),
      Offset.zero,
    );
  }
  final pierced = Path.combine(ui.PathOperation.difference, wall, holes);

  // Two veils over the openings, or they become a row of lightboxes.
  //  · vertical: light comes through the *top* of an arch; the bottom looks
  //    onto shaded ground beyond, so each slot must fade to dark at its foot.
  //    Without this they end flat on the near parapet like backlit panels.
  canvas.drawPath(
    holes,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, apex),
        Offset(0, h * _roofY),
        [
          const Color(0xFF3D2C48).withValues(alpha: 0.74),
          const Color(0xFF2F2239).withValues(alpha: 0.86),
          const Color(0xFF221930).withValues(alpha: 0.95),
        ],
        const [0.0, 0.45, 1.0],
      ),
  );
  //  · horizontal: only the bays near the sun are really alight.
  canvas.drawPath(
    holes,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          const Color(0xFF2C2140).withValues(alpha: 0.44),
          const Color(0xFF322544).withValues(alpha: 0.22),
          const Color(0xFF322544).withValues(alpha: 0.0),
          const Color(0xFF2C2140).withValues(alpha: 0.14),
        ],
        const [0.0, 0.34, _sunX, 1.0],
      ),
  );
  canvas.drawPath(
    pierced,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * _farCorniceY),
        Offset(0, base),
        [
          _haze.withValues(alpha: 0.90),
          const Color(0xFF3E2E4C).withValues(alpha: 0.96),
        ],
      ),
  );
  // Each opening gets a hairline of light where the arch meets the sky.
  canvas.drawPath(
    holes,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.0018
      ..color = _rim.withValues(alpha: 0.20)
      ..blendMode = BlendMode.plus,
  );
  // The sun side of the far wall catches a little more light.
  canvas.drawPath(
    pierced,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.2, 0),
        Offset(w * _sunX, 0),
        [
          _rim.withValues(alpha: 0.0),
          _rim.withValues(alpha: 0.10),
        ],
      )
      ..blendMode = BlendMode.plus,
  );

  // Cornice + a simple merlon run along the far parapet.
  canvas.drawRect(
    Rect.fromLTRB(0, h * _farRoofY, w, h * _farCorniceY),
    Paint()..color = _haze.withValues(alpha: 0.92),
  );
  // Dawn catching the top edge of the parapet.
  canvas.drawRect(
    Rect.fromLTRB(0, h * _farRoofY, w, h * _farRoofY + h * 0.0012),
    Paint()
      ..color = _rim.withValues(alpha: 0.22)
      ..blendMode = BlendMode.plus,
  );
}

// A small, very hazy minaret far right — balances the left-hand cluster and
// pushes the horizon back another plane.
void _distantMinaret(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w * 0.885;
  final bw = w * 0.020;
  final p = Paint()..color = _haze.withValues(alpha: 0.62);
  canvas.drawRect(
    Rect.fromLTRB(cx - bw / 2, h * 0.176, cx + bw / 2, h * _farRoofY),
    p,
  );
  canvas.drawRect(
    Rect.fromLTRB(cx - bw * 0.85, h * 0.212, cx + bw * 0.85, h * 0.222),
    p,
  );
  canvas.drawPath(
    Path()
      ..moveTo(cx - bw * 0.62, h * 0.176)
      ..quadraticBezierTo(cx, h * 0.144, cx + bw * 0.62, h * 0.176)
      ..close(),
    p,
  );
}

// A band of low dawn mist lying across the courtyard between the far arcade's
// foot and the near arcade's roofline. Cheap, but it is what makes the two
// colonnades sit in different *places* rather than on top of each other.
void _courtyardHaze(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  canvas.drawRect(
    Rect.fromLTRB(0, h * 0.392, w, h * _roofY + h * 0.004),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.392),
        Offset(0, h * _roofY),
        [
          const Color(0xFFFFD4A8).withValues(alpha: 0.0),
          const Color(0xFFFFC79A).withValues(alpha: 0.055),
          const Color(0xFFE8AC92).withValues(alpha: 0.02),
        ],
        const [0.0, 0.62, 1.0],
      )
      ..blendMode = BlendMode.plus,
  );
}

// ── 6. Minaret ──────────────────────────────────────────────────────────────
// Offset well to the LEFT. Tapering shaft, corbelled balcony, upper stage,
// onion cap, finial. Rim-lit down its right edge because the sun is right.
void _minaret(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w * 0.128;
  final fill = Paint()..color = _mid;
  final rimP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0035
    ..color = _rim.withValues(alpha: 0.40)
    ..blendMode = BlendMode.plus;

  // Lower shaft: wider at the foot, tapering to the balcony.
  final lowW = w * 0.052, midW = w * 0.040;
  final balconyY = h * 0.212;
  final shaft = Path()
    ..moveTo(cx - lowW / 2, h * 0.50)
    ..lineTo(cx - midW / 2, balconyY)
    ..lineTo(cx + midW / 2, balconyY)
    ..lineTo(cx + lowW / 2, h * 0.50)
    ..close();
  canvas.drawPath(shaft, fill);
  canvas.drawLine(
    Offset(cx + midW / 2, balconyY),
    Offset(cx + lowW / 2, h * 0.50),
    rimP,
  );

  // Corbel course + balcony slab.
  canvas.drawPath(
    Path()
      ..moveTo(cx - midW * 0.62, balconyY + h * 0.012)
      ..lineTo(cx - midW * 0.95, balconyY + h * 0.002)
      ..lineTo(cx + midW * 0.95, balconyY + h * 0.002)
      ..lineTo(cx + midW * 0.62, balconyY + h * 0.012)
      ..close(),
    fill,
  );
  final slab = Rect.fromLTRB(
    cx - midW * 0.98,
    balconyY - h * 0.010,
    cx + midW * 0.98,
    balconyY + h * 0.002,
  );
  canvas.drawRect(slab, fill);
  canvas.drawLine(slab.topRight, slab.bottomRight, rimP);
  canvas.drawLine(
    Offset(slab.left, slab.top),
    Offset(slab.right, slab.top),
    Paint()
      ..strokeWidth = w * 0.0025
      ..color = _rim.withValues(alpha: 0.28)
      ..blendMode = BlendMode.plus,
  );

  // Upper stage.
  final upW = w * 0.030;
  final capY = h * 0.118;
  canvas.drawRect(
    Rect.fromLTRB(cx - upW / 2, capY, cx + upW / 2, balconyY - h * 0.010),
    fill,
  );
  canvas.drawLine(
    Offset(cx + upW / 2, capY),
    Offset(cx + upW / 2, balconyY - h * 0.010),
    rimP,
  );

  // Onion cap + finial.
  final cap = Path()
    ..moveTo(cx - upW * 0.72, capY)
    ..cubicTo(
      cx - upW * 0.86,
      capY - h * 0.012,
      cx - upW * 0.40,
      capY - h * 0.030,
      cx,
      capY - h * 0.036,
    )
    ..cubicTo(
      cx + upW * 0.40,
      capY - h * 0.030,
      cx + upW * 0.86,
      capY - h * 0.012,
      cx + upW * 0.72,
      capY,
    )
    ..close();
  canvas.drawPath(cap, fill);
  canvas.drawPath(cap, rimP);
  canvas.drawRect(
    Rect.fromLTWH(cx - w * 0.0022, h * 0.072, w * 0.0044, h * 0.010),
    fill,
  );
  _tinyCrescent(canvas, Offset(cx, h * 0.0665), w * 0.011);
}

// ── Dome ────────────────────────────────────────────────────────────────────
// Sits between the minaret and the centre, still comfortably left of the
// lantern's column. Drum, ribbed onion dome, finial.
void _dome(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final cx = w * 0.288;
  final r = w * 0.090;
  final springY = h * 0.352;
  final apexY = h * 0.272;
  final fill = Paint()..color = _mid;
  final rimP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0035
    ..color = _rim.withValues(alpha: 0.38)
    ..blendMode = BlendMode.plus;

  // Drum below the dome, running down behind the near arcade.
  canvas.drawRect(
    Rect.fromLTRB(cx - r * 0.86, springY, cx + r * 0.86, h * 0.50),
    fill,
  );

  // Onion profile: bulges past the drum, then draws in to a point.
  final dome = Path()
    ..moveTo(cx - r, springY)
    ..cubicTo(
      cx - r * 1.20,
      springY - (springY - apexY) * 0.42,
      cx - r * 0.72,
      apexY + (springY - apexY) * 0.16,
      cx - r * 0.10,
      apexY,
    )
    ..lineTo(cx + r * 0.10, apexY)
    ..cubicTo(
      cx + r * 0.72,
      apexY + (springY - apexY) * 0.16,
      cx + r * 1.20,
      springY - (springY - apexY) * 0.42,
      cx + r,
      springY,
    )
    ..close();
  canvas.drawPath(dome, fill);
  canvas.drawPath(dome, rimP);

  // Two faint ribs — enough to say "dome", not enough to draw the eye.
  final ribP = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0018
    ..color = _rim.withValues(alpha: 0.13)
    ..blendMode = BlendMode.plus;
  for (final f in const [0.36, 0.68]) {
    canvas.drawPath(
      Path()
        ..moveTo(cx + r * f, springY)
        ..quadraticBezierTo(
          cx + r * f * 0.86,
          apexY + (springY - apexY) * 0.34,
          cx + r * 0.04,
          apexY,
        ),
      ribP,
    );
  }

  // Base moulding + finial.
  canvas.drawRect(
    Rect.fromLTRB(cx - r * 1.02, springY, cx + r * 1.02, springY + h * 0.007),
    fill,
  );
  canvas.drawRect(
    Rect.fromLTWH(cx - w * 0.0022, apexY - h * 0.016, w * 0.0044, h * 0.017),
    fill,
  );
  _tinyCrescent(canvas, Offset(cx, apexY - h * 0.0205), w * 0.011);
}

void _tinyCrescent(Canvas canvas, Offset c, double r) {
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(
      Rect.fromCircle(
        center: c.translate(r * 0.42, -r * 0.16),
        radius: r * 0.86,
      ),
    );
  canvas.drawPath(
    Path.combine(ui.PathOperation.difference, outer, inner),
    Paint()..color = _mid,
  );
}

// ── 7. Near arcade ──────────────────────────────────────────────────────────
// The courtyard's far side, and the most load-bearing layer for the lantern:
// with an odd bay count the middle bay is an *opening*, so the lantern is
// silhouetted against a near-black arch interior rather than against the sky.
void _nearArcade(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final bw = w / _nearBays;
  final hw = bw * 0.40; // → piers are bw * 0.20 wide: slender columns
  final base = h * _baseY, spring = h * _springY, apex = h * _apexY;
  final cornice = h * _corniceY;

  // (a) Interior first — a deep, cold void that warms very slightly at the
  //     floor where dawn light spills in under the arches.
  canvas.drawRect(
    Rect.fromLTRB(0, cornice, w, base),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, cornice),
        Offset(0, base),
        const [Color(0xFF120C1E), Color(0xFF1A1226), Color(0xFF2A1D2C)],
        const [0.0, 0.55, 1.0],
      ),
  );

  // (b) The pierced wall on top of it.
  final wall = Path()..addRect(Rect.fromLTRB(0, cornice, w, base));
  final holes = Path();
  final apexOf = <double>[];
  for (var i = 0; i < _nearBays; i++) {
    final cx = (i + 0.5) * bw;
    // Slight deterministic scale variation, ±3% of the rise.
    final a = apex + (spring - apex) * 0.03 * math.sin(i * 2.11 + 0.7);
    apexOf.add(a);
    holes.addPath(_pointedArch(cx, hw, base, spring, a), Offset.zero);
  }
  final pierced = Path.combine(ui.PathOperation.difference, wall, holes);
  canvas.drawPath(
    pierced,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, cornice),
        Offset(0, base),
        const [_stone, _stoneDeep],
      ),
  );

  // (c) A warm keel-line tracing every arch: the dawn behind the colonnade
  //     licking around the stone. Brighter on the bays nearer the sun.
  for (var i = 0; i < _nearBays; i++) {
    final cx = (i + 0.5) * bw;
    final d = ((cx / w) - _sunX).abs();
    final a = (0.34 - d * 0.36).clamp(0.06, 0.34);
    canvas.drawPath(
      _pointedArch(cx, hw, base, spring, apexOf[i]),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.0028
        ..color = _rim.withValues(alpha: a)
        ..blendMode = BlendMode.plus,
    );
  }

  // (d) Capitals, bases and spandrel roundels on every pier. Small, but they
  //     are the difference between "arch shapes" and "architecture".
  final pierW = bw - 2 * hw;
  final fill = Paint()..color = _stoneDeep;
  for (var i = 0; i <= _nearBays; i++) {
    final px = i * bw;
    // Capital.
    canvas.drawRect(
      Rect.fromLTRB(
        px - pierW * 0.86,
        spring - h * 0.007,
        px + pierW * 0.86,
        spring + h * 0.004,
      ),
      fill,
    );
    // Base block.
    canvas.drawRect(
      Rect.fromLTRB(
        px - pierW * 0.80,
        base - h * 0.013,
        px + pierW * 0.80,
        base,
      ),
      fill,
    );
    // Spandrel roundel, only on interior piers.
    if (i > 0 && i < _nearBays) {
      canvas.drawCircle(
        Offset(px, cornice + h * 0.019),
        bw * 0.085,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.0018
          ..color = _rim.withValues(alpha: 0.14)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  // (d2) String course: one lit line under the cornice, which is all the
  //      spandrel band needs to stop reading as a flat slab.
  canvas.drawRect(
    Rect.fromLTRB(0, cornice + h * 0.0055, w, cornice + h * 0.0070),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          _rim.withValues(alpha: 0.04),
          _rim.withValues(alpha: 0.17),
          _rim.withValues(alpha: 0.06),
        ],
        const [0.0, _sunX, 1.0],
      )
      ..blendMode = BlendMode.plus,
  );

  // (e) Cornice band + merlon run along the near parapet.
  canvas.drawRect(
    Rect.fromLTRB(0, h * _roofY, w, cornice),
    Paint()..color = _stone,
  );
  final mw = w * 0.026;
  for (var x = mw * 0.35; x < w; x += mw * 2.0) {
    canvas.drawRect(
      Rect.fromLTWH(x, h * _roofY - h * 0.011, mw, h * 0.011),
      Paint()..color = _stone,
    );
  }
  // Dawn on the parapet's top edge — the brightest single line in the scene,
  // and it sits well above the lantern so it never competes.
  canvas.drawRect(
    Rect.fromLTRB(0, h * _roofY, w, h * _roofY + h * 0.0015),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          _rim.withValues(alpha: 0.10),
          _rim.withValues(alpha: 0.42),
          _rim.withValues(alpha: 0.16),
        ],
        const [0.0, _sunX, 1.0],
      )
      ..blendMode = BlendMode.plus,
  );
}

// ── 8. Wet marble courtyard ─────────────────────────────────────────────────
// The foreground plane. Brightest right at the arcade's foot (a wet floor
// mirrors the bright sky just above the horizon) and falling away toward the
// viewer, with perspective jointing, a mirrored smear of the arcade's warm
// light, and a calm pool where the lantern stands.
void _floor(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final top = h * _baseY;

  // (a) Slab.
  canvas.drawRect(
    Rect.fromLTRB(0, top, w, h),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, top),
        Offset(0, h),
        const [
          Color(0xFF56404F), // wet stone mirroring the horizon
          Color(0xFF3E2F44),
          Color(0xFF2A2038),
          Color(0xFF191322),
          Color(0xFF100C18),
        ],
        const [0.0, 0.10, 0.30, 0.66, 1.0],
      ),
  );

  // (b) Perspective jointing. Lines converge on a vanishing point sitting on
  //     the horizon, and the horizontals space out as they come forward.
  final vp = Offset(w * 0.5, top);
  final joint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.0016
    ..color = Colors.white.withValues(alpha: 0.035);
  for (var i = -5; i <= 5; i++) {
    if (i == 0) continue;
    canvas.drawLine(vp, Offset(w * 0.5 + i * w * 0.42, h), joint);
  }
  for (var i = 1; i <= 6; i++) {
    // Quadratic spacing → depth.
    final t = math.pow(i / 6.0, 1.9).toDouble();
    final y = top + (h - top) * t;
    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..strokeWidth = w * 0.0016
        ..color = Colors.white.withValues(alpha: 0.045 * (1 - t * 0.85)),
    );
  }

  // (c) Specular sheen: a tight band immediately under the arcade, which is
  //     what actually sells "wet". Weighted toward the sun side so it does not
  //     become a bright bar running under the lantern.
  canvas.drawRect(
    Rect.fromLTRB(0, top, w, top + h * 0.016),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, top),
        Offset(0, top + h * 0.016),
        [
          const Color(0xFFFFD3A0).withValues(alpha: 0.09),
          const Color(0xFFFFD3A0).withValues(alpha: 0.0),
        ],
      )
      ..blendMode = BlendMode.plus,
  );
  canvas.drawRect(
    Rect.fromLTRB(0, top, w, top + h * 0.016),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [
          const Color(0xFFFFC28A).withValues(alpha: 0.0),
          const Color(0xFFFFC28A).withValues(alpha: 0.13),
          const Color(0xFFFFC28A).withValues(alpha: 0.02),
        ],
        const [0.30, _sunX, 1.0],
      )
      ..blendMode = BlendMode.plus,
  );

  // (d) Mirrored arcade light: one soft vertical smear under each pier, warm
  //     and strongest on the sun side. Reflections stretch and blur with
  //     distance from the surface, so these fade fast.
  final bw = w / _nearBays;
  for (var i = 0; i <= _nearBays; i++) {
    final px = i * bw;
    final d = ((px / w) - _sunX).abs();
    final a = (0.15 - d * 0.20).clamp(0.02, 0.15);
    canvas.drawRect(
      Rect.fromLTWH(px - bw * 0.09, top, bw * 0.18, h * 0.048),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, top + h * 0.048),
          [
            _rim.withValues(alpha: a),
            _rim.withValues(alpha: 0.0),
          ],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.010)
        ..blendMode = BlendMode.plus,
    );
  }

  // (e) The sun's reflection: a long warm column under the bloom.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * _sunX, top + h * 0.050),
      width: w * 0.26,
      height: h * 0.11,
    ),
    Paint()
      ..color = const Color(0xFFFFAE70).withValues(alpha: 0.13)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055)
      ..blendMode = BlendMode.plus,
  );

  // (f) A faint scatter of stone-grain flecks so the marble isn't a flat ramp.
  for (var i = 0; i < 40; i++) {
    final x = _r(i, 4.1) * w;
    final ty = _r(i, 7.3);
    final y = top + (h - top) * (ty * ty); // clustered near the horizon
    canvas.drawCircle(
      Offset(x, y),
      w * (0.0008 + 0.0016 * _r(i, 9.7)),
      Paint()..color = Colors.white.withValues(alpha: 0.05 + 0.05 * _r(i, 2.2)),
    );
  }

  // (g) The lantern's pool. Deliberately gentle — it grounds the lantern
  //     without lifting the floor's value enough to swallow warm gold.
  final pool = Offset(w * 0.5, h * 0.752);
  canvas.drawCircle(
    pool,
    w * 0.44,
    Paint()
      ..shader = ui.Gradient.radial(pool, w * 0.44, [
        const Color(0xFFE9C88A).withValues(alpha: 0.11),
        const Color(0xFFE9C88A).withValues(alpha: 0.03),
        const Color(0xFFE9C88A).withValues(alpha: 0.0),
      ], const [
        0.0,
        0.5,
        1.0
      ])
      ..blendMode = BlendMode.plus,
  );
  // A tight contact shadow so the lantern reads as standing, not floating.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.722),
      width: w * 0.34,
      height: h * 0.018,
    ),
    Paint()
      ..color = const Color(0xFF150F1C).withValues(alpha: 0.34)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035),
  );
}

// ── 9. Vignette ─────────────────────────────────────────────────────────────
void _vignette(Canvas canvas, Size size, double strength) {
  final c = Offset(size.width / 2, size.height * 0.54);
  canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..shader = ui.Gradient.radial(c, size.height * 0.62, [
        Colors.black.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: strength),
      ], const [
        0.58,
        1.0
      ]),
  );
}

// ── Animated: the last stars ────────────────────────────────────────────────
// Five (plus one faint sixth) fixed positions high in the sky, each fading on
// its own phase offset. Their base alpha also falls off with height, so the
// lower ones are already almost lost to the dawn.
const List<Offset> _starPos = [
  Offset(0.085, 0.048),
  Offset(0.455, 0.112),
  Offset(0.560, 0.038),
  Offset(0.648, 0.136),
  Offset(0.862, 0.074),
  Offset(0.752, 0.192),
];

void _lastStars(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height;
  for (var i = 0; i < _starPos.length; i++) {
    final p = _starPos[i];
    final o = Offset(w * p.dx, h * p.dy);
    // Dawn is eating them from the bottom up.
    final height = (1.0 - p.dy / 0.22).clamp(0.18, 1.0);
    final base = (0.54 + 0.34 * _r(i, 3.7)) * height;
    final fade = 0.42 + 0.58 * math.sin(phase + i * 1.27);
    final a = (base * fade).clamp(0.0, 0.85);
    final rad = w * (0.0022 + 0.0026 * _r(i, 5.9));

    // Soft bloom under every star.
    canvas.drawCircle(
      o,
      rad * 4.0,
      Paint()
        ..shader = ui.Gradient.radial(o, rad * 4.0, [
          const Color(0xFFFDF6E4).withValues(alpha: a * 0.35),
          const Color(0xFFFDF6E4).withValues(alpha: 0.0),
        ])
        ..blendMode = BlendMode.plus,
    );
    // The two brightest get a four-point sparkle.
    if (i == 0 || i == 4) {
      _sparkle(canvas, o, rad * 4.6, a);
    } else {
      canvas.drawCircle(
        o,
        rad,
        Paint()
          ..color = const Color(0xFFFDF6E4).withValues(alpha: a)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

void _sparkle(Canvas canvas, Offset o, double r, double a) {
  final p = Paint()
    ..color = const Color(0xFFFDF6E4).withValues(alpha: a)
    ..blendMode = BlendMode.plus;
  canvas.drawPath(
    Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 0.22, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 0.22, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close(),
    p,
  );
  canvas.drawCircle(o, r * 0.15, p);
}

// ── Animated: the bloom breathing ───────────────────────────────────────────
// One extra radial over the horizon that warms and cools very slowly. Drawn
// after the static layer, so it doubles as the atmospheric scatter sitting in
// *front* of the colonnade. Kept far from centre-lower so the lantern is safe.
void _bloomBreath(Canvas canvas, Size size, double phase) {
  final w = size.width, h = size.height;
  final c = Offset(w * _sunX, h * (_sunY + 0.006));
  final breath = 0.5 + 0.5 * math.sin(phase);
  canvas.drawCircle(
    c,
    w * (0.50 + 0.02 * breath),
    Paint()
      ..shader = ui.Gradient.radial(c, w * (0.50 + 0.02 * breath), [
        const Color(0xFFFFC98A).withValues(alpha: 0.06 + 0.05 * breath),
        const Color(0xFFFFB477).withValues(alpha: 0.0),
      ])
      ..blendMode = BlendMode.plus,
  );
}
