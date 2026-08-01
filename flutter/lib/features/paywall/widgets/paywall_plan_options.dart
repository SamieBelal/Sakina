import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../paywall_offer_view.dart';

/// The plan chooser: annual as a card, weekly as a de-emphasized text row.
///
/// Weekly is deliberately NOT a peer card (draft build rule). Two equal cards
/// make the choice the screen's subject; one card plus a quiet row makes the
/// annual plan the default and leaves weekly reachable for anyone who wants it.
///
/// House rules applied here: card radius 14, control radius 12, **no drop
/// shadows** — selection reads as border + tinted background, which is how
/// every other selected surface in the app reads (DESIGN.md §4).
class PaywallPlanOptions extends StatelessWidget {
  const PaywallPlanOptions({
    required this.offer,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final PaywallOfferView offer;
  final PaywallPlanType selected;
  final ValueChanged<PaywallPlanType> onSelect;

  @override
  Widget build(BuildContext context) {
    final annualSelected = selected == PaywallPlanType.annual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          inMutuallyExclusiveGroup: true,
          selected: annualSelected,
          button: true,
          child: GestureDetector(
            onTap: () => onSelect(PaywallPlanType.annual),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  decoration: BoxDecoration(
                    color: annualSelected
                        ? AppColors.primaryLight
                        : AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: annualSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: annualSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.paywallAnnualLabel,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        offer.annualPriceLine,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Gold as a FILL with `goldInk` text — bright gold at
                      // ~2.2:1 on cream fails contrast for anything that
                      // carries meaning (DESIGN.md §2.3).
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppStrings.paywallPlanAnnualSavings,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.goldInk,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (offer.trialFlag != null)
                  Positioned(
                    top: -10,
                    right: 14,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          offer.trialFlag!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textOnPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          inMutuallyExclusiveGroup: true,
          selected: !annualSelected,
          button: true,
          child: TextButton(
            onPressed: () => onSelect(PaywallPlanType.weekly),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: annualSelected
                  ? Colors.transparent
                  : AppColors.surfaceAltLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: Text(
              offer.weeklyRowLabel,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: annualSelected
                    ? AppColors.textSecondaryLight
                    : AppColors.textPrimaryLight,
                fontWeight: annualSelected ? FontWeight.w400 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
