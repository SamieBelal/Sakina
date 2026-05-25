import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/card_collection_service.dart';
import '../providers/onboarding_provider.dart';

/// "Your personalized plan." Page 23 of onboarding (post-2026-05-05; was page 17).
///
/// Reskinned for the paywall flow: plain Scaffold (no OnboardingQuestionScaffold
/// progress bar), gold "Crafted for you" ribbon at top, plain "Continue →" CTA.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final translit = translitForCatalogId(state.starterNameId);
    // Trimmed-flow refactor (2026-05-25, Option α): `commonEmotions` was
    // removed from OnboardingState. The "You often feel" tile now falls back
    // to its existing default copy; Phase B copy refresh will rewrite the
    // tile against the trimmed signals (intention / dua_topics).
    const struggle = 'Whatever comes up';
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
      // ignore: prefer_const_constructors
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    AppStrings.personalizedPlanRibbon,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your plan, $name.',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontSize: 26,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Everything you need, one tap away.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        tiles[i]
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (100 * i).ms)
                            .slideY(begin: 0.04, end: 0, duration: 400.ms),
                        if (i < tiles.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    AppStrings.continueButton,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
