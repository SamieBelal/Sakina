import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Loading screen shown while a reflection is being generated.
/// Matches the onboarding first-checkin loading style: pulsing dots,
/// Bismillah Arabic text, title + subtitle.
class ReflectLoading extends StatelessWidget {
  const ReflectLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Three pulsing dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 600.ms, delay: (i * 200).ms)
                  .then()
                  .fadeOut(duration: 600.ms);
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Decorative Bismillah
          Opacity(
            opacity: 0.75,
            child: Text(
              '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650',
              style: AppTypography.nameOfAllahDisplay.copyWith(
                color: AppColors.secondary,
                fontSize: 36,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Finding your reflection\u2026',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Searching Allah\u2019s names and Quran',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
