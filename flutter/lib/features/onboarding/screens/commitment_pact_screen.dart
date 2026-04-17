import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

class CommitmentPactScreen extends ConsumerWidget {
  const CommitmentPactScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final mins = state.dailyCommitmentMinutes ?? 3;
    final notifyOk = state.notificationPermissionGranted;
    final reminderTime = state.reminderTime ?? '08:00';

    final pactText = notifyOk
        ? 'I commit to $mins minutes a day, with a gentle reminder at $reminderTime.'
        : 'I commit to $mins minutes a day.';

    return OnboardingQuestionScaffold(
      progressSegment: 20,
      headline: 'Your commitment.',
      subtitle: 'A small daily promise to yourself.',
      onBack: onBack,
      continueEnabled: state.commitmentAccepted,
      onContinue: () {
        ref
            .read(analyticsProvider)
            .trackOnboardingAnswer('commitment_accepted', state.commitmentAccepted);
        onNext();
      },
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              pactText,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () => ref
                .read(onboardingProvider.notifier)
                .setCommitmentAccepted(!state.commitmentAccepted),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: state.commitmentAccepted
                    ? AppColors.primary
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                state.commitmentAccepted ? '✓ I commit' : 'Tap to commit',
                style: AppTypography.headlineMedium.copyWith(
                  color: state.commitmentAccepted
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
