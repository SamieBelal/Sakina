import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/card_collection_service.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_question_scaffold.dart';

/// "Your personalized plan." Renders the user's starter Name (selected on
/// the first check-in screen) as the anchor of the plan preview.
class PersonalizedPlanScreen extends ConsumerWidget {
  const PersonalizedPlanScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  /// Resolves a `starter_name_id` (catalog int) to its transliteration. Falls
  /// back to Ar-Rahman if the id is null or not present in the catalog.
  static String translitForCatalogId(int? id) {
    if (id == null) return 'Ar-Rahman';
    for (final n in allCollectibleNames) {
      if (n.id == id) return n.transliteration;
    }
    return 'Ar-Rahman';
  }

  static String _titleCase(String id) =>
      '${id.substring(0, 1).toUpperCase()}${id.substring(1)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translit = translitForCatalogId(state.starterNameId);
    // Mirror back the emotions the user actually selected on the common
    // emotions screen, capped at 3 so the tile stays readable. Reads as
    // "You often feel: Anxious, Sad, Lonely" — natural English, no awkward
    // "we'll meet you with anxiety" framing where the app sounds like the
    // emotion delivery service.
    final emotions = (state.commonEmotions.toList()..sort())
        .take(3)
        .map(_titleCase)
        .join(', ');
    final struggle = emotions.isNotEmpty ? emotions : 'Whatever comes up';
    final reminder = state.reminderTime ?? '08:00';
    final minutes = state.dailyCommitmentMinutes ?? 3;
    final name = (state.signUpName != null && state.signUpName!.isNotEmpty)
        ? state.signUpName!
        : 'friend';
    final intention = state.intention ?? 'growing closer to Allah';

    final tiles = <Widget>[
      _PlanTile(
        icon: Icons.auto_awesome_rounded,
        label: 'First Name in your collection',
        value: translit,
        emphasize: true,
      ),
      _PlanTile(
        icon: Icons.favorite_rounded,
        label: 'You often feel',
        value: struggle,
      ),
      _PlanTile(
        icon: Icons.schedule_rounded,
        label: 'Your daily check-in',
        value: '$minutes min  ·  $reminder',
      ),
      _PlanTile(
        icon: Icons.spa_rounded,
        label: "Why you're here",
        value: intention,
      ),
    ];

    return OnboardingQuestionScaffold(
      progressSegment: 17,
      headline: 'Your plan, $name.',
      subtitle: 'Everything you need, one tap away.',
      onBack: onBack,
      continueEnabled: true,
      onContinue: onNext,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            tiles[i]
                .animate()
                .fadeIn(duration: 400.ms, delay: (100 * i).ms)
                .slideY(begin: 0.04, end: 0, duration: 400.ms),
            if (i < tiles.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: emphasize
                      ? AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                        )
                      : AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
