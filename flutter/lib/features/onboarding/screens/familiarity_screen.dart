import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/onboarding_provider.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_question_scaffold.dart';

class FamiliarityScreen extends ConsumerWidget {
  const FamiliarityScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    (
      key: 'beginner',
      title: AppStrings.familiarityBeginner,
      subtitle: AppStrings.familiarityBeginnerDesc,
      icon: Icons.spa_outlined,
    ),
    (
      key: 'somewhat',
      title: AppStrings.familiaritySomewhat,
      subtitle: AppStrings.familiaritySomewhatDesc,
      icon: Icons.wb_sunny_outlined,
    ),
    (
      key: 'very_familiar',
      title: AppStrings.familiarityVeryFamiliar,
      subtitle: AppStrings.familiarityVeryFamiliarDesc,
      icon: Icons.auto_awesome,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingQuestionScaffold(
      progressSegment: 6,
      headline: AppStrings.familiarityTitle,
      subtitle: AppStrings.familiaritySubtitle,
      continueEnabled: state.familiarity != null,
      onBack: onBack,
      onContinue: () {
        final value = ref.read(onboardingProvider).familiarity;
        ref.read(analyticsProvider).trackSurveyAnswered('familiarity', value);
        ref.read(analyticsProvider).trackOnboardingAnswerWithRef(ref, 'familiarity', value);
        onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_options.length, (index) {
          final option = _options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: IntentionOptionCard(
              icon: option.icon,
              title: option.title,
              subtitle: option.subtitle,
              isSelected: state.familiarity == option.key,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .setFamiliarity(option.key),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (80 * index).ms)
              .slideX(begin: 0.05, end: 0);
        }),
      ),
    );
  }
}
