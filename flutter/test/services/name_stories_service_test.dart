import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/name_stories_service.dart';

/// One Ship W2-A1 — the deck loader.
///
/// Reads the REAL shipped asset (through the injectable seam, so the test is a
/// plain VM test) — a loader that passes against a fixture but not against the
/// content we ship would be worthless.
void main() {
  String realAsset() =>
      File(NameStoriesService.assetPath).readAsStringSync();

  NameStoriesService serviceFor(String raw) =>
      NameStoriesService(loadAsset: (_) async => raw);

  group('NameStoriesService (real asset)', () {
    late NameStoriesService service;

    setUp(() => service = serviceFor(realAsset()));

    test('loads every approved deck', () async {
      final decks = await service.decks();

      // Counted from the asset, not hardcoded. The literal 14 that used to sit
      // here was really two claims wearing one number: "the loader drops
      // nothing" (the point of this test) and "there are 14 decks" (a fact
      // about content that changes every batch). Only the first belongs here,
      // and pinning the second meant a content-only change turned this file
      // red for a reason that had nothing to do with the loader.
      final rawCount = (jsonDecode(realAsset()) as List).length;
      expect(rawCount, greaterThan(0), reason: 'the asset itself is empty');
      expect(decks, hasLength(rawCount),
          reason: 'the loader dropped a deck the asset carries');

      expect(decks.every((d) => d.reviewVerdict == 'good'), isTrue);
    });

    test('decksForChip returns the pair ordered Name₁ then Name₂', () async {
      final pair = await service.decksForChip('anxiety');
      expect(pair.map((d) => d.deckId).toList(), ['as-salam@1', 'al-wakeel@1']);
      expect(pair.map((d) => d.positionInPair).toList(), [1, 2]);
      expect(pair.first.nameId, 6);
      expect(pair.first.transliteration, 'As-Salam');
    });

    test('every rendered chip resolves to a complete pair', () async {
      for (final chip in const [
        'anxiety',
        'far-from-allah',
        'guilt',
        'heavy',
        'rizq',
        'sign',
        'unseen',
      ]) {
        final pair = await service.decksForChip(chip);
        expect(pair, hasLength(2), reason: 'chip "$chip" pair incomplete');
      }
    });

    test('an unknown chip resolves to nothing (caller falls back)', () async {
      expect(await service.decksForChip('no-such-chip'), isEmpty);
    });

    test('comfortPair is the sign pair — the unmatched-free-text fallback',
        () async {
      final comfort = await service.comfortPair();
      expect(comfort.map((d) => d.deckId).toList(),
          ['ar-rahman@1', 'al-lateef@1']);
      expect(comfort, await service.decksForChip('sign'));
    });

    test('deckForName finds by catalog id, null when absent', () async {
      expect((await service.deckForName(36))?.deckId, 'al-lateef@1');
      // Absent means OUT OF RANGE, not "an id that happens to be undecked".
      // This used to assert `deckForName(99)` was null, which held only while
      // some of the 99 Names had no deck. The 2026-08-05 merge took coverage to
      // 99/99 and the assertion became false — it was testing the state of the
      // catalogue, not the lookup. The catalogue is 1-99, so 0 can never
      // resolve and the invariant survives the next wave too. (Same lesson the
      // test below already records about pinning deck ids literally.)
      expect(await service.deckForName(0), isNull);
      expect(await service.deckForName(1000), isNull);
    });

    test('sorting never mutates the shared cache', () async {
      // Snapshot the cache order BEFORE the sorting call, so an in-place sort
      // inside decksForChip shows up as a diff rather than as agreement with a
      // hardcoded deck id. The ids used to be pinned literally here, which made
      // this test fail every time a wave added a deck that sorts near the top —
      // churn that says nothing about the invariant the test is named for.
      final before = (await service.decks()).map((d) => d.deckId).toList();
      final first = (await service.decksForChip('sign')).map((d) => d.deckId);
      final after = (await service.decks()).map((d) => d.deckId).toList();
      expect(first, ['ar-rahman@1', 'al-lateef@1']);
      expect(after, before);
    });
  });

  group('runtime defenses', () {
    test('a deck whose verdict is not "good" never loads', () async {
      final decks =
          jsonDecode(realAsset()) as List<dynamic>; // mutate a copy in memory
      (decks.firstWhere((d) => d['deck_id'] == 'al-wakeel@1')
          as Map<String, dynamic>)['review_verdict'] = 'needs_work';
      final service =
          NameStoriesService(loadAsset: (_) async => jsonEncode(decks));

      expect((await service.decks()).map((d) => d.deckId),
          isNot(contains('al-wakeel@1')));
      // …and the half-pair is visible to the caller, which falls back.
      expect(await service.decksForChip('anxiety'), hasLength(1));
    });

    test('the asset is decoded once and cached', () async {
      var loads = 0;
      final raw = realAsset();
      final service = NameStoriesService(loadAsset: (_) async {
        loads++;
        return raw;
      });

      await Future.wait([
        service.decks(),
        service.decksForChip('guilt'),
        service.comfortPair(),
      ]);
      await service.deckForName(6);

      expect(loads, 1);
    });
  });
}
