import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The daily question's title plus its one-line taught gloss.
///
/// Marked `header: true` so VoiceOver announces the question first and a rotor
/// jump lands on it. Both lines are Latin script — the gloss transliterates
/// muḥāsabah rather than setting it in Arabic, so no `Text` here mixes
/// directions.
class DailyQuestionHeader extends StatelessWidget {
  const DailyQuestionHeader({
    required this.title,
    required this.gloss,
    super.key,
  });

  final String title;

  /// Taught, never a button label (plan §4).
  final String gloss;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.sacredInk,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          gloss,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.sacredInk.withValues(alpha: 0.70),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
