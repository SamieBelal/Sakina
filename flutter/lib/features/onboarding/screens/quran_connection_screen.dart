import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/intention_option_card.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

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

    return OnboardingPageWrapper(
      progressSegment: 11,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.quranConnectionTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.quranConnectionSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(_options.length, (index) {
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
          const Spacer(),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
            enabled: state.quranConnection != null,
          ),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
