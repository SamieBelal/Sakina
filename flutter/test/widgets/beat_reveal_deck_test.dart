import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/models/name_story_deck.dart';
import 'package:sakina/services/name_stories_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

/// One Ship W2-A3 — the deck-native path through the beat spine.
///
/// Built against the REAL shipped decks: the mapping's whole job is to render
/// the content we ship, and the asset's per-kind field usage (see the table on
/// [NameStoryBeat]) is exactly what a fixture would paper over.
void main() {
  final service = NameStoriesService(
    loadAsset: (_) async =>
        File(NameStoriesService.assetPath).readAsStringSync(),
  );

  Future<NameStoryDeck> deck(String id) async =>
      (await service.decks()).firstWhere((d) => d.deckId == id);

  group('buildBeatScreensFromDeck', () {
    test('maps the standard spine in the deck\'s own order', () async {
      final screens = buildBeatScreensFromDeck(await deck('as-salam@1'));
      expect(screens.map((s) => s.kind).toList(), [
        BeatKind.keyLine, // bridge
        BeatKind.name, // name_intro
        BeatKind.story,
        BeatKind.story,
        BeatKind.story,
        BeatKind.verse,
        BeatKind.dua,
        BeatKind.takeaway, // pair synergy
      ]);
    });

    test('the sign deck opens on recognition then the comfort verse', () async {
      final screens = buildBeatScreensFromDeck(await deck('ar-rahman@1'));
      expect(screens.take(3).map((s) => s.kind).toList(),
          [BeatKind.recognition, BeatKind.comfortVerse, BeatKind.keyLine]);
      expect(screens.first.primary, startsWith("You didn't find this"));
      // The comfort verse carries translation + citation (no Arabic in this
      // deck) — never both scripts in one field.
      expect(screens[1].label, contains('does not charge a soul'));
      expect(screens[1].source, "Qur'an 2:286");
      expect(screens[1].primary, isEmpty);
    });

    test('the Name hero takes arabic/transliteration/meaning, not the '
        'provenance label', () async {
      final hero = buildBeatScreensFromDeck(await deck('as-salam@1'))
          .firstWhere((s) => s.kind == BeatKind.name);
      expect(hero.arabic, 'السَّلَامُ');
      expect(hero.label, 'As-Salam'); // transliteration, NOT the editorial note
      expect(hero.source, 'The Source of Serenity');
      expect(hero.label, isNot(contains('verbatim')));
    });

    test('story beats keep their title and citation', () async {
      final stories = buildBeatScreensFromDeck(await deck('as-salam@1'))
          .where((s) => s.kind == BeatKind.story)
          .toList();
      expect(stories.every((s) => s.label == 'The Cave'), isTrue);
      expect(stories.first.primary, contains('hid in a cave'));
    });

    test('the duʿa lands in the standalone fields, translation from primary',
        () async {
      final dua = buildBeatScreensFromDeck(await deck('as-salam@1'))
          .firstWhere((s) => s.kind == BeatKind.dua);
      expect(dua.dua, isNull); // no ReflectResponse on the deck path
      expect(dua.duaArabic, startsWith('اللَّهُمَّ'));
      expect(dua.duaTransliteration, startsWith('Allahumma Antas-Salam'));
      expect(dua.duaTranslation, startsWith('O Allah, You are Peace'));
      // …and the effective getters resolve without a response behind them.
      expect(dua.duaArabicText, dua.duaArabic);
      expect(dua.duaTranslationText, dua.duaTranslation);
      expect(dua.semanticText, contains('O Allah, You are Peace'));
    });

    test('a verse with Arabic puts it on primary and the translation on label',
        () async {
      final verse = buildBeatScreensFromDeck(await deck('al-lateef@1'))
          .firstWhere((s) => s.kind == BeatKind.verse);
      expect(verse.primary, isNotEmpty); // Arabic
      expect(verse.label, 'Allah is Ever Kind to His servants.');
      expect(verse.source, startsWith("Qur'an 42:19"));
    });

    test('includePairSynergy:false drops the Name₂-naming takeaway', () async {
      final d = await deck('as-salam@1');
      final without = buildBeatScreensFromDeck(d, includePairSynergy: false);
      expect(without.where((s) => s.kind == BeatKind.takeaway), isEmpty);
      expect(without, hasLength(buildBeatScreensFromDeck(d).length - 1));
      // Name₂ decks carry no synergy beat, so the flag changes nothing there.
      final n2 = await deck('al-wakeel@1');
      expect(buildBeatScreensFromDeck(n2, includePairSynergy: false).length,
          buildBeatScreensFromDeck(n2).length);
    });

    test('every shipped deck maps end-to-end with no dropped beats', () async {
      for (final d in await service.decks()) {
        final screens = buildBeatScreensFromDeck(d);
        expect(screens, hasLength(d.beats.length),
            reason: '${d.deckId} lost a beat in the mapping');
        expect(screens.where((s) => s.kind == BeatKind.dua), hasLength(1),
            reason: '${d.deckId} must have exactly one duʿa screen');
      }
    });
  });

  group('beat_kind wire names', () {
    test('keyLine keeps its historical value; new kinds are snake_case', () {
      expect(BeatKind.keyLine.wireName, 'keyLine');
      expect(BeatKind.comfortVerse.wireName, 'comfort_verse');
      expect(BeatKind.recognition.wireName, 'recognition');
    });

    test('the pre-existing single-word kinds are unchanged', () {
      for (final kind in const [
        BeatKind.name,
        BeatKind.reframe,
        BeatKind.story,
        BeatKind.verse,
        BeatKind.takeaway,
        BeatKind.dua,
      ]) {
        expect(kind.wireName, kind.name);
      }
    });
  });

  group('BeatRevealFlow driven by pre-built screens', () {
    testWidgets('renders a deck and reaches its duʿa with the Ameen pill',
        (t) async {
      final screens = buildBeatScreensFromDeck(await deck('as-salam@1'));
      var ameens = 0;

      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: null,
          screens: screens,
          onAmeen: () => ameens++,
        ),
      ));
      await t.pumpAndSettle();

      expect(find.textContaining('there is a Name'), findsOneWidget);

      // Skip straight to the duʿa: it must render its text, not a blank screen
      // (the standalone-fields fix — a deck screen has no ReflectResponse).
      await t.tap(find.text('Skip to duʿa'));
      await t.pumpAndSettle();
      expect(find.textContaining('O Allah, You are Peace'), findsOneWidget);
      expect(find.textContaining('Allahumma Antas-Salam'), findsOneWidget);

      await t.tap(find.text('Ameen'));
      await t.pump(); // enter the completion beat
      await t.pump(const Duration(milliseconds: 1200)); // delayed exit fires
      expect(ameens, 1);
      // Dispose the tree so the completion-beat animation leaves no pending
      // timer at teardown (the app pops the route here).
      await t.pumpWidget(const SizedBox());
    });
  });
}
