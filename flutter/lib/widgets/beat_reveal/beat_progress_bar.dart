import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';

/// The segmented progress bar at the top of the beat reveal flow (one segment
/// per screen, Glorify / IG-story style). Gold fill on the [AppColors.sacredTrack]
/// track. Decorative — excluded from the semantics tree (the per-beat "beat N of
/// M" announcement carries progress for screen-reader users).
class BeatProgressBar extends StatelessWidget {
  final int count;
  final int currentIndex;

  const BeatProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: List.generate(count, (i) {
          final filled = i <= currentIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: filled ? AppColors.secondary : AppColors.sacredTrack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
