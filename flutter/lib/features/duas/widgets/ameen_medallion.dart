import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';

/// The آمين hero for the Build-a-Dua Ameen screen — gold calligraphy over a
/// soft pulsing gold halo, composed for the emerald **sacred canvas**.
class AmeenMedallion extends StatelessWidget {
  const AmeenMedallion({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.28),
                  AppColors.secondary.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.92, end: 1.08, duration: 2400.ms),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.auto_awesome,
                    color: AppColors.secondary
                        .withValues(alpha: i == 2 ? 1.0 : 0.55),
                    size: i == 2 ? 20 : 14,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 600.ms,
                        delay: (i * 80).ms,
                      )
                      .fadeIn(duration: 400.ms, delay: (i * 80).ms);
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(height: 33),
              AdjustedArabicDisplay(
                text: 'آمين',
                style: AppTypography.nameOfAllahDisplay.copyWith(
                  color: AppColors.secondary,
                  fontSize: 76,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 900.ms).scaleXY(
                    begin: 0.82,
                    end: 1.0,
                    duration: 900.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 20),
              Text(
                'Ameen',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.sacredInk,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'May Allah accept your dua',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.sacredInkSoft,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section card on the canvas — a translucent cream panel with a gold accent
/// bar header (the sacred-canvas counterpart of the old `_ameenSectionCard`).
class AmeenSectionCard extends StatelessWidget {
  const AmeenSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.sacredPattern,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.sacredTrack),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.sacredInk,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.sacredInkFaint,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
