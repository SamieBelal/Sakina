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

class QuranConnectionScreen extends ConsumerWidget {
  const QuranConnectionScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [
    (
      key: 'daily',
      title: AppStrings.quranDaily,
      subtitle: AppStrings.quranDailyDesc,
      icon: Icons.wb_sunny,
    ),
    (
      key: 'weekly',
      title: AppStrings.quranWeekly,
      subtitle: AppStrings.quranWeeklyDesc,
      icon: Icons.date_range_outlined,
    ),
    (
      key: 'occasionally',
      title: AppStrings.quranOccasionally,
      subtitle: AppStrings.quranOccasionallyDesc,
      icon: Icons.water_drop_outlined,
    ),
    (
      key: 'rarely',
      title: AppStrings.quranRarely,
      subtitle: AppStrings.quranRarelyDesc,
      icon: Icons.favorite_border,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingQuestionScaffold(
      progressSegment: 5,
      headline: AppStrings.quranConnectionTitle,
      subtitle: AppStrings.quranConnectionSubtitle,
      continueEnabled: state.quranConnection != null,
      onBack: onBack,
      onContinue: () {
        final value = ref.read(onboardingProvider).quranConnection;
        ref
            .read(analyticsProvider)
            .trackSurveyAnswered('quran_connection', value);
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('quran_connection', value);
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
              isSelected: state.quranConnection == option.key,
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .setQuranConnection(option.key),
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
