import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';

/// The seven approved [problemChips], demoted beneath the daily question's text
/// field as quick-fill (spec M2).
///
/// **The taxonomy is shared, not forked.** Labels come straight from
/// `problem_chips.dart` in its approved order, so a tap here segments
/// identically to the same tap in onboarding — which is the whole reason
/// `problem_category` stays comparable across the two surfaces.
class DailyQuestionChipList extends StatelessWidget {
  const DailyQuestionChipList({
    required this.leadLabel,
    required this.selectedChipKey,
    required this.onChipTapped,
    super.key,
  });

  final String leadLabel;

  /// The chip whose commit is in flight; every other chip recedes.
  final String? selectedChipKey;

  final ValueChanged<ProblemChip> onChipTapped;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final anySelected = selectedChipKey != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          leadLabel,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.sacredInk.withValues(alpha: 0.70),
          ),
        )
            .animate(delay: AppMotion.listStart)
            .fadeIn(duration: AppMotion.item, curve: AppMotion.enter),
        const SizedBox(height: AppSpacing.sm),
        // Staggered so the chips arrive while the field above is still
        // settling rather than queuing behind it (`app_motion.dart` — layers
        // overlap). 40ms × 7 keeps the tail inside the ~900ms budget.
        for (var i = 0; i < problemChips.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DailyQuestionChip(
              chip: problemChips[i],
              selected: selectedChipKey == problemChips[i].chipKey,
              dimmed:
                  anySelected && selectedChipKey != problemChips[i].chipKey,
              onTap: () => onChipTapped(problemChips[i]),
            )
                .animate(
                    delay: AppMotion.listStart + AppMotion.stagger * (i + 1))
                .fadeIn(duration: AppMotion.item, curve: AppMotion.enter)
                .moveY(
                  begin: reduceMotion ? 0 : AppMotion.riseSmall,
                  end: 0,
                  duration: AppMotion.item,
                  curve: AppMotion.enter,
                ),
          ),
      ],
    );
  }
}
