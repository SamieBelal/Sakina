import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureNamesScreen extends StatelessWidget {
  const FeatureNamesScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 9,
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
                    AppStrings.featureNamesHeadline,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05, end: 0, duration: 500.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.featureNamesSubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 150.ms),
                  const SizedBox(height: AppSpacing.xl + AppSpacing.sm),

                  // Fanned card stack
                  _buildCardStack(context),

                  const SizedBox(height: AppSpacing.xl),

                  // Tier progression
                  _buildTierProgression(),

                  const Spacer(),
                  OnboardingContinueButton(
                    label: AppStrings.continueButton,
                    onPressed: onNext,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack(BuildContext context) {
    const cards = [
      (
        AppStrings.featureNamesSampleName3,
        AppStrings.featureNamesSampleTranslit3,
        AppStrings.featureNamesSampleMeaning3,
        _CardTier.bronze,
      ),
      (
        AppStrings.featureNamesSampleName2,
        AppStrings.featureNamesSampleTranslit2,
        AppStrings.featureNamesSampleMeaning2,
        _CardTier.silver,
      ),
      (
        AppStrings.featureNamesSampleName1,
        AppStrings.featureNamesSampleTranslit1,
        AppStrings.featureNamesSampleMeaning1,
        _CardTier.gold,
      ),
    ];

    return SizedBox(
      height: 200,
      child: Center(
        child: SizedBox(
          width: 280,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: List.generate(cards.length, (index) {
              final (arabic, translit, meaning, tier) = cards[index];
              final angle = (index - 1) * 0.06; // -0.06, 0, 0.06 radians
              final offsetX = (index - 1) * 20.0;

              return Positioned(
                left: 20 + offsetX,
                child: Transform.rotate(
                  angle: angle,
                  child: _buildNameCard(arabic, translit, meaning, tier),
                )
                    .animate()
                    .fadeIn(
                      duration: 500.ms,
                      delay: (400 + index * 180).ms,
                    )
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 500.ms,
                      delay: (400 + index * 180).ms,
                    )
                    .rotate(
                      begin: -0.02,
                      end: 0,
                      duration: 500.ms,
                      delay: (400 + index * 180).ms,
                    ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNameCard(
    String arabic,
    String translit,
    String meaning,
    _CardTier tier,
  ) {
    final tierColor = switch (tier) {
      _CardTier.bronze => const Color(0xFFCD7F32),
      _CardTier.silver => const Color(0xFF9CA3AF),
      _CardTier.gold => AppColors.secondary,
    };

    final tierBg = switch (tier) {
      _CardTier.bronze => const Color(0xFFFDF6EE),
      _CardTier.silver => const Color(0xFFF8F9FA),
      _CardTier.gold => const Color(0xFFFCF8F0),
    };

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: tierBg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: tierColor.withAlpha(60), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i <= tier.index;
              return Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? tierColor : tierColor.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          // Arabic name
          Text(
            arabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              fontSize: 32,
              color: AppColors.textPrimaryLight,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Transliteration
          Text(
            translit,
            style: AppTypography.labelMedium.copyWith(
              color: tierColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          // Meaning
          Text(
            meaning,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgression() {
    const tiers = [
      (Icons.circle, 'Bronze', AppStrings.featureNamesTierBronze, Color(0xFFCD7F32)),
      (Icons.circle, 'Silver', AppStrings.featureNamesTierSilver, Color(0xFF9CA3AF)),
      (Icons.circle, 'Gold', AppStrings.featureNamesTierGold, Color(0xFFC8985E)),
    ];

    return Column(
      children: List.generate(tiers.length, (index) {
        final (_, tierName, unlock, color) = tiers[index];
        final isLast = index == tiers.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
          child: Row(
            children: [
              // Tier badge
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(60), width: 1),
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName,
                      style: AppTypography.labelLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      unlock,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (1000 + index * 150).ms)
            .slideX(
              begin: 0.05,
              end: 0,
              duration: 400.ms,
              delay: (1000 + index * 150).ms,
            );
      }),
    );
  }
}

enum _CardTier { bronze, silver, gold }
