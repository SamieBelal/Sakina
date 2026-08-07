// The Journal's compose control becomes a chooser (2026-08-07).
//
// Wave D shipped ONE control with three meanings, resolved from the day. That
// was right about the problem — the archive had no compose affordance at all —
// and wrong about the shape, for a reason that only shows up in use: the
// control changed identity underneath the user. The same pixel was "Begin
// Muhāsabah" in the morning, "Add to today" after the ritual, and "Free write"
// once the thread filled. A primary control you cannot predict is one you stop
// reaching for.
//
// Worse, its third face lied. "Free write" routed to Reflect, which is metered
// — so a free user who had spent the day's reflection tapped a button labelled
// *free* and met a paywall sheet. The label promised the one thing the
// destination could not give.
//
// And the capability everyone assumed was missing was never missing. "Can I
// write more than one entry today?" — yes: Reflect writes an unlimited number
// of rows per day (`uniq_muhasabah_per_local_day` is partial and does not touch
// them). It was buried behind a button named after neither the act nor its
// cost.
//
// So: a permanent `+` that always opens the same sheet, listing what is
// actually available right now, each row saying what it will cost before it is
// tapped.

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

class _StubQuests extends QuestsNotifier {
  @override
  Future<void> onJournalVisited() async {}
}

class _StubLoop extends DailyLoopNotifier {
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }

  final List<String> appends = [];

  @override
  Future<bool> appendToTonight(
    String text, {
    String surface = AnalyticsEvents.surfaceMuhasabah,
  }) async {
    appends.add(text);
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

  SavedReflection tonight({List<ReflectionThreadEntry> thread = const []}) =>
      SavedReflection(
        id: 'm1',
        date: '2026-08-07T21:00:00.000Z',
        userText: 'I keep replaying it.',
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: 'preview',
        source: reflectionSourceMuhasabah,
        entryLocalDay: '2026-08-07',
        thread: thread,
      );

  List<ReflectionThreadEntry> fullThread() => [
        for (var i = 0; i < 20; i++)
          ReflectionThreadEntry(at: '2026-08-07T2$i:00:00.000Z', text: 'x$i'),
      ];

  Future<void> pump(WidgetTester t, {DailyLoopState? loop}) async {
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
          reflectProvider
              .overrideWith((_) => ReflectNotifier(loadOnInit: false)),
          duasProvider.overrideWith((_) => DuasNotifier(loadOnInit: false)),
          questsProvider.overrideWith((_) => _StubQuests()),
          dailyLoopProvider.overrideWith(
              (_) => _StubLoop(loop ?? const DailyLoopState(loaded: true))),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  Future<void> openSheet(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('journal-compose-fab')));
    await t.pumpAndSettle();
  }

  final sheet = find.byKey(const ValueKey('journal-compose-sheet'));

  /// Scoped to the sheet. The All tab's empty state renders the same labels on
  /// its own CTA, so an unscoped text finder matches both.
  Finder inSheet(String text) =>
      find.descendant(of: sheet, matching: find.text(text));

  Future<void> pick(WidgetTester t, JournalComposeAction a) async {
    await t.tap(inSheet(JournalComposeCopy.label(a)));
    await t.pumpAndSettle();
  }

  // ── The rule ──────────────────────────────────────────────────────────────

  group('what is on offer, given the day', () {
    test('nothing written yet — the ritual first, a reflection under it', () {
      expect(
        journalComposeOptions(tonightEntry: null, checkinDone: false),
        [JournalComposeAction.startTonight, JournalComposeAction.newReflection],
      );
    });

    test('the night happened but left no row — no ritual on offer', () {
      // An offline night, or one the server refused. Offering "Begin" here
      // sends the user at a loop that will tell them they already did it.
      expect(
        journalComposeOptions(tonightEntry: null, checkinDone: true),
        [JournalComposeAction.newReflection],
      );
    });

    test("today's entry is open — appending is free, so it leads", () {
      expect(
        journalComposeOptions(tonightEntry: tonight(), checkinDone: true),
        [JournalComposeAction.addToTonight, JournalComposeAction.newReflection],
      );
    });

    test('a full thread drops the append rather than offering a failure', () {
      expect(
        journalComposeOptions(
            tonightEntry: tonight(thread: fullThread()), checkinDone: true),
        [JournalComposeAction.newReflection],
      );
    });

    test('a new reflection is ALWAYS on offer', () {
      // The one thing that is true on every day, in every state: Reflect writes
      // an unlimited number of rows per day. Whatever else the sheet holds, it
      // holds this.
      for (final options in [
        journalComposeOptions(tonightEntry: null, checkinDone: false),
        journalComposeOptions(tonightEntry: null, checkinDone: true),
        journalComposeOptions(tonightEntry: tonight(), checkinDone: true),
        journalComposeOptions(
            tonightEntry: tonight(thread: fullThread()), checkinDone: true),
      ]) {
        expect(options, contains(JournalComposeAction.newReflection));
      }
    });

    test('the old single-action rule is the head of the new list', () {
      // `resolveJournalComposeAction` still has callers and still means "the
      // one thing to do first". Deriving it keeps the two from drifting.
      for (final (entry, done) in [
        (null, false),
        (null, true),
        (tonight(), true),
        (tonight(thread: fullThread()), true),
      ]) {
        expect(
          resolveJournalComposeAction(tonightEntry: entry, checkinDone: done),
          journalComposeOptions(tonightEntry: entry, checkinDone: done).first,
        );
      }
    });
  });

  // ── The copy ──────────────────────────────────────────────────────────────

  group('the sheet says what a row will cost, before it is tapped', () {
    test('a new reflection states that it spends one', () {
      final sub = JournalComposeCopy.subtitle(
        JournalComposeAction.newReflection,
        isPremium: false,
      );
      expect(sub, contains('reflection'));
      expect(sub.toLowerCase(), isNot(contains('free')),
          reason: 'the label that lied said "free" about a metered thing');
    });

    test('a premium reader is not told about an allowance they do not have',
        () {
      expect(
        JournalComposeCopy.subtitle(JournalComposeAction.newReflection,
            isPremium: true),
        isNot(JournalComposeCopy.subtitle(JournalComposeAction.newReflection,
            isPremium: false)),
      );
    });

    test('appending says it costs nothing, because it costs nothing', () {
      // `appendToTonight` is a pure text write against an existing row: no
      // reveal, no streak, no allowance. The copy may say so without hedging.
      final sub = JournalComposeCopy.subtitle(
        JournalComposeAction.addToTonight,
        isPremium: false,
      );
      expect(sub.toLowerCase(), contains('free'));
    });

    test('"Free write" is gone from every label', () {
      for (final a in JournalComposeAction.values) {
        for (final premium in [true, false]) {
          expect(JournalComposeCopy.label(a), isNot(contains('Free write')));
          expect(JournalComposeCopy.subtitle(a, isPremium: premium),
              isNot(contains('Free write')));
        }
      }
    });
  });

  // ── The control ───────────────────────────────────────────────────────────

  group('the + is one control that never changes identity', () {
    testWidgets('it is a plain +, whatever the day looks like', (t) async {
      await pump(t);
      expect(find.byKey(const ValueKey('journal-compose-fab')), findsOneWidget);
      // The three faces it used to wear.
      expect(find.text('Begin Muhāsabah'), findsNothing);
      expect(find.text('Free write'), findsNothing);

      await pump(t, loop: DailyLoopState(loaded: true, tonightEntry: tonight()));
      expect(find.byKey(const ValueKey('journal-compose-fab')), findsOneWidget);
      expect(find.textContaining('Add to'), findsNothing);
    });

    testWidgets('tapping it offers the ritual and a reflection', (t) async {
      await pump(t);
      await openSheet(t);

      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.startTonight)),
          findsOneWidget);
      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.newReflection)),
          findsOneWidget);
    });

    testWidgets('with today written, it offers the append and a reflection',
        (t) async {
      await pump(t, loop: DailyLoopState(loaded: true, tonightEntry: tonight()));
      await openSheet(t);

      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.addToTonight)),
          findsOneWidget);
      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.newReflection)),
          findsOneWidget);
      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.startTonight)),
          findsNothing,
          reason: 'the ritual is done — offering it again is the duplicate the '
              'one-per-day index would refuse anyway');
    });

    testWidgets('a full thread offers no append it cannot honour', (t) async {
      await pump(t,
          loop: DailyLoopState(
              loaded: true, tonightEntry: tonight(thread: fullThread())));
      await openSheet(t);

      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.addToTonight)),
          findsNothing);
      expect(
          inSheet(JournalComposeCopy.label(JournalComposeAction.newReflection)),
          findsOneWidget);
    });
  });

  // ── Where the rows go ─────────────────────────────────────────────────────

  group('each row goes where it says', () {
    testWidgets('a new reflection routes to Reflect', (t) async {
      await pump(t, loop: DailyLoopState(loaded: true, tonightEntry: tonight()));
      await openSheet(t);

      await pick(t, JournalComposeAction.newReflection);

      expect(find.text('REFLECT ROUTE'), findsOneWidget);
    });

    testWidgets('the ritual routes to the muḥāsabah', (t) async {
      await pump(t);
      await openSheet(t);

      await pick(t, JournalComposeAction.startTonight);

      expect(find.text('MUHASABAH ROUTE'), findsOneWidget);
    });

    testWidgets('the append opens the append sheet, not a route', (t) async {
      await pump(t, loop: DailyLoopState(loaded: true, tonightEntry: tonight()));
      await openSheet(t);

      await pick(t, JournalComposeAction.addToTonight);

      expect(find.text('MUHASABAH ROUTE'), findsNothing);
      expect(find.text('REFLECT ROUTE'), findsNothing);
      expect(find.byType(TextField), findsWidgets,
          reason: 'the append is a text write, done in place');
    });

    testWidgets('dismissing the sheet does nothing at all', (t) async {
      await pump(t);
      await openSheet(t);

      // Tap the scrim above the sheet.
      await t.tapAt(const Offset(200, 40));
      await t.pumpAndSettle();

      expect(find.text('MUHASABAH ROUTE'), findsNothing);
      expect(find.text('REFLECT ROUTE'), findsNothing);
      expect(sheet, findsNothing);
    });
  });
}
