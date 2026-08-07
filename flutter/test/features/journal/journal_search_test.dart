// Journal search — the matching rule (2026-08-06).
//
// The archive shipped with filters and no search. Filters answer "which KIND of
// thing"; the question that actually keeps a long journal is "where is the night
// I wrote about my father", and nothing on the screen could answer it. This file
// pins the rule that now does.
//
// Two properties are load-bearing and neither is obvious from reading
// `journal_search.dart`:
//
//   * **tokens are AND-ed, not substring-matched.** People type what they
//     remember in the order they remember it. `hospital dad` has to find "my dad
//     is in hospital" — a raw substring match finds nothing, and finding nothing
//     is what teaches someone the search is broken.
//   * **the AI body is NOT searched.** Every entry's reframe says Allah, heart,
//     mercy, trust. Folding it in would make `mercy` return the entire journal,
//     which is indistinguishable from having no search at all.
//
// MUTATION: add `r.reframe` to `reflectionSearchText` → the precision group
// fails and names the word that started matching everything.

import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_search.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';

SavedReflection _entry({
  String id = 'e1',
  String userText = '',
  String name = 'Al-Hadi',
  String nameArabic = 'الهادي',
  String reframe = '',
  String story = '',
  List<ReflectionThreadEntry> thread = const [],
  String azm = '',
}) =>
    SavedReflection(
      id: id,
      date: '2026-08-01T21:00:00Z',
      userText: userText,
      name: name,
      nameArabic: nameArabic,
      reframePreview: reframe,
      reframe: reframe,
      story: story,
      thread: thread,
      azm: azm,
    );

