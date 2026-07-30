/// The daily question's **auto-entry** marker (W4 Waves 2 + 4 — plan §4/§6,
/// spec M2).
///
/// Day-open drops the user straight into the day's question. This marker is what
/// stops that happening twice: **auto-entry happens at most once per local day**,
/// and after it the home CTA is the only entry. Nothing here gates the muḥāsabah
/// route itself — a user who taps that CTA gets the full flow from the top. It
/// gates only the app's decision to ask *unprompted*.
///
/// **The stamp is written at auto-entry, not at the exit** (founder,
/// 2026-07-30). Wave 2 first wrote it from the "Not right now" handler, which
/// left a hole: someone who backed out with the system gesture had not
/// "deferred", so the question was thrown at them again on the next open. The
/// marker's job is preventing nagging, and that has to hold regardless of *how*
/// they left. The skip-versus-abandon distinction is real and still matters — it
/// lives in the analytics events (Wave 7), because that is about signal, not
/// about frequency.
///
/// A consequence, accepted deliberately: the stamp lands *before* the user does
/// anything, so a crash immediately after auto-entry costs that day's auto-entry.
/// That is the price of "at most once per local day, however they left", and the
/// home CTA still re-enters the whole flow.
///
/// ## Why this clock is not the launch gate's clock
///
/// This marker is **user-local**; `launch_gate_state.dart` is **UTC**; both are
/// right. The launch gate must agree with `claim_daily_reward`, whose SQL keys
/// off `timezone('utc', now())::date`. But "have we already asked this person
/// today" is a question about *their* day, so it resolves through
/// [userLocalDayString] — the same boundary the queue unseal uses.
///
/// The two can disagree by up to a day near midnight, and
/// [shouldAutoEnterDailyQuestion] is a conjunction rather than an attempt to
/// reconcile them. **The asymmetry in that conjunction is deliberate and must
/// not be "tidied up":**
///
/// > **Failing to auto-enter costs the user one tap on the home CTA.
/// > Auto-entering twice is nagging, and cannot be undone.
/// > So when the clocks disagree, always fail toward not-asking.**
///
/// Worked example, because the direction is easy to get backwards. A UTC-7 user
/// finishes their muḥāsabah at 16:00 local Monday and reopens at 18:00 local —
/// which is 01:00 UTC *Tuesday*. The UTC gate legitimately reports a new day, so
/// without this marker they would meet the question a second time in one evening,
/// on a local day whose Name they already revealed and whose queue has unsealed
/// nothing new.
///
/// The opposite disagreement is left alone on purpose: a UTC+9 user's 08:00 local
/// Tuesday is still Monday UTC, so they get no auto-entry until 09:00 local. That
/// is the pre-existing behaviour of the UTC launch gate rather than a regression
/// of this wave, and the promoted home CTA means they are never blocked — only
/// not auto-entered. Which is the cheap side of the asymmetry.
library;

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

/// Unscoped key; the account suffix is added by `scopedKey` so one device's two
/// accounts cannot inherit each other's auto-entry.
const String dailyQuestionAutoEntryBaseKey =
    'sakina_daily_question_auto_entered';

/// Test seam, mirroring `debugLaunchGateClock`. Always interpreted as UTC and
/// then mapped into the user's zone by [userLocalDayString].
@visibleForTesting
DateTime Function()? debugDailyQuestionGateClock;

String _scopedKey() =>
    supabaseSyncService.scopedKey(dailyQuestionAutoEntryBaseKey);

/// Whether day-open may drop the user into the question unprompted.
///
/// The UTC launch gate keeps deciding *"is there a reward day to open"*; this
/// marker decides *"have we already asked this person today"*. See the library
/// doc for why the two clocks stay separate and which way the conjunction leans.
///
/// The local marker is checked FIRST because it is a prefs read while
/// [shouldShowDailyLaunch] does a network reconcile — no reason to pay for that
/// once we already know we will not ask.
Future<bool> shouldAutoEnterDailyQuestion() async {
  if (await dailyQuestionAutoEnteredToday()) return false;
  return shouldShowDailyLaunch();
}

/// Records that the question was auto-entered today. Best-effort: a prefs
/// failure costs one extra auto-entry, never the user's way out of the screen,
/// so callers proceed regardless.
Future<void> markDailyQuestionAutoEnteredToday() async {
  try {
    final day = await userLocalDayString(clock: debugDailyQuestionGateClock);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(), day);
  } catch (e) {
    debugPrint(
        '[daily_question_gate] could not write the auto-entry marker: $e');
  }
}

/// Whether the question has already been auto-entered during the current local
/// day.
Future<bool> dailyQuestionAutoEnteredToday() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final marker = prefs.getString(_scopedKey());
    if (marker == null) return false;
    return marker ==
        await userLocalDayString(clock: debugDailyQuestionGateClock);
  } catch (e) {
    // Fail OPEN: an unreadable marker must not lock the user out of the day's
    // question — the worst case is one auto-entry they already declined.
    debugPrint(
        '[daily_question_gate] could not read the auto-entry marker: $e');
    return false;
  }
}

/// Clears the marker — the Settings "reset the daily loop" path, alongside
/// `resetDailyLaunchGate`.
Future<void> resetDailyQuestionGate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_scopedKey());
}
