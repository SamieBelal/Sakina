/// The daily question's within-wave funnel (W4 Wave 7 — plan §9, spec §2/§9).
///
/// W4 ships alongside the paywall wave, and the One Ship's keep read is a
/// pre/post comparison with no control arm — so at T0+6wk we will know whether
/// the ship worked and **not** which half did it. This funnel is the
/// compensation: shown → answered → (the existing completion event), with the
/// two failure modes held apart.
///
/// **`daily_question_skipped` and `daily_question_abandoned` are never merged.**
/// A skip is the user telling us the *placement* was wrong for that moment and
/// the loop stays collectible from home; an abandon is the user telling us the
/// *question* was wrong. Folding them together loses the whole readout for the
/// defer design.
///
/// ---
///
/// **PRIVACY — the one rule that outranks every metric here.** The user's own
/// words about what is on their heart are the most sensitive thing this app
/// holds. They are written to `DailyLoopState.checkinAnswers`, persisted
/// locally, and sent to the reflection engine because that is the product.
/// They are **never** sent to Mixpanel: not as a property, not truncated, not
/// hashed, and not inside an error payload. What leaves the device about an
/// answer is exactly two things — a [charCountBucket] and the chip category the
/// pure offline keyword map derived from it.
///
/// That is why this file exposes buckets and no formatter that takes the text.
/// [charCountBucket] takes an `int` on purpose: a helper that accepted the
/// String would be one careless refactor away from putting it on the wire.
/// Pinned by `daily_question_analytics_test.dart`, which asserts the answer
/// text appears in no emitted payload on any path.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

// ---------------------------------------------------------------------------
// entry_source — how the user arrived at the question
// ---------------------------------------------------------------------------

/// The app put the question in front of the user on open. The only entry the
/// app initiates on the user's behalf, and therefore the only one bound by
/// "auto-entry at most once per local day" (spec M2).
const String questionEntryDayOpen = 'day_open';

/// A home-screen widget tap. **Must stay separable from [questionEntryDayOpen]**
/// (plan §9): a widget tap deliberately takes precedence over the day-open
/// path, so folding the two together would hide the widget's contribution
/// entirely.
const String questionEntryWidget = 'widget';

/// The user tapped something in the app to get here — the home CTA, a re-roll,
/// a quest card. Also the same-day *return* after a skip, which makes
/// `daily_question_shown{entry_source:'home_cta'}` following a
/// `daily_question_skipped` the headline metric for the whole defer design: if
/// skippers do not come back, the defer is a polite exit from the product
/// rather than a deferral within it.
const String questionEntryHomeCta = 'home_cta';

/// The GoRouter query parameter carrying [questionEntryDayOpen] and friends
/// into `MuhasabahScreen`. `/muhasabah?entry=home_cta`.
///
/// **An untagged navigation to `/muhasabah` counts as [questionEntryDayOpen]**
/// — see [questionEntrySourceFor]. Every in-app push tags itself, so absence
/// means the app brought the user here. `daily_question_entry_source_test.dart`
/// greps `lib/` and fails on any untagged push, because a new one added later
/// would silently inflate day-open rather than show up as a miscount.
const String questionEntryQueryParam = 'entry';

/// Reads [questionEntryQueryParam] out of a route's query parameters.
///
/// Unrecognised values degrade to [questionEntryDayOpen] rather than passing a
/// junk string through to Mixpanel — the prop is a closed set of three and a
/// fourth value would quietly break every segment built on it.
String questionEntrySourceFor(Map<String, String> queryParameters) {
  switch (queryParameters[questionEntryQueryParam]) {
    case questionEntryWidget:
      return questionEntryWidget;
    case questionEntryHomeCta:
      return questionEntryHomeCta;
    default:
      return questionEntryDayOpen;
  }
}

// ---------------------------------------------------------------------------
// Buckets
// ---------------------------------------------------------------------------

/// Bucketed length of the user's answer. **The only thing about the text itself
/// that ever leaves the device.**
///
/// Boundaries are lower-inclusive / upper-inclusive as the names read: `1_20`
/// is 1–20 characters, `21_60` is 21–60, and so on. Chosen against the shape of
/// real answers rather than round numbers — the longest chip label is 24
/// characters, so `1_20` is very nearly "shorter than a chip", and `21_60`
/// straddles the tapped answers. `301_plus` is open-ended.
///
/// Zero is not a legitimate answer (both the surface and the provider refuse
/// empty input) but is bucketed as `0` rather than asserted, because a metric
/// helper is the wrong place to throw.
String charCountBucket(int chars) {
  if (chars <= 0) return '0';
  if (chars <= 20) return '1_20';
  if (chars <= 60) return '21_60';
  if (chars <= 140) return '61_140';
  if (chars <= 300) return '141_300';
  return '301_plus';
}

/// Bucketed time on the question before the user skipped or abandoned it.
///
/// Boundaries are lower-inclusive / upper-EXCLUSIVE, as the `_` names read as
/// ranges: `0_2s` is [0, 2000), `2_5s` is [2000, 5000), and so on. The short
/// buckets carry the signal — a sub-two-second abandon is a user who did not
/// read the question, which is a different finding from one who read it,
/// thought about it, and left.
///
/// Negative input (a clock that went backwards) floors at the first bucket.
String dwellMsBucket(int ms) {
  if (ms < 2000) return '0_2s';
  if (ms < 5000) return '2_5s';
  if (ms < 15000) return '5_15s';
  if (ms < 60000) return '15_60s';
  return '60s_plus';
}

