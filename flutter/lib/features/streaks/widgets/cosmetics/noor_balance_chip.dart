import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The Noor currency pill (wardrobe/companion header). Gold is a NON-TEXT accent
/// only (design rule): the star glyph is gold, the number is cream/ink for
/// contrast. `onCanvas` renders it for the emerald sacred canvas (cream text),
/// otherwise for warm cream light mode (ink text).
///
/// Display-only — it never reads or writes the economy; the balance is passed
/// down from `CosmeticsState.noorBalance`.
class NoorBalanceChip extends StatelessWidget {
  const NoorBalanceChip({
    super.key,
    required this.balance,
    this.onCanvas = false,
  });

  final int balance;
  final bool onCanvas;

  @override
  Widget build(BuildContext context) {
    final textColor =
        onCanvas ? AppColors.sacredInk : AppColors.textPrimaryLight;
    final bg = onCanvas
        ? AppColors.sacredInk.withValues(alpha: 0.10)
        : AppColors.secondaryLight;
    return Semantics(
      container: true,
      // One node: "Noor balance: 240", not "Noor balance: 240" then "240".
      excludeSemantics: true,
      label: 'Noor balance: $balance',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$balance',
              style: AppTypography.labelLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
