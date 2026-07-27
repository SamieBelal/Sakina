import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/aspirations.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/name_stories_service.dart';

/// One Ship W2-C2a — the aspiration → queue-rows-3-7 map.
///
/// These are the constraints `seed_name_queue` enforces server-side, pulled
/// forward into CI: the RPC raises `check_violation` on a duplicate id anywhere
/// in the 7, and every id is FK'd to `collectible_names`. A sequence that
/// collides with a chip pair would therefore fail the seed for exactly the
/// users who chose that chip — a bug that would only ever show up in
/// production, for a subset.
void main() {
  late Set<int> catalogIds;
  late Set<String> anchorSlugs;
  late List<NameStoryDeck> decks;

  setUpAll(() async {
    catalogIds = (jsonDecode(
                File('assets/content/collectible_names.json').readAsStringSync())
            as List<dynamic>)
        .map((n) => (n as Map<String, dynamic>)['id'] as int)
        .toSet();
    anchorSlugs = (jsonDecode(
                File('assets/content/name_anchors.json').readAsStringSync())
            as List<dynamic>)
        .map((a) => (a as Map<String, dynamic>)['name_key'] as String)
        .toSet();
    decks = await NameStoriesService(
      loadAsset: (_) async =>
          File(NameStoriesService.assetPath).readAsStringSync(),
    ).decks();
  });

  /// Every Name id reachable as a queue position 1 or 2 — the union of all
  /// chip pairs, which by construction includes the comfort pair.
  Set<int> pairNameIds() => decks.map((d) => d.nameId).toSet();

  test('the taxonomy is 5 options with stable, unique keys', () {
    expect(aspirations, hasLength(5));
    expect(aspirations.map((a) => a.key).toSet(), hasLength(5));
    expect(aspirationsByKey.keys, containsAll(aspirations.map((a) => a.key)));
  });

  test('every sequence is exactly 5 internally-unique ids', () {
    for (final a in aspirations) {
      expect(a.queueNameIds, hasLength(5), reason: a.key);
      expect(a.queueNameIds.toSet(), hasLength(5),
          reason: '${a.key} repeats a Name — seed_name_queue would raise');
    }
  });

  test('no sequence collides with any chip pair (incl. the comfort pair)', () {
    final pairs = pairNameIds();
    // Guard the guard: if the pairs set were empty this test would pass
    // vacuously and let a real collision through.
    expect(pairs, hasLength(14));
    expect(pairs, containsAll(<int>[2, 36]), reason: 'the comfort pair');

    for (final a in aspirations) {
      final clash = a.queueNameIds.where(pairs.contains).toList();
      expect(clash, isEmpty,
          reason: '${a.key} would duplicate pair Name(s) $clash in the 7-id '
              'seed for whoever draws that pair');
    }
  });

  test('every id exists in the catalog and has a Name anchor', () {
    // Slugs in name_anchors.json are lowercase-hyphenated Latin renderings;
    // matching by id → transliteration → slug would re-implement the
    // translation table in name_anchors_coverage_test. Every catalog Name
    // except id 1 (Allah) carries an anchor, so the coverage assertion here is
    // simply that no sequence reaches for id 1.
    expect(anchorSlugs, isNotEmpty);
    for (final a in aspirations) {
      for (final id in a.queueNameIds) {
        expect(catalogIds.contains(id), isTrue,
            reason: '${a.key}: name id $id is not in collectible_names.json');
        expect(id, isNot(1),
            reason: '${a.key}: "Allah" has no anchor and is not a queue Name');
      }
    }
  });

  test('a full 7-id seed is unique for every chip × aspiration combination',
      () async {
    final resolver = ProblemChipResolver(
      stories: NameStoriesService(
        loadAsset: (_) async =>
            File(NameStoriesService.assetPath).readAsStringSync(),
      ),
    );
    for (final chip in problemChips) {
      final pair = await resolver.pairNameIdsForChip(chip.chipKey);
      expect(pair, hasLength(2), reason: chip.chipKey);
      for (final a in aspirations) {
        final seed = [...pair, ...a.queueNameIds];
        expect(seed, hasLength(7), reason: '${chip.chipKey}/${a.key}');
        expect(seed.toSet(), hasLength(7),
            reason: '${chip.chipKey}/${a.key} has a duplicate id');
      }
    }
  });

  test('the sign register is a distinct phrasing, never the problem label', () {
    for (final a in aspirations) {
      expect(a.signLabel, isNotEmpty, reason: a.key);
      expect(a.signLabel, isNot(a.label), reason: a.key);
      expect(aspirationLabelFor(a, HookContract.sign), a.signLabel);
      expect(aspirationLabelFor(a, HookContract.problem), a.label);
      expect(aspirationLabelFor(a, null), a.label);
    }
    expect(aspirationQuestionFor(HookContract.sign),
        aspirationQuestionSignLabel);
    expect(aspirationQuestionFor(HookContract.problem), aspirationQuestionLabel);
  });

  group('aspirationQueueNameIds', () {
    test('returns the answered option\'s five', () {
      expect(aspirationQueueNameIds('closeness'),
          aspirationsByKey['closeness']!.queueNameIds);
    });

    test('returns empty — never an invented default — when unanswered', () {
      expect(aspirationQueueNameIds(null), isEmpty);
      expect(aspirationQueueNameIds(''), isEmpty);
      expect(aspirationQueueNameIds('productivity'), isEmpty);
    });
  });
}
