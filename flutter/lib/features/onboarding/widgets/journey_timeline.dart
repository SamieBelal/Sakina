import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One milestone in the journey timeline. Heading is the day label
/// ("Day 1 — Today"); lines are the qualitative outcome statements
/// rendered as a small bulleted block below the heading.
class JourneyMilestone {
  const JourneyMilestone({
    required this.heading,
    required this.lines,
  });

  final String heading;
  final List<String> lines;
}

/// Vertical timeline used by `YourJourneyScreen` (page 24). Renders each
/// milestone as a card with a gold dot on the left edge connected by a
/// thin gold line. Cards fade in top-to-bottom with a 200ms stagger.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({
    required this.milestones,
    super.key,
  });

  final List<JourneyMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < milestones.length; i++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Rail(isFirst: i == 0, isLast: i == milestones.length - 1),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _MilestoneCard(milestone: milestones[i])),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 380.ms, delay: (i * 200).ms)
              .slideY(begin: 0.05, end: 0, duration: 380.ms),
          if (i < milestones.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.isFirst, required this.isLast});

  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: Column(
        children: [
          // Top half-line (skipped for first card).
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : AppColors.secondary,
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
              border: Border.all(
                color: AppColors.backgroundLight,
                width: 2,
              ),
            ),
          ),
          // Bottom half-line (skipped for last card).
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone});

  final JourneyMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            milestone.heading,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final line in milestone.lines) ...[
            Text(
              line,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
            if (line != milestone.lines.last)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