void main() {
  group('tokenising', () {
    test(
        'a blank query produces no tokens, which every caller reads as '
        '"not searching"', () {
      expect(journalSearchTokens(''), isEmpty);
      expect(journalSearchTokens('   '), isEmpty);
      expect(journalSearchTokens('\n\t '), isEmpty);
    });

    test('splits on any run of whitespace and lowercases', () {
      expect(journalSearchTokens('  Dad   HOSPITAL\tnight '),
          ['dad', 'hospital', 'night']);
    });

    test(
        'nothing matches an empty token list — an empty query must return the '
        'prompt, never every entry', () {
      final r = _entry(userText: 'anything at all');
      expect(reflectionMatchesSearch(r, journalSearchTokens('')), isFalse);
    });
  });

  group('recall — the searches people actually type', () {
    final r = _entry(
      userText: 'my dad is in hospital and I have not slept',
      name: 'Al-Shafi',
    );

    test('finds a word from the middle of the entry', () {
      expect(
          reflectionMatchesSearch(r, journalSearchTokens('hospital')), isTrue);
    });

    test(
        'finds several words in ANY order — the whole reason tokens are '
        'AND-ed rather than matched as one substring', () {
      expect(reflectionMatchesSearch(r, journalSearchTokens('hospital dad')),
          isTrue);
      expect(reflectionMatchesSearch(r, journalSearchTokens('dad hospital')),
          isTrue);
    });

    test(
        'a word that is not there fails the whole query, however many of the '
        'others matched', () {
      expect(
          reflectionMatchesSearch(r, journalSearchTokens('dad hospital money')),
          isFalse);
    });

    test('is case-insensitive on both sides', () {
      expect(
          reflectionMatchesSearch(r, journalSearchTokens('HOSPITAL')), isTrue);
      expect(
          reflectionMatchesSearch(
              _entry(userText: 'HOSPITAL'), journalSearchTokens('hospital')),
          isTrue);
    });

    test(
        'matches a partial word — someone searching `sleep` should find '
        '"slept" without knowing the inflection they used', () {
      expect(reflectionMatchesSearch(r, journalSearchTokens('slep')), isTrue);
    });

    test('finds the Name, in English and in Arabic', () {
      expect(reflectionMatchesSearch(r, journalSearchTokens('shafi')), isTrue);
      expect(
          reflectionMatchesSearch(
              _entry(nameArabic: 'الهادي'), journalSearchTokens('الهادي')),
          isTrue);
    });

    test(
        'unvowelled Arabic finds the vowelled catalogue spelling — which is '
        'the only way anyone types Arabic on a phone', () {
      final vowelled = _entry(nameArabic: 'الصَّبُور');
      expect(reflectionMatchesSearch(vowelled, journalSearchTokens('الصبور')),
          isTrue);
    });

    test(
        'finds an "add to tonight" append — a line written at 1am is no less '
        'the user\'s own words for having arrived late', () {
      final r = _entry(
        userText: 'a quiet day',
        thread: const [
          ReflectionThreadEntry(at: '', text: 'I called my sister after all'),
        ],
      );
      expect(reflectionMatchesSearch(r, journalSearchTokens('sister')), isTrue);
    });

    test('finds the night\'s azm', () {
      final r = _entry(userText: 'a quiet day', azm: 'call her tomorrow');
      expect(
          reflectionMatchesSearch(r, journalSearchTokens('tomorrow')), isTrue);
    });
  });

  group('precision — what is deliberately NOT searched', () {
    // The AI body is the same register on every entry. If it were in the
    // haystack, these queries would return the whole journal.
    final r = _entry(
      userText: 'work has been heavy',
      reframe: 'Allah is the One who holds what your heart cannot, with mercy.',
      story: 'The companions rose. The Prophet did not.',
    );

    test('the reframe is not matched', () {
      expect(reflectionMatchesSearch(r, journalSearchTokens('mercy')), isFalse);
      expect(reflectionMatchesSearch(r, journalSearchTokens('holds')), isFalse);
    });

    test('the story is not matched', () {
      expect(reflectionMatchesSearch(r, journalSearchTokens('companions')),
          isFalse);
    });

    test(
        'the user\'s own words in the SAME entry still are — this is a rule '
        'about which field, never about which entry', () {
      expect(reflectionMatchesSearch(r, journalSearchTokens('heavy')), isTrue);
    });
  });

  group('duas — the artifact IS the content, so the content is searched', () {
    const built = SavedBuiltDua(
      id: 'b1',
      savedAt: '2026-08-01T21:00:00Z',
      need: 'my mother is unwell',
      arabic: 'اللهم اشفها',
      transliteration: 'Allahumma ishfiha',
      translation: 'O Allah, heal her.',
    );

    const related = SavedRelatedDua(
      id: 'r1',
      title: 'Dua for anxiety',
      arabic: 'اللهم إني أعوذ بك من الهم',
      transliteration: 'Allahumma inni a\'udhu bika min al-hamm',
      translation: 'O Allah, I seek refuge in You from anxiety and grief.',
      source: 'Bukhari 6369',
    );

    test('a built dua matches on the need the user typed', () {
      expect(
          builtDuaMatchesSearch(built, journalSearchTokens('mother')), isTrue);
    });

    test('a built dua matches on its translation', () {
      expect(builtDuaMatchesSearch(built, journalSearchTokens('heal')), isTrue);
    });

    test(
        'a saved related dua carries NO user words at all, so a rule that '
        'only looked at those would make every one unfindable', () {
      expect(relatedDuaSearchText(related), isNotEmpty);
      expect(relatedDuaMatchesSearch(related, journalSearchTokens('anxiety')),
          isTrue);
      expect(relatedDuaMatchesSearch(related, journalSearchTokens('bukhari')),
          isTrue);
    });

    test('a dua that does not match stays out', () {
      expect(
          builtDuaMatchesSearch(built, journalSearchTokens('rent')), isFalse);
      expect(relatedDuaMatchesSearch(related, journalSearchTokens('rent')),
          isFalse);
    });
  });

  group('normalisation is applied to BOTH sides', () {
    test(
        'collapsing whitespace on one side only would silently break every '
        'multi-space entry', () {
      final r = _entry(userText: 'the  rent   is  due');
      expect(reflectionMatchesSearch(r, journalSearchTokens('rent is due')),
          isTrue);
    });

    test('normalizeForSearch is idempotent', () {
      const raw = '  The   RENT is Due  ';
      expect(
          normalizeForSearch(normalizeForSearch(raw)), normalizeForSearch(raw));
    });
  });
}
