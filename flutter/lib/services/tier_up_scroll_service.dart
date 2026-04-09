import 'package:shared_preferences/shared_preferences.dart';

const String _scrollKey = 'sakina_tier_up_scrolls';

// Scroll costs
const int scrollCostBronzeToSilver = 5;
const int scrollCostSilverToGold = 10;

class TierUpScrollState {
  final int balance;

  const TierUpScrollState({required this.balance});
}

class TierUpScrollSpendResult {
  final bool success;
  final int newBalance;

  const TierUpScrollSpendResult({required this.success, required this.newBalance});
}

Future<TierUpScrollState> getTierUpScrolls() async {
  final prefs = await SharedPreferences.getInstance();
  final balance = prefs.getInt(_scrollKey) ?? 0;
  return TierUpScrollState(balance: balance);
}

Future<TierUpScrollState> earnTierUpScrolls(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_scrollKey) ?? 0;
  final newBalance = current + amount;
  await prefs.setInt(_scrollKey, newBalance);
  return TierUpScrollState(balance: newBalance);
}

Future<TierUpScrollSpendResult> spendTierUpScrolls(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_scrollKey) ?? 0;
  if (current < amount) {
    return TierUpScrollSpendResult(success: false, newBalance: current);
  }
  final newBalance = current - amount;
  await prefs.setInt(_scrollKey, newBalance);
  await prefs.setBool('sakina_has_used_scroll', true);
  return TierUpScrollSpendResult(success: true, newBalance: newBalance);
}

Future<bool> hasTierUpScrolls() async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_scrollKey) ?? 0;
  return current >= 1;
}
