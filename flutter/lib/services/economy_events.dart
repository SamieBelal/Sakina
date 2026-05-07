// lib/services/economy_events.dart
import 'dart:async';
import 'package:sakina/services/xp_service.dart';

enum EconomyEventSource { quest, firstSteps, streak, dailyReward, iap, dev }

sealed class EconomyEvent {
  const EconomyEvent({required this.source});
  final EconomyEventSource source;
}

/// Emitted when a token grant lands and the cache + (optional) server are updated.
class TokenGranted extends EconomyEvent {
  const TokenGranted({
    required this.amount,
    required this.newBalance,
    required super.source,
  });
  final int amount;
  final int newBalance;
}

/// Emitted when a tier-up scroll grant lands.
class ScrollGranted extends EconomyEvent {
  const ScrollGranted({
    required this.amount,
    required this.newBalance,
    required super.source,
  });
  final int amount;
  final int newBalance;
}

/// Emitted when an XP award lands. Carries level-up info if the grant crossed a threshold.
class XpGranted extends EconomyEvent {
  const XpGranted({
    required this.amount,
    required this.newTotal,
    required this.newState,
    required this.leveledUp,
    this.rewards,
    required super.source,
  });
  final int amount;
  final int newTotal;
  final XpState newState;
  final bool leveledUp;
  final LevelUpRewards? rewards;
}

/// Broadcaster: late subscribers do NOT receive replays. UI state is loaded
/// from the cache at startup; live events are for in-session refresh only.
class EconomyEvents {
  EconomyEvents._();

  static final StreamController<EconomyEvent> _controller =
      StreamController<EconomyEvent>.broadcast();

  static Stream<EconomyEvent> get stream => _controller.stream;

  static void publish(EconomyEvent event) => _controller.add(event);
}
