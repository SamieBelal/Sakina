import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';

// ---------------------------------------------------------------------------
// Cosmetics Service (Lane B)
//
// Server-authoritative Lantern Cosmetics economy client. NEVER writes economy
// tables directly — all client mutation flows through the Lane A SECURITY
// DEFINER RPCs (award_noor / unlock_cosmetic / equip_cosmetic). Skin IAP
// ownership is granted by the RevenueCat WEBHOOK server-side (service_role-only
// grant_cosmetic_iap, revoked from authenticated; 2026-07-25 contract change),
// NOT by this client — the client purchases via RC then re-syncs (see Task 7).
// State is read from the additive noor / equipped / cosmetics sections of
// sync_all_user_data() and mirrored into user-scoped SharedPreferences so the
// wardrobe renders synchronously (mirrors TokenState / premium_grants_service).
//
// No Riverpod imports (pinned indirectly by the leaf-import discipline).
// ---------------------------------------------------------------------------

/// Analytics seam. Top-level cosmetics functions have no Riverpod access, so
/// they emit through this static hook (same pattern as
/// `GatingService.onAnalyticsEvent` / `StreakAnalytics.onAnalyticsEvent`).
/// Wired once in `main.dart`; null in tests and until wired, so emitting is a
/// safe no-op.
class CosmeticsAnalytics {
  CosmeticsAnalytics._();

  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  static void emit(String event, Map<String, dynamic> props) {
    try {
      onAnalyticsEvent?.call(event, props);
    } catch (_) {
      // Telemetry must never break an economy write.
    }
  }
}

/// Read-only view of the user's cosmetics economy state. Hand-written (like
/// TokenState / StreakState) — no Freezed, since it is a tiny read model with
/// no JSON round-trip of its own.
@immutable
class CosmeticsState {
  const CosmeticsState({
    required this.noorBalance,
    required this.equippedLanternSkin,
    required this.equippedBackdrop,
    required this.ownedLanternSkins,
    required this.ownedBackdrops,
  });

  final int noorBalance;
  final String equippedLanternSkin;
  final String equippedBackdrop;
  final Set<String> ownedLanternSkins;
  final Set<String> ownedBackdrops;

  bool owns(String itemType, String itemId) {
    switch (itemType) {
      case itemTypeLanternSkin:
        return itemId == defaultLanternSkin ||
            ownedLanternSkins.contains(itemId);
      case itemTypeBackdrop:
        return itemId == defaultBackdrop || ownedBackdrops.contains(itemId);
      default:
        return false;
    }
  }
}

// item_type values — mirror the cosmetic_catalog CHECK constraint.
const String itemTypeLanternSkin = 'lantern_skin';
const String itemTypeBackdrop = 'backdrop';

// The always-owned defaults (backfilled server-side; never in user_cosmetics).
const String defaultLanternSkin = 'classic_gold';
const String defaultBackdrop = 'default';

// User-scoped SharedPreferences base keys.
const String _noorBalanceKey = 'sakina_noor_balance';
const String _equippedSkinKey = 'sakina_equipped_lantern_skin';
const String _equippedBackdropKey = 'sakina_equipped_backdrop';
const String _ownedSkinsKey = 'sakina_owned_lantern_skins';
const String _ownedBackdropsKey = 'sakina_owned_backdrops';

