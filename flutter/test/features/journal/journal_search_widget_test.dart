// Journal search, as a MODE on the archive screen (2026-08-06).
//
// The matching rule is pinned by `journal_search_test.dart`. What can only go
// wrong HERE is the wiring, and it is the part a user actually feels:
//
//   * search has to cut across every tab. A per-tab box would have told someone
//     who searched from the wrong tab — truthfully and uselessly — that their
//     entry does not exist.
//   * cancelling has to restore the archive EXACTLY, including the tabs, the
//     filters and the compose FAB. A mode that leaks its filter back into the
//     feed is worse than no search.
//   * `journal_searched` has to be debounced. Emitting per keystroke turns one
//     search into four events and makes the has-results ratio meaningless.
//   * the query must never reach analytics. It is the same confessional text the
//     answer-text rule already keeps off the wire; a search box is just a second
//     place to type it.
//
// MUTATION: drop the debounce and emit from `_onSearchChanged` directly → the
// "one event per settled query" test fails with a count that tracks keystrokes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/screens/journal_screen.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';

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

class _Spy extends AnalyticsService {
  final tracked = <(String, Map<String, dynamic>?)>[];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }
}

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

  SavedReflection entry({
    required String id,
    required String words,
    String name = 'Al-Halim',
  }) =>
      SavedReflection(
        id: id,
        date: '2026-08-01T21:00:00.000',
        userText: words,
        name: name,
        nameArabic: 'الحليم',
        reframePreview: 'Forbearance is not indifference.',
      );

  Future<_Spy> pump(
    WidgetTester t, {
    List<SavedReflection> reflections = const [],
  }) async {
    final spy = _Spy();
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
          analyticsProvider.overrideWithValue(spy),
          reflectProvider.overrideWith((_) => reflectNotifier),
          duasProvider.overrideWith((_) => duasNotifier),
          questsProvider.overrideWith((_) => _StubQuests()),
          dailyLoopProvider.overrideWith((_) => _StubLoop()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    return spy;
  }

  Future<void> openSearch(WidgetTester t) async {
    await t.tap(find.byIcon(Icons.search_rounded).first);
    await t.pumpAndSettle();
  }

  /// A keystroke, and nothing more. Leaves the analytics debounce armed, which
  /// is what the `journal_searched` group needs to observe.
  Future<void> keystroke(WidgetTester t, String text) async {
    await t.enterText(find.byType(TextField), text);
    await t.pump();
  }

  /// Types and then waits, the way a person does: the results are on screen and
  /// the debounce has fired. Anything that leaves a Timer armed at the end of a
  /// test body trips the binding's pending-timer invariant.
  Future<void> type(WidgetTester t, String text) async {
    await keystroke(t, text);
    await t.pump(const Duration(seconds: 1));
  }

  List<Map<String, dynamic>?> propsFor(_Spy spy, String event) =>
      spy.tracked.where((e) => e.$1 == event).map((e) => e.$2).toList();

  final corpus = <SavedReflection>[
    entry(id: 'a', words: 'my dad is in hospital and I have not slept'),
    entry(id: 'b', words: 'the rent is due again', name: 'Al-Razzaq'),
    entry(id: 'c', words: 'I snapped at my brother'),
  ];

  group('the mode', () {
    testWidgets('opens from the header and replaces the archive controls',
        (t) async {
      await pump(t, reflections: corpus);
      expect(find.text('Journal'), findsOneWidget);

      await openSearch(t);

      expect(find.byType(TextField), findsOneWidget);
      // Every control that answers "which KIND of thing" is gone: the question
      // search asks cuts across all of them.
      expect(find.byKey(const ValueKey('journal-tab-0')), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('cancelling restores the archive exactly', (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'hospital');

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('journal-tab-0')), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      // Every entry is back — a mode must not leak its filter into the feed.
      expect(find.textContaining('the rent is due again'), findsWidgets);
    });

    testWidgets('re-opening starts from the prompt, not from the last query',
        (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'hospital');
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      await openSearch(t);

      expect(find.text('Search your entries, your duas and the Names.'),
          findsOneWidget);
    });
  });

  group('the results', () {
    testWidgets('an empty query shows the prompt and no entries', (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);

      expect(find.text('Search your entries, your duas and the Names.'),
          findsOneWidget);
      expect(find.textContaining('the rent is due again'), findsNothing);
    });

    testWidgets('narrows to the matching entries and counts them', (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'hospital');

      expect(find.text('1 entry'), findsOneWidget);
      expect(find.textContaining('my dad is in hospital'), findsWidgets);
      expect(find.textContaining('the rent is due again'), findsNothing);
    });

    testWidgets(
        'finds an entry filed under ANY tab — searching from the '
        'archive is one question, not four', (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);
      // A Name, which is what the Reflections tab's chips cannot filter on.
      await type(t, 'razzaq');

      expect(find.textContaining('the rent is due again'), findsWidgets);
    });

    testWidgets('says so plainly when nothing matches', (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'zzzzz');

      expect(find.text('Nothing matches that.'), findsOneWidget);
    });

    testWidgets('clearing the field returns to the prompt', (t) async {
      await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'hospital');
      expect(find.text('1 entry'), findsOneWidget);

      await t.tap(find.byIcon(Icons.close_rounded));
      await t.pumpAndSettle();

      expect(find.text('Search your entries, your duas and the Names.'),
          findsOneWidget);
    });
  });

  group('journal_searched', () {
    testWidgets('one event per SETTLED query, not one per keystroke',
        (t) async {
      final spy = await pump(t, reflections: corpus);
      await openSearch(t);

      // Four keystrokes inside the debounce window.
      for (final q in ['h', 'ho', 'hos', 'hospital']) {
        await keystroke(t, q);
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(propsFor(spy, AnalyticsEvents.journalSearched), isEmpty,
          reason: 'nothing has settled yet');

      await t.pump(const Duration(seconds: 1));

      final events = propsFor(spy, AnalyticsEvents.journalSearched);
      expect(events, hasLength(1));
      expect(events.single![AnalyticsEvents.propResultCount], 1);
      expect(events.single![AnalyticsEvents.propHasResults], isTrue);
    });

    testWidgets(
        'a search that finds nothing is the slice that matters, so it '
        'still reports', (t) async {
      final spy = await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'zzzzz');
      await t.pump(const Duration(seconds: 1));

      final events = propsFor(spy, AnalyticsEvents.journalSearched);
      expect(events, hasLength(1));
      expect(events.single![AnalyticsEvents.propResultCount], 0);
      expect(events.single![AnalyticsEvents.propHasResults], isFalse);
    });

    testWidgets(
        'the query itself never reaches analytics — not the text and '
        'not its length', (t) async {
      final spy = await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'hospital');
      await t.pump(const Duration(seconds: 1));

      for (final (_, props) in spy.tracked) {
        for (final value in (props ?? const {}).values) {
          expect(value.toString().toLowerCase(), isNot(contains('hospital')));
        }
        expect((props ?? const {}).keys, isNot(contains('query')));
        expect((props ?? const {}).keys, isNot(contains('query_length')));
      }
    });

    testWidgets(
        'clearing the field emits nothing — an empty query is not a '
        'search', (t) async {
      final spy = await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, '');
      await t.pump(const Duration(seconds: 1));

      expect(propsFor(spy, AnalyticsEvents.journalSearched), isEmpty);
    });

    testWidgets(
        'cancelling mid-type cancels the pending event — the timer '
        'outlives the mode otherwise', (t) async {
      final spy = await pump(t, reflections: corpus);
      await openSearch(t);
      await keystroke(t, 'hospital');
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle(const Duration(seconds: 2));

      expect(propsFor(spy, AnalyticsEvents.journalSearched), isEmpty);
    });
  });

  group('opening a result', () {
    testWidgets(
        'carries origin: journal_search, so "people find things and '
        'read them" is separable from "people scroll and read things"',
        (t) async {
      final spy = await pump(t, reflections: corpus);
      await openSearch(t);
      await type(t, 'hospital');

      await t.tap(find.textContaining('my dad is in hospital').first);
      await t.pumpAndSettle();

      final opened = propsFor(spy, AnalyticsEvents.journalEntryOpened);
      expect(opened, hasLength(1));
      expect(opened.single![AnalyticsEvents.propOrigin],
          AnalyticsEvents.originJournalSearch);
    });
  });
}
