import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';

/// Home-screen upgrade affordance — a slim gold strip shown ONLY to free users,
/// tapping through to the paywall. A second in-app entry point alongside the
/// persistent Settings → Premium card (`SettingsPremiumCard`), placed above the
/// daily muḥāsabah CTA on the home dashboard.
///
/// Watches the same `premiumStateProvider` the Settings card uses. Premium
/// users collapse to `SizedBox.shrink()`. A transient RevenueCat outage
/// (loading / error) also collapses — the Settings card is the guaranteed
/// affordance, so we never risk showing the upsell to a paying user here.
class HomePremiumStrip extends ConsumerWidget {
  const HomePremiumStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumStateProvider).valueOrNull;

    // Only free users see the strip. Loading / error / premium all collapse.
    if (state == null || state.isPremium) {
      return const SizedBox.shrink();
    }

    return Padding(
      // Match the vertical rhythm of the other self-collapsing cards in the
      // home scroll body — own the bottom margin only when shown.
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPaywall(context, ref),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
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
              border:
                  Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                // Dark text on the light gold gradient keeps contrast legible —
                // bright gold (#C8985E) as text on cream fails WCAG, so it's a
                // fill/accent here only, never the copy color.
                Expanded(
                  child: Text(
                    'Try Sakina Premium →',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
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

  void _openPaywall(BuildContext context, WidgetRef ref) {
    ref.read(analyticsProvider).track(AnalyticsEvents.homePremiumStripTapped);
    context.push('/paywall');
  }
}
