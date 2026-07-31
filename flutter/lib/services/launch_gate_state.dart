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
///
/// **The date is read before the first await, not after it.** This used to
/// resolve `_today()` on the far side of `SharedPreferences.getInstance()`, and
/// the caller (`daily_launch_overlay.initState`) does not await it — so an app
/// opened at 23:59:59 could stamp TOMORROW's date. That marks tomorrow as
/// already-shown before it has begun, and the user loses a day of the loop
/// entirely: no overlay, and — because `shouldAutoEnterDailyQuestion` leans on
/// this same gate — no question either.
///
/// Vanishingly rare per user per day, and certain across a userbase over
/// months. The window is not microseconds: on a cold launch the prefs channel
/// has to spin up, which is exactly when someone opening the app last thing at
/// night hits it.
Future<void> markDailyLaunchShown() async {
  _overlayPushedThisSession = true;
  // The instant the app ASKED is the instant that defines the day. Everything
  // after this line may take as long as it likes.
  final day = _today();
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  await prefs.setString(scopedKey, day);
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
