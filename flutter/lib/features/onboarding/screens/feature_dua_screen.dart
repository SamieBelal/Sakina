import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureDuaScreen extends StatelessWidget {
  const FeatureDuaScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _steps = [
    (Icons.volunteer_activism_outlined, AppStrings.featureDuaStep1),
    (Icons.favorite_border, AppStrings.featureDuaStep2),
    (Icons.front_hand_outlined, AppStrings.featureDuaStep3),
    (Icons.auto_awesome_outlined, AppStrings.featureDuaStep4),
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 5,
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
                    AppStrings.featureDuaHeadlinePostLoop,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.featureDuaSubtitlePostLoop,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                  const SizedBox(height: AppSpacing.xl),

                  // Mock dua card
                  _buildDuaCard(context),

                  const SizedBox(height: AppSpacing.lg),

                  // 4-step flow
                  ...List.generate(_steps.length, (index) {
                    final (icon, label) = _steps[index];
                    return _buildStepRow(icon, label, index);
                  }),

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

  Widget _buildDuaCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gold accent line
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Arabic sample
          Text(
            AppStrings.featureDuaSampleArabic,
            style: AppTypography.quranArabic.copyWith(
              color: AppColors.textPrimaryLight,
              fontSize: 26,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Translation
          Text(
            AppStrings.featureDuaSampleTranslation,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Gold accent line
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 600.ms, delay: 300.ms)
        .then()
        .shimmer(
          duration: 1500.ms,
          delay: 400.ms,
          color: AppColors.secondary.withAlpha(25),
        );
  }

  Widget _buildStepRow(IconData icon, String label, int index) {
    final isLast = index == _steps.length - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        children: [
          // Step number circle
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.md),
          // Connecting concept
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          // Step number
          Text(
            '${index + 1}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (600 + index * 120).ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: (600 + index * 120).ms);
  }
}
