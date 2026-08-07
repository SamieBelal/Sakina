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
import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';
import 'package:sakina/features/streaks/widgets/month_of_light_cell.dart';
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

  SavedBuiltDua builtDua({
    String id = 'b1',
    String need = 'Ease for my mother',
  }) =>
      SavedBuiltDua(
        id: id,
        savedAt: '2026-08-04T12:00:00Z',
        need: need,
        arabic: 'اللهم يسر',
        transliteration: 'Allahumma yassir',
        translation: 'O Allah, make it easy.',
      );

  Future<_StubLoop> pump(
    WidgetTester t, {
    List<SavedReflection> reflections = const [],
    List<SavedRelatedDua> duas = const [],
    List<SavedBuiltDua> builtDuas = const [],
    DailyLoopState? loop,
    MonthOfLight? month,
  }) async {
    final reflectNotifier = ReflectNotifier(loadOnInit: false)
      ..debugSeedReflections(reflections);
    final duasNotifier = DuasNotifier(loadOnInit: false);
    if (duas.isNotEmpty || builtDuas.isNotEmpty) {
      duasNotifier.state = duasNotifier.state.copyWith(
        savedRelatedDuas: duas,
        savedBuiltDuas: builtDuas,
      );
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
          if (month != null)
            monthOfLightProvider.overrideWith((_) async => month),
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

  /// Taps a filter chip by KEY, never by label. "All" is the first chip of both
  /// filter rows AND the first tab, and `IndexedStack` builds every tab whether
  /// or not it is showing — so `find.text('All')` matches up to three widgets.
  Future<void> filter(WidgetTester t, String group, int index) async {
    await t.tap(find.byKey(ValueKey('journal-filter-$group-$index')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  group('D1 — muhasabah entries appear and can be filtered', () {
    testWidgets('a muhasabah row renders with its own type chip', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);

      // Both chips are present on the All feed: one entry of each kind.
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);
      // 2026-08-06: the card no longer wraps the words in quotation marks.
      // They existed to mark 15px grey italic as the user's voice; the words
      // now lead the card at 19px near-black, where the marks are chrome.
      expect(find.text('I snapped at my brother tonight.'), findsOneWidget);
    });

    testWidgets('the Nightly filter shows only muhasabah entries', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      // All: both.
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);

      await filter(t, 'reflection', 1);

      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsNothing);
    });

    testWidgets('the Reflect filter shows only Reflect saves', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      await filter(t, 'reflection', 2);

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

  // 2026-08-06 — the archive's cards were rebuilt around the entry rather than
  // around the app's labels for it. Two things that redesign can silently lose.
  group('the entry leads its card', () {
    /// A real phone. The default 800x600 test surface is wide enough that a
    /// paragraph fits in three lines, so nothing ever overflows and the fade
    /// branch below would never run.
    Future<void> phone(WidgetTester t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
    }

    const long = 'I keep replaying the conversation from work. I said '
        'something careless and now I cannot tell whether to apologise again '
        'or leave it alone and let it fade on its own.';

    testWidgets('a long entry fades out instead of ellipsing', (t) async {
      await phone(t);
      await pump(t, reflections: [muhasabah(words: long)]);

      expect(
        find.ancestor(of: find.text(long), matching: find.byType(ShaderMask)),
        findsOneWidget,
        reason: 'an ellipsis says the string was cut; a fade says the entry '
            'continues, which is the true thing and the one that invites the '
            'tap',
      );
    });

    testWidgets('a short entry gets no fade at all', (t) async {
      await phone(t);
      await pump(t, reflections: [muhasabah(words: 'Short.')]);

      expect(
        find.ancestor(
            of: find.text('Short.'), matching: find.byType(ShaderMask)),
        findsNothing,
        reason: 'an unconditional ShaderMask would wash out the last line of '
            'every short entry, which is most of them',
      );
    });

    testWidgets('the archive opens in the top quarter of the screen',
        (t) async {
      await phone(t);
      await pump(t, reflections: [muhasabah()]);

      // The chip is the top of the first entry block. Before this redesign the
      // screen spent ~285px on a title, a four-tile stats card and a pill tab
      // row before reaching it — a third of the phone, above the fold, on
      // chrome. Pinned as a fraction rather than a pixel so it survives a font
      // bump but still fails if a new banner moves in.
      final chipY = t.getTopLeft(find.text('MUHĀSABAH')).dy;
      expect(chipY, lessThan(844 * 0.25));
    });
  });

  // The Duas tab's filter row is the exact twin of the Reflections tab's, and
  // shares `_filterChip` with it precisely so the two cannot drift into looking
  // like different controls. Until now only one of the twins was tested.
  //
  // The two kinds are genuinely different objects — a duʿā you BUILT from your
  // own need, and one you SAVED from a reflection — living in separate lists on
  // `DuasState`. A filter that reads the wrong list is invisible until a user
  // has both.
  group('the Duas tab filters by where the duʿā came from', () {
    const duasTab = 2;

    testWidgets('All shows both kinds', (t) async {
      await pump(t, duas: [savedDua()], builtDuas: [builtDua()]);
      await openTab(t, duasTab);

      expect(find.text('PERSONAL DUA'), findsOneWidget);
      expect(find.text('SAVED DUA'), findsOneWidget);
      expect(find.text('Ease for my mother'), findsOneWidget);
      expect(find.text('Dua for ease'), findsOneWidget);
    });

    testWidgets('Built shows only the ones you made', (t) async {
      await pump(t, duas: [savedDua()], builtDuas: [builtDua()]);
      await openTab(t, duasTab);

      await filter(t, 'dua', 1);

      expect(find.text('PERSONAL DUA'), findsOneWidget);
      expect(find.text('SAVED DUA'), findsNothing);
      expect(find.text('Dua for ease'), findsNothing);
    });

    testWidgets('Saved shows only the ones you kept', (t) async {
      await pump(t, duas: [savedDua()], builtDuas: [builtDua()]);
      await openTab(t, duasTab);

      await filter(t, 'dua', 2);

      expect(find.text('SAVED DUA'), findsOneWidget);
      expect(find.text('PERSONAL DUA'), findsNothing);
      expect(find.text('Ease for my mother'), findsNothing);
    });

    testWidgets('returning to All brings both back — the filter is not a delete',
        (t) async {
      await pump(t, duas: [savedDua()], builtDuas: [builtDua()]);
      await openTab(t, duasTab);

      await filter(t, 'dua', 1);
      await filter(t, 'dua', 0);

      expect(find.text('PERSONAL DUA'), findsOneWidget);
      expect(find.text('SAVED DUA'), findsOneWidget);
    });

    testWidgets('the chips render even when one side is empty', (t) async {
      // Same rule D1 states for the Reflections tab: an empty "Saved" list is
      // itself the answer to "where are my saved duʿās", and hiding the chip
      // would leave the question unanswered.
      await pump(t, builtDuas: [builtDua()]);
      await openTab(t, duasTab);

      // By key: "All" is also a tab label, so the text finder is ambiguous.
      expect(find.byKey(const ValueKey('journal-filter-dua-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('journal-filter-dua-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('journal-filter-dua-2')), findsOneWidget);
      expect(find.text('Built'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);

      await filter(t, 'dua', 2);

      expect(find.text('PERSONAL DUA'), findsNothing,
          reason: 'an empty filter shows nothing rather than falling back to '
              'everything');
    });

    testWidgets('the filter does not leak across tabs', (t) async {
      // `_duaFilter` and `_reflectionFilter` are separate fields on the same
      // State. Sharing `_filterChip` between them is what makes crossing them
      // a plausible mistake.
      await pump(
        t,
        reflections: [muhasabah(), reflectSave()],
        duas: [savedDua()],
        builtDuas: [builtDua()],
      );

      await openTab(t, duasTab);
      await filter(t, 'dua', 1);

      await openTab(t, 1); // Reflections
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget,
          reason: 'the Reflections tab is still on All — picking Built on the '
              'Duas tab must not have moved it');
    });
  });

  // D4 — the calendar became a door. `month_of_light_browse_test` pins WHICH
  // cells route; this pins where the Journal takes them once they do.
  //
  // The middle case is the one with no coverage at all and the most ways to be
  // wrong: a night the STREAK knows about but the journal does not. Every night
  // completed before Wave B started persisting entries is one of these, and so
  // is a night whose write the server refused. Doing nothing at all reads as a
  // broken tap; opening a blank page is worse.
  group('D4 — the calendar opens a night, or says why it cannot', () {
    MonthOfLight month(Map<int, MonthCellState> states) {
      final cells = <DateTime, MonthCellState>{};
      for (var d = 1; d <= 31; d++) {
        cells[DateTime.utc(2026, 8, d)] =
            states[d] ?? MonthCellState.future;
      }
      return MonthOfLight(
        cells: cells,
        litCount: states.values.where((s) => s == MonthCellState.lit).length,
        month: DateTime.utc(2026, 8, 1),
      );
    }

    Finder cellFor(DateTime day) => find.byWidgetPredicate(
          (w) => w is MonthOfLightCell && w.day == day && !w.dense,
        );

    Future<void> openCalendar(WidgetTester t) async {
      await t.tap(find.byTooltip('Browse by month'));
      await t.pumpAndSettle();
    }

    testWidgets('a lit night with an entry opens that entry', (t) async {
      await pump(
        t,
        reflections: [muhasabah(day: '2026-08-02')],
        month: month({2: MonthCellState.lit}),
      );

      await openCalendar(t);
      await t.tap(cellFor(DateTime.utc(2026, 8, 2)));
      await t.pumpAndSettle();

      // `textContaining`, not `text`: the story cover wraps the words in
      // typographic quotes, so the literal string never matches there.
      expect(find.textContaining('I snapped at my brother tonight.'),
          findsWidgets,
          reason: 'the night opened');
      expect(find.text('That night was lit, but no entry was saved for it.'),
          findsNothing);
    });

    testWidgets('a lit night with NO entry says so plainly', (t) async {
      // The 1st is lit; the only entry is on the 2nd.
      await pump(
        t,
        reflections: [muhasabah(day: '2026-08-02')],
        month: month({1: MonthCellState.lit, 2: MonthCellState.lit}),
      );

      await openCalendar(t);
      await t.tap(cellFor(DateTime.utc(2026, 8, 1)));
      await t.pumpAndSettle();

      expect(
        find.text('That night was lit, but no entry was saved for it.'),
        findsOneWidget,
        reason: 'a pre-Wave-B night, or one the server refused — saying '
            'nothing at all reads as a broken tap',
      );
    });

    testWidgets('an empty journal does not crash the calendar', (t) async {
      await pump(t, month: month({1: MonthCellState.lit}));

      await openCalendar(t);
      await t.tap(cellFor(DateTime.utc(2026, 8, 1)));
      await t.pumpAndSettle();

      expect(find.text('That night was lit, but no entry was saved for it.'),
          findsOneWidget);
    });

    testWidgets('today pending starts tonight rather than opening it',
        (t) async {
      await pump(t, month: month({2: MonthCellState.todayPending}));

      await openCalendar(t);
      await t.tap(cellFor(DateTime.utc(2026, 8, 2)));
      await t.pumpAndSettle();

      expect(find.text('MUHASABAH ROUTE'), findsOneWidget);
      expect(find.text('That night was lit, but no entry was saved for it.'),
          findsNothing,
          reason: 'todayPending is handled BEFORE the entry lookup — a pending '
              'night has no entry by definition, so falling through would show '
              'the message on every fresh day');
    });

    testWidgets('a Reflect save with no local day still answers for its date',
        (t) async {
      // The `saved_at` fallback in `_entryForDay`. A Reflect save is not a
      // night and carries no `entry_local_day`, so without the fallback every
      // calendar tap on a day whose only entry is a Reflect save would report
      // "no entry was saved for it" — while the entry sits in the feed above.
      await pump(
        t,
        reflections: [reflectSave(date: '2026-08-01T10:00:00.000Z')],
        month: month({1: MonthCellState.lit}),
      );

      await openCalendar(t);
      await t.tap(cellFor(DateTime.utc(2026, 8, 1)));
      await t.pumpAndSettle();

      expect(find.text('That night was lit, but no entry was saved for it.'),
          findsNothing);
      expect(find.textContaining('The interview is tomorrow and I cannot sleep.'),
          findsWidgets);
    });
  });

  // 2026-08-07 — the filter said "Nightly" for a thing that is not night-gated.
  //
  // The muḥāsabah is keyed on `entry_local_day` with a one-per-local-day unique
  // index, and nothing in the daily loop consults the clock to decide whether it
  // may be done. `MuhasabahCompletionCopy` already knows this — it swaps its own
  // header to "Today is written down" before 17:00 — so a 9am accounting was
  // being filed under a word that contradicted the screen that wrote it.
  group('the reflection filters are named after what they select', () {
    testWidgets('a filter and the chip it selects use one word', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      // The chip is the same string, uppercased by `_typeChip`. Pinned as a
      // pair so a rename of either has to move both — the spelling differs by
      // one diacritic between "Muhāsabah" and "Muḥāsabah", which is invisible
      // in review and would silently split the two labels apart.
      expect(find.text('Muhāsabah'), findsOneWidget);
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('Reflection'), findsOneWidget);
      expect(find.text('REFLECTION'), findsOneWidget);
    });

    testWidgets('"Nightly" is gone, and "Reflect" with it', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      expect(find.text('Nightly'), findsNothing,
          reason: 'the muḥāsabah is not night-gated — see '
              'MuhasabahCompletionCopy.eveningStartsAtHour, which exists '
              'precisely because a morning muḥāsabah is ordinary');
      expect(find.text('Reflect'), findsNothing,
          reason: '"Reflect" is the name of the screen an entry is made on, '
              'not of the entry');
    });

    testWidgets('renaming them did not break what they filter', (t) async {
      await pump(t, reflections: [muhasabah(), reflectSave()]);
      await openTab(t, 1);

      await filter(t, 'reflection', 1);
      expect(find.text('MUHĀSABAH'), findsOneWidget);
      expect(find.text('REFLECTION'), findsNothing);

      await filter(t, 'reflection', 2);
      expect(find.text('MUHĀSABAH'), findsNothing);
      expect(find.text('REFLECTION'), findsOneWidget);
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
          .getTopLeft(find.text('The interview is tomorrow and I cannot '
              'sleep.'))
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
