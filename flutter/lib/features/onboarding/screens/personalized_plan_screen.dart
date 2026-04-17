import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

/// Task 17 / Screen #22 — "Your personalized plan."
///
/// Assembles a visual summary of the user's quiz answers: the Name they
/// resonated with (or Ar-Rahman as a fallback per spec §4), their top
/// struggle, their daily commitment, and their reminder time. Continue is
/// always enabled — this is a reveal screen, not a question.
class PersonalizedPlanScreen extends ConsumerWidget {
  const PersonalizedPlanScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Mirrors the curated list in [ResonantNameScreen]. The fallback branch
  /// (`null` or unknown id) returns Ar-Rahman per spec §4.
  static String translitForId(String? id) {
    switch (id) {
      case 'ar-rahim':
        return 'Ar-Rahim';
      case 'as-salam':
        return 'As-Salam';
      case 'al-wadud':
        return 'Al-Wadud';
      case 'al-hafiz':
        return 'Al-Hafiz';
      case 'al-karim':
        return 'Al-Karim';
      case 'ar-rahman':
      default:
        return 'Ar-Rahman';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translit = translitForId(state.resonantNameId);
    // Set.first has undefined iteration order — sort alphabetically for a
    // deterministic plan card across renders.
    final struggle = state.struggles.isNotEmpty
        ? (state.struggles.toList()..sort()).first
        : 'your path';
    final reminder = state.reminderTime ?? '08:00';
    final minutes = state.dailyCommitmentMinutes ?? 3;
    final name = (state.signUpName != null && state.signUpName!.isNotEmpty)
        ? state.signUpName!
        : 'friend';
    final intention = state.intention ?? 'growing closer to Allah';

    return OnboardingQuestionScaffold(
      progressSegment: 22,
      headline: 'Your plan, $name.',
      subtitle: 'Everything you need, one tap away.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: _PlanCard(
        translit: translit,
        struggle: struggle,
        reminder: reminder,
        minutes: minutes,
        intention: intention,
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.translit,
    required this.struggle,
    required this.reminder,
    required this.minutes,
    required this.intention,
  });

  final String translit;
  final String struggle;
  final String reminder;
  final int minutes;
  final String intention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanRow(
            label: 'First Name in your collection:',
            value: translit,
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlanRow(
            label: 'What we\'ll meet you with:',
            value: struggle,
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlanRow(
            label: 'Your daily check-in:',
            value: '$minutes min · $reminder',
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlanRow(
            label: 'Why you\'re here:',
            value: intention,
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: emphasize
              ? AppTypography.headlineMedium.copyWith(color: AppColors.primary)
              : AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
