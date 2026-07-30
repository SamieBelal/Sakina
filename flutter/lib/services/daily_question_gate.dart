/// The daily question's **auto-entry** marker (W4 Wave 2 — plan §4, spec M2).
///
/// "Not right now" defers the whole loop rather than dismissing it: the
/// question, the reveal and the reward all stay collectible from the home CTA
/// for the rest of the day. What the defer must NOT do is let the question be
/// thrown at the user again on the next app open — nagging someone who already
/// said "not right now" is the fastest way to make the exit feel fake. So a
/// defer writes this marker, and **auto-entry happens at most once per local
/// day**; after it, the home CTA is the only entry.
///
/// Read by the day-open path (Wave 4). Nothing here gates the muḥāsabah route
/// itself — a user who taps the home CTA after deferring gets the full flow
/// from the top, which is the entire point.
///
/// **Local day, not UTC.** The launch gate deliberately keys off UTC so it
/// agrees with `claim_daily_reward`; this one is about the user's own sense of
/// "today, later", so it uses the same user-local day the queue unseal does
/// (`user_local_day.dart`). The two can disagree by up to a day near midnight —
/// that seam is real, it is called out in plan §6, and it is Wave 4's to pin.
library;

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

/// Unscoped key; the account suffix is added by `scopedKey` so one device's two
/// accounts cannot inherit each other's defer.
const String dailyQuestionDeferredBaseKey = 'sakina_daily_question_deferred';

/// Test seam, mirroring `debugLaunchGateClock`. Always interpreted as UTC and
/// then mapped into the user's zone by [userLocalDayString].
@visibleForTesting
DateTime Function()? debugDailyQuestionGateClock;

String _scopedKey() =>
    supabaseSyncService.scopedKey(dailyQuestionDeferredBaseKey);

/// Records that the user deferred today's question. Best-effort: a prefs
/// failure costs one extra auto-entry, never the user's way out of the screen,
/// so callers navigate home regardless.
Future<void> markDailyQuestionDeferredToday() async {
  try {
    final day = await userLocalDayString(clock: debugDailyQuestionGateClock);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(), day);
  } catch (e) {
    debugPrint('[daily_question_gate] could not write the defer marker: $e');
  }
}

/// Whether the question has already been deferred during the current local day.
Future<bool> dailyQuestionDeferredToday() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final marker = prefs.getString(_scopedKey());
    if (marker == null) return false;
    return marker ==
        await userLocalDayString(clock: debugDailyQuestionGateClock);
  } catch (e) {
    // Fail OPEN: an unreadable marker must not lock the user out of the day's
    // question — the worst case is one auto-entry they already declined.
    debugPrint('[daily_question_gate] could not read the defer marker: $e');
    return false;
  }
}

/// Clears the marker — the Settings "reset the daily loop" path, alongside
/// [resetDailyLaunchGate].
Future<void> resetDailyQuestionGate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_scopedKey());
}
