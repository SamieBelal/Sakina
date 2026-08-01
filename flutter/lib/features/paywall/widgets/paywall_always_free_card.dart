import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'paywall_gate_page.dart';

/// Shown once, ever, after the user dismisses the gate — then home.
///
/// It exists because the honest thing to do when someone declines is to tell
/// them plainly what they still have, rather than let a dismissed paywall be
/// the last thing they read. It never asks for anything: no second offer, no
/// referral chain, no "are you sure". [onContinue] is the only way out, and it
/// goes home.
class PaywallAlwaysFreeCard extends StatelessWidget {
  const PaywallAlwaysFreeCard({required this.onContinue, super.key});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                paywallEntry(
                  context,
                  0,
                  ExcludeSemantics(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        // Gold as a fill; the glyph strokes in `goldInk`,
                        // which is the gold that passes contrast on cream.
                        color: AppColors.secondaryLight,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_outlined,
                        size: 26,
                        color: AppColors.goldInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                paywallEntry(
                  context,
                  1,
                  Text(
                    AppStrings.paywallAlwaysFreeCardBody,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontSize: 19,
                      fontWeight: FontWeight.w300,
                      height: 1.6,
                      letterSpacing: -0.19,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                paywallEntry(
                  context,
                  2,
                  OutlinedButton(
                    onPressed: onContinue,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    child: Text(
                      AppStrings.paywallGateContinue,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
