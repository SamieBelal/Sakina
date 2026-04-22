import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_events.dart';
import '../../../services/analytics_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

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
        ? 'I commit to $mins minutes a day,\nwith a gentle reminder at $reminderTime.'
        : 'I commit to $mins minutes a day.';

    return OnboardingPageWrapper(
      progressSegment: 16,
      onBack: onBack,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your commitment.',
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'A small daily promise to yourself.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const Spacer(flex: 2),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight,
                border: Border.all(
                  color: AppColors.primary.withAlpha(60),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.spa_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(40)),
            ),
            child: Column(
              children: [
                Text(
                  '\u201C',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.secondary,
                    height: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  pactText,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 150.ms)
              .slideY(begin: 0.03, end: 0, duration: 500.ms),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'The deeds most beloved to Allah are those done consistently, even if small.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
          const Spacer(flex: 2),
          Center(
            child: _CommitButton(
              accepted: state.commitmentAccepted,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref
                    .read(onboardingProvider.notifier)
                    .setCommitmentAccepted(!state.commitmentAccepted);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OnboardingContinueButton(
            label: AppStrings.continueButton,
            onPressed: () {
              ref.read(analyticsProvider).trackOnboardingAnswerWithRef(
                    ref,
                    'commitment_accepted',
                    state.commitmentAccepted,
                  );
              onNext();
            },
            enabled: state.commitmentAccepted,
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

class _CommitButton extends StatelessWidget {
  const _CommitButton({required this.accepted, required this.onTap});

  final bool accepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: accepted ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primary,
            width: accepted ? 0 : 1.5,
          ),
          boxShadow: accepted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              accepted ? Icons.check_rounded : Icons.favorite_outline,
              size: 20,
              color: accepted ? AppColors.textOnPrimary : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              accepted ? 'I commit' : 'Tap to commit',
              style: AppTypography.labelLarge.copyWith(
                color: accepted ? AppColors.textOnPrimary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
