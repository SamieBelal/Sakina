import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureQuestsScreen extends StatelessWidget {
  const FeatureQuestsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 6,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero: rank journey card
          Expanded(
            flex: 5,
            child: Center(child: _buildRankJourney()),
          ),

          // Headline + subtitle + CTA
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.featureQuestsHeadlinePostLoop,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureQuestsSubtitlePostLoop,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                const Spacer(),
                OnboardingContinueButton(
                  label: AppStrings.continueButton,
                  onPressed: onNext,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankJourney() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Row(
        children: [
          // Start rank
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withAlpha(30),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    AppStrings.featureQuestsRankStartArabic,
                    style: AppTypography.arabicClassical.copyWith(
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.featureQuestsRankStart,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar + label
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * 0.6,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                          .animate()
                          .scaleX(
                            begin: 0,
                            end: 1,
                            duration: 1200.ms,
                            delay: 600.ms,
                            curve: Curves.easeOut,
                            alignment: Alignment.centerLeft,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt, size: 14, color: AppColors.streakAmber),
                    const SizedBox(width: 2),
                    Text(
                      '10 ranks to discover',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // End rank
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondary.withAlpha(40),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    AppStrings.featureQuestsRankEndArabic,
                    style: AppTypography.arabicClassical.copyWith(
                      fontSize: 18,
                      color: AppColors.secondary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.featureQuestsRankEnd,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 600.ms, delay: 300.ms);
  }
}
