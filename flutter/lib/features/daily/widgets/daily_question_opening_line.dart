import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';

/// The ʿazm the user wrote at the end of their last night, opening this one
/// (Wave C, C4).
///
/// **It asks nothing.** No "did you?", no checkbox, no streak attached — a
/// resolve handed back with an obligation is a debt collector, and this surface
/// is deliberately built with nothing guilt-shaped on it. It reminds, and then
/// the question follows underneath.
///
/// Latin script only, and on the emerald canvas, so the ink is cream:
/// [AppColors.sacredInkSoft] is 70% of `sacredInk`, which sits above the
/// canvas's 80%-cream floor for supporting text (DESIGN.md). The gold rule is
/// respected by omission — there is no gold text here, only the hairline rule.
class DailyQuestionOpeningLine extends StatelessWidget {
  const DailyQuestionOpeningLine({required this.text, super.key});

  /// The resolve, verbatim. Never emitted anywhere.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.sacredInkFaint, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            MuhasabahCompletionCopy.azmResurfaceLead,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.sacredInkFaint,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.sacredInkSoft,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
