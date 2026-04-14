import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_provider.dart';
import '../../../services/analytics_events.dart';

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

  String get _planName => _selectedPlan == _PlanType.annual ? 'annual' : 'weekly';

  static const _benefits = [
    AppStrings.paywallBenefit1,
    AppStrings.paywallBenefit2,
    AppStrings.paywallBenefit3,
    AppStrings.paywallBenefit4,
  ];

  void _handleComplete() {
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallCtaTapped, properties: {'plan': _planName});
    widget.onComplete();
  }

  void _handleClose() {
    ref.read(analyticsProvider).track(AnalyticsEvents.paywallClosed);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _handleClose,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),

              // Decorative Arabic calligraphy
              Text(
                '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u0650',
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.secondary.withAlpha(191),
                  fontFamily: 'Amiri',
                  fontSize: 28,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Headline
              Text(
                AppStrings.paywallTitle,
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Subtitle
              Text(
                AppStrings.paywallSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // 4 compact benefit rows
              ...List.generate(_benefits.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _benefits[i],
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
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
              const SizedBox(height: AppSpacing.sm),

              // Social proof
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.streakAmber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.paywallSocialProof,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Pricing cards — stacked, yearly first
              _PricingCard(
                label: AppStrings.paywallAnnualLabel,
                mainPrice: AppStrings.paywallAnnualPerWeek,
                mainPriceLabel: AppStrings.paywallAnnualPerWeekLabel,
                subPrice: AppStrings.paywallAnnualTotal,
                badge: AppStrings.paywallAnnualBadge,
                selected: _selectedPlan == _PlanType.annual,
                onTap: () {
                  setState(() => _selectedPlan = _PlanType.annual);
                  ref.read(analyticsProvider).track(AnalyticsEvents.paywallPlanSelected, properties: {'plan': _planName});
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _PricingCard(
                label: AppStrings.paywallWeeklyLabel,
                mainPrice: AppStrings.paywallWeeklyPrice,
                mainPriceLabel: AppStrings.paywallWeeklyPerWeekLabel,
                selected: _selectedPlan == _PlanType.weekly,
                onTap: () {
                  setState(() => _selectedPlan = _PlanType.weekly);
                  ref.read(analyticsProvider).track(AnalyticsEvents.paywallPlanSelected, properties: {'plan': _planName});
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Trial terms — updates based on selected plan
              Text(
                _selectedPlan == _PlanType.annual
                    ? AppStrings.paywallTrialTermsAnnual
                    : AppStrings.paywallTrialTermsWeekly,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // CTA button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _handleComplete();
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
              const SizedBox(height: AppSpacing.sm),

              // Legal links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _LegalLink(label: AppStrings.paywallRestore),
                  _dot(),
                  const _LegalLink(label: AppStrings.paywallTerms),
                  _dot(),
                  const _LegalLink(label: AppStrings.paywallPrivacy),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Text(
      ' \u00B7 ',
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textTertiaryLight,
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {},
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiaryLight,
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.label,
    required this.mainPrice,
    required this.mainPriceLabel,
    required this.selected,
    required this.onTap,
    this.badge,
    this.subPrice,
  });

  final String label;
  final String mainPrice;
  final String mainPriceLabel;
  final String? badge;
  final String? subPrice;
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
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textTertiaryLight,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Label + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price column — right-aligned
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mainPrice,
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(
                  mainPriceLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
                if (subPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subPrice!,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
