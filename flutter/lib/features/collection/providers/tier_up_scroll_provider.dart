import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/consumable_grants_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

class TierUpScrollNotifier extends StateNotifier<TierUpScrollState> {
  TierUpScrollNotifier() : super(const TierUpScrollState(balance: 0)) {
    // Subscribe BEFORE _load so a grant landing during hydration still
    // updates the balance pill — same rationale as DailyLoopNotifier.
    _grantsSub = ConsumableGrantsService.grants.listen((event) {
      if (event.kind == ConsumableGrantKind.scrolls) {
        state = TierUpScrollState(balance: event.newBalance);
      }
    });
    _load();
  }

  StreamSubscription<ConsumableGrantEvent>? _grantsSub;

  @override
  void dispose() {
    _grantsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    state = await getTierUpScrolls();
  }

  Future<TierUpScrollEarnResult> earn(int amount) async {
    final result = await earnTierUpScrolls(amount);
    state = TierUpScrollState(balance: result.newBalance);
    return result;
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
