import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Progress theater loading screen for Build a Dua.
class DuaLoading extends StatelessWidget {
  const DuaLoading({required this.progress, super.key});

  final double progress;

  static const _steps = [
    (threshold: 0.0, label: 'Praise'),
    (threshold: 0.25, label: 'Salawat'),
    (threshold: 0.50, label: 'Your ask'),
    (threshold: 0.75, label: 'Closing'),
  ];

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold sparkles
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return Icon(
                  Icons.auto_awesome,
                  color: AppColors.secondary.withValues(alpha: i == 2 ? 1.0 : 0.6),
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
            // Duas header illustration
            SvgPicture.asset(
              'assets/illustrations/main_screens/duas_header.svg',
              height: 120,
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.05, end: 0, duration: 600.ms, delay: 200.ms),
            const SizedBox(height: AppSpacing.lg),
            // Percentage display
            Text(
              '$percentage%',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.primary,
                fontSize: 48,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crafting your dua\u2026',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Horizontal step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_steps.length, (index) {
                final step = _steps[index];
                final isActive = progress >= step.threshold;
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.primaryLight
                            : AppColors.surfaceAltLight,
                      ),
                      child: Icon(
                        isActive
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: isActive
                            ? AppColors.textPrimaryLight
                            : AppColors.textTertiaryLight,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
