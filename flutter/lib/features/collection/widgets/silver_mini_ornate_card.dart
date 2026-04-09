import 'package:flutter/material.dart';
import 'package:sakina/core/theme/app_typography.dart';

import 'ornate_card_shimmer.dart';

class SilverMiniOrnateTile extends StatelessWidget {
  const SilverMiniOrnateTile({
    required this.arabic,
    required this.transliteration,
    super.key,
    this.shimmer,
  });

  final String arabic;
  final String transliteration;
  final OrnateCardShimmer? shimmer;

  static const _bgDark = Color(0xFF2A2D3A);
  static const _bgMid = Color(0xFF353847);
  static const _silverBright = Color(0xFFCDD0D6);
  static const _silverCore = Color(0xFFA8A9AD);
  static const _silverDim = Color(0xFF6B6E78);
  static const _glowColor = Color(0xFFB8C8E0);
  static const _frameGold = Color(0xFFC8985E);

  @override
  Widget build(BuildContext context) {
    final bool isShimmering = shimmer?.enabled ?? false;

    final Widget tile = AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _glowColor.withValues(alpha: isShimmering ? 0.22 : 0.15),
              blurRadius: isShimmering ? 14 : 10,
              spreadRadius: isShimmering ? 1 : 0,
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
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [_bgMid, _bgDark],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MiniPatternPainter(
                    color: _silverDim.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MiniBorderPainter(
                    color: _silverCore.withValues(alpha: 0.5),
                    accentColor: _silverBright.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final medallionSize = constraints.maxWidth * 0.55;
                    final glowSize = medallionSize + 16;

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
                              Container(
                                width: glowSize,
                                height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _glowColor.withValues(
                                        alpha: isShimmering ? 0.16 : 0.1,
                                      ),
                                      _glowColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: medallionSize,
                                height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _frameGold.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: medallionSize * 0.65,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    arabic,
                                    style: AppTypography.nameOfAllahDisplay
                                        .copyWith(
                                      fontSize: 18,
                                      color: _silverBright,
                                      shadows: [
                                        Shadow(
                                          color:
                                              _glowColor.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < 2
                                    ? _silverBright
                                    : _silverDim.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transliteration,
                          style: AppTypography.labelSmall.copyWith(
                            color: _silverCore.withValues(alpha: 0.7),
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

    return applyOrnateCardShimmer(
      child: tile,
      color: _glowColor.withValues(alpha: 0.2),
      legacyEnabled: false,
      shimmer: shimmer,
    );
  }
}

class _MiniPatternPainter extends CustomPainter {
  _MiniPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const cellSize = 20.0;
    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2;
        final cy = y + cellSize / 2;
        const r = cellSize * 0.38;
        const s1 = r * 0.7;
        final path = Path()
          ..moveTo(cx - s1, cy - s1)
          ..lineTo(cx + s1, cy - s1)
          ..lineTo(cx + s1, cy + s1)
          ..lineTo(cx - s1, cy + s1)
          ..close()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBorderPainter extends CustomPainter {
  _MiniBorderPainter({required this.color, required this.accentColor});

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, w - 6, h - 6),
        const Radius.circular(9),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final ap = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    const ds = 3.0;
    const o = 4.0;
    for (final pos in [
      const Offset(o, o),
      Offset(w - o, o),
      Offset(o, h - o),
      Offset(w - o, h - o),
    ]) {
      final d = Path()
        ..moveTo(pos.dx, pos.dy - ds)
        ..lineTo(pos.dx + ds, pos.dy)
        ..lineTo(pos.dx, pos.dy + ds)
        ..lineTo(pos.dx - ds, pos.dy)
        ..close();
      canvas.drawPath(d, ap);
    }

    final mp = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    const ms = 2.5;
    for (final pos in [
      Offset(w / 2, 3),
      Offset(w / 2, h - 3),
      Offset(3, h / 2),
      Offset(w - 3, h / 2),
    ]) {
      final d = Path()
        ..moveTo(pos.dx, pos.dy - ms)
        ..lineTo(pos.dx + ms, pos.dy)
        ..lineTo(pos.dx, pos.dy + ms)
        ..lineTo(pos.dx - ms, pos.dy)
        ..close();
      canvas.drawPath(d, mp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
