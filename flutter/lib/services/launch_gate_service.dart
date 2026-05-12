import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_state.dart';

// Re-export the gate primitives so existing callers that import
// `launch_gate_service.dart` keep working unchanged. The underlying state
// lives in `launch_gate_state.dart` to avoid a cycle with
// `daily_rewards_service.dart`.
export 'package:sakina/services/launch_gate_state.dart';

/// Returns true if the daily launch overlay should be shown (first open today).
///
/// Reconciles the local rewards cache with the server FIRST so admin/QA-driven
/// resets to `user_daily_rewards` (or multi-device claims) actually re-trigger
/// the overlay. Without this, the local SharedPref gate could lie about
/// "shown today" even when the server says nothing was claimed.
///
/// After reconcile, also checks whether the server says the user already
/// claimed today. On a fresh install (marker absent) where the server already
/// confirms a same-UTC-day claim — typically a delete+reinstall on the same
/// day — the overlay would otherwise re-fire and walk the user through a
/// "Reward Claimed!" success screen they've already seen. We suppress the
/// overlay and persist the marker so subsequent cold launches today also
/// skip. See docs/qa/findings/2026-05-12-daily-launch-overlay-fix.md.
Future<bool> shouldShowDailyLaunch() async {
  if (launchGateOverlayPushedThisSession) return false;

  // Best-effort server reconcile — if the network is down we fall through
  // to the cached value (better to skip the overlay than to crash).
  try {
    await reconcileDailyRewardsFromServer();
  } catch (_) {}

  final last = await readLaunchGateMarker();
  if (last == launchGateTodayMarker()) return false;

  // Fresh-install / cache-wiped path: the marker is missing but the server
  // already says today's reward is claimed. Don't re-show the post-claim
  // success screen — persist the marker so the rest of today is quiet.
  final rewards = await getDailyRewards();
  if (rewards.claimedToday) {
    await markDailyLaunchShown();
    return false;
  }

  return true;
}
