import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The heading on a reel-flow question screen (One Ship W2-D1/D3).
///
/// The hook screen's header typography without its basmala ornament: the
/// ornament opens the journey once, and repeating it above every question after
/// would spend it. No progress bar either — when the flow wants one, the shared
/// `OnboardingPageWrapper` supplies it (and its own back affordance, which is
/// why [onBack] is optional here).
class ReelQuestionHeader extends StatelessWidget {
  const ReelQuestionHeader({
    required this.headline,
    required this.subline,
    this.onBack,
    super.key,
  });

  final String headline;
  final String subline;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        Semantics(
          header: true,
          child: Text(
            headline,
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(
              begin: 0.04,
              end: 0,
              duration: 500.ms,
            ),
        const SizedBox(height: AppSpacing.xs + 1),
        Text(
          subline,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w300,
            color: AppColors.textSecondaryLight,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
      ],
    );
  }
}
