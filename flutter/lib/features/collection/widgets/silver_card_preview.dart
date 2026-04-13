import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Preview screen — Hearthstone-inspired dark ornate silver card design.
class SilverCardPreviewScreen extends StatelessWidget {
  const SilverCardPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('Silver Card — "Ornate Collectible"',
            style: AppTypography.labelLarge.copyWith(color: const Color(0xFFD0D1D5))),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD0D1D5)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section: Grid tiles ──
            Text('Grid Tiles (3-up)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFD0D1D5))),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: _OrnateTile(arabic: 'الرَّحِيمُ', transliteration: 'Ar-Raheem', unseen: true)),
                SizedBox(width: 14),
                Expanded(child: _OrnateTile(arabic: 'السَّلَامُ', transliteration: 'As-Salaam', unseen: false)),
                SizedBox(width: 14),
                Expanded(child: _OrnateTile(arabic: 'المُؤْمِنُ', transliteration: "Al-Mu'min", unseen: false)),
              ],
            ),

            const SizedBox(height: 48),

            // ── Section: Large single card ──
            Text('Single Card (Large)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFD0D1D5))),
            const SizedBox(height: 16),
            Center(
              child: const SizedBox(
                width: 200,
                child: _OrnateTile(arabic: 'الوَدُودُ', transliteration: 'Al-Wadud', unseen: true),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                    duration: 2200.ms,
                    color: const Color(0xFFB8C8E0).withValues(alpha: 0.2),
                  ),
            ),

            const SizedBox(height: 48),

            // ── On light background ──
            Text('On Light Background (in-app)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFD0D1D5))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(child: _OrnateTile(arabic: 'الرَّحِيمُ', transliteration: 'Ar-Raheem', unseen: true)),
                  SizedBox(width: 14),
                  Expanded(child: _OrnateTile(arabic: 'السَّلَامُ', transliteration: 'As-Salaam', unseen: false)),
                  SizedBox(width: 14),
                  Expanded(child: _OrnateTile(arabic: 'المُؤْمِنُ', transliteration: "Al-Mu'min", unseen: false)),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ── Section: Detail card ──
            Text('Detail Card (Bottom Sheet)', style: AppTypography.headlineMedium.copyWith(color: const Color(0xFFD0D1D5))),
            const SizedBox(height: 16),
            const _OrnateDetailCard(),

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ornate Silver — Grid Tile (Hearthstone-inspired)
// ═══════════════════════════════════════════════════════════════════════════════

class _OrnateTile extends StatelessWidget {
  const _OrnateTile({required this.arabic, required this.transliteration, this.unseen = false});

  final String arabic;
  final String transliteration;
  final bool unseen;

  // Silver palette
  static const _bgDark = Color(0xFF2A2D3A);       // dark slate card body
  static const _bgMid = Color(0xFF353847);         // slightly lighter center
  static const _silverBright = Color(0xFFCDD0D6);  // bright silver for text/accents
  static const _silverCore = Color(0xFFA8A9AD);    // mid silver
  static const _silverDim = Color(0xFF6B6E78);     // dim silver for subtle elements
  static const _glowColor = Color(0xFFB8C8E0);     // cool silver glow
  static const _frameGold = Color(0xFFC8985E);     // warm gold for the inner ring

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Outer glow
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: unseen ? 0.4 : 0.15),
              blurRadius: unseen ? 20 : 10,
              spreadRadius: unseen ? 2 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // ── Dark gradient background ──
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),

              // ── Islamic geometric pattern (subtle, etched into the card) ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _IslamicPatternPainter(
                    color: _silverDim.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // ── Ornate border frame ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrnateBorderPainter(
                    color: _silverCore.withValues(alpha: 0.5),
                    cornerAccentColor: _silverBright.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // ── Center medallion (glow + ring + Arabic text) ──
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final medallionSize = constraints.maxWidth * 0.55;
                    final glowSize = medallionSize + 16;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        // Medallion with everything centered together
                        SizedBox(
                          width: glowSize,
                          height: glowSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(alpha: unseen ? 0.2 : 0.1),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              // Gold ring
                              Container(
                                width: medallionSize,
                                height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _frameGold.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _frameGold.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      spreadRadius: 1,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      arabic,
                                      style: AppTypography.nameOfAllahDisplay.copyWith(
                                        fontSize: 18,
                                        color: _silverBright,
                                        shadows: [
                                          Shadow(color: _glowColor.withValues(alpha: 0.5), blurRadius: 12),
                                          Shadow(color: _glowColor.withValues(alpha: 0.2), blurRadius: 24),
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

                        // Tier dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final filled = i < 2;
                            return Container(
                              width: 4, height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled ? _silverBright : _silverDim.withValues(alpha: 0.3),
                                boxShadow: filled ? [
                                  BoxShadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 4),
                                ] : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 4),

                        // Transliteration
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            transliteration,
                            style: AppTypography.labelSmall.copyWith(
                              color: _silverCore.withValues(alpha: 0.7),
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
// Ornate Silver — Detail Card
// ═══════════════════════════════════════════════════════════════════════════════

class _OrnateDetailCard extends StatelessWidget {
  const _OrnateDetailCard();

  static const _bgDark = Color(0xFF2A2D3A);
  static const _bgMid = Color(0xFF353847);
  static const _silverBright = Color(0xFFCDD0D6);
  static const _silverCore = Color(0xFFA8A9AD);
  static const _silverDim = Color(0xFF6B6E78);
  static const _glowColor = Color(0xFFB8C8E0);
  static const _frameGold = Color(0xFFC8985E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dark gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgMid, _bgDark, Color(0xFF222533)],
                ),
              ),
            ),

            // Islamic pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: _silverDim.withValues(alpha: 0.05),
                  scale: 1.8,
                ),
              ),
            ),

            // Ornate border
            Positioned.fill(
              child: CustomPaint(
                painter: _OrnateDetailBorderPainter(
                  color: _silverCore.withValues(alpha: 0.35),
                  accentColor: _frameGold.withValues(alpha: 0.3),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: _silverDim.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Medallion ring + Arabic
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _frameGold.withValues(alpha: 0.35), width: 2),
                      boxShadow: [
                        BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 4),
                        BoxShadow(color: _frameGold.withValues(alpha: 0.1), blurRadius: 16),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'الرَّحِيمُ',
                        style: AppTypography.nameOfAllahDisplay.copyWith(
                          fontSize: 38,
                          color: _silverBright,
                          shadows: [
                            Shadow(color: _glowColor.withValues(alpha: 0.6), blurRadius: 16),
                            Shadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 32),
                          ],
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _silverCore.withValues(alpha: 0.25)),
                      color: _silverDim.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(3, (i) => Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < 2 ? _silverBright : _silverDim.withValues(alpha: 0.3),
                            boxShadow: i < 2 ? [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 3),
                            ] : null,
                          ),
                        )),
                        const SizedBox(width: 6),
                        Text(
                          'SILVER',
                          style: AppTypography.labelSmall.copyWith(
                            color: _silverCore,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Ar-Raheem', style: AppTypography.headlineMedium.copyWith(color: _silverBright)),
                  const SizedBox(height: 4),
                  Text('The Most Merciful', style: AppTypography.bodyMedium.copyWith(color: _silverCore)),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 12,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _OrnateDividerPainter(
                        lineColor: _silverDim.withValues(alpha: 0.3),
                        accentColor: _frameGold.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meaning
                  Text(
                    'Ar-Raheem emphasizes the continuous, active mercy of Allah — a mercy that is always reaching, always encompassing.',
                    style: AppTypography.bodyMedium.copyWith(color: _silverCore, height: 1.7),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Lesson box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B6B4A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1B6B4A).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'When you feel undeserving, remember: His mercy isn\'t something you earn — it\'s something He gives freely.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: const Color(0xFF8BC6A5),
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 12,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _OrnateDividerPainter(
                        lineColor: _silverDim.withValues(alpha: 0.3),
                        accentColor: _frameGold.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tier 2: Hadith
                  Row(
                    children: [
                      Container(
                        width: 3, height: 16,
                        decoration: BoxDecoration(
                          color: _silverBright,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'PROPHETIC TEACHING',
                        style: AppTypography.labelSmall.copyWith(
                          color: _silverCore,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"Allah divided mercy into one hundred parts. He kept ninety-nine parts with Him and sent down one part to the earth."',
                    style: AppTypography.bodyMedium.copyWith(
                      color: _silverCore,
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— Sahih Muslim',
                      style: AppTypography.bodySmall.copyWith(color: _silverDim),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Upgrade hint
                  Text(
                    'Encounter this Name again to unlock the Dua',
                    style: AppTypography.bodySmall.copyWith(color: _silverDim),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Islamic Geometric Pattern Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _IslamicPatternPainter extends CustomPainter {
  _IslamicPatternPainter({required this.color, this.scale = 1.0});
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 * scale;

    final cellSize = 20.0 * scale;

    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2;
        final cy = y + cellSize / 2;
        final r = cellSize * 0.38;

        // 8-pointed star: two overlapping rotated squares
        final path = Path();
        final s1 = r * 0.7;
        path.moveTo(cx - s1, cy - s1);
        path.lineTo(cx + s1, cy - s1);
        path.lineTo(cx + s1, cy + s1);
        path.lineTo(cx - s1, cy + s1);
        path.close();

        path.moveTo(cx, cy - r);
        path.lineTo(cx + r, cy);
        path.lineTo(cx, cy + r);
        path.lineTo(cx - r, cy);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ornate Border Painter (for grid tiles)
// ═══════════════════════════════════════════════════════════════════════════════

class _OrnateBorderPainter extends CustomPainter {
  _OrnateBorderPainter({required this.color, required this.cornerAccentColor});
  final Color color;
  final Color cornerAccentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const inset = 3.0;
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(9),
    );
    canvas.drawRRect(borderRect, borderPaint);

    // Inner border (thinner)
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 6.0;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(7),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Corner ornaments
    final accentPaint = Paint()
      ..color = cornerAccentColor
      ..style = PaintingStyle.fill;

    const cornerSize = 10.0;

    // Top-left
    _drawCornerOrnament(canvas, accentPaint, inset + 1, inset + 1, cornerSize, false, false);
    // Top-right
    _drawCornerOrnament(canvas, accentPaint, w - inset - 1, inset + 1, cornerSize, true, false);
    // Bottom-left
    _drawCornerOrnament(canvas, accentPaint, inset + 1, h - inset - 1, cornerSize, false, true);
    // Bottom-right
    _drawCornerOrnament(canvas, accentPaint, w - inset - 1, h - inset - 1, cornerSize, true, true);

    // Mid-edge diamonds
    final diamondPaint = Paint()
      ..color = cornerAccentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    const ds = 2.5;

    // Top center
    _drawDiamond(canvas, diamondPaint, w / 2, inset, ds);
    // Bottom center
    _drawDiamond(canvas, diamondPaint, w / 2, h - inset, ds);
    // Left center
    _drawDiamond(canvas, diamondPaint, inset, h / 2, ds);
    // Right center
    _drawDiamond(canvas, diamondPaint, w - inset, h / 2, ds);
  }

  void _drawCornerOrnament(Canvas canvas, Paint paint, double x, double y, double size, bool flipX, bool flipY) {
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;

    // Small diamond at the corner
    const ds = 3.0;
    final diamond = Path()
      ..moveTo(x, y - ds * dy)
      ..lineTo(x + ds * dx, y)
      ..lineTo(x, y + ds * dy)
      ..lineTo(x - ds * dx, y)
      ..close();
    canvas.drawPath(diamond, paint);

    // Small tick lines extending from corner
    final linePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x + ds * dx * 1.2, y),
      Offset(x + size * dx * 0.6, y),
      linePaint,
    );
    canvas.drawLine(
      Offset(x, y + ds * dy * 1.2),
      Offset(x, y + size * dy * 0.6),
      linePaint,
    );
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double size) {
    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ornate Detail Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _OrnateDetailBorderPainter extends CustomPainter {
  _OrnateDetailBorderPainter({required this.color, required this.accentColor});
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer frame
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const inset = 6.0;
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(14),
    );
    canvas.drawRRect(outerRect, borderPaint);

    // Inner frame
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 10.0;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(12),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Gold accent diamonds at corners and edges
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    const ds = 3.5;
    // Top center
    _drawDiamond(canvas, accentPaint, w / 2, inset, ds);
    // Bottom center
    _drawDiamond(canvas, accentPaint, w / 2, h - inset, ds);
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double size) {
    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Ornate Divider Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _OrnateDividerPainter extends CustomPainter {
  _OrnateDividerPainter({required this.lineColor, required this.accentColor});
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Center diamond (gold accent)
    const ds = 4.0;
    final diamond = Path()
      ..moveTo(centerX, cy - ds)
      ..lineTo(centerX + ds, cy)
      ..lineTo(centerX, cy + ds)
      ..lineTo(centerX - ds, cy)
      ..close();
    canvas.drawPath(diamond, accentPaint);

    // Lines
    canvas.drawLine(Offset(20, cy), Offset(centerX - ds - 6, cy), linePaint);
    canvas.drawLine(Offset(centerX + ds + 6, cy), Offset(size.width - 20, cy), linePaint);

    // Small dots at ends
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(20, cy), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 20, cy), 1.5, dotPaint);

    // Small side diamonds
    const sds = 2.0;
    for (final px in [size.width * 0.28, size.width * 0.72]) {
      final sm = Path()
        ..moveTo(px, cy - sds)
        ..lineTo(px + sds, cy)
        ..lineTo(px, cy + sds)
        ..lineTo(px - sds, cy)
        ..close();
      canvas.drawPath(sm, Paint()..color = lineColor..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
