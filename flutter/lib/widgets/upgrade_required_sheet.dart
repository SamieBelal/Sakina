import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Modal sheet shown when a free-tier user hits the journal save limit.
///
/// Previously these cases were a silent `return` (save just disappeared).
/// Now the user sees an explicit prompt: "you've saved X — upgrade for
/// unlimited" with a CTA that deep-links to /paywall.
///
/// Usage:
/// ```dart
/// ref.listen(reflectProvider, (prev, next) {
///   if (next.needsUpgrade) {
///     UpgradeRequiredSheet.show(context, currentCount: 5).then((_) {
///       ref.read(reflectProvider.notifier).dismissUpgradePrompt();
///     });
///   }
/// });
/// ```
class UpgradeRequiredSheet extends StatelessWidget {
  const UpgradeRequiredSheet({
    super.key,
    required this.currentCount,
    required this.featureLabel,
  });

  /// How many items the user has already saved in the free tier.
  final int currentCount;

  /// e.g. "reflection", "dua" — used in the copy.
  final String featureLabel;

  static Future<void> show(
    BuildContext context, {
    required int currentCount,
    required String featureLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UpgradeRequiredSheet(
        currentCount: currentCount,
        featureLabel: featureLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Icon(
              Icons.auto_awesome,
              color: AppColors.secondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "You've saved $currentCount ${featureLabel}s",
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimaryLight,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Upgrade to Premium to save unlimited ${featureLabel}s and revisit '
              'them whenever your heart needs them.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Capture the router BEFORE popping the sheet — after pop,
                  // this BuildContext is unmounting and GoRouter.of could fail.
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/paywall');
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
                  'Upgrade to Premium',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Not now',
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
