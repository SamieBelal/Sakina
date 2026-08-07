/// Every user-facing string the completion screen gained in Wave C.
///
/// Kept apart from the widgets for the same reason `DailyQuestionCopy` is: this
/// copy is the product decision, it is referenced verbatim by tests, and it is
/// the first thing an i18n pass will extract. The rationale travels with the
/// strings so the next person has to meet it before rewriting one.
///
/// Latin script throughout. No string here is ever concatenated with Arabic —
/// the Name renders in its own `Text` with its own direction (CLAUDE.md).
library;

abstract final class MuhasabahCompletionCopy {
  /// The headline the night lands on.
  ///
  /// Over *"Muhāsabah Complete"*, which is what shipped before Wave C and which
  /// is a receipt rather than an ending — a status label for a thing the user
  /// already knows they did. The whole finding behind this wave is that the core
  /// loop left no artifact; the first line of the screen should say that it now
  /// does, in the plainest available words.
  static const String header = 'Tonight is written down.';

  /// Sits under [header]. Says the two things that are now true and were not
  /// before: it is kept, and it is not finished with you.
  static const String subheader =
      'Your words, the Name you met, and the duʿā are saved to your journal. '
      'Tonight stays open until tomorrow.';

  /// Section label above the user's own answer.
  static const String yourWordsLabel = 'What you wrote';

  /// Section label above the duʿā.
  static const String duaLabel = 'The duʿā';

  /// Section label above the Name.
  static const String nameLabel = 'The Name you met';

  /// The same slot, when the entry on screen is one the day ALREADY had — see
  /// [DailyLoopState.tonightEntryIsReplay].
  ///
  /// The row is real and it is the user's, so it is still shown; what changes
  /// is the claim made about it. [nameLabel] says *you met this tonight*, and
  /// on a replay that is simply false — the ceremony just handed over a
  /// different Name. This label says only what is true: this is the Name
  /// recorded on today's entry.
  static const String nameLabelReplay = 'The Name on today’s entry';

  /// Sits above the summary on a replay, so the screen is not silently showing
  /// someone else's night with no explanation.
  static const String replayNotice =
      'Today already had an entry, so this is the one that was kept.';

  // ── Add to tonight (C1) ──

  /// The affordance, not a button that submits a form.
  ///
  /// Never *"Reflect again"* or *"New entry"*: the honest answer to "it won't
  /// let me do it again" is that tonight's entry is still open, not that a
  /// second night can be started. A label promising a second reflection would
  /// be promising a second reveal, which is exactly the thing the economy fires
  /// once.
  ///
  /// The wording moved from *"Add to tonight"* to *"Something else for
  /// tonight"* on 2026-08-07 — see [addToCtaFor] for the survey behind it. The
  /// constraint above is unchanged; only the half that named a database
  /// operation was replaced.
  static const String addToTonight = 'Something else for tonight';

  /// Accessible name for the append field.
  static const String addFieldLabel = 'Add to tonight';

  static const String addFieldHint = 'Anything else on your heart…';

  static const String addAction = 'Add';

  /// Shown when the day's twenty appends are used up, or the entry is full.
  ///
  /// Not an error and not a limit being sold: a cap nobody honest reaches,
  /// stated once, with the day's end as the reset.
  static const String addFull =
      "Tonight's entry is full. Tomorrow opens a fresh one.";

  /// Shown when the write did not land.
  static const String addFailed = "Couldn't add that just now. Try again?";

  /// Heading over the appends already made tonight.
  static const String threadLabel = 'Added tonight';

  // ── ʿazm (C4) ──

  /// The ask, phrased as a resolve rather than a goal or a task.
  ///
  /// ʿazm is a classical part of muḥāsabah — the accounting ends in a resolve —
  /// and it is also the strongest retention datum in the literature. It is one
  /// line on purpose: a text box that invites a plan invites abandonment.
  static const String azmPrompt = 'One thing you resolve for tomorrow';

  static const String azmHint = 'Tomorrow, I will…';

  static const String azmFieldLabel = 'Your resolve for tomorrow';

  static const String azmAction = 'Save';

  static const String azmSaved = 'Saved for tomorrow.';

  static const String azmFailed = "Couldn't save that just now. Try again?";

  /// The opener on the NEXT night's question surface.
  ///
  /// *"Last time"*, not *"Last night"*: the resolve is resurfaced from the most
  /// recent night the user wrote one, which is usually but not always yesterday.
  /// A line that says "last night" on a resolve written three nights ago is a
  /// small lie the user can catch, and it lands on the one screen that has to be
  /// trusted.
  static const String azmResurfaceLead = 'Last time, you resolved:';

  // ── Time machine (C3) ──

