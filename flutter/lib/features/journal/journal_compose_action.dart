import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/journal/content/new_reflection_copy.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/gating_service.dart';

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
        // The completion screen's label, elided. The same act, reached from a
        // second place, must not acquire a second NAME — but it may lose its
        // day noun, because this card is capped at 168pt and the long form
        // ("Something else for tonight") would ellipsise mid-word there.
        //
        // Both forms live in [MuhasabahCompletionCopy] so the two surfaces
        // cannot drift, and the short one is hour-independent on purpose: a
        // menu row whose text changed at 17:00 would be the shape-shifting
        // control this enum was rebuilt to remove.
        JournalComposeAction.addToTonight =>
          MuhasabahCompletionCopy.addToCtaShort,
        // Was "Free write". It named neither the act nor its price, and the
        // destination is metered — so on a spent day the button said *free* and
        // produced a paywall sheet. "New reflection" names the act; the
        // subtitle names the price.
        JournalComposeAction.newReflection => 'New reflection',
      };

  /// The line under each row in the compose menu: what it will cost, BEFORE it
  /// is tapped.
  ///
  /// Kept to ONE short line. These stack above the FAB 64pt apart, against a
  /// ~52pt card — a wrapping two-line caption makes the row ~80pt tall and the
  /// rows physically overlap, at which point the upper option swallows taps
  /// meant for the lower one. That shipped once; `compose_menu_test` pins it
  /// now.
  ///
  /// The cost half is the point. `canUse` already refuses a spent free user at
  /// the gate, but refusing after the tap is not the same as saying so before
  /// it — the first is a wall, the second is a choice.
  ///
  /// ## ONE source for "is this person premium", and it is [allowance]
  ///
  /// This used to take a separate `isPremium` flag, which the Journal filled
  /// from `premiumStateProvider`. That shipped a screen contradicting itself: a
  /// free user's header read *"9 free to try"* while this row read *"Included
  /// with premium"*.
  ///
  /// The two providers are not equivalent and that is the whole bug.
  /// `premiumStateProvider` is a plain `FutureProvider` — it caches for the
  /// life of the app and is only invalidated when the lifecycle observer sees a
  /// foreground or an auth change. `reflectionAllowanceProvider` is
  /// `autoDispose` and re-resolves on every Journal visit. So the moment
  /// premium actually lapses — a gift expiring, a subscription ending, a test
  /// account being changed underneath — the fresh source knows and the cached
  /// one does not, and the user is told both.
  ///
  /// [AllowanceKind.unlimited] IS the premium answer, produced by the same
  /// `describeAllowance` call that produces the count. Reading it from there
  /// means the two halves of this line cannot disagree, because they are one
  /// read.
  ///
  /// [allowance] null — unresolved, or a failed resolve — falls back to the
  /// number-free sentence. That briefly over-states the cost to a subscriber,
  /// which is the direction to be wrong in: over-stating a cost is a smaller
  /// error than hiding one.
  static String subtitle(
    JournalComposeAction action, {
    AllowanceSnapshot? allowance,
  }) =>
      switch (action) {
        JournalComposeAction.startTonight =>
          'Keeps your streak',
        // No hedge: `appendToTonight` is a pure text write against a row that
        // already exists. It reveals no Name, marks no streak, claims no
        // reward and spends no allowance.
        //
        // Shortened from "Free, as often as you like" (2026-08-07). At 26
        // characters it was the widest string in the menu by a distance and
        // set the width of every card, since they share a right edge — a 175pt
        // slab on a 390pt phone, for a caption. "any time" carries the same
        // unlimited-ness in a third of the room.
        JournalComposeAction.addToTonight => 'Free, any time',
        JournalComposeAction.newReflection =>
          switch (allowance?.kind) {
            // True for a subscriber: the only ceiling is the fair-use one at
            // 30/day, which nobody honest reaches, so quoting it would be
            // inventing a limit the reader does not have.
            AllowanceKind.unlimited => 'Included with premium',
            _ => allowance != null && allowance.hasCount
                // The balance at the instant of the decision, which is the
                // only instant it is worth knowing.
                ? NewReflectionCopy.remainingShort(allowance)
                // The honest fallback. A wrong number on this line is worse
                // than no number.
                : 'Uses one reflection',
          },
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
