/// **DRAFT — copy awaiting founder review (spec §11 item 2).** The four
/// single-tap intake questions added by Wave H (H2, H3, H4, H6) and the H7
/// free-text copy, together with the **visible consequence** each answer buys
/// (One Ship W2-H, `2026-07-28-onboarding-intake-depth-design.md`).
///
/// §2 of that spec is the governing constraint and the reason every option list
/// here sits next to a consequence function rather than alone: *a question whose
/// answer never surfaces is extractive, and a longer extractive form is worse
/// than the three questions we have today.* Nothing in this file is a habit
/// target, a commitment device or a completion goal — the streak, lantern and
/// widget stack owns commitment (founder call, 2026-07-28), and H6 in particular
/// is deliberately NOT Duolingo's "I'M COMMITTED" screen.
///
/// Copy rules carried in from spec §8 and pinned by
/// `test/features/onboarding/intake_copy_register_test.dart`:
///
///   * never attribute a stance, intent or outcome to Allah — every promise
///     here is about the USER's knowledge, words or practice;
///   * no lapse presupposition ("again", "when I slip") — the corrected ICP is a
///     Muslim at ANY level of practice in a period of real difficulty, and a
///     devout user having the worst month of their life must not be told they
///     drifted;
///   * no prescriptive tone — "just pray more" is the advice this user has
///     already failed at, and the top-ranked bounce trigger.
library;

/// One selectable answer. [key] is stable snake_case (persisted to
/// `OnboardingState` and used as the analytics value); the label is free to be
/// re-written. Same shape as [CarryingDuration], deliberately — the reel flow's
/// question screens all render one list of these.
class IntakeOption {
  const IntakeOption({required this.key, required this.label});

  final String key;
  final String label;
}

// ───────────────────────────────────────────────────────────────────────────
// H2 — "When is it heaviest?"
//
// This question REPLACES the reminder-time ask rather than adding to it. "What
// time do you want reminders?" is a chore and an ask; asking when the weight is
// heaviest extracts the same information with the opposite emotional valence,
// and lets the app say something true back. Net-zero screen count.
// ───────────────────────────────────────────────────────────────────────────

const String heaviestQuestionLabel = 'When is it heaviest?';

/// Not "be accurate" or "pick carefully" — the subline takes weight off
/// answering, it does not add any.
const String heaviestSublineLabel = 'Whenever it tends to settle on you.';

const List<IntakeOption> heaviestTimes = [
  IntakeOption(key: 'mornings', label: 'Mornings'),
  IntakeOption(key: 'daytime', label: 'During the day'),
  IntakeOption(key: 'nights', label: 'At night'),
  IntakeOption(key: 'alone', label: "When I'm alone"),
  IntakeOption(key: 'relentless', label: "It doesn't let up"),
];

/// [heaviestTimes] keyed by [IntakeOption.key].
final Map<String, IntakeOption> heaviestTimesByKey = {
  for (final o in heaviestTimes) o.key: o,
};

/// The reminder time [key] derives, as the `"HH:mm"` 24h string
/// `OnboardingState.reminderTime` already carries.
///
/// **Whole hours only.** The shipped reminder-time screen normalises to the hour
/// and the server's due-query filters on the hour, so a half-hour value here
/// would be silently rounded somewhere downstream and the persisted value would
/// stop describing what the user actually gets.
///
/// The two answers that are not clock times get the defensible reading rather
/// than a clever one: *"when I'm alone"* is most often the evening, and *"it
/// doesn't let up"* has no worst hour, so it takes the app's own long-standing
/// 08:00 default — the kindest anchor is the start of the day, not the end of
/// it. Returns null when unanswered, so the caller writes nothing rather than
/// committing a guessed reminder.
String? heaviestReminderTime(String? key) {
  switch (key) {
    case 'mornings':
      return '07:00';
    case 'daytime':
      return '13:00';
    case 'nights':
      return '21:00';
    case 'alone':
      return '20:00';
    case 'relentless':
      return '08:00';
    default:
      return null;
  }
}

