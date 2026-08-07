/// Wave E — in-app resurfacing. The rules and the copy, with no widgets.
///
/// Three surfaces, one file, because they share a single constraint that is
/// easier to hold in one place than in three: **the archive must not turn into a
/// wall of prompts.** Every resolver here returns null far more often than it
/// returns something, and each of them says in its own doc comment what makes it
/// stay quiet. A resurfacing feature that fires every day is a feed.
///
/// * **E1 "On This Night"** — your own entry from this date a month / three
///   months / a year ago. Delegates to Wave C's [selectTimeMachineAnchor]; it
///   does not own a lookup.
/// * **E2 weekly recap** — the themes, the Names met, one line you wrote.
/// * **E3 answered duʿā** — *"you asked for this four months ago."*
///
/// **No push.** `send-scheduled-notifications/index.ts:29` freezes
/// `COPY_VERSION` at `reel_v1` until the keep read, so none of this may grow a
/// notification template, a scheduled send, or a copy constant that reads like
/// one. Design §7 is explicit that the push half is worth scheduling
/// deliberately later rather than smuggling in now.
library;

import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_themes.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

// ---------------------------------------------------------------------------
// E1 — "On This Night"
// ---------------------------------------------------------------------------

/// A resurfaced entry plus how far back it came from.
class OnThisNight {
  const OnThisNight({required this.entry, required this.offsetDays});

  final SavedReflection entry;

  /// Nights between [entry] and today — 30, 90 or 365. Only ever one of the
  /// anchors, because [selectTimeMachineAnchor] matches exact days.
  final int offsetDays;
}

/// The journal-side "On This Night" card (E1), or null.
///
/// **Wave C already resurfaces this same anchor inside the muḥāsabah itself**
/// (`daily_loop_provider._persistMuhasabahEntry` → `state.timeMachineEntry`),
/// and this is deliberately not a second lookup: both call
/// [selectTimeMachineAnchor], which is the one place the exact-day rule, the
/// nearest-first ordering and the blank-text filter live. The difference between
/// the two surfaces is *when*, not *what*:
///
///   * C3 reveals it once, at the end of the night, and it is not on state
///     before completion — the reward for finishing.
///   * E1 shows it in the archive, where the entry was already reachable through
///     the calendar and the feed. Nothing is disclosed early, because nothing
///     here is hidden in the first place.
///
/// Returns null with no anchor, which is the whole experience for a user younger
/// than thirty-one days.
OnThisNight? resolveOnThisNight({
  required List<SavedReflection> entries,
  required String? todayLocalDay,
  List<int> offsets = muhasabahTimeMachineOffsets,
}) {
  if (todayLocalDay == null) return null;
  final today = parseLocalDayString(todayLocalDay);
  if (today == null) return null;
  final anchor = selectTimeMachineAnchor(entries, todayLocalDay,
      offsets: offsets);
  if (anchor == null) return null;
  final then = parseLocalDayString(anchor.entryLocalDay ?? '');
  if (then == null) return null;
  return OnThisNight(
    entry: anchor,
    offsetDays: today.difference(then).inDays,
  );
}

// ---------------------------------------------------------------------------
// E2 — the weekly recap
// ---------------------------------------------------------------------------

/// What the last week of writing amounted to.
class WeeklyRecap {
  const WeeklyRecap({
    required this.entryCount,
    required this.themes,
    required this.names,
    required this.oneLine,
  });

  /// Entries inside the window. Always >= [weeklyRecapMinEntries].
  final int entryCount;

  /// At most two, most-used first. Empty when nobody's words matched a bucket —
  /// which is common and fine; the recap still has a count, Names and a line.
  final List<String> themes;

  /// The Names met, most recent night first, de-duplicated.
  final List<String> names;

  /// One line the user wrote, verbatim. Empty when the week produced none.
  final String oneLine;
}

/// A recap needs at least two nights in it. One entry is not a week, and
/// summarising a single night back to its author is a mirror, not a recap.
const int weeklyRecapMinEntries = 2;

/// The recap window, in nights, counting today.
const int weeklyRecapWindowDays = 7;

