

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
      final packages = await purchaseService.getConsumablePackages();
      final package = packages
          .where((p) => p.storeProduct.identifier == productId)
          .firstOrNull;

      if (package == null) {
        if (mounted) _showError('Pack not available yet. Try again later.');
        if (mounted) setState(() => _purchasing = false);
        return;
      }

      // RC's contract: no-throw = success. Reaching this line means the
      // user has been charged and `customerInfo.nonSubscriptionTransactions`
      // includes the just-completed transaction.
      final customerInfo = await purchaseService.purchaseConsumable(package);
      // Route the local grant through ConsumableGrantsService — it shares
      // the credited-set dedup primitive with the orphan-recovery listener
      // registered in main.dart, so neither path can double-credit a single
      // transaction. Whichever wins the compare-and-set wins the grant;
      // the loser is a no-op.
      //
      // Pass the fresh `customerInfo` from `purchasePackage` directly —
      // a separate `Purchases.getCustomerInfo()` call would race with RC's
      // cache update and often return data missing the just-completed
      // transaction (the 2026-04-28 stale-balance bug). The grants stream
      // emitted by the service notifies `dailyLoopProvider` of the new
      // balance — no manual `refreshTokenBalance` call needed.
      await ConsumableGrantsService().grantForMostRecentPurchase(
        productId,
        customerInfo: customerInfo,
      );
      if (mounted) {
        _showPurchaseToast(
            context, 'Tokens', amount, AppColors.secondary, Icons.toll);
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
      final packages = await purchaseService.getConsumablePackages();
      final package = packages
          .where((p) => p.storeProduct.identifier == productId)
          .firstOrNull;

      if (package == null) {
        if (mounted) _showError('Pack not available yet. Try again later.');
        if (mounted) setState(() => _purchasing = false);
        return;
      }

      // See _buyTokensIAP for the customerInfo / grants-stream rationale —
      // same pattern, scrolls instead of tokens. The grants stream notifies
      // `tierUpScrollProvider` of the new balance, so no manual `.reload()`
      // call is needed.
      final customerInfo = await purchaseService.purchaseConsumable(package);
      await ConsumableGrantsService().grantForMostRecentPurchase(
        productId,
        customerInfo: customerInfo,
      );
      if (mounted) {
        _showPurchaseToast(context, 'Scrolls', amount,
            const Color(0xFF3B82F6), Icons.receipt_long);
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
        // Stack so the Restore Purchase pill floats over the scrolling tab
        // content instead of sitting in its own full-width strip below it
        // (which read as a beige band stretched across the screen).
        child: Stack(
          children: [
            Column(
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
                      const SizedBox(height: AppSpacing.xl),
                      // Tab bar — pill-style segmented control. Replaces
                      // the earlier hard-divider underline, which felt
                      // heavy against the warm cream background.
                      _StoreTabSelector(controller: _tabController),
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
              ],
            ),

            // Floating Restore Purchase pill — overlays the scrollable
            // content. The tab bodies add bottom padding equal to the pill
            // height so the last card stays visible when scrolled all the
            // way down.
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.lg,
              child: Center(
                child: TextButton.icon(
                  onPressed: _restorePurchases,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Restore purchase',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    backgroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
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
      // Bottom inset = floating Restore pill height (~48) + matching
      // breathing space above and below it (AppSpacing.lg ×2 = 48), so
      // when scrolled to the end the last card has the same gap from the
      // pill that the pill has from the bottom nav bar.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        AppSpacing.xxxl + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Buy Tokens',
            subtitle: 'Use tokens for extra reflections and duas.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _IapItem(
            icon: Icons.toll_rounded,
            iconColor: AppColors.secondary,
            title: '100 Tokens',
            subtitle: 'Starter pack',
            price: '\$1.99',
            highlighted: false,
            badge: null,
            onTap: purchasing ? null : () => onBuy(100, _iapTokens100),
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: AppSpacing.md),
          _IapItem(
            icon: Icons.toll_rounded,
            iconColor: AppColors.secondary,
            title: '250 Tokens',
            subtitle: 'Most popular',
            price: '\$3.99',
            highlighted: false,
            badge: null,
            onTap: purchasing ? null : () => onBuy(250, _iapTokens250),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: AppSpacing.md),
          _IapItem(
            icon: Icons.toll_rounded,
            iconColor: AppColors.secondary,
            title: '500 Tokens',
            subtitle: 'Save 30%',
            price: '\$6.99',
            highlighted: true,
            badge: 'Best Value',
            onTap: purchasing ? null : () => onBuy(500, _iapTokens500),
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
    const scrollColor = Color(0xFF3B82F6);
    return SingleChildScrollView(
      // Bottom inset = floating Restore pill height (~48) + matching
      // breathing space above and below it (AppSpacing.lg ×2 = 48), so
      // when scrolled to the end the last card has the same gap from the
      // pill that the pill has from the bottom nav bar.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xl,
        AppSpacing.pagePadding,
        AppSpacing.xxxl + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Buy Scrolls',
            subtitle: 'Upgrade cards from Bronze to Silver, Silver to Gold.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _IapItem(
            icon: Icons.receipt_long_rounded,
            iconColor: scrollColor,
            title: '3 Scrolls',
            subtitle: 'Starter pack',
            price: '\$0.99',
            highlighted: false,
            badge: null,
            onTap: purchasing ? null : () => onBuy(3, _iapScrolls3),
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: AppSpacing.md),
          _IapItem(
            icon: Icons.receipt_long_rounded,
            iconColor: scrollColor,
            title: '10 Scrolls',
            subtitle: 'Most popular',
            price: '\$2.49',
            highlighted: false,
            badge: null,
            onTap: purchasing ? null : () => onBuy(10, _iapScrolls10),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: AppSpacing.md),
          _IapItem(
            icon: Icons.receipt_long_rounded,
            iconColor: scrollColor,
            title: '25 Scrolls',
            subtitle: 'Save 40%',
            price: '\$4.99',
            highlighted: true,
            badge: 'Best Value',
            onTap: purchasing ? null : () => onBuy(25, _iapScrolls25),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared IAP item widget
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}

/// Pill-style segmented control. Replaces the previous TabBar-with-underline
/// because the solid divider beneath it felt heavy on the warm cream
/// background. The selected pill is filled primary; the unselected pill is
/// transparent with muted text. Single tap = animated swap.
class _StoreTabSelector extends StatefulWidget {
  const _StoreTabSelector({required this.controller});

  final TabController controller;

  @override
  State<_StoreTabSelector> createState() => _StoreTabSelectorState();
}

class _StoreTabSelectorState extends State<_StoreTabSelector> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.controller.index;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(label: 'Tokens', selected: index == 0, onTap: () {
            HapticFeedback.selectionClick();
            widget.controller.animateTo(0);
          }),
          _segment(label: 'Scrolls', selected: index == 1, onTap: () {
            HapticFeedback.selectionClick();
            widget.controller.animateTo(1);
          }),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: selected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IapItem extends StatelessWidget {
  const _IapItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.highlighted,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String price;
  final bool highlighted;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg =
        highlighted ? AppColors.primaryLight : AppColors.surfaceLight;
    final borderColor =
        highlighted ? AppColors.primary : AppColors.borderLight;
    final borderWidth = highlighted ? 1.5 : 1.0;

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0x0F0F172A),
            blurRadius: highlighted ? 20 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: highlighted
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                    fontWeight:
                        highlighted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              price,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: card,
      ),
    );

    if (badge == null) return tappable;

    // Floating "Best Value" ribbon — sits above the card so it reads as a
    // tag, not part of the title row. Negative top offset on a Padding so
    // it overlaps the card border.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: tappable,
        ),
        Positioned(
          top: 0,
          right: 18,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              badge!,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
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
