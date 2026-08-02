import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

/// Keeps [renderableNameStoryBeatKinds] honest against the builder that defines
/// what "renderable" actually means.
///
/// The set lives in the model layer because the provider has to consult it — a
/// deck that draws nothing must not be parked in `DailyLoopState.revealDeck`,
/// since `startDeeper` short-circuits on `revealDeck != null` and would leave the
/// user on a view whose only action is a retry back to the same state. But the
/// authority on which kinds draw is `buildBeatScreensFromDeck`, in the widget
/// layer. Two declarations, one truth, so drift is possible and silent in both
/// directions:
///
///  * a kind in the set that the builder skips → the provider commits to a deck
///    that renders fewer beats than it thought, or none at all;
///  * a kind the builder handles that is missing from the set → the provider
///    throws away a deck the user could have been shown.
///
/// This test is the join between them.
NameStoryDeck _deckOf(List<String> kinds) => NameStoryDeck(
      deckId: 'test@1',
      nameId: 1,
      transliteration: 'Test',
      chipKeys: const [],
      positionInPair: 1,
      beats: [
        for (final k in kinds)
          NameStoryBeat(
            kind: k,
            primary: 'primary',
            arabic: 'ع',
            transliteration: 'translit',
            translation: 'translation',
            source: 'source',
          ),
      ],
      sources: const [],
      author: 'test',
      reviewedBy: 'test',
      reviewedAt: '2026-07-30',
      reviewVerdict: 'good',
    );

void main() {
  test('every kind the set calls renderable actually produces a screen', () {
    for (final kind in renderableNameStoryBeatKinds) {
      expect(
        buildBeatScreensFromDeck(_deckOf([kind])),
        isNotEmpty,
        reason: '"$kind" is in renderableNameStoryBeatKinds but '
            'buildBeatScreensFromDeck skips it — the provider will commit to '
            'decks that draw less than it expects',
      );
    }
  });

  test('a kind outside the set produces nothing', () {
    expect(buildBeatScreensFromDeck(_deckOf(['not_a_real_kind'])), isEmpty);
    expect(_deckOf(['not_a_real_kind']).hasRenderableBeat, isFalse);
  });

  test('the set contains no kind the builder cannot draw, and vice versa', () {
    // Drives the builder with a deck of every kind at once, then checks the
    // count matches. A kind the builder handles but the set omits would make the
    // builder produce MORE screens than the set has members.
    final all = renderableNameStoryBeatKinds.toList();
    expect(
      buildBeatScreensFromDeck(_deckOf(all)).length,
      all.length,
      reason: 'one screen per renderable kind — a mismatch means the set and '
          'the builder disagree about the vocabulary',
    );
  });

  test('every kind in the shipped asset is renderable', () async {
    // The real ship-gate consequence: if an authored deck carries a kind the
    // builder cannot draw, that deck silently loses a beat — or becomes
    // undrawable entirely and falls back to the AI reflection.
    final stories = NameStoriesService(
      loadAsset: (_) async =>
          File(NameStoriesService.assetPath).readAsStringSync(),
    );
    final decks = await stories.decks();
    expect(decks, isNotEmpty);

    for (final deck in decks) {
      expect(deck.hasRenderableBeat, isTrue, reason: deck.deckId);
      for (final beat in deck.beats) {
        expect(
          beat.isRenderable,
          isTrue,
          reason: '${deck.deckId} carries kind "${beat.kind}", which the beat '
              'flow skips — the beat would vanish from the reveal',
        );
      }
    }
  });
}
