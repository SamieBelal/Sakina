import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class DailyCommitmentScreen extends ConsumerWidget {
  const DailyCommitmentScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });
  final VoidCallback onNext;
  final VoidCallback onBack;

  static const _options = [1, 3, 5, 10];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return OnboardingQuestionScaffold(
      progressSegment: 14,
      headline: 'How much time a day feels right?',
      subtitle: 'You can change this later.',
      onBack: onBack,
      continueEnabled: state.dailyCommitmentMinutes != null,
      onContinue: onNext,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _options.map((m) {
          final selected = state.dailyCommitmentMinutes == m;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => ref
                  .read(onboardingProvider.notifier)
                  .setDailyCommitmentMinutes(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 72,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : AppColors.borderLight,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$m min',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
