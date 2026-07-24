import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/card_collection_provider.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/features/collection/widgets/bronze_ornate_card.dart';
import 'package:sakina/features/collection/widgets/silver_card_preview.dart';
import 'package:sakina/features/daily/widgets/name_reveal_overlay.dart';
import 'package:sakina/features/collection/widgets/gold_ornate_card.dart';
import 'package:sakina/features/collection/widgets/emerald_ornate_card.dart';
import 'package:go_router/go_router.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

enum _Filter { all, newCards, bronze, silver, gold, emerald }

class _GridEntry {
  final CollectibleName card;
  final CardTier? displayTier; // null = locked
  final bool isMaxTier;

  /// When true this is a locked "Emerald · Premium" teaser tile shown to free
  /// users in the All view — tapping routes to the paywall rather than a
  /// card-detail sheet. `displayTier` stays null so it renders as a locked
  /// tile (with a Premium lock badge instead of the plain "???" treatment).
  final bool premiumLocked;

  const _GridEntry(
      {required this.card,
      this.displayTier,
      this.isMaxTier = false,
      this.premiumLocked = false});
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  _Filter _filter = _Filter.all;
  bool _questFired = false;
  bool _showOnlyDiscovered = false;
  // Tri-state: null = premium not resolved yet. Teaser tiles render only once
  // this is explicitly `false`, so a premium user never flashes the locked
  // "Emerald · Premium" tiles on their own collection while isPremium()'s
  // (possibly networked) resolve is in flight.
  bool? _isPremium;
  NavigatorState? _sheetNavigator;
  AppSessionNotifier? _session;

  @override
  void initState() {
    super.initState();
    // Resolve premium status so the "All" view can decide whether to show the
    // locked Emerald · Premium teaser tiles (free users only).
    PurchaseService().isPremium().then((v) {
      if (mounted) setState(() => _isPremium = v);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reload from disk on first mount so newly engaged cards appear.
      ref.read(cardCollectionProvider.notifier).reload();
      // Listen for economy hydration so scroll balance refreshes after sign-in.
      final session = ref.read(appSessionProvider);
      _session = session;
      if (!session.economyHydrated) {
        session.addListener(_onSessionChange);
      } else {
        ref.read(tierUpScrollProvider.notifier).reload();
      }
    });
  }

  void _onSessionChange() {
    if (!mounted) {
      _session?.removeListener(_onSessionChange);
      return;
    }
    final session = _session;
    if (session != null && session.economyHydrated) {
      session.removeListener(_onSessionChange);
      ref.read(tierUpScrollProvider.notifier).reload();
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChange);
    super.dispose();
  }

