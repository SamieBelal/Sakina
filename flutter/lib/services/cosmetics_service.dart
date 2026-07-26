import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/supabase_sync_service.dart';

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
