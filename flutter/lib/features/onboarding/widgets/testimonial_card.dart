import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class TestimonialCard extends StatelessWidget {
  const TestimonialCard({
    required this.quote,
    required this.author,
    required this.location,
    this.initials,
    super.key,
  });

  final String quote;
  final String author;
  final String location;
  final String? initials;

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
              color: AppColors.textPrimaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                ),
                child: Center(
                  child: Text(
                    initials ?? author[0],
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$author \u00b7 $location',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
