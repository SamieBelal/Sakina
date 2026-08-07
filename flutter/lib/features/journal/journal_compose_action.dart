import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// What the Journal's compose control can do right now (Wave D D3; reshaped
/// 2026-08-07).
///
/// D3 shipped ONE control with three meanings, resolved from the day. It was
/// right about the problem — the archive had no compose affordance at all — and
/// wrong about the shape, for a reason that only shows up in use: **the control
/// changed identity underneath the user.** The same pixel read "Begin Muhāsabah"
/// in the morning, "Add to today" after the ritual, and "Free write" once the
/// thread filled. A primary control you cannot predict is one you stop reaching
/// for.
///
/// Its third face also lied. "Free write" routed to Reflect, which is metered —
/// so a free user who had spent the day's reflection tapped a button labelled
/// *free* and met a paywall sheet.
///
/// It is now a permanent `+` that opens a sheet of whatever is genuinely
/// available, each row stating its cost before it is tapped. The resolver below
/// still exists and still means "the one thing to do first"; it is now the head
/// of [journalComposeOptions] rather than a separate rule.
enum JournalComposeAction {
  /// Today has not been written. → the muḥāsabah.
  startTonight,

  /// Today's entry exists and has room. → an append, which is a pure text
  /// write against a row that already exists. **Never a second reveal**, and
  /// the only compose action that spends nothing.
  addToTonight,

  /// → Reflect. A second, third, fourth entry today is not a missing feature
  /// and never was: `uniq_muhasabah_per_local_day` is a PARTIAL index and does
  /// not touch `source = 'reflect'` rows, so these are unlimited per day at the
  /// table. What limits them is the AI allowance, which is a different thing
  /// and is now said out loud.
  ///
  /// Renamed from `freeWrite` — "free write" named neither the act nor its
  /// price. The analytics wire value is deliberately unchanged; see
  /// `AnalyticsEvents.composeActionNewReflection`.
  newReflection,
}

/// Everything the compose control may offer, most-primary first.
///
/// [checkinDone] is what distinguishes "today hasn't happened" from "today
/// happened but left no row" — an offline night, or one whose write the server
/// refused. Offering *begin the muḥāsabah* in that second case would send the
/// user at a loop that will tell them they already did it.
///
/// [JournalComposeAction.newReflection] is in every list this returns, because
/// it is true on every day in every state. The contextual row is what varies.
List<JournalComposeAction> journalComposeOptions({
  required SavedReflection? tonightEntry,
  required bool checkinDone,
  int maxThread = 20,
}) {
  // The free action leads when it exists: appending to an open entry costs
  // nothing, and a chooser whose first row is the metered one is a chooser that
  // sells before it serves.
  if (tonightEntry != null && tonightEntry.thread.length < maxThread) {
    return const [
      JournalComposeAction.addToTonight,
      JournalComposeAction.newReflection,
    ];
  }
  if (tonightEntry == null && !checkinDone) {
    return const [
      JournalComposeAction.startTonight,
      JournalComposeAction.newReflection,
    ];
  }
  return const [JournalComposeAction.newReflection];
}

/// The one thing to do first. Derived, so it cannot drift from the list.
JournalComposeAction resolveJournalComposeAction({
  required SavedReflection? tonightEntry,
  required bool checkinDone,
  int maxThread = 20,
}) =>
    journalComposeOptions(
      tonightEntry: tonightEntry,
      checkinDone: checkinDone,
      maxThread: maxThread,
    ).first;

/// The control's copy. Verbatim-referenced by tests, like
/// `MuhasabahCompletionCopy` — and for the same reason: it is the product
/// decision, not decoration.
abstract final class JournalComposeCopy {
  static String label(JournalComposeAction action) => switch (action) {
        // "Begin", matching the Home CTA the user already knows, so the Journal
        // is not teaching a second name for the same thing.
        JournalComposeAction.startTonight => 'Begin Muḥāsabah',
        // Verbatim the completion screen's label. The same act, reached from a
        // second place, must not acquire a second name.
        // Hour-aware for the same reason the completion screen is: the entry
        // is local-DAY keyed, so a morning reader is adding to *today*. Still
        // "verbatim the completion screen's label" — both now call
        // [MuhasabahCompletionCopy.addToCtaFor], so the two cannot drift.
        JournalComposeAction.addToTonight =>
          MuhasabahCompletionCopy.addToCtaFor(DateTime.now().hour),
        // Was "Free write". It named neither the act nor its price, and the
        // destination is metered — so on a spent day the button said *free* and
        // produced a paywall sheet. "New reflection" names the act; the
        // subtitle names the price.
        JournalComposeAction.newReflection => 'New reflection',
      };

  /// The line under each row in the compose sheet: what this will do, and what
  /// it will cost, BEFORE it is tapped.
  ///
  /// The cost half is the point. `canUse` already refuses a spent free user at
  /// the gate, but refusing after the tap is not the same as saying so before
  /// it — the first is a wall, the second is a choice.
  ///
  /// [isPremium] only changes the reflection line. Everything else costs the
  /// same for everyone.
  static String subtitle(
    JournalComposeAction action, {
    required bool isPremium,
  }) =>
      switch (action) {
        JournalComposeAction.startTonight =>
          "Today's accounting. You meet a Name, and it keeps your streak.",
        // No hedge: `appendToTonight` is a pure text write against a row that
        // already exists. It reveals no Name, marks no streak, claims no
        // reward and spends no allowance.
        JournalComposeAction.addToTonight =>
          "Adds to today's entry. Free, and as often as you like.",
        JournalComposeAction.newReflection => isPremium
            // True for a subscriber: the only ceiling is the fair-use one at
            // 30/day, which nobody honest reaches, so quoting it would be
            // inventing a limit the reader does not have.
            ? 'A fresh reflection on anything on your mind.'
            // Deliberately not a number. The remaining count is async and
            // varies by cohort, warmup and trial state; a wrong number here is
            // worse than an honest sentence. See the follow-up note in
            // `journal_screen._buildComposeSheet`.
            : 'A fresh reflection on anything on your mind. Uses one of your '
                'reflections.',
      };

  /// The empty-state sub-line under the control, when the All tab has nothing
  /// to show. Says what the button will do, not what the screen is missing.
  static String emptyStateSub(JournalComposeAction action) =>
      switch (action) {
        JournalComposeAction.startTonight =>
          "Tonight's muḥāsabah will be the first entry here — your words, the "
              'Name you meet, and the duʿā.',
        JournalComposeAction.addToTonight =>
          "Tonight's entry is open. Anything else on your heart can still go in.",
        JournalComposeAction.newReflection =>
          'Reflections, duas you build, and duas you save will all appear here.',
      };
}
