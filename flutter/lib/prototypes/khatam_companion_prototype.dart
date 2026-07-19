// Illuminated Khatam companion — STANDALONE PROTOTYPE.
//
// Proves the "code-drawn, free, Claude-controllable, premium" pipeline from
// docs/superpowers/specs/2026-07-18-streaks-and-companion-research.md §7: a
// non-figurative Islamic geometric companion whose light reflects a streak
// state, drawn entirely in a CustomPainter (no asset files, no Rive/Lottie, no
// image generator). The SAME painter renders the live in-app animation AND the
// static home-screen widget frame (bottom row) — one source of truth.
//
// RUN IT DIRECTLY (own entrypoint — does not touch the app / Supabase / env):
//   flutter run -d <device_id> -t lib/prototypes/khatam_companion_prototype.dart
//
// The companion "lights up from the centre outward" as the streak grows, rests
// (dormant) on a lapse — never breaks — and gains a soft shield halo when a
// streak-freeze protects it. Tap the state chips or drag the slider to explore.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() => runApp(const _KhatamPrototypeApp());

// ── Brand palette (Sakina design system) ─────────────────────────────────────
const _bgCenter = Color(0xFF124A34); // deep emerald (sacred canvas centre)
const _bgEdge = Color(0xFF062017); // near-black emerald
const _gold = Color(0xFFC8985E); // warm matte gold
const _goldBright = Color(0xFFF0D8A8); // lit gold
const _amber = Color(0xFFE8A154);
const _shield = Color(0xFFAFD8EC); // soft blue-silver (protected)
const _ghost = Color(0xFF3C4E42); // unlit "template" lines

/// The five streak states the companion expresses.
enum KhatamState { dormant, dim, glowing, fullyLit, protected }

extension _KhatamStateInfo on KhatamState {
  String get label => switch (this) {
        KhatamState.dormant => 'Dormant',
        KhatamState.dim => 'Dim',
        KhatamState.glowing => 'Glowing',
        KhatamState.fullyLit => 'Fully lit',
        KhatamState.protected => 'Protected',
      };

  /// What each state means in streak terms (shown under the preview).
  String get meaning => switch (this) {
        KhatamState.dormant => 'lapsed — resting, not lost',
        KhatamState.dim => 'streak building (day 1–3)',
        KhatamState.glowing => 'steady streak',
        KhatamState.fullyLit => 'strong streak',
        KhatamState.protected => 'a freeze is protecting you',
      };

  /// Target illumination 0→1 (how much of the pattern is lit).
  double get illumination => switch (this) {
        KhatamState.dormant => 1.0, // fully formed, but the light is asleep
        KhatamState.dim => 0.42,
        KhatamState.glowing => 0.72,
        KhatamState.fullyLit => 1.0,
        KhatamState.protected => 1.0,
      };

  /// Target glow strength 0→1.
  double get glow => switch (this) {
        KhatamState.dormant => 0.0,
        KhatamState.dim => 0.22,
        KhatamState.glowing => 0.5,
        KhatamState.fullyLit => 0.9,
        KhatamState.protected => 0.9,
      };

  bool get isDormant => this == KhatamState.dormant;
  bool get isProtected => this == KhatamState.protected;
}

class _KhatamPrototypeApp extends StatelessWidget {
  const _KhatamPrototypeApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: const _KhatamPrototypeScreen(),
      );
}

class _KhatamPrototypeScreen extends StatefulWidget {
  const _KhatamPrototypeScreen();
  @override
  State<_KhatamPrototypeScreen> createState() => _KhatamPrototypeScreenState();
}

