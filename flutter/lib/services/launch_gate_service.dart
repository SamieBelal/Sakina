import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';

const String _launchGateKey = 'sakina_launch_gate';

// In-memory guard so only one overlay is ever pushed per app session.
bool _overlayPushedThisSession = false;

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Returns true if the daily launch overlay should be shown (first open today).
Future<bool> shouldShowDailyLaunch() async {
  if (_overlayPushedThisSession) return false;
  final prefs = await SharedPreferences.getInstance();
  final scopedKey = supabaseSyncService.scopedKey(_launchGateKey);
  final last = prefs.getString(scopedKey);
  return last != _today();
}

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
