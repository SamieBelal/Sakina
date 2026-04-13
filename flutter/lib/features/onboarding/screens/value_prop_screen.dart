import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class ValuePropScreen extends StatelessWidget {
  const ValuePropScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _steps = [
    (Icons.favorite_border, AppStrings.valuePropStep1),
    (Icons.auto_awesome, AppStrings.valuePropStep2),
    (Icons.menu_book_outlined, AppStrings.valuePropStep3),
  ];

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
            AppStrings.valuePropHeadline,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.left,
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.05, end: 0, duration: 500.ms),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.valuePropSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.left,
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: SvgPicture.asset(
              'assets/illustrations/onboarding_value_prop.svg',
              height: (MediaQuery.sizeOf(context).height * 0.24).clamp(140, 220),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideY(begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(_steps.length, (index) {
            final (icon, label) = _steps[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          label,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: (500 + index * 150).ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  delay: (500 + index * 150).ms,
                );
          }),
          const Spacer(),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
