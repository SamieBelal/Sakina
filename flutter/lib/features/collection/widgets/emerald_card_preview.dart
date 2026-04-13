import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Preview screen — Ornate emerald collectible card (premium exclusive).
/// Deep forest green background with gold ornate border, emerald gem accents,
/// six-pointed star interlace pattern, and trefoil frame motifs.
class EmeraldCardPreviewScreen extends StatelessWidget {
  const EmeraldCardPreviewScreen({super.key});

  // ── Emerald palette ──
  static const _bgDark = Color(0xFF0F1F16);
  static const _emeraldBright = Color(0xFF7EEAAF);
  static const _glowColor = Color(0xFF4AE68A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: Text('Emerald Card — "Premium Exclusive"',
            style: AppTypography.labelLarge.copyWith(color: _emeraldBright)),
        backgroundColor: _bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _emeraldBright),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Grid tiles ──
            Text('Grid Tiles (3-up)',
                style: AppTypography.headlineMedium
                    .copyWith(color: _emeraldBright)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                    child: _EmeraldOrnateTile(
                        arabic: 'الرَّحْمَنُ',
                        transliteration: 'Ar-Rahman',
                        unseen: true)),
                SizedBox(width: 14),
                Expanded(
                    child: _EmeraldOrnateTile(
                        arabic: 'المَلِكُ',
                        transliteration: 'Al-Malik',
                        unseen: false)),
                SizedBox(width: 14),
                Expanded(
                    child: _EmeraldOrnateTile(
                        arabic: 'القُدُّوسُ',
                        transliteration: 'Al-Quddus',
                        unseen: false)),
              ],
            ),

            const SizedBox(height: 48),

            // ── Large single card ──
            Text('Single Card (Large)',
                style: AppTypography.headlineMedium
                    .copyWith(color: _emeraldBright)),
            const SizedBox(height: 16),
            Center(
              child: const SizedBox(
                width: 200,
                child: _EmeraldOrnateTile(
                    arabic: 'الوَدُودُ',
                    transliteration: 'Al-Wadud',
                    unseen: true),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                    duration: 2200.ms,
                    color: _glowColor.withValues(alpha: 0.2),
                  ),
            ),

            const SizedBox(height: 48),

            // ── On light background ──
            Text('On Light Background (in-app)',
                style: AppTypography.headlineMedium
                    .copyWith(color: _emeraldBright)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                      child: _EmeraldOrnateTile(
                          arabic: 'الرَّحْمَنُ',
                          transliteration: 'Ar-Rahman',
                          unseen: false)),
                  SizedBox(width: 14),
                  Expanded(
                      child: _EmeraldOrnateTile(
                          arabic: 'المَلِكُ',
                          transliteration: 'Al-Malik',
                          unseen: true)),
                  SizedBox(width: 14),
                  Expanded(
                      child: _EmeraldOrnateTile(
                          arabic: 'القُدُّوسُ',
                          transliteration: 'Al-Quddus',
                          unseen: false)),
                ],
              ),
            ),

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Preview-only Emerald Ornate Tile (standalone, takes simple strings)
// ═══════════════════════════════════════════════════════════════════════════════

class _EmeraldOrnateTile extends StatelessWidget {
  const _EmeraldOrnateTile({
    required this.arabic,
    required this.transliteration,
    this.unseen = false,
  });

  final String arabic;
  final String transliteration;
  final bool unseen;

