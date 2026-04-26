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
/// "shown today" even when the server says nothing was claimed. See F1/F5
/// in docs/qa/findings/2026-04-22-core-loop-fixes.md.
Future<bool> shouldShowDailyLaunch() async {
  if (launchGateOverlayPushedThisSession) return false;

  // Best-effort server reconcile — if the network is down we fall through
  // to the cached value (better to skip the overlay than to crash).
  try {
    await reconcileDailyRewardsFromServer();
  } catch (_) {}

  final last = await readLaunchGateMarker();
  return last != launchGateTodayMarker();
}
