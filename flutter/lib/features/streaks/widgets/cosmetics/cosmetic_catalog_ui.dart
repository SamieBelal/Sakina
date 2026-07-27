// UI-side mirror of the cosmetic_catalog seed (20260726000100). The SERVER is
// the price/availability authority (unlock_cosmetic reads its own table); this
// carries the DISPLAY metadata the wardrobe needs (price/gating/product-id) and
// the id -> LanternSkin/Backdrop resolvers Lane C's value models don't ship.
// When the seed migration changes, this table changes with it (same discipline
// as skinIapProductToItem in cosmetics_service.dart).
//
// PURE: no Supabase, no Riverpod, no I/O — trivially unit-testable.

import 'package:flutter/foundation.dart';

import 'package:sakina/features/streaks/models/backdrop.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/services/cosmetics_service.dart';

/// Whether the à-la-carte skin IAP is live. THE single source of truth for it.
///
/// While false the wardrobe must not offer a Buy CTA for an à-la-carte skin:
/// the SKUs (`sakina.skin.obsidian` / `.masjid` / `.crystal`) do not exist in
/// App Store Connect yet, and the client-side RevenueCat purchase call is not
/// written. `completeSkinIapPurchase` only RE-SYNCS — the RC webhook is the
/// sole server-side granter — so a "Buy" button wired straight to it moves no
/// money, grants nothing, and would still report success.
///
/// Flip to true ONLY when BOTH hold:
///   1. the three SKUs are live in App Store Connect / RevenueCat, AND
///   2. `_buy` in `wardrobe_screen.dart` actually runs the purchase
///      (`getOfferings()` → matching package → `purchasePackage`) BEFORE
///      `completeSkinIapPurchase`, and the button's price comes from
///      `StoreProduct.priceString` rather than a hardcoded literal.
/// Until then à-la-carte skins are reachable with Noor and read "Coming soon".
const bool kSkinIapEnabled = false;

/// One catalog row's display + gating metadata.
@immutable
class CosmeticCatalogEntry {
  const CosmeticCatalogEntry({
    required this.itemType,
    required this.itemId,
    required this.sort,
    this.noorPrice,
    this.iapProductId,
    this.isPremiumExclusive = false,
    this.isSeasonal = false,
    this.seasonKey,
    this.milestoneDay,
  });

  final String itemType;
  final String itemId;
  final int sort;
  final int? noorPrice;
  final String? iapProductId;
  final bool isPremiumExclusive;
  final bool isSeasonal;
  final String? seasonKey;
  final int? milestoneDay;

  /// À-la-carte real-money skins (obsidian/masjid/crystal in the seed).
  bool get isAlaCarte => iapProductId != null;
}

// Mirrors 20260726000100_seed_cosmetic_catalog.sql exactly.
const List<CosmeticCatalogEntry> _catalog = [
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'classic_gold',
      noorPrice: 0,
      sort: 0),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'moonlit_silver',
      noorPrice: 120,
      sort: 1),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'emerald_jade',
      noorPrice: 120,
      milestoneDay: 7,
      sort: 2),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'rose_quartz',
      noorPrice: 120,
      sort: 3),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'obsidian_gold',
      noorPrice: 200,
      milestoneDay: 30,
      iapProductId: 'sakina.skin.obsidian',
      sort: 4),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'masjid_brass',
      noorPrice: 300,
      iapProductId: 'sakina.skin.masjid',
      sort: 5),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'crystal_star',
      noorPrice: 300,
      iapProductId: 'sakina.skin.crystal',
      sort: 6),
  CosmeticCatalogEntry(
      itemType: itemTypeLanternSkin,
      itemId: 'ramadan_royal',
      isPremiumExclusive: true,
      isSeasonal: true,
      seasonKey: 'ramadan',
      sort: 7),
  CosmeticCatalogEntry(
      itemType: itemTypeBackdrop, itemId: 'default', noorPrice: 0, sort: 0),
  CosmeticCatalogEntry(
      itemType: itemTypeBackdrop,
      itemId: 'laylat_night',
      noorPrice: 150,
      milestoneDay: 14,
      sort: 1),
  CosmeticCatalogEntry(
      itemType: itemTypeBackdrop,
      itemId: 'emerald_sanctuary',
      noorPrice: 150,
      sort: 2),
  CosmeticCatalogEntry(
      itemType: itemTypeBackdrop,
      itemId: 'desert_night',
      noorPrice: 150,
      sort: 3),
  CosmeticCatalogEntry(
      itemType: itemTypeBackdrop,
      itemId: 'fajr_courtyard',
      noorPrice: 200,
      milestoneDay: 30,
      sort: 4),
];

