import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

class TierUpScrollNotifier extends StateNotifier<TierUpScrollState> {
  TierUpScrollNotifier() : super(const TierUpScrollState(balance: 0)) {
    _load();
  }

  Future<void> _load() async {
    state = await getTierUpScrolls();
  }

  Future<void> earn(int amount) async {
    state = await earnTierUpScrolls(amount);
  }

  Future<TierUpScrollSpendResult> spend(int amount) async {
    final result = await spendTierUpScrolls(amount);
    state = TierUpScrollState(balance: result.newBalance);
    return result;
  }

  Future<void> reload() async {
    state = await getTierUpScrolls();
  }
}

final tierUpScrollProvider =
    StateNotifierProvider<TierUpScrollNotifier, TierUpScrollState>(
  (ref) => TierUpScrollNotifier(),
);
