// The Journal becomes an archive (Wave D — D1, D3, D6).
//
// Three things this file pins, in the order they went wrong:
//
//  * D1 — a muḥāsabah row and a Reflect save land in the SAME table and used to
//    render with the same word on them. They are now told apart by a chip and
//    separable by a filter. Wave B is what made this possible; before it there
//    were no muḥāsabah rows to show at all.
//  * D3 — the archive had no compose affordance whatsoever: no FAB, and an
//    All-tab empty state that described what would eventually appear and gave
//    no way to make any of it happen. There is now ONE control whose meaning
//    follows the day.
//  * D6 — the sort regression. Saved related duʿās carry no timestamp, and the
//    merge stamped `DateTime.now()` on them, so they outranked everything on
//    every rebuild. That is pinned here by ORDER, because a unit test on the
//    sort key would pass against the bug too (`DateTime.now()` is a perfectly
//    valid DateTime).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_compose_action.dart';
import 'package:sakina/features/journal/screens/journal_screen.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

import '../../support/fake_supabase_sync_service.dart';

/// Quests fire a post-frame `onJournalVisited` on every build of this screen.
/// Stubbed out: the quest ladder is not what is under test, and letting it run
/// drags prefs writes and a reward grant into a rendering test.
class _StubQuests extends QuestsNotifier {
  @override
  Future<void> onJournalVisited() async {}
}

