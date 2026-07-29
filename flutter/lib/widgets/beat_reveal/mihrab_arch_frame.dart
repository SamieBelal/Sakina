import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';

/// A gold-stroked mihrab (prayer-niche) arch that frames the Name-of-Allah
/// hero on the emerald sacred canvas. Draws only decorative strokes — the
/// content (Arabic name, meaning, etc.) is laid over it by the caller.
///
/// The arch is a pointed ogee-style niche: two straight jambs rising into a
/// cusped point, with a thin inner keyline echoing the outline. Gold is used
/// as a NON-TEXT accent only (DESIGN.md contrast rule); the stroke sits at a
/// low enough alpha to read as ornament, not chrome.
class MihrabArchFrame extends StatelessWidget {
  const MihrabArchFrame({
    required this.child,
    this.animate = false,
    this.progress,
    super.key,
  });

  final Widget child;

  /// When true, the arch strokes draw on once (0→1) instead of appearing
  /// instantly. The caller gates this to the first reveal + reduced-motion.
  /// Ignored when [progress] is supplied.
  final bool animate;

  /// Caller-driven draw-on, 0→1. Use this when the arch is one beat inside a
  /// longer sequence and has to start on that sequence's clock rather than when
  /// it happens to be built — flipping [animate] from false to true mid-life
  /// would paint the arch complete, then erase it and redraw.
  ///
  /// The padding is unaffected, so the frame reserves its layout on the first
  /// frame and content inside it never moves as the strokes arrive.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      // Keep content inside the arch strokes.
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 34),
      child: child,
    );
    final progress = this.progress;
    if (progress != null) {
      return CustomPaint(painter: _MihrabArchPainter(progress), child: content);
    }
    if (!animate) {
      return CustomPaint(painter: _MihrabArchPainter(1), child: content);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      builder: (_, t, child) =>
          CustomPaint(painter: _MihrabArchPainter(t), child: child),
      child: content,
    );
  }
}

class _MihrabArchPainter extends CustomPainter {
  _MihrabArchPainter(this.progress);

  /// 0 = nothing drawn, 1 = fully drawn. Strokes reveal along their length;
  /// the fill wash fades in with it.
  final double progress;

  static const _gold = AppColors.secondary;

  // Draws [path] up to [t] of its length (stroke draw-on effect).
  void _drawUpTo(Canvas canvas, Path path, Paint paint, double t) {
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Arch geometry: jambs rise from the base, curve inward, and meet at a
    // cusped apex centered horizontally.
    final inset = w * 0.06;
    final left = inset;
    final right = w - inset;
    final base = h - inset;
    final springLine = h * 0.34; // where the jambs start curving
    final apexY = h * 0.02;
    final cx = w / 2;

    Path archPath(double pad) {
      final l = left + pad;
      final r = right - pad;
      final b = base - pad;
      final spring = springLine + pad * 0.5;
      final apex = apexY + pad;
      return Path()
        ..moveTo(l, b)
        ..lineTo(l, spring)
        // Left shoulder up toward a small cusp, then into the point.
        ..cubicTo(l, spring - (spring - apex) * 0.55, cx - w * 0.16, apex + h * 0.12,
            cx, apex)
        ..cubicTo(cx + w * 0.16, apex + h * 0.12, r, spring - (spring - apex) * 0.55,
            r, spring)
        ..lineTo(r, b)
        ..lineTo(l, b);
    }

    // Faint geometric fill wash inside the niche (5–8% ink), so the framed
    // area feels set apart from the surrounding canvas. Fades in with progress.
    canvas.drawPath(
      archPath(3),
      Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.sacredInk.withValues(alpha: 0.03 * progress),
    );

    // Outer stroke draws on along its length.
    _drawUpTo(
      canvas,
      archPath(0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _gold.withValues(alpha: 0.55),
      progress,
    );
    // Inner keyline echo — trails slightly behind the outer stroke.
    _drawUpTo(
      canvas,
      archPath(9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = _gold.withValues(alpha: 0.30),
      (progress * 1.15 - 0.15).clamp(0.0, 1.0),
    );
  }

  @override
  bool shouldRepaint(covariant _MihrabArchPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// The small 8-point star ornament that sits at the arch apex (matches the
/// reference mockup's crest). Decorative, gold, non-interactive.
class MihrabCrestOrnament extends StatelessWidget {
  const MihrabCrestOrnament({this.size = 26, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarOrnamentPainter(),
    );
  }
}

class _StarOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rOuter = size.width / 2;
    final rInner = rOuter * 0.46;
    final path = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? rOuter : rInner;
      final a = (i / (points * 2)) * 2 * math.pi - math.pi / 2;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.secondary.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _StarOrnamentPainter oldDelegate) => false;
}
