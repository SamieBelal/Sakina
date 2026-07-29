/// Eligibility for the first-visit hints (Wave F, F3) — the calm replacement
/// for the deleted guided tour.
///
/// **This is deliberately NOT a tour.** A hint is a small cream banner that
/// appears once, beside the thing it describes, on the user's first arrival at
/// that surface. It dims nothing, absorbs no taps, has no step counter, no skip
/// affordance and no sequence. Ignoring one costs the user nothing — it fades
/// on its own. See [FirstVisitHintBanner] for the widget half.
///
/// The guardrails below are binding, not advisory. Per-surface hints with no
/// global budget is precisely the Clippy failure mode (excessive interruption),
/// and it is how hint systems die:
///
///   1. **Once ever, per hint** — one scoped pref key each.
///   2. **Max one hint per session** — a process-global latch.
///   3. **None in the first session** in which the user reaches any hint
///      surface (see [_resolveSessionOrdinal]) — a hint immediately after ~18
///      pages of onboarding reads as more onboarding.
///   4. **A lifetime cap** ([firstVisitHintLifetimeCap]) — so this cannot
///      quietly grow into a hint *system* as features ship. Adding a fourth
///      hint does not add a fourth interruption; it competes for the same three.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// How long a hint lingers before fading itself out.
const Duration firstVisitHintAutoFade = Duration(seconds: 6);

/// The total number of hints a user may ever be shown, across all surfaces and
/// all time. Equal to the current hint count on purpose: shipping a fourth hint
/// must be a deliberate decision to raise the budget, not a silent one.
const int firstVisitHintLifetimeCap = 3;

/// Unscoped base key for the running total of hints shown to this user.
const String firstVisitHintShownCountBaseKey = 'first_visit_hint_shown_count';

/// Unscoped base key for the session ordinal (see [_resolveSessionOrdinal]).
const String firstVisitHintSessionOrdinalBaseKey =
    'first_visit_hint_session_ordinal';

/// The three surfaces that earn a hint.
///
/// The test applied was "is this feature genuinely not self-explanatory?" —
/// Collection, Journal, the Duas tab and streaks all failed it and get nothing.
enum FirstVisitHintId {
  /// The tab name does not convey what the feature does, and Reflect is the
  /// single biggest payer/free behavioural gap in the app.
  reflect,

  /// The stage is reached by tapping the Home medallion — an unguessable
  /// gesture — and the lamp's dimness has no on-screen explanation.
  companion,

  /// A currency with no explanation of what it is or where it comes from.
  noor,
}

extension FirstVisitHintIdX on FirstVisitHintId {
  /// Unscoped base key for the once-ever flag. Scoped per user at read/write
  /// time so a shared device cannot spend one user's hint on another.
  String get baseKey => switch (this) {
        FirstVisitHintId.reflect => 'first_visit_hint_reflect',
        FirstVisitHintId.companion => 'first_visit_hint_companion',
        FirstVisitHintId.noor => 'first_visit_hint_noor',
      };

  /// The banner copy. Kept here rather than at the call site so all three read
  /// as one voice, and so they extract together for translation.
  ///
  /// Voice rules these are written to: warm, never instructional, never
  /// prescriptive, no exclamation, no "tip", no second-person command where an
  /// observation will do. Each is a quiet aside, not a notification.
  String get message => switch (this) {
        FirstVisitHintId.reflect =>
          'Whatever is on your heart can go here — a Name, verse and '
              'duʿā return.',
        FirstVisitHintId.companion =>
          'Your lantern lives here — the lamp on Home. It brightens as your '
              'streak grows.',
        FirstVisitHintId.noor =>
          'Noor gathers on the days you show up. It is what dresses your '
              'lantern.',
      };
}

