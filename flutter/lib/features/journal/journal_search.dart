/// Journal search — the matching rule, as a pure function.
///
/// ## Why this exists
///
/// The archive shipped with filters and no search. Filters answer *"show me the
/// nightly ones"*; they cannot answer *"what did I write when my father was in
/// hospital"*, and that second question is the only reason a long journal is
/// worth keeping. It is also the failure that turns the heaviest users into
/// churners — the ones with the most entries are precisely the ones for whom
/// scrolling stops working, and *"if I can't find my notes, why type all this
/// in"* is the review that follows.
///
/// ## What is searched, and what deliberately is not
///
/// **A reflection matches on the user's own words and on the Name** — the
/// answer, every "add to tonight" append, the night's ʿazm, and the Name in
/// English and Arabic. It does **not** match on the reframe, the story, the
/// takeaway, the verses or the duʿā.
///
/// That is not an oversight and it is not about cost. The AI body is the same
/// register on every entry: it says *Allah*, *heart*, *mercy* and *trust* on all
/// of them. Folding it into the haystack would mean a search for `mercy`
/// returning three hundred nights, which is indistinguishable from no search at
/// all. The words the user typed are the ones that differ between one night and
/// the next, so they are the ones that can locate a night.
///
/// **A duʿā matches on its content** — including the Arabic, the transliteration
/// and the source. The asymmetry is deliberate and follows from the same
/// principle: for a reflection the artifact is what you wrote, and for a saved
/// duʿā the artifact IS the duʿā. There are no user words on a saved related
/// duʿā at all, so a rule that only looked at those would make every one of them
/// permanently unfindable.
library;

import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// Arabic combining marks: tashkīl (fatḥa…sukūn and the Qurʾānic marks),
/// superscript alif, and the tajwīd annotations.
///
/// Stripped from BOTH the query and the haystack so a user who types
/// `الصبور` — which is how anyone actually types Arabic on a phone — still finds
/// `الصَّبُور`, which is how the catalogue stores it. Without this the Arabic
/// half of the index is reachable only by someone willing to key in the
/// vowelling exactly.
///
/// Written as escapes rather than as literal glyphs. A range typed out in
/// Arabic looks innocent and silently swallows U+0660-U+0669 — the Arabic-Indic
/// DIGITS — because they sit inside the obvious-looking span. Spelling the
/// endpoints out is what makes the deliberate gap visible.
final RegExp _arabicDiacritics =
    RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]');

final RegExp _whitespace = RegExp(r'\s+');

/// Lowercased, unvowelled, single-spaced. Applied identically to the query and
/// to every field it is matched against — normalising only one side is how a
/// search box quietly stops matching half its own index.
String normalizeForSearch(String value) => value
    .toLowerCase()
    .replaceAll(_arabicDiacritics, '')
    .replaceAll(_whitespace, ' ')
    .trim();

/// The query, split into the terms that must ALL appear.
///
/// AND across whitespace-separated tokens rather than one substring match on the
/// whole query, because people type what they remember in the order they
/// remember it and the entry rarely contains that exact phrase. `hospital dad`
/// finds *"my dad is in hospital"*; a raw substring match finds nothing, and
/// finding nothing is what teaches someone the search does not work.
///
/// Order-independent and duplicate-tolerant. Returns empty for a blank query,
/// which every caller reads as "not searching".
List<String> journalSearchTokens(String query) {
  final normalized = normalizeForSearch(query);
  if (normalized.isEmpty) return const [];
  return normalized.split(' ').where((t) => t.isNotEmpty).toList();
}

/// Every token present somewhere in [haystack], which must already be
/// normalised.
bool _matchesAll(String haystack, List<String> tokens) {
  for (final token in tokens) {
    if (!haystack.contains(token)) return false;
  }
  return true;
}

/// The searchable text of a reflection: what the user wrote, plus the Name.
///
/// The thread and the ʿazm are in here because they are the same act of writing
/// as the answer — a line added at 1am is no less the user's own words for
/// having arrived late, and leaving it out would make the appends the one thing
/// in the journal that cannot be found again.
String reflectionSearchText(SavedReflection r) => normalizeForSearch([
      r.userText,
      for (final entry in r.thread) entry.text,
      r.azm,
      r.name,
      r.nameArabic,
    ].join(' '));

String builtDuaSearchText(SavedBuiltDua d) => normalizeForSearch([
      d.need,
      d.arabic,
      d.transliteration,
      d.translation,
    ].join(' '));

String relatedDuaSearchText(SavedRelatedDua d) => normalizeForSearch([
      d.title,
      d.arabic,
      d.transliteration,
      d.translation,
      d.source,
    ].join(' '));

bool reflectionMatchesSearch(SavedReflection r, List<String> tokens) =>
    tokens.isNotEmpty && _matchesAll(reflectionSearchText(r), tokens);

bool builtDuaMatchesSearch(SavedBuiltDua d, List<String> tokens) =>
    tokens.isNotEmpty && _matchesAll(builtDuaSearchText(d), tokens);

bool relatedDuaMatchesSearch(SavedRelatedDua d, List<String> tokens) =>
    tokens.isNotEmpty && _matchesAll(relatedDuaSearchText(d), tokens);
