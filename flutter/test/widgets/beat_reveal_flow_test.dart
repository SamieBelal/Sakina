import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

ReflectResponse _response({List<ReflectVerse> verses = const []}) =>
    ReflectResponse(
      name: 'Al-Lateef',
      nameArabic: 'اللطيف',
      reframe: 'derived',
      story: 'derived',
      duaArabic: 'رَبِّ',
      duaTransliteration: 'Rabbi',
      duaTranslation: 'My Lord',
      duaSource: "Qur'an 20:25",
      relatedNames: const [],
      offTopic: false,
      reframeKey: 'Allah was gentle with you tonight',
      reframeBody: 'Even unseen, His kindness arranged what you could not.',
      storyTitle: 'Musa at the Sea',
      storyBeats: const [
        'The sea stood before him and the army behind.',
        'He said, my Lord is with me.',
      ],
      storySource: "Qur'an 26:62",
      takeaway: 'What feels like drowning may be the sea parting.',
      verses: verses,
    );

void main() {
  group('buildBeatScreens', () {
    test('produces key/reframe/2 story/takeaway/dua = 6 screens', () {
      final screens = buildBeatScreens(_response());
      expect(screens.map((s) => s.kind).toList(), [
        BeatKind.keyLine,
        BeatKind.reframe,
        BeatKind.story,
        BeatKind.story,
        BeatKind.takeaway,
        BeatKind.dua,
      ]);
    });

    test('verses added between takeaway and dua only when includeVerses', () {
      final verses = [
        const ReflectVerse(
            arabic: 'فَإِنَّ', translation: 'with hardship, ease', reference: '94:5'),
      ];
      final without = buildBeatScreens(_response(verses: verses));
      expect(without.where((s) => s.kind == BeatKind.verse), isEmpty);

      final withV =
          buildBeatScreens(_response(verses: verses), includeVerses: true);
      final kinds = withV.map((s) => s.kind).toList();
      expect(kinds.where((k) => k == BeatKind.verse), hasLength(1));
      // verse sits before the dua and after the takeaway
      expect(kinds.indexOf(BeatKind.verse),
          greaterThan(kinds.indexOf(BeatKind.takeaway)));
      expect(kinds.indexOf(BeatKind.verse),
          lessThan(kinds.indexOf(BeatKind.dua)));
    });

    test('story title is on the first story beat, source on the last', () {
      final screens = buildBeatScreens(_response());
      final story = screens.where((s) => s.kind == BeatKind.story).toList();
      expect(story.first.label, 'Musa at the Sea');
      expect(story.last.source, "Qur'an 26:62");
      expect(story.first.source, isEmpty);
    });

    test('dua screen is always last', () {
      expect(buildBeatScreens(_response()).last.kind, BeatKind.dua);
    });
  });

  group('BeatRevealFlow widget', () {
    testWidgets('advances forward on right tap, back on left tap', (t) async {
      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: _response(),
          onAmeen: () {},
        ),
      ));
      await t.pumpAndSettle();

      expect(find.text('Allah was gentle with you tonight'), findsOneWidget);

      final size = t.getSize(find.byType(BeatRevealFlow));
      // Right 60% → advance.
      await t.tapAt(Offset(size.width * 0.8, size.height * 0.5));
      await t.pumpAndSettle();
      expect(find.text('Allah was gentle with you tonight'), findsNothing);
      expect(
          find.text('Even unseen, His kindness arranged what you could not.'),
          findsOneWidget);

      // Left 40% → back.
      await t.tapAt(Offset(size.width * 0.2, size.height * 0.5));
      await t.pumpAndSettle();
      expect(find.text('Allah was gentle with you tonight'), findsOneWidget);
    });

    testWidgets('Skip to duʿa jumps to the dua screen with the Ameen pill',
        (t) async {
      var skippedFrom = -1;
      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: _response(),
          onAmeen: () {},
          onSkip: (from) => skippedFrom = from,
        ),
      ));
      await t.pumpAndSettle();

      await t.tap(find.text('Skip to duʿa'));
      await t.pumpAndSettle();

      expect(skippedFrom, 0);
      expect(find.text('Ameen'), findsOneWidget);
      expect(find.text('Skip to duʿa'), findsNothing); // no skip on dua screen
    });

    testWidgets('Ameen fires the callback exactly once', (t) async {
      var ameenCount = 0;
      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.ready,
          response: _response(),
          onAmeen: () => ameenCount++,
        ),
      ));
      await t.pumpAndSettle();
      await t.tap(find.text('Skip to duʿa'));
      await t.pumpAndSettle();

      await t.tap(find.text('Ameen'));
      await t.pump(); // enter the completion beat
      await t.pump(const Duration(milliseconds: 1200)); // fire the delayed exit
      expect(ameenCount, 1);
      // In the app onAmeen pops the route; here dispose the tree so the
      // completion-beat animations don't leave a pending timer at teardown.
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('error status shows warm retry, not a snackbar', (t) async {
      var retried = 0;
      await t.pumpWidget(MaterialApp(
        home: BeatRevealFlow(
          status: BeatFlowStatus.error,
          response: null,
          onAmeen: () {},
          onRetry: () => retried++,
        ),
      ));
      await t.pumpAndSettle();
      expect(find.text("We couldn't prepare your reflection."), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await t.tap(find.text('Try Again'));
      expect(retried, 1);
    });
  });
}
