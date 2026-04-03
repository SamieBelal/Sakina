import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/demo_result_card.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/testimonial_card.dart';
import '../widgets/typing_text_widget.dart';

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
      progressSegment: 3,
      onBack: onBack,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.socialProofTitle,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Inline typing demo
                  const _InlineDemo()
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),
                  const SizedBox(height: AppSpacing.lg),
                  // Compact stats row
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppStrings.socialProofUserCount}+',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          ' ${AppStrings.socialProofUserCountLabel}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.streakAmber,
                        ),
                        Text(
                          ' ${AppStrings.socialProofRating}',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const TestimonialCard(
                    quote: AppStrings.socialProofTestimonial1,
                    author: AppStrings.socialProofTestimonial1Author,
                    location: AppStrings.socialProofTestimonial1Location,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  const SizedBox(height: AppSpacing.md),
                  const TestimonialCard(
                    quote: AppStrings.socialProofTestimonial2,
                    author: AppStrings.socialProofTestimonial2Author,
                    location: AppStrings.socialProofTestimonial2Location,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
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
        ],
      ),
    );
  }
}

class _InlineDemo extends StatefulWidget {
  const _InlineDemo();

  @override
  State<_InlineDemo> createState() => _InlineDemoState();
}

class _InlineDemoState extends State<_InlineDemo> {
  bool _showResult = false;

  void _onTypingComplete() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showResult = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.howAreYouFeeling,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Mini text field with typing animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TypingTextWidget(
              text: AppStrings.hookDemoFeeling,
              startDelay: const Duration(seconds: 1),
              charDuration: const Duration(milliseconds: 60),
              onComplete: _onTypingComplete,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          if (_showResult) ...[
            const SizedBox(height: AppSpacing.md),
            const _CompactResult(data: DemoResultData.asSalam),
          ],
        ],
      ),
    );
  }
}

class _CompactResult extends StatelessWidget {
  const _CompactResult({required this.data});

  final DemoResultData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            data.nameArabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              fontSize: 28,
              color: AppColors.secondary,
            ),
            textDirection: TextDirection.rtl,
          ),
          Text(
            '${data.nameTransliteration} \u00b7 ${data.nameEnglish}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '"${data.verseTranslation}"',
            style: AppTypography.bodySmall.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            data.verseReference,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
