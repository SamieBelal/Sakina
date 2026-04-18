import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_question_scaffold.dart';

class PrayerFrequencyScreen extends ConsumerWidget {
  const PrayerFrequencyScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    ('fivePlus', 'Five times a day', 'Al-hamdulillah.'),
    ('someDaily', 'Some days', 'Every prayer counts.'),
    ('fridaysOnly', 'Mostly Fridays', 'A good anchor.'),
    ('rarely', 'Not often', 'No judgement here.'),
    ('learning', 'Still learning', 'You\'re welcome here.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 4,
      headline: 'How often do you pray right now?',
      subtitle: 'Honesty helps us meet you where you are.',
      onBack: onBack,
      continueEnabled: state.prayerFrequency != null,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('prayer_frequency', state.prayerFrequency);
        onNext();
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options
            .map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: IntentionOptionCard(
                    title: opt.$2,
                    subtitle: opt.$3,
                    isSelected: state.prayerFrequency == opt.$1,
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .setPrayerFrequency(opt.$1),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
