import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_question_scaffold.dart';

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
      icon: Icons.auto_awesome,
    ),
    (
      title: AppStrings.intentionDifficultTime,
      subtitle: AppStrings.intentionDifficultTimeDesc,
      icon: Icons.favorite_border,
    ),
    (
      title: AppStrings.intentionCurious,
      subtitle: AppStrings.intentionCuriousDesc,
      icon: Icons.explore_outlined,
    ),
    (
      title: AppStrings.intentionBuildHabit,
      subtitle: AppStrings.intentionBuildHabitDesc,
      icon: Icons.calendar_today_outlined,
    ),
  ];

  static String _affirmationForIntention(String intention) {
    if (intention == AppStrings.intentionSpiritualGrowth) {
      return AppStrings.affirmSpiritualGrowth;
    } else if (intention == AppStrings.intentionDifficultTime) {
      return AppStrings.affirmDifficultTime;
    } else if (intention == AppStrings.intentionBuildHabit) {
      return AppStrings.affirmBuildHabit;
    } else if (intention == AppStrings.intentionCurious) {
      return AppStrings.affirmCurious;
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingQuestionScaffold(
      progressSegment: 5,
      headline: AppStrings.intentionTitle,
      subtitle: AppStrings.intentionSubtitle,
      continueEnabled: state.intention != null,
      onBack: onBack,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackSurveyAnswered('intention', ref.read(onboardingProvider).intention);
        onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: IntentionOptionCard(
                icon: option.icon,
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: state.intention != null
                ? SizedBox(
                    key: ValueKey(state.intention),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Text(
                        _affirmationForIntention(state.intention!),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
