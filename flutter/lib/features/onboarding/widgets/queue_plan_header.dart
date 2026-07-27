import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The queue plan screen's heading (One Ship W2-D2): the title, the pacing line
/// the carrying-duration answer bought, and an optional back affordance.
///
/// No progress bar — the plan screen is an artifact the user reads, not a step
/// they are being counted through.
class QueuePlanHeader extends StatelessWidget {
  const QueuePlanHeader({
    required this.headline,
    required this.pacingLine,
    this.onBack,
    super.key,
  });

  final String headline;
  final String pacingLine;
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
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          pacingLine,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
