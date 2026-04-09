import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/collection/widgets/bronze_ornate_card.dart';
import '../../../features/collection/widgets/gold_ornate_card.dart';
import '../../../services/card_collection_service.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureNamesScreen extends StatelessWidget {
  const FeatureNamesScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 9,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.featureNamesHeadline,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.featureNamesSubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                  const SizedBox(height: AppSpacing.xl + AppSpacing.sm),

                  // Fanned card stack
                  _buildCardStack(context),

                  const SizedBox(height: AppSpacing.xl),

                  // Tier progression
                  _buildTierProgression(),

                  const Spacer(),
                  OnboardingContinueButton(
                    label: AppStrings.continueButton,
                    onPressed: onNext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.26;
    final cardHeight = cardWidth / 0.72;

    return SizedBox(
      height: cardHeight + 30,
      child: Center(
        child: SizedBox(
          width: screenWidth * 0.8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Bronze — left
              Positioned(
                left: 0,
                top: 14,
                child: Transform.rotate(
                  angle: -0.12,
                  child: SizedBox(
                    width: cardWidth,
                    child: BronzeOrnateTile(
                      arabic: AppStrings.featureNamesSampleName3,
                      transliteration: AppStrings.featureNamesSampleTranslit3,
                      unseen: false,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms, delay: 400.ms),
              ),
              // Gold — center, raised
              Positioned(
                top: 0,
                child: SizedBox(
                  width: cardWidth * 1.1,
                  child: GoldOrnateTile(
                    card: allCollectibleNames[0],
                    unseen: true,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 580.ms)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms, delay: 580.ms),
              ),
              // Silver — right
              Positioned(
                right: 0,
                top: 14,
                child: Transform.rotate(
                  angle: 0.12,
                  child: SizedBox(
                    width: cardWidth,
                    child: _SilverMiniTile(
                      arabic: AppStrings.featureNamesSampleName2,
                      transliteration: AppStrings.featureNamesSampleTranslit2,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 760.ms)
                    .slideY(begin: 0.15, end: 0, duration: 500.ms, delay: 760.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierProgression() {
    const tiers = [
      (Icons.circle, 'Bronze', AppStrings.featureNamesTierBronze, Color(0xFFCD7F32)),
      (Icons.circle, 'Silver', AppStrings.featureNamesTierSilver, Color(0xFF9CA3AF)),
      (Icons.circle, 'Gold', AppStrings.featureNamesTierGold, Color(0xFFC8985E)),
    ];

    return Column(
      children: List.generate(tiers.length, (index) {
        final (_, tierName, unlock, color) = tiers[index];
        final isLast = index == tiers.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
          child: Row(
            children: [
              // Tier badge
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(60), width: 1),
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName,
                      style: AppTypography.labelLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      unlock,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (1000 + index * 150).ms)
            .slideX(
              begin: 0.05,
              end: 0,
              duration: 400.ms,
              delay: (1000 + index * 150).ms,
            );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Mini Tile (self-contained since the silver ornate tile is private
// in collection_screen.dart)
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverMiniTile extends StatelessWidget {
  const _SilverMiniTile({required this.arabic, required this.transliteration});

  final String arabic;
  final String transliteration;

  static const _bgDark = Color(0xFF2A2D3A);
  static const _bgMid = Color(0xFF353847);
  static const _silverBright = Color(0xFFCDD0D6);
  static const _silverCore = Color(0xFFA8A9AD);
  static const _silverDim = Color(0xFF6B6E78);
  static const _glowColor = Color(0xFFB8C8E0);
  static const _frameGold = Color(0xFFC8985E);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 10),
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.2, colors: [_bgMid, _bgDark]),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _MiniPatternPainter(color: _silverDim.withValues(alpha: 0.08))),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _MiniBorderPainter(color: _silverCore.withValues(alpha: 0.5), accentColor: _silverBright.withValues(alpha: 0.7))),
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
                          width: glowSize, height: glowSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: glowSize, height: glowSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(colors: [_glowColor.withValues(alpha: 0.1), _glowColor.withValues(alpha: 0.0)]),
                                ),
                              ),
                              Container(
                                width: medallionSize, height: medallionSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _frameGold.withValues(alpha: 0.4), width: 1.5),
                                ),
                              ),
                              SizedBox(
                                width: medallionSize * 0.65,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    arabic,
                                    style: AppTypography.nameOfAllahDisplay.copyWith(
                                      fontSize: 18, color: _silverBright,
                                      shadows: [Shadow(color: _glowColor.withValues(alpha: 0.5), blurRadius: 12)],
                                    ),
                                    textDirection: TextDirection.rtl, textAlign: TextAlign.center, maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) => Container(
                            width: 4, height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < 2 ? _silverBright : _silverDim.withValues(alpha: 0.3),
                            ),
                          )),
                        ),
                        const SizedBox(height: 4),
                        Text(transliteration, style: AppTypography.labelSmall.copyWith(color: _silverCore.withValues(alpha: 0.7), fontSize: 8), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _MiniPatternPainter extends CustomPainter {
  _MiniPatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.6;
    const cellSize = 20.0;
    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2; final cy = y + cellSize / 2; final r = cellSize * 0.38;
        final path = Path(); final s1 = r * 0.7;
        path.moveTo(cx - s1, cy - s1); path.lineTo(cx + s1, cy - s1); path.lineTo(cx + s1, cy + s1); path.lineTo(cx - s1, cy + s1); path.close();
        path.moveTo(cx, cy - r); path.lineTo(cx + r, cy); path.lineTo(cx, cy + r); path.lineTo(cx - r, cy); path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBorderPainter extends CustomPainter {
  _MiniBorderPainter({required this.color, required this.accentColor});
  final Color color; final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, w - 6, h - 6), const Radius.circular(9)),
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    final ap = Paint()..color = accentColor..style = PaintingStyle.fill;
    const ds = 3.0; const o = 4.0;
    for (final pos in [Offset(o, o), Offset(w - o, o), Offset(o, h - o), Offset(w - o, h - o)]) {
      final d = Path()..moveTo(pos.dx, pos.dy - ds)..lineTo(pos.dx + ds, pos.dy)..lineTo(pos.dx, pos.dy + ds)..lineTo(pos.dx - ds, pos.dy)..close();
      canvas.drawPath(d, ap);
    }
    final mp = Paint()..color = accentColor.withValues(alpha: 0.5)..style = PaintingStyle.fill;
    const ms = 2.5;
    for (final pos in [Offset(w / 2, 3), Offset(w / 2, h - 3), Offset(3, h / 2), Offset(w - 3, h / 2)]) {
      final d = Path()..moveTo(pos.dx, pos.dy - ms)..lineTo(pos.dx + ms, pos.dy)..lineTo(pos.dx, pos.dy + ms)..lineTo(pos.dx - ms, pos.dy)..close();
      canvas.drawPath(d, mp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
