/// Every user-facing string on the Journal's *new reflection* composer
/// (2026-08-07).
///
/// Kept apart from the widget for the same reason `daily_question_copy.dart`
/// is: these are product decisions referenced verbatim by tests, and a
/// rewording is a product change rather than a layout tweak.
///
/// **This surface is the muḥāsabah's twin, deliberately.** It asks the same
/// kind of question, on the same emerald canvas, over the same seven
/// `problemChips`, and ends in the same `BeatRevealFlow`. Only two things
/// differ, and both are why the copy below is not simply
/// [DailyQuestionCopy]'s:
///
///  1. **The Name is not predetermined.** The muḥāsabah reveals the day's Name
///     from the queue and writes *about* it; here the model picks the Name that
///     answers what the user wrote. Text → Name, not Name → text.
///  2. **It is not the day's ritual.** It marks no streak the muḥāsabah has not
///     already marked, and it can be done as often as the allowance permits —
///     so nothing here may imply "today", "tonight", or a thing owed.
library;

import 'package:sakina/services/gating_service.dart';

abstract final class NewReflectionCopy {
  /// The question.
  ///
  /// Deliberately NOT [DailyQuestionCopy.header] (*"What's on your heart
  /// today?"*). The word *today* is load-bearing on that surface — it is the
  /// day's one entry — and actively wrong here, where the whole point is that
  /// this is an entry the day did not ask for. A user reaching this screen at
  /// 4pm having already done their muḥāsabah must not be asked the identical
  /// question a second time, or the two surfaces read as a bug.
  ///
  /// *"What are you carrying?"* is the reel vocabulary (see the widget's
  /// "A Name for What You're Carrying"), present-tense and un-dated.
  static const String header = 'What are you carrying?';

  /// The answer-set carrier, and the same rule applies here as on the daily
  /// question: **it must not be a hint.** A hint clears on the first keystroke,
  /// and this line is the only thing telling the user that a good day is a
  /// legitimate answer. See [DailyQuestionCopy.answerSetCaption] for the full
  /// account of the defect this shape exists to avoid.
  static const String answerSetCaption =
      'A worry, a thanks, a question — however it comes out.';

  /// Accessible name for the field. Shorter than the caption on purpose: the
  /// caption explains what counts as an answer, this says which control takes
  /// it.
  static const String answerFieldLabel = 'Your reflection';

  /// The exit's accessible name. A pushed route, so this closes and returns to
  /// the Journal — it does not defer anything, and must not borrow the daily
  /// question's "Not right now" (which defers a whole ritual).
  static const String closeLabel = 'Close';

  /// The balance, shown when the user is on the free tier and it is known.
  ///
  /// **The [AllowanceKind] is not optional decoration — it picks the sentence.**
  /// The first draft of this took a bare `int` and always said *"left this
  /// week"*, which is true of the weekly pool and false of the warm-up: the
  /// warm-up is a LIFETIME per-feature grant that never refills. Every new
  /// account starts in warm-up, so that draft told literally every new user
  /// their three lifetime reflections would come back on Monday. Caught by a
  /// layout test, of all things, which is not a mechanism to rely on twice —
  /// hence the kind is required rather than defaulted.
  ///
  /// [AllowanceKind.unlimited] and [AllowanceKind.unmetered] must never reach
  /// here; callers check `hasCount` first. Asserted rather than silently
  /// rendered, because the failure mode is quoting a subscriber a limit.
  ///
  /// Singular is handled: "1 reflections" on a screen about someone's inner
  /// life is the kind of sloppiness that makes the rest feel automated.
  static String remainingLine(AllowanceSnapshot allowance) {
    assert(
      allowance.hasCount,
      'remainingLine called for ${allowance.kind}, which has no honest number. '
      'Check AllowanceSnapshot.hasCount first.',
    );
    final n = allowance.remaining!;
    final noun = n == 1 ? 'reflection' : 'reflections';
    return switch (allowance.kind) {
      // No reset promised, because none is owed — this grant is spent once and
      // does not return. "to try" rather than "left" for the same reason: it
      // reads as an invitation to spend rather than as a countdown.
      AllowanceKind.warmup => '$n free $noun to try',
      AllowanceKind.weeklyPool => '$n $noun left this week',
      AllowanceKind.unlimited || AllowanceKind.unmetered => '',
    };
  }

  /// The same fact, short enough for the compose menu — whose rows are one
  /// ellipsised line each, because the options stack 64pt apart and a wrapping
  /// caption makes the rows physically overlap.
  static String remainingShort(AllowanceSnapshot allowance) {
    assert(allowance.hasCount);
    final n = allowance.remaining!;
    return switch (allowance.kind) {
      AllowanceKind.warmup => '$n free to try',
      AllowanceKind.weeklyPool => '$n left this week',
      AllowanceKind.unlimited || AllowanceKind.unmetered => '',
    };
  }
}
