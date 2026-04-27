import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';

/// Module-level lock that serializes mutations to the credited set.
///
/// Without this, two concurrent `markCredited` calls (the listener firing
/// for two transactions in quick succession, or sync+listener racing) can
/// both read an empty list, both append their own id, and both write —
/// the second `setString` overwrites the first, losing one entry. The
/// listener then re-grants the lost transaction on its next fire.
///
/// Same pattern as `_spendTierUpScrollsLock` in `tier_up_scroll_service.dart`.
Completer<void>? _markCreditedLock;

/// Maps a RevenueCat consumable SKU to the local grant it produces.
///
/// Source-of-truth for the SKUs lives in `store_screen.dart` (the IAP
/// constants). When SKUs change, BOTH places must update.
const Map<String, _ConsumableMapping> _skuToConsumable = {
  'sakina_tokens_100': _ConsumableMapping(_ConsumableKind.tokens, 100),
  'sakina_tokens_250': _ConsumableMapping(_ConsumableKind.tokens, 250),
  'sakina_tokens_500': _ConsumableMapping(_ConsumableKind.tokens, 500),
  'sakina_scrolls_3': _ConsumableMapping(_ConsumableKind.scrolls, 3),
  'sakina_scrolls_10': _ConsumableMapping(_ConsumableKind.scrolls, 10),
  'sakina_scrolls_25': _ConsumableMapping(_ConsumableKind.scrolls, 25),
};

enum _ConsumableKind { tokens, scrolls }

class _ConsumableMapping {
  const _ConsumableMapping(this.kind, this.amount);
  final _ConsumableKind kind;
  final int amount;
}

/// Tracks which RevenueCat consumable transactions have been credited
/// locally, and reconciles orphaned transactions on app launch.
///
/// The problem this solves: if the app is killed (or backgrounds and is
/// suspended) BETWEEN `Purchases.purchasePackage` resolving and
/// `earnTokens()` running, Apple has charged the user but Sakina never
/// credits the local balance. The pending transaction sits in RevenueCat's
/// queue. On next launch, RC fires `customerInfoUpdateListener` with the
/// transaction in `nonSubscriptionTransactions`, and this service detects
/// it as un-credited and replays the grant.
///
/// Idempotency is via a SharedPreferences-backed credited set, scoped per
/// user. The `_buyTokensIAP` / `_buyScrollsIAP` synchronous path also marks
/// transaction ids before granting, so the listener doesn't double-credit
/// the same purchase.
///
/// Known limitation (filed under TODOs as the #1 server-side dedup work):
/// the credited set lives in scoped SharedPreferences and is wiped on
/// signout. Until #1 lands, [initializeForUser] establishes a high-water
/// mark on first signin so we don't re-grant the user's lifetime
/// transaction history.
class ConsumableGrantsService {
  ConsumableGrantsService();

  static const String _creditedKey = 'credited_consumable_txn_ids_v1';
  static const String _baselinedKey = 'consumable_grants_baselined_v1';
  static const int _maxCreditedEntries = 200;

