import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/widgets/subpage_header.dart';
import 'package:sakina/widgets/summary_metric_card.dart';

// Store pricing
const int tokenCostPerScroll = 20;
const int tokenCostStreakFreeze = 10;

// IAP product IDs — set these up in App Store Connect / Google Play Console / RevenueCat
const String iapTokens50 = 'sakina_tokens_50'; // $0.99

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  bool _purchasing = false;

  Future<void> _buyScrolls(int count) async {
    final cost = count * tokenCostPerScroll;
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    final result = await spendTokens(cost);
    if (result.success) {
      await ref.read(tierUpScrollProvider.notifier).earn(count);
      // Refresh token balance in daily loop state
      final tokenState = await getTokens();
      ref
          .read(dailyLoopProvider.notifier)
          .refreshTokenBalance(tokenState.balance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchased $count scroll${count == 1 ? '' : 's'}!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough tokens ($cost needed)'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _purchasing = false);
  }

  Future<void> _buyStreakFreeze() async {
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    final result = await spendTokens(tokenCostStreakFreeze);
    if (result.success) {
      await grantStreakFreeze();
      final tokenState = await getTokens();
      ref
          .read(dailyLoopProvider.notifier)
          .refreshTokenBalance(tokenState.balance);
      await ref.read(dailyRewardsProvider.notifier).reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Streak Freeze purchased!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough tokens ($tokenCostStreakFreeze needed)'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _purchasing = false);
  }

  Future<void> _buyTokensIAP() async {
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    try {
      final purchaseService = PurchaseService();
      final packages = await purchaseService.getOfferings();

      // Look for the token package
      final package = packages
          .where((p) => p.storeProduct.identifier == iapTokens50)
          .firstOrNull;

      if (package == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Token pack not available yet. Please try again later.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (mounted) setState(() => _purchasing = false);
        return;
      }

      final success = await purchaseService.purchase(package);
      if (success) {
        await earnTokens(50);
        final tokenState = await getTokens();
        ref
            .read(dailyLoopProvider.notifier)
            .refreshTokenBalance(tokenState.balance);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('50 Tokens purchased!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      // Purchase cancelled or failed — no action needed
    }

    if (mounted) setState(() => _purchasing = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokenBalance = ref.watch(dailyLoopProvider).tokenBalance;
    final scrollBalance = ref.watch(tierUpScrollProvider).balance;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.lg,
            AppSpacing.pagePadding,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SubpageHeader(
                title: 'Store',
                subtitle:
                    'Tokens, scrolls, and small boosts for your daily rhythm.',
              ),
              const SizedBox(height: AppSpacing.xl),
              // Balance cards
              Row(
                children: [
                  Expanded(
                    child: SummaryMetricCard(
                      icon: Icons.toll_rounded,
                      iconColor: AppColors.secondary,
                      label: 'Tokens',
                      value: '$tokenBalance',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryMetricCard(
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Scrolls',
                      value: '$scrollBalance',
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 28),

              // Buy Tokens section (real money)
              Text(
                'Buy Tokens',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use tokens for extra reflections, duas, and to buy scrolls.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              _iapItem(
                icon: Icons.toll,
                iconColor: AppColors.secondary,
                title: '50 Tokens',
                price: '\$0.99',
                onTap: _purchasing ? null : _buyTokensIAP,
              ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
              const SizedBox(height: 28),

              // Tier Up Scrolls section
              Text(
                'Tier Up Scrolls',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upgrade your cards from Bronze to Silver or Silver to Gold.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              _storeItem(
                icon: Icons.receipt_long,
                iconColor: const Color(0xFF3B82F6),
                title: '1 Scroll',
                cost: '$tokenCostPerScroll Tokens',
                onTap: _purchasing ? null : () => _buyScrolls(1),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 8),
              _storeItem(
                icon: Icons.receipt_long,
                iconColor: const Color(0xFF3B82F6),
                title: '5 Scrolls',
                cost: '${tokenCostPerScroll * 5} Tokens',
                badge: 'Popular',
                onTap: _purchasing ? null : () => _buyScrolls(5),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 8),
              _storeItem(
                icon: Icons.receipt_long,
                iconColor: const Color(0xFF3B82F6),
                title: '10 Scrolls',
                cost: '${tokenCostPerScroll * 10} Tokens',
                onTap: _purchasing ? null : () => _buyScrolls(10),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 28),

              // Streak Freeze section
              Text(
                'Streak Freeze',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Protect your streak if you miss a day.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              _storeItem(
                icon: Icons.ac_unit,
                iconColor: const Color(0xFF60A5FA),
                title: 'Streak Freeze',
                cost: '$tokenCostStreakFreeze Tokens',
                onTap: _purchasing ? null : _buyStreakFreeze,
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String cost,
    String? badge,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge,
                              style: AppTypography.labelSmall
                                  .copyWith(color: Colors.white, fontSize: 9)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.toll,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 3),
                      Text(cost,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Buy',
                  style: AppTypography.labelSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iapItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String price,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(price,
                  style: AppTypography.labelSmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