/// The catalog row for [itemType]/[itemId], or null if unknown.
CosmeticCatalogEntry? catalogEntryFor(String itemType, String itemId) {
  for (final e in _catalog) {
    if (e.itemType == itemType && e.itemId == itemId) return e;
  }
  return null;
}

/// All rows for one axis, in sort order.
List<CosmeticCatalogEntry> displayCatalog(String itemType) {
  final rows = _catalog.where((e) => e.itemType == itemType).toList()
    ..sort((a, b) => a.sort.compareTo(b.sort));
  return rows;
}

// id -> visual value object. Lane C's LanternSkin.all/.sculpted + Backdrop.all
// omit the defaults from `all`, so we build a full lookup including the defaults.
final Map<String, LanternSkin> _skinsById = {
  for (final s in [...LanternSkin.all, ...LanternSkin.sculpted]) s.id: s,
};

/// Resolve a skin id to its [LanternSkin]; unknown ids fall back to classicGold
/// (mirrors CosmeticsState.owns treating classic_gold as the always-owned base).
LanternSkin resolveSkin(String id) => _skinsById[id] ?? LanternSkin.classicGold;

/// The lantern skin id that should actually be RENDERED for the equipped slot.
///
/// The gate is `owned || (premium-exclusive && premium)` — the same rule as
/// `CosmeticsService.canEquip`, minus the async premium read (each screen
/// resolves premium ONCE and passes the snapshot in). Both the Companion stage
/// and the Wardrobe preview stage go through here so they cannot drift apart.
///
/// Gating on ownership ALONE would be wrong: a premium-exclusive skin is never
/// written to the owned cache (the perk lasts while the subscription does and
/// never converts to permanent ownership), so the lapse fallback would fire for
/// ACTIVE subscribers too and render their equipped skin as classic gold.
///
/// DEP-D2 is preserved: without premium, an equipped premium-exclusive skin
/// still falls back to the always-owned [defaultLanternSkin]. The server slot is
/// left untouched — that is a sync concern.
String renderableSkinId(CosmeticsState state, {required bool isPremium}) {
  final id = state.equippedLanternSkin;
  if (state.owns(itemTypeLanternSkin, id)) return id;
  final entry = catalogEntryFor(itemTypeLanternSkin, id);
  if (entry != null && entry.isPremiumExclusive && isPremium) return id;
  return defaultLanternSkin;
}

/// Whether [entry] can be equipped RIGHT NOW, resolved against the premium
/// snapshot the caller already holds.
///
/// Same rule as `CosmeticsService.canEquip` — `owned || (premium-exclusive &&
/// premium)` — minus its own async premium read. Sharing ONE snapshot with
/// [resolveWardrobeTileStatus] and [renderableSkinId] is the point (I5): the
/// per-tap async gate resolved premium independently of the badges, so a
/// mid-session entitlement change left badge and action button disagreeing —
/// and because its answer landed in a single shared field, two taps whose
/// futures completed out of order applied one tile's answer to another.
///
/// A premium-exclusive item stays equippable-but-NOT-owned: the perk lasts
/// while premium is active and never converts to permanent ownership.
bool entryEquippable({
  required CosmeticCatalogEntry entry,
  required CosmeticsState state,
  required bool isPremium,
}) =>
    state.owns(entry.itemType, entry.itemId) ||
    (entry.isPremiumExclusive && isPremium);

/// Resolve a backdrop id to its [Backdrop]; 'default'/unknown → Backdrop.none.
Backdrop resolveBackdrop(String id) {
  if (id == defaultBackdrop) return Backdrop.none;
  for (final b in Backdrop.all) {
    if (b.id == id) return b;
  }
  return Backdrop.none;
}
