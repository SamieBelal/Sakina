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
        // The "Everything in Premium" eyebrow was deleted 2026-08-01
        // (founder). The headline already frames the page and the five ticks
        // are self-evidently a feature list — the label restated the obvious
        // in the smallest type on the screen, which is where a reader's
        // attention is scarcest.
        paywallEntry(context, 1, const PaywallBenefitChecklist()),
        const SizedBox(height: AppSpacing.lg),
        paywallEntry(
          context,
          2,
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

/// The tick rows, in the shipped geometry (26px circle, `primaryLight` fill,
/// 16px check, 12px gap, 17px label) so this surface and every other benefit
/// list in the app cannot drift apart.
class PaywallBenefitChecklist extends StatelessWidget {
  const PaywallBenefitChecklist({this.maxItems, super.key});

  /// Show only the first N benefits. `null` shows all five.
  ///
  /// The condensed surface uses this to FIT WITHOUT SCROLLING on short
  /// frames. Truncating is the right lever because the list is already
  /// ordered by relevance to someone who just hit a cap — "unlimited
  /// reflections, duʿās & Name discoveries" answers their situation, and
  /// "3 streak freezes" does not. Shrinking the type instead would make the
  /// only statement of what premium contains the smallest thing on a screen
  /// asking for money.
  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final shown = maxItems == null
        ? paywallPremiumBenefits
        : paywallPremiumBenefits.take(maxItems!).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final benefit in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryLight,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    benefit,
                    // 17, up from 15, with the tick and gutter grown to match
                    // (founder, 2026-08-01). These five lines are the only
                    // statement of what premium actually contains, and they
                    // were set two steps below the page headline. The space
                    // came free when the always-free footer left this surface.
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontSize: 17,
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
