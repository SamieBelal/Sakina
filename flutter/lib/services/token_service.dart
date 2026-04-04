import 'package:shared_preferences/shared_preferences.dart';

const String _tokenKey = 'sakina_tokens';
const int startingTokens = 50;

// Token costs
const int tokenCostReflection = 1;
const int tokenCostBuiltDua = 1;

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

Future<TokenState> getTokens() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(_tokenKey)) {
    // First launch — grant starting tokens
    await prefs.setInt(_tokenKey, startingTokens);
    return const TokenState(balance: startingTokens);
  }
  final balance = prefs.getInt(_tokenKey) ?? 0;
  return TokenState(balance: balance);
}

Future<TokenState> earnTokens(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_tokenKey) ?? startingTokens;
  final newBalance = current + amount;
  await prefs.setInt(_tokenKey, newBalance);
  return TokenState(balance: newBalance);
}

Future<TokenSpendResult> spendTokens(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_tokenKey) ?? startingTokens;
  if (current < amount) {
    return TokenSpendResult(success: false, newBalance: current);
  }
  final newBalance = current - amount;
  await prefs.setInt(_tokenKey, newBalance);
  return TokenSpendResult(success: true, newBalance: newBalance);
}

Future<bool> hasTokens(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_tokenKey) ?? startingTokens;
  return current >= amount;
}
