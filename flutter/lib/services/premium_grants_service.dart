import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

const String _lastGrantKey = 'sakina_premium_last_grant';
Completer<({bool granted, int tokens, int scrolls})>? _grantLock;

/// Test-only override for the premium entitlement dependency.
///
/// Production code should use the default [PurchaseService] instance.
PurchaseService _purchaseService = PurchaseService();

/// Check and apply monthly premium grants.
/// Call on app startup. Idempotent — only grants once per calendar month.
Future<({bool granted, int tokens, int scrolls})>
    checkPremiumMonthlyGrant() async {
  if (_grantLock != null) {
    return _grantLock!.future;
  }

  final lock = Completer<({bool granted, int tokens, int scrolls})>();
  _grantLock = lock;

  try {
    final premium = await _purchaseService.isPremium();
    if (!premium) {
      const result = (granted: false, tokens: 0, scrolls: 0);
      lock.complete(result);
      return result;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = supabaseSyncService.currentUserId;

    // Premium grants require authentication — the server-side RPC is the only
    // trusted path. Without a userId the grant would rely on device-local
    // SharedPreferences which can be wiped by reinstalling the app.
    if (userId == null) {
      const result = (granted: false, tokens: 0, scrolls: 0);
      lock.complete(result);
      return result;
    }

    try {
      await supabaseSyncService.migrateLegacyStringCache(prefs, _lastGrantKey);
    } catch (e) {
      debugPrint('premium_grants: legacy migration failed: $e');
    }

    final rpcResult = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'grant_premium_monthly',
    );
    if (rpcResult == null) {
      const result = (granted: false, tokens: 0, scrolls: 0);
      lock.complete(result);
      return result;
    }

    await _hydratePremiumGrantResult(rpcResult);
    final result = (
      granted: rpcResult['granted'] == true,
      tokens: _intValue(rpcResult['tokens_granted']) ?? 0,
      scrolls: _intValue(rpcResult['scrolls_granted']) ?? 0,
    );
    lock.complete(result);
    return result;
  } catch (e, st) {
    lock.completeError(e, st);
    rethrow;
  } finally {
    _grantLock = null;
  }
}

Future<void> preparePremiumGrantCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  try {
    await supabaseSyncService.migrateLegacyStringCache(prefs, _lastGrantKey);
  } catch (e) {
    debugPrint('premium_grants: legacy migration failed: $e');
  }
}

Future<void> hydratePremiumGrantCache({required String? lastGrantMonth}) async {
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_lastGrantKey);
  if (lastGrantMonth == null || lastGrantMonth.isEmpty) {
    await prefs.remove(scopedKey);
    return;
  }
  await prefs.setString(scopedKey, lastGrantMonth);
}

Future<void> _hydratePremiumGrantResult(Map<String, dynamic> rpcResult) async {
  await hydratePremiumGrantCache(
    lastGrantMonth: rpcResult['grant_month'] as String?,
  );

  final newTokenBalance = _intValue(rpcResult['new_token_balance']);
  if (newTokenBalance != null) {
    await hydrateTokenCache(balance: newTokenBalance);
  }

  final newScrollBalance = _intValue(rpcResult['new_scroll_balance']);
  if (newScrollBalance != null) {
    await hydrateTierUpScrollCache(balance: newScrollBalance);
  }
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

/// Test-only setter for swapping the premium entitlement dependency.
///
/// This should not be used by production code paths.
@visibleForTesting
void debugSetPremiumGrantPurchaseService(PurchaseService service) {
  _purchaseService = service;
}

/// Restores the default test-overridable state for this module.
///
/// Intended for use from tests that modify [_purchaseService].
@visibleForTesting
void debugResetPremiumGrantService() {
  _purchaseService = PurchaseService();
  _grantLock = null;
}
