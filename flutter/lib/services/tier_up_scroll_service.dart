import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

const String _scrollKey = 'sakina_tier_up_scrolls';
const String _hasUsedScrollKey = 'sakina_has_used_scroll';

// Scroll costs
const int scrollCostBronzeToSilver = 5;
const int scrollCostSilverToGold = 10;

Completer<void>? _spendTierUpScrollsLock;

enum TierUpScrollFailureReason {
  insufficientBalance,
  syncFailed,
}

class TierUpScrollEarnException implements Exception {
  final int amount;
  final TierUpScrollFailureReason failureReason;

  const TierUpScrollEarnException({
    required this.amount,
    required this.failureReason,
  });

  @override
  String toString() {
    return 'TierUpScrollEarnException(amount: $amount, '
        'failureReason: $failureReason)';
  }
}

class TierUpScrollState {
  final int balance;

  const TierUpScrollState({required this.balance});
}

class TierUpScrollEarnResult {
  final bool success;
  final int newBalance;
  final TierUpScrollFailureReason? failureReason;

  const TierUpScrollEarnResult({
    required this.success,
    required this.newBalance,
    this.failureReason,
  });
}

class TierUpScrollSpendResult {
  final bool success;
  final int newBalance;
  final TierUpScrollFailureReason? failureReason;

  const TierUpScrollSpendResult({
    required this.success,
    required this.newBalance,
    this.failureReason,
  });
}

Future<int> _getCachedBalance(SharedPreferences prefs) async {
  final migrated =
      await supabaseSyncService.migrateLegacyIntCache(prefs, _scrollKey);
  if (migrated == null) {
    await prefs.setInt(supabaseSyncService.scopedKey(_scrollKey), 0);
    return 0;
  }
  return migrated;
}

Future<void> _setCachedBalance(SharedPreferences prefs, int balance) async {
  await prefs.setInt(supabaseSyncService.scopedKey(_scrollKey), balance);
}

Future<void> prepareTierUpScrollCacheForHydration() async {
  final prefs = await SharedPreferences.getInstance();
  await _getCachedBalance(prefs);
}

Future<void> hydrateTierUpScrollCache({required int balance}) async {
  final prefs = await SharedPreferences.getInstance();
  await _setCachedBalance(prefs, balance);
}

/// Mark that the user has used at least one scroll.
Future<void> markScrollUsed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(supabaseSyncService.scopedKey(_hasUsedScrollKey), true);
}

/// Check whether the current user has ever used a scroll.
Future<bool> hasEverUsedScroll() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(supabaseSyncService.scopedKey(_hasUsedScrollKey)) ??
      false;
}

Future<TierUpScrollState> getTierUpScrolls() async {
  final prefs = await SharedPreferences.getInstance();
  final balance = await _getCachedBalance(prefs);
  return TierUpScrollState(balance: balance);
}

Future<TierUpScrollEarnResult> earnTierUpScrolls(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  final userId = supabaseSyncService.currentUserId;

  int newBalance;
  if (userId != null) {
    final remoteBalance = await supabaseSyncService.callRpc<int>(
      'earn_scrolls',
      {'amount': amount},
    );
    if (remoteBalance == null) {
      return TierUpScrollEarnResult(
        success: false,
        newBalance: current,
        failureReason: TierUpScrollFailureReason.syncFailed,
      );
    }
    newBalance = remoteBalance;
  } else {
    newBalance = current + amount;
  }

  await _setCachedBalance(prefs, newBalance);
  return TierUpScrollEarnResult(success: true, newBalance: newBalance);
}

Future<int> earnTierUpScrollsOrThrow(int amount) async {
  final result = await earnTierUpScrolls(amount);
  if (!result.success) {
    throw TierUpScrollEarnException(
      amount: amount,
      failureReason:
          result.failureReason ?? TierUpScrollFailureReason.syncFailed,
    );
  }
  return result.newBalance;
}

Future<TierUpScrollSpendResult> spendTierUpScrolls(int amount) async {
  while (_spendTierUpScrollsLock != null) {
    await _spendTierUpScrollsLock!.future;
  }

  final lock = Completer<void>();
  _spendTierUpScrollsLock = lock;

  try {
    final prefs = await SharedPreferences.getInstance();
    final current = await _getCachedBalance(prefs);
    if (current < amount) {
      return TierUpScrollSpendResult(
        success: false,
        newBalance: current,
        failureReason: TierUpScrollFailureReason.insufficientBalance,
      );
    }

    final userId = supabaseSyncService.currentUserId;
    int newBalance;
    if (userId != null) {
      final remoteBalance = await supabaseSyncService.callRpc<int>(
        'spend_scrolls',
        {'amount': amount},
      );
      if (remoteBalance == null) {
        return TierUpScrollSpendResult(
          success: false,
          newBalance: current,
          failureReason: TierUpScrollFailureReason.syncFailed,
        );
      }
      newBalance = remoteBalance;
    } else {
      newBalance = current - amount;
    }

    await _setCachedBalance(prefs, newBalance);
    await markScrollUsed();
    return TierUpScrollSpendResult(success: true, newBalance: newBalance);
  } finally {
    _spendTierUpScrollsLock = null;
    lock.complete();
  }
}

/// Test seam: clears the module-level `_spendTierUpScrollsLock` so each
/// test case starts from a known state. The `finally` block in
/// [spendTierUpScrolls] already releases the lock on the success and
/// `insufficientBalance` paths, but a thrown `SharedPreferences` or RPC
/// call in production would surface as an unhandled exception that propagates
/// past `finally` only if the throw happens *before* line 154 (`_spendTier
/// UpScrollsLock = lock`). Tests that fake-throw mid-spend rely on this hook
/// to keep cases isolated.
@visibleForTesting
void debugResetTierUpScrollLock() {
  _spendTierUpScrollsLock = null;
}

Future<bool> hasTierUpScrolls() async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getCachedBalance(prefs);
  return current >= 1;
}
