import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/services/daily_rewards_service.dart';

/// True when a streak freeze was burned to bridge a lapse and the user hasn't
/// yet dismissed the Home reunion card (spec S4 / D14). Server-authoritative
/// via [hasPendingFreezeBurn], so it fires exactly once across devices and
/// survives a cache clear. Invalidate after [ackFreezeBurn] to hide the card.
final pendingFreezeBurnProvider = FutureProvider<bool>((ref) async {
  return hasPendingFreezeBurn();
});