Future<Set<String>> _readOwnedSet(
  SharedPreferences prefs,
  String baseKey,
) async {
  final raw = prefs.getString(supabaseSyncService.scopedKey(baseKey));
  if (raw == null || raw.isEmpty) return <String>{};
  try {
    return (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
  } catch (_) {
    return <String>{};
  }
}

/// Reads the cached cosmetics state. Server is the source of truth; this cache
/// is refreshed on every `sync_all_user_data` via [hydrateCosmeticsFromSync].
Future<CosmeticsState> getCosmeticsState() async {
  final prefs = await SharedPreferences.getInstance();
  return CosmeticsState(
    noorBalance:
        prefs.getInt(supabaseSyncService.scopedKey(_noorBalanceKey)) ?? 0,
    equippedLanternSkin:
        prefs.getString(supabaseSyncService.scopedKey(_equippedSkinKey)) ??
            defaultLanternSkin,
    equippedBackdrop:
        prefs.getString(supabaseSyncService.scopedKey(_equippedBackdropKey)) ??
            defaultBackdrop,
    ownedLanternSkins: await _readOwnedSet(prefs, _ownedSkinsKey),
    ownedBackdrops: await _readOwnedSet(prefs, _ownedBackdropsKey),
  );
}

/// Mirrors the three additive sync sections into the local caches. Called by
/// `user_data_batch_sync_service` on every app-launch / re-sync. Owned rows
/// arrive as the `cosmetics` section's `[{item_type, item_id, acquired_via}]`.
Future<void> hydrateCosmeticsFromSync({
  required int noorBalance,
  required String equippedLanternSkin,
  required String equippedBackdrop,
  required List<Map<String, dynamic>> owned,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
      supabaseSyncService.scopedKey(_noorBalanceKey), noorBalance);
  await prefs.setString(
      supabaseSyncService.scopedKey(_equippedSkinKey), equippedLanternSkin);
  await prefs.setString(
      supabaseSyncService.scopedKey(_equippedBackdropKey), equippedBackdrop);

  final skins = <String>[];
  final backdrops = <String>[];
  for (final row in owned) {
    final type = row['item_type'];
    final id = row['item_id'];
    if (id is! String) continue;
    if (type == itemTypeLanternSkin) {
      skins.add(id);
    } else if (type == itemTypeBackdrop) {
      backdrops.add(id);
    }
  }
  await prefs.setString(
      supabaseSyncService.scopedKey(_ownedSkinsKey), jsonEncode(skins));
  await prefs.setString(
      supabaseSyncService.scopedKey(_ownedBackdropsKey), jsonEncode(backdrops));
}

/// Outcome of an unlock / equip / grant action. [success] drives whether the
/// caller shows a confirmation or an error snackbar (spec §UI). The service
/// itself surfaces nothing — it returns this so the widget layer owns the
/// snackbar (services never show UI).
@immutable
class CosmeticActionResult {
  const CosmeticActionResult({required this.success});
  final bool success;

  static const CosmeticActionResult ok = CosmeticActionResult(success: true);
  static const CosmeticActionResult failed =
      CosmeticActionResult(success: false);
}

/// Spends Noor to unlock [itemId]. Delegates ALL price/availability/gating to
/// the Lane A `unlock_cosmetic` RPC (server never trusts the client price —
/// [noorPrice] is used ONLY to optimistically mirror the debit into the cache
/// on success; the next sync reconciles the authoritative balance). Returns
/// [CosmeticActionResult.failed] when the RPC raises (insufficient noor,
/// inactive, premium-exclusive, out-of-window) — `callRpc` maps the raise to
/// null.
Future<CosmeticActionResult> unlockCosmetic({
  required String itemType,
  required String itemId,
  required int noorPrice,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }

  final ok = await supabaseSyncService.callRpc<bool>(
    'unlock_cosmetic',
    {'p_item_type': itemType, 'p_item_id': itemId},
  );

  if (ok != true) {
    CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticUnlockRejected, {
      AnalyticsEvents.propItemType: itemType,
      AnalyticsEvents.propItemId: itemId,
      AnalyticsEvents.propReason: 'rpc_declined',
    });
    return CosmeticActionResult.failed;
  }

  await _addOwnedToCache(itemType, itemId);
  await _debitNoorCache(noorPrice);

  CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticUnlocked, {
    AnalyticsEvents.propItemType: itemType,
    AnalyticsEvents.propItemId: itemId,
    AnalyticsEvents.propVia: AnalyticsEvents.cosmeticViaNoor,
  });
  return CosmeticActionResult.ok;
}

