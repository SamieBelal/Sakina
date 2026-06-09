import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.currentSegment,
    // 23 segments (indices 0–22) so the bar COMPLETES on the last bar-visible
    // screen. The trimmed flow (active default) tops out at the password screen
    // (`progressSegment: 22`); after it the paywall-flow pages render no bar by
    // design. With the old 25, segments 23–24 were unreachable in the trimmed
    // flow, so the bar showed "2 left" on the last step then vanished. 23 also
    // completes the legacy flow (its max is encouragement at segment 23, which
    // fills all indices). See onboarding screen page lists.
    this.totalSegments = 23,
    super.key,
  });

  final int currentSegment;
  final int totalSegments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (index) {
        final isActive = index <= currentSegment;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < totalSegments - 1 ? AppSpacing.xs : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
