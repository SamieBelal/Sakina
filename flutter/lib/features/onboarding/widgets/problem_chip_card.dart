import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../content/problem_chips.dart';

/// One full-width selection card on the hook screen (One Ship W2-B2, spec ①⑥).
///
/// ≥64pt tall, 16px radius, identical surface and spacing for every chip
/// including the sign chip — its distinction is **typography only** (lighter
/// weight, secondary ink). A tinted surface was rejected on 2026-07-25: it
/// reads as a pre-selected state, and the selected state is already the
/// emerald tint applied here.
///
/// Height is a *minimum*, never a fixed box, so a Dynamic-Type label grows the
/// card instead of clipping.
class ProblemChipCard extends StatelessWidget {
  const ProblemChipCard({
    required this.chip,
    required this.selected,
    required this.onTap,
    super.key,
  });

  static const double minHeight = 64;

  final ProblemChip chip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyLarge.copyWith(
      // Sign card: lighter weight + quieter ink until it is the chosen one.
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: minHeight),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 4,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(chip.label, style: baseStyle),
        ),
      ),
    );
  }
}
