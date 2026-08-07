import 'dart:convert';
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

  // ---------------------------------------------------------------------
  // Wave 4 — the swap seam.
  //
  // `selection` names, per deck beat kind, an already-resolved variant id. The
  // seam exists so a selector service can swap the two personalisable beats
  // without the builder learning any policy; the tests below pin what the
  // builder is allowed to do with the id and, far more importantly, what it
  // must keep doing when nobody passes one.
  group('buildBeatScreensFromDeck · selection', () {
    /// Every field of a screen, flattened so a failure names the field that
    /// moved rather than reporting two opaque objects as unequal.
    Map<String, Object?> shot(BeatScreen s) => {
          'kind': s.kind.wireName,
          'label': s.label,
          'primary': s.primary,
          'source': s.source,
          'arabic': s.arabic,
          'hasResponse': s.dua != null,
          'duaArabic': s.duaArabic,
          'duaTransliteration': s.duaTransliteration,
          'duaTranslation': s.duaTranslation,
          'duaSource': s.duaSource,
          'semanticText': s.semanticText,
        };

    List<Map<String, Object?>> shots(List<BeatScreen> screens) =>
        screens.map(shot).toList();

    // The raw asset, parsed independently of the model layer. The point of the
    // regression test is to re-derive today's output from the CONTENT rather
    // than from the code under test — a golden dumped from the builder would
    // agree with any bug the builder learns, and a mirrored copy of 99 decks'
    // prose in a fixture is the duplicated-content failure this repo has
    // already paid for more than once.
    late List<Map<String, dynamic>> raw;
    setUpAll(() {
      raw = (jsonDecode(File(NameStoriesService.assetPath).readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>()
          .where((d) => d['review_verdict'] == 'good')
          .toList();
    });

    String f(Map<String, dynamic> beat, String key) =>
        (beat[key] ?? '') as String;

    /// What the beat spine has ALWAYS produced for a deck: every field derived
    /// straight from the beat's own `primary`/`arabic`/… fields, with `variants`
    /// not consulted at all. This is the definition of "today's output" that the
    /// null-selection contract is measured against.
    List<Map<String, Object?>> expectedFromAsset(Map<String, dynamic> deck) {
      final out = <Map<String, Object?>>[];
      Map<String, Object?> screen({
        required String kind,
        String label = '',
        String primary = '',
        String source = '',
        String arabic = '',
        String duaArabic = '',
        String duaTransliteration = '',
        String duaTranslation = '',
        String duaSource = '',
      }) =>
          shot(BeatScreen(
            kind: BeatKind.values.firstWhere((k) => k.wireName == kind),
            label: label,
            primary: primary,
            source: source,
            arabic: arabic,
            duaArabic: duaArabic,
            duaTransliteration: duaTransliteration,
            duaTranslation: duaTranslation,
            duaSource: duaSource,
          ));

      for (final b in (deck['beats'] as List).cast<Map<String, dynamic>>()) {
        switch (b['kind'] as String) {
          case 'bridge':
            out.add(screen(kind: 'keyLine', primary: f(b, 'primary')));
          case 'recognition':
            out.add(screen(kind: 'recognition', primary: f(b, 'primary')));
          case 'name_intro':
            out.add(screen(
              kind: 'name',
              arabic: f(b, 'arabic'),
              label: f(b, 'transliteration'),
              source: f(b, 'primary'),
            ));
          case 'story':
            out.add(screen(
              kind: 'story',
              label: f(b, 'label'),
              primary: f(b, 'primary'),
              source: f(b, 'source'),
            ));
          case 'verse':
          case 'comfort_verse':
            out.add(screen(
              kind: b['kind'] == 'verse' ? 'verse' : 'comfort_verse',
              primary: f(b, 'arabic'),
              label: f(b, 'primary'),
              source: f(b, 'source'),
            ));
          case 'dua':
            out.add(screen(
              kind: 'dua',
              duaArabic: f(b, 'arabic'),
              duaTransliteration: f(b, 'transliteration'),
              duaTranslation: f(b, 'primary'),
              duaSource: f(b, 'source'),
            ));
          case 'takeaway':
          case 'reflection':
            out.add(screen(kind: 'takeaway', primary: f(b, 'primary')));
          default:
            continue;
        }
      }
      return out;
    }

    test('THE CONTRACT: selection:null renders every one of the 99 decks '
        'exactly as the asset\'s own `primary` fields say, variants ignored',
        () async {
      final decks = await service.decks();
      expect(decks, hasLength(raw.length));
      expect(decks, hasLength(99), reason: 'the shipped deck count moved');

      for (final d in decks) {
        final json = raw.firstWhere((r) => r['deck_id'] == d.deckId);
        final expected = expectedFromAsset(json);
        // Both the default call and an explicit null, because the three live
        // call sites use the first and a selector under construction will use
        // the second.
        for (final actual in [
          shots(buildBeatScreensFromDeck(d)),
          shots(buildBeatScreensFromDeck(d, selection: null)),
        ]) {
          expect(actual, hasLength(expected.length),
              reason: '${d.deckId} changed its screen COUNT');
          for (var i = 0; i < expected.length; i++) {
            expect(actual[i], expected[i],
                reason: '${d.deckId} screen $i drifted from the asset');
          }
        }
      }
    });

    test('…and not one of the authored variants reaches a screen unasked',
        () async {
      // Belt to the contract's braces, and it is the assertion that would fail
      // LOUDLY if the default ever flipped to "personalise unless told not to".
      // Also proves the corpus is non-empty: a suite that passes because the
      // variants vanished from the asset is not evidence of anything.
      final variantTexts = <String>{};
      for (final d in raw) {
        for (final b in (d['beats'] as List).cast<Map<String, dynamic>>()) {
          for (final v in ((b['variants'] ?? const []) as List)
              .cast<Map<String, dynamic>>()) {
            variantTexts.add((v['text'] ?? '') as String);
          }
        }
      }
      expect(variantTexts.length, greaterThan(700),
          reason: 'the authored variant corpus is missing — this test would '
              'then pass vacuously');

      for (final d in await service.decks()) {
        for (final s in buildBeatScreensFromDeck(d)) {
          expect(variantTexts.contains(s.primary), isFalse,
              reason: '${d.deckId} rendered variant text with no selection');
        }
      }
    });

    test('the model parses variants without the builder reading them', () async {
      final withVariants = (await service.decks())
          .expand((d) => d.beats)
          .where((b) => b.variants.isNotEmpty)
          .toList();
      expect(withVariants, isNotEmpty);
      expect(withVariants.map((b) => b.kind).toSet(), {'bridge', 'reflection'},
          reason: 'the ship gate forbids variants on any other kind');
      expect(withVariants.every((b) => b.variants.every((v) => v.id.isNotEmpty)),
          isTrue);
      // The lookup is total: null, an unknown id and a real id are the only
      // three cases, and two of them answer `primary`.
      final b = withVariants.first;
      expect(b.textForVariant(null), b.primary);
      expect(b.textForVariant('not_a_real_id'), b.primary);
      expect(b.textForVariant(b.variants.first.id), b.variants.first.text);
    });

    /// The first deck that OPENS on a `bridge` carrying variants, with that
    /// beat's first variant. Opening on the bridge is what lets these tests
    /// address the screen as `first` — the sign deck prepends two beats.
    Future<(NameStoryDeck, NameStoryBeatVariant)> deckWithBridgeVariant() async {
      for (final d in await service.decks()) {
        final b = d.beats.first;
        if (b.kind == 'bridge' && b.variants.isNotEmpty) {
          return (d, b.variants.first);
        }
      }
      fail('no shipped deck opens on a bridge carrying variants');
    }

    test('a selection naming a real id swaps that beat and only that beat',
        () async {
      final (d, variant) = await deckWithBridgeVariant();
      final before = shots(buildBeatScreensFromDeck(d));
      final after =
          shots(buildBeatScreensFromDeck(d, selection: {'bridge': variant.id}));

      expect(after, hasLength(before.length));
      final swapped = <int>[];
      for (var i = 0; i < before.length; i++) {
        // Encoded, because Dart's `Map ==` is identity: comparing the shots
        // directly reports every screen as changed and the assertion below
        // would then be measuring nothing.
        if (jsonEncode(after[i]) != jsonEncode(before[i])) swapped.add(i);
      }
      expect(swapped, hasLength(1), reason: 'exactly the bridge screen moves');
      expect(after[swapped.single]['kind'], 'keyLine');
      expect(after[swapped.single]['primary'], variant.text);
      expect(before[swapped.single]['primary'], isNot(variant.text));
    });

    // NOTE ON NAMING: this asserts what the SEAM can express, not what the
    // product does. The founder settled selection as PAIRED on 2026-08-05 — one
    // category id resolves both beats, because both come from a single answer,
    // and a deck that opened in `guilt` and closed in `rizq` would read as two
    // readings of one input. Wave 5's selector is what enforces that; the map
    // stays general so paired-vs-independent never becomes a signature change.
    test('the seam can address the two personalisable beats separately — '
        'different ids, the same id, or only one of them', () async {
      // A deck that OPENS on its bridge (the sign deck prepends two beats) and
      // carries variants on both slots, so `first`/`last` name the two beats
      // under test.
      final deck = (await service.decks()).firstWhere(
        (d) =>
            d.beats.first.kind == 'bridge' &&
            d.beats.first.variants.isNotEmpty &&
            d.beats.last.kind == 'reflection' &&
            d.beats.last.variants.isNotEmpty,
      );
      final bridge = deck.beats.firstWhere((b) => b.kind == 'bridge');
      final reflection = deck.beats.firstWhere((b) => b.kind == 'reflection');

      // Only the reflection named: the bridge must still read its `primary`.
      final reflectionOnly = buildBeatScreensFromDeck(deck,
          selection: {'reflection': reflection.variants.first.id});
      expect(reflectionOnly.first.primary, bridge.primary);
      expect(reflectionOnly.last.primary, reflection.variants.first.text);

      // Both named, with different ids — the shape the "paired vs independent"
      // decision is still open on (plan §7). The seam must not presume.
      final both = buildBeatScreensFromDeck(deck, selection: {
        'bridge': bridge.variants.first.id,
        'reflection': reflection.variants.first.id,
      });
      expect(both.first.primary, bridge.variants.first.text);
      expect(both.last.primary, reflection.variants.first.text);
    });

    test('an id the beat does not carry falls back to primary', () async {
      final (d, _) = await deckWithBridgeVariant();
      expect(
        shots(buildBeatScreensFromDeck(d, selection: {'bridge': 'no_such_id'})),
        shots(buildBeatScreensFromDeck(d)),
      );
      // …and the no-variants case, which is the MAIN path, not an edge case:
      // every deck that has not been through the variant backfill renders its
      // `primary` no matter what it is asked for. Synthetic on purpose — the
      // shipped asset currently has variants on all 99 bridges, so the only way
      // to exercise the pre-backfill shape is to build one.
      const bare = NameStoryDeck(
        deckId: 'bare@1',
        nameId: 1,
        transliteration: 'Bare',
        chipKeys: [],
        positionInPair: 1,
        beats: [NameStoryBeat(kind: 'bridge', primary: 'The authored line.')],
        sources: [],
        author: 'test',
        reviewedBy: 'test',
        reviewedAt: '2026-08-05',
        reviewVerdict: 'good',
      );
      expect(
        buildBeatScreensFromDeck(bare, selection: {'bridge': 'anxiety'})
            .single
            .primary,
        'The authored line.',
      );
    });

    test('a selection naming a non-personalisable kind changes nothing',
        () async {
      const meddling = {
        'verse': 'anxiety',
        'comfort_verse': 'anxiety',
        'dua': 'anxiety',
        'name_intro': 'anxiety',
        'story': 'anxiety',
        'takeaway': 'anxiety',
        'recognition': 'anxiety',
        'not_a_kind': 'anxiety',
      };
      for (final d in await service.decks()) {
        expect(shots(buildBeatScreensFromDeck(d, selection: meddling)),
            shots(buildBeatScreensFromDeck(d)),
            reason: '${d.deckId} let a selection reach a scripture beat');
      }
    });

    test('selection composes with the existing flags without disturbing them',
        () async {
      final (d, variant) = await deckWithBridgeVariant();
      final trimmed = buildBeatScreensFromDeck(d,
          includePairSynergy: false, selection: {'bridge': variant.id});
      expect(trimmed.first.primary, variant.text);
      final synergyBeats = d.beats.where((b) => b.isPairSynergy).length;
      expect(trimmed,
          hasLength(buildBeatScreensFromDeck(d).length - synergyBeats));
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
    testWidgets('renders a deck and reaches its duʿa with its text intact',
        (t) async {
      final screens = buildBeatScreensFromDeck(await deck('as-salam@1'));

      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: null,
          screens: screens,
          onAmeen: () {},
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
      // …and its citation, now that dua beats carry one.
      expect(find.textContaining('Sahih Muslim 591'), findsOneWidget);
    });

    testWidgets('a real deck can be walked to its last beat and completed',
        (t) async {
      // A deck ends `…dua → takeaway`, so the completion CTA cannot key on the
      // duʿa: it belongs to the LAST beat or the user strands on the takeaway.
      final screens = buildBeatScreensFromDeck(await deck('as-salam@1'));
      expect(screens.last.kind, BeatKind.takeaway);
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

      final size = t.getSize(find.byType(BeatRevealFlow));
      for (var i = 1; i < screens.length; i++) {
        expect(find.text('Ameen'), findsNothing,
            reason: 'the pill must not appear before the last beat (at $i)');
        await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
        await t.pumpAndSettle();
      }

      expect(find.textContaining('As-Salam — peace itself'), findsOneWidget);
      await t.tap(find.text('Ameen'));
      await t.pump(); // enter the completion beat
      await t.pump(const Duration(milliseconds: 1200)); // delayed exit fires
      expect(ameens, 1);
      // Dispose the tree so the completion-beat animation leaves no pending
      // timer at teardown (the app pops the route here).
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('swapping the deck under a live flow restarts at beat 0',
        (t) async {
      final first = buildBeatScreensFromDeck(await deck('as-salam@1'));
      final shorter = buildBeatScreensFromDeck(await deck('al-wakeel@1'))
          .take(3)
          .toList();

      Widget flow(List<BeatScreen> screens) => MaterialApp(
            home: BeatRevealFlow(
              status: BeatFlowStatus.ready,
              response: null,
              screens: screens,
              onAmeen: () {},
            ),
          );

      await t.pumpWidget(flow(first));
      await t.pumpAndSettle();
      final size = t.getSize(find.byType(BeatRevealFlow));
      for (var i = 1; i < first.length; i++) {
        await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
        await t.pumpAndSettle();
      }
      expect(find.text('Ameen'), findsOneWidget); // on the last beat

      // The old index (7) is out of range for a 3-screen deck.
      await t.pumpWidget(flow(shorter));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull); // no RangeError from the stale index
      expect(find.textContaining('A racing mind'), findsOneWidget);
    });
  });
}
