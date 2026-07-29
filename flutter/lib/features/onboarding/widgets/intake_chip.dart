import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One chip in the H5 cloud (One Ship W2-H, spec §5).
///
/// **No checkbox glyph.** The hook screen's borderless direction applies here
/// too: the only thing that draws attention to a chip is the emerald tint it
/// takes when the user chooses it — the same `primaryLight` fill
/// `ProblemChipCard` uses, so a user who tapped a row on screen one recognises
/// the state instantly. A tick box would announce "form", which is the whole
/// thing this treatment exists to avoid.
///
/// **[dimmed] is the cap made visible.** When three chips are already held, the
/// unselected ones recede and stop responding — the refusal has to be legible
/// *before* the fourth tap, not as a silent no-op after it. The three that are
/// held stay fully live, so the user can always trade one out.
///
/// Height is a minimum, not a fixed value, so a Dynamic-Type label grows the
/// chip rather than clipping.
class IntakeChip extends StatelessWidget {
  const IntakeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
    super.key,
  });

  /// Apple's tap-target floor. Chips are lighter than the hook screen's 64pt
  /// rows by design — that is the point of the treatment — but not smaller than
  /// a finger.
  static const double minHeight = 44;

  static const double _dimmedFade = 0.35;

  final String label;
  final bool selected;

  /// The cap is reached and this chip is not one of the held ones.
  final bool dimmed;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: !dimmed,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: dimmed ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          // Unhurried recede against a fast confirm — the same asymmetry the
          // hook screen's rows use.
          duration: AppMotion.recede,
          curve: AppMotion.enter,
          opacity: dimmed ? _dimmedFade : 1,
          child: AnimatedContainer(
            duration: AppMotion.feedback,
            curve: AppMotion.enter,
            constraints: const BoxConstraints(minHeight: minHeight),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryLight
                  : AppColors.surfaceAltLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 16,
                color: selected
                    ? AppColors.primaryDark
                    : AppColors.textPrimaryLight,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
