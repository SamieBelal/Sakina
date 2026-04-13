import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';
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

    return OnboardingPageWrapper(
      progressSegment: 12,
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
            AppStrings.attributionTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.attributionSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
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
          const Spacer(),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
            enabled: state.attribution.isNotEmpty,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