/// The last [windowDays] nights, summarised — or null when there is not enough
/// in the window to be worth summarising.
///
/// **Why this replaces the lifetime theme line rather than sitting under it.**
/// `journal_screen` has always rendered *"You often turn to Allah with X"* from
/// the same buckets over the user's entire history. That line and this card
/// answer the same question at two resolutions, and stacking them puts two
/// theme claims one above the other — one of which is always the vaguer. The
/// recap wins when it exists; the lifetime line is the fallback for a journal
/// with no recent week.
WeeklyRecap? resolveWeeklyRecap({
  required List<SavedReflection> entries,
  required String? todayLocalDay,
  int windowDays = weeklyRecapWindowDays,
  int minEntries = weeklyRecapMinEntries,
}) {
  if (todayLocalDay == null) return null;
  final today = parseLocalDayString(todayLocalDay);
  if (today == null) return null;
  final firstDay = today.subtract(Duration(days: windowDays - 1));

  final window = <({SavedReflection entry, DateTime day})>[];
  for (final r in entries) {
    final day = parseLocalDayString(journalEntryDay(r) ?? '');
    if (day == null) continue;
    if (day.isBefore(firstDay) || day.isAfter(today)) continue;
    window.add((entry: r, day: day));
  }
  if (window.length < minEntries) return null;

  // Newest first, and stable: two entries on the same day keep the order the
  // caller handed them in, so the recap does not reshuffle between rebuilds.
  window.sort((a, b) => b.day.compareTo(a.day));

  final inWindow = window.map((w) => w.entry).toList();
  final names = <String>[];
  for (final r in inWindow) {
    final name = r.name.trim();
    if (name.isNotEmpty && !names.contains(name)) names.add(name);
  }

  return WeeklyRecap(
    entryCount: inWindow.length,
    themes: journalTopThemes(inWindow, limit: 2),
    names: names,
    oneLine: _longestLine(inWindow),
  );
}

// ── The Journal's cadence gate ─────────────────────────────────────────────
//
// [resolveWeeklyRecap] is a WINDOW rule, not a rhythm: it fires whenever two
// entries fall inside a ROLLING seven days, which for anyone writing regularly
// is *every single day*, with content that barely moves between one day and the
// next. That is the exact failure this library opens by naming — "a resurfacing
// feature that fires every day is a feed" — and the recap was the one resolver
// that had no rule keeping it quiet.
//
// The muḥāsabah completion screen does not need this. There the recap is
// already gated behind "the time machine did not answer" and behind having
// finished a night, so it is at most one a day and it is the reward for work
// just done. The **Journal** is a place people open to look for something, and
// a summary that is waiting there every time is wallpaper.

/// The SharedPreferences key holding the week the Journal last showed the
/// recap. Scope it with `supabaseSyncService.scopedKey` at the call site — two
/// accounts on one device do not share a cadence.
const String weeklyRecapLastWeekPrefsKey = 'journal_weekly_recap_last_week';

/// **At most one recap per calendar week**, and the alternative was considered.
///
/// The other candidate was a content fingerprint — show it again only when the
/// window's themes / Names / line actually changed. That is more expressive and
/// it is the wrong rule here, because for the user this is aimed at the content
/// changes *daily*: one new night shifts the count, usually adds a Name, and can
/// replace the quoted line. A fingerprint gate would therefore fire almost as
/// often as no gate at all, while being much harder to reason about — and it
/// would fire LEAST for the dormant user, who is the one person for whom a
/// resurfaced week is worth anything.
///
/// A calendar week is a rhythm the user can feel without being told about it: it
/// arrives, it is gone for a few days, it comes back. It also cannot get stuck.
/// The key is derived from today, never from stored state, so an unreadable,
/// corrupt or future-dated marker simply fails to match and the recap shows —
/// every failure mode is fail-OPEN.
///
/// Weeks start on Monday, arbitrarily but consistently: what matters is that the
/// boundary is fixed and the same one every week.
String? weeklyRecapWeekKey(String? localDay) {
  if (localDay == null) return null;
  final day = parseLocalDayString(localDay);
  if (day == null) return null;
  // `weekday` is 1 (Monday) … 7 (Sunday), and [parseLocalDayString] returns a
  // UTC midnight, so this subtraction cannot land at 23:00 the day before.
  return formatLocalDay(day.subtract(Duration(days: day.weekday - 1)));
}

/// Whether the Journal may give the recap its slot today.
///
/// [lastShownWeek] is whatever [weeklyRecapLastWeekPrefsKey] held — including
/// null (never shown) and garbage (a partial write, a schema that moved). All of
/// those are "not this week", so all of them show it.
bool weeklyRecapIsDue({
  required String? todayLocalDay,
  required String? lastShownWeek,
}) {
  final thisWeek = weeklyRecapWeekKey(todayLocalDay);
  // No resolvable day means no recap at all (every resolver above agrees), so
  // there is nothing to be due.
  if (thisWeek == null) return false;
  return lastShownWeek != thisWeek;
}

