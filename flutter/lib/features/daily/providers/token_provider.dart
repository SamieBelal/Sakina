import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/token_service.dart';

class TokenNotifier extends StateNotifier<TokenState> {
  TokenNotifier() : super(const TokenState(balance: 0)) {
    _load();
  }

  Future<void> _load() async {
    state = await getTokens();
  }

  Future<bool> spend(int amount) async {
    final result = await spendTokens(amount);
    state = TokenState(balance: result.newBalance);
    return result.success;
  }

  Future<void> earn(int amount) async {
    final result = await earnTokens(amount);
    state = result;
  }

  Future<void> reload() async {
    state = await getTokens();
  }
}

final tokenProvider = StateNotifierProvider<TokenNotifier, TokenState>(
  (ref) => TokenNotifier(),
);
