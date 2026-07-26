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
      expect(decks, hasLength(14));
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
      expect(await service.deckForName(99), isNull);
    });

    test('sorting never mutates the shared cache', () async {
      final first = (await service.decksForChip('sign')).map((d) => d.deckId);
      final all = (await service.decks()).map((d) => d.deckId).toList();
      expect(first, ['ar-rahman@1', 'al-lateef@1']);
      // The cached list keeps its asset order (sign decks are 11th and 12th).
      expect(all.first, 'as-salam@1');
      expect(all[10], 'ar-rahman@1');
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