Future<void> _addOwnedToCache(String itemType, String itemId) async {
  final prefs = await SharedPreferences.getInstance();
  final baseKey =
      itemType == itemTypeBackdrop ? _ownedBackdropsKey : _ownedSkinsKey;
  final set = await _readOwnedSet(prefs, baseKey);
  set.add(itemId);
  await prefs.setString(
      supabaseSyncService.scopedKey(baseKey), jsonEncode(set.toList()));
}

Future<void> _debitNoorCache(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final key = supabaseSyncService.scopedKey(_noorBalanceKey);
  final current = prefs.getInt(key) ?? 0;
  await prefs.setInt(key, (current - amount).clamp(0, 1 << 31));
}

/// The streak-milestone days that `award_noor` recognizes (the RPC's `case`
/// arms are `milestone:7|14|30|60|100`). Client-side allowlist so an
/// unrecognized day never reaches the RPC (which would `raise 'unknown noor
/// reason'`). Kept in lockstep with the RPC body in
/// `20260726000000_cosmetics_economy.sql`.
const Set<int> awardableMilestoneDays = {7, 14, 30, 60, 100};

/// Awards milestone Noor for reaching [day], but ONLY after a successful,
/// newly-recorded `claim_streak_milestone(day)`. This ordering is spec §13
/// item 13: `award_noor` is idempotent but does NOT verify the milestone was
/// reached — that authority is `claim_streak_milestone`. We therefore claim
/// first and award only when the claim reports `newly_claimed=true`.
///
/// DEP-3: correctness assumes Lane A fixed the exploitable `claim_streak_
/// milestone` (§13 item 3) so a `newly_claimed=true` genuinely means the day
/// was recognized AND reached. Lane B depends on that fix; it does not build it.
///
/// The reason + reason_key are BOTH the server-shaped `'milestone:<day>'` so
/// the `noor_grants` ledger dedupes per (user, day) forever — a streak rebuild
/// can never re-mint the same milestone's Noor (kills the farming exploit).
///
/// Returns the Noor amount minted (server-derived), or 0 when the claim was
/// not newly recorded, the day is unrecognized, the user is unauthenticated,
/// or the grant was an idempotent replay (award_noor returns 0).
Future<int> awardMilestoneNoor(int day) async {
  if (supabaseSyncService.currentUserId == null) return 0;
  if (!awardableMilestoneDays.contains(day)) return 0;

  // 1. Claim FIRST — the server decides whether the milestone is genuinely
  //    new + reached. Only proceed to award on a fresh claim.
  final claim = await supabaseSyncService.callRpc<Map<String, dynamic>>(
    'claim_streak_milestone',
    {'p_day': day},
  );
  final newlyClaimed = claim?['newly_claimed'] == true;
  if (!newlyClaimed) return 0;

  // 2. THEN award, with the server-shaped reason_key so the ledger dedupes.
  final reasonKey = 'milestone:$day';
  final amount = await supabaseSyncService.callRpc<int>(
    'award_noor',
    {'p_reason': reasonKey, 'p_reason_key': reasonKey},
  );
  if (amount == null || amount <= 0) return 0; // deduped replay or failure

  // Mirror the mint into the cache so the wardrobe balance updates without a
  // round-trip; the next full sync reconciles the authoritative value.
  await _creditNoorCache(amount);

  CosmeticsAnalytics.emit(AnalyticsEvents.noorEarned, {
    AnalyticsEvents.propAmount: amount,
    AnalyticsEvents.propReason: reasonKey,
  });
  return amount;
}

/// The coarse `reason` values `award_noor` recognizes for NON-milestone grants
/// (its `case` arms). Milestone grants go through [awardMilestoneNoor], which
/// enforces the claim-first ordering, so `'milestone:*'` is intentionally NOT
/// accepted here.
const Set<String> awardableNoorReasons = {'daily', 'quest'};

