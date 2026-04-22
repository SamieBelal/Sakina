import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart';

class CommonEmotionsScreen extends ConsumerWidget {
  const CommonEmotionsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _emotions = [
    'anxious',
    'grateful',
    'overwhelmed',
    'joyful',
    'lonely',
    'numb',
    'hopeful',
    'angry',
    'sad',
    'grief',
  ];

  static String _label(String id) =>
      '${id.substring(0, 1).toUpperCase()}${id.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    // Note: spec copy says "Pick up to three" on sibling screens but the plan's
    // code for this screen does not enforce a 3-item cap. Per plan, no cap.
    return OnboardingQuestionScaffold(
      progressSegment: 9,
      headline: 'Which emotions come up most for you?',
      subtitle: "We'll tailor your first reflections around these.",
      onBack: onBack,
      continueEnabled: state.commonEmotions.isNotEmpty,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswerWithRef(ref, 'common_emotions', state.commonEmotions);
        onNext();
      },
      body: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _emotions
            .map(
              (e) => StruggleChip(
                label: _label(e),
                isSelected: state.commonEmotions.contains(e),
                onTap: () => ref
                    .read(onboardingProvider.notifier)
                    .toggleCommonEmotion(e),
              ),
            )
            .toList(),
      ),
    );
  }
}
