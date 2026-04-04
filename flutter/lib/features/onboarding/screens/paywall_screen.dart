import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/feature_row.dart';

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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            children: [
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
              const SizedBox(height: AppSpacing.sm),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.paywallBadge,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.secondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Heading
              Text(
                AppStrings.paywallTitle,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              // Social proof — above pricing for conversion impact
              Text(
                AppStrings.paywallSocialProof,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Pricing options — IntrinsicHeight keeps cards equal
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _PricingOption(
                        price: AppStrings.paywallAnnualPrice,
                        period: AppStrings.paywallAnnualPeriod,
                        label: AppStrings.paywallAnnualLabel,
                        badge: AppStrings.paywallAnnualBadge,
                        subPrice: AppStrings.paywallAnnualPerMonth,
                        savings: AppStrings.paywallAnnualSavings,
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
              ),
              const SizedBox(height: AppSpacing.md),
              // Trial timeline
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const _TimelineDot(color: AppColors.primary),
                        Expanded(child: Container(height: 1, color: AppColors.primary.withAlpha(50))),
                        const _TimelineDot(color: AppColors.streakAmber),
                        Expanded(child: Container(height: 1, color: AppColors.primary.withAlpha(50))),
                        const _TimelineDot(color: AppColors.textTertiaryLight),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TimelineLabel(label: 'Today', sublabel: AppStrings.paywallTrialStep1),
                        _TimelineLabel(label: 'Day 3', sublabel: AppStrings.paywallTrialStep2),
                        _TimelineLabel(label: 'Day 4', sublabel: AppStrings.paywallTrialStep3),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // CTA button — inline, not sticky
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    () async {
                      try {
                        await notifier.completeOnboarding();
                      } catch (_) {}
                      widget.onComplete();
                    }();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    AppStrings.paywallCta,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Legal links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    child: Text(
                      AppStrings.paywallRestore,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                  Text(
                    ' \u00B7 ',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {},
                    child: Text(
                      AppStrings.paywallTerms,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                  Text(
                    ' \u00B7 ',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
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
    this.subPrice,
    this.savings,
  });

  final String price;
  final String period;
  final String label;
  final String? badge;
  final String? subPrice;
  final String? savings;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            if (subPrice != null)
              Text(
                subPrice!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            if (savings != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  savings!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
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

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TimelineLabel extends StatelessWidget {
  const _TimelineLabel({required this.label, required this.sublabel});
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            sublabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
