import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_question_scaffold.dart';

class AgeRangeScreen extends ConsumerWidget {
  const AgeRangeScreen({required this.onNext, required this.onBack, super.key});
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    ('13_17', '13-17'),
    ('18_24', '18-24'),
    ('25_34', '25-34'),
    ('35_44', '35-44'),
    ('45_54', '45-54'),
    ('55plus', '55+'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 4,
      headline: 'How old are you?',
      subtitle: 'So we can tune the tone for you.',
      onBack: onBack,
      continueEnabled: state.ageRange != null,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('age_range', state.ageRange);
        onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: IntentionOptionCard(
              icon: Icons.person_outline,
              title: opt.$2,
              subtitle: '',
              isSelected: state.ageRange == opt.$1,
              onTap: () =>
                  ref.read(onboardingProvider.notifier).setAgeRange(opt.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}
