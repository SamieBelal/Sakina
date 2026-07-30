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
  /// line that spans worry → thanks.
  ///
  /// **A caption, not a placeholder** — renamed from `placeholder` by the Wave
  /// 2 review. It renders as a persistent line under the field and is therefore
  /// visible while the user types and on an off-topic re-ask, where the field
  /// opens pre-filled. As a hint it vanished on the first keystroke, was never
  /// shown on a re-ask at all, and ellipsized at large Dynamic Type. The name
  /// is part of the fix: a constant called `placeholder` invites the next
  /// person to put it back in `hintText`.
  ///
  /// **The defect this fixed, stated so a future reader knows when it applies:
  /// the bug was never "guidance lives in a hint". It was that the answer set
  /// had exactly ONE carrier and that carrier was a hint.** Both halves are
  /// required. W4 created the condition on this surface by demoting the chips
  /// and promoting free text — the carrier moved, and nothing noticed.
  ///
  /// The corollary is the rule worth applying elsewhere: **the answer set must
  /// have a carrier that cannot disappear and cannot be truncated.** A hint
  /// fails the first (it clears on input); a `maxLines` budget fails the
  /// second. Measured 2026-07-30, the live reel hook screen
  /// (`hook_problem_screen.dart`) passes both — its seven chip cards wrap
  /// freely inside `minHeight` constraints — which is why it needed no
  /// equivalent fix. The legacy `first_checkin_screen.dart` hides its chips on
  /// focus, losing both carriers at once; it is unfixed and out of scope,
  /// recorded here only because it is the same rule being broken.
  static const String answerSetCaption =
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

  /// Shown when the off-topic classifier rejects an answer (W4 Wave 3
  /// follow-up). Founder copy, 2026-07-30.
  ///
  /// **It never tells the user they were wrong.** No "invalid", no "couldn't
  /// understand", no suggestion that the app failed to comprehend them — the
  /// failure is ours and we simply do not mention it. The person most likely to
  /// trip the classifier is the person who wrote the least, and being told your
  /// sentence about what you are carrying did not parse is the worst possible
  /// moment to meet a machine.
  ///
  /// [offTopicHeader] is a question rather than a statement so it reads as an
  /// invitation, and [offTopicBody] deliberately echoes [answerSetCaption] — a
  /// re-ask is the same invitation repeated, not a new error state. *"A few
  /// words is enough"* lowers the bar explicitly.
  static const String offTopicHeader = 'Say a little more?';
  static const String offTopicBody =
      'However it comes out — a worry, a thanks, a few words is enough.';
}
