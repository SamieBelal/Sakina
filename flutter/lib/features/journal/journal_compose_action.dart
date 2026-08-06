import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// What the Journal's ONE primary control does right now (Wave D, D3).
///
/// One control, three meanings, resolved from the day's state — not three
/// buttons. The archive had no compose affordance at all: the screen listed
/// entries and offered no way to make one, and the All-tab empty state had no
/// CTA. Three buttons would have been the obvious fix and the wrong one, because
/// at any moment exactly one of them is the right thing to do and the other two
/// are either impossible (`add to tonight` before the night exists) or a
/// duplicate of the daily loop's own CTA.
enum JournalComposeAction {
  /// Tonight has not been written. → the muḥāsabah.
  startTonight,

  /// Tonight's entry exists and has room. → an append, which is a pure text
  /// write against a row that already exists. **Never a second reveal.**
  addToTonight,

  /// The night is done and closed (or full). → Reflect, the free-write surface,
  /// which is unlimited now that Wave A removed the save cap.
  freeWrite,
}

/// Resolves the control's meaning from the day's state. Pure, so the rule can
/// be pinned without standing up the daily loop.
///
/// [checkinDone] is what distinguishes "tonight hasn't happened" from "tonight
/// happened but left no row" — an offline night, or one whose write the server
/// refused. Offering *start tonight's muḥāsabah* in that second case would send
/// the user at a loop that will tell them they already did it.
JournalComposeAction resolveJournalComposeAction({
  required SavedReflection? tonightEntry,
  required bool checkinDone,
  int maxThread = 20,
}) {
  if (tonightEntry == null) {
    return checkinDone
        ? JournalComposeAction.freeWrite
        : JournalComposeAction.startTonight;
  }
  if (tonightEntry.thread.length >= maxThread) {
    return JournalComposeAction.freeWrite;
  }
  return JournalComposeAction.addToTonight;
}

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
        JournalComposeAction.freeWrite => 'Free write',
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
        JournalComposeAction.freeWrite =>
          'Reflections, duas you build, and duas you save will all appear here.',
      };
}