class _StubLoop extends DailyLoopNotifier {
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }

  final List<String> appends = [];

  /// Wave H — the surface the append was filed under. See the note on the
  /// completion screen's stub: this argument is the only thing that separates a
  /// Journal append from a muḥāsabah one in the data.
  final List<String> appendSurfaces = [];

  @override
  Future<bool> appendToTonight(
    String text, {
    String surface = AnalyticsEvents.surfaceMuhasabah,
  }) async {
    appends.add(text);
    appendSurfaces.add(surface);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
  });

  tearDown(() {
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  SavedReflection muhasabah({
    String id = 'm1',
    String day = '2026-08-02',
    String words = 'I snapped at my brother tonight.',
    List<ReflectionThreadEntry> thread = const [],
  }) =>
      SavedReflection(
        id: id,
        date: '${day}T21:00:00.000Z',
        userText: words,
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: 'Forbearance is not indifference.',
        source: reflectionSourceMuhasabah,
        entryLocalDay: day,
        thread: thread,
      );

  SavedReflection reflectSave({
    String id = 'r1',
    String date = '2024-03-04T10:00:00.000Z',
    String words = 'The interview is tomorrow and I cannot sleep.',
  }) =>
      SavedReflection(
        id: id,
        date: date,
        userText: words,
        name: 'Al-Wakeel',
        nameArabic: 'الوكيل',
        reframePreview: 'You are not carrying the outcome.',
      );

  SavedRelatedDua savedDua() => const SavedRelatedDua(
        id: 'd1',
        title: 'Dua for ease',
        arabic: 'اللهم لا سهل',
        transliteration: 'Allahumma la sahla',
        translation: 'O Allah, nothing is easy except what You make easy.',
        source: 'Ibn Hibban',
      );

  Future<_StubLoop> pump(
    WidgetTester t, {
    List<SavedReflection> reflections = const [],
    List<SavedRelatedDua> duas = const [],
    DailyLoopState? loop,
  }) async {
    final reflectNotifier = ReflectNotifier(loadOnInit: false)
      ..debugSeedReflections(reflections);
    final duasNotifier = DuasNotifier(loadOnInit: false);
    if (duas.isNotEmpty) {
      duasNotifier.state = duasNotifier.state.copyWith(savedRelatedDuas: duas);
    }
    final loopNotifier = _StubLoop(loop ?? const DailyLoopState(loaded: true));

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
          dailyLoopProvider.overrideWith((_) => loopNotifier),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    return loopNotifier;
  }

  Future<void> openTab(WidgetTester t, int index) async {
    await t.tap(find.byKey(ValueKey('journal-tab-$index')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  group('D1 — muhasabah entries appear and can be filtered', () {
    testWidgets('a muhasabah row renders with its own type chip', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);

      // Both chips are present on the All feed: one entry of each kind.
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);
      expect(find.text('I snapped at my brother tonight.'), findsNothing,
          reason: 'the card quotes the words, so the raw string is wrapped');
      expect(
        find.text('"I snapped at my brother tonight."'),
        findsOneWidget,
      );
    });

    testWidgets('the Nightly filter shows only muhasabah entries', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      // All: both.
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);

      await t.tap(find.text('Nightly'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsNothing);
    });

    testWidgets('the Reflect filter shows only Reflect saves', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      await t.tap(find.text('Reflect'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      expect(find.text('MUHĀSABAH'), findsNothing);
      expect(find.text('REFLECTION'), findsOneWidget);
    });
  });

  group('D3 — one compose control, three meanings', () {
    testWidgets('nothing written yet → start tonight, and it routes',
        (t) async {
      await pump(t, reflections: [reflectSave()]);

      expect(
        find.text(JournalComposeCopy.label(JournalComposeAction.startTonight)),
        findsOneWidget,
      );

      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();
      expect(find.text('MUHASABAH ROUTE'), findsOneWidget);
    });

    testWidgets("tonight's entry is open → add to tonight, and the append "
        'goes through the no-economy path', (t) async {
      final loop = await pump(
        t,
        reflections: [muhasabah()],
        loop: DailyLoopState(
          loaded: true,
          checkinDone: true,
          tonightEntry: muhasabah(),
        ),
      );

      expect(
        find.text(JournalComposeCopy.label(JournalComposeAction.addToTonight)),
        findsOneWidget,
      );

      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField).last, 'one more thing');
      await t.pump();
      await t.tap(find.text('Add'));
      await t.pumpAndSettle();

      expect(loop.appends, ['one more thing'],
          reason: 'the sheet must reuse appendToTonight, not reimplement it');
      // Wave H. Same write, second surface — and the argument is the only thing
      // that tells them apart in the data. A call site that forgets it files a
      // Journal append under the muḥāsabah and D3's control looks unused.
      expect(loop.appendSurfaces, [AnalyticsEvents.surfaceJournal]);
    });

    testWidgets('a full thread → free write, and it routes to Reflect',
        (t) async {
      final full = muhasabah(
        thread: List.generate(
          20,
          (i) => ReflectionThreadEntry(at: '', text: 'append $i'),
        ),
      );
      await pump(
        t,
        reflections: [full],
        loop: DailyLoopState(
            loaded: true, checkinDone: true, tonightEntry: full),
      );

      expect(
        find.text(JournalComposeCopy.label(JournalComposeAction.freeWrite)),
        findsOneWidget,
      );

      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();
      expect(find.text('REFLECT ROUTE'), findsOneWidget);
    });

    testWidgets('the empty All tab carries the same control', (t) async {
      await pump(t);

      expect(
        find.text(JournalComposeCopy.label(JournalComposeAction.startTonight)),
        // Once on the FAB, once in the empty state.
        findsNWidgets(2),
      );
    });
  });

  group('D6 — undated saved duʿās stop pinning themselves to the top', () {
    testWidgets('a 2024 reflection still outranks an undated saved duʿā',
        (t) async {
      await pump(
        t,
        reflections: [reflectSave(date: '2024-03-04T10:00:00.000Z')],
        duas: [savedDua()],
      );

      final reflectionY = t
          .getTopLeft(find.text('"The interview is tomorrow and I cannot '
              'sleep."'))
          .dy;
      final duaY = t.getTopLeft(find.text('Dua for ease')).dy;

      expect(
        reflectionY,
        lessThan(duaY),
        reason: 'the saved duʿā has no timestamp — before D6 it was stamped '
            'with DateTime.now() and sat above a reflection from two years '
            'later, forever',
      );
    });
  });

  group('the pure compose rule', () {
    test('resolves from the day, not from the screen', () {
      expect(
        resolveJournalComposeAction(tonightEntry: null, checkinDone: false),
        JournalComposeAction.startTonight,
      );
      // The night happened but left no row (offline, or a refused write).
      // Sending the user back at the muḥāsabah would land them on a loop that
      // tells them they already did it.
      expect(
        resolveJournalComposeAction(tonightEntry: null, checkinDone: true),
        JournalComposeAction.freeWrite,
      );
      expect(
        resolveJournalComposeAction(
            tonightEntry: muhasabah(), checkinDone: true),
        JournalComposeAction.addToTonight,
      );
      expect(
        resolveJournalComposeAction(
          tonightEntry: muhasabah(
            thread: List.generate(
                20, (i) => ReflectionThreadEntry(at: '', text: '$i')),
          ),
          checkinDone: true,
        ),
        JournalComposeAction.freeWrite,
      );
    });
  });
}
