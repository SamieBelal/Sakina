import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class EncouragementScreen extends ConsumerWidget {
  const EncouragementScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static String _headlineForIntention(String? intention) {
    switch (intention) {
      case AppStrings.intentionSpiritualGrowth:
        return AppStrings.encouragementHeadlineSpiritualGrowth;
      case AppStrings.intentionDifficultTime:
        return AppStrings.encouragementHeadlineDifficultTime;
      case AppStrings.intentionBuildHabit:
        return AppStrings.encouragementHeadlineBuildHabit;
      case AppStrings.intentionCurious:
        return AppStrings.encouragementHeadlineCurious;
      default:
        return AppStrings.encouragementHeadlineDefault;
    }
  }

  static String _subtitleForFamiliarity(String? familiarity) {
    switch (familiarity) {
      case 'beginner':
        return AppStrings.encouragementSubtitleBeginner;
      case 'somewhat':
        return AppStrings.encouragementSubtitleSomewhat;
      case 'very_familiar':
        return AppStrings.encouragementSubtitleVeryFamiliar;
      default:
        return AppStrings.encouragementSubtitleDefault;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final headline = _headlineForIntention(state.intention);
    final subtitle = _subtitleForFamiliarity(state.familiarity);

    return OnboardingPageWrapper(
      progressSegment: 7,
      onBack: onBack,
      child: Column(
        children: [
          const Spacer(flex: 2),
          SvgPicture.asset(
            'assets/illustrations/onboarding_encouragement.svg',
            height: 220,
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
              ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            headline,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: AppSpacing.xxl),
          // Decorative Arabic bismillah
          Opacity(
            opacity: 0.75,
            child: Text(
              AppStrings.encouragementBismillah,
              style: AppTypography.nameOfAllahDisplay.copyWith(
                color: AppColors.secondary,
                fontSize: 36,
              ),
              textDirection: TextDirection.rtl,
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 600.ms),
          const Spacer(flex: 3),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
