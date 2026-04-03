import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

import '../../../core/theme/app_typography.dart';

class StruggleChip extends StatelessWidget {
  const StruggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$label-$isSelected'),
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }
}
