import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The journey track (One Ship W2-D2) — one stamp for arriving, one for each
/// Name in the queue, so the full path is 8 and the plan screen already shows
/// **2 of 8** filled.
///
/// This replaces the legacy `JourneyTimeline` for the reel flow. The endowment
/// is real, not a head start invented to look like progress: the user did
/// arrive, and they did meet a Name. Nothing here is a streak — a stamp is a
/// Name met, and a missed day removes none of them.
///
/// No dates and no countdown: the track says how far, never how soon.
class JourneyStampTrack extends StatelessWidget {
  const JourneyStampTrack({
    required this.totalStamps,
    required this.earnedStamps,
    this.caption,
    super.key,
  });

  static const double stampSize = 20;

  final int totalStamps;
  final int earnedStamps;

  /// The plain-language line under the count. Null renders the count alone.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final earned = earnedStamps.clamp(0, totalStamps);
    return Semantics(
      label: '$earned of $totalStamps stamps',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < totalStamps; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= earned - 1
                          ? AppColors.secondary
                          : AppColors.borderLight,
                    ),
                  ),
                _Stamp(filled: i < earned)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (80 * i).ms),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            '$earned of $totalStamps',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.goldInk,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
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

class _Stamp extends StatelessWidget {
  const _Stamp({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: JourneyStampTrack.stampSize,
      height: JourneyStampTrack.stampSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.secondary : AppColors.surfaceLight,
        border: Border.all(
          color: filled ? AppColors.secondary : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: filled
          ? const Icon(
              Icons.check_rounded,
              size: 13,
              color: AppColors.textOnPrimary,
            )
          : null,
    );
  }
}
