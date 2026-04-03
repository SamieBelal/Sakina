import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.currentSegment,
    this.totalSegments = 5,
    super.key,
  });

  final int currentSegment;
  final int totalSegments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (index) {
        final isActive = index < currentSegment;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < totalSegments - 1 ? AppSpacing.xs : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 4,
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
