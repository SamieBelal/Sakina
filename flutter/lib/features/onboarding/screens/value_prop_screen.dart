import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

/// Task 18 / Screen #23 — Value prop with dynamic copy.
///
/// The headline is keyed on the user's top aspiration from the quiz so the
/// promise mirrors what they told us they want to become. Continue is always
/// enabled — this is a reveal, not a question.
class ValuePropScreen extends ConsumerWidget {
  const ValuePropScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Maps an aspiration id (from `AspirationsScreen`) to a lowercase phrase
  /// that slots naturally after "become". Unknown ids fall back to a
  /// generic phrase so the screen never reads awkwardly.
  static String aspirationPhrase(String? id) {
    switch (id) {
      case 'morePatient':
        return 'more patient';
      case 'moreGrateful':
        return 'more grateful';
      case 'closerToAllah':
        return 'closer to Allah';
      case 'morePresent':
        return 'more present';
      case 'strongerFaith':
        return 'stronger in faith';
      case 'moreConsistent':
        return 'more consistent';
      default:
        return 'who you want to be';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final aspiration = state.aspirations.isNotEmpty
        ? aspirationPhrase(state.aspirations.first)
        : aspirationPhrase(null);

    return OnboardingQuestionScaffold(
      progressSegment: 23,
      headline: 'Sakina helps you become $aspiration.',
      subtitle: 'In the time you already have — even 1 minute a day.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ValueRow(
            icon: Icons.favorite_border,
            title: 'Daily check-in',
            body: 'Name your feeling, meet it with Qur\'an.',
          ),
          SizedBox(height: AppSpacing.lg),
          _ValueRow(
            icon: Icons.collections_bookmark_outlined,
            title: '99 Names',
            body: 'Collect, study, and reflect.',
          ),
          SizedBox(height: AppSpacing.lg),
          _ValueRow(
            icon: Icons.auto_stories_outlined,
            title: 'Your journal',
            body: 'Every reflection saved.',
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
