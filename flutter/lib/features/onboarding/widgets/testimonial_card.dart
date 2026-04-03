import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class TestimonialCard extends StatelessWidget {
  const TestimonialCard({
    required this.quote,
    required this.author,
    required this.location,
    super.key,
  });

  final String quote;
  final String author;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (_) => const Icon(
                Icons.star,
                size: 16,
                color: AppColors.streakAmber,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            quote,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$author \u00b7 $location',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
