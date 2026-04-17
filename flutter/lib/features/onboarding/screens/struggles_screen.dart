import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/onboarding_provider.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart';

class StrugglesScreen extends ConsumerWidget {
  const StrugglesScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _struggles = [
    AppStrings.struggleAnxiety,
    AppStrings.struggleSadness,
    AppStrings.struggleAnger,
    AppStrings.struggleLoneliness,
    AppStrings.struggleMotivation,
    AppStrings.struggleGratitude,
    AppStrings.struggleGrief,
    AppStrings.struggleOverwhelm,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingQuestionScaffold(
      progressSegment: 11,
      headline: AppStrings.strugglesTitle,
      subtitle: AppStrings.strugglesSubtitle,
      continueEnabled: state.struggles.isNotEmpty,
      onBack: onBack,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackSurveyAnswered('struggles', ref.read(onboardingProvider).struggles);
        onNext();
      },
      body: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: List.generate(_struggles.length, (index) {
          final struggle = _struggles[index];
          return StruggleChip(
            label: struggle,
            isSelected: state.struggles.contains(struggle),
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .toggleStruggle(struggle),
          )
              .animate()
              .fadeIn(
                duration: 400.ms,
                delay: (60 * index).ms,
              )
              .slideY(begin: 0.1, end: 0);
        }),
      ),
    );
  }
}
