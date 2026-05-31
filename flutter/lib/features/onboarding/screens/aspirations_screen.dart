import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
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
    // Trimmed-flow refactor (2026-05-25, Option α): `aspirations` was removed
    // from OnboardingState. Legacy screen is preserved for the
    // `onboarding_trim_enabled=false` rollback path but is now stateless.
    return OnboardingQuestionScaffold(
      progressSegment: 9,
      headline: 'Who do you want to become?',
      subtitle: 'Pick up to three.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswerWithRef(ref, 'aspirations', null);
        onNext();
      },
      body: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _aspirations
            .map(
              (a) => StruggleChip(
                label: a.$2,
                isSelected: false,
                onTap: () {},
              ),
            )
            .toList(),
      ),
    );
  }
}
