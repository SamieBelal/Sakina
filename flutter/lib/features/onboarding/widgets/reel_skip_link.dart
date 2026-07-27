import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The quiet decline path under a reel-flow question (One Ship W2-D3).
///
/// A link, never a button: declining to answer must not compete with answering.
/// The tap target is still 44pt — quiet is a visual register, not a smaller
/// target.
class ReelSkipLink extends StatelessWidget {
  const ReelSkipLink({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
    );
  }
}
