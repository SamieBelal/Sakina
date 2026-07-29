import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The journey track (One Ship W2-D2) — one step for arriving, one for each Name
/// in the queue, so the full path is 8 and the plan screen already shows
/// **2 of 8** filled.
///
/// The endowment is real, not a head start invented to look like progress: the
/// user did arrive, and they did meet a Name. Nothing here is a streak — a step
/// is a Name met, and a missed day removes none of them.
///
/// No dates and no countdown: the track says how far, never how soon.
///
/// **A bar, not stamps** (founder, 2026-07-29). Eight circles joined by rules
/// read as a checklist and, at this width, as eight things the user now owed.
/// A single filled bar says the same thing in one shape and gives the fill
/// somewhere to animate to.
///
/// **The count says "steps"** for a reason worth keeping. It sits directly under
/// H4's projection ("You know about 10. In 30 days you'll know 40"), and a bare
/// "2 of 8" beside those numbers reads as a contradiction — 8 of what, when you
/// were just told 40? The two are different units: 40 is Names known, 8 is this
/// path. One word fixes it, and it is cheaper than moving either line.
class JourneyStampTrack extends StatelessWidget {
  const JourneyStampTrack({
    required this.totalStamps,
    required this.earnedStamps,
    this.caption,
    super.key,
  });

  /// Slim enough to read as a measure rather than a container.
  static const double trackHeight = 10;

  /// Long enough to be seen filling rather than to have simply arrived full —
  /// this is the one place on the plan screen that shows motion.
  static const Duration fillDuration = Duration(milliseconds: 720);

  final int totalStamps;
  final int earnedStamps;

  /// The plain-language line under the count. Null renders the count alone.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final earned = earnedStamps.clamp(0, totalStamps);
    final fraction = totalStamps <= 0 ? 0.0 : earned / totalStamps;
    // Honour reduce-motion: the bar arrives already filled rather than growing.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final line = caption;

    return Semantics(
      label: '$earned of $totalStamps steps',
      value: '${(fraction * 100).round()} percent',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: trackHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.borderLight.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    // Begins at the destination under reduce-motion so the
                    // tween has nowhere to travel.
                    tween: Tween<double>(
                      begin: reduceMotion ? fraction : 0,
                      end: fraction,
                    ),
                    duration: reduceMotion ? Duration.zero : fillDuration,
                    // The house entrance curve — decelerating, no overshoot.
                    // A bar that springs past its value and settles back would
                    // be claiming progress the user has not made.
                    curve: AppMotion.enter,
                    builder: (_, value, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          // Gold as a FILL, which DESIGN.md 2.3 allows — the
                          // contrast rule it carries is about text.
                          color: AppColors.secondary,
                          borderRadius:
                              BorderRadius.circular(trackHeight / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            '$earned of $totalStamps steps',
            style: AppTypography.labelMedium.copyWith(
              // goldInk, never `secondary`: this is text on a light surface.
              color: AppColors.goldInk,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (line != null && line.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              line,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
