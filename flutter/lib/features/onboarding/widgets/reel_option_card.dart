import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One full-width option on a reel-flow question screen (One Ship W2-D1/D3).
///
/// The hook screen's card, generalised past [ProblemChip]: same ≥64pt minimum,
/// same 16px radius, same emerald selected tint, so a user who tapped a chip on
/// screen one meets exactly the same affordance for every question after it.
/// Height stays a minimum so a Dynamic-Type label grows the card.
class ReelOptionCard extends StatelessWidget {
  const ReelOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  static const double minHeight = 64;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
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
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
