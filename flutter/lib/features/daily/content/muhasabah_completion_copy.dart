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

  // ── Add to tonight (C1) ──

  /// The affordance, not a button that submits a form.
  ///
  /// *"Add to tonight"*, never *"Reflect again"* or *"New entry"*: the honest
  /// answer to "it won't let me do it again" is that tonight's entry is still
  /// open, not that a second night can be started. A label promising a second
  /// reflection would be promising a second reveal, which is exactly the thing
  /// the economy fires once.
  static const String addToTonight = 'Add to tonight';

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
}