/// H2's visible consequence on the plan screen — the app repeating back what
/// the user said about their own hours, and when it will be there.
///
/// No claim about what will happen to them at that hour: the promise is about
/// the app's own behaviour, which is the right side of the §8 line.
///
/// Two copy rules hold across all six branches, because only ONE of them ever
/// renders and the set has to read as one voice regardless of which:
///
///   * the playback echoes the user's own words — the question asked what was
///     *heaviest*, so the answer never paraphrases that as "hardest", and each
///     first sentence mirrors the option label the user actually tapped;
///   * one verb for the promise ("will be there"). "Waiting" was the other half
///     of an earlier split, and it quietly implies something expecting you.
String heaviestPlanLine(String? key) {
  switch (key) {
    case 'mornings':
      return 'You said mornings are heaviest. Your Name will be there first '
          'thing.';
    case 'daytime':
      return "You said it's heaviest during the day. Your Name will be there "
          'at midday.';
    case 'nights':
      return 'You said nights are heaviest. Your Name will be there before you '
          'sleep.';
    case 'alone':
      return "You said it's heaviest when you're alone. Your Name will be "
          'there each evening.';
    case 'relentless':
      return "You said it doesn't let up. Your Name will be there each "
          'morning.';
    default:
      return 'Your Name will be there whenever you open this.';
  }
}

// ───────────────────────────────────────────────────────────────────────────
// H3 — "Have you been able to tell anyone?"
//
// The highest-variance question in the set, approved by the founder ON THE
// CONDITION that we act on it (spec §4): 40% of young Muslim men in the MYH
// data told nobody about their last problem, and answering "No one" to an app is
// itself the moment of being seen — but if the answer changes nothing visible it
// is voyeurism. Binding: "No one" and "A little" must alter at least the plan
// line and the first notification's register. Both live below.
// ───────────────────────────────────────────────────────────────────────────

const String toldAnyoneQuestionLabel = 'Have you been able to tell anyone?';

const String toldAnyoneSublineLabel = "There's no right answer here.";

const List<IntakeOption> toldAnyoneOptions = [
  IntakeOption(key: 'someone_knows', label: 'Someone knows'),
  IntakeOption(key: 'a_little', label: 'A little'),
  IntakeOption(key: 'no_one', label: 'No one'),
  // Unlike the "Rather not say" on the source question — which is a SKIP that
  // writes nothing, because declining to be measured is an answer about being
  // measured — this one is a real option with a real value. Declining to say
  // whether anyone knows is itself a state worth honouring, and it routes to the
  // same neutral register as an unanswered screen, so recording it costs the
  // user nothing and never puts words in their mouth.
  IntakeOption(key: 'rather_not_say', label: 'Rather not say'),
];

/// [toldAnyoneOptions] keyed by [IntakeOption.key].
final Map<String, IntakeOption> toldAnyoneOptionsByKey = {
  for (final o in toldAnyoneOptions) o.key: o,
};

/// The two registers H3 selects between. String constants rather than an enum
/// because they are also the analytics value and the notification-copy key.
abstract final class ToldAnyoneRegister {
  /// "No one" / "A little" — nobody has heard this in full.
  static const String unspoken = 'unspoken';

  /// "Someone knows", "Rather not say", or unanswered.
  static const String spoken = 'spoken';
}

/// Which register [key] puts the reveal and the first notification in.
///
/// "Rather not say" deliberately reads as [ToldAnyoneRegister.spoken]: the
/// quieter register is a response to someone who told us they are carrying this
/// alone, and inferring that from a decline would be reading something into an
/// answer the user withheld on purpose.
String toldAnyoneRegister(String? key) =>
    (key == 'no_one' || key == 'a_little')
        ? ToldAnyoneRegister.unspoken
        : ToldAnyoneRegister.spoken;

/// H3's visible consequence on the plan screen.
///
/// The unspoken lines answer the ICP's second-ranked fear — being judged —
/// rather than promising anything about what saying it will do.
String toldAnyonePlanLine(String? key) {
  switch (key) {
    case 'someone_knows':
      return 'Someone already knows. This is somewhere to sit with it '
          'yourself.';
    case 'a_little':
      return "You've said some of it. There's room here for the rest.";
    case 'no_one':
      return "You haven't said this to anyone. Nothing here asks you to "
          'explain yourself.';
    default:
      return 'Nothing here asks you to explain yourself.';
  }
}

