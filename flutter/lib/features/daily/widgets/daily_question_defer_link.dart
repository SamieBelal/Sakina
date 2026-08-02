import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// "Not right now" — the daily question's exit (spec M2, plan §2 rule 7).
///
/// **A defer, not a dismissal.** It leaves the question, the reveal and the
/// reward all collectible from the home CTA for the rest of the day, so the
/// copy carries no consequence and no guilt: nothing about missing out,
/// nothing about a streak, nothing on the way back in that references having
/// skipped.
///
/// A quiet link rather than a second button — the escape hatch has to be
/// visible (NN/g heuristic #3) without competing with the answer. Cream at 80%
/// on the canvas, matching `BeatRevealFlow`'s "Return home".
class DailyQuestionDeferLink extends StatelessWidget {
  const DailyQuestionDeferLink({
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Apple's floor. A `minHeight`, so the row grows with Dynamic Type.
  static const double minTapHeight = 44;

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: minTapHeight),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.sacredInk.withValues(alpha: 0.80),
            ),
          ),
        ),
      ),
    );
  }
}
