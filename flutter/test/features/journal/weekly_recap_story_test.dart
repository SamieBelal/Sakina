// The Journal's weekly recap, rebuilt as a door and a story (2026-08-06).
//
// Three separate things can go wrong here and each has its own group.
//
//  * THE BEATS. `themes` is empty whenever nobody's words matched a bucket —
//    the model's own doc comment calls that common — and `oneLine` is empty for
//    a week that produced no line worth handing back. A tap-through flow that
//    renders those as screens gives the reader a blank card they cannot tell
//    from a crash, so the beats are content-driven and the count is the proof.
//
//  * THE CADENCE. `resolveWeeklyRecap` is a WINDOW rule, not a rhythm: two
//    entries inside a ROLLING seven days is true EVERY DAY for anyone writing
//    regularly, with content that barely moves. `journal_resurfacing.dart` opens
//    by naming that failure — "a resurfacing feature that fires every day is a
//    feed" — and the recap was the one resolver with nothing keeping it quiet.
//    The gate is one per calendar week, and the test that matters is the SECOND
//    visit in the same week.
//
//  * THE DISMISSAL, which is a repeat of a real shipped bug (af71431).
//    `BeatRevealFlow` wraps itself in `PopScope(canPop: false)` whose handler
//    steps back one beat — that is how the back GESTURE works and it is right.
//    A completion button routed through `maybePop` is therefore refused its pop
//    and handed to `_back()`: "Done" on the last beat sends the reader back one
//    screen instead of leaving. These pump the real page on a real Navigator,
//    because `BeatRevealFlow` alone cannot reproduce it — the PopScope is in the
//    widget and the pop call is in the host.
//
// MUTATION: any one of these should fail —
//   * drop the `if (line.isNotEmpty)` guard in `buildWeeklyRecapScreens` → the
//     skip-empty group fails with a blank fourth beat;
//   * make `weeklyRecapIsDue` return `true` unconditionally → "a second visit in
//     the same week" fails, still showing the recap;
//   * put `maybePop` back in `WeeklyRecapStoryPage._dismiss` → "Done leaves"
//     fails, still showing the story.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/features/journal/screens/journal_screen.dart';
import 'package:sakina/features/journal/screens/new_reflection_screen.dart'
    show newReflectionRoutePath;
import 'package:sakina/features/journal/screens/weekly_recap_story_page.dart';
import 'package:sakina/features/journal/widgets/weekly_recap_card.dart';
import 'package:sakina/features/journal/widgets/weekly_recap_line.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_models.dart';

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