/// H3's second consequence — the register of the first notification the user
/// receives, at the hour H2 derived.
///
/// The difference is deliberately small. A user who has told nobody does not
/// want the app to make a thing of it; they want the one line that arrives to
/// sound like it knows.
String toldAnyoneFirstNotificationBody(String? key) =>
    toldAnyoneRegister(key) == ToldAnyoneRegister.unspoken
        ? 'Your Name for today is here — quietly.'
        : 'Your Name for today is here.';

// ───────────────────────────────────────────────────────────────────────────
// H4 — "How many of Allah's Names could you name right now?"
//
// The projection baseline. Nothing in the current intake establishes what the
// user already knows, so "you'll learn 30 Names" has nothing to be measured
// against. This is Duolingo's "How much French do you know?" — load-bearing,
// because it is what lets the plan say "You know about five. In 30 days you'll
// know thirty-five." A claim about the USER's own knowledge, which is why it
// stays the right side of §8.
// ───────────────────────────────────────────────────────────────────────────

/// No "right now" on the end: the hook screen ("What's weighing on you right
/// now?") and H5 ("What would help most right now?") both carry it already, and
/// three screens in eight saying it is the flow's most audible tic. The work it
/// did here — *off the top of your head, don't go and count* — is done better by
/// the subline below.
const String namesKnownQuestionLabel =
    "How many of Allah's Names could you name?";

/// The whole point of the subline: this must not read as a test. A user who
/// feels caught out here is a user who has just been told they are not Muslim
/// enough for the app, which is the exact failure the corrected ICP forbids.
const String namesKnownSublineLabel = 'A guess is fine.';

const List<IntakeOption> namesKnownOptions = [
  IntakeOption(key: 'few', label: 'Just a few'),
  IntakeOption(key: 'ten', label: 'Maybe ten'),
  IntakeOption(key: 'many', label: 'A good number'),
  // Not "I've tried to learn them all". "Tried" makes the top rung the only
  // option in the whole intake that asks the user to concede a shortfall, and
  // it was also the longest label in the flow by half again — a six-word
  // sentence in a set where nothing else runs past four.
  IntakeOption(key: 'all', label: "I've studied them"),
];

/// [namesKnownOptions] keyed by [IntakeOption.key].
final Map<String, IntakeOption> namesKnownOptionsByKey = {
  for (final o in namesKnownOptions) o.key: o,
};

/// How many Names the plan screen credits [key] with, or null when unanswered.
///
/// Null rather than a default: the projection sentence names a number back at
/// the user as something they told us, and inventing one would be putting a
/// claim about their own knowledge in their mouth.
int? namesKnownBaseline(String? key) {
  switch (key) {
    case 'few':
      return 5;
    case 'ten':
      return 10;
    case 'many':
      return 25;
    case 'all':
      return 50;
    default:
      return null;
  }
}

/// How many Names the first month adds — the queue is one Name a day.
const int namesKnownProjectionGain = 30;

/// H4's visible consequence: the projection sentence on the plan screen, or
/// null when the question was not answered.
///
/// Clamped at 99 because there are 99, and a plan promising a hundredth would be
/// the app inventing scripture-adjacent content in a sentence about scripture.
String? namesKnownProjectionLine(String? key) {
  final baseline = namesKnownBaseline(key);
  if (baseline == null) return null;
  final projected = (baseline + namesKnownProjectionGain).clamp(0, 99);
  // "on the hard days", not "when life gets heavy": this user's life is heavy
  // today, and a future tense quietly tells them their situation is the
  // hypothetical case. It also keeps "heaviest" belonging to H2's playback,
  // which renders a few lines below this one on the same screen.
  return "You know about $baseline. In $namesKnownProjectionGain days you'll "
      'know $projected — and which one to turn to on the hard days.';
}

