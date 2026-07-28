import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../content/problem_chips.dart';

/// One selectable line on the hook screen (One Ship W2-B2, spec ①⑥ — visual
/// treatment revised 2026-07-27 after the founder's first simulator pass).
///
/// **Borderless by design.** The first build gave every option a white fill and
/// a 1.5px border, so the screen rendered as seven stacked rectangles — the
/// single biggest reason it read as a form rather than an invitation. The row
/// now sits directly on the canvas with a hairline rule beneath it; the only
/// thing that draws a shape is the option the user actually chooses. Nothing
/// about the tap target changed: still ≥64pt, still the whole row.
///
/// **Unchosen rows recede.** When a selection is in flight the others drop to
/// [_unselectedFade] opacity, so the screen resolves to the single line the
/// user picked instead of holding seven live-looking choices behind the
/// transition.
///
/// The sign row keeps its typography-only distinction (lighter weight, quieter
/// ink) — a tinted surface was rejected on 2026-07-25 because it reads as
/// pre-selected, and the selected state is exactly that emerald tint.
class ProblemChipCard extends StatelessWidget {
  const ProblemChipCard({
    required this.chip,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
    this.showRule = true,
    this.rowHeight = minHeight,
    super.key,
  });

  static const double minHeight = 64;

  /// Compact rows for short screens. 56 keeps the list — and crucially the
  /// escape hatch — above the fold on an iPhone SE while staying well clear of
  /// Apple's 44pt tap floor.
  static const double compactMinHeight = 56;

  static const double _unselectedFade = 0.35;

  /// Minimum row height; the row still grows for Dynamic Type.
  final double rowHeight;

  final ProblemChip chip;
  final bool selected;

  /// Another row owns the commit — recede so the chosen line reads alone.
  final bool dimmed;

  /// Hairline rule beneath the row; suppressed on the last one.
  final bool showRule;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyLarge.copyWith(
      fontSize: 17.5,
      fontWeight: chip.isSign ? FontWeight.w300 : FontWeight.w400,
      color: chip.isSign && !selected
          ? AppColors.textSecondaryLight
          : AppColors.textPrimaryLight,
      height: 1.35,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: chip.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          // Unhurried recede — the asymmetry against the fast confirm below is
          // deliberate: the answer is acknowledged instantly, the alternatives
          // withdraw gently.
          duration: AppMotion.recede,
          curve: AppMotion.enter,
          opacity: dimmed ? _unselectedFade : 1,
          child: AnimatedContainer(
            // Fast on purpose (~140ms). A slow tint on an emotionally loaded
            // answer reads as the app deliberating over what was just admitted.
            duration: AppMotion.feedback,
            curve: AppMotion.enter,
            constraints: BoxConstraints(minHeight: rowHeight),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                bottom: BorderSide(
                  // The rule belongs to the list, not the row: it disappears
                  // under the chosen line and under the last row.
                  color: (showRule && !selected)
                      ? AppColors.borderLight.withValues(alpha: 0.55)
                      : Colors.transparent,
                ),
              ),
            ),
            child: Text(chip.label, style: baseStyle),
          ),
        ),
      ),
    );
  }
}
