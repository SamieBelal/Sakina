import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

class TierUpScrollNotifier extends StateNotifier<TierUpScrollState> {
  TierUpScrollNotifier() : super(const TierUpScrollState(balance: 0)) {
    // Subscribe BEFORE _load so a grant landing during hydration still
    // updates the balance pill — same rationale as DailyLoopNotifier.
    _grantsSub = EconomyEvents.stream.listen((event) {
      if (event is ScrollGranted) {
        state = TierUpScrollState(balance: event.newBalance);
      }
    });
    _load();
  }

  StreamSubscription<EconomyEvent>? _grantsSub;

  @override
  void dispose() {
    _grantsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    state = await getTierUpScrolls();
  }

  Future<TierUpScrollEarnResult> earn(int amount) async {
    // earnTierUpScrolls publishes ScrollGranted via EconomyEvents; our
    // grants listener (constructor) updates state. No manual set needed.
    return earnTierUpScrolls(amount, source: EconomyEventSource.dev);
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
