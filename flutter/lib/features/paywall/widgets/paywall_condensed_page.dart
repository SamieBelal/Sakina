import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../paywall_offer_view.dart';
import 'paywall_gate_page.dart';
import 'paywall_plan_options.dart';
import 'paywall_plan_select_page.dart';

/// The condensed single screen for every non-onboarding surface: a value line,
/// the plans, plain terms.
///
/// **Never the 3-page ceremony mid-task.** A user who hit a cap while writing a
/// duʿā is interrupted, not arriving; making them tap through a ceremony to get
/// back to what they were doing is the shape of gate that trains people to
/// dismiss on sight. The ceremony is earned once, at the emotional peak of
/// onboarding, and nowhere else.
class PaywallCondensedPage extends StatelessWidget {
  const PaywallCondensedPage({
    required this.offer,
    required this.selectedPlan,
    required this.onSelectPlan,
    this.valueLine,
    super.key,
  });

  final PaywallOfferView offer;
  final PaywallPlanType selectedPlan;
  final ValueChanged<PaywallPlanType> onSelectPlan;

  /// The trigger-specific line ("Your reflections for this week are used — …").
  /// `null` falls back to a statement of what premium gives, which is true
  /// under both the daily cap and the weekly pool.
  final String? valueLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(height: 10),
        paywallEntry(
          context,
          1,
          Text(
            valueLine ?? AppStrings.paywallSoftGateDefaultLine,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
