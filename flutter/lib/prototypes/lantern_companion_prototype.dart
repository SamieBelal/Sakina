// Lantern (fānūs) companion — STANDALONE DEV HARNESS, with a Khatam/Lantern
// toggle so the warm illustrated lantern can be compared directly against the
// geometric khatam. The lantern is the "warm companion" direction: a glowing
// lamp (the lamp of Āyat an-Nūr) whose light — the khatam pattern in its glass —
// reflects the streak.
//
// The painter itself now lives in production at
// `lib/features/streaks/widgets/lantern_painter.dart` (extracted in Phase 0 of
// the streaks + companion plan). This file is just the interactive harness that
// drives it through the five demo states.
//
// RUN: flutter run -d <device_id> -t lib/prototypes/lantern_companion_prototype.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sakina/features/streaks/widgets/lantern_painter.dart';

import 'khatam_companion_prototype.dart' show KhatamPainter, KhatamState;

// ── Screen palette (harness chrome only; the painter owns its own palette) ────
const _bgCenter = Color(0xFF124A34);
const _bgEdge = Color(0xFF062017);
const _goldMid = Color(0xFFD9A968);
const _lightGold = Color(0xFFFBE7BE);
const _amber = Color(0xFFE8A154);

void main() => runApp(const _App());

/// Per-state params. The geometric sequence is ALWAYS fully drawn (illum pinned
/// 1.0); only `glow` scales, so the whole medallion goes from very dim (early
/// streak) to fully lit (strong streak).
({double illum, double glow, bool dormant, bool protected}) _params(
    KhatamState s) {
  return switch (s) {
    KhatamState.dormant =>
      (illum: 1.0, glow: 0.0, dormant: true, protected: false),
    KhatamState.dim =>
      (illum: 1.0, glow: 0.26, dormant: false, protected: false),
    KhatamState.glowing =>
      (illum: 1.0, glow: 0.55, dormant: false, protected: false),
    KhatamState.fullyLit =>
      (illum: 1.0, glow: 0.95, dormant: false, protected: false),
    KhatamState.protected =>
      (illum: 1.0, glow: 0.95, dormant: false, protected: true),
  };
}

String _meaning(KhatamState s) => switch (s) {
      KhatamState.dormant => 'lapsed — resting, not lost',
      KhatamState.dim => 'streak building (day 1–3)',
      KhatamState.glowing => 'steady streak',
      KhatamState.fullyLit => 'strong streak',
      KhatamState.protected => 'a freeze is protecting you',
    };

CustomPainter _companion({
  required bool lantern,
  required double illumination,
  required double glow,
  required bool dormant,
  required bool protected,
  required double pulse,
  ui.FragmentShader? shader,
}) {
  return lantern
      ? LanternPainter(
          illumination: illumination,
          glow: glow,
          dormant: dormant,
          protected: protected,
          pulse: pulse,
          ambientShader: shader,
        )
      : KhatamPainter(
          illumination: illumination,
          glow: glow,
          dormant: dormant,
          protected: protected,
          pulse: pulse,
          ambientShader: shader,
        );
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _Screen(),
      );
}

class _Screen extends StatefulWidget {
  const _Screen();
  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> with TickerProviderStateMixin {
  bool _lantern = true;
  KhatamState _state = KhatamState.glowing;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..value = 1;
  double _fromIllum = 0.72, _fromGlow = 0.5;

  ui.FragmentShader? _glowShader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final p = await ui.FragmentProgram.fromAsset('shaders/khatam_glow.frag');
      if (mounted) setState(() => _glowShader = p.fragmentShader());
    } catch (e) {
      debugPrint('shader load failed: $e');
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _transition.dispose();
    super.dispose();
  }

  void _select(KhatamState s) {
    final p = _params(_state);
    final t = Curves.easeOutCubic.transform(_transition.value);
    setState(() {
      _fromIllum = ui.lerpDouble(_fromIllum, p.illum, t)!;
      _fromGlow = ui.lerpDouble(_fromGlow, p.glow, t)!;
      _state = s;
    });
    _transition.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final target = _params(_state);
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
              const SizedBox(height: 6),
              // Khatam / Lantern toggle.
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Khatam')),
                  ButtonSegment(value: true, label: Text('Lantern')),
                ],
                selected: {_lantern},
                onSelectionChanged: (v) => setState(() => _lantern = v.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  backgroundColor: WidgetStateProperty.resolveWith((s) =>
                      s.contains(WidgetState.selected)
                          ? _goldMid
                          : Colors.white10),
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulse, _transition]),
                    builder: (context, _) {
                      final t = Curves.easeOutCubic.transform(_transition.value);
                      final illum = ui.lerpDouble(_fromIllum, target.illum, t)!;
                      final glow = ui.lerpDouble(_fromGlow, target.glow, t)!;
                      return SizedBox(
                        width: 300,
                        height: 320,
                        child: CustomPaint(
                          painter: _companion(
                            lantern: _lantern,
                            illumination: illum,
                            glow: glow,
                            dormant: target.dormant,
                            protected: target.protected,
                            pulse: _pulse.value,
                            shader: _glowShader,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final s in KhatamState.values)
                    ChoiceChip(
                      label: Text(s.name),
                      selected: _state == s,
                      onSelected: (_) => _select(s),
                      selectedColor: _goldMid,
                      labelStyle: TextStyle(
                        color: _state == s ? Colors.black87 : Colors.white70,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white10,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text('${_state.name} — ${_meaning(_state)}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              const SizedBox(height: 6),
              // Widget frames of the SELECTED companion.
              const Text('Home-screen widget frame per state',
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
                        child: _WidgetCard(
                            lantern: _lantern,
                            state: entry.$1,
                            streak: entry.$2),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  const _WidgetCard(
      {required this.lantern, required this.state, required this.streak});
  final bool lantern;
  final KhatamState state;
  final String streak;

  @override
  Widget build(BuildContext context) {
    final p = _params(state);
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
              painter: _companion(
                lantern: lantern,
                illumination: p.illum,
                glow: p.glow * 0.9,
                dormant: p.dormant,
                protected: p.protected,
                pulse: 0.3,
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
                        color: p.dormant ? Colors.white38 : _lightGold,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                Icon(Icons.local_fire_department,
                    size: 13, color: p.dormant ? Colors.white24 : _amber),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