// ---------------------------------------------------------------------------
// Emission
// ---------------------------------------------------------------------------

/// Static analytics hook for the question *surface* (mirrors
/// [AnalyticsEvents]-adjacent hooks like `StreakAnalytics.onAnalyticsEvent` and
/// `WidgetDeepLinkHandler.onAnalyticsEvent`). `main.dart` wires it; tests leave
/// it null, which makes every method here a no-op.
///
/// The three surface events live here rather than on `DailyLoopNotifier`
/// because only the widget knows them: a skip and an abandon never reach the
/// provider at all, and the dwell clock is a mount lifetime.
/// `daily_question_answered` is emitted from the provider instead — it is the
/// one event whose properties the provider already owns (Wave 3 derived
/// `problem_category` and `input_mode` at submit), and re-deriving them up here
/// would fork the taxonomy.
abstract final class DailyQuestionAnalytics {
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  /// Unscoped; the account suffix is added by `scopedKey` so one device's two
  /// accounts cannot inherit each other's marker.
  @visibleForTesting
  static const String shownDayBaseKey = 'sakina_daily_question_shown_day';

  /// Test seam for the local-day clock behind the debug guard.
  @visibleForTesting
  static DateTime Function()? debugShownClock;

  /// The question was put to the user. [entrySource] is one of
  /// [questionEntryDayOpen] / [questionEntryWidget] / [questionEntryHomeCta].
  static void shown(String entrySource) {
    final emit = onAnalyticsEvent;
    if (emit == null) return;
    emit(AnalyticsEvents.dailyQuestionShown, {
      AnalyticsEvents.propEntrySource: entrySource,
    });
    // Debug-only, and deliberately fire-and-forget: the guard reads prefs, and
    // nothing about telemetry may put an await between the user and the screen
    // they are looking at.
    assert(() {
      unawaited(debugCheckAutoEntryOncePerLocalDay(entrySource));
      return true;
    }());
  }

  /// "Not right now" — the explicit defer. [dwell] is the time since the
  /// question was shown.
  static void skipped(Duration dwell) => onAnalyticsEvent?.call(
        AnalyticsEvents.dailyQuestionSkipped,
        {AnalyticsEvents.propDwellMsBucket: dwellMsBucket(dwell.inMilliseconds)},
      );

  /// Backgrounded or navigated away without deciding.
  static void abandoned(Duration dwell) => onAnalyticsEvent?.call(
        AnalyticsEvents.dailyQuestionAbandoned,
        {AnalyticsEvents.propDwellMsBucket: dwellMsBucket(dwell.inMilliseconds)},
      );

  // -------------------------------------------------------------------------
  // Debug guard
  // -------------------------------------------------------------------------

  /// Asserts that **auto-entry** has not already thrown the question at this
  /// user today, and records the day when it has not.
  ///
  /// **Scoped to [questionEntryDayOpen] on purpose, and this is a deliberate
  /// narrowing of "`daily_question_shown` never fires twice in one local day".**
  /// Applied to every entry source that sentence is simply false in normal use:
  /// a metered re-roll calls `resetToday()` and legitimately re-shows the
  /// question from the home CTA, and a user who backs out of the question and
  /// taps their widget again gets a second, entirely correct, `widget` show. An
  /// assert that fires during ordinary use is an assert that gets deleted.
  ///
  /// What the invariant actually protects is the *nagging* bug: spec M2 says
  /// auto-entry happens at most once per local day, and day-open is the only
  /// entry the app initiates on the user's behalf. A second `day_open` show in
  /// one local day means the defer marker or the launch gate is not holding —
  /// which is exactly the failure that makes the "Not right now" exit feel
  /// fake.
  ///
  /// Local day, not UTC: this is about the user's own sense of "today, later",
  /// like `daily_question_gate.dart` and unlike the UTC launch gate.
  ///
  /// Everything is swallowed except the assertion itself. A prefs failure must
  /// never surface as a crash in a debug build for the sake of a metric.
  @visibleForTesting
  static Future<void> debugCheckAutoEntryOncePerLocalDay(
      String entrySource) async {
    if (entrySource != questionEntryDayOpen) return;
    String today;
    SharedPreferences prefs;
    String key;
    try {
      today = await userLocalDayString(clock: debugShownClock);
      prefs = await SharedPreferences.getInstance();
      key = supabaseSyncService.scopedKey(shownDayBaseKey);
    } catch (e) {
      debugPrint('[daily_question_analytics] auto-entry guard skipped: $e');
      return;
    }
    debugAssertFirstAutoEntryToday(prefs.getString(key), today);
    try {
      await prefs.setString(key, today);
    } catch (_) {}
  }

  /// The pure core of the guard, so the invariant is testable without a clock,
  /// prefs or a mounted widget.
  @visibleForTesting
  static void debugAssertFirstAutoEntryToday(String? priorDay, String today) {
    assert(
      priorDay != today,
      'daily_question_shown{entry_source: day_open} fired twice on $today. '
      'Auto-entry is once per local day (spec M2) — a second one means the '
      'defer marker (daily_question_gate.dart) or the launch gate is not '
      'holding, and the user is being asked again after saying "not right '
      'now". Re-rolls and widget taps are NOT this bug; they enter as '
      'home_cta / widget and are not checked.',
    );
  }

  /// Clears the guard's marker. Test-only — production never needs it.
  @visibleForTesting
  static Future<void> debugResetShownDay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(supabaseSyncService.scopedKey(shownDayBaseKey));
  }
}
