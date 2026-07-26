import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_action_bar.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_grid.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_preview_stage.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';

/// Pure resolution of the primary action for a previewed item.
///
/// [equippable] is the resolved `canEquip` result (async — the screen awaits it
/// before calling this). Ordering matters:
///   • owned OR currently equippable → Equip.
///   • premium-exclusive (and not equippable) → a teaser, never a purchase.
///   • affordable with Noor → Unlock. This precedes Buy deliberately: the
///     à-la-carte skins ALSO carry a noor_price and `unlock_cosmetic` accepts
///     them, so a user who can pay in Noor is never pushed to real money.
///   • à-la-carte and not affordable in Noor → Buy.
///   • priced but unaffordable → the disabled Unlock (price stays visible).
WardrobeAction resolveWardrobeAction({
  required CosmeticsState state,
  required CosmeticCatalogEntry entry,
  required bool equippable,
}) {
  if (state.owns(entry.itemType, entry.itemId) || equippable) {
    return WardrobeAction.equip;
  }
  if (entry.isPremiumExclusive) return WardrobeAction.premiumTeaser;
  final price = entry.noorPrice;
  if (price != null && price > 0 && state.noorBalance >= price) {
    return WardrobeAction.unlock;
  }
  if (entry.isAlaCarte) return WardrobeAction.buy;
  if (price != null && price > 0) return WardrobeAction.unlockUnaffordable;
  return WardrobeAction.milestoneTeaser;
}