/// Builds the user-scoped pref key for [baseKey].
///
/// Mirrors `SupabaseSyncService.scopedKey`: unscoped while signed out (the
/// deferred-signup flow means real users browse before they have a uid),
/// `base:<uid>` once signed in. The `:<uid>` suffix is also the contract
/// `clearScopedPreferencesForUser` matches on, so sign-out clears these for
/// free. Top level so it is unit-testable without a live Supabase client.
String firstVisitHintScopedKey(String baseKey, String? userId) =>
    (userId == null || userId.isEmpty) ? baseKey : '$baseKey:$userId';

String? _defaultUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    // Supabase not initialised (tests, very early boot). Unscoped is the safe
    // read: it can never leak another user's state, because there isn't one.
    return null;
  }
}

class FirstVisitHintService {
  FirstVisitHintService._();

  static final FirstVisitHintService instance = FirstVisitHintService._();

  /// Test/QA seam for the signed-in user id, in the same spirit as
  /// `GiftService.debugGiftClock`.
  static String? Function() debugUserIdResolver = _defaultUserId;

  /// Guardrail 2. Process-global, so it resets exactly when the app does —
  /// the same definition of "session" `launchGateOverlayPushedThisSession`
  /// already uses.
  static bool _sessionClaimed = false;

  /// Guardrail 3, memoised per scope so the ordinal is incremented once per
  /// process. Keyed by the *scoped* pref key rather than a bare bool, so a user
  /// who signs in mid-process is correctly treated as being in their own first
  /// session (which is the post-onboarding session we must stay out of).
  static String? _ordinalScope;
  static int? _sessionOrdinal;

  @visibleForTesting
  static void debugResetSession() {
    _sessionClaimed = false;
    _ordinalScope = null;
    _sessionOrdinal = null;
  }

  /// True if [hint] may be shown right now — and, when true, **records it as
  /// spent** (both the once-ever flag and the lifetime tally).
  ///
  /// Marking at claim time rather than at dismiss is deliberate: "once ever"
  /// means once *offered*. A user who ignores a hint has still seen it, and
  /// re-offering it would be the interruption the guardrails exist to prevent.
  Future<bool> claim(FirstVisitHintId hint) async {
    if (_sessionClaimed) return false;

    final userId = debugUserIdResolver();
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // No pref store means no way to honour once-ever, and a hint we cannot
      // remember showing is a hint that shows forever. Stay silent.
      return false;
    }

    final hintKey = firstVisitHintScopedKey(hint.baseKey, userId);
    if (prefs.getBool(hintKey) ?? false) return false;

    final ordinal = await _resolveSessionOrdinal(prefs, userId);
    if (ordinal <= 1) return false;

    final countKey =
        firstVisitHintScopedKey(firstVisitHintShownCountBaseKey, userId);
    final shownSoFar = prefs.getInt(countKey) ?? 0;
    if (shownSoFar >= firstVisitHintLifetimeCap) return false;

    // Re-check after the awaits: two surfaces resolving concurrently must not
    // both win the session.
    if (_sessionClaimed) return false;
    _sessionClaimed = true;

    await prefs.setBool(hintKey, true);
    await prefs.setInt(countKey, shownSoFar + 1);
    return true;
  }

  /// Which session this is, counting only sessions in which the user actually
  /// reached a hint surface. Incremented once per process per scope.
  ///
  /// Counting arrivals rather than app launches is a deliberate trade. It means
  /// guardrail 3 costs every user their first *visit* to a hint surface, not
  /// just their first launch — but the alternative (a launch counter) would
  /// have to live in `main.dart`/`app_session.dart`, and under-counting there
  /// is worse: it would let a hint land in the session right after onboarding,
  /// which is the one place it must never land.
  Future<int> _resolveSessionOrdinal(
      SharedPreferences prefs, String? userId) async {
    final key =
        firstVisitHintScopedKey(firstVisitHintSessionOrdinalBaseKey, userId);
    final memoised = _sessionOrdinal;
    if (_ordinalScope == key && memoised != null) return memoised;

    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    _ordinalScope = key;
    _sessionOrdinal = next;
    return next;
  }
}