/// Awards Noor for a non-milestone earned event (daily muḥāsabah completion,
/// quest completion — spec §3). The [reason] is the coarse value the RPC maps
/// to an amount (server-derived); the [reasonKey] is the per-occurrence dedup
/// key (e.g. `daily:2026-07-25`, `quest:<id>:<period>`) so re-running the loop
/// the same day cannot double-mint.
///
/// Returns the amount minted, or 0 on a deduped replay / unrecognized reason /
/// unauthenticated caller.
Future<int> awardNoor({
  required String reason,
  required String reasonKey,
}) async {
  if (supabaseSyncService.currentUserId == null) return 0;
  if (!awardableNoorReasons.contains(reason)) return 0;

  final amount = await supabaseSyncService.callRpc<int>(
    'award_noor',
    {'p_reason': reason, 'p_reason_key': reasonKey},
  );
  if (amount == null || amount <= 0) return 0;

  await _creditNoorCache(amount);
  CosmeticsAnalytics.emit(AnalyticsEvents.noorEarned, {
    AnalyticsEvents.propAmount: amount,
    AnalyticsEvents.propReason: reason,
  });
  return amount;
}

Future<void> _creditNoorCache(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final key = supabaseSyncService.scopedKey(_noorBalanceKey);
  final current = prefs.getInt(key) ?? 0;
  await prefs.setInt(key, current + amount);
}

/// Equips [itemId] via the Lane A `equip_cosmetic` RPC, which verifies
/// ownership server-side (raises "cannot equip unowned item" → null here).
/// On success, mirrors the equipped column into the cache so the Companion
/// stage / Home medallion re-render without a round-trip.
Future<CosmeticActionResult> equipCosmetic({
  required String itemType,
  required String itemId,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }

  final ok = await supabaseSyncService.callRpc<bool>(
    'equip_cosmetic',
    {'p_item_type': itemType, 'p_item_id': itemId},
  );
  if (ok != true) return CosmeticActionResult.failed;

  final prefs = await SharedPreferences.getInstance();
  final key =
      itemType == itemTypeBackdrop ? _equippedBackdropKey : _equippedSkinKey;
  await prefs.setString(supabaseSyncService.scopedKey(key), itemId);

  CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticEquipped, {
    AnalyticsEvents.propItemType: itemType,
    AnalyticsEvents.propItemId: itemId,
  });
  return CosmeticActionResult.ok;
}

/// Client-side predicate for whether the Equip button should be shown for a
/// catalog row (spec §13 item 6 / OQ-1 — the single premium definition seam).
///
/// Rules (conservative — the spec is silent on whether trial/gift/referral
/// users PERMANENTLY keep premium-exclusive skins, so we never convert them to
/// ownership here; see OQ-1):
///   • Owned (in user_cosmetics or the always-owned default) → equippable.
///   • Premium-exclusive AND the caller is premium (any source: sub, trial,
///     gift, referral — [PurchaseService.isPremium] ORs over all) → equippable
///     WHILE premium is active. The server `equip_cosmetic` remains the final
///     authority; this only decides whether to surface the button.
///   • Otherwise → NOT equippable (the user must unlock/buy it first).
///
/// [purchaseService] is injectable for tests; production passes the default
/// `PurchaseService()`.
Future<bool> canEquip({
  required CosmeticsState state,
  required String itemType,
  required String itemId,
  required bool isPremiumExclusive,
  PurchaseService? purchaseService,
}) async {
  if (state.owns(itemType, itemId)) return true;
  if (isPremiumExclusive) {
    final svc = purchaseService ?? PurchaseService();
    return svc.isPremium();
  }
  return false;
}

