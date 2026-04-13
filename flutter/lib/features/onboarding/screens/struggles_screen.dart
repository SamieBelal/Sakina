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

    return OnboardingPageWrapper(
      progressSegment: 16,
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
            AppStrings.strugglesTitle,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.strugglesSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
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
          const Spacer(),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: onNext,
            enabled: state.struggles.isNotEmpty,
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
