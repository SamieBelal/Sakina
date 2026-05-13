import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';

/// Persistent Settings → Premium entry point. Added 2026-05-13 to satisfy
/// App Review's "subscriptions must be reachable outside onboarding"
/// requirement. Three resolved visual states + a loading skeleton, driven
/// by `premiumStateProvider`. Re-invalidates on `AppLifecycleState.resumed`
/// so returning from the StoreKit sheet refreshes the card state.
class SettingsPremiumCard extends ConsumerStatefulWidget {
  const SettingsPremiumCard({super.key});

  @override
  ConsumerState<SettingsPremiumCard> createState() => _SettingsPremiumCardState();
}

class _SettingsPremiumCardState extends ConsumerState<SettingsPremiumCard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(premiumStateProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(premiumStateProvider);

    // Loading → neutral skeleton. Error → State 1 (free) so a transient
    // RevenueCat outage never hides the upgrade affordance.
    if (async.isLoading && !async.hasValue) {
      return const _PremiumCardRow(
        icon: Icons.workspace_premium_rounded,
        iconColor: AppColors.textTertiaryLight,
        bgColor: AppColors.surfaceLight,
        borderColor: AppColors.borderLight,
        title: 'Sakina Premium',
        subtitle: '\u00A0',
      );
    }

    final state = async.valueOrNull;
    if (state == null || !state.isPremium) {
      return _PremiumCardFree(onTap: () => _openPaywall(context));
    }
    if (state.billingIssueAt != null) {
      return _PremiumCardRow(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.streakAmber,
        bgColor: AppColors.streakBackground,
        borderColor: AppColors.streakAmber,
        chevronColor: AppColors.streakAmber,
        title: 'Payment issue',
        subtitle: 'Tap to update payment',
        onTap: () => _openManageSubscription(
            context, AnalyticsEvents.settingsPremiumBillingIssueTapped),
      );
    }
    return _PremiumCardRow(
      icon: Icons.workspace_premium_rounded,
      iconColor: AppColors.primary,
      bgColor: AppColors.surfaceLight,
      borderColor: AppColors.borderLight,
      title: 'Sakina Premium',
      subtitle: 'Active \u00B7 Manage subscription',
      onTap: () => _openManageSubscription(
          context, AnalyticsEvents.settingsPremiumManageTapped),
    );
  }

  void _openPaywall(BuildContext context) {
    ref.read(analyticsProvider).track(AnalyticsEvents.settingsPremiumCtaTapped);
    context.push('/paywall');
  }

  /// Opens RevenueCat's Customer Center via `purchases_ui_flutter`, which
  /// presents the native in-app subscription management sheet (StoreKit on
  /// iOS 15+, Play Billing on Android). Apple's review-canonical post-iOS-15
  /// mechanism for "manage my subscription" surfaces inside Customer Center.
  Future<void> _openManageSubscription(
      BuildContext context, String eventName) async {
    ref.read(analyticsProvider).track(eventName);
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open subscription management. '
              'Open the App Store directly to manage your subscription.'),
        ),
      );
    }
  }
}

/// State 1 — distinct gold-gradient upsell card for free / unknown users.
class _PremiumCardFree extends StatelessWidget {
  const _PremiumCardFree({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondaryLight,
                AppColors.secondary.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sakina Premium',
                      style: AppTypography.displaySmall.copyWith(
                          fontSize: 18, color: AppColors.textPrimaryLight)),
                  const SizedBox(height: 2),
                  Text('Weekly & Annual plans \u00B7 Unlock everything',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.secondary, size: 22),
          ]),
        ),
      ),
    );
  }
}

/// States 2, 3, and the loading skeleton share an icon-title-subtitle-chevron
/// scaffold. Parameterized so we don't repeat the row three times.
class _PremiumCardRow extends StatelessWidget {
  const _PremiumCardRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.chevronColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? chevronColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: chevronColor ?? AppColors.textTertiaryLight),
          ]),
        ),
      ),
    );
  }
}
