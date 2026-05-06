import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/journey_timeline.dart';
import 'personalized_plan_screen.dart';

/// "Where you'll be in 30 days, {name}." — page 24 of onboarding.
///
/// Concrete-but-qualitative 30-day promise screen. Loss-aversion lever.
/// Copy is intentionally NON-quantified (no "5 Names by Day 7" etc.) because
/// the gacha + streak system can't guarantee specific counts and a spiritual
/// brand can't survive "the app exaggerated to sell me."
class YourJourneyScreen extends ConsumerWidget {
  const YourJourneyScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final name = (state.signUpName != null && state.signUpName!.isNotEmpty)
        ? state.signUpName!
        : 'friend';
    final starter = PersonalizedPlanScreen.translitForCatalogId(
      state.starterNameId,
    );
    final minutes = state.dailyCommitmentMinutes ?? 3;

    final headline = AppStrings.paywallFlowJourneyHeadlineTemplate
        .replaceAll('{name}', name);
    final day1Line2 = AppStrings.paywallFlowJourneyDay1Line2Template
        .replaceAll('{name}', starter);
    final footer = AppStrings.paywallFlowJourneyFooterTemplate
        .replaceAll('{minutes}', '$minutes');

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
              const SizedBox(height: AppSpacing.md),
              Text(
                headline,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontSize: 26,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.paywallFlowJourneySubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: JourneyTimeline(
                    milestones: [
                      JourneyMilestone(
                        heading: AppStrings.paywallFlowJourneyDay1Heading,
                        lines: [
                          AppStrings.paywallFlowJourneyDay1Line1,
                          day1Line2,
                        ],
                      ),
                      const JourneyMilestone(
                        heading: AppStrings.paywallFlowJourneyDay7Heading,
                        lines: [
                          AppStrings.paywallFlowJourneyDay7Line1,
                          AppStrings.paywallFlowJourneyDay7Line2,
                          AppStrings.paywallFlowJourneyDay7Line3,
                        ],
                      ),
                      const JourneyMilestone(
                        heading: AppStrings.paywallFlowJourneyDay30Heading,
                        lines: [
                          AppStrings.paywallFlowJourneyDay30Line1,
                          AppStrings.paywallFlowJourneyDay30Line2,
                          AppStrings.paywallFlowJourneyDay30Line3,
                          AppStrings.paywallFlowJourneyDay30Line4,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                footer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
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
                    AppStrings.paywallFlowJourneyCta,
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
