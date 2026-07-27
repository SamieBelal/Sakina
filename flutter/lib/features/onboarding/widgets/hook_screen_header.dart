import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The hook screen's compact header (One Ship W2-B2, spec ③④).
///
/// The shipped check-in screen's SVG (~19% of screen height) is replaced by a
/// small basmala ornament, and there is deliberately **no progress bar** — the
/// vertical space belongs to the choices.
///
/// The ornament is its own `Text` with an explicit RTL direction so no Arabic
/// glyph ever shares a `Text` with Latin copy (CLAUDE.md RTL-bleed rule).
class HookScreenHeader extends StatelessWidget {
  const HookScreenHeader({
    required this.title,
    required this.subline,
    this.onBack,
    super.key,
  });

  final String title;
  final String subline;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        ExcludeSemantics(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              '﷽',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTypography.quranArabic.copyWith(
                fontSize: 17,
                height: 1.6,
                color: AppColors.secondary.withValues(alpha: 0.8),
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(
              begin: 0.04,
              end: 0,
              duration: 500.ms,
            ),
        const SizedBox(height: AppSpacing.xs + 1),
        Text(
          subline,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w300,
            color: AppColors.textSecondaryLight,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
      ],
    );
  }
}
