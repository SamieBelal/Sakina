import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/daily/providers/daily_rewards_provider.dart';

/// Thin Material banner shown at the top of the app when a billing issue
/// has been detected on the premium entitlement. Non-dismissable by design:
/// without action, the subscription will lapse. Deep-links to the store's
/// subscription management UI.
///
/// Reads the combined `premiumStateProvider` (single source of truth for
/// premium status + billing issue) so the banner can never disagree with
/// the Settings premium card about whether payment is broken.
class BillingIssueBanner extends ConsumerWidget {
  const BillingIssueBanner({super.key});

  static const _iosSubsUrl = 'https://apps.apple.com/account/subscriptions';
  static const _androidSubsUrl =
      'https://play.google.com/store/account/subscriptions';

  Future<void> _openSubscriptionManagement() async {
    final url = Platform.isIOS ? _iosSubsUrl : _androidSubsUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumStateProvider);
    final detectedAt = status.value?.billingIssueAt;

    if (detectedAt == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.errorBackground,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: _openSubscriptionManagement,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "We couldn't process your last payment",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap to update your payment method and keep Premium.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondaryLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
