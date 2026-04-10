import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

const String _tokenKey = 'sakina_tokens';
const String _totalSpentKey = 'sakina_total_tokens_spent';
const int startingTokens = 100;

// Token costs
const int tokenCostReflection = 50;
const int tokenCostBuiltDua = 50;
const int tokenCostDiscoverName = 50;

// Token rewards
const int tokenRewardDeeperReflection = 2;
const int tokenRewardQuestComplete = 1;

class TokenState {
  final int balance;

  const TokenState({required this.balance});
}

class TokenSpendResult {
  final bool success;
  final int newBalance;

  const TokenSpendResult({required this.success, required this.newBalance});
}

Future<int> _getCachedBalance(SharedPreferences prefs) async {
  final migrated =
      await supabaseSyncService.migrateLegacyIntCache(prefs, _tokenKey);
  if (migrated == null) {
    await prefs.setInt(
        supabaseSyncService.scopedKey(_tokenKey), startingTokens);
    return startingTokens;
  }
  return migrated;
}

Future<int> _getCachedTotalSpent(SharedPreferences prefs) async {
  final migrated =
      await supabaseSyncService.migrateLegacyIntCache(prefs, _totalSpentKey);
  return migrated ?? 0;
}

Future<void> _setCachedBalance(SharedPreferences prefs, int balance) async {
  await prefs.setInt(supabaseSyncService.scopedKey(_tokenKey), balance);
}

Future<void> _setCachedTotalSpent(
  SharedPreferences prefs,
  int totalSpent,
) async {
  await prefs.setInt(supabaseSyncService.scopedKey(_totalSpentKey), totalSpent);
}

Future<TokenState> getTokens() async {
  final prefs = await SharedPreferences.getInstance();
  final balance = await _getCachedBalance(prefs);
  return TokenState(balance: balance);
}

Future<void> prepareTokenCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await _getCachedBalance(prefs);
  await _getCachedTotalSpent(prefs);
}

Future<void> hydrateTokenCache({
  required int balance,
  required int totalSpent,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await _setCachedBalance(prefs, balance);
  await _setCachedTotalSpent(prefs, totalSpent);
}

Future<TokenState> earnTokens(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  final userId = supabaseSyncService.currentUserId;

  int newBalance;
  if (userId != null) {
    final remoteBalance = await supabaseSyncService.callRpc<int>(
      'earn_tokens',
      {'amount': amount},
    );
    if (remoteBalance == null) {
      return TokenState(balance: current);
    }
    newBalance = remoteBalance;
  } else {
    newBalance = current + amount;
  }

  await _setCachedBalance(prefs, newBalance);
  return TokenState(balance: newBalance);
}

Future<TokenSpendResult> spendTokens(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  if (current < amount) {
    return TokenSpendResult(success: false, newBalance: current);
  }

  final userId = supabaseSyncService.currentUserId;
  int newBalance;
  if (userId != null) {
    // RPC returns {"balance": N, "total_spent": N} in one round trip.
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'spend_tokens',
      {'amount': amount},
    );
    if (result == null) {
      return TokenSpendResult(success: false, newBalance: current);
    }
    newBalance = result['balance'] as int;
    final serverSpent = result['total_spent'] as int;
    await _setCachedBalance(prefs, newBalance);
    await _setCachedTotalSpent(prefs, serverSpent);
  } else {
    newBalance = current - amount;
    await _setCachedBalance(prefs, newBalance);
    final localSpent = await _getCachedTotalSpent(prefs);
    await _setCachedTotalSpent(prefs, localSpent + amount);
  }
  return TokenSpendResult(success: true, newBalance: newBalance);
}

Future<bool> hasTokens(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  return current >= amount;
}

Future<int> getTotalTokensSpent() async {
  final prefs = await SharedPreferences.getInstance();
  return _getCachedTotalSpent(prefs);
}
