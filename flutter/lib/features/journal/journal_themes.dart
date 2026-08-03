/// The Journal's theme buckets — one keyword map, two readers.
///
/// This lived as a private `_themeBuckets` constant plus a private `_topTheme`
/// inside `journal_screen.dart`, where it fed the lifetime insight line
/// (*"You often turn to Allah with Anxiety & Worry"*). Wave E's weekly recap
/// needs exactly the same classification over a seven-night window, and a second
/// copy of a keyword list is a copy that silently disagrees with the first the
/// moment either gains a word. So the list moved out here and both read it.
///
/// **What this is not.** It is not the taxonomy Wave F needs (plan §F6): that
/// one has to be anchored in a citable published classification because it makes
/// claims about which Names belong together. This one makes no claim about
/// anything except which words the *user* used, so it needs no attribution — and
/// it must never be promoted into the other job without one.
library;

import 'package:sakina/features/reflect/providers/reflect_provider.dart';

/// Theme label → the words that put an entry in it. Substring matching, so
/// `worry` also catches `worried`; the explicit inflections are the ones a stem
/// would miss.
const Map<String, List<String>> journalThemeBuckets = <String, List<String>>{
  'Anxiety & Worry': [
    'anxious',
    'anxiety',
    'stressed',
    'stress',
    'worry',
    'worried',
    'nervous',
    'fear',
    'scared',
    'overwhelmed',
    'panic'
  ],
  'Relationships': [
    'family',
    'friend',
    'friends',
    'wife',
    'husband',
    'mother',
    'father',
    'parents',
    'sister',
    'brother',
    'relationship',
    'people',
    'nosy',
    'marriage'
  ],
  'Work & Career': [
    'job',
    'work',
    'career',
    'business',
    'money',
    'salary',
    'boss',
    'interview',
    'study',
    'school',
    'exam',
    'university'
  ],
  'Sadness & Grief': [
    'sad',
    'sadness',
    'grief',
    'loss',
    'lost',
    'cry',
    'crying',
    'depressed',
    'depression',
    'lonely',
    'alone',
    'hurt'
  ],
  'Gratitude': [
    'grateful',
    'gratitude',
    'thankful',
    'blessed',
    'blessing',
    'alhamdulillah',
    'happy',
    'joy',
    'peace'
  ],
  'Guidance': [
    'confused',
    'decision',
    'istikhara',
    'guidance',
    'direction',
    'know',
    'should',
    'proceed',
    'unsure',
    'doubt'
  ],
};

/// How many of [entries] fall in each theme. An entry counts once per theme at
/// most (the inner loop breaks), so a paragraph that says "worried" four times
/// does not outvote four separate nights.
Map<String, int> journalThemeCounts(List<SavedReflection> entries) {
  final counts = <String, int>{};
  for (final r in entries) {
    final text = r.userText.toLowerCase();
    for (final bucket in journalThemeBuckets.entries) {
      for (final keyword in bucket.value) {
        if (text.contains(keyword)) {
          counts[bucket.key] = (counts[bucket.key] ?? 0) + 1;
          break;
        }
      }
    }
  }
  return counts;
}

/// The [limit] most-used themes, most-used first.
///
/// Ties break on the bucket's declaration order rather than on hash order, so
/// the same journal always produces the same recap — a summary that reshuffles
/// between two equally-true answers on every rebuild reads as noise.
List<String> journalTopThemes(
  List<SavedReflection> entries, {
  int limit = 2,
}) {
  final counts = journalThemeCounts(entries);
  if (counts.isEmpty) return const [];
  final ordered = journalThemeBuckets.keys.where(counts.containsKey).toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return ordered.take(limit).toList();
}

/// The single dominant theme, or null when there is nothing to say.
///
/// [minEntries] guards the lifetime insight line: one word in one entry is not
/// a pattern, and stating it as one is the kind of over-claim that costs a
/// reflective surface its credibility.
String? journalTopTheme(
  List<SavedReflection> entries, {
  int minEntries = 3,
}) {
  if (entries.length < minEntries) return null;
  final top = journalTopThemes(entries, limit: 1);
  return top.isEmpty ? null : top.first;
}
