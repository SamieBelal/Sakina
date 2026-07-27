import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The wardrobe's Lanterns / Backdrops switch, as a segmented pill.
///
/// Replaces a Material `TabBar`, which drew a hard divider rule across the
/// screen plus an underline indicator — a heavy, utilitarian treatment on a
/// surface whose whole job is to feel like a jewellery box. A segmented pill
/// carries two options with far less visual weight: the track recedes into the
/// page and only the selected segment lifts.
///
/// Purely presentational — it reports taps and renders [index]; the screen owns
/// the tab state so this can never disagree with what the grid is showing.
class WardrobeTabPills extends StatelessWidget {
  const WardrobeTabPills({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // A recessed track: slightly deeper than the page so the raised
          // selected pill reads as sitting on top of it.
          color: AppColors.secondary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(child: _segment(i)),
          ],
        ),
      ),
    );
  }

  Widget _segment(int i) {
    final selected = i == index;
    return Semantics(
      button: true,
      selected: selected,
      label: labels[i],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selected) return;
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        // Animated so the selection slides in rather than snapping — the
        // motion is what makes a segmented control feel physical.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: AppTypography.labelLarge.copyWith(
              color: selected
                  ? AppColors.sacredInk
                  : AppColors.textSecondaryLight,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(labels[i]),
          ),
        ),
      ),
    );
  }
}
