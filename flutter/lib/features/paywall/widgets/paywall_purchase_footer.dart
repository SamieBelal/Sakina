import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

/// The pinned purchase block: CTA, plain terms, the free-forever honesty line,
/// and Restore / Terms / Privacy.
///
/// All four are in the FOOTER rather than the scroll body on purpose. Restore
/// is an App Store requirement and a Restore button below the fold is a review
/// risk; the terms line is what guideline 3.1.2 wants visible before purchase.
/// Neither may depend on the user scrolling.
class PaywallPurchaseFooter extends StatelessWidget {
  const PaywallPurchaseFooter({
    required this.ctaLabel,
    required this.termsLine,
    required this.onPurchase,
    required this.onRestore,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.busy = false,
    this.restoring = false,
    this.errorMessage,
    this.showFreeForeverLine = true,
    this.extra,
    super.key,
  });

  final String ctaLabel;
  final String termsLine;
  final VoidCallback? onPurchase;
  final VoidCallback? onRestore;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final bool busy;
  final bool restoring;
  final String? errorMessage;

  /// The honesty line belongs to the decision moment (page 3 / the condensed
  /// screen), not to every page — repeating it on the ceremony pages would
  /// turn the free tier into the pitch.
  final bool showFreeForeverLine;

  /// Slot for surface-specific chrome under the legal row (the hard gate's
  /// offerings-failure safety valve).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMessage != null) ...[
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: busy ? null : onPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Text(
                    ctaLabel,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.17,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          termsLine,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            // `textSecondaryLight` is the FLOOR for billing terms — tertiary
            // is a hint colour and these are the terms of a charge.
            color: AppColors.textSecondaryLight,
          ),
        ),
        if (showFreeForeverLine) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.paywallFreeForeverFooter,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
        const SizedBox(height: 4),
        // Scaled down rather than wrapped: "Restore Purchase · Terms · Privacy"
        // is 69px too wide for a 390pt frame's gutters, and these three must
        // stay on one reachable line.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PaywallLegalLink(
                label: restoring ? 'Restoring…' : AppStrings.paywallRestore,
                onPressed: onRestore,
              ),
              _PaywallLegalLink(
                label: AppStrings.paywallTerms,
                onPressed: onOpenTerms,
              ),
              _PaywallLegalLink(
                label: AppStrings.paywallPrivacy,
                onPressed: onOpenPrivacy,
              ),
            ],
          ),
        ),
        if (extra != null) extra!,
      ],
    );
  }
}

class _PaywallLegalLink extends StatelessWidget {
  const _PaywallLegalLink({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiaryLight,
          fontSize: 12,
        ),
      ),
    );
  }
}
