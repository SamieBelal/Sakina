import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/testimonial_card.dart';

class SocialProofScreen extends ConsumerWidget {
  const SocialProofScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingPageWrapper(
      progressSegment: 18,
      onBack: onBack,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  // Rating badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.streakAmber,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          AppStrings.socialProofRating,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          ' \u00b7 ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          AppStrings.socialProofRatingLabel,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: AppSpacing.xl),
                  // Headline
                  Text(
                    AppStrings.socialProofTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 100.ms)
                      .slideY(begin: 0.03, end: 0, duration: 300.ms),
                  const SizedBox(height: AppSpacing.xl),
                  // Avatar stack + user count
                  Column(
                    children: [
                      const _AvatarStack(),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${AppStrings.socialProofUserCount}+ ${AppStrings.socialProofUserCountLabel}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: AppSpacing.xl),
                  // Single testimonial
                  const TestimonialCard(
                    quote: AppStrings.socialProofTestimonial1,
                    author: AppStrings.socialProofTestimonial1Author,
                    location: AppStrings.socialProofTestimonial1Location,
                    initials: 'A',
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  const SizedBox(height: AppSpacing.md),
                  const TestimonialCard(
                    quote: AppStrings.socialProofTestimonial2,
                    author: AppStrings.socialProofTestimonial2Author,
                    location: AppStrings.socialProofTestimonial2Location,
                    initials: 'Y',
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  static const _initials = ['S', 'A', 'Y', 'M', 'F'];
  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.streakAmber,
    AppColors.primaryDark,
    AppColors.primary,
  ];
  static const double _size = 40;
  static const double _overlap = 12;

  @override
  Widget build(BuildContext context) {
    final totalWidth = _size + (_initials.length - 1) * (_size - _overlap);
    return SizedBox(
      width: totalWidth,
      height: _size,
      child: Stack(
        children: List.generate(_initials.length, (i) {
          return Positioned(
            left: i * (_size - _overlap),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colors[i],
                border: Border.all(
                  color: AppColors.backgroundLight,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _initials[i],
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