/// The day an entry belongs to: `entry_local_day` when it has one, the calendar
/// date of `saved_at` otherwise.
///
/// The fallback covers the two row shapes that carry no local day at all — every
/// entry written before Wave B, and every Reflect save, which is not a night.
/// It is the same fallback `journal_screen._entryForDay` uses for the calendar,
/// and it is approximate in the same way: `saved_at` is written from a *local*
/// `DateTime.toIso8601String()`, so its first ten characters are the local
/// calendar date the user actually saw.
String? journalEntryDay(SavedReflection r) {
  final day = r.entryLocalDay;
  if (day != null && day.isNotEmpty) return day;
  if (r.date.length < 10) return null;
  return r.date.substring(0, 10);
}

/// The longest single line in the window, most recent first on a tie.
///
/// A *line*, not an entry: the recap promises "one line you wrote", and handing
/// back a six-paragraph answer under that lead is a different promise. Thread
/// appends are eligible — an append is the same kind of writing as the answer,
/// and it is often the more candid half of the night.
///
/// Longest rather than most recent, because the most recent line is frequently
/// *"nothing much today"* and the recap's job is to hand back something worth
/// having met again. [entries] arrives newest-first, and `>` (not `>=`) keeps
/// the first-seen winner, so recency breaks ties.
String _longestLine(List<SavedReflection> entries) {
  var best = '';
  for (final r in entries) {
    for (final raw in [
      ...r.userText.split('\n'),
      ...r.thread.map((t) => t.text),
    ]) {
      final line = raw.trim();
      if (line.length > best.length) best = line;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// E3 — the answered duʿā
// ---------------------------------------------------------------------------

/// An old, still-open built duʿā the user might want to mark answered.
class AnsweredDuaPrompt {
  const AnsweredDuaPrompt({required this.dua, required this.ageDays});

  final SavedBuiltDua dua;

  /// Nights since it was asked for.
  final int ageDays;

  /// *"four months"*, *"a year"* — the phrase the prompt is built around.
  String get elapsedLabel => describeDuaAge(ageDays);
}

/// A duʿā has to be genuinely old before the app asks. Thirty days is the floor
/// at which *"you asked for this a month ago"* is a true sentence and not a
/// receipt for something the user did last Tuesday.
const int answeredDuaMinAgeDays = 30;

/// The one duʿā to ask about, or null.
///
/// **Null is the normal answer, and that is the design.** This is the highest-
/// emotion mechanic in the app and the single easiest one to turn into a chore,
/// so four separate things keep it quiet:
///
///   1. only built duʿās — the ones the user wrote a need into. A hearted
///      catalogue duʿā was never a request they made;
///   2. only [answeredDuaMinAgeDays] old or more;
///   3. only one at a time, ever — the OLDEST, because that is the one the
///      sentence lands hardest for;
///   4. *"Not yet"* snoozes it, and a snoozed duʿā is invisible until its date
///      passes. Nothing is marked, nothing is counted, and the dismissal is a
///      local write with no server row and no analytics.
///
/// There is deliberately no badge, no count and no "3 duʿās to review".
AnsweredDuaPrompt? selectAnsweredDuaPrompt({
  required List<SavedBuiltDua> duas,
  required DateTime now,
  Map<String, DateTime> snoozedUntil = const {},
  int minAgeDays = answeredDuaMinAgeDays,
}) {
  AnsweredDuaPrompt? best;
  for (final d in duas) {
    if (d.status != builtDuaStatusOpen) continue;
    final snooze = snoozedUntil[d.id];
    if (snooze != null && snooze.isAfter(now)) continue;
    final savedAt = DateTime.tryParse(d.savedAt);
    if (savedAt == null) continue;
    final age = now.difference(savedAt).inDays;
    if (age < minAgeDays) continue;
    // Oldest wins. `>` keeps the first of two equally-old duʿās, and the list
    // order is the save order, so the tie-break is stable.
    if (best == null || age > best.ageDays) {
      best = AnsweredDuaPrompt(dua: d, ageDays: age);
    }
  }
  return best;
}

/// How long ago, in the words a person would use.
///
/// Rounded and vague on purpose: *"four months"* is what the design doc quotes
/// and what a user recognises. *"127 days"* is a log line, and precision here
/// reads as surveillance rather than memory.
String describeDuaAge(int days) {
  if (days < 45) return 'a month';
  if (days < 340) {
    final months = (days / 30.44).round().clamp(2, 11);
    return '${_numberWord(months)} months';
  }
  if (days < 550) return 'a year';
  final years = (days / 365.25).floor().clamp(2, 11);
  return '${_numberWord(years)} years';
}

String _numberWord(int n) => switch (n) {
      2 => 'two',
      3 => 'three',
      4 => 'four',
      5 => 'five',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
      10 => 'ten',
      _ => 'eleven',
    };

// ---------------------------------------------------------------------------
// Copy
// ---------------------------------------------------------------------------

/// Every user-facing string Wave E adds.
///
/// Apart from the widgets for the same reason `MuhasabahCompletionCopy` is: it
/// is the product decision, tests reference it verbatim, and it is the first
/// thing an i18n pass extracts. Latin script throughout — no string here is ever
/// concatenated with Arabic (CLAUDE.md).
abstract final class JournalResurfacingCopy {
  // ── E1 ──

  /// The card's own label. The lead sentence under it is
  /// `MuhasabahCompletionCopy.timeMachineLead`, reused verbatim rather than
  /// re-written: the same act reached from a second place must not acquire a
  /// second name, which is the rule "Add to tonight" already follows.
  static const String onThisNight = 'On this night';

  /// The tap affordance. Says where it goes, not what it is.
  static const String onThisNightOpen = 'Read that night';

  // ── E2 ──

  static const String recapHeader = 'Your last seven nights';

  static String recapCount(int entries) =>
      entries == 1 ? '1 entry' : '$entries entries';

  /// Lead-in above the resurfaced line. *"You wrote"* and nothing more — the
  /// force is that the words are the user's own.
  static const String recapOneLineLead = 'You wrote:';

  static const String recapNamesLead = 'Names you met:';

  // ── E2 as a story (2026-08-06) ──
  //
  // In the Journal the recap is no longer a block; it is a one-line door and
  // four screens behind it. The strings below are the story's, and the trailing
  // half of the door.

  /// What the line says AFTER the user's own words, and the order is the whole
  /// point: the quote earns the tap, *"your last seven nights"* is a filing
  /// category. Lower-case because it continues the sentence the quote started.
  static const String recapLineTrail = '— your last seven nights';

  /// The story's opening beat. Nights, not entries, is what a person counts a
  /// week in — and the count of ENTRIES is what the recap has, which is the same
  /// number until somebody writes twice in one day. [weeklyRecapWindowDays] and
  /// above collapses to *"every one of them"* rather than claim a number the
  /// window cannot hold.
  static String recapOpener(int entries) {
    if (entries <= 1) return 'Seven nights. You wrote on one of them.';
    if (entries >= weeklyRecapWindowDays) {
      return 'Seven nights. You wrote on every one of them.';
    }
    return 'Seven nights. You wrote on ${_numberWord(entries)} of them.';
  }

  /// The three body beats' small-caps labels. Statements of what the screen
  /// holds, in the second person, and none of them grades anything.
  static const String recapThemesLabel = 'What you carried';
  static const String recapNamesLabel = 'Names you met';
  static const String recapWordsLabel = 'In your words';

  // ── E3 ──

  /// The sentence the whole mechanic exists for (design §7).
  static String askedAgo(String elapsed) => 'You asked for this $elapsed ago.';

  /// Marking it. First person, past tense, and no claim about *why* — the user
  /// is recording their own gratitude, not the app adjudicating an outcome.
  static const String answeredAction = 'Alhamdulillah, this was answered';

  /// The other half, and it must be as easy to press as the first. A prompt
  /// with one button is a task.
  static const String notYetAction = 'Not yet';

  /// Under both buttons, so the card cannot read as an obligation. This is the
  /// line that keeps a duʿā from becoming a to-do item.
  static const String answeredFooter =
      'Nothing is owed here — only if it comes to mind.';

  /// The chip on a duʿā that has been marked.
  static const String answeredChip = 'Answered';

  /// Confirmation, shown once after marking. Warm, brief, and it does not
  /// congratulate the user for the answer.
  static const String answeredConfirmation = 'Marked. Alhamdulillah.';

  /// Undo, for the mis-tap. Reachable from the duʿā itself, not from a toast
  /// that vanishes.
  static const String answeredUndo = 'Mark as still open';
}