  /// The reveal's lead-in. The whole force of the pattern is that the words are
  /// the user's own, so the copy names the day and gets out of the way.
  static const String timeMachineMonth = 'A month ago tonight, you wrote:';
  static const String timeMachineQuarter = 'Three months ago tonight, you wrote:';
  static const String timeMachineYear = 'A year ago tonight, you wrote:';

  /// The lead for an anchor at [offsetDays] nights ago.
  static String timeMachineLead(int offsetDays) => switch (offsetDays) {
        30 => timeMachineMonth,
        90 => timeMachineQuarter,
        _ => timeMachineYear,
      };

  /// Closes the reveal by naming what it is — the archive paying rent, said
  /// once, without congratulating the user for having a past.
  static const String timeMachineFooter = 'You met a Name that night too.';

  // ── The one forward action ──

  /// The single way onward from the night.
  ///
  /// *"Seek Another Name"* sits below it and is deliberately NOT this: it is a
  /// card re-roll, premium-gated for `reel_v1`, and conflating it with the
  /// journaling path is the confusion this screen exists to remove.
  static const String returnHome = 'Return to Home';

  // ── The morning reader ────────────────────────────────────────────────────
  //
  // The muḥāsabah is NOT night-gated. It is keyed on `entry_local_day` with a
  // one-per-user-per-local-day unique index, and nothing in the daily provider
  // consults the clock to decide whether it may be done — the only
  // `DateTime.now().hour` reads there pick a greeting and a quest duʿā. So a
  // user who opens the app at 9am does a complete, correct muḥāsabah and then
  // gets told "Tonight is written down."
  //
  // That is a copy bug, not a behaviour bug, and the fix is a noun rather than
  // a gate: the entry belongs to a DAY, so before evening it should say so.
  // Classical muḥāsabah is evening-associated but not evening-restricted, and
  // refusing a morning reader — or lying to them about when they are — would
  // both be worse than swapping one word.
  //
  // [hour] is passed in, never read from `DateTime.now()` here, so every string
  // below stays pure and testable.

  /// The hour at which "today" becomes "tonight". 17:00 local — late enough
  /// that an afternoon session still reads as daytime, early enough that it has
  /// turned over before ʿIshāʾ anywhere this app ships.
  static const int eveningStartsAtHour = 17;

  static bool _isEvening(int hour) => hour >= eveningStartsAtHour;

  /// "Tonight" after [eveningStartsAtHour], "Today" before it. Capitalised.
  static String dayNoun(int hour) => _isEvening(hour) ? 'Tonight' : 'Today';

  /// Lowercase form, for mid-sentence use.
  static String dayNounLower(int hour) => _isEvening(hour) ? 'tonight' : 'today';

  /// [header], with the right noun for the hour.
  static String headerFor(int hour) => '${dayNoun(hour)} is written down.';

  /// [subheader], with the right noun for the hour.
  static String subheaderFor(int hour) =>
      'Your words, the Name you met, and the duʿā are saved to your journal. '
      '${dayNoun(hour)} stays open until tomorrow.';

  /// [addToTonightCta], with the right noun for the hour.
  ///
  /// **Was "Add to today" until 2026-08-07, and the rename is the point.**
  /// That label named the MECHANISM — a row exists for this date, put another
  /// line on it. Surveying the field (Five Minute Journal, Stoic, Day One,
  /// Rosebud, Niyyah, Hallow) turned up no app that labels this action after
  /// its storage: the guided journals name the MOMENT ("Evening reflection")
  /// and the free-form ones name the CONTENT ("What else are you grateful
  /// for?"). Ours now names the content, and harmonises with the field's own
  /// placeholder — *"Anything else on your heart…"* — which was already doing
  /// that job one screen later.
  ///
  /// Hour-aware for the reason it always was: the entry is keyed to the local
  /// DAY, so a reader at 09:00 is adding to *today* even though the ritual is
  /// called the nightly muḥāsabah.
  static String addToCtaFor(int hour) =>
      'Something else for ${dayNounLower(hour)}';

  /// The same label, short enough for the Journal's compose menu.
  ///
  /// Not a second name — the same name, elided. The menu's card is capped at
  /// 168pt (`_labelMaxWidth`) so that the option rows stay annotations on their
  /// icons rather than becoming a menu with icons stuck on the side; at 13pt
  /// the long form measures ~192pt and would ellipsise to
  /// "Something else for tod…", which is worse than eliding on purpose.
  ///
  /// Mirrors the split `NewReflectionCopy.remainingLine` / `remainingShort`
  /// already makes for the same reason, on the same surface.
  /// Deliberately hour-INDEPENDENT, unlike its long form: the day noun is the
  /// first thing the elision drops, and a menu row whose text changed at 17:00
  /// would reintroduce the shape-shifting control that
  /// [JournalComposeAction] was rebuilt to remove.
  static const String addToCtaShort = 'Something else';
}
