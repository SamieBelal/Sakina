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

class AttributionScreen extends ConsumerWidget {
  const AttributionScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _sources = [
    AppStrings.attributionTikTok,
    AppStrings.attributionInstagram,
    AppStrings.attributionYouTube,
    AppStrings.attributionFriend,
    AppStrings.attributionAppStore,
    AppStrings.attributionMosque,
    AppStrings.attributionTwitter,
    AppStrings.attributionOther,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingQuestionScaffold(
      progressSegment: 12,
      headline: AppStrings.attributionTitle,
      subtitle: AppStrings.attributionSubtitle,
      continueEnabled: state.attribution.isNotEmpty,
      onBack: onBack,
      onContinue: () {
        final value = ref.read(onboardingProvider).attribution;
        ref.read(analyticsProvider).trackSurveyAnswered('attribution', value);
        ref.read(analyticsProvider).trackOnboardingAnswerWithRef(ref, 'attribution', value);
        onNext();
      },
      body: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: List.generate(_sources.length, (index) {
          final source = _sources[index];
          return StruggleChip(
            label: source,
            isSelected: state.attribution.contains(source),
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .toggleAttribution(source),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: (60 * index).ms)
              .slideY(begin: 0.1, end: 0);
        }),
      ),
    );
  }
}
