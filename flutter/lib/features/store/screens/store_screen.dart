

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/collection/widgets/emerald_ornate_card.dart';
import 'package:sakina/features/collection/widgets/ornate_card_shimmer.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/subpage_header.dart';
import 'package:sakina/widgets/summary_metric_card.dart';

// ── IAP product IDs ──────────────────────────────────────────────────────────
const String _iapPremiumOnce = 'sakina_premium';
const String _iapTokens100 = 'sakina_tokens_100';
const String _iapTokens250 = 'sakina_tokens_250';
const String _iapTokens500 = 'sakina_tokens_500';
const String _iapScrolls3 = 'sakina_scrolls_3';
const String _iapScrolls10 = 'sakina_scrolls_10';
const String _iapScrolls25 = 'sakina_scrolls_25';

// ── Premium perks granted on purchase ───────────────────────────────────────
const int _premiumTokenGrant = 10000;
const int _premiumScrollGrant = 1000;

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Purchase handlers ────────────────────────────────────────────────────

  Future<void> _buyPremium() async {
    setState(() => _purchasing = true);
    HapticFeedback.mediumImpact();

    try {
      final purchaseService = PurchaseService();
      final packages = await purchaseService.getOfferings();
      final package = packages
          .where((p) => p.storeProduct.identifier == _iapPremiumOnce)
          .firstOrNull;

      if (package == null) {
        if (mounted) _showError('Premium not available yet. Try again later.');
        if (mounted) setState(() => _purchasing = false);
        return;
      }

      final success = await purchaseService.purchase(package);
      if (success) {
        await earnTokens(_premiumTokenGrant);
        await ref.read(tierUpScrollProvider.notifier).earn(_premiumScrollGrant);
        final tokenState = await getTokens();
        ref
            .read(dailyLoopProvider.notifier)
            .refreshTokenBalance(tokenState.balance);
        if (mounted) _showSuccess('Welcome to Premium!');
      }
    } catch (_) {
      // Purchase cancelled or failed — no action needed
    }

    if (mounted) setState(() => _purchasing = false);
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

      final success = await purchaseService.purchase(package);
      if (success) {
        await earnTokens(amount);
        final tokenState = await getTokens();
        ref
            .read(dailyLoopProvider.notifier)
            .refreshTokenBalance(tokenState.balance);
        if (mounted) _showSuccess('$amount Tokens added!');
      }
    } catch (_) {}

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

      final success = await purchaseService.purchase(package);
      if (success) {
        await ref.read(tierUpScrollProvider.notifier).earn(amount);
        if (mounted) _showSuccess('$amount Scrolls added!');
      }
    } catch (_) {}

    if (mounted) setState(() => _purchasing = false);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primary,
    ));
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
                    subtitle: 'Tokens, scrolls, and Premium.',
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
                    decoration: BoxDecoration(
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
                        Tab(text: 'Premium'),
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
                  _PremiumTab(
                    purchasing: _purchasing,
                    onBuy: _buyPremium,
                  ),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Premium Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({
    required this.purchasing,
    required this.onBuy,
  });

  final bool purchasing;
  final VoidCallback onBuy;

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
          // ── Card fan hero ──────────────────────────────────────────────
          _CardFanHero().animate().fadeIn(duration: 600.ms).slideY(
              begin: 0.06,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOut),
          const SizedBox(height: 28),

          // ── Section label ──────────────────────────────────────────────
          Text(
            'SAKINA PREMIUM',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 6),
          Text(
            'Everything you need for a deeper practice.',
            style: AppTypography.headlineMedium
                .copyWith(color: AppColors.textPrimaryLight),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 24),

          // ── Perks list ─────────────────────────────────────────────────
          _PerksList()
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 28),

          // ── Price block ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One-time purchase',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Yours forever. No subscription.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '\$50',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 28),

          // ── CTA button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: purchasing ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: purchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Get Premium',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
          const SizedBox(height: 12),

          // ── Restore link ───────────────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: () async {
                final success = await PurchaseService().restore();
                if (success) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Premium restored!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: Text(
                'Restore purchase',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 450.ms),
        ],
      ),
    );
  }
}

// ── Card fan with 3 emerald cards ──────────────────────────────────────────

class _CardFanHero extends StatelessWidget {
  const _CardFanHero();

  @override
  Widget build(BuildContext context) {
    const cardWidth = 110.0;

    return SizedBox(
      height: 170,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Left card
            Positioned(
              left: 0,
              child: Transform.rotate(
                angle: -0.18,
                child: SizedBox(
                  width: cardWidth,
                  child: const EmeraldPreviewTile(
                    arabic: 'الرَّحْمَنُ',
                    transliteration: 'Ar-Rahman',
                  ),
                ),
              ),
            ),
            // Right card
            Positioned(
              right: 0,
              child: Transform.rotate(
                angle: 0.18,
                child: SizedBox(
                  width: cardWidth,
                  child: const EmeraldPreviewTile(
                    arabic: 'الرَّحِيمُ',
                    transliteration: 'Ar-Rahim',
                  ),
                ),
              ),
            ),
            // Center card (on top)
            SizedBox(
              width: cardWidth + 16,
              child: EmeraldPreviewTile(
                arabic: 'المَلِكُ',
                transliteration: 'Al-Malik',
                shimmer: const OrnateCardShimmer(enabled: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Perks list ─────────────────────────────────────────────────────────────

class _PerksList extends StatelessWidget {
  const _PerksList();

  @override
  Widget build(BuildContext context) {
    final perks = [
      (Icons.all_inclusive_rounded, AppColors.primary, 'Unlimited Reflect'),
      (Icons.auto_awesome_rounded, AppColors.primary, 'Unlimited Build a Dua'),
      (
        Icons.style_rounded,
        const Color(0xFF3CB371),
        'Exclusive Emerald Card Collection'
      ),
      (Icons.toll_rounded, AppColors.secondary, '10,000 Tokens'),
      (Icons.receipt_long_rounded, const Color(0xFF3B82F6), '1,000 Scrolls'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: perks
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: EdgeInsets.only(
                      bottom: e.key < perks.length - 1 ? 14 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: e.value.$2.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.value.$1,
                            color: e.value.$2, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.value.$3,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
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
