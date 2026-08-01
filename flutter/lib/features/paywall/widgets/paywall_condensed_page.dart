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

  /// How many benefits fit above the plans on a frame this tall.
  ///
  /// Thresholds are screen classes measured against the real type ramp, not
  /// round numbers: 932 = Pro Max, 844/852 = the standard iPhone, 667 = SE.
  /// Three of the five benefit lines wrap to two rows at 17px on a 390pt
  /// frame, so the list costs ~255pt at full length — more than the ~216pt a
  /// standard iPhone has left after the headline, value line, both plan tiles
  /// and the pinned footer.
  static int _benefitCountFor(double screenHeight) {
    if (screenHeight >= 900) return 5; // Pro Max
    if (screenHeight >= 820) return 4; // 14/15/16, and Pro
    if (screenHeight >= 750) return 3;
    return 2; // SE class
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // The SE cannot afford a 34pt headline AND a usable benefit list. The
    // headline is the cheaper thing to shrink: it is the same six words on
    // every surface, while the benefits are the only content here.
    final headlineStyle = screenHeight < 780
        ? AppTypography.displayMedium
        : AppTypography.displayLarge;
    final gap = screenHeight < 780 ? AppSpacing.md : AppSpacing.lg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No leading gap. The ceremony pages start their headline immediately
        // under the 44pt chrome bar; this page had an extra 8pt, which set the
        // same six words 8pt lower than on the three screens it sits beside.
        // It also cost 8pt on the surface that has the least room to spare.
        paywallEntry(
          context,
          0,
          Text(
            AppStrings.paywallPlanSelectHeadline,
            style: headlineStyle.copyWith(
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
        SizedBox(height: gap),
        paywallEntry(
          context,
          2,
          PaywallBenefitChecklist(
            maxItems: _benefitCountFor(screenHeight),
          ),
        ),
        SizedBox(height: gap),
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
