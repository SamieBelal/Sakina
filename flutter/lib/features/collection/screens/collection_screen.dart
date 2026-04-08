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
    final tierColor = tier != null ? Color(tier!.colorValue) : AppColors.borderLight;

    Widget tile = Container(
      decoration: BoxDecoration(
        color: discovered ? AppColors.surfaceLight : AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: discovered
              ? (unseen ? tierColor : tierColor.withValues(alpha: 0.6))
              : AppColors.borderLight,
          width: unseen ? 2.0 : (discovered ? 1.5 : 1),
        ),
        boxShadow: discovered
            ? [BoxShadow(color: tierColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (discovered) ...[
            // Tier indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < tier!.number;
                return Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? tierColor : tierColor.withValues(alpha: 0.2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              card.arabic,
              style: AppTypography.nameOfAllahDisplay.copyWith(fontSize: 22, color: AppColors.secondary),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                card.transliteration,
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tier!.label,
              style: AppTypography.labelSmall.copyWith(color: tierColor, fontSize: 8, fontWeight: FontWeight.w700),
            ),
          ] else ...[
            Icon(Icons.lock_outline, color: AppColors.textTertiaryLight.withValues(alpha: 0.4), size: 24),
            const SizedBox(height: 6),
            Text(
              '???',
              style: AppTypography.nameOfAllahDisplay.copyWith(fontSize: 22, color: AppColors.textTertiaryLight.withValues(alpha: 0.3)),
            ),
          ],
        ],
      ),
    );

    if (unseen) {
      tile = tile
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1800.ms,
            color: tierColor.withValues(alpha: 0.3),
          );
    }

    return GestureDetector(onTap: onTap, child: tile);
  }
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
    final tierColor = Color(tier.colorValue);

    return Container(
      margin: const EdgeInsets.all(12),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSpacing.lg),

          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(3, (i) => Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < tier.number ? tierColor : tierColor.withValues(alpha: 0.2),
                  ),
                )),
                const SizedBox(width: 4),
                Text(tier.label, style: AppTypography.labelSmall.copyWith(color: tierColor, fontWeight: FontWeight.w700)),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: AppSpacing.lg),

          // Arabic
          Text(
            card.arabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(fontSize: 52, color: AppColors.secondary),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .scaleXY(
                begin: 0.85,
                end: 1.0,
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: AppSpacing.sm),
          Text(card.transliteration, style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimaryLight))
              .animate()
              .fadeIn(duration: 500.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 300.ms),
          const SizedBox(height: 4),
          Text(card.english, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight))
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.dividerLight),
          const SizedBox(height: AppSpacing.md),

          // Tier 1: Meaning + lesson
          Text(card.meaning, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight, height: 1.7), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Text(card.lesson, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic, height: 1.6), textAlign: TextAlign.center),
          ),

          // Tier 2: Hadith
          if (tier.number >= 2) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.dividerLight),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(CardTier.silver.colorValue))),
                const SizedBox(width: 8),
                Text('Prophetic Teaching', style: AppTypography.labelMedium.copyWith(color: Color(CardTier.silver.colorValue))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (card.hasTier2Content)
              Text(card.hadith, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight, height: 1.7))
            else
              Text('Coming soon...', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight, fontStyle: FontStyle.italic)),
          ],

          // Tier 3: Dua
          if (tier.number >= 3) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.dividerLight),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(CardTier.gold.colorValue))),
                const SizedBox(width: 8),
                Text('Dua', style: AppTypography.labelMedium.copyWith(color: Color(CardTier.gold.colorValue))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (card.hasTier3Content) ...[
              Text(card.duaArabic, style: AppTypography.quranArabic.copyWith(color: AppColors.secondary, fontSize: 22), textDirection: TextDirection.rtl, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(card.duaTransliteration, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic)),
              const SizedBox(height: AppSpacing.xs),
              Text(card.duaTranslation, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
            ] else
              Text('Coming soon...', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight, fontStyle: FontStyle.italic)),
          ],

          // Upgrade hint
          if (tier.number < 3) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Encounter this Name again to unlock ${tier.number == 1 ? 'the Prophetic Teaching' : 'the Dua'}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
              textAlign: TextAlign.center,
            ),
          ],

          // Share button
          if (card.hasTier3Content) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  shareReflectionCard(
                    context: context,
                    nameArabic: card.arabic,
                    nameEnglish: '${card.transliteration} — ${card.english}',
                    duaArabic: card.duaArabic,
                    duaTransliteration: card.duaTransliteration,
                    duaTranslation: card.duaTranslation,
                    duaSource: '',
                    story: card.lesson,
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share this Name'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms);
  }
}
