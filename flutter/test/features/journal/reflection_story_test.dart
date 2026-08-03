// Story-format entries in the archive (Wave D, D2).
//
// The Journal rendered an entry as two lines of grey text while the night it
// came from rendered as a full-screen tap-through sequence on the sacred canvas.
// `buildBeatScreensFromReflection` is what closes that gap: the same
// `BeatRevealFlow`, fed from a saved row instead of a live AI response.
//
// Two of these tests are regression pins rather than feature tests:
//
//  * the LEGACY row. Every entry saved before `beat_data` existed (2026-07-14)
//    has NULL beats and carries only joined prose. If the archive could not
//    render those, "the Journal renders in story format" would be true only for
//    entries written in the last three weeks — which is the opposite of what an
//    archive is for. The `splitIntoBeats` fallback is the whole answer, and it
//    is one line that is easy to drop.
//
//  * SKIP TO DUʿĀ. `duaScreenIndex` clamped `lastIndexWhere`'s -1 to 0, so on a
//    screen list with no duʿā beat the affordance jumped the reader BACKWARDS to
//    beat 0 and emitted a skip that never happened. Nothing on the live paths
//    could reach it. An archived entry with no saved duʿā can.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/journal/screens/reflection_story_page.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A row exactly as it came back before `beat_data` existed: every beat field
  /// empty, the whole reflection living in the two joined prose columns.
  SavedReflection legacyRow() => const SavedReflection(
        id: 'legacy-1',
        date: '2025-11-02T21:14:00.000Z',
        userText: 'I keep bracing for bad news that never comes.',
        name: 'Al-Wakeel',
        nameArabic: 'الوكيل',
        reframePreview: '',
        reframe: 'You are bracing against a future you cannot see. '
            'The bracing is the cost, not the news. '
            'Handing it over is not giving up on it.',
        story: 'Musa stood at the sea with an army behind him. '
            'He did not know the water would open. '
            'He knew who he had handed the morning to.',
        duaArabic: 'حَسْبُنَا اللَّهُ',
        duaTransliteration: 'Hasbunallahu',
        duaTranslation: 'Allah is sufficient for us.',
        duaSource: 'Quran 3:173',
      );

  /// A modern row with structured beats and NO duʿā — the shape that exposed
  /// the skip bug. The deck path produces these (the deck's own beats are the
  /// content and none of the duʿā columns are written).
  SavedReflection rowWithoutDua() => const SavedReflection(
        id: 'no-dua-1',
        date: '2026-08-02T21:00:00.000Z',
        userText: 'I snapped at my brother.',
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: '',
        reframeKey: 'Forbearance is not indifference.',
        reframeBody: 'It is the strength to hold a reaction you are entitled '
            'to and not spend it.',
        storyTitle: 'The one who was slow to anger',
        storyBeats: ['A first beat.', 'A second beat.'],
        storySource: 'Sahih Bukhari',
        takeaway: 'Hold it one more breath.',
        source: reflectionSourceMuhasabah,
        entryLocalDay: '2026-08-02',
      );

  group('buildBeatScreensFromReflection', () {
    test('a LEGACY null-beat_data row still becomes a story, via splitIntoBeats',
        () {
      final r = legacyRow();
      expect(r.hasBeats, isFalse,
          reason: 'the fixture must actually be a legacy row, or this test '
              'proves nothing');

      final screens = buildBeatScreensFromReflection(r);
      final kinds = screens.map((s) => s.kind).toList();

      expect(kinds.first, BeatKind.entryCover);
      expect(kinds, contains(BeatKind.name));
      expect(kinds.last, BeatKind.dua);

      // The prose was split, not dumped onto one screen: three sentences in
      // `reframe`, three in `story`.
      expect(kinds.where((k) => k == BeatKind.reframe).length, 3);
      expect(kinds.where((k) => k == BeatKind.story).length, 3);
      expect(
        screens.firstWhere((s) => s.kind == BeatKind.reframe).primary,
        'You are bracing against a future you cannot see.',
      );
    });

    test('the cover carries the night and the user\'s own words', () {
      final screens = buildBeatScreensFromReflection(
        rowWithoutDua(),
        coverLabel: ReflectionStoryPage.coverLabel(rowWithoutDua()),
      );
      final cover = screens.first;
      expect(cover.kind, BeatKind.entryCover);
      expect(cover.primary, 'I snapped at my brother.');
      expect(cover.label, 'August 2, 2026');
      expect(cover.source, 'Al-Halim');
    });

    test('verses are included by default and become their own screens', () {
      final r = legacyRow().copyWith(verses: const [
        ReflectVerse(
          arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
          translation: 'Indeed, with hardship comes ease.',
          reference: 'Quran 94:6',
        ),
      ]);
      final screens = buildBeatScreensFromReflection(r);
      expect(screens.where((s) => s.kind == BeatKind.verse).length, 1);
      expect(
        buildBeatScreensFromReflection(r, includeVerses: false)
            .where((s) => s.kind == BeatKind.verse),
        isEmpty,
      );
    });

    test('an entry with no saved duʿā gets no duʿā screen', () {
      final screens = buildBeatScreensFromReflection(rowWithoutDua());
      expect(screens.where((s) => s.kind == BeatKind.dua), isEmpty);
      expect(screens.last.kind, BeatKind.takeaway);
    });
  });

  group('duaScreenIndex — the skip-to-duʿā guard', () {
    test('returns -1, NOT 0, when the list has no duʿā beat', () {
      final screens = buildBeatScreensFromReflection(rowWithoutDua());
      expect(
        duaScreenIndex(screens),
        -1,
        reason: 'the clamp(0, …) this replaced turned "not found" into '
            '"the first beat", which is a jump backwards',
      );
    });

    test('still finds the duʿā when there is one', () {
      final screens = buildBeatScreensFromReflection(legacyRow());
      expect(duaScreenIndex(screens), screens.length - 1);
    });
  });

  group('BeatRevealFlow — the re-read', () {
    Future<void> pumpFlow(
      WidgetTester t, {
      required SavedReflection entry,
      VoidCallback? onDone,
    }) async {
      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: null,
          screens: buildBeatScreensFromReflection(entry),
          completionLabel: 'Done',
          showCompletionCeremony: false,
          onAmeen: onDone ?? () {},
        ),
      ));
      await t.pumpAndSettle();
    }

    testWidgets('offers no "Skip to duʿa" anywhere in an entry that has none',
        (t) async {
      await pumpFlow(t, entry: rowWithoutDua());
      final screens = buildBeatScreensFromReflection(rowWithoutDua());

      for (var i = 0; i < screens.length; i++) {
        expect(find.text('Skip to duʿa'), findsNothing,
            reason: 'beat $i of an entry with no duʿā still offered the skip');
        if (i < screens.length - 1) {
          // Advance: tap the right 60% of the content zone.
          await t.tapAt(const Offset(700, 400));
          await t.pumpAndSettle();
        }
      }
    });

    testWidgets('still offers, and honours, the skip when a duʿā exists',
        (t) async {
      await pumpFlow(t, entry: legacyRow());
      expect(find.text('Skip to duʿa'), findsOneWidget);

      await t.tap(find.text('Skip to duʿa'));
      await t.pumpAndSettle();

      // Landed on the duʿā (which is last), so the completion pill is up and
      // the skip button is gone.
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Skip to duʿa'), findsNothing);
      expect(find.text('Allah is sufficient for us.'), findsOneWidget);
    });

    testWidgets('a re-read completes on its own label, with no ceremony',
        (t) async {
      var done = 0;
      await pumpFlow(t, entry: legacyRow(), onDone: () => done++);
      await t.tap(find.text('Skip to duʿa'));
      await t.pumpAndSettle();

      expect(find.text('Ameen'), findsNothing,
          reason: 'a re-read is a reading, not a supplication');
      await t.tap(find.text('Done'));
      // No pump past the tap: the ceremony is off, so the callback must have
      // fired synchronously rather than after the 1.1s bloom.
      expect(done, 1);
    });

    testWidgets('the live path keeps "Ameen" and keeps the ceremony', (t) async {
      var done = 0;
      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: null,
          screens: buildBeatScreensFromReflection(legacyRow()),
          onAmeen: () => done++,
        ),
      ));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip to duʿa'));
      await t.pumpAndSettle();

      expect(find.text('Ameen'), findsOneWidget);
      await t.tap(find.text('Ameen'));
      await t.pump();
      expect(done, 0, reason: 'the 1.1s ceremony must still run on the live '
          'path — the default is unchanged');
      await t.pump(const Duration(milliseconds: 1200));
      expect(done, 1);
    });
  });

  group('ReflectionStoryPage', () {
    test('will not offer a story for a row with nothing but the words', () {
      const bare = SavedReflection(
        id: 'bare',
        date: '2026-08-02T21:00:00.000Z',
        userText: 'Just today.',
        name: '',
        nameArabic: '',
        reframePreview: '',
      );
      expect(ReflectionStoryPage.canRenderAsStory(bare), isFalse);
      expect(ReflectionStoryPage.canRenderAsStory(legacyRow()), isTrue);
    });

    test('the cover date comes from entry_local_day, not saved_at', () {
      // 21:00 UTC on the 2nd is already the 3rd in Sydney; the row says the
      // night it belongs to is the 2nd, and the cover must agree with the row.
      final r = rowWithoutDua().copyWith(
        date: '2026-08-03T00:30:00.000Z',
        entryLocalDay: '2026-08-02',
      );
      expect(ReflectionStoryPage.coverLabel(r), 'August 2, 2026');
    });
  });
}