// ───────────────────────────────────────────────────────────────────────────
// H6 — "How much time feels right most days?"
//
// **Deliberately NOT a commitment device** (founder call, 2026-07-28). The
// streak, lantern and widget already own commitment and this question must not
// compete with them. No option may read as the failure choice: "As long as I
// need" replaces "Longer when I can" precisely because the latter implies a
// scarcity the user should feel bad about.
// ───────────────────────────────────────────────────────────────────────────

const String dailyTimeQuestionLabel = 'How much time feels right most days?';

const String dailyTimeSublineLabel = 'Whatever fits your days.';

const List<IntakeOption> dailyTimeOptions = [
  IntakeOption(key: 'minute', label: 'Just a minute'),
  IntakeOption(key: 'few_minutes', label: 'A few minutes'),
  IntakeOption(key: 'as_long', label: 'As long as I need'),
];

/// [dailyTimeOptions] keyed by [IntakeOption.key].
final Map<String, IntakeOption> dailyTimeOptionsByKey = {
  for (final o in dailyTimeOptions) o.key: o,
};

/// How much of a Name's deck [key] asks for. W3 reads this; it is the second
/// consumer that keeps H6 from being decorative.
abstract final class DeckLength {
  /// Name, meaning, one line to carry.
  static const String short = 'short';

  /// The story behind it as well.
  static const String standard = 'standard';

  /// Everything beneath it — verse, duʿā, takeaway.
  static const String full = 'full';
}

/// The deck depth [key] prefers. Unanswered gets [DeckLength.standard] — the
/// shipped default, not a guess about the user.
String dailyTimeDeckLength(String? key) {
  switch (key) {
    case 'minute':
      return DeckLength.short;
    case 'as_long':
      return DeckLength.full;
    default:
      return DeckLength.standard;
  }
}

/// H6's visible consequence on the plan screen — what a session actually looks
/// like at the length they chose. Every line describes the same daily Name; none
/// of them describes more or fewer days.
String dailyTimePacingLine(String? key) {
  switch (key) {
    case 'minute':
      return 'A minute is enough. One Name, and one line to carry.';
    case 'few_minutes':
      return 'A few minutes. One Name, and the story behind it.';
    case 'as_long':
      return 'As long as you need. One Name, and everything beneath it.';
    default:
      return 'One Name at a time, however long you need.';
  }
}

// ───────────────────────────────────────────────────────────────────────────
// H7 — "Anything you want to add?"
//
// A payer-detection surface, not merely an input: payers do 3× the reflections
// on near-identical check-in counts, so giving the depth-diver somewhere to go
// deep on Day 0 targets the person who actually converts. Skippable, so it costs
// everyone else nothing.
// ───────────────────────────────────────────────────────────────────────────

const String intakeNoteQuestionLabel = 'Anything you want to add?';

/// States the consequence honestly rather than begging for the input: this text
/// becomes AI context for Reflect and Build-a-Duʿā. "What we bring you" rather
/// than "the words we bring you" — it shapes duʿā and reflection as well, so the
/// broader noun is both shorter and truer.
const String intakeNoteSublineLabel =
    'Only if you want to. It shapes what we bring you.';

/// Four words, and no second sentence. This is grey placeholder text inside a
/// field, the lightest-weight copy in the flow — and its old second half
/// ("There's no right length") was a near-repeat of H3's subline two screens
/// back, which made the reassurance sound like a script rather than a reply.
const String intakeNoteHintLabel = 'In your own words.';

const String intakeNoteSubmitLabel = 'Continue';

/// The decline path, phrased as a complete answer rather than an abandonment —
/// most people have nothing to add and must not feel they skipped something.
const String intakeNoteSkipLabel = 'Nothing to add';

/// Grapheme cap on the stored note (user-perceived characters, so emoji and
/// Arabic ligatures are never split mid-code-unit).
///
/// Far more generous than the 280 on duʿā topics: this is the depth-diver's
/// screen and a hard stop mid-sentence is the wrong message to send the one
/// person writing at length. It exists only so a pathological paste cannot
/// balloon the prefs blob or the AI context window.
const int intakeNoteMaxGraphemes = 1000;
