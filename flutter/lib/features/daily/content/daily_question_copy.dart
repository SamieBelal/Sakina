/// Every user-facing string on the daily question surface (W4 Wave 2).
///
/// Kept apart from the widget for the same reason `problem_chips.dart` is:
/// this copy was decided by the founder on 2026-07-30 against evidence, it is
/// referenced verbatim by tests, and it is the first thing an i18n pass will
/// extract. A rewording is a product change, not a layout tweak — the rationale
/// travels with the strings so the next person has to meet it before editing.
library;

abstract final class DailyQuestionCopy {
  /// Approved 2026-07-30 (spec M4).
  ///
  /// Over *"How is your heart today?"* — the primary input is a text field, and
  /// "how is" invites *"fine"* while "what's on" invites a sentence.
  ///
  /// Over *"What's weighing on you right now?"* — that is the onboarding hook
  /// line and the strongest ICP resonance we have, but it presupposes a burden
  /// **every single day**, which is the failure the evidence is most emphatic
  /// about. It stays in the reels.
  static const String header = "What's on your heart today?";

  /// **Load-bearing, not decoration** (spec M4).
  ///
  /// With chips, the answer set itself showed the user that gratitude was a
  /// legitimate answer. With free text there is nothing else doing that job, so
  /// without this line the question silently means *"what's wrong"* — and a
  /// good day is a first-class answer here. Any change to [header] must keep a
  /// placeholder that spans worry → thanks.
  static const String placeholder =
      'A worry, a thanks, a question — however it comes out.';

  /// Muḥāsabah is taught as a one-line gloss and is **never** the button label
  /// (plan §4): the CTA is the job to be done, the word teaches rather than
  /// gates — Hallow's treatment of Lectio Divina and the Examen.
  ///
  /// Transliterated in Latin script, so no `Text` on this screen mixes Arabic
  /// and English.
  static const String gloss =
      'Muḥāsabah — the daily habit of taking account of your own heart.';

  /// Neutral on purpose: no urgency, no promise of a reward, nothing that reads
  /// as a price for the answer above it.
  static const String submit = 'Continue';

  /// A defer, not a dismissal (spec M2). Nothing guilt-shaped on the way out,
  /// and nothing on the way back in references having skipped.
  static const String defer = 'Not right now';

  /// Frames the chips as the shortcut they are — "or", never "instead".
  static const String chipsLead = 'Or start from one of these';
}
