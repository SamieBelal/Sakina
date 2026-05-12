import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// Internal SharedPref key + in-memory session guard for the daily launch
// overlay. Lives in its own file (no Sakina-internal imports) so both
// `launch_gate_service.dart` and `daily_rewards_service.dart` can depend
// on it without forming an import cycle.

const String _launchGateKey = 'sakina_launch_gate';

bool _overlayPushedThisSession = false;

/// Test seam — replace in tests via `debugLaunchGateClock = ...` to drive
/// the gate at deterministic UTC instants. Production callers always read
/// `DateTime.now().toUtc()`. The gate stores UTC dates so it agrees with
/// `daily_rewards_service._today()` and the `claim_daily_reward` SQL RPC,
/// both of which key off UTC (`timezone('utc', now())::date`). Without
/// this, a claim made near local-but-not-UTC midnight wrote a "today
/// local" marker while the server wrote a "tomorrow UTC" `last_claim_date`
/// — next morning the marker disagreed with the UTC clock and the overlay
/// re-fired despite the user having already claimed.
@visibleForTesting
DateTime Function() debugLaunchGateClock = () => DateTime.now().toUtc();

String _today() {
  final now = debugLaunchGateClock();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

bool get launchGateOverlayPushedThisSession => _overlayPushedThisSession;

Future<String?> readLaunchGateMarker() async {
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  return prefs.getString(scopedKey);
}

String launchGateTodayMarker() => _today();

/// Call this after the overlay has been presented so subsequent opens skip it.
Future<void> markDailyLaunchShown() async {
  _overlayPushedThisSession = true;
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  await prefs.setString(scopedKey, _today());
}

/// Call this when the user resets the daily loop from Settings.
Future<void> resetDailyLaunchGate() async {
  _overlayPushedThisSession = false;
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  await prefs.remove(scopedKey);
}

void resetLaunchGateSessionState() {
  _overlayPushedThisSession = false;
}

@visibleForTesting
void resetLaunchGateMemoryGuard() {
  resetLaunchGateSessionState();
}
