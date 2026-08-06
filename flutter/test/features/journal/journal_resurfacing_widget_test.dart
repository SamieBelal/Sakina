// Wave E on the actual Journal screen.
//
// The pure rules are pinned in `journal_resurfacing_test.dart`. This file pins
// the wiring, which is where the three surfaces can go wrong in ways a resolver
// test cannot see:
//
//  * the resurfacing strip is prepended to the All feed's ListView, which
//    shifted every index by one — the tour anchor for step 12 has to stay on the
//    FIRST ENTRY and not land on the strip;
//  * the recap and the lifetime theme line share one slot and must never both
//    render;
//  * the answered-duʿā actions have to reach the real provider methods, not a
//    reimplementation local to the screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/features/journal/screens/journal_screen.dart';
import 'package:sakina/features/journal/widgets/answered_dua_card.dart';
import 'package:sakina/features/journal/widgets/on_this_night_card.dart';
import 'package:sakina/features/journal/widgets/weekly_recap_line.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';

import '../../support/fake_supabase_sync_service.dart';

class _StubQuests extends QuestsNotifier {
  @override
  Future<void> onJournalVisited() async {}
}

class _StubLoop extends DailyLoopNotifier {
  _StubLoop() : super(skipInitForTests: true) {
    state = const DailyLoopState(loaded: true);
  }
}

