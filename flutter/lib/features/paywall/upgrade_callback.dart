import 'package:sakina/services/gating_service.dart';

/// Builds the `onUpgrade` callback for a `DailyCapSheet`.
///
/// Premium users who hit the fair-use cap (30/day) see the SAME sheet as free
/// users hitting their 1/day cap, but the upgrade CTA must be a no-op for them
/// — they're already paying, so routing to the paywall would be insulting.
/// Every other gate reason routes to `/paywall` as normal.
Future<void> Function() buildPaywallUpgradeCallback({
  required GateReason reason,
  required void Function() pushPaywall,
}) {
  if (reason == GateReason.premiumFairUse) {
    return () async {};
  }
  return () async => pushPaywall();
}