/// À-la-carte skin IAP SKUs → catalog item_id. Mirrors the `iap_product_id`
/// column in `20260726000100_seed_cosmetic_catalog.sql`. The client uses this
/// ONLY to recognize which RC products are skin purchases and to LABEL the
/// analytics event with the item_id; it performs NO grant with it. The SERVER
/// (RC webhook, service_role) re-verifies product↔item against the catalog and
/// is the sole granter. When SKUs change, this map AND the seed migration must
/// both update.
const Map<String, String> skinIapProductToItem = {
  'sakina.skin.obsidian': 'obsidian_gold',
  'sakina.skin.masjid': 'masjid_brass',
  'sakina.skin.crystal': 'crystal_star',
};

/// Completes an à-la-carte skin purchase from the CLIENT side (spec §13 item 4;
/// 2026-07-25 security-driven contract change). The caller has already run the
/// RevenueCat purchase (`Purchases.purchase...`) successfully; this function
/// does the post-purchase reconciliation.
///
/// The client does NOT grant ownership — `grant_cosmetic_iap` is service_role-
/// ONLY (revoked from `authenticated`) and is called by the RC WEBHOOK. Here we
/// simply re-sync via [syncNow] (default: `hydrateUserDataFromBatchRpc`, i.e.
/// `sync_all_user_data()`), so the webhook's server-side grant shows up in the
/// `cosmetics` section and the caches report the skin owned. See DEP-1/DEP-2.
///
/// Emits `cosmetic_iap_purchased` on a recognized skin SKU (client-observed RC
/// success). Idempotency / refund clawback / receipt verification are all
/// server-side. Returns failure for a non-skin SKU, an unauthenticated caller,
/// or when the sync throws.
Future<CosmeticActionResult> completeSkinIapPurchase({
  required String productId,
  Future<void> Function()? syncNow,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }
  final itemId = skinIapProductToItem[productId];
  if (itemId == null) {
    // Not a skin SKU — refuse (consumables go through ConsumableGrantsService).
    return CosmeticActionResult.failed;
  }

  // Re-sync so the webhook's server-side grant is reflected. NO grant RPC here.
  final sync = syncNow ?? hydrateUserDataFromBatchRpc;
  try {
    await sync();
  } catch (_) {
    return CosmeticActionResult.failed;
  }

  CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticIapPurchased, {
    AnalyticsEvents.propItemId: itemId,
    AnalyticsEvents.propProductId: productId,
  });
  return CosmeticActionResult.ok;
}

/// Restores previously-purchased skins (spec §13 item 4; DEP-2). Calls
/// [restore] (default: `Purchases.restorePurchases()`), which makes RevenueCat
/// re-fire its non-consumable / TRANSFER event to the WEBHOOK — the webhook
/// re-grants ownership server-side — then re-syncs via [syncNow] so the
/// restored rows surface from the `cosmetics` section.
///
/// The client grants NOTHING and does NOT reconcile from `CustomerInfo` by
/// granting (the revoked, service_role-only contract forbids it). Callers: the
/// explicit "Restore purchases" action and app-launch recovery. Returns success
/// when both the restore and the sync complete without throwing.
Future<CosmeticActionResult> restoreSkinIaps({
  Future<void> Function()? restore,
  Future<void> Function()? syncNow,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }
  final doRestore = restore ?? _defaultRestorePurchases;
  final sync = syncNow ?? hydrateUserDataFromBatchRpc;
  try {
    await doRestore(); // RC re-fires non-consumable/TRANSFER → webhook grants.
    await sync(); // Surface the server-side (re)grant from the sync payload.
  } catch (_) {
    return CosmeticActionResult.failed;
  }
  return CosmeticActionResult.ok;
}

/// Production default for [restoreSkinIaps.restore]. Thin wrapper over
/// `purchases_flutter` so the service stays trivially unit-testable (tests
/// inject a fake and never touch RevenueCat).
Future<void> _defaultRestorePurchases() async {
  await Purchases.restorePurchases();
}
