import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

/// How the user left [PaywallExitOfferSheet].
enum PaywallExitOfferOutcome {
  /// Tapped the CTA — take them to the weekly purchase.
  accepted,

  /// Tapped "No thanks" — an explicit decline; the dismissal continues.
  declinedByButton,

  /// Scrim tap or back gesture. Still a decline for measurement, but the
  /// consequence differs: the user goes back to the paywall rather than out of
  /// it, which is how this sheet has always behaved.
  dismissed,
}

/// Shown when the user taps ✕ with the annual plan selected: weekly offered as
/// a price alternative, **not** a different product and **not** a second full
/// paywall (Apple guideline 5.6).
///
/// See the block comment on `AppStrings.paywallExitOfferTitle` for why this
/// exists at all — it is a deliberate, recorded divergence from the approved
/// paywall draft, kept so the mechanic can be measured before it is judged.
///
/// Every route out returns a [PaywallExitOfferOutcome]; **none returns null**,
/// so no exit can silently skip the decline event. `showModalBottomSheet`
/// reports a scrim tap and a back gesture identically (both pop with no value),
/// so the caller maps a null result to [PaywallExitOfferOutcome.dismissed]
/// rather than to nothing.
class PaywallExitOfferSheet extends StatelessWidget {
  const PaywallExitOfferSheet({
    required this.weeklyPrice,
    this.trialLabel,
    super.key,
  });

  /// Live storefront price string for the weekly package.
  final String weeklyPrice;

  /// `"7 days"` — derived from the weekly product's introductory offer AND
  /// this user's eligibility for it. `null` means no trial may be promised
  /// here either, so the copy drops the trial clause entirely.
  final String? trialLabel;

  @override
  Widget build(BuildContext context) {
    final trial = trialLabel;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.paywallExitOfferTitle,
              textAlign: TextAlign.center,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              trial == null
                  ? 'Not ready for a year? Try the weekly plan — '
                      '$weeklyPrice/week, cancel anytime.'
                  : AppStrings.paywallExitOfferBodyTemplate
                      .replaceAll('{trial}', trial),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            if (trial != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$weeklyPrice / week after trial',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  // Billing terms never go below `textSecondaryLight`.
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pop(PaywallExitOfferOutcome.accepted),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        // `buttonRadius` (12), matching every other CTA on
                        // every purchase surface: the gate's own footer, the
                        // ceremony's Continue, and both cap sheets.
                        //
                        // Pre-W5 this was a full pill (100) and was briefly
                        // restored to it on the grounds that D11 kept the
                        // sheet "as it was". That was the wrong call: the pill
                        // was not a deliberate style, it was the last survivor
                        // of an older button treatment, and keeping it would
                        // have left one odd control in a set of five that now
                        // agree. Consistency wins over faithfulness to a
                        // shape nothing else uses.
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: Text(
                  trial == null
                      ? 'Try weekly'
                      : AppStrings.paywallExitOfferAcceptTemplate
                          .replaceAll('{trial}', trial),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(PaywallExitOfferOutcome.declinedByButton),
              child: Text(
                AppStrings.paywallExitOfferDecline,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
