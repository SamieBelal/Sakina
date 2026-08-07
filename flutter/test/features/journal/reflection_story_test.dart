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

  // ── The dismissal (2026-08-06 regression) ─────────────────────────────────
  //
  // `BeatRevealFlow` wraps itself in `PopScope(canPop: false)` whose handler
  // calls its own `_back()` — that is how the system back GESTURE steps back one
  // beat instead of abandoning the night, and it is right for the live flow.
  //
  // The re-read dismissed itself with `maybePop`, which is precisely the call
  // `PopScope` intercepts. So "Done" was refused its pop and handed to `_back()`
  // instead: the reader tapped Done on the last beat and was sent back one
  // screen. On a saved entry the beats end `… → verse → duʿā`, so that landed on
  // the AYAH, with no way out but the system gesture — the flow was a trap.
  //
  // These pump the real page on a real Navigator. `BeatRevealFlow` on its own
  // cannot reproduce it: the PopScope is in the widget, but the `maybePop` was
  // in the host.
  //
  // MUTATION: put `maybePop` back in `_dismiss` → the first test fails, still
  // showing the story.
  group('ReflectionStoryPage — leaving it', () {
    Future<void> pumpPushed(WidgetTester t, SavedReflection entry) async {
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReflectionStoryPage(reflection: entry),
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('OPEN'));
      await t.pumpAndSettle();
    }

    Future<void> tapThroughToLast(
        WidgetTester t, SavedReflection entry) async {
      final count = buildBeatScreensFromReflection(entry).length;
      for (var i = 0; i < count - 1; i++) {
        await t.tapAt(const Offset(700, 400));
        await t.pumpAndSettle();
      }
    }

    testWidgets('"Done" on the last beat leaves the story', (t) async {
      final entry = legacyRow();
      await pumpPushed(t, entry);
      await tapThroughToLast(t, entry);

      expect(find.text('Done'), findsOneWidget,
          reason: 'the tap-through must actually have reached the last beat');

      await t.tap(find.text('Done'));
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsOneWidget,
          reason: 'the story route must be gone');
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('it does NOT step back to the ayah — the exact symptom',
        (t) async {
      // A verse, so the beats end `… → verse → duʿā` exactly as a real entry's
      // do. That ordering is why the reported landing screen was the ayah: it
      // is what sits one step back from the last beat.
      final entry = legacyRow().copyWith(verses: const [
        ReflectVerse(
          arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
          translation: 'Indeed, with hardship comes ease.',
          reference: 'Quran 94:6',
        ),
      ]);
      final screens = buildBeatScreensFromReflection(entry);
      expect(screens[screens.length - 2].kind, BeatKind.verse,
          reason: 'the fixture must reproduce the real beat order, or this '
              'test is not about the reported bug');

      await pumpPushed(t, entry);
      await tapThroughToLast(t, entry);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();

      expect(find.text('Indeed, with hardship comes ease.'), findsNothing,
          reason: 'landing on the ayah IS the bug');
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('a double-tap pops once — an unconditional pop would take the '
        'Journal underneath it too', (t) async {
      final entry = legacyRow();
      await pumpPushed(t, entry);
      await tapThroughToLast(t, entry);

      // Two taps inside one frame, before any settle.
      await t.tap(find.text('Done'));
      await t.tap(find.text('Done'), warnIfMissed: false);
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsOneWidget,
          reason: 'the host route must survive');
    });

    testWidgets('the back GESTURE still means "one beat back", not "leave"',
        (t) async {
      final entry = legacyRow();
      await pumpPushed(t, entry);
      // Advance one beat, then send a system back.
      await t.tapAt(const Offset(700, 400));
      await t.pumpAndSettle();

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsNothing,
          reason: 'the PopScope is what makes back a beat control; a gesture '
              'mid-flow must not abandon the story');
    });

    testWidgets('the back gesture on the FIRST beat does leave', (t) async {
      final entry = legacyRow();
      await pumpPushed(t, entry);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsOneWidget,
          reason: 'back on beat 0 routes through onReturnHome, which is the '
              'same dismissal — it must not be swallowed either');
    });
  });
}