  @override
  void deactivate() {
    if (_sheetNavigator != null && _sheetNavigator!.canPop()) {
      _sheetNavigator!.pop();
      _sheetNavigator = null;
    }
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload and auto-show new cards if any exist.
    ref.read(cardCollectionProvider.notifier).reload().then((_) {
      if (!mounted) return;
      final col = ref.read(cardCollectionProvider);
      final hasUnseen = col.discoveredIds.any(col.isUnseen);
      if (hasUnseen) {
        setState(() => _filter = _Filter.newCards);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reload collection from disk whenever daily loop engages a card.
    ref.listen(dailyLoopProvider.select((s) => s.engagedCard), (prev, next) {
      if (next != null && next != prev) {
        ref.read(cardCollectionProvider.notifier).reload();
      }
    });

    final collection = ref.watch(cardCollectionProvider);
    if (!_questFired) {
      _questFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(questsProvider.notifier).onCollectionVisited();
      });
    }

    final List<_GridEntry> filtered = switch (_filter) {
      _Filter.all => _showOnlyDiscovered
          ? _buildDiscoveredEntries(collection)
          : _buildAllEntries(collection),
      _Filter.newCards => _buildNewEntries(collection),
      _Filter.bronze => _buildTierEntries(collection, CardTier.bronze),
      _Filter.silver => _buildTierEntries(collection, CardTier.silver),
      _Filter.gold => _buildTierEntries(collection, CardTier.gold),
      _Filter.emerald => _buildTierEntries(collection, CardTier.emerald),
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: _filter == _Filter.all
          ? FloatingActionButton.small(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _showOnlyDiscovered = !_showOnlyDiscovered);
              },
              backgroundColor: _showOnlyDiscovered
                  ? AppColors.primary
                  : AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: _showOnlyDiscovered
                        ? AppColors.primary
                        : AppColors.borderLight),
              ),
              child: Icon(
                _showOnlyDiscovered
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 20,
                color: _showOnlyDiscovered
                    ? Colors.white
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  32,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Collection',
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const Spacer(),
                        Builder(builder: (_) {
                          final scrolls =
                              ref.watch(tierUpScrollProvider).balance;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long,
                                    size: 14, color: Color(0xFF3B82F6)),
                                const SizedBox(width: 4),
                                Text(
                                  '$scrolls',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.05, end: 0, duration: 500.ms),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTierFilters(collection),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = filtered[index];
                    if (entry.displayTier == null) {
                      // Locked tile. A premium teaser routes to the paywall;
                      // an ordinary undiscovered tile is inert.
                      return _CardTile(
                          card: entry.card,
                          tier: null,
                          unseen: false,
                          premiumLocked: entry.premiumLocked,
                          onTap: entry.premiumLocked
                              ? () {
                                  HapticFeedback.lightImpact();
                                  context.push('/paywall');
                                }
                              : null);
                    }
                    return _CardTile(
                      card: entry.card,
                      tier: entry.displayTier,
                      unseen:
                          collection.isUnseen(entry.card.id, entry.displayTier),
                      onTap: () => _showCardDetail(context, entry.card,
                          entry.displayTier!, entry.isMaxTier, collection),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
            // DEBUG: Preview button per tier
            if (_filter == _Filter.bronze ||
                _filter == _Filter.silver ||
                _filter == _Filter.gold ||
                _filter == _Filter.emerald)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding,
                      AppSpacing.lg, AppSpacing.pagePadding, 0),
                  child: GestureDetector(
                    onTap: () => context.push(switch (_filter) {
                      _Filter.bronze => '/bronze-preview',
                      _Filter.silver => '/silver-preview',
                      _Filter.gold => '/gold-preview',
                      _Filter.emerald => '/emerald-preview',
                      _ => '',
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: switch (_filter) {
                          _Filter.bronze =>
                            const Color(0xFFCD7F32).withValues(alpha: 0.15),
                          _Filter.silver =>
                            const Color(0xFFA8A9AD).withValues(alpha: 0.12),
                          _Filter.gold =>
                            const Color(0xFFC8985E).withValues(alpha: 0.15),
                          _Filter.emerald =>
                            AppColors.primary.withValues(alpha: 0.15),
                          _ => Colors.transparent,
                        },
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 14,
                              color: switch (_filter) {
                                _Filter.bronze => const Color(0xFFCD7F32),
                                _Filter.silver => const Color(0xFFA8A9AD),
                                _Filter.gold => const Color(0xFFC8985E),
                                _Filter.emerald => AppColors.primary,
                                _ => Colors.transparent,
                              }),
                          const SizedBox(width: 6),
                          Text(
                            '${switch (_filter) {
                              _Filter.bronze => 'Bronze',
                              _Filter.silver => 'Silver',
                              _Filter.gold => 'Gold',
                              _Filter.emerald => 'Emerald',
                              _ => ''
                            }} Preview',
                            style: AppTypography.labelSmall.copyWith(
                              color: switch (_filter) {
                                _Filter.bronze => const Color(0xFFCD7F32),
                                _Filter.silver => const Color(0xFFA8A9AD),
                                _Filter.gold => const Color(0xFFC8985E),
                                _Filter.emerald => AppColors.primary,
                                _ => Colors.transparent,
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  List<_GridEntry> _buildAllEntries(CardCollectionState col) {
    final entries = <_GridEntry>[];
    for (final name in currentCollectibleNames()) {
      final tiers = col.unlockedTiersFor(name.id);
      if (tiers.isEmpty) {
        entries.add(_GridEntry(card: name));
      } else {
        for (final tier in tiers) {
          entries.add(_GridEntry(
              card: name, displayTier: tier, isMaxTier: tier == tiers.last));
        }
        // Conversion hook: for every Name a FREE user has collected but whose
        // Emerald tier they haven't earned, surface one locked "Emerald ·
        // Premium" teaser tile that routes to the paywall. Premium users never
        // see it (they can earn Emerald directly). Denominator stays *4.
        if (_isPremium == false && !tiers.contains(CardTier.emerald)) {
          entries.add(_GridEntry(card: name, premiumLocked: true));
        }
      }
    }
    return entries;
  }

  List<_GridEntry> _buildDiscoveredEntries(CardCollectionState col) {
    final entries = <_GridEntry>[];
    for (final name in currentCollectibleNames()) {
      final tiers = col.unlockedTiersFor(name.id);
      for (final tier in tiers) {
        entries.add(_GridEntry(
            card: name, displayTier: tier, isMaxTier: tier == tiers.last));
      }
    }
    return entries;
  }

  List<_GridEntry> _buildTierEntries(CardCollectionState col, CardTier tier) {
    return currentCollectibleNames()
        .where((n) => col.hasTierVersion(n.id, tier))
        .map((n) => _GridEntry(
              card: n,
              displayTier: tier,
              isMaxTier: col.cardTierFor(n.id) == tier,
            ))
        .toList();
  }

  List<_GridEntry> _buildNewEntries(CardCollectionState col) {
    final entries = <_GridEntry>[];
    for (final name in currentCollectibleNames()) {
      final tiers = col.unlockedTiersFor(name.id);
      for (final tier in tiers) {
        if (col.isUnseen(name.id, tier)) {
          entries.add(_GridEntry(
              card: name, displayTier: tier, isMaxTier: tier == tiers.last));
        }
      }
    }
    return entries;
  }

  Widget _buildTierFilters(CardCollectionState collection) {
    final unseenCount = collection.unseenCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(_Filter.all, 'All',
              '${collection.totalDiscovered}/${collection.totalCards}'),
          const SizedBox(width: 8),
          if (unseenCount > 0) ...[
            _filterChip(_Filter.newCards, 'New', '$unseenCount',
                dotColor: AppColors.primary),
            const SizedBox(width: 8),
          ],
          _filterChip(_Filter.bronze, 'Bronze', '${collection.totalBronze}',
              dotColor: const Color(0xFFCD7F32)),
          const SizedBox(width: 8),
          _filterChip(_Filter.silver, 'Silver', '${collection.totalSilver}',
              dotColor: const Color(0xFFA8A9AD)),
          const SizedBox(width: 8),
          _filterChip(_Filter.gold, 'Gold', '${collection.totalGold}',
              dotColor: const Color(0xFFC8985E)),
          const SizedBox(width: 8),
          _filterChip(_Filter.emerald, 'Emerald', '${collection.totalEmerald}',
              dotColor: AppColors.primary),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _filterChip(_Filter filter, String label, String count,
      {Color? dotColor}) {
    final isSelected = _filter == filter;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _filter = filter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '$label $count',
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDetail(BuildContext context, CollectibleName card,
      CardTier tier, bool isMaxTier, CardCollectionState collection) {
    HapticFeedback.lightImpact();
    ref.read(questsProvider.notifier).onNameExplored();
    ref
        .read(cardCollectionProvider.notifier)
        .markSeen(card.id, tierNumber: tier.number);
    _sheetNavigator = Navigator.of(context, rootNavigator: true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => _CardDetailSheet(
        card: card,
        tier: tier,
        isMaxTier: isMaxTier,
        // Use this State's ref, which outlives the sheet, so the achievement
        // check + toast complete after the sheet pops.
        onTieredUp: () => unawaited(checkAchievements(ref)),
      ),
    ).whenComplete(() => _sheetNavigator = null);
  }
}

enum CollectionTierUpFailureAction {
  goToStore,
  retry,
}

class CollectionTierUpFailurePresentation {
  final String title;
  final String message;
  final CollectionTierUpFailureAction primaryAction;
  final String primaryActionLabel;

  const CollectionTierUpFailurePresentation({
    required this.title,
    required this.message,
    required this.primaryAction,
    required this.primaryActionLabel,
  });
}

CollectionTierUpFailurePresentation? collectionTierUpFailurePresentation({
  required TierUpScrollSpendResult spendResult,
  required int scrollCost,
  required int scrollBalance,
  required String nextTier,
}) {
  if (spendResult.success) return null;

  switch (spendResult.failureReason) {
    case TierUpScrollFailureReason.insufficientBalance:
      return CollectionTierUpFailurePresentation(
        title: 'Not Enough Scrolls',
        message:
            'You need $scrollCost scrolls to upgrade to $nextTier. You have $scrollBalance.',
        primaryAction: CollectionTierUpFailureAction.goToStore,
        primaryActionLabel: 'Go to Store',
      );
    case TierUpScrollFailureReason.syncFailed:
      return const CollectionTierUpFailurePresentation(
        title: 'Couldn\'t Spend Scrolls',
        message:
            'Your balance looks fine, but we could not sync the upgrade right now. Please try again.',
        primaryAction: CollectionTierUpFailureAction.retry,
        primaryActionLabel: 'Try Again',
      );
    case null:
      return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _CardTile extends StatelessWidget {
  const _CardTile(
      {required this.card,
      required this.tier,
      this.unseen = false,
      this.premiumLocked = false,
      this.onTap});

  final CollectibleName card;
  final CardTier? tier;
  final bool unseen;

  /// Locked Emerald · Premium teaser (free users only) — renders an emerald
  /// tinted lock tile that routes to the paywall on tap.
  final bool premiumLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final discovered = tier != null;

    // Discovered cards get ornate dark treatment per tier
    if (discovered) {
      final Widget ornateTile = switch (tier!) {
        CardTier.bronze => BronzeOrnateTile(
            arabic: card.arabic,
            transliteration: card.transliteration,
            unseen: unseen),
        CardTier.silver => SilverOrnateTile(card: card, unseen: unseen),
        CardTier.gold => GoldOrnateTile(card: card, unseen: unseen),
        CardTier.emerald => EmeraldOrnateTile(card: card, unseen: unseen),
      };
      // Explicit "NEW" pill on unseen tiles — the ambient shimmer alone is easy
      // to miss, so a labelled badge makes a freshly-granted card unmistakable
      // on the grid. Cleared (with the shimmer) once the card is opened.
      final Widget tileWithBadge = unseen
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                ornateTile,
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary, // warm matte gold
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'NEW',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ornateTile;
      return GestureDetector(onTap: onTap, child: tileWithBadge);
    }

    // Emerald · Premium teaser — a tasteful, on-brand locked tile that shows a
    // free user the Emerald tier exists for a Name they've collected. Tapping
    // routes to the paywall (handled by [onTap]).
    if (premiumLocked) {
      const emerald = AppColors.primary; // deep emerald #1B6B4A
      const gold = AppColors.secondary; // warm matte gold #C8985E
      final Widget premiumTile = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              emerald.withValues(alpha: 0.10),
              emerald.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: emerald.withValues(alpha: 0.25), width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded,
                      color: emerald.withValues(alpha: 0.55), size: 22),
                  const SizedBox(height: 8),
                  // Faint Arabic Name so the tile feels tied to this card.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      card.arabic,
                      style: AppTypography.nameOfAllahDisplay.copyWith(
                        fontSize: 18,
                        color: emerald.withValues(alpha: 0.5),
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            // "Premium" badge, pinned bottom-center.
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 9, color: gold),
                      const SizedBox(width: 3),
                      Text(
                        'Premium',
                        style: AppTypography.labelSmall.copyWith(
                          color: gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      return GestureDetector(onTap: onTap, child: premiumTile);
    }

    // Locked/undiscovered cards
    final Widget tile = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              color: AppColors.textTertiaryLight.withValues(alpha: 0.4),
              size: 24),
          const SizedBox(height: 6),
          Text(
            '???',
            style: AppTypography.nameOfAllahDisplay.copyWith(
                fontSize: 22,
                color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );

    return GestureDetector(onTap: onTap, child: tile);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Islamic Pattern Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverIslamicPatternPainter extends CustomPainter {
  _SilverIslamicPatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const cellSize = 20.0;
    for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
      for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
        final cx = x + cellSize / 2;
        final cy = y + cellSize / 2;
        const r = cellSize * 0.38;

        final path = Path();
        const s1 = r * 0.7;
        path.moveTo(cx - s1, cy - s1);
        path.lineTo(cx + s1, cy - s1);
        path.lineTo(cx + s1, cy + s1);
        path.lineTo(cx - s1, cy + s1);
        path.close();

        path.moveTo(cx, cy - r);
        path.lineTo(cx + r, cy);
        path.lineTo(cx, cy + r);
        path.lineTo(cx - r, cy);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _CardDetailSheet extends ConsumerWidget {
  const _CardDetailSheet(
      {required this.card,
      required this.tier,
      required this.isMaxTier,
      this.onTieredUp});

  final CollectibleName card;
  final CardTier tier;
  final bool isMaxTier;

  /// Fired when a scroll upgrade tiers the card up. Invoked with the parent
  /// screen's long-lived ref (not this sheet's) so the downstream
  /// `checkAchievements` survives the sheet being popped on the same frame —
  /// otherwise its post-await `ref.read` throws on the disposed sheet element
  /// and the achievement toast is silently swallowed.
  final VoidCallback? onTieredUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollBalance = ref.watch(tierUpScrollProvider).balance;
    final scrollCost = tier == CardTier.bronze
        ? scrollCostBronzeToSilver
        : scrollCostSilverToGold;
    final showUpgrade = isMaxTier && tier.number < 3;
    final canAfford = scrollBalance >= scrollCost;
    final nextTier = tier.number == 1 ? 'Silver' : 'Gold';
    late final VoidCallback confirmUpgrade;

    void showSpendFailureSheet(CollectionTierUpFailurePresentation failure) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.receipt_long,
                  size: 32, color: Color(0xFF3B82F6)),
              const SizedBox(height: 12),
              Text(
                failure.title,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                failure.message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    switch (failure.primaryAction) {
                      case CollectionTierUpFailureAction.goToStore:
                        Navigator.of(context).pop();
                        GoRouter.of(context).push('/store');
                      case CollectionTierUpFailureAction.retry:
                        confirmUpgrade();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(failure.primaryActionLabel),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      );
    }

    confirmUpgrade = () {
      if (!canAfford) {
        final failure = collectionTierUpFailurePresentation(
          spendResult: TierUpScrollSpendResult(
            success: false,
            newBalance: scrollBalance,
            failureReason: TierUpScrollFailureReason.insufficientBalance,
          ),
          scrollCost: scrollCost,
          scrollBalance: scrollBalance,
          nextTier: nextTier,
        );
        if (failure != null) {
          showSpendFailureSheet(failure);
        }
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.receipt_long,
                  size: 32, color: Color(0xFF3B82F6)),
              const SizedBox(height: 12),
              Text(
                'Upgrade to $nextTier?',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use $scrollCost Tier Up Scroll${scrollCost == 1 ? '' : 's'} to upgrade ${card.transliteration} from ${tier.label} to $nextTier.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'You have $scrollBalance scroll${scrollBalance == 1 ? '' : 's'} remaining.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel',
                          style:
                              TextStyle(color: AppColors.textSecondaryLight)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetCtx).pop();
                        final spendResult = await ref
                            .read(tierUpScrollProvider.notifier)
                            .spend(scrollCost);
                        if (!spendResult.success) {
                          if (!context.mounted) return;
                          final failure = collectionTierUpFailurePresentation(
                            spendResult: spendResult,
                            scrollCost: scrollCost,
                            scrollBalance: spendResult.newBalance,
                            nextTier: nextTier,
                          );
                          if (failure != null) {
                            showSpendFailureSheet(failure);
                          }
                          return;
                        }

                        // Refund-on-throw: scrolls were already decremented
                        // by `spend(scrollCost)`. If `engageById` throws
                        // (e.g. SharedPreferences write fault, scoped-key
                        // collision, transient IO), the user paid for an
                        // upgrade that didn't apply. Re-credit via
                        // `earnTierUpScrolls` and surface a snackbar.
                        //
                        // The refund itself can fail too: when authenticated,
                        // `earn_scrolls` is an RPC that returns null on sync
                        // failure (`tier_up_scroll_service.dart:120-126`).
                        // We branch the snackbar copy so we don't lie about
                        // a refund that didn't land.
                        late final CardEngageResult engageResult;
                        try {
                          engageResult = await ref
                              .read(cardCollectionProvider.notifier)
                              .engageById(card.id);
                        } catch (e) {
                          debugPrint(
                              '[Collection] engageById failed after spend: $e');
                          final refund = await ref
                              .read(tierUpScrollProvider.notifier)
                              .earn(scrollCost);
                          if (refund.success) {
                            debugPrint(
                                '[Collection] refunded $scrollCost scrolls after engage failure');
                          } else {
                            // Both engage AND refund-RPC failed. Vanishingly
                            // rare in production, but we need to be honest:
                            // server already debited the spend, refund RPC
                            // returned null, so nothing the client does on
                            // its own will restore the balance. Log loud so
                            // it's visible in any crash/log reporter.
                            debugPrint(
                                '[Collection] CRITICAL: refund failed after engage failure. '
                                'User lost $scrollCost scrolls. reason=${refund.failureReason}');
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                refund.success
                                    ? "Couldn't upgrade. Your scrolls were refunded."
                                    : "Couldn't upgrade and your $scrollCost scrolls couldn't be refunded. Please contact support.",
                              ),
                            ),
                          );
                          return;
                        }
                        if (engageResult.tierChanged) {
                          ref.read(questsProvider.notifier).onCardTieredUp();
                          // Unlock tier-driven achievements (Golden Light,
                          // Silver Collector, First Upgrade…) at the moment
                          // the scroll upgrade lands. Without this they only
                          // unlock at the next muhasabah/reflect/dua check.
                          // Routed through the parent screen's ref (see
                          // [onTieredUp]) because this sheet is popped on the
                          // same frame below.
                          onTieredUp?.call();
                        }
                        if (context.mounted) {
                          final rootNav =
                              Navigator.of(context, rootNavigator: true);
                          Navigator.of(context).pop();
                          rootNav.push(
                            PageRouteBuilder(
                              opaque: true,
                              barrierDismissible: false,
                              pageBuilder: (_, __, ___) => NameRevealOverlay(
                                nameArabic: card.arabic,
                                nameEnglish: card.transliteration,
                                nameEnglishMeaning: card.english,
                                teaching: card.lesson,
                                card: card,
                                engageResult: engageResult,
                                onContinue: rootNav.pop,
                              ),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 16),
                          SizedBox(width: 6),
                          Text('Upgrade'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    };

    return switch (tier) {
      CardTier.bronze => BronzeOrnateDetailSheet(
          card: card,
          tier: tier,
          canUpgrade: showUpgrade,
          onUpgrade: showUpgrade ? confirmUpgrade : null,
          scrollCost: scrollCost,
          isMaxTier: isMaxTier,
        ),
      CardTier.silver => _SilverOrnateDetailSheet(
          card: card,
          tier: tier,
          canUpgrade: showUpgrade,
          onUpgrade: showUpgrade ? confirmUpgrade : null,
          scrollCost: scrollCost,
          isMaxTier: isMaxTier,
        ),
      CardTier.gold => GoldOrnateDetailSheet(card: card, tier: tier),
      CardTier.emerald => EmeraldOrnateDetailSheet(card: card, tier: tier),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Ornate Detail Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateDetailSheet extends StatelessWidget {
  const _SilverOrnateDetailSheet(
      {required this.card,
      required this.tier,
      this.canUpgrade = false,
      this.onUpgrade,
      this.scrollCost = 0,
      this.isMaxTier = true});

  final CollectibleName card;
  final CardTier tier;
  final bool canUpgrade;
  final VoidCallback? onUpgrade;
  final int scrollCost;
  final bool isMaxTier;

  static const _bgDark = Color(0xFF2A2D3A);
  static const _bgMid = Color(0xFF353847);
  static const _silverBright = Color(0xFFCDD0D6);
  static const _silverCore = Color(0xFFA8A9AD);
  static const _silverDim = Color(0xFF6B6E78);
  static const _glowColor = Color(0xFFB8C8E0);
  static const _frameGold = Color(0xFFC8985E);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final verticalInset = (media.padding.top + 28).clamp(56.0, 96.0);

    return SizedBox(
      height: media.size.height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, verticalInset, 12, verticalInset),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _glowColor.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2),
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Dark gradient background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_bgMid, _bgDark, Color(0xFF222533)],
                    ),
                  ),
                ),

                // Islamic pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SilverIslamicPatternPainter(
                      color: _silverDim.withValues(alpha: 0.05),
                    ),
                  ),
                ),

                // Ornate border
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SilverOrnateDetailBorderPainter(
                      color: _silverCore.withValues(alpha: 0.35),
                      accentColor: _frameGold.withValues(alpha: 0.3),
                    ),
                  ),
                ),

                // Content (scrollable) + sticky footer (Upgrade button / hint)
                Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                          child: ConstrainedBox(
                            // Match BronzeOrnateDetailSheet — vertically center
                            // content in available height instead of letting it
                            // pack at the top with dead space below.
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 40,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _silverDim.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 28),

                            // Medallion ring + Arabic
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _frameGold.withValues(alpha: 0.35),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: _glowColor.withValues(alpha: 0.15),
                                      blurRadius: 24,
                                      spreadRadius: 4),
                                  BoxShadow(
                                      color: _frameGold.withValues(alpha: 0.1),
                                      blurRadius: 16),
                                ],
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      card.arabic,
                                      style: AppTypography.nameOfAllahDisplay
                                          .copyWith(
                                        fontSize: 38,
                                        color: _silverBright,
                                        shadows: [
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.6),
                                              blurRadius: 16),
                                          Shadow(
                                              color: _glowColor.withValues(
                                                  alpha: 0.3),
                                              blurRadius: 32),
                                        ],
                                      ),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 800.ms).scaleXY(
                                begin: 0.85,
                                end: 1.0,
                                duration: 800.ms,
                                curve: Curves.easeOutBack),
                            const SizedBox(height: 16),

                            // Tier badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _silverCore.withValues(alpha: 0.25)),
                                color: _silverDim.withValues(alpha: 0.12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(
                                      3,
                                      (i) => Container(
                                            width: 5,
                                            height: 5,
                                            margin:
                                                const EdgeInsets.only(right: 3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: i < 2
                                                  ? _silverBright
                                                  : _silverDim.withValues(
                                                      alpha: 0.3),
                                              boxShadow: i < 2
                                                  ? [
                                                      BoxShadow(
                                                          color: _glowColor
                                                              .withValues(
                                                                  alpha: 0.3),
                                                          blurRadius: 3),
                                                    ]
                                                  : null,
                                            ),
                                          )),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SILVER',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _silverCore,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                            const SizedBox(height: 16),

                            Text(card.transliteration,
                                    style: AppTypography.headlineMedium
                                        .copyWith(color: _silverBright))
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 300.ms)
                                .slideY(
                                    begin: 0.1,
                                    end: 0,
                                    duration: 500.ms,
                                    delay: 300.ms),
                            const SizedBox(height: 4),
                            Text(card.english,
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: _silverCore))
                                .animate()
                                .fadeIn(duration: 500.ms, delay: 400.ms),
                            const SizedBox(height: 24),

                            // Ornate divider
                            SizedBox(
                              height: 12,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _SilverOrnateDividerPainter(
                                  lineColor: _silverDim.withValues(alpha: 0.3),
                                  accentColor:
                                      _frameGold.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Meaning
                            Text(card.meaning,
                                style: AppTypography.bodyMedium
                                    .copyWith(color: _silverCore, height: 1.7),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),

                            // Lesson box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B6B4A)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF1B6B4A)
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                card.lesson,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: const Color(0xFF8BC6A5),
                                  fontStyle: FontStyle.italic,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Tier 2: Hadith
                            if (tier.number >= 2) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 12,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _SilverOrnateDividerPainter(
                                    lineColor:
                                        _silverDim.withValues(alpha: 0.3),
                                    accentColor:
                                        _frameGold.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _silverBright,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: _glowColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'PROPHETIC TEACHING',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _silverCore,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (card.hasTier2Content)
                                Text(card.hadith,
                                    style: AppTypography.bodyMedium.copyWith(
                                        color: _silverCore,
                                        height: 1.7,
                                        fontStyle: FontStyle.italic))
                              else
                                Text('Coming soon...',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: _silverDim,
                                        fontStyle: FontStyle.italic)),
                            ],
                            const Spacer(),
                          ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Sticky footer — always-visible Upgrade CTA / hint, inset from
                    // the ornate border so it never overlaps the curved card edge.
                    if (isMaxTier && tier.number < 3)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: onUpgrade != null
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: onUpgrade,
                                  icon:
                                      const Icon(Icons.receipt_long, size: 18),
                                  label: Text('Upgrade ($scrollCost Scrolls)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _silverCore,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              )
                            : Text(
                                'Earn a Tier Up Scroll to unlock the Dua',
                                style: AppTypography.bodySmall
                                    .copyWith(color: _silverDim),
                                textAlign: TextAlign.center,
                              ),
                      )
                    else
                      const SizedBox(height: 24),
                  ],
                ),

                // Dismiss button — pinned to top-right so it doesn't fight
                // with the sticky footer at the bottom of the card.
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: _silverBright.withValues(alpha: 0.8),
                          size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Ornate Detail Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateDetailBorderPainter extends CustomPainter {
  _SilverOrnateDetailBorderPainter(
      {required this.color, required this.accentColor});
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const inset = 6.0;
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(14),
    );
    canvas.drawRRect(outerRect, borderPaint);

    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 10.0;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(12),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Gold accent diamonds
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    const ds = 3.5;

    _drawDiamond(canvas, accentPaint, w / 2, inset, ds);
    _drawDiamond(canvas, accentPaint, w / 2, h - inset, ds);
  }

  void _drawDiamond(
      Canvas canvas, Paint paint, double cx, double cy, double size) {
    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Ornate Divider Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateDividerPainter extends CustomPainter {
  _SilverOrnateDividerPainter(
      {required this.lineColor, required this.accentColor});
  final Color lineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    const ds = 4.0;
    final diamond = Path()
      ..moveTo(centerX, cy - ds)
      ..lineTo(centerX + ds, cy)
      ..lineTo(centerX, cy + ds)
      ..lineTo(centerX - ds, cy)
      ..close();
    canvas.drawPath(diamond, accentPaint);

    canvas.drawLine(Offset(20, cy), Offset(centerX - ds - 6, cy), linePaint);
    canvas.drawLine(
        Offset(centerX + ds + 6, cy), Offset(size.width - 20, cy), linePaint);

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(20, cy), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 20, cy), 1.5, dotPaint);

    const sds = 2.0;
    for (final px in [size.width * 0.28, size.width * 0.72]) {
      final sm = Path()
        ..moveTo(px, cy - sds)
        ..lineTo(px + sds, cy)
        ..lineTo(px, cy + sds)
        ..lineTo(px - sds, cy)
        ..close();
      canvas.drawPath(
          sm,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
