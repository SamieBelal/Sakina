import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';

/// One quick-fill chip under the daily question's text field (W4 Wave 2).
///
/// The onboarding hook screen's [ProblemChipCard] cannot be reused here: it is
/// built for a cream canvas (`textPrimaryLight` on `backgroundLight`, a
/// `borderLight` hairline) and every one of those colours is unreadable on the
/// emerald sacred canvas. The *taxonomy* is shared — [ProblemChip.label] is
/// verbatim from `problem_chips.dart`, never re-worded here — the treatment is
/// not.
///
/// Demoted on purpose: an outlined pill, not a filled row, because the field
/// above it is the primary input (spec M2). The outline is `sacredTrack` (22%
/// cream), the label `sacredInk` — gold is barred from text on this canvas
/// (DESIGN.md §2.3 / `app_colors.dart`).
class DailyQuestionChip extends StatelessWidget {
  const DailyQuestionChip({
    required this.chip,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    super.key,
  });

  /// Apple's floor, and the reason this is a `constraints.minHeight` rather
  /// than a fixed height: the pill grows with Dynamic Type instead of clipping.
  static const double minTapHeight = 44;

  final ProblemChip chip;

  /// This chip owns the commit in flight.
  final bool selected;

  /// Another chip owns it — recede so the chosen line reads alone.
  final bool dimmed;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: chip.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: AppMotion.recede,
          curve: AppMotion.enter,
          opacity: dimmed ? ProblemChipCard.unselectedFade : 1,
          child: AnimatedContainer(
            duration: AppMotion.feedback,
            curve: AppMotion.enter,
            constraints: const BoxConstraints(minHeight: minTapHeight),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.sacredInk.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.sacredTrack),
            ),
            child: Text(
              chip.label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.sacredInk,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
