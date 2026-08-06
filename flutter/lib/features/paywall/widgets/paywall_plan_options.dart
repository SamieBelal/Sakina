import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../paywall_offer_view.dart';

/// The plan chooser: annual as a full card, weekly as a smaller card beneath.
///
/// Weekly is deliberately NOT a peer (draft build rule). Two equal cards make
/// the choice the screen's subject; a large card over a compact one keeps
/// annual the default while leaving weekly obviously reachable. It reads as a
/// selectable tile rather than a text link, because it always WAS selectable —
/// as a bare row it did not look it.
///
/// **No trial badge here (2026-08-01, founder).** A "3 days free first" flag
/// floated above the annual card duplicated the CTA directly below it and the
/// terms line below that — the same promise three times in one viewport. The
/// weekly tile lost its trial clause for the same reason.
///
/// **The savings sticker sits in a `Stack`, and that Stack is a known trap.**
/// A `Stack` passes LOOSE constraints to non-positioned children, so the card
/// will size to its widest line of text — ~55% of the column, with the sticker
/// stranded beside it — unless it is given an explicit width. That is exactly
/// what the old trial badge did. `width: double.infinity` on the card is
/// load-bearing; do not remove it while a `Positioned` sibling exists.
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
                  // MUST stay explicit. A `Stack` hands LOOSE constraints to
                  // its non-positioned children, so without this the card
                  // sizes to its widest line of text and renders at ~55% of
                  // the column with the sticker stranded beside it — the exact
                  // bug the previous badge caused.
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  decoration: BoxDecoration(
                    color: annualSelected
                        ? AppColors.primaryLight
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
                    ],
                  ),
                ),
                // The savings STICKER, sat on the tile's top-right edge.
                //
                // It was an inline chip in the card's text column, which put
                // the strongest argument for annual third in reading order,
                // at 12px, below the price. As a sticker it reads before the
                // price does — which is the job, since the whole point is that
                // the price is smaller than it looks.
                //
                // Gold as a FILL with `goldInk` text: bright gold sits at
                // ~2.2:1 on cream and fails contrast for anything carrying
                // meaning (DESIGN.md §2.3). The rotation is slight on purpose
                // — enough to read as an applied sticker, not enough to look
                // like a rendering error.
                // Absent whenever the saving could not be computed from the
                // live packages. The card's `width: double.infinity` above
                // stays load-bearing either way — do not "simplify" it on the
                // grounds that the Stack sometimes has one child.
                if (offer.annualSavingsLabel != null)
                  Positioned(
                    top: -12,
                    right: 12,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: -0.045,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: AppColors.secondary,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            offer.annualSavingsLabel!,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.goldInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
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
          child: GestureDetector(
            onTap: () => onSelect(PaywallPlanType.weekly),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              // Shorter than the annual card and single-line, so the two read
              // as primary and alternative rather than as a pair to weigh.
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: annualSelected
                    ? AppColors.surfaceLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: annualSelected
                      ? AppColors.borderLight
                      : AppColors.primary,
                  width: annualSelected ? 1 : 1.5,
                ),
              ),
              child: Text(
                offer.weeklyRowLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontSize: 15,
                  fontWeight:
                      annualSelected ? FontWeight.w400 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
