import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The queue plan screen's heading (One Ship W2-D2): the title, and the two
/// quiet lines the carrying-duration and told-anyone answers bought.
///
/// **No back affordance and no bar of its own** (founder, 2026-07-29). Both used
/// to be this widget's problem because the screen built a bare `Scaffold` —
/// which is exactly why it was the one page in the flow with a naked chevron and
/// no progress bar. The screen now wears `OnboardingPageWrapper` like every
/// other page, so the chrome belongs to the wrapper and this widget is only the
/// words.
///
/// [pacingLine] is the screen's ONLY subline (founder, 2026-07-29). A second
/// one for H3 lived here briefly; two grey blocks under one headline read as
/// two competing sublines, and the screen already had three more below.
class QueuePlanHeader extends StatelessWidget {
  const QueuePlanHeader({
    required this.headline,
    required this.pacingLine,
    super.key,
  });

  final String headline;
  final String pacingLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
