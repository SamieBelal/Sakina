import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// Store → Companion/wardrobe cross-link (spec §6 store integration).
///
/// Cosmetics deliberately do NOT get their own store tab or clutter the
/// token/scroll shelves — this single banner is the whole touchpoint. Routing
/// is the caller's business so the banner stays route-agnostic and testable.
class WardrobeCrossLinkBanner extends StatelessWidget {
  const WardrobeCrossLinkBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Personalize your lantern',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