final _today = DateTime.utc(2026, 8, 2, 20); // a Sunday

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

  WeeklyRecap recap({
    int entryCount = 3,
    List<String> themes = const ['Anxiety & Worry'],
    List<String> names = const ['Al-Wakeel', 'Al-Halim'],
    String oneLine = 'I cannot sleep because I keep worrying about money.',
  }) =>
      WeeklyRecap(
        entryCount: entryCount,
        themes: themes,
        names: names,
        oneLine: oneLine,
      );

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

  // ── The beats ─────────────────────────────────────────────────────────────

  group('buildWeeklyRecapScreens', () {
    test('four beats, in the order the recap is read in', () {
      final screens = buildWeeklyRecapScreens(recap());
      expect(screens.map((s) => s.kind).toList(), [
        BeatKind.keyLine, // the count
        BeatKind.story, // what you carried
        BeatKind.story, // who you met
        BeatKind.entryCover, // in your words
      ]);
      expect(screens[0].primary, 'Seven nights. You wrote on three of them.');
      expect(screens[1].label, JournalResurfacingCopy.recapThemesLabel);
      expect(screens[1].primary, 'Anxiety & Worry');
      expect(screens[2].label, JournalResurfacingCopy.recapNamesLabel);
      expect(screens[2].primary, 'Al-Wakeel, Al-Halim');
      expect(screens[3].label, JournalResurfacingCopy.recapWordsLabel);
      expect(screens[3].primary,
          'I cannot sleep because I keep worrying about money.');
    });

    test('an empty theme list is SKIPPED, not rendered blank', () {
      // The common case, by the model's own doc comment.
      final screens = buildWeeklyRecapScreens(recap(themes: const []));
      expect(screens, hasLength(3));
      expect(
        screens.where((s) => s.label == JournalResurfacingCopy.recapThemesLabel),
        isEmpty,
      );
      expect(screens.every((s) => s.primary.trim().isNotEmpty), isTrue,
          reason: 'a blank beat inside a tap-through flow is indistinguishable '
              'from a broken one');
    });

    test('an empty one-line is skipped too, and so is an empty Name list', () {
      expect(buildWeeklyRecapScreens(recap(oneLine: '   ')), hasLength(3));
      expect(buildWeeklyRecapScreens(recap(names: const [])), hasLength(3));
      // The floor: a recap with nothing but a count is still one honest beat.
      final bare = buildWeeklyRecapScreens(
        recap(themes: const [], names: const [], oneLine: ''),
      );
      expect(bare, hasLength(1));
      expect(bare.single.kind, BeatKind.keyLine);
    });

    test('the Names beat carries Latin transliterations and nothing else', () {
      // CLAUDE.md: Arabic must never be concatenated into an English Text. The
      // recap has no Arabic to leak, and this is what keeps it that way.
      final screens = buildWeeklyRecapScreens(recap());
      final names = screens[2];
      expect(names.arabic, isEmpty);
      expect(names.primary, isNot(contains(RegExp(r'[؀-ۿ]'))));
    });

    test('there is no duʿā beat, so the skip affordance has nowhere to go', () {
      // `duaScreenIndex`'s -1 contract: callers must hide the control rather
      // than treat it as an index. A recap has no duʿā at all.
      expect(duaScreenIndex(buildWeeklyRecapScreens(recap())), -1);
    });
  });

  group('the opener\'s grammar', () {
    test('two vs three-and-up vs the whole week', () {
      expect(JournalResurfacingCopy.recapOpener(2),
          'Seven nights. You wrote on two of them.');
      expect(JournalResurfacingCopy.recapOpener(3),
          'Seven nights. You wrote on three of them.');
      expect(JournalResurfacingCopy.recapOpener(6),
          'Seven nights. You wrote on six of them.');
      expect(JournalResurfacingCopy.recapOpener(7),
          'Seven nights. You wrote on every one of them.');
    });

    test('the singular edge, and a count the window cannot hold', () {
      // A one-entry recap is unreachable through `resolveWeeklyRecap` (its floor
      // is two) — but the copy must not say "one of them." with a plural word,
      // and a user who wrote twice in one day can push the count past seven.
      expect(JournalResurfacingCopy.recapOpener(1),
          'Seven nights. You wrote on one of them.');
      expect(JournalResurfacingCopy.recapOpener(9),
          'Seven nights. You wrote on every one of them.',
          reason: 'entries are not nights, and the copy must not claim nine of '
              'seven');
    });

    test('never emits a digit', () {
      for (var n = 1; n <= 20; n++) {
        expect(JournalResurfacingCopy.recapOpener(n),
            isNot(contains(RegExp(r'\d'))));
      }
    });
  });

  // ── The cadence gate ──────────────────────────────────────────────────────

  group('the cadence gate, as a rule', () {
    test('the week key is the Monday, so every day of a week agrees', () {
      // 2026-07-27 is a Monday; 2026-08-02 the Sunday that closes it.
      for (final day in [
        '2026-07-27',
        '2026-07-30',
        '2026-08-02',
      ]) {
        expect(weeklyRecapWeekKey(day), '2026-07-27', reason: day);
      }
      expect(weeklyRecapWeekKey('2026-08-03'), '2026-08-03',
          reason: 'the next Monday opens a new week');
    });

    test('due once a week, and every failure mode is fail-OPEN', () {
      expect(
        weeklyRecapIsDue(todayLocalDay: '2026-08-02', lastShownWeek: null),
        isTrue,
        reason: 'never shown',
      );
      expect(
        weeklyRecapIsDue(
            todayLocalDay: '2026-08-02', lastShownWeek: '2026-07-27'),
        isFalse,
        reason: 'already spent this week — this is the whole feature',
      );
      expect(
        weeklyRecapIsDue(
            todayLocalDay: '2026-08-03', lastShownWeek: '2026-07-27'),
        isTrue,
        reason: 'the next Monday brings it back',
      );
      // Garbage, a marker from a schema that moved, and a clock that went
      // backwards all read as "not this week" and therefore SHOW it. A gate that
      // can wedge shut is worse than one that fires twice.
      for (final junk in ['', 'not-a-date', '2027-01-04']) {
        expect(
          weeklyRecapIsDue(todayLocalDay: '2026-08-02', lastShownWeek: junk),
          isTrue,
          reason: junk,
        );
      }
    });

    test('no resolvable day means nothing is due', () {
      expect(weeklyRecapWeekKey(null), isNull);
      expect(weeklyRecapWeekKey('nonsense'), isNull);
      expect(
        weeklyRecapIsDue(todayLocalDay: null, lastShownWeek: null),
        isFalse,
      );
    });
  });

  // ── The gate on the actual screen ─────────────────────────────────────────

  late GoRouter router;

  Future<_Spy> pumpJournal(
    WidgetTester t, {
    required List<SavedReflection> reflections,
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

    router = GoRouter(
      initialLocation: '/journal',
      routes: [
        GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
        GoRoute(
            path: '/muhasabah',
            builder: (_, __) => const Scaffold(body: Text('MUHASABAH ROUTE'))),
        // The Journal's `+` pushes the composer here. Was `/reflect` until
        // 2026-08-07; that route no longer exists, and a stub for a route the
        // screen can no longer reach is a harness lying about the app.
        GoRoute(
            path: newReflectionRoutePath,
            builder: (_, __) =>
                const Scaffold(body: Text('NEW REFLECTION ROUTE'))),
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
    // Two async inputs — the local day and the cadence marker — so the recap
    // slot is not settled on the first frame by construction.
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    return spy;
  }

  /// Leave the Journal and come back — a SECOND VISIT, which is what the gate is
  /// about.
  ///
  /// Navigation, not a second `pumpWidget`: the ProviderScope lives above the
  /// router in the real app and is never rebuilt, so re-pumping one would reuse
  /// the same container and the same cached cadence read, and the test would be
  /// measuring Riverpod's cache instead of the gate. `journalRecapWeekProvider`
  /// is `autoDispose` precisely so that LEAVING is what re-reads it.
  Future<void> revisit(WidgetTester t) async {
    router.go('/muhasabah');
    await t.pumpAndSettle();
    router.go('/journal');
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
  }

  /// Three nights in the trailing week, whose words also reach the lifetime
  /// theme bucket — so the recap and its fallback are BOTH available and the
  /// slot's answer is the only thing under test.
  List<SavedReflection> aWeekOfNights() => [
        muhasabah(day: '2026-08-02', words: 'anxious about money'),
        muhasabah(day: '2026-08-01', words: 'stressed about the exam'),
        muhasabah(
            day: '2026-07-31',
            words: 'worried about my father and I have told nobody'),
      ];

  group('the recap slot in the Journal', () {
    testWidgets('is a slim line, not the block — and the block is gone from '
        'this screen entirely', (t) async {
      await pumpJournal(t, reflections: aWeekOfNights());

      expect(find.byType(WeeklyRecapLine), findsOneWidget);
      expect(find.byType(WeeklyRecapCard), findsNothing,
          reason: '~19% of the viewport, pushing the first entry to ~57% down '
              'the screen, is what this replaced');
      // It leads with the user's own words; the category is the tail.
      expect(find.textContaining('worried about my father'), findsWidgets);
      expect(find.text(JournalResurfacingCopy.recapLineTrail), findsOneWidget);
      expect(find.textContaining('You often turn to Allah with'), findsNothing,
          reason: 'two theme claims stacked is what this slot exists to '
              'prevent, and that has not changed');
    });

    testWidgets('a SECOND visit in the same week suppresses it and falls back '
        'to the lifetime line', (t) async {
      await pumpJournal(t, reflections: aWeekOfNights());
      expect(find.byType(WeeklyRecapLine), findsOneWidget);

      await revisit(t);

      expect(find.byType(WeeklyRecapLine), findsNothing,
          reason: 'the window rule is true again today, which is exactly the '
              'every-day feed the gate exists to stop');
      expect(find.textContaining('You often turn to Allah with'), findsOneWidget,
          reason: 'suppressed must mean the SAME fallback an empty window gets, '
              'not an empty slot');
    });

    testWidgets('the next week brings it back — the gate cannot wedge shut',
        (t) async {
      await pumpJournal(t, reflections: aWeekOfNights());
      await revisit(t);
      expect(find.byType(WeeklyRecapLine), findsNothing);

      // Monday. The window still holds two of the three nights.
      // `debugResetUserLocalDay` clears the memo AND both seams, so it has to
      // come first — setting the clock and then resetting silently un-sets it.
      debugResetUserLocalDay();
      debugUserTimeZoneOverride = 'UTC';
      debugUserLocalDayClock = () => DateTime.utc(2026, 8, 3, 20);
      await revisit(t);

      expect(find.byType(WeeklyRecapLine), findsOneWidget);
    });

    testWidgets('a marker written for another account does not silence this one',
        (t) async {
      SharedPreferences.setMockInitialValues({
        '$weeklyRecapLastWeekPrefsKey:someone-else': '2026-07-27',
      });
      await pumpJournal(t, reflections: aWeekOfNights());
      expect(find.byType(WeeklyRecapLine), findsOneWidget);
    });

    testWidgets('survives a search round-trip — the marker is written the '
        'moment it shows, so a re-read of it would suppress the line the user '
        'is looking at', (t) async {
      // `_buildInlineStats` is not built in search mode, so the cadence
      // provider (autoDispose) loses its last watcher and re-reads on the way
      // back — by which time the marker exists. The gate is latched per visit
      // for exactly this reason.
      await pumpJournal(t, reflections: aWeekOfNights());
      expect(find.byType(WeeklyRecapLine), findsOneWidget);

      await t.tap(find.byTooltip('Search'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      expect(find.byType(WeeklyRecapLine), findsOneWidget,
          reason: 'cancelling a search must not delete the recap');
    });

    testWidgets('a week with no quotable line leads with the category instead',
        (t) async {
      // `oneLine` can be empty. The line has no quote to lead with then, so the
      // filing category becomes the whole sentence rather than a dangling tail.
      await pumpJournal(t, reflections: [
        muhasabah(day: '2026-08-02', words: '   '),
        muhasabah(day: '2026-08-01', words: ''),
      ]);

      expect(find.byType(WeeklyRecapLine), findsOneWidget);
      expect(find.text(JournalResurfacingCopy.recapHeader), findsOneWidget);
      expect(find.text(JournalResurfacingCopy.recapLineTrail), findsNothing);
    });

    testWidgets('an empty window still falls through to the lifetime line',
        (t) async {
      await pumpJournal(t, reflections: [
        muhasabah(day: '2026-01-02', words: 'anxious'),
        muhasabah(day: '2026-01-03', words: 'stressed'),
        muhasabah(day: '2026-01-04', words: 'worried'),
      ]);
      expect(find.byType(WeeklyRecapLine), findsNothing);
      expect(
          find.textContaining('You often turn to Allah with'), findsOneWidget);
    });

    testWidgets('the visit event reports what the archive ACTUALLY opened with',
        (t) async {
      final spy = await pumpJournal(t, reflections: aWeekOfNights());
      List<Map<String, dynamic>?> visits() => spy.tracked
          .where((e) => e.$1 == AnalyticsEvents.journalResurfacingShown)
          .map((e) => e.$2)
          .toList();

      expect(visits(), hasLength(1));
      expect(visits().first![AnalyticsEvents.propWeeklyRecap], isTrue);

      await revisit(t);

      expect(visits(), hasLength(2),
          reason: 'a visit is a visit whether or not the recap was in it');
      expect(
        visits().last![AnalyticsEvents.propWeeklyRecap],
        isFalse,
        reason: 'a property that counts what the gate would have allowed counts '
            'something no user saw',
      );
    });
  });

  group('opening it', () {
    testWidgets('the line opens the story, and the event is structural only',
        (t) async {
      final spy = await pumpJournal(t, reflections: aWeekOfNights());

      await t.tap(find.byType(WeeklyRecapLine));
      await t.pumpAndSettle();

      expect(find.byType(WeeklyRecapStoryPage), findsOneWidget);

      final opened = spy.tracked
          .where((e) => e.$1 == AnalyticsEvents.journalRecapOpened)
          .single
          .$2!;
      expect(opened, {
        AnalyticsEvents.propEntryCount: 3,
        AnalyticsEvents.propBeatCount: 4,
      });
      // Exact-match above is the guard; this states the reason out loud.
      for (final v in opened.values) {
        expect(v, isA<int>(),
            reason: 'the door leads with the user\'s own words and none of '
                'them may travel with the tap');
      }
    });
  });

  // ── The dismissal ─────────────────────────────────────────────────────────

  group('WeeklyRecapStoryPage — leaving it', () {
    Future<void> pumpPushed(
      WidgetTester t,
      WeeklyRecap r, {
      bool reduceMotion = false,
    }) async {
      await t.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WeeklyRecapStoryPage(recap: r),
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

    Future<void> tapThroughToLast(WidgetTester t, WeeklyRecap r) async {
      final count = buildWeeklyRecapScreens(r).length;
      for (var i = 0; i < count - 1; i++) {
        await t.tapAt(const Offset(700, 400));
        await t.pumpAndSettle();
      }
    }

    testWidgets('a recap is a reading, not a supplication', (t) async {
      final r = recap();
      await pumpPushed(t, r);
      await tapThroughToLast(t, r);
      expect(find.text('Ameen'), findsNothing);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('"Done" on the last beat leaves the story', (t) async {
      final r = recap();
      await pumpPushed(t, r);
      await tapThroughToLast(t, r);

      await t.tap(find.text('Done'));
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsOneWidget,
          reason: 'the story route must be gone');
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('it does NOT step back one beat — the exact symptom of the '
        'maybePop bug', (t) async {
      final r = recap();
      final screens = buildWeeklyRecapScreens(r);
      final previous = screens[screens.length - 2].primary;
      expect(previous, 'Al-Wakeel, Al-Halim',
          reason: 'the fixture must know which beat sits one step back');

      await pumpPushed(t, r);
      await tapThroughToLast(t, r);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();

      expect(find.text(previous), findsNothing,
          reason: 'landing on the previous beat IS the bug');
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('a double-tap pops once — an unconditional pop would take the '
        'Journal underneath it too', (t) async {
      final r = recap();
      await pumpPushed(t, r);
      await tapThroughToLast(t, r);

      await t.tap(find.text('Done'));
      await t.tap(find.text('Done'), warnIfMissed: false);
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsOneWidget,
          reason: 'the host route must survive');
    });

    testWidgets('the back GESTURE still means "one beat back", not "leave"',
        (t) async {
      final r = recap();
      await pumpPushed(t, r);
      await t.tapAt(const Offset(700, 400));
      await t.pumpAndSettle();

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();

      expect(find.text('OPEN'), findsNothing,
          reason: 'the PopScope is what makes back a beat control');
    });

    testWidgets('the back gesture on the FIRST beat does leave', (t) async {
      await pumpPushed(t, recap());
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text('OPEN'), findsOneWidget,
          reason: 'back on beat 0 routes through onReturnHome, which is the '
              'same dismissal — it must not be swallowed either');
    });

    testWidgets('reduced motion loses the movement and NOTHING else', (t) async {
      // `motion_context.dart`'s rule: less movement, not less content and not
      // fewer taps. Same beat count, same content, same way out — the journal
      // is required to honour the setting and read it nowhere at all until
      // recently.
      final r = recap();
      await pumpPushed(t, r, reduceMotion: true);
      expect(find.text('Seven nights. You wrote on three of them.'),
          findsOneWidget);

      await tapThroughToLast(t, r);
      expect(find.textContaining('I cannot sleep because'), findsOneWidget);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('a recap with only a count is still a complete flow', (t) async {
      // One beat, so it is the last beat, so the completion pill is up
      // immediately and there is nothing to tap through.
      final r = recap(themes: const [], names: const [], oneLine: '');
      await pumpPushed(t, r);
      expect(find.text('Done'), findsOneWidget);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(find.text('OPEN'), findsOneWidget);
    });
  });
}