/// Pure resolution of one grid tile's display state.
///
/// [isPremium] is resolved ONCE per wardrobe open (never per tile — a grid of
/// async `canEquip` calls would fan out N futures). That is sound because Lane
/// B's `canEquip` is exactly `owned || (isPremiumExclusive && isPremium)`.
///
/// A premium-exclusive item held by an active subscriber is `equippable`, NOT
/// `owned`: the perk lasts while premium is active and never converts to
/// permanent ownership.
WardrobeTileStatus resolveWardrobeTileStatus({
  required CosmeticCatalogEntry entry,
  required CosmeticsState state,
  required bool isPremium,
}) {
  final equippedId = entry.itemType == itemTypeBackdrop
      ? state.equippedBackdrop
      : state.equippedLanternSkin;
  if (entry.itemId == equippedId) return WardrobeTileStatus.equipped;
  if (state.owns(entry.itemType, entry.itemId)) return WardrobeTileStatus.owned;
  if (entry.isPremiumExclusive && isPremium) {
    return WardrobeTileStatus.equippable;
  }
  if (entry.isPremiumExclusive) return WardrobeTileStatus.premiumLocked;
  if (entry.isAlaCarte) return WardrobeTileStatus.alaCarteLocked;
  return WardrobeTileStatus.locked;
}

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(_onTabChanged);

  /// `canEquip` for the CURRENT preview (async, per-preview).
  bool _equippable = false;

  /// Premium, resolved once for the whole grid (see [resolveWardrobeTileStatus]).
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _resolvePremium();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CosmeticsAnalytics.emit(AnalyticsEvents.wardrobeOpened,
          {AnalyticsEvents.propTab: itemTypeLanternSkin});
    });
  }

  Future<void> _resolvePremium() async {
    var premium = false;
    try {
      premium = await PurchaseService().isPremium();
    } catch (_) {
      // Unresolvable premium reads as NOT premium — the conservative default
      // (the server `equip_cosmetic` remains the final authority anyway).
    }
    if (mounted) setState(() => _isPremium = premium);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    final tab = _tabs.index == 0 ? itemTypeLanternSkin : itemTypeBackdrop;
    ref.read(wardrobePreviewProvider.notifier).setTab(tab);
    CosmeticsAnalytics.emit(
        AnalyticsEvents.wardrobeOpened, {AnalyticsEvents.propTab: tab});
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _preview(CosmeticCatalogEntry entry, CosmeticsState state) async {
    ref
        .read(wardrobePreviewProvider.notifier)
        .preview(entry.itemType, entry.itemId);
    CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticPreviewed, {
      AnalyticsEvents.propItemType: entry.itemType,
      AnalyticsEvents.propItemId: entry.itemId,
    });
    final can = await canEquip(
      state: state,
      itemType: entry.itemType,
      itemId: entry.itemId,
      isPremiumExclusive: entry.isPremiumExclusive,
    );
    if (mounted) setState(() => _equippable = can);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(cosmeticsStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Lanterns'), Tab(text: 'Backdrops')],
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Could not load the wardrobe')),
        data: _body,
      ),
    );
  }

  Widget _body(CosmeticsState state) {
    final preview = ref.watch(wardrobePreviewProvider);
    final tab = preview.tab;
    final previewedId = tab == itemTypeBackdrop
        ? preview.previewedBackdropId
        : preview.previewedSkinId;
    final previewedEntry =
        previewedId == null ? null : catalogEntryFor(tab, previewedId);

    // DEP-D2: an equipped-but-unowned (lapsed premium) skin renders as classic.
    final equippedSkinId =
        state.owns(itemTypeLanternSkin, state.equippedLanternSkin)
            ? state.equippedLanternSkin
            : defaultLanternSkin;

    return Column(
      children: [
        WardrobePreviewStage(
          skinId: preview.previewedSkinId ?? equippedSkinId,
          backdropId: preview.previewedBackdropId ?? state.equippedBackdrop,
        ),
        Expanded(
          child: WardrobeGrid(
            entries: displayCatalog(tab),
            nameFor: _nameFor,
            statusFor: (e) => resolveWardrobeTileStatus(
                entry: e, state: state, isPremium: _isPremium),
            previewedId: previewedId,
            onPreview: (e) => _preview(e, state),
          ),
        ),
        if (previewedEntry != null) _actionBar(previewedEntry, state),
      ],
    );
  }

  Widget _actionBar(CosmeticCatalogEntry entry, CosmeticsState state) {
    final action = resolveWardrobeAction(
        state: state, entry: entry, equippable: _equippable);
    return WardrobeActionBar(
      action: action,
      priceLabel: _priceLabel(entry, action),
      teaser: _teaser(entry),
      onEquip: () => _equip(entry),
      onUnlock: () => _unlock(entry, state),
      onBuy: () => _buy(entry),
    );
  }

  String _nameFor(CosmeticCatalogEntry e) => e.itemType == itemTypeBackdrop
      ? resolveBackdrop(e.itemId).name
      : resolveSkin(e.itemId).name;

  String? _priceLabel(CosmeticCatalogEntry e, WardrobeAction action) =>
      switch (action) {
        WardrobeAction.unlock ||
        WardrobeAction.unlockUnaffordable =>
          e.noorPrice == null ? null : '${e.noorPrice} Noor',
        // TODO(lane-d): read the real RC StoreProduct.priceString.
        WardrobeAction.buy => r'$2.99',
        _ => null,
      };

  String? _teaser(CosmeticCatalogEntry e) {
    if (e.isPremiumExclusive) return 'Premium · this month';
    if (e.milestoneDay != null) return 'Unlock at a ${e.milestoneDay}-day streak';
    return null;
  }

  Future<void> _equip(CosmeticCatalogEntry e) async {
    final res = await equipCosmetic(itemType: e.itemType, itemId: e.itemId);
    _afterMutation(res.success, res.success ? 'Equipped' : "Couldn't equip");
  }

  Future<void> _unlock(CosmeticCatalogEntry e, CosmeticsState state) async {
    // Runtime double-debit guard: an owned item can never be re-unlocked, even
    // if a stale action bar somehow offered it.
    if (state.owns(e.itemType, e.itemId)) return;
    final res = await unlockCosmetic(
        itemType: e.itemType, itemId: e.itemId, noorPrice: e.noorPrice ?? 0);
    _afterMutation(res.success, res.success ? 'Unlocked' : 'Not enough Noor');
  }

  Future<void> _buy(CosmeticCatalogEntry e) async {
    // TODO(lane-d): run the real RevenueCat purchase (getOfferings() → package)
    // BEFORE this call. completeSkinIapPurchase only RE-SYNCS — the RC webhook
    // is the sole granter server-side; the client never calls a grant RPC.
    final res = await completeSkinIapPurchase(productId: e.iapProductId!);
    _afterMutation(
        res.success, res.success ? 'Purchased' : "Purchase didn't complete");
  }

  void _afterMutation(bool ok, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
    if (ok) ref.invalidate(cosmeticsStateProvider);
  }
}
