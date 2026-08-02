import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/services/name_stories_service.dart';

/// One Ship W2-B1 — the chip taxonomy, the free-text keyword map, and the
/// derivation of Name pairs from the approved decks.
///
/// Pair ids are read through the REAL asset (via the loader seam, so this stays
/// a plain VM test): a resolver that agrees with a fixture but disagrees with
/// the decks we ship would reveal the wrong Names.
void main() {
  NameStoriesService realService() => NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      );

  group('taxonomy', () {
    test('is exactly the 7 approved chips with the sign chip last', () {
      expect(problemChips, hasLength(7));
      expect(
        problemChips.map((c) => c.chipKey).toList(),
        ['anxiety', 'heavy', 'guilt', 'far-from-allah', 'rizq', 'unseen', 'sign'],
      );
      expect(problemChips.last.chipKey, 'sign');
      expect(problemChips.last.contract, HookContract.sign);
      expect(
        problemChips.where((c) => c.contract == HookContract.problem),
        hasLength(6),
      );
    });

    test('labels are the approved sentences', () {
      expect(problemChipsByKey['anxiety']!.label, "My mind won't stop racing");
      expect(problemChipsByKey['heavy']!.label, 'Everything feels heavy');
      expect(
        problemChipsByKey['guilt']!.label,
        'I keep sinning and going back',
      );
      expect(
        problemChipsByKey['far-from-allah']!.label,
        'I feel far from Allah',
      );
      expect(
        problemChipsByKey['rizq']!.label,
        "I'm worried about money / providing",
      );
      expect(
        problemChipsByKey['unseen']!.label,
        "No one sees what I'm carrying",
      );
    });

    test('problem categories are stable snake_case, unique per chip', () {
      final categories = problemChips.map((c) => c.problemCategory).toList();
      expect(categories.toSet(), hasLength(categories.length));
      for (final c in categories) {
        expect(RegExp(r'^[a-z_]+$').hasMatch(c), isTrue, reason: c);
      }
    });
  });

  group('OnboardingFlow', () {
    test('is exactly the two wire values the column accepts', () {
      expect(OnboardingFlow.reelV1, 'reel_v1');
      expect(OnboardingFlow.legacy, 'legacy');
      expect(OnboardingFlow.values, {'reel_v1', 'legacy'});
    });
  });

  group('free-text keyword map', () {
    void mapsTo(String chipKey, List<String> phrases) {
      for (final p in phrases) {
        expect(matchChipKeyForText(p), chipKey, reason: '"$p"');
      }
    }

    test('the research note\'s required term families reach a chip', () {
      // family / marriage / exams / sleep / grief — the benched topics that
      // free text MUST still route somewhere sensible.
      mapsTo('heavy', [
        'my family is falling apart',
        'constant fighting at home with my parents',
        'my mother passed away last month',
        'I am grieving',
      ]);
      mapsTo('unseen', [
        'I want to get married and it is not happening',
        'my marriage is lonely',
        'nobody knows what I go through',
      ]);
      mapsTo('anxiety', [
        'my exams start next week',
        'I cannot sleep at night',
        'insomnia every night',
        'university is too much',
      ]);
    });

    test('each chip is reachable from its own vocabulary', () {
      mapsTo('anxiety', ['I feel so anxious', 'panic attacks', 'overthinking']);
      mapsTo('heavy', ['I feel hopeless', 'so depressed lately']);
      mapsTo('guilt', ['I keep relapsing', 'the shame of my sins']);
      mapsTo('far-from-allah', [
        'I feel far from Allah',
        'my iman is low',
        'I keep missing salah',
      ]);
      mapsTo('rizq', ['I cannot pay rent', 'drowning in debt', 'lost my job']);
      mapsTo('unseen', ['I am so alone', 'no one checks on me']);
    });

    test('ordering rules disambiguate the overlaps', () {
      // rizq before heavy: "lost my job" is provision, not grief.
      expect(matchChipKeyForText('I lost my job last week'), 'rizq');
      // guilt before far-from-allah: the return cycle is the named problem.
      expect(
        matchChipKeyForText('I feel far from Allah because I keep sinning'),
        'guilt',
      );
      // unseen before anxiety: marriage longing is not a racing mind.
      expect(
        matchChipKeyForText('worried I will never find a spouse'),
        'unseen',
      );
    });

    test('matches whole tokens and phrases, never substrings', () {
      expect(matchChipKeyForText('I made a salad'), isNull);
      expect(matchChipKeyForText('sinner'), isNull);
      expect(matchChipKeyForText('sin'), 'guilt');
    });

    test('normalizes case, apostrophes and punctuation', () {
      expect(matchChipKeyForText("I CAN'T SLEEP!!!"), 'anxiety');
      expect(matchChipKeyForText('I can’t sleep.'), 'anxiety');
    });

    test('unmatched and empty text return null', () {
      expect(matchChipKeyForText(''), isNull);
      expect(matchChipKeyForText('   '), isNull);
      expect(matchChipKeyForText('qwerty zxcvb'), isNull);
    });

    test('evaluation order is the disambiguation rule — pin it explicitly', () {
      // First hit wins, so the key order IS the routing policy. Reordering this
      // map silently re-routes real sentences; changing it should have to
      // change this line too.
      expect(
        problemChipKeywords.keys.toList(),
        ['guilt', 'far-from-allah', 'rizq', 'unseen', 'anxiety', 'heavy'],
      );
    });

    test('ambient devotional and relational words do not hijack the sentence',
        () {
      // 'praying' / 'prayers' / 'faith' left far-from-allah on 2026-07-26: they
      // fire on sentences whose actual problem is somewhere else entirely.
      expect(matchChipKeyForText('I keep praying for a job'), 'rizq');
      expect(matchChipKeyForText('praying for my exams'), 'anxiety');
      // ...and 'disconnected' with them: it is ambient, not devotional.
      expect(
        matchChipKeyForText('I feel disconnected from my wife'),
        'unseen',
      );
      // The register terms that DO name the problem stayed.
      mapsTo('far-from-allah', [
        'I keep missing salah',
        'my iman is gone',
        'I feel empty inside',
        'just going through the motions',
        'I feel like a hypocrite',
        'I am not consistent with anything',
      ]);
    });

    test('the terms the reviewer found missing now route', () {
      expect(matchChipKeyForText('I am so tired'), 'heavy');
      mapsTo('anxiety', ['the waswas will not stop', 'constant waswasa']);
    });
  });

  group('pair derivation from the approved decks', () {
    late ProblemChipResolver resolver;

    setUp(() => resolver = ProblemChipResolver(stories: realService()));

    test('all 7 chips derive a two-deck pair, ordered Name₁ then Name₂',
        () async {
      final seen = <String, List<int>>{};
      for (final chip in problemChips) {
        final ids = await resolver.pairNameIdsForChip(chip.chipKey);
        expect(ids, hasLength(2), reason: chip.chipKey);
        expect(ids[0], isNot(ids[1]), reason: chip.chipKey);
        seen[chip.chipKey] = ids;
      }
      // Spot-check against the approved pair table (As-Salam + Al-Wakeel).
      expect(seen['anxiety'], [6, 35]);
      expect(seen['sign'], [2, 36]);
    });

    test('a chip tap carries its contract, category and pair', () async {
      final sel = await resolver.forChip('guilt');
      expect(sel.chipKey, 'guilt');
      expect(sel.contract, HookContract.problem);
      expect(sel.problemCategory, 'guilt');
      expect(sel.hookType, HookType.chip);
      expect(sel.pairNameIds, [11, 31]);
      expect(sel.problemTextRaw, isNull);
    });

    test('the sign chip is the only sign contract', () async {
      final sel = await resolver.forChip('sign');
      expect(sel.contract, HookContract.sign);
      expect(sel.problemCategory, 'unspoken');
    });

    test('an off-taxonomy chip key is a programming error', () async {
      expect(
        () => resolver.forChip('family'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('matched free text resolves the matched chip pair, keeps the text',
        () async {
      final sel = await resolver.forFreeText('  my exams start monday  ');
      expect(sel.chipKey, 'anxiety');
      expect(sel.problemCategory, 'anxiety');
      expect(sel.hookType, HookType.freeText);
      expect(sel.contract, HookContract.problem);
      expect(sel.pairNameIds, [6, 35]);
      expect(sel.problemTextRaw, 'my exams start monday');
    });

    test('unmatched free text falls back to the comfort pair as "unmatched"',
        () async {
      final sel = await resolver.forFreeText('qwerty zxcvb');
      expect(sel.chipKey, isNull,
          reason: 'the comfort fallback must not claim the sign chip');
      expect(sel.problemCategory, problemCategoryUnmatched);
      expect(sel.contract, HookContract.problem,
          reason: 'typed words never make the sign claim');
      expect(sel.pairNameIds, [2, 36]);
      expect(sel.problemTextRaw, 'qwerty zxcvb');
    });

    test('a chip missing half its pair falls back to the comfort pair',
        () async {
      // What the runtime sees once the ship gate drops an unapproved deck:
      // guilt keeps only Name₁, so it must NOT reveal half a pair.
      final halved = ProblemChipResolver(
        stories: NameStoriesService(loadAsset: (_) async => _fixture),
      );
      expect(await halved.pairNameIdsForChip('guilt'), [2, 36]);
      final sel = await halved.forChip('guilt');
      expect(sel.pairNameIds, [2, 36]);
      expect(sel.problemCategory, 'guilt',
          reason: 'the fallback swaps the Names, never what the user said');
    });

    test('unresolvedForChip keeps everything the tap said, minus the pair', () {
      final sel = resolver.unresolvedForChip('guilt');
      expect(sel.chipKey, 'guilt');
      expect(sel.contract, HookContract.problem);
      expect(sel.problemCategory, 'guilt');
      expect(sel.hookType, HookType.chip);
      expect(sel.pairNameIds, isEmpty);
    });

    test('unresolvedForFreeText still runs the (pure) keyword match', () {
      final sel = resolver.unresolvedForFreeText('  my exams start monday  ');
      expect(sel.chipKey, 'anxiety');
      expect(sel.problemCategory, 'anxiety');
      expect(sel.hookType, HookType.freeText);
      expect(sel.problemTextRaw, 'my exams start monday');
      expect(sel.pairNameIds, isEmpty);
    });

    test('an uncovered comfort pair yields no ids rather than half a pair',
        () async {
      final empty = ProblemChipResolver(
        stories: NameStoriesService(loadAsset: (_) async => '[]'),
      );
      expect(await empty.pairNameIdsForChip('anxiety'), isEmpty);
      expect(await empty.pairNameIdsForChip('sign'), isEmpty);
    });
  });
}

/// Sign pair complete, guilt pair missing its Name₂.
const String _fixture = '''
[
  {"deck_id":"al-ghaffar@1","name_id":11,"transliteration":"Al-Ghaffar",
   "chip_keys":["guilt"],"position_in_pair":1,"beats":[],"sources":[],
   "author":"t","reviewed_by":"t","reviewed_at":"2026-07-25","review_verdict":"good"},
  {"deck_id":"ar-rahman@1","name_id":2,"transliteration":"Ar-Rahman",
   "chip_keys":["sign"],"position_in_pair":1,"beats":[],"sources":[],
   "author":"t","reviewed_by":"t","reviewed_at":"2026-07-25","review_verdict":"good"},
  {"deck_id":"al-lateef@1","name_id":36,"transliteration":"Al-Lateef",
   "chip_keys":["sign"],"position_in_pair":2,"beats":[],"sources":[],
   "author":"t","reviewed_by":"t","reviewed_at":"2026-07-25","review_verdict":"good"}
]
''';
