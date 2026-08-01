import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../paywall_offer_view.dart';
import 'paywall_gate_page.dart';
import 'paywall_plan_options.dart';

/// The five shipped premium benefits, verbatim. Page 1 sells the personalized
/// depth at the emotional peak; the full checklist completes the value case at
/// the decision moment, which is why it lives here and not there.
const List<String> paywallPremiumBenefits = <String>[
  AppStrings.paywallPremiumBenefit1,
  AppStrings.paywallPremiumBenefit2,
  AppStrings.paywallPremiumBenefit3,
  AppStrings.paywallPremiumBenefit4,
  AppStrings.paywallPremiumBenefit5,
];

/// Page 3 of the gate — `plan_select`.
class PaywallPlanSelectPage extends StatelessWidget {
  const PaywallPlanSelectPage({
    required this.offer,
    required this.selectedPlan,
    required this.onSelectPlan,
    super.key,
  });

  final PaywallOfferView offer;
  final PaywallPlanType selectedPlan;
  final ValueChanged<PaywallPlanType> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        paywallEntry(
          context,
          0,
          Text(
            AppStrings.paywallPlanSelectHeadline,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        paywallEntry(
          context,
          1,
          Text(
            AppStrings.paywallPlanSelectBenefitsHeader,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.72,
            ),
          ),
        ),
        const SizedBox(height: 12),
        paywallEntry(context, 2, const PaywallBenefitChecklist()),
        const SizedBox(height: AppSpacing.lg),
        paywallEntry(
          context,
          3,
          PaywallPlanOptions(
            offer: offer,
            selected: selectedPlan,
            onSelect: onSelectPlan,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// The tick rows, in the shipped geometry (22px circle, `primaryLight` fill,
/// 14px check, 10px gap) so this surface and every other benefit list in the
/// app cannot drift apart.
class PaywallBenefitChecklist extends StatelessWidget {
  const PaywallBenefitChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final benefit in paywallPremiumBenefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefit,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
