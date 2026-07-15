import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Confirmation toast when a related dua is saved/unsaved from the Ameen
/// screen. The heart fill alone was too quiet to register — especially during
/// the guided tour, where tapping the heart immediately moves the spotlight to
/// the Journal tab. Styled to match the warm gift-card toast. Top-level +
/// visibleForTesting so it can be exercised without pumping the whole screen.
/// (Public — also called in production from the built-dua Ameen screen.)
void showRelatedDuaSnack(BuildContext context, {required bool saved}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              saved ? 'Saved to Journal' : 'Removed from Journal',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimaryLight),
            ),
          ],
        ),
      ),
    );
}

/// The save-heart on a Related Dua row. Extracted so the save → fill feedback
/// is a self-contained, testable animation: an [AnimatedSwitcher] cross-scales
/// the outline → filled icon with an `easeOutBack` overshoot, so the "it
/// filled" moment reads as a deliberate pop even if the surrounding card
/// repaints. The keyed [Icon] is what drives the switch when [isSaved] flips.
class RelatedDuaHeart extends StatelessWidget {
  const RelatedDuaHeart({
    super.key,
    required this.isSaved,
    required this.onTap,
  });

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isSaved ? Icons.favorite : Icons.favorite_outline,
            key: ValueKey<bool>(isSaved),
            color: isSaved ? AppColors.primary : AppColors.textTertiaryLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
