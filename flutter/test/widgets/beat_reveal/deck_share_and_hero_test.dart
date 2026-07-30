import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';
import 'package:sakina/widgets/share_card.dart';

/// Table tests over the REAL shipped decks for the two places a wrong assumption
/// silently costs authored content: the Name hero's meaning line, and the verse
/// a share card quotes.
///
/// Both bugs these pin were shipped and caught in review, and both were the same
/// mistake — reasoning about the content instead of reading it. A table over the
/// asset is the cheap guard.
void main() {
  final service = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  NameStoryBeat? beatOf(NameStoryDeck deck, String kind) {
    for (final b in deck.beats) {
      if (b.kind == kind) return b;
    }
    return null;
  }

  group('the Name hero drops its meaning only on an exact match', () {
    test('an identical meaning is dropped; a longer one survives', () async {
      final decks = await service.decks();
      final wakeel = decks.firstWhere((d) => d.transliteration == 'Al-Wakeel');
      final salam = decks.firstWhere((d) => d.transliteration == 'As-Salam');

      BeatScreen heroOf(NameStoryDeck d, String? shown) =>
          buildBeatScreensFromDeck(d, meaningAlreadyShown: shown)
              .firstWhere((s) => s.kind == BeatKind.name);

      // As-Salam's card and deck agree, so the repetition is real and goes.
      expect(heroOf(salam, 'The Source of Serenity').source, isEmpty);

      // Al-Wakeel's do NOT agree: the card says "The Trustee", the deck adds
      // "— the Guardian you hand your affairs to". A boolean flag deleted that
      // clause on the D1 Name. Comparing keeps it.
      final wakeelHero = heroOf(wakeel, 'The Trustee');
      expect(wakeelHero.source, 'The Trustee — the Guardian you hand your affairs to');
    });

    test('the Arabic and transliteration always survive', () async {
      for (final deck in await service.decks()) {
        final meaning = beatOf(deck, 'name_intro')!.primary;
        final hero = buildBeatScreensFromDeck(deck, meaningAlreadyShown: meaning)
            .firstWhere((s) => s.kind == BeatKind.name);
        expect(hero.arabic, isNotEmpty, reason: deck.deckId);
        // Without this a reader who cannot read Arabic cannot identify the Name.
        expect(hero.label, isNotEmpty, reason: deck.deckId);
        expect(hero.source, isEmpty, reason: deck.deckId);
      }
    });

    test('passing nothing preserves the full hero for every deck', () async {
      for (final deck in await service.decks()) {
        final hero = buildBeatScreensFromDeck(deck)
            .firstWhere((s) => s.kind == BeatKind.name);
        expect(hero.source, beatOf(deck, 'name_intro')!.primary,
            reason: '${deck.deckId} — the default must not change onboarding');
      }
    });
  });

  group('the share card quotes the deck', () {
    test("every deck's card takes that Name's OWN verse, not a comfort verse",
        () async {
      for (final deck in await service.decks()) {
        final own = beatOf(deck, 'verse');
        expect(own, isNotNull, reason: '${deck.deckId} has no verse beat');

        // Ar-Rahman is the case that matters: its comfort_verse sits at index 1
        // and its own verse at index 7, so a positional search over both kinds
        // put 2:286 under a heading about encompassing mercy.
        final comfort = beatOf(deck, 'comfort_verse');
        if (comfort != null) {
          expect(deck.beats.indexOf(comfort) < deck.beats.indexOf(own!), isTrue,
              reason: '${deck.deckId} — this deck is only interesting if the '
                  'comfort verse comes FIRST; otherwise the test proves nothing');
        }
      }
    });

    test('every deck yields a non-empty quote and citation', () async {
      for (final deck in await service.decks()) {
        final verse = beatOf(deck, 'verse') ?? beatOf(deck, 'comfort_verse');
        expect(verse!.primary.trim(), isNotEmpty, reason: deck.deckId);
        expect(shareableVerseSource(verse.source).trim(), isNotEmpty,
            reason: deck.deckId);
        // The hero and the Arabic both come from name_intro.
        expect(beatOf(deck, 'name_intro')!.arabic, isNotEmpty,
            reason: deck.deckId);
      }
    });
  });

  group('shareableVerseSource', () {
    test('strips reviewer provenance notes', () {
      expect(shareableVerseSource("Qur'an 42:19 (the Name in-text)"),
          "Qur'an 42:19");
      expect(shareableVerseSource("Qur'an 2:37 (Name in-text)"), "Qur'an 2:37");
      expect(
        shareableVerseSource(
            "Qur'an 58:1 (revealed for a woman whose complaint the person in the same room could not hear)"),
        "Qur'an 58:1",
      );
    });

    test('keeps accuracy qualifiers — a short quote must not read as whole', () {
      // 39:53 genuinely is partial and the quoted text carries no ellipsis, so
      // dropping "(excerpt)" would present it as the complete ayah.
      expect(shareableVerseSource("Qur'an 39:53 (excerpt)"),
          "Qur'an 39:53 (excerpt)");
      expect(shareableVerseSource("Qur'an 1:1 (partial)"), "Qur'an 1:1 (partial)");
    });

    test('leaves plain citations and ranges intact', () {
      expect(shareableVerseSource("Qur'an 65:2-3"), "Qur'an 65:2-3");
      expect(shareableVerseSource("Qur'an 7:156"), "Qur'an 7:156");
      expect(shareableVerseSource(''), '');
    });

    test('no shipped citation is left carrying a reviewer note', () async {
      for (final deck in await service.decks()) {
        final verse = beatOf(deck, 'verse') ?? beatOf(deck, 'comfort_verse');
        final out = shareableVerseSource(verse!.source);
        if (out.contains('(')) {
          // The only parentheses that may survive are accuracy qualifiers.
          expect(out.toLowerCase(), contains('excerpt'), reason: deck.deckId);
        }
      }
    });
  });
}
