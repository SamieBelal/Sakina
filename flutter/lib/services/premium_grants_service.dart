import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

// Monthly grant amounts for premium users
const int premiumMonthlyTokens = 50;
const int premiumMonthlyScrolls = 15;

const String _lastGrantKey = 'sakina_premium_last_grant';

PurchaseService _purchaseService = PurchaseService();

/// Check and apply monthly premium grants.
/// Call on app startup. Idempotent — only grants once per calendar month.
Future<({bool granted, int tokens, int scrolls})>
    checkPremiumMonthlyGrant() async {
  final premium = await _purchaseService.isPremium();
  if (!premium) return (granted: false, tokens: 0, scrolls: 0);

  final prefs = await SharedPreferences.getInstance();
  final userId = supabaseSyncService.currentUserId;

  // Premium grants require authentication — the server-side RPC is the only
  // trusted path. Without a userId the grant would rely on device-local
  // SharedPreferences which can be wiped by reinstalling the app.
  if (userId == null) return (granted: false, tokens: 0, scrolls: 0);

  await supabaseSyncService.migrateLegacyStringCache(prefs, _lastGrantKey);

  final rpcResult = await supabaseSyncService.callRpc<Map<String, dynamic>>(
    'grant_premium_monthly',
  );
  if (rpcResult == null) {
    return (granted: false, tokens: 0, scrolls: 0);
  }

  await _hydratePremiumGrantResult(rpcResult);
  return (
    granted: rpcResult['granted'] == true,
    tokens: rpcResult['granted'] == true ? premiumMonthlyTokens : 0,
    scrolls: rpcResult['granted'] == true ? premiumMonthlyScrolls : 0,
  );
}

Future<void> preparePremiumGrantCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await supabaseSyncService.migrateLegacyStringCache(prefs, _lastGrantKey);
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
    await hydrateTokenCache(
      balance: newTokenBalance,
      totalSpent: await getTotalTokensSpent(),
    );
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

@visibleForTesting
void debugSetPremiumGrantPurchaseService(PurchaseService service) {
  _purchaseService = service;
}

@visibleForTesting
void debugResetPremiumGrantService() {
  _purchaseService = PurchaseService();
}
