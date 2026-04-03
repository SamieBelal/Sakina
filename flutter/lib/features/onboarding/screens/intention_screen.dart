import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class IntentionScreen extends ConsumerWidget {
  const IntentionScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    (
      title: AppStrings.intentionSpiritualGrowth,
      subtitle: AppStrings.intentionSpiritualGrowthDesc,
    ),
    (
      title: AppStrings.intentionDifficultTime,
      subtitle: AppStrings.intentionDifficultTimeDesc,
    ),
    (
      title: AppStrings.intentionCurious,
      subtitle: AppStrings.intentionCuriousDesc,
    ),
    (
      title: AppStrings.intentionBuildHabit,
      subtitle: AppStrings.intentionBuildHabitDesc,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingPageWrapper(
      progressSegment: 1,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.intentionTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.intentionSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: IntentionOptionCard(
                title: option.title,
                subtitle: option.subtitle,
                isSelected: state.intention == option.title,
                onTap: () => ref
                    .read(onboardingProvider.notifier)
                    .setIntention(option.title),
              ),
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: (80 * index).ms,
                )
                .slideX(begin: 0.05, end: 0);
          }),
          const Spacer(),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
            enabled: state.intention != null,
          ),
        ],
      ),
    );
  }
}
