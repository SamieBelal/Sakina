import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/help_chips.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/name_stories_service.dart';

/// One Ship W2-H §5 — the H5 chip set and the queue-rows-3-7 blend.
///
/// The same constraints `aspirations_test.dart` pulls forward from
/// `seed_name_queue`, because the blend feeds the same RPC: it raises
/// `check_violation` on a duplicate id anywhere in the 7, and every id is FK'd
/// to `collectible_names`. A sequence colliding with a chip pair would fail the
/// seed for exactly the users who chose that chip — a bug that only ever shows
/// up in production, for a subset.
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

  /// Every Name id reachable as queue position 1 or 2 — the union of all chip
  /// pairs, which by construction includes the comfort pair.
  Set<int> pairNameIds() => decks.map((d) => d.nameId).toSet();

  group('the chip set', () {
    test('is the seven the spec names, with stable unique keys', () {
      expect(helpChips, hasLength(7));
      final keys = helpChips.map((c) => c.key).toList();
      expect(keys.toSet(), hasLength(7));
      expect(keys, [
        'words',
        'sense',
        'daily',
        'less_alone',
        'closer',
        'names',
        'strength',
      ]);
      expect(helpChipsByKey.keys, containsAll(keys));
    });

    test('carries the two motives nothing else in the intake captured', () {
      // Reel 2's literal promise, and the sabr/endurance motive the old four
      // aspirations missed entirely.
      expect(helpChipsByKey['names']!.label, 'Learning His Names');
      expect(helpChipsByKey['strength']!.label, 'Strength to keep going');
    });

    test('the cap is stated, and the reassurance is one we can keep', () {
      expect(helpChipsMaxSelections, 3);
      // The second sentence is load-bearing copy: this ICP's fear ranking puts
      // failing at another thing near the top, so the screen has to take the
      // stakes off the pick.
      expect(helpChipsSublineLabel, contains('up to three'));
      expect(helpChipsSublineLabel, contains('meet the rest'));
      // It used to say "You can change this later", which was false: `helpWith`
      // has no settings surface and no consumer outside onboarding, so there is
      // nowhere in the shipped app to change it. Pinned negative so the promise
      // cannot return without the edit screen it promises.
      expect(helpChipsSublineLabel, isNot(contains('change this later')));
    });
  });

  group('the orderings', () {
    test('are exactly 5 internally-unique ids each', () {
      for (final chip in helpChips) {
        expect(chip.queueNameIds, hasLength(helpChipsQueueLength),
            reason: chip.key);
        expect(chip.queueNameIds.toSet(), hasLength(helpChipsQueueLength),
            reason: '${chip.key} repeats a Name — seed_name_queue would raise');
      }
    });

    test('collide with no chip pair (incl. the comfort pair)', () {
      final pairs = pairNameIds();
      // Guard the guard: an empty pairs set would pass vacuously and let a real
      // collision through.
      expect(pairs, hasLength(14));
      expect(pairs, containsAll(<int>[2, 36]), reason: 'the comfort pair');

      for (final chip in helpChips) {
        final clash = chip.queueNameIds.where(pairs.contains).toList();
        expect(clash, isEmpty,
            reason: '${chip.key} would duplicate pair Name(s) $clash in the '
                '7-id seed for whoever draws that pair');
      }
    });

    test('are pairwise disjoint across the seven chips', () {
      // Not a server constraint — the blend dedupes — but two chips sharing a
      // Name would spend a queue slot on something the user asked for twice,
      // and it is what makes the weighting assertion below meaningful.
      final seen = <int, String>{};
      for (final chip in helpChips) {
        for (final id in chip.queueNameIds) {
          expect(seen.containsKey(id), isFalse,
              reason: 'name id $id is in both ${seen[id]} and ${chip.key}');
          seen[id] = chip.key;
        }
      }
      expect(seen, hasLength(helpChips.length * helpChipsQueueLength));
    });

    test('every id exists in the catalog and has a Name anchor', () {
      expect(anchorSlugs, isNotEmpty);
      for (final chip in helpChips) {
        for (final id in chip.queueNameIds) {
          expect(catalogIds.contains(id), isTrue,
              reason: '${chip.key}: name id $id is not in the catalog');
          expect(id, isNot(1),
              reason: '${chip.key}: "Allah" has no anchor and is not a queue '
                  'Name');
        }
      }
    });
  });

  group('the blend', () {
    test('one selection degenerates to that chip\'s own five', () {
      for (final chip in helpChips) {
        expect(helpChipsQueueNameIds([chip.key]), chip.queueNameIds,
            reason: chip.key);
      }
    });

    test('caps at five however many chips are held', () {
      for (final keys in [
        ['words'],
        ['words', 'sense'],
        ['words', 'sense', 'strength'],
      ]) {
        final blend = helpChipsQueueNameIds(keys);
        expect(blend, hasLength(helpChipsQueueLength), reason: '$keys');
        expect(blend.toSet(), hasLength(helpChipsQueueLength),
            reason: '$keys has a duplicate id');
      }
    });

    test('weights by selection order — the first chip contributes most', () {
      final blend = helpChipsQueueNameIds(['words', 'sense', 'strength']);
      int from(String key) =>
          blend.where(helpChipsByKey[key]!.queueNameIds.contains).length;
      expect(from('words'), 2);
      expect(from('sense'), 2);
      expect(from('strength'), 1);
      // Reversing the order reverses who is short-changed, which is what makes
      // this a weighting rather than a set union.
      final reversed = helpChipsQueueNameIds(['strength', 'sense', 'words']);
      expect(reversed, isNot(blend));
      expect(reversed.first, helpChipsByKey['strength']!.queueNameIds.first);
    });

    test('is deterministic and order-stable', () {
      const keys = ['closer', 'daily'];
      expect(helpChipsQueueNameIds(keys), helpChipsQueueNameIds(keys));
    });

    test('returns empty — never an invented default — for no valid selection',
        () {
      expect(helpChipsQueueNameIds(const []), isEmpty);
      expect(helpChipsQueueNameIds(['productivity']), isEmpty);
    });

    test('ignores a repeated key rather than double-weighting it', () {
      // No selection UI can produce this; a restored prefs blob could.
      expect(
        helpChipsQueueNameIds(['words', 'words', 'sense']),
        helpChipsQueueNameIds(['words', 'sense']),
      );
    });

    test('honours the exclude set — the reel name_ids override case', () {
      final chip = helpChipsByKey['sense']!;
      final blend = helpChipsQueueNameIds(
        [chip.key],
        exclude: {chip.queueNameIds.first},
      );
      expect(blend, isNot(contains(chip.queueNameIds.first)));
      expect(blend.first, chip.queueNameIds[1]);
    });

    test('a full 7-id seed is unique for every chip pair × every blend',
        () async {
      final resolver = ProblemChipResolver(
        stories: NameStoriesService(
          loadAsset: (_) async =>
              File(NameStoriesService.assetPath).readAsStringSync(),
        ),
      );
      // Every 1-, 2- and 3-chip selection the cap allows, order included.
      final selections = <List<String>>[];
      for (final a in helpChips) {
        selections.add([a.key]);
        for (final b in helpChips) {
          if (b.key == a.key) continue;
          selections.add([a.key, b.key]);
          for (final c in helpChips) {
            if (c.key == a.key || c.key == b.key) continue;
            selections.add([a.key, b.key, c.key]);
          }
        }
      }

      for (final chip in problemChips) {
        final pair = await resolver.pairNameIdsForChip(chip.chipKey);
        expect(pair, hasLength(2), reason: chip.chipKey);
        for (final selection in selections) {
          final seed = [...pair, ...helpChipsQueueNameIds(selection)];
          expect(seed, hasLength(7), reason: '${chip.chipKey}/$selection');
          expect(seed.toSet(), hasLength(7),
              reason: '${chip.chipKey}/$selection has a duplicate id');
        }
      }
    });
  });
}
