

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/consumable_grants_service.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/services/premium_grants_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/subpage_header.dart';
import 'package:sakina/widgets/summary_metric_card.dart';

// ── IAP product IDs ──────────────────────────────────────────────────────────
// Note: sakina_premium (one-time SKU) was removed per the subscription-only
// monetization decision on 2026-04-17 (docs/decisions/monetization-model.md).
// Premium is sold exclusively through the onboarding paywall subscriptions.
const String _iapTokens100 = 'sakina_tokens_100';
const String _iapTokens250 = 'sakina_tokens_250';
const String _iapTokens500 = 'sakina_tokens_500';
const String _iapScrolls3 = 'sakina_scrolls_3';
const String _iapScrolls10 = 'sakina_scrolls_10';
const String _iapScrolls25 = 'sakina_scrolls_25';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Purchase handlers ────────────────────────────────────────────────────

  /// Shared typed-error handler for all Store purchase flows.
  /// Silences user-initiated cancellation; surfaces everything else.
  void _handlePurchaseException(PlatformException error) {
    final code = PurchasesErrorHelper.getErrorCode(error);
    if (code == PurchasesErrorCode.purchaseCancelledError) return;
    if (!mounted) return;
    _showError('Purchase failed. Please try again.');
  }

  Future<void> _buyTokensIAP(int amount, String productId) async {
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    try {
      final purchaseService = PurchaseService();
      final packages = await purchaseService.getOfferings();
      final package = packages
          .where((p) => p.storeProduct.identifier == productId)
          .firstOrNull;

      if (package == null) {
        if (mounted) _showError('Pack not available yet. Try again later.');
        if (mounted) setState(() => _purchasing = false);
        return;
      }

      final success = await purchaseService.purchaseConsumable(package);
      if (success) {
        // Route the local grant through ConsumableGrantsService — it shares
        // the credited-set dedup primitive with the orphan-recovery
        // listener registered in main.dart, so neither path can
        // double-credit a single transaction. Whichever wins the
        // compare-and-set wins the grant; the loser is a no-op.
        await ConsumableGrantsService().grantForMostRecentPurchase(productId);
        // Refresh the balance pill regardless of who granted (us or the
        // listener) — the user paid, the balance is now correct.
        final tokenState = await getTokens();
        ref
            .read(dailyLoopProvider.notifier)
            .refreshTokenBalance(tokenState.balance);
        if (mounted) {
          _showPurchaseToast(
              context, 'Tokens', amount, AppColors.secondary, Icons.toll);
        }
      }
    } on PlatformException catch (error) {
      _handlePurchaseException(error);
    } catch (_) {
      if (mounted) _showError('Purchase failed. Please try again.');
    }

    if (mounted) setState(() => _purchasing = false);
  }

  Future<void> _buyScrollsIAP(int amount, String productId) async {
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    try {
      final purchaseService = PurchaseService();
      final packages = await purchaseService.getOfferings();
      final package = packages
          .where((p) => p.storeProduct.identifier == productId)
          .firstOrNull;

      if (package == null) {
        if (mounted) _showError('Pack not available yet. Try again later.');
        if (mounted) setState(() => _purchasing = false);
        return;
      }

      final success = await purchaseService.purchaseConsumable(package);
      if (success) {
        // Route the grant through ConsumableGrantsService for atomic dedup
        // with the orphan-recovery listener (see _buyTokensIAP for the
        // same comment). Service writes directly to the underlying
        // earnTierUpScrolls; the provider notifier just needs a reload to
        // reflect the new balance in the UI.
        await ConsumableGrantsService().grantForMostRecentPurchase(productId);
        await ref.read(tierUpScrollProvider.notifier).reload();
        if (mounted) {
          _showPurchaseToast(context, 'Scrolls', amount,
              const Color(0xFF3B82F6), Icons.receipt_long);
        }
      }
    } on PlatformException catch (error) {
      _handlePurchaseException(error);
    } catch (_) {
      if (mounted) _showError('Purchase failed. Please try again.');
    }

    if (mounted) setState(() => _purchasing = false);
  }

  void _showPurchaseToast(BuildContext context, String label, int amount,
      Color color, IconData icon) {
    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _PurchaseToastWidget(
        label: label,
        amount: amount,
        color: color,
        icon: icon,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokenBalance = ref.watch(dailyLoopProvider).tokenBalance;
    final scrollBalance = ref.watch(tierUpScrollProvider).balance;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SubpageHeader(
                    title: 'Store',
                    subtitle: 'Tokens and scrolls.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Balance row
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
                  const SizedBox(height: AppSpacing.lg),
                  // Tab bar
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondaryLight,
                      labelStyle: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      unselectedLabelStyle: AppTypography.labelMedium,
                      tabs: const [
                        Tab(text: 'Tokens'),
                        Tab(text: 'Scrolls'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TokensTab(
                    purchasing: _purchasing,
                    onBuy: _buyTokensIAP,
                  ),
                  _ScrollsTab(
                    purchasing: _purchasing,
                    onBuy: _buyScrollsIAP,
                  ),
                ],
              ),
            ),

            // Restore purchase link — users who bought a sub on another
            // device or reinstalled the app need a way back to Premium.
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.md,
                top: AppSpacing.xs,
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _restorePurchases,
                  child: Text(
                    'Restore purchase',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    bool success;
    try {
      success = await PurchaseService().restorePurchases();
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore failed. Please try again.'),
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore failed. Please try again.'),
        ),
      );
      return;
    }
    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active premium subscription was found to restore.'),
        ),
      );
      return;
    }
    ref.invalidate(isPremiumProvider);
    try {
      await checkPremiumMonthlyGrant();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Premium restored!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tokens Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _TokensTab extends StatelessWidget {
  const _TokensTab({required this.purchasing, required this.onBuy});

  final bool purchasing;
  final void Function(int amount, String productId) onBuy;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buy Tokens',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use tokens for extra reflections and duas.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          _IapItem(
            icon: Icons.toll_rounded,
            iconColor: AppColors.secondary,
            title: '100 Tokens',
            price: '\$1.99',
            badge: null,
            onTap: purchasing
                ? null
                : () => onBuy(100, _iapTokens100),
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: 10),
          _IapItem(
            icon: Icons.toll_rounded,
            iconColor: AppColors.secondary,
            title: '250 Tokens',
            price: '\$3.99',
            badge: null,
            onTap: purchasing
                ? null
                : () => onBuy(250, _iapTokens250),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 10),
          _IapItem(
            icon: Icons.toll_rounded,
            iconColor: AppColors.secondary,
            title: '500 Tokens',
            price: '\$6.99',
            badge: 'Best Value',
            onTap: purchasing
                ? null
                : () => onBuy(500, _iapTokens500),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Scrolls Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _ScrollsTab extends StatelessWidget {
  const _ScrollsTab({required this.purchasing, required this.onBuy});

  final bool purchasing;
  final void Function(int amount, String productId) onBuy;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buy Scrolls',
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
          const SizedBox(height: 16),
          _IapItem(
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: '3 Scrolls',
            price: '\$0.99',
            badge: null,
            onTap: purchasing
                ? null
                : () => onBuy(3, _iapScrolls3),
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: 10),
          _IapItem(
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: '10 Scrolls',
            price: '\$2.49',
            badge: null,
            onTap: purchasing
                ? null
                : () => onBuy(10, _iapScrolls10),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 10),
          _IapItem(
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: '25 Scrolls',
            price: '\$4.99',
            badge: 'Best Value',
            onTap: purchasing
                ? null
                : () => onBuy(25, _iapScrolls25),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared IAP item widget
// ═══════════════════════════════════════════════════════════════════════════════

class _IapItem extends StatelessWidget {
  const _IapItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.price,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String price;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
              child: Row(
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                price,
                style: AppTypography.labelSmall.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Purchase Celebration Toast
// ═══════════════════════════════════════════════════════════════════════════════

class _PurchaseToastWidget extends StatefulWidget {
  const _PurchaseToastWidget({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });
  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  @override
  State<_PurchaseToastWidget> createState() => _PurchaseToastWidgetState();
}

class _PurchaseToastWidgetState extends State<_PurchaseToastWidget> {
  bool _visible = false;
  bool _removed = false;

  void _dismiss() {
    if (_removed) return;
    _removed = true;
    widget.onDismiss();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() => _visible = false);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _dismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 60,
      right: 60,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: _visible ? 1.0 : 0.8,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 36)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.9, end: 1.2, duration: 600.ms),
                    const SizedBox(height: 12),
                    Text(
                      '+${widget.amount} ${widget.label}',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .shimmer(
                          delay: 200.ms,
                          duration: 1000.ms,
                          color: widget.color.withValues(alpha: 0.3),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
