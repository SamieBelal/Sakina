import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/card_collection_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/widgets/share_card.dart';
import 'package:sakina/features/collection/widgets/bronze_ornate_card.dart';
import 'package:sakina/features/collection/widgets/gold_ornate_card.dart';
import 'package:go_router/go_router.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

enum _Filter { all, newCards, bronze, silver, gold }

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  _Filter _filter = _Filter.all;
  bool _questFired = false;

  @override
  void initState() {
    super.initState();
    // Reload from disk on first mount so newly engaged cards appear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardCollectionProvider.notifier).reload();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload and auto-show new cards if any exist.
    ref.read(cardCollectionProvider.notifier).reload().then((_) {
      if (!mounted) return;
      final col = ref.read(cardCollectionProvider);
      final hasUnseen = col.discoveredIds.any((id) => col.isUnseen(id));
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

    final filtered = switch (_filter) {
      _Filter.all => allCollectibleNames,
      _Filter.newCards => allCollectibleNames.where((n) => collection.isUnseen(n.id)).toList(),
      _Filter.bronze => allCollectibleNames.where((n) => collection.cardTierFor(n.id) == CardTier.bronze).toList(),
      _Filter.silver => allCollectibleNames.where((n) => collection.cardTierFor(n.id) == CardTier.silver).toList(),
      _Filter.gold => allCollectibleNames.where((n) => collection.cardTierFor(n.id) == CardTier.gold).toList(),
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding, 32,
                  AppSpacing.pagePadding, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.05, end: 0, duration: 500.ms),
                    const SizedBox(height: AppSpacing.lg),
                    _buildProgressSummary(collection),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTierFilters(collection),
                    const SizedBox(height: AppSpacing.sm),
                    // DEBUG: Preview buttons — remove later
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/silver-preview'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8A9AD).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Silver Preview', style: AppTypography.labelSmall.copyWith(color: const Color(0xFFA8A9AD))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/gold-preview'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8985E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Gold Preview', style: AppTypography.labelSmall.copyWith(color: const Color(0xFFC8985E))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/bronze-preview'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCD7F32).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Bronze Preview', style: AppTypography.labelSmall.copyWith(color: const Color(0xFFCD7F32))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = filtered[index];
                    final tier = collection.cardTierFor(card.id);
                    return _CardTile(
                      card: card,
                      tier: tier,
                      unseen: collection.isUnseen(card.id),
                      onTap: tier != null
                          ? () => _showCardDetail(context, card, tier, collection)
                          : null,
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(CardCollectionState collection) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text('${collection.totalDiscovered}', style: AppTypography.displaySmall.copyWith(color: AppColors.primary)),
          Text(' / ${collection.totalCards}', style: AppTypography.bodyLarge.copyWith(color: AppColors.textTertiaryLight)),
          const SizedBox(width: 8),
          Text('Names discovered', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          const Spacer(),
          SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(
              value: collection.progress,
              strokeWidth: 3.5,
              backgroundColor: AppColors.borderLight,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, delay: 200.ms);
  }

  Widget _buildTierFilters(CardCollectionState collection) {
    final unseenCount = collection.discoveredIds.where((id) => collection.isUnseen(id)).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(_Filter.all, 'All', '${collection.totalDiscovered}/${collection.totalCards}'),
          const SizedBox(width: 8),
          if (unseenCount > 0) ...[
            _filterChip(_Filter.newCards, 'New', '$unseenCount', dotColor: AppColors.primary),
            const SizedBox(width: 8),
          ],
          _filterChip(_Filter.bronze, 'Bronze', '${collection.totalBronze}', dotColor: const Color(0xFFCD7F32)),
          const SizedBox(width: 8),
          _filterChip(_Filter.silver, 'Silver', '${collection.totalSilver}', dotColor: const Color(0xFFA8A9AD)),
          const SizedBox(width: 8),
          _filterChip(_Filter.gold, 'Gold', '${collection.totalGold}', dotColor: const Color(0xFFC8985E)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _filterChip(_Filter filter, String label, String count, {Color? dotColor}) {
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
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '$label $count',
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDetail(BuildContext context, CollectibleName card, CardTier tier, CardCollectionState collection) {
    HapticFeedback.lightImpact();
    ref.read(questsProvider.notifier).onNameExplored();
    ref.read(cardCollectionProvider.notifier).markSeen(card.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CardDetailSheet(card: card, tier: tier),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.tier, this.unseen = false, this.onTap});

  final CollectibleName card;
  final CardTier? tier;
  final bool unseen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final discovered = tier != null;

    // Discovered cards get ornate dark treatment per tier
    if (discovered) {
      Widget ornateTile = switch (tier!) {
        CardTier.bronze => BronzeOrnateTile(arabic: card.arabic, transliteration: card.transliteration, unseen: unseen),
        CardTier.silver => _SilverOrnateTile(card: card, unseen: unseen),
        CardTier.gold => GoldOrnateTile(card: card, unseen: unseen),
      };
      return GestureDetector(onTap: onTap, child: ornateTile);
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
          Icon(Icons.lock_outline, color: AppColors.textTertiaryLight.withValues(alpha: 0.4), size: 24),
          const SizedBox(height: 6),
          Text(
            '???',
            style: AppTypography.nameOfAllahDisplay.copyWith(fontSize: 22, color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );

    return GestureDetector(onTap: onTap, child: tile);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Ornate Tile (Hearthstone-inspired dark collectible card)
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateTile extends StatelessWidget {
  const _SilverOrnateTile({required this.card, this.unseen = false});

  final CollectibleName card;
  final bool unseen;

  static const _bgDark = Color(0xFF2A2D3A);
  static const _bgMid = Color(0xFF353847);
  static const _silverBright = Color(0xFFCDD0D6);
  static const _silverCore = Color(0xFFA8A9AD);
  static const _silverDim = Color(0xFF6B6E78);
  static const _glowColor = Color(0xFFB8C8E0);
  static const _frameGold = Color(0xFFC8985E);

  @override
  Widget build(BuildContext context) {
    Widget tile = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withValues(alpha: unseen ? 0.4 : 0.15),
            blurRadius: unseen ? 20 : 10,
            spreadRadius: unseen ? 2 : 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Dark gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [_bgMid, _bgDark],
                ),
              ),
            ),

            // Islamic geometric pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _SilverIslamicPatternPainter(
                  color: _silverDim.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Ornate border frame
            Positioned.fill(
              child: CustomPaint(
                painter: _SilverOrnateBorderPainter(
                  color: _silverCore.withValues(alpha: 0.5),
                  cornerAccentColor: _silverBright.withValues(alpha: 0.7),
                ),
              ),
            ),

            // Center medallion (glow + ring + Arabic text)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final medallionSize = constraints.maxWidth * 0.55;
                  final glowSize = medallionSize + 16;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      SizedBox(
                        width: glowSize,
                        height: glowSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow
                            Container(
                              width: glowSize,
                              height: glowSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _glowColor.withValues(alpha: unseen ? 0.2 : 0.1),
                                    _glowColor.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            // Gold ring
                            Container(
                              width: medallionSize,
                              height: medallionSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _frameGold.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _frameGold.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            // Arabic text
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    card.arabic,
                                    style: AppTypography.nameOfAllahDisplay.copyWith(
                                      fontSize: 18,
                                      color: _silverBright,
                                      shadows: [
                                        Shadow(color: _glowColor.withValues(alpha: 0.5), blurRadius: 12),
                                        Shadow(color: _glowColor.withValues(alpha: 0.2), blurRadius: 24),
                                      ],
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),

                      // Tier dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final filled = i < 2;
                          return Container(
                            width: 4, height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? _silverBright : _silverDim.withValues(alpha: 0.3),
                              boxShadow: filled ? [
                                BoxShadow(color: _glowColor.withValues(alpha: 0.4), blurRadius: 4),
                              ] : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),

                      // Transliteration
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          card.transliteration,
                          style: AppTypography.labelSmall.copyWith(
                            color: _silverCore.withValues(alpha: 0.7),
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const Spacer(flex: 1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (unseen) {
      tile = tile
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2200.ms,
            color: _glowColor.withValues(alpha: 0.2),
          );
    }

    return tile;
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
        final r = cellSize * 0.38;

        final path = Path();
        final s1 = r * 0.7;
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
// Silver Ornate Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateBorderPainter extends CustomPainter {
  _SilverOrnateBorderPainter({required this.color, required this.cornerAccentColor});
  final Color color;
  final Color cornerAccentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const inset = 3.0;
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
      const Radius.circular(9),
    );
    canvas.drawRRect(borderRect, borderPaint);

    // Inner border
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const innerInset = 6.0;
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
      const Radius.circular(7),
    );
    canvas.drawRRect(innerRect, innerPaint);

    // Corner ornaments
    final accentPaint = Paint()
      ..color = cornerAccentColor
      ..style = PaintingStyle.fill;

    _drawCornerOrnament(canvas, accentPaint, inset + 1, inset + 1, 10, false, false);
    _drawCornerOrnament(canvas, accentPaint, w - inset - 1, inset + 1, 10, true, false);
    _drawCornerOrnament(canvas, accentPaint, inset + 1, h - inset - 1, 10, false, true);
    _drawCornerOrnament(canvas, accentPaint, w - inset - 1, h - inset - 1, 10, true, true);

    // Mid-edge diamonds
    final diamondPaint = Paint()
      ..color = cornerAccentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    _drawDiamond(canvas, diamondPaint, w / 2, inset, 2.5);
    _drawDiamond(canvas, diamondPaint, w / 2, h - inset, 2.5);
    _drawDiamond(canvas, diamondPaint, inset, h / 2, 2.5);
    _drawDiamond(canvas, diamondPaint, w - inset, h / 2, 2.5);
  }

  void _drawCornerOrnament(Canvas canvas, Paint paint, double x, double y, double size, bool flipX, bool flipY) {
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;

    const ds = 3.0;
    final diamond = Path()
      ..moveTo(x, y - ds * dy)
      ..lineTo(x + ds * dx, y)
      ..lineTo(x, y + ds * dy)
      ..lineTo(x - ds * dx, y)
      ..close();
    canvas.drawPath(diamond, paint);

    final linePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x + ds * dx * 1.2, y),
      Offset(x + size * dx * 0.6, y),
      linePaint,
    );
    canvas.drawLine(
      Offset(x, y + ds * dy * 1.2),
      Offset(x, y + size * dy * 0.6),
      linePaint,
    );
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double size) {
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
// Card Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _CardDetailSheet extends StatelessWidget {
  const _CardDetailSheet({required this.card, required this.tier});

  final CollectibleName card;
  final CardTier tier;

  @override
  Widget build(BuildContext context) {
    return switch (tier) {
      CardTier.bronze => BronzeOrnateDetailSheet(card: card, tier: tier),
      CardTier.silver => _SilverOrnateDetailSheet(card: card, tier: tier),
      CardTier.gold => GoldOrnateDetailSheet(card: card, tier: tier),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Ornate Detail Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateDetailSheet extends StatelessWidget {
  const _SilverOrnateDetailSheet({required this.card, required this.tier});

  final CollectibleName card;
  final CardTier tier;

  static const _bgDark = Color(0xFF2A2D3A);
  static const _bgMid = Color(0xFF353847);
  static const _silverBright = Color(0xFFCDD0D6);
  static const _silverCore = Color(0xFFA8A9AD);
  static const _silverDim = Color(0xFF6B6E78);
  static const _glowColor = Color(0xFFB8C8E0);
  static const _frameGold = Color(0xFFC8985E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8)),
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

            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: _silverDim.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Medallion ring + Arabic
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _frameGold.withValues(alpha: 0.35), width: 2),
                      boxShadow: [
                        BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 4),
                        BoxShadow(color: _frameGold.withValues(alpha: 0.1), blurRadius: 16),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            card.arabic,
                            style: AppTypography.nameOfAllahDisplay.copyWith(
                              fontSize: 38,
                              color: _silverBright,
                              shadows: [
                                Shadow(color: _glowColor.withValues(alpha: 0.6), blurRadius: 16),
                                Shadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 32),
                              ],
                            ),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scaleXY(begin: 0.85, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),

                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _silverCore.withValues(alpha: 0.25)),
                      color: _silverDim.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(3, (i) => Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < 2 ? _silverBright : _silverDim.withValues(alpha: 0.3),
                            boxShadow: i < 2 ? [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 3),
                            ] : null,
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

                  Text(card.transliteration, style: AppTypography.headlineMedium.copyWith(color: _silverBright))
                      .animate().fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 300.ms),
                  const SizedBox(height: 4),
                  Text(card.english, style: AppTypography.bodyMedium.copyWith(color: _silverCore))
                      .animate().fadeIn(duration: 500.ms, delay: 400.ms),
                  const SizedBox(height: 24),

                  // Ornate divider
                  SizedBox(
                    height: 12,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SilverOrnateDividerPainter(
                        lineColor: _silverDim.withValues(alpha: 0.3),
                        accentColor: _frameGold.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meaning
                  Text(card.meaning, style: AppTypography.bodyMedium.copyWith(color: _silverCore, height: 1.7), textAlign: TextAlign.center),
                  const SizedBox(height: 16),

                  // Lesson box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B6B4A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1B6B4A).withValues(alpha: 0.2)),
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
                          lineColor: _silverDim.withValues(alpha: 0.3),
                          accentColor: _frameGold.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 3, height: 16,
                          decoration: BoxDecoration(
                            color: _silverBright,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(color: _glowColor.withValues(alpha: 0.3), blurRadius: 4),
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
                      Text(card.hadith, style: AppTypography.bodyMedium.copyWith(color: _silverCore, height: 1.7, fontStyle: FontStyle.italic))
                    else
                      Text('Coming soon...', style: AppTypography.bodySmall.copyWith(color: _silverDim, fontStyle: FontStyle.italic)),
                  ],

                  // Upgrade hint
                  if (tier.number < 3) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Encounter this Name again to unlock the Dua',
                      style: AppTypography.bodySmall.copyWith(color: _silverDim),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Silver Ornate Detail Border Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _SilverOrnateDetailBorderPainter extends CustomPainter {
  _SilverOrnateDetailBorderPainter({required this.color, required this.accentColor});
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
      Rect.fromLTWH(innerInset, innerInset, w - innerInset * 2, h - innerInset * 2),
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

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double size) {
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
  _SilverOrnateDividerPainter({required this.lineColor, required this.accentColor});
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
    canvas.drawLine(Offset(centerX + ds + 6, cy), Offset(size.width - 20, cy), linePaint);

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
      canvas.drawPath(sm, Paint()..color = lineColor..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
