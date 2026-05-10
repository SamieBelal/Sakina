import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sakina/services/gating_service.dart' show GatedFeature;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

export 'package:sakina/services/gating_service.dart' show GatedFeature;

/// Bottom sheet shown the first time a free user exhausts a feature's
/// lifetime warm-up budget (10 reflects / 10 duas / 5 discoveries).
///
/// Copy is parameterized per [GatedFeature]. Primary CTA opens the paywall;
/// secondary dismisses and lets the user fall through to the 1/day cap.
class WarmupExhaustedSheet extends StatelessWidget {
  final GatedFeature feature;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const WarmupExhaustedSheet({
    super.key,
    required this.feature,
    required this.onUpgrade,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required GatedFeature feature,
    required VoidCallback onUpgrade,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return WarmupExhaustedSheet(
          feature: feature,
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  String get _headline {
    switch (feature) {
      case GatedFeature.reflect:
        return "You've completed your free reflections";
      case GatedFeature.builtDua:
        return "You've built your free duas";
      case GatedFeature.discoverName:
        return "You've discovered your free Names";
    }
  }

  String get _body {
    // Body copy is identical across features per spec.
    return "From tomorrow you'll get one a day. Or unlock unlimited now.";
  }

  @override
  Widget build(BuildContext context) {
    return _PaywallSheetScaffold(
      icon: Icons.auto_awesome,
      headline: _headline,
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
    );
  }
}

/// Shared scaffold so all three paywall sheets render with the same visual
/// language (drag handle, icon, headline, body, primary + secondary CTAs).
class _PaywallSheetScaffold extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _PaywallSheetScaffold({
    required this.icon,
    required this.headline,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Headline (DM Serif Display feel — using Outfit at high weight
              // since Outfit is the project's display font; spec calls for
              // serif but the project standardised on Outfit).
              Text(
                headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              // Body
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Primary CTA
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                  child: Text(
                    primaryLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Secondary text-only CTA
              TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  secondaryLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Re-export the shared scaffold so sibling widgets in this folder can use it
// without each one redefining the chrome. Keeping this private file-local but
// exposing via package-private import in the sibling files using `part` would
// require build_runner; instead, we duplicate intentionally-minimal code in
// the sibling sheets that all delegate to PaywallSheetScaffold defined below.
//
// To avoid duplication AND avoid `part`, we expose a public scaffold widget
// here that the other two sheets import. The leading underscore on
// `_PaywallSheetScaffold` would prevent that, so we also expose an alias.
class PaywallSheetScaffold extends StatelessWidget {
  final IconData icon;
  final String headline;
  final String body;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const PaywallSheetScaffold({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return _PaywallSheetScaffold(
      icon: icon,
      headline: headline,
      body: body,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    );
  }
}
