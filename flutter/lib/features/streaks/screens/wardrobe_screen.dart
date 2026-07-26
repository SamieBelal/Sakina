import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/features/streaks/providers/cosmetics_ui_providers.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_unlock_reveal.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_action_bar.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_grid.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_preview_stage.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/purchase_service.dart';

/// Pure resolution of the primary action for a previewed item.
///
/// [equippable] is [entryEquippable] against the screen's premium snapshot —
/// the same snapshot the grid badges use, so the two can never disagree.
/// Ordering matters:
///   • owned OR currently equippable → Equip.
///   • premium-exclusive (and not equippable) → a teaser, never a purchase.
///   • affordable with Noor → Unlock. This precedes Buy deliberately: the
///     à-la-carte skins ALSO carry a noor_price and `unlock_cosmetic` accepts
///     them, so a user who can pay in Noor is never pushed to real money.
///   • à-la-carte and not affordable in Noor → Buy, but ONLY while
///     [kSkinIapEnabled]; the IAP is not live, so today this is an inert
///     "Coming soon" teaser instead of a CTA that cannot actually charge.
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
  if (entry.isAlaCarte) {
    return kSkinIapEnabled
        ? WardrobeAction.buy
        : WardrobeAction.comingSoonTeaser;
  }
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
///
/// The equipped SLOT alone does not earn the "Equipped" badge — entitlement is
/// checked first. A lapsed subscriber keeps a premium-exclusive skin in the
/// server slot while the stage renders classic gold (see [renderableSkinId]),
/// and a badge claiming "Equipped" over a lantern that is visibly NOT equipped
/// is the same bug seen from the other side.
WardrobeTileStatus resolveWardrobeTileStatus({
  required CosmeticCatalogEntry entry,
  required CosmeticsState state,
  required bool isPremium,
}) {
  final equippedId = entry.itemType == itemTypeBackdrop
      ? state.equippedBackdrop
      : state.equippedLanternSkin;
  final owned = state.owns(entry.itemType, entry.itemId);
  final entitled = owned || (entry.isPremiumExclusive && isPremium);
  if (entry.itemId == equippedId && entitled) return WardrobeTileStatus.equipped;
  if (owned) return WardrobeTileStatus.owned;
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
  /// The initial index is sourced from [wardrobePreviewProvider] — the SAME
  /// state the body reads to pick a grid — so the TabBar's underline and the
  /// rendered axis can never disagree (I4). Created lazily on first build, by
  /// which point `ref.read` is legal.
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex:
        ref.read(wardrobePreviewProvider).tab == itemTypeBackdrop ? 1 : 0,
  )..addListener(_onTabChanged);

  /// The ONE premium snapshot this screen renders from: the grid badges
  /// ([resolveWardrobeTileStatus]), the stage ([renderableSkinId]) and the
  /// action button ([entryEquippable]) all read it, so they cannot disagree
  /// about entitlement. Refreshed on open and on every state re-read (I5) —
  /// a subscription that starts elsewhere mid-session lands on the next
  /// mutation rather than waiting for the screen to be reopened.
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

  /// Synchronous by design. The equip gate is now derived from [_isPremium]
  /// (see [entryEquippable]), so there is no per-tap future whose out-of-order
  /// completion could apply one tile's answer to the tile actually on screen.
  void _preview(CosmeticCatalogEntry entry) {
    ref
        .read(wardrobePreviewProvider.notifier)
        .preview(entry.itemType, entry.itemId);
    CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticPreviewed, {
      AnalyticsEvents.propItemType: entry.itemType,
      AnalyticsEvents.propItemId: entry.itemId,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watched HERE, not inside the loaded branch: the preview state is
    // autoDispose, and it must live exactly as long as the screen — including
    // while the cosmetics read is still loading or has errored.
    final preview = ref.watch(wardrobePreviewProvider);
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
        data: (state) => _body(state, preview),
      ),
    );
  }

  Widget _body(CosmeticsState state, WardrobePreview preview) {
    final tab = preview.tab;
    final previewedId = tab == itemTypeBackdrop
        ? preview.previewedBackdropId
        : preview.previewedSkinId;
    final previewedEntry =
        previewedId == null ? null : catalogEntryFor(tab, previewedId);

    // Shared with the Companion stage so the two can never disagree: owned, or
    // premium-exclusive while premium is active; classic gold once it lapses.
    final equippedSkinId = renderableSkinId(state, isPremium: _isPremium);

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
            onPreview: _preview,
          ),
        ),
        if (previewedEntry != null) _actionBar(previewedEntry, state),
      ],
    );
  }

  Widget _actionBar(CosmeticCatalogEntry entry, CosmeticsState state) {
    final action = resolveWardrobeAction(
      state: state,
      entry: entry,
      equippable:
          entryEquippable(entry: entry, state: state, isPremium: _isPremium),
    );
    return WardrobeActionBar(
      action: action,
      priceLabel: _priceLabel(entry, action),
      teaser: _teaser(entry, action),
      onEquip: () => _equip(entry),
      onUnlock: () => _unlock(entry, state),
      onBuy: () => _buy(entry),
    );
  }

  String _nameFor(CosmeticCatalogEntry e) => e.itemType == itemTypeBackdrop
      ? resolveBackdrop(e.itemId).name
      : resolveSkin(e.itemId).name;

  // Noor prices come from the catalog mirror. Real-money prices do NOT: they
  // must be the localized `StoreProduct.priceString` from the matched
  // RevenueCat package, so `buy` carries no label until that is wired (see
  // [_buy]). A hardcoded literal is wrong in every non-USD storefront.
  String? _priceLabel(CosmeticCatalogEntry e, WardrobeAction action) =>
      switch (action) {
        WardrobeAction.unlock ||
        WardrobeAction.unlockUnaffordable =>
          e.noorPrice == null ? null : '${e.noorPrice} Noor',
        _ => null,
      };

  String? _teaser(CosmeticCatalogEntry e, WardrobeAction action) {
    // Deliberately priceless: quoting a figure we cannot localize is exactly
    // what the à-la-carte teaser exists to avoid.
    if (action == WardrobeAction.comingSoonTeaser) return 'Coming soon';
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
    if (!res.success) {
      _afterMutation(false, 'Not enough Noor');
      return;
    }
    // E2: the earned-it moment replaces the snackbar on the success path.
    _afterMutation(true, null);
    if (mounted) await showCosmeticUnlockReveal(context, e.itemType, e.itemId);
  }

  /// Unreachable while [kSkinIapEnabled] is false — `resolveWardrobeAction`
  /// never returns [WardrobeAction.buy] — and inert on purpose if it ever is.
  /// It must NEVER report success: the only thing the client can do today is
  /// re-sync, and a re-sync is not a purchase.
  ///
  /// TODO(lane-d): to enable, wire this IN THIS ORDER, then flip
  /// `kSkinIapEnabled`:
  ///   1. `final offerings = await Purchases.getOfferings();`
  ///   2. find the `Package` whose `storeProduct.identifier == e.iapProductId`
  ///   3. `await Purchases.purchasePackage(pkg)` — the money moves HERE, and
  ///      the App Store sheet appears here or nowhere
  ///   4. only on RC success: `await completeSkinIapPurchase(productId: ...)`
  ///      to re-sync (the RC webhook is the sole granter server-side; the
  ///      client never calls a grant RPC), then report its result
  /// and label the CTA with `pkg.storeProduct.priceString` (see [_priceLabel]).
  Future<void> _buy(CosmeticCatalogEntry e) async {
    _afterMutation(false, 'Not available yet');
  }

  /// Re-reads the Lane-B-mirrored cache after a successful mutation. A null
  /// [msg] suppresses the snackbar (the unlock reveal is the feedback instead).
  void _afterMutation(bool ok, String? msg) {
    if (!mounted) return;
    if (msg != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    }
    if (!ok) return;
    ref.invalidate(cosmeticsStateProvider);
    // Re-read entitlement with the state (I5): premium can be granted anywhere
    // in the app, and a snapshot frozen at initState would leave the badges
    // describing an entitlement the user no longer (or now does) hold.
    _resolvePremium();
  }
}
