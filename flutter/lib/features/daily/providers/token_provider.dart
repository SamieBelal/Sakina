import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/token_service.dart';

class TokenNotifier extends StateNotifier<TokenState> {
  TokenNotifier() : super(const TokenState(balance: 0)) {
    _econSub = EconomyEvents.stream.listen((event) {
      if (event is TokenGranted) {
        state = TokenState(balance: event.newBalance);
      }
    });
    _load();
  }

  StreamSubscription<EconomyEvent>? _econSub;

  @override
  void dispose() {
    _econSub?.cancel();
    super.dispose();
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
    // earnTokens publishes via EconomyEvents; our listener will set state.
    await earnTokens(amount, source: EconomyEventSource.dev);
  }

  Future<void> reload() async {
    state = await getTokens();
  }
}

final tokenProvider = StateNotifierProvider<TokenNotifier, TokenState>(
  (ref) => TokenNotifier(),
);
