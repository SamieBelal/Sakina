import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureJournalScreen extends StatelessWidget {
  const FeatureJournalScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 7,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero: journal entry stack
          Expanded(
            flex: 5,
            child: Center(child: _buildJournalStack()),
          ),

          // Headline + subtitle + CTA
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.featureJournalHeadline,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureJournalSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                const Spacer(),
                OnboardingContinueButton(
                  label: AppStrings.continueButton,
                  onPressed: onNext,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildJournalEntry(
          icon: Icons.auto_awesome,
          iconColor: AppColors.primary,
          iconBg: AppColors.primaryLight,
          badge: AppStrings.featureJournalItem1Title,
          badgeColor: AppColors.primary,
          badgeBg: AppColors.primaryLight,
          preview: AppStrings.featureJournalItem1Preview,
          accentWidget: _buildNameBadge('Al-Qawī', 'ٱلْقَوِيّ'),
          index: 0,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildJournalEntry(
          icon: Icons.mosque_outlined,
          iconColor: AppColors.secondary,
          iconBg: AppColors.secondaryLight,
          badge: AppStrings.featureJournalItem2Title,
          badgeColor: AppColors.secondary,
          badgeBg: AppColors.secondaryLight,
          preview: AppStrings.featureJournalItem2Preview,
          accentWidget: _buildArabicSnippet('يَا صَبُور'),
          index: 1,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildJournalEntry(
          icon: Icons.star_rounded,
          iconColor: AppColors.streakAmber,
          iconBg: AppColors.streakBackground,
          badge: AppStrings.featureJournalItem3Title,
          badgeColor: AppColors.streakAmber,
          badgeBg: AppColors.streakBackground,
          preview: AppStrings.featureJournalItem3Preview,
          accentWidget: _buildTierDots(2),
          index: 2,
        ),
      ],
    );
  }

  Widget _buildJournalEntry({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required String preview,
    required Widget accentWidget,
    required int index,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.labelSmall.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    accentWidget,
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  preview,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: (200 + index * 150).ms)
        .slideY(begin: 0.08, end: 0, duration: 500.ms, delay: (200 + index * 150).ms);
  }

  Widget _buildNameBadge(String translitName, String arabicName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          translitName,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          arabicName,
          style: AppTypography.arabicClassical.copyWith(
            fontSize: 13,
            color: AppColors.primary,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildArabicSnippet(String arabic) {
    return Text(
      arabic,
      style: AppTypography.arabicClassical.copyWith(
        fontSize: 14,
        color: AppColors.secondary,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildTierDots(int tierLevel) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i <= tierLevel;
        final color = active
            ? AppColors.streakAmber
            : AppColors.streakAmber.withAlpha(40);
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}