/// Today, pinned. The screen resolves it through `resolveUserLocalDay()`, which
/// the UTC override below makes deterministic.
final _today = DateTime.utc(2026, 8, 2, 20);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugUserLocalDayClock = () => _today;
  });

  tearDown(() {
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  SavedReflection muhasabah({
    required String day,
    String words = 'I could not sleep.',
    String name = 'Al-Halim',
  }) =>
      SavedReflection(
        id: 'm-$day',
        date: '${day}T21:00:00.000',
        userText: words,
        name: name,
        nameArabic: 'الحليم',
        reframePreview: 'Forbearance is not indifference.',
        source: reflectionSourceMuhasabah,
        entryLocalDay: day,
      );

  SavedBuiltDua builtDua({
    String id = 'd1',
    String savedAt = '2026-04-02T10:00:00.000Z',
    String status = builtDuaStatusOpen,
    String? answeredAt,
  }) =>
      SavedBuiltDua(
        id: id,
        savedAt: savedAt,
        need: 'A job that lets me pray on time.',
        arabic: 'اللهم',
        transliteration: 'Allahumma',
        translation: 'O Allah',
        status: status,
        answeredAt: answeredAt,
      );

  Future<DuasNotifier> pump(
    WidgetTester t, {
    List<SavedReflection> reflections = const [],
    List<SavedBuiltDua> duas = const [],
  }) async {
    final reflectNotifier = ReflectNotifier(loadOnInit: false)
      ..debugSeedReflections(reflections);
    final duasNotifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => throw UnimplementedError(),
        buildDua: (_) async => throw UnimplementedError(),
        now: () => _today,
        createId: () => 'generated',
      ),
    );
    duasNotifier.state = duasNotifier.state.copyWith(savedBuiltDuas: duas);

    final router = GoRouter(
      initialLocation: '/journal',
      routes: [
        GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
        GoRoute(
            path: '/muhasabah',
            builder: (_, __) => const Scaffold(body: Text('MUHASABAH ROUTE'))),
        GoRoute(
            path: '/reflect',
            builder: (_, __) => const Scaffold(body: Text('REFLECT ROUTE'))),
      ],
    );
    addTearDown(router.dispose);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          reflectProvider.overrideWith((_) => reflectNotifier),
          duasProvider.overrideWith((_) => duasNotifier),
          questsProvider.overrideWith((_) => _StubQuests()),
          dailyLoopProvider.overrideWith((_) => _StubLoop()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Twice plus a settle: the local-day provider is async, so the resurfacing
    // surfaces are absent on the very first frame by construction.
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    return duasNotifier;
  }

  group('E1 — On This Night', () {
    testWidgets('surfaces the entry from a month ago, and it opens', (t) async {
      await pump(t, reflections: [
        muhasabah(day: '2026-07-03', words: 'The result comes on Thursday.'),
        muhasabah(day: '2026-08-02', words: 'Tonight.'),
      ]);

      expect(find.byType(OnThisNightCard), findsOneWidget);
      expect(find.text(MuhasabahCompletionCopy.timeMachineMonth),
          findsOneWidget);
      // Scoped to the card. The feed card below it renders the same words
      // unquoted now, so an unscoped finder matches both — which is the point
      // of the resurfacing card, not a bug in it.
      expect(
        find.descendant(
          of: find.byType(OnThisNightCard),
          matching: find.text('The result comes on Thursday.'),
        ),
        findsOneWidget,
      );

      await t.tap(find.text(JournalResurfacingCopy.onThisNightOpen));
      await t.pumpAndSettle();
      // The card opens the entry itself — the same door the calendar uses.
      expect(find.text(MuhasabahCompletionCopy.timeMachineMonth), findsNothing);
    });

    testWidgets('is absent for a journal with no anchor', (t) async {
      await pump(t, reflections: [muhasabah(day: '2026-08-01')]);
      expect(find.byType(OnThisNightCard), findsNothing);
    });
  });

  group('E2 — the weekly recap', () {
    // 2026-08-06: the recap stopped being a block in the archive and became a
    // one-line door onto a story — see `weekly_recap_story_test.dart`, which
    // owns the beats, the cadence gate and the dismissal. What this group still
    // pins is the thing that did NOT change: whatever the recap looks like, it
    // and the lifetime theme line share one slot and never stack.
    testWidgets('replaces the lifetime theme line, never stacks on it',
        (t) async {
      await pump(t, reflections: [
        muhasabah(day: '2026-08-02', words: 'work is crushing me'),
        muhasabah(day: '2026-08-01', words: 'anxious about the exam'),
        muhasabah(day: '2026-07-31', words: 'worried about money'),
      ]);

      expect(find.byType(WeeklyRecapLine), findsOneWidget);
      expect(find.text(JournalResurfacingCopy.recapLineTrail), findsOneWidget);
      expect(
        find.textContaining('You often turn to Allah with'),
        findsNothing,
        reason: 'two theme claims stacked, the vaguer one on top, is what this '
            'slot exists to prevent',
      );
    });

    testWidgets('falls back to the lifetime line when the week is empty',
        (t) async {
      await pump(t, reflections: [
        muhasabah(day: '2026-01-02', words: 'anxious'),
        muhasabah(day: '2026-01-03', words: 'stressed'),
        muhasabah(day: '2026-01-04', words: 'worried'),
      ]);

      expect(find.byType(WeeklyRecapLine), findsNothing);
      expect(find.textContaining('You often turn to Allah with'),
          findsOneWidget);
    });
  });

  group('E3 — the answered duʿā', () {
    testWidgets('asks gently, with two equal ways out', (t) async {
      await pump(t,
          reflections: [muhasabah(day: '2026-08-02')], duas: [builtDua()]);

      expect(find.byType(AnsweredDuaCard), findsOneWidget);
      expect(find.text(JournalResurfacingCopy.askedAgo('four months')),
          findsOneWidget);
      expect(find.text(JournalResurfacingCopy.answeredAction), findsOneWidget);
      expect(find.text(JournalResurfacingCopy.notYetAction), findsOneWidget);
      // The line that keeps a duʿā from becoming a to-do item.
      expect(find.text(JournalResurfacingCopy.answeredFooter), findsOneWidget);
    });

    testWidgets('marking it answered goes through the provider and the card '
        'goes away', (t) async {
      final duas = await pump(t,
          reflections: [muhasabah(day: '2026-08-02')], duas: [builtDua()]);

      await t.tap(find.text(JournalResurfacingCopy.answeredAction));
      await t.pumpAndSettle();

      expect(duas.state.savedBuiltDuas.single.isAnswered, isTrue);
      expect(find.byType(AnsweredDuaCard), findsNothing,
          reason: 'the prompt never asks twice about the same duʿā');
      expect(find.text(JournalResurfacingCopy.answeredConfirmation),
          findsOneWidget);
    });

    testWidgets('"Not yet" snoozes rather than marking anything', (t) async {
      final duas = await pump(t,
          reflections: [muhasabah(day: '2026-08-02')], duas: [builtDua()]);

      await t.tap(find.text(JournalResurfacingCopy.notYetAction));
      await t.pumpAndSettle();

      expect(duas.state.savedBuiltDuas.single.status, builtDuaStatusOpen);
      expect(duas.state.answeredPromptSnoozedUntil, contains('d1'));
      expect(find.byType(AnsweredDuaCard), findsNothing);
    });

    testWidgets('an answered duʿā carries its chip and an undo', (t) async {
      final duas = await pump(
        t,
        duas: [
          builtDua(
            status: builtDuaStatusAnswered,
            answeredAt: '2026-07-01T10:00:00.000Z',
          )
        ],
      );

      // No prompt — it is already marked.
      expect(find.byType(AnsweredDuaCard), findsNothing);
      expect(find.text(JournalResurfacingCopy.answeredChip.toUpperCase()),
          findsOneWidget);

      // The undo lives on the duʿā card itself, reachable after the toast is
      // long gone — and on the footer row, which is the part of
      // `_ExpandableCard` that actually renders when the card has an `onTap`.
      await t.tap(find.text(JournalResurfacingCopy.answeredUndo));
      await t.pumpAndSettle();
      expect(duas.state.savedBuiltDuas.single.status, builtDuaStatusOpen);
      expect(duas.state.savedBuiltDuas.single.answeredAt, isNull);
    });

    testWidgets('never asks about a duʿā younger than the floor', (t) async {
      await pump(t, duas: [builtDua(savedAt: '2026-07-25T10:00:00.000Z')]);
      expect(find.byType(AnsweredDuaCard), findsNothing);
    });
  });

  group('the feed itself', () {
    testWidgets('the tour anchor stays on the first ENTRY, not on the strip',
        (t) async {
      // The strip is item 0 of the All feed's ListView now. Step 12 of the tour
      // targets `journal.firstEntry`, and an off-by-one here points the
      // coachmark at a card that is usually not even rendered.
      await pump(t, reflections: [
        muhasabah(day: '2026-07-03', words: 'a month ago'),
        muhasabah(day: '2026-08-02', words: 'tonight'),
      ]);

      final anchor = find.byWidgetPredicate(
        (w) => w is TourAnchor && w.anchorId == 'firstEntry',
      );
      expect(anchor, findsOneWidget);
      expect(
        find.descendant(of: anchor, matching: find.byType(OnThisNightCard)),
        findsNothing,
      );
      expect(
        find.descendant(of: anchor, matching: find.text('tonight')),
        findsOneWidget,
      );
    });

    testWidgets('a journal with nothing to resurface renders no strip at all',
        (t) async {
      await pump(t, reflections: [muhasabah(day: '2026-08-02')]);
      expect(find.byType(OnThisNightCard), findsNothing);
      expect(find.byType(AnsweredDuaCard), findsNothing);
      expect(find.byType(WeeklyRecapLine), findsNothing);
      // And the entry is still there.
      expect(find.text('I could not sleep.'), findsOneWidget);
    });
  });
}
