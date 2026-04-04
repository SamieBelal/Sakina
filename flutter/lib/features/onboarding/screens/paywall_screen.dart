import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/feature_row.dart';
import '../widgets/onboarding_continue_button.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

enum _PlanType { annual, weekly }

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _PlanType _selectedPlan = _PlanType.annual;

  static const _features = [
    (Icons.all_inclusive, AppStrings.paywallFeatureUnlimited),
    (Icons.menu_book, AppStrings.paywallFeatureTafsir),
    (Icons.headphones, AppStrings.paywallFeatureAudio),
    (Icons.ac_unit, AppStrings.paywallFeatureStreak),
    (Icons.history, AppStrings.paywallFeatureHistory),
    (Icons.block, AppStrings.paywallFeatureAdFree),
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Close button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () async {
                        try {
                          await notifier.completeOnboarding();
                        } catch (_) {}
                        widget.onComplete();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Premium badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.paywallBadge,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Heading
                  Text(
                    AppStrings.paywallTitle,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Feature rows with stagger animation
                  ...List.generate(_features.length, (i) {
                    final (icon, label) = _features[i];
                    return FeatureRow(icon: icon, label: label)
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 80 * i),
                          duration: 400.ms,
                        )
                        .slideX(
                          begin: -0.05,
                          end: 0,
                          delay: Duration(milliseconds: 80 * i),
                          duration: 400.ms,
                        );
                  }),
                  const SizedBox(height: AppSpacing.xl),
                  // Pricing options
                  Row(
                    children: [
                      Expanded(
                        child: _PricingOption(
                          price: AppStrings.paywallAnnualPrice,
                          period: AppStrings.paywallAnnualPeriod,
                          label: AppStrings.paywallAnnualLabel,
                          badge: AppStrings.paywallAnnualBadge,
                          selected: _selectedPlan == _PlanType.annual,
                          onTap: () =>
                              setState(() => _selectedPlan = _PlanType.annual),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _PricingOption(
                          price: AppStrings.paywallWeeklyPrice,
                          period: AppStrings.paywallWeeklyPeriod,
                          label: AppStrings.paywallWeeklyLabel,
                          selected: _selectedPlan == _PlanType.weekly,
                          onTap: () =>
                              setState(() => _selectedPlan = _PlanType.weekly),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Trial info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: Text(
                      AppStrings.paywallTrialInfo,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          // Sticky bottom
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OnboardingContinueButton(
                  label: AppStrings.paywallCta,
                  onPressed: () async {
                    try {
                      await notifier.completeOnboarding();
                    } catch (_) {}
                    widget.onComplete();
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        AppStrings.paywallRestore,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                    Text(
                      '\u00B7',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        AppStrings.paywallTerms,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                    Text(
                      '\u00B7',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        AppStrings.paywallPrivacy,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingOption extends StatelessWidget {
  const _PricingOption({
    required this.price,
    required this.period,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String price;
  final String period;
  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                child: Text(
                  badge!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              price,
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              period,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