class _KhatamPrototypeScreenState extends State<_KhatamPrototypeScreen>
    with TickerProviderStateMixin {
  KhatamState _state = KhatamState.glowing;
  bool _manual = false;
  double _manualIllumination = 0.72;

  // Eased transition of illumination + glow when the state changes.
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..value = 1;
  double _fromIllum = KhatamState.glowing.illumination;
  double _fromGlow = KhatamState.glowing.glow;

  // Continuous gentle breathing for the lit states.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  /// The GPU glow-field shader (loaded async; null until ready → bloom still works).
  ui.FragmentShader? _glowShader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/khatam_glow.frag');
      if (mounted) setState(() => _glowShader = program.fragmentShader());
    } catch (e) {
      debugPrint('khatam glow shader failed to load: $e');
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _select(KhatamState s) {
    setState(() {
      _fromIllum = _currentIllumination;
      _fromGlow = _currentGlow;
      _state = s;
      _manual = false;
    });
    _transition.forward(from: 0);
  }

  double get _currentIllumination {
    final t = Curves.easeOutCubic.transform(_transition.value);
    return ui.lerpDouble(_fromIllum, _state.illumination, t)!;
  }

  double get _currentGlow {
    final t = Curves.easeOutCubic.transform(_transition.value);
    return ui.lerpDouble(_fromGlow, _state.glow, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [_bgCenter, _bgEdge],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text('Khatam companion — code-drawn prototype',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              // ── The live companion ──
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_transition, _pulse]),
                    builder: (context, _) {
                      final illum =
                          _manual ? _manualIllumination : _currentIllumination;
                      final glow = _manual ? 0.7 : _currentGlow;
                      return SizedBox(
                        width: 300,
                        height: 300,
                        child: CustomPaint(
                          painter: KhatamPainter(
                            illumination: illum,
                            glow: glow,
                            dormant: _state.isDormant && !_manual,
                            protected: _state.isProtected && !_manual,
                            // Continuous phase drives the ambient shader + sweep.
                            pulse: _pulse.value,
                            ambientShader: _glowShader,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ── State chips ──
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final s in KhatamState.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _state == s && !_manual,
                      onSelected: (_) => _select(s),
                      selectedColor: _gold,
                      labelStyle: TextStyle(
                        color: (_state == s && !_manual)
                            ? Colors.black87
                            : Colors.white70,
                        fontSize: 12.5,
                      ),
                      backgroundColor: Colors.white10,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  _manual
                      ? 'manual illumination'
                      : '${_state.label} — ${_state.meaning}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              // ── Manual illumination slider ──
              Row(
                children: [
                  const SizedBox(width: 16),
                  const Text('illumination',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: _manualIllumination,
                      activeColor: _amber,
                      onChanged: (v) => setState(() {
                        _manual = true;
                        _manualIllumination = v;
                      }),
                    ),
                  ),
                ],
              ),
              // ── Widget frame preview (what the home-screen widget shows) ──
              const _WidgetFramePreview(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottom row: the SAME painter, rendered static per streak state on a
/// widget-sized card — i.e. exactly the pre-rendered PNG frames the iOS/Android
/// home-screen widget would display (widgets can't run the live animation).
class _WidgetFramePreview extends StatelessWidget {
  const _WidgetFramePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Home-screen widget frame per state (static, pre-rendered)',
            style: TextStyle(color: Colors.white38, fontSize: 10.5)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final entry in const [
                (KhatamState.dormant, '0'),
                (KhatamState.dim, '2'),
                (KhatamState.glowing, '9'),
                (KhatamState.fullyLit, '30'),
                (KhatamState.protected, '30'),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _WidgetCard(state: entry.$1, streak: entry.$2),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({required this.state, required this.streak});
  final KhatamState state;
  final String streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.0,
          colors: [Color(0xFF0F3E2C), Color(0xFF07231A)],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: KhatamPainter(
                illumination: state.illumination,
                glow: state.glow * 0.9,
                dormant: state.isDormant,
                protected: state.isProtected,
                pulse: 0,
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 6,
            child: Row(
              children: [
                Text(streak,
                    style: TextStyle(
                        color: state.isDormant ? Colors.white38 : _goldBright,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                Icon(Icons.local_fire_department,
                    size: 13,
                    color: state.isDormant ? Colors.white24 : _amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── The painter — the whole companion, in code ───────────────────────────────

/// Draws an 8-fold khatam medallion that fills with light from the centre
/// outward. [illumination] 0→1 reveals five concentric layers (seed → inner
/// octagon → spokes → 8-point star → outer frame), each with a "draw-on" stroke
/// via PathMetric. [glow] blooms the lit strokes (blur + gold gradient).
/// [dormant] renders the full form muted + unlit. [protected] adds a soft shield
/// halo. [pulse] 0→1 gently breathes the glow on the lit states.
class KhatamPainter extends CustomPainter {
  KhatamPainter({
    required this.illumination,
    required this.glow,
    required this.dormant,
    required this.protected,
    required this.pulse,
    this.ambientShader,
  });

  final double illumination;
  final double glow;
  final bool dormant;
  final bool protected;
  final double pulse;

  /// Optional GPU glow-field shader (khatam_glow.frag). Null → skipped (the
  /// blur-bloom below still renders). Only the ONE live medallion passes it, so
  /// its uniforms are never contended by another painter in the same frame.
  final ui.FragmentShader? ambientShader;

  static const int _layers = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = pulse * 2 * math.pi;

    // 0) Ambient GPU glow field (additive) — a breathing gold aura behind it.
    final shader = ambientShader;
    if (shader != null && !dormant) {
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, phase)
        ..setFloat(3, (0.35 + 0.65 * glow).clamp(0.0, 1.0));
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.plus,
      );
    }

    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.44;
    canvas.translate(c.dx, c.dy);

    final paths = _buildLayers(r);
    final breath = 1.0 + (pulse - 0.5) * 0.28;
    final g = (glow * breath).clamp(0.0, 1.2);

    // Protected: a soft shield halo behind the medallion.
    if (protected) {
      canvas.drawCircle(
        Offset.zero,
        r * 1.02,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = _shield.withValues(alpha: 0.12 + 0.08 * pulse)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, r * (0.11 + 0.04 * pulse)),
      );
    }

    // 1) Ghost template — the full form, always faintly present.
    final ghostPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.011
      ..strokeCap = StrokeCap.round
      ..color = _ghost.withValues(alpha: dormant ? 0.55 : 0.30);
    for (final p in paths) {
      canvas.drawPath(p, ghostPaint);
    }

    if (dormant) {
      // Resting: a whisper of gold so it reads "asleep", not "dead".
      canvas.drawPath(
        paths.first,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.012
          ..strokeCap = StrokeCap.round
          ..color = _gold.withValues(alpha: 0.14),
      );
      return;
    }

    // Engraved under-stroke → gives the lines an inlaid, woven depth.
    final under = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.022
      ..strokeCap = StrokeCap.round
      ..color = _bgEdge.withValues(alpha: 0.85);

    // 2) Lit pass — reveal layers centre-outward, each with additive bloom.
    for (var i = 0; i < paths.length; i++) {
      final local = (illumination * _layers - i).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final revealed = _partial(paths[i], local);

      canvas.drawPath(revealed, under);

      if (g > 0.02) {
        // Wide soft halo (additive).
        canvas.drawPath(
          revealed,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * (0.03 + 0.05 * g)
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.plus
            ..color = _amber.withValues(alpha: (0.16 * g).clamp(0.0, 0.4))
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, r * (0.05 + 0.06 * g)),
        );
        // Tight bright bloom (additive).
        canvas.drawPath(
          revealed,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.02
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.plus
            ..color = _goldBright.withValues(alpha: (0.26 * g).clamp(0.0, 0.6))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.015),
        );
      }

      // Crisp lit stroke, radial gold gradient (brighter toward centre).
      canvas.drawPath(
        revealed,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.013
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = ui.Gradient.radial(Offset.zero, r, [
            Color.lerp(_gold, _goldBright, (0.4 + 0.6 * g).clamp(0.0, 1.0))!,
            _gold,
          ]),
      );
    }

    // 3) A light-sweep travelling around the star when it's alight.
    if (illumination > 0.9 && g > 0.35) {
      final sweep = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..shader = SweepGradient(
          transform: GradientRotation(phase),
          colors: [
            _goldBright.withValues(alpha: 0.0),
            _goldBright.withValues(alpha: 0.0),
            _goldBright.withValues(alpha: 0.55 * g),
            _goldBright.withValues(alpha: 0.0),
            _goldBright.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.42, 0.5, 0.58, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawPath(paths[3], sweep);
      canvas.drawPath(paths[4], sweep);
    }

    // 4) Spark tips at full illumination.
    if (illumination > 0.92 && g > 0.4) {
      final spark = Paint()
        ..color = _goldBright.withValues(alpha: (0.5 + 0.5 * pulse).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);
      for (var k = 0; k < 8; k++) {
        final a = k * math.pi / 4;
        canvas.drawCircle(
          Offset(r * 0.9 * math.cos(a), r * 0.9 * math.sin(a)),
          r * (0.022 + 0.012 * pulse),
          spark,
        );
      }
    }
  }

  /// The five concentric layers, ordered centre → edge (reveal order).
  List<Path> _buildLayers(double r) {
    return [
      _starPolygon(r * 0.20, r * 0.09, 8, math.pi / 8), // seed star
      _polygon(r * 0.34, 8, math.pi / 8), // inner octagon
      _spokes(r * 0.34, r * 0.64, 8, math.pi / 8), // radiating spokes
      _khatamStar(r * 0.86, r * 0.40), // hero 8-point interlaced star
      _outerFrame(r), // circle frame + tip finials
    ];
  }

  // A {2n}-vertex star: outer/inner radii alternate.
  Path _starPolygon(double outer, double inner, int points, double rot) {
    final p = Path();
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? outer : inner;
      final a = rot + i * math.pi / points;
      final o = Offset(rad * math.cos(a), rad * math.sin(a));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  Path _polygon(double radius, int sides, double rot) {
    final p = Path();
    for (var i = 0; i < sides; i++) {
      final a = rot + i * 2 * math.pi / sides;
      final o = Offset(radius * math.cos(a), radius * math.sin(a));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  Path _spokes(double from, double to, int count, double rot) {
    final p = Path();
    for (var i = 0; i < count; i++) {
      final a = rot + i * 2 * math.pi / count;
      p.moveTo(from * math.cos(a), from * math.sin(a));
      p.lineTo(to * math.cos(a), to * math.sin(a));
    }
    return p;
  }

  // The hero khatam: an 8-point star outline + two overlapping squares
  // (the classic interlace).
  Path _khatamStar(double outer, double inner) {
    final p = _starPolygon(outer, inner, 8, math.pi / 8);
    for (final rot in [0.0, math.pi / 4]) {
      final sq = _polygon(outer * 0.86, 4, rot + math.pi / 4);
      p.addPath(sq, Offset.zero);
    }
    return p;
  }

  Path _outerFrame(double r) {
    final p = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.98));
    // Small diamond finials at the 8 star tips.
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      final tip = Offset(r * 0.9 * math.cos(a), r * 0.9 * math.sin(a));
      final d = r * 0.06;
      final diamond = Path()
        ..moveTo(tip.dx, tip.dy - d)
        ..lineTo(tip.dx + d, tip.dy)
        ..lineTo(tip.dx, tip.dy + d)
        ..lineTo(tip.dx - d, tip.dy)
        ..close();
      p.addPath(diamond, Offset.zero);
    }
    return p;
  }

  /// Partial path for the "draw-on" reveal (frac of each contour's length).
  Path _partial(Path source, double frac) {
    if (frac >= 1.0) return source;
    final out = Path();
    for (final m in source.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * frac), Offset.zero);
    }
    return out;
  }

  @override
  bool shouldRepaint(KhatamPainter old) =>
      old.illumination != illumination ||
      old.glow != glow ||
      old.dormant != dormant ||
      old.protected != protected ||
      old.pulse != pulse ||
      old.ambientShader != ambientShader;
}
