import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';
import '../widgets/struggle_chip.dart';

class AspirationsScreen extends ConsumerWidget {
  const AspirationsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _aspirations = <(String, String)>[
    ('morePatient', 'More patient'),
    ('moreGrateful', 'More grateful'),
    ('closerToAllah', 'Closer to Allah'),
    ('morePresent', 'More present'),
    ('strongerFaith', 'Stronger faith'),
    ('moreConsistent', 'More consistent'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    // Note: copy says "Pick up to three" but the plan does not enforce a
    // 3-item cap in code. Following the plan: no cap.
    return OnboardingQuestionScaffold(
      progressSegment: 13,
      headline: 'Who do you want to become?',
      subtitle: 'Pick up to three.',
      onBack: onBack,
      continueEnabled: state.aspirations.isNotEmpty,
      onContinue: onNext,
      body: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _aspirations
            .map(
              (a) => StruggleChip(
                label: a.$2,
                isSelected: state.aspirations.contains(a.$1),
                onTap: () => ref
                    .read(onboardingProvider.notifier)
                    .toggleAspiration(a.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}