  static const _bgDark = Color(0xFF0F1F16);
  static const _bgMid = Color(0xFF1A3328);
  static const _emeraldBright = Color(0xFF7EEAAF);
  static const _emeraldCore = Color(0xFF3CB371);
  static const _emeraldDim = Color(0xFF2A6B4A);
  static const _glowColor = Color(0xFF4AE68A);
  static const _goldAccent = Color(0xFFC8985E);
  static const _goldBright = Color(0xFFEDD9A3);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: unseen ? 0.45 : 0.2),
              blurRadius: unseen ? 22 : 12,
              spreadRadius: unseen ? 3 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // ── Deep forest gradient ──
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.1,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),

              // ── Interlace pattern ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _PreviewInterlacePatternPainter(
                    color: _emeraldDim.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // ── Gold ornate border ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _PreviewOrnateBorderPainter(
                    borderColor: _goldAccent.withValues(alpha: 0.6),
                    flourishColor: _goldBright.withValues(alpha: 0.7),
                    gemColor: _emeraldCore.withValues(alpha: 0.8),
                  ),
                ),
              ),

              // ── Center medallion ──
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final medallionSize = constraints.maxWidth * 0.52;
                    final glowSize = medallionSize + 20;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        SizedBox(
                          width: glowSize,
                          height: glowSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Emerald glow
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(
                                          alpha: unseen ? 0.3 : 0.15),
                                      _glowColor.withValues(alpha: 0.05),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              // Trefoil frame
                              CustomPaint(
                                size:
                                    Size(medallionSize + 8, medallionSize + 8),
                                painter: _PreviewTrefoilFramePainter(
                                  color: _goldAccent.withValues(alpha: 0.5),
                                  gemColor:
                                      _emeraldCore.withValues(alpha: 0.6),
                                ),
                              ),
                              // Gold ring
                              Container(
                                width: medallionSize,
                                height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _goldAccent.withValues(alpha: 0.7),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          _glowColor.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Arabic text
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      arabic,
                                      style: AppTypography.nameOfAllahDisplay
                                          .copyWith(
                                        fontSize: 18,
                                        color: _emeraldBright,
                                        shadows: [
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.7),
                                              blurRadius: 14),
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.3),
                                              blurRadius: 28),
                                        ],
                                      ),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),

                        // Tier dots (3 gold + 1 emerald)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(3, (i) {
                              return Container(
                                width: 4,
                                height: 4,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _goldBright,
                                  boxShadow: [
                                    BoxShadow(
                                        color: _goldAccent.withValues(
                                            alpha: 0.5),
                                        blurRadius: 4),
                                  ],
                                ),
                              );
                            }),
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _emeraldBright,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          _glowColor.withValues(alpha: 0.6),
                                      blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Transliteration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            transliteration,
                            style: AppTypography.labelSmall.copyWith(
                              color: _goldAccent.withValues(alpha: 0.8),
                              fontSize: 8,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const Spacer(flex: 1),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Preview-only painters (standalone, no external deps)
// ═══════════════════════════════════════════════════════════════════════════════

class _PreviewInterlacePatternPainter extends CustomPainter {
  _PreviewInterlacePatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const cellSize = 24.0;
    const r = cellSize * 0.38;

    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2;
        final cy = y + cellSize / 2;

        // Six-pointed star
        final path = Path();
        path.moveTo(cx, cy - r);
        path.lineTo(cx + r * cos(pi / 6), cy + r * sin(pi / 6));
        path.lineTo(cx - r * cos(pi / 6), cy + r * sin(pi / 6));
        path.close();

        path.moveTo(cx, cy + r);
        path.lineTo(cx + r * cos(pi / 6), cy - r * sin(pi / 6));
        path.lineTo(cx - r * cos(pi / 6), cy - r * sin(pi / 6));
        path.close();

        canvas.drawPath(path, paint);

        // Hexagonal ring
        final hexPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4;

        final hexPath = Path();
        const hr = r * 0.55;
        for (int i = 0; i < 6; i++) {
          final angle = i * pi / 3 - pi / 6;
          final px = cx + hr * cos(angle);
          final py = cy + hr * sin(angle);
          if (i == 0) {
            hexPath.moveTo(px, py);
          } else {
            hexPath.lineTo(px, py);
          }
        }
        hexPath.close();
        canvas.drawPath(hexPath, hexPaint);

        canvas.drawCircle(
          Offset(cx, cy),
          1.2,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewOrnateBorderPainter extends CustomPainter {
  _PreviewOrnateBorderPainter({
    required this.borderColor,
    required this.flourishColor,
    required this.gemColor,
  });
  final Color borderColor;
  final Color flourishColor;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const inset = 3.0;
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(9),
    );
    canvas.drawRRect(borderRect, borderPaint);

    final innerPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 6.5;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(7),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Corner flourishes
    final flourishPaint = Paint()
      ..color = flourishColor
      ..style = PaintingStyle.fill;

    _drawCorner(canvas, flourishPaint, inset + 1, inset + 1, 12, false, false);
    _drawCorner(
        canvas, flourishPaint, w - inset - 1, inset + 1, 12, true, false);
    _drawCorner(
        canvas, flourishPaint, inset + 1, h - inset - 1, 12, false, true);
    _drawCorner(
        canvas, flourishPaint, w - inset - 1, h - inset - 1, 12, true, true);

    // Emerald gems at mid-edges
    final gemPaint = Paint()
      ..color = gemColor
      ..style = PaintingStyle.fill;

    final gemGlowPaint = Paint()
      ..color = gemColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(Offset(w / 2, inset), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(w / 2, inset), 1.8, gemPaint);
    canvas.drawCircle(Offset(w / 2, h - inset), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(w / 2, h - inset), 1.8, gemPaint);
    canvas.drawCircle(Offset(inset, h / 2), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(inset, h / 2), 1.8, gemPaint);
    canvas.drawCircle(Offset(w - inset, h / 2), 2.5, gemGlowPaint);
    canvas.drawCircle(Offset(w - inset, h / 2), 1.8, gemPaint);
  }

  void _drawCorner(Canvas canvas, Paint paint, double x, double y, double size,
      bool flipX, bool flipY) {
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;

    const ds = 4.0;
    final diamond = Path()
      ..moveTo(x, y - ds * dy)
      ..lineTo(x + ds * dx, y)
      ..lineTo(x, y + ds * dy)
      ..lineTo(x - ds * dx, y)
      ..close();
    canvas.drawPath(diamond, paint);

    final linePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x + ds * dx * 1.2, y),
      Offset(x + size * dx * 0.7, y),
      linePaint,
    );
    final hEnd = Offset(x + size * dx * 0.7, y);
    canvas.drawCircle(
        hEnd,
        1.2,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill);

    canvas.drawLine(
      Offset(x, y + ds * dy * 1.2),
      Offset(x, y + size * dy * 0.7),
      linePaint,
    );
    final vEnd = Offset(x, y + size * dy * 0.7);
    canvas.drawCircle(
        vEnd,
        1.2,
        Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewTrefoilFramePainter extends CustomPainter {
  _PreviewTrefoilFramePainter({required this.color, required this.gemColor});
  final Color color;
  final Color gemColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.5;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(diamond, paint);

    // Small arch circles at each point
    final archPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2 - pi / 2;
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r;
      final archR = r * 0.12;
      canvas.drawCircle(Offset(px, py), archR, archPaint);
    }

    // Emerald gems at diamond points
    final gemPaint = Paint()
      ..color = gemColor
      ..style = PaintingStyle.fill;

    const gs = 2.0;
    for (final point in [
      Offset(cx, cy - r),
      Offset(cx + r, cy),
      Offset(cx, cy + r),
      Offset(cx - r, cy)
    ]) {
      canvas.drawCircle(point, gs, gemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