  /// Atomically adds [transactionId] to the credited set. Returns `true` if
  /// it was newly added; `false` if already present.
  ///
  /// Both the synchronous purchase path and the listener race to mark via
  /// this method. Whichever wins runs the grant; the other sees `false` and
  /// skips. This is the dedup primitive for the entire service.
  ///
  /// Serialized via a module-level `Completer` lock — without it, two
  /// concurrent calls would interleave their read-modify-write on
  /// SharedPreferences and lose one of the entries (test pinned in
  /// `concurrent markCredited calls do not lose entries`).
  Future<bool> markCredited(String transactionId) async {
    while (_markCreditedLock != null) {
      await _markCreditedLock!.future;
    }
    final lock = Completer<void>();
    _markCreditedLock = lock;
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoped = supabaseSyncService.scopedKey(_creditedKey);
      final raw = prefs.getString(scoped) ?? '[]';
      final ids = (jsonDecode(raw) as List).cast<String>();
      if (ids.contains(transactionId)) return false;
      ids.add(transactionId);
      if (ids.length > _maxCreditedEntries) {
        ids.removeRange(0, ids.length - _maxCreditedEntries);
      }
      await prefs.setString(scoped, jsonEncode(ids));
      return true;
    } finally {
      _markCreditedLock = null;
      lock.complete();
    }
  }

  /// Establishes a baseline of already-granted transactions on the user's
  /// first signin to this device. Called by the app session after RC's user
  /// id is set.
  ///
  /// Without this, a fresh install (or signout+signin where SharedPrefs was
  /// cleared) would treat every transaction in the user's lifetime list as
  /// "new" and re-grant them all on the first listener fire.
  ///
  /// Once baselined, the flag persists and subsequent signins are no-ops.
  /// Trade-off: a transaction that was IN-FLIGHT when the user installed
  /// the app for the first time gets baselined-but-not-granted (~the
  /// reinstall-while-mid-purchase edge case). Acceptable until server-side
  /// dedup lands.
  Future<void> initializeForUser(CustomerInfo customerInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final flag = supabaseSyncService.scopedKey(_baselinedKey);
    if (prefs.getBool(flag) ?? false) return;

    for (final txn in customerInfo.nonSubscriptionTransactions) {
      await markCredited(txn.transactionIdentifier);
    }
    await prefs.setBool(flag, true);
    debugPrint(
      '[ConsumableGrants] Baselined '
      '${customerInfo.nonSubscriptionTransactions.length} historical '
      'transactions for first signin',
    );
  }

  /// Iterates `customerInfo.nonSubscriptionTransactions` and grants tokens
  /// or scrolls for any that are not yet in the credited set. Idempotent.
  ///
  /// **Pre-baseline gate (fixes the setUserId → listener race):** the RC
  /// `customerInfoUpdateListener` registered in `main.dart` fires when
  /// `app_session.dart` calls `setUserId(uid)`, BEFORE `initializeForUser`
  /// runs. If we granted on that fire, every transaction in the user's
  /// lifetime history would re-credit on first signin to a device. So
  /// when [debugIsBaselined] is `false`, we mark transactions as credited
  /// WITHOUT granting — equivalent to the baseline behavior. Once
  /// `initializeForUser` flips the baseline flag, subsequent listener
  /// fires (purchases, restores) hit the normal grant path.
  ///
  /// Returns the number of NEW grants performed. Errors during a single
  /// grant roll back the [markCredited] entry so the next listener fire
  /// retries — bounded by RC's own backoff. The earlier "log and don't
  /// roll back" approach left credited-but-not-granted state on transient
  /// `earn_tokens` failures, silently losing the user's purchase.
  Future<int> processCustomerInfo(CustomerInfo customerInfo) async {
    final baselined = await _isBaselined();
    var grantsCount = 0;
    for (final txn in customerInfo.nonSubscriptionTransactions) {
      final mapping = _skuToConsumable[txn.productIdentifier];
      if (mapping == null) {
        debugPrint(
          '[ConsumableGrants] Unknown SKU: ${txn.productIdentifier}',
        );
        continue;
      }

      final newlyCredited = await markCredited(txn.transactionIdentifier);
      if (!newlyCredited) continue;

      // Pre-baseline: just mark, don't grant. Avoids re-granting the
      // user's lifetime history when the listener fires on setUserId
      // before initializeForUser runs.
      if (!baselined) continue;

      try {
        switch (mapping.kind) {
          case _ConsumableKind.tokens:
            await earnTokens(mapping.amount);
            break;
          case _ConsumableKind.scrolls:
            await earnTierUpScrolls(mapping.amount);
            break;
        }
        grantsCount += 1;
        debugPrint(
          '[ConsumableGrants] Recovered grant: ${mapping.amount} '
          '${mapping.kind.name} for txn ${txn.transactionIdentifier}',
        );
      } catch (e) {
        // Roll back the credited mark so the next listener fire retries.
        // Bounded by RC's backoff. Without this rollback, a transient
        // earn_tokens failure would lose the user's purchase silently.
        await _unmarkCredited(txn.transactionIdentifier);
        debugPrint(
          '[ConsumableGrants] Grant failed for ${mapping.amount} '
          '${mapping.kind.name} (txn ${txn.transactionIdentifier}): $e. '
          'Rolled back credited mark; will retry on next listener fire.',
        );
      }
    }
    return grantsCount;
  }

  /// Convenience wrapper that fetches current customerInfo from RC and
  /// processes it. Useful for the synchronous purchase path which knows
  /// a transaction just landed but doesn't have the customerInfo handy.
  ///
  /// Implementation note: `Purchases.getCustomerInfo()` returns the cached
  /// state without a network round-trip when fresh, so this is cheap.
  Future<int> reconcileNow() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return await processCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('[ConsumableGrants] reconcileNow failed: $e');
      return 0;
    }
  }

  /// Grants the local reward for the most recent transaction matching
  /// [productId]. Used by the synchronous purchase path immediately after
  /// `Purchases.purchasePackage` returns, so the user sees the balance
  /// update without waiting for the listener to fire.
  ///
  /// Returns `true` if a grant was performed, `false` if the latest matching
  /// transaction was already credited (e.g., the listener won the race) or
  /// no matching transaction was found in customerInfo.
  ///
  /// Atomicity is preserved by [markCredited]: whichever caller (this or
  /// the listener) wins the compare-and-set wins the grant.
  Future<bool> grantForMostRecentPurchase(String productId) async {
    final CustomerInfo customerInfo;
    try {
      customerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint(
        '[ConsumableGrants] grantForMostRecentPurchase: '
        'getCustomerInfo failed for $productId: $e',
      );
      return false;
    }

    final matches = customerInfo.nonSubscriptionTransactions
        .where((t) => t.productIdentifier == productId)
        .toList();
    if (matches.isEmpty) {
      debugPrint(
        '[ConsumableGrants] grantForMostRecentPurchase: no transaction '
        'found for $productId in customerInfo',
      );
      return false;
    }
    matches.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    final latest = matches.first;

    final mapping = _skuToConsumable[productId];
    if (mapping == null) {
      debugPrint(
        '[ConsumableGrants] grantForMostRecentPurchase: unknown SKU '
        '$productId — refusing to grant',
      );
      return false;
    }

    final newlyCredited = await markCredited(latest.transactionIdentifier);
    if (!newlyCredited) {
      debugPrint(
        '[ConsumableGrants] grantForMostRecentPurchase: txn '
        '${latest.transactionIdentifier} already credited (listener won '
        'the race) — skipping',
      );
      return false;
    }

    try {
      switch (mapping.kind) {
        case _ConsumableKind.tokens:
          await earnTokens(mapping.amount);
          break;
        case _ConsumableKind.scrolls:
          await earnTierUpScrolls(mapping.amount);
          break;
      }
      return true;
    } catch (e) {
      // Roll back the credited mark so a subsequent listener fire (or
      // explicit reconcileNow call) can retry the grant. Without this,
      // a transient `earn_tokens` failure leaves the user paid-but-not-
      // credited with no recovery path.
      await _unmarkCredited(latest.transactionIdentifier);
      debugPrint(
        '[ConsumableGrants] grantForMostRecentPurchase: grant failed for '
        'txn ${latest.transactionIdentifier}: $e. Rolled back credited '
        'mark; listener will retry.',
      );
      return false;
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────

  Future<bool> _isBaselined() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(supabaseSyncService.scopedKey(_baselinedKey)) ?? false;
  }

  /// Removes [transactionId] from the credited set if present. Used to roll
  /// back a failed grant so the next listener fire retries instead of
  /// silently dropping the user's purchase. Goes through the same
  /// [_markCreditedLock] as [markCredited] so concurrent rollbacks and
  /// marks can't lose entries.
  Future<void> _unmarkCredited(String transactionId) async {
    while (_markCreditedLock != null) {
      await _markCreditedLock!.future;
    }
    final lock = Completer<void>();
    _markCreditedLock = lock;
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoped = supabaseSyncService.scopedKey(_creditedKey);
      final raw = prefs.getString(scoped) ?? '[]';
      final ids = (jsonDecode(raw) as List).cast<String>();
      if (!ids.remove(transactionId)) return;
      await prefs.setString(scoped, jsonEncode(ids));
    } finally {
      _markCreditedLock = null;
      lock.complete();
    }
  }

  // ── Test seam ────────────────────────────────────────────────────────

  @visibleForTesting
  Future<List<String>> debugGetCreditedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(supabaseSyncService.scopedKey(_creditedKey)) ??
        '[]';
    return (jsonDecode(raw) as List).cast<String>();
  }

  @visibleForTesting
  Future<bool> debugIsBaselined() => _isBaselined();
}
