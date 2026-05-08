// lib/services/economy_events.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
///
/// **Test-isolation contract:** the underlying `StreamController` is a
/// process-level singleton that is never closed in production. Tests that
/// subscribe via [stream] MUST:
///
///   1. Hold their own [StreamSubscription] and cancel it in `tearDown`
///      (or via `addTearDown(sub.cancel)`). This is the canonical pattern
///      and the primary defense against cross-test event leakage.
///   2. Call [resetForTest] in `tearDown` as a backstop. This closes and
///      recreates the controller so any subscribers that escaped (1) get
///      a stream-closed event and stop receiving.
///
/// Production code subscribers (`token_provider`, `tier_up_scroll_provider`,
/// `daily_loop_provider`, `app_shell`) are designed to live for the duration
/// of their provider/widget — that's correct in production and unaffected
/// by [resetForTest].
class EconomyEvents {
  EconomyEvents._();

  static StreamController<EconomyEvent> _controller =
      StreamController<EconomyEvent>.broadcast();

  static Stream<EconomyEvent> get stream => _controller.stream;

  static void publish(EconomyEvent event) => _controller.add(event);

  /// Closes and recreates the underlying broadcast controller. Call in
  /// `tearDown()` for tests that subscribe to the stream — guarantees
  /// listeners from one test don't survive into the next.
  ///
  /// This is a TEST contract only. Production code never calls this.
  @visibleForTesting
  static Future<void> resetForTest() async {
    await _controller.close();
    _controller = StreamController<EconomyEvent>.broadcast();
  }
}
