// lib/features/daily/reveal/painters/card_fx_painters.dart
//
// The on-card FX painters clipped to the ornate tile: holographic foil +
// rotation-synced specular glint, a settle lens-flare, and a diagonal shine
// sweep. Widget-free; driven by explicit phase/intensity/color params.
import 'package:flutter/material.dart';

import 'package:sakina/features/daily/reveal/reveal_geometry.dart';

// Holographic foil sheen (a travelling diagonal rainbow) + a specular band that
// tracks the card's Y-rotation, so a highlight sweeps across as it turns.
class FoilPainter extends CustomPainter {
  FoilPainter(
      {required this.foilPhase,
      required this.tilt,
      required this.bright,
      this.intensity = 1.0});
  final double foilPhase;
  final double tilt;
  final Color bright;
  final double intensity; // 0-1 scales the holographic sheen (1.0 = Emerald)

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final p = foilPhase;

    // Diagonal hue-shift sheen, band travels with the rotation phase.
    // Alpha scaled by [intensity] so lower tiers get a subtler (or no) foil.
    if (intensity > 0) {
      final sheen = LinearGradient(
        begin: Alignment(-1 + 2 * p, -1),
        end: Alignment(1, 1 - 2 * p),
        colors: [
          bright.withValues(alpha: 0.0),
          goldBright.withValues(alpha: 0.16 * intensity),
          Colors.white.withValues(alpha: 0.10 * intensity),
          bright.withValues(alpha: 0.14 * intensity),
          bright.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
      ).createShader(rect);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = sheen
          ..blendMode = BlendMode.plus,
      );
    }

    // Specular band — brightest mid-turn, position tracks the tilt.
    final strength = tilt.abs();
    if (strength > 0.02) {
      final sx = (0.5 + tilt.clamp(-1.0, 1.0) * 0.55) * size.width;
      final band = size.width * 0.30;
      final spec = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.34 * strength),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(sx - band, 0, band * 2, size.height));
      canvas.drawRect(
        rect,
        Paint()
          ..shader = spec
          ..blendMode = BlendMode.plus,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FoilPainter old) =>
      old.foilPhase != foilPhase ||
      old.tilt != tilt ||
      old.intensity != intensity;
}

// A horizontal anamorphic lens-flare that flashes across the card as it lands.
class LensFlarePainter extends CustomPainter {
  LensFlarePainter(this.flare, this.bright);
  final double flare;
  final Color bright;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.42;
    final streak = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.0),
        bright.withValues(alpha: 0.5 * flare),
        Colors.white.withValues(alpha: 0.85 * flare),
        bright.withValues(alpha: 0.5 * flare),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    ).createShader(
        Rect.fromLTWH(-size.width * 0.4, 0, size.width * 1.8, size.height));
    final h = size.height * 0.10 * (0.6 + flare * 0.6);
    canvas.drawRect(
      Rect.fromLTWH(-size.width * 0.4, cy - h / 2, size.width * 1.8, h),
      Paint()
        ..shader = streak
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.4),
    );
    // Bright core.
    canvas.drawCircle(
      Offset(size.width / 2, cy),
      size.width * 0.10 * flare,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.9 * flare),
          Colors.white.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(
            center: Offset(size.width / 2, cy),
            radius: size.width * 0.10 * flare)),
    );
  }

  @override
  bool shouldRepaint(covariant LensFlarePainter old) => old.flare != flare;
}

class ShineSweepPainter extends CustomPainter {
  const ShineSweepPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.width * 0.4;
    final x = -band + progress * (size.width + band * 2);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.38),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.35, 0.5, 0.65],
    );
    final shader = gradient.createShader(
      Rect.fromLTWH(x - band, 0, band * 2, size.height),
    );
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant ShineSweepPainter old) =>
      old.progress != progress;
}
