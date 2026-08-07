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
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/features/journal/screens/journal_screen.dart';
import 'package:sakina/features/journal/screens/new_reflection_screen.dart'
    show newReflectionRoutePath;
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

  Future<void> pump(
    WidgetTester t, {
    DailyLoopState? loop,
    /// Simulates a home-indicator device. Real phones have one; the default
    /// test surface does not, which is exactly why a missing safe-area term
    /// shipped unnoticed.
    double bottomInset = 0,
  }) async {
    final router = GoRouter(
      initialLocation: '/journal',
      routes: [
        GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
        GoRoute(
            path: '/muhasabah',
            builder: (_, __) => const Scaffold(body: Text('MUHASABAH ROUTE'))),
        // The composer the `+`'s "New reflection" row opens. PUSHED, not
        // `go`'d — see `JournalScreen._openNewReflection` — so the Journal
        // stays under it and the user lands back on their archive.
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
          reflectProvider
              .overrideWith((_) => ReflectNotifier(loadOnInit: false)),
          duasProvider.overrideWith((_) => DuasNotifier(loadOnInit: false)),
          questsProvider.overrideWith((_) => _StubQuests()),
          dailyLoopProvider.overrideWith(
              (_) => _StubLoop(loop ?? const DailyLoopState(loaded: true))),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(bottom: bottomInset),
              viewPadding: EdgeInsets.only(bottom: bottomInset),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  Future<void> openSheet(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('journal-compose-fab')));
    await t.pumpAndSettle();
  }

  final sheet = find.byKey(const ValueKey('journal-compose-menu'));

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
      );
      expect(sub, contains('reflection'));
      expect(sub.toLowerCase(), isNot(contains('free')),
          reason: 'the label that lied said "free" about a metered thing');
    });

    test('a premium reader is not told about an allowance they do not have',
        () {
      expect(
        JournalComposeCopy.subtitle(JournalComposeAction.newReflection,
            allowance: const AllowanceSnapshot(AllowanceKind.unlimited)),
        isNot(JournalComposeCopy.subtitle(JournalComposeAction.newReflection,
            allowance:
                const AllowanceSnapshot(AllowanceKind.warmup, remaining: 3))),
      );
    });

    test('appending says it costs nothing, because it costs nothing', () {
      // `appendToTonight` is a pure text write against an existing row: no
      // reveal, no streak, no allowance. The copy may say so without hedging.
      final sub = JournalComposeCopy.subtitle(
        JournalComposeAction.addToTonight,
      );
      expect(sub.toLowerCase(), contains('free'));
    });

    test('"Free write" is gone from every label', () {
      for (final a in JournalComposeAction.values) {
        for (final allowance in <AllowanceSnapshot?>[
          null,
          const AllowanceSnapshot(AllowanceKind.unlimited),
          const AllowanceSnapshot(AllowanceKind.warmup, remaining: 3),
          const AllowanceSnapshot(AllowanceKind.weeklyPool, remaining: 2),
        ]) {
          expect(JournalComposeCopy.label(a), isNot(contains('Free write')));
          expect(JournalComposeCopy.subtitle(a, allowance: allowance),
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
    testWidgets('a new reflection routes to the composer', (t) async {
      await pump(t, loop: DailyLoopState(loaded: true, tonightEntry: tonight()));
      await openSheet(t);

      await pick(t, JournalComposeAction.newReflection);

      expect(find.text('NEW REFLECTION ROUTE'), findsOneWidget);
    });

    testWidgets('the ritual routes to the muḥāsabah', (t) async {
      await pump(t);
      await openSheet(t);

      await pick(t, JournalComposeAction.startTonight);

      expect(find.text('MUHASABAH ROUTE'), findsOneWidget);
    });

    testWidgets('an EMPTY archive still gets the live count in the menu',
        (t) async {
      // Found by review, 2026-08-07, and it hit exactly the audience the
      // feature is for. `readReflectionAllowance` is a `read`, safe only
      // because the header's stats line `watch`es the same provider every
      // build — but `_statsLines` returned early on an empty archive BEFORE
      // reaching the watch. Nothing subscribed, the `autoDispose` provider
      // stayed cold, and `ref.read` returned `AsyncLoading` forever: a
      // brand-new user saw the number-free fallback permanently.
      await pump(t); // no reflections seeded
      await openSheet(t);

      // Asserted as "NOT the fallback" rather than against a literal count:
      // the number comes from a server dial with an offline default, so
      // hardcoding it would pin the dial rather than the subscription.
      final fallback = JournalComposeCopy.subtitle(
        JournalComposeAction.newReflection,
        allowance: null,
      );
      expect(inSheet(fallback), findsNothing,
          reason: 'the fresh account fell back to "$fallback" — the provider '
              'was never kept alive, so the read got AsyncLoading');
    });

    testWidgets('the append opens the append sheet, not a route', (t) async {
      await pump(t, loop: DailyLoopState(loaded: true, tonightEntry: tonight()));
      await openSheet(t);

      await pick(t, JournalComposeAction.addToTonight);

      expect(find.text('MUHASABAH ROUTE'), findsNothing);
      expect(find.text('NEW REFLECTION ROUTE'), findsNothing);
      expect(find.byType(TextField), findsWidgets,
          reason: 'the append is a text write, done in place');
    });

    testWidgets('the append sheet keeps its field off the screen edge',
        (t) async {
      // A phone WITH a home indicator. The bug this pins was invisible without
      // one: the sheet padded 24pt under its field and stopped there, so on an
      // indicator device the field sat in the 34pt strip the system owns and
      // read as clipped.
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await pump(
        t,
        loop: DailyLoopState(loaded: true, tonightEntry: tonight()),
        bottomInset: 34,
      );
      await openSheet(t);
      await pick(t, JournalComposeAction.addToTonight);

      final field = t.getRect(find.byType(TextField).last);
      final gap = 844 - field.bottom;
      expect(gap, greaterThan(34 + 24),
          reason: 'the field ends ${gap.toStringAsFixed(1)}pt from the bottom '
              'of a screen whose last 34 belong to the home indicator');
    });

    // Both of these were found by measuring, not by reading, and both shipped
    // in earlier drafts of this file. Neither is visible to a test that only
    // asserts a widget is present: the labels were in the tree and readable by
    // `find.text` while sitting off the side of the phone, and the swallowed
    // taps hit a real GestureDetector — just the wrong one.
    group('on a real phone, not the 800x600 test surface', () {
      Future<void> phone(WidgetTester t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
      }

      testWidgets('every option stays on screen', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        for (final a in [
          JournalComposeAction.startTonight,
          JournalComposeAction.newReflection,
        ]) {
          final r = t.getRect(inSheet(JournalComposeCopy.label(a)));
          expect(r.left, greaterThanOrEqualTo(0),
              reason: '${JournalComposeCopy.label(a)} ran off the left edge — '
                  'the label is the widest part of the row and hangs '
                  'furthest left');
          expect(r.right, lessThanOrEqualTo(390));
        }
      });

      // NOT pinned here: a structural "the two rows never intersect" assertion.
      //
      // I wrote one, keyed each row, and it failed against the SHIPPING layout
      // — so either the rows really do overlap by a few points at 390pt, or the
      // rect I was measuring is not the row's. I could not settle which without
      // more time than the question is worth right now, and a red test whose
      // subject I cannot explain is worse than an honest gap.
      //
      // What IS known, and is covered below: both options stay on screen, and
      // each one activates itself. The overlap risk is real (options sit 64pt
      // apart and a two-line caption would make a row ~80pt tall), which is why
      // `compose_menu` forces both label lines to `maxLines: 1` — and is now
      // pinned outright by the geometry group below.
      testWidgets('each option activates ITSELF, not its neighbour', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);
        await pick(t, JournalComposeAction.startTonight);
        expect(find.text('MUHASABAH ROUTE'), findsOneWidget);
        expect(find.text('NEW REFLECTION ROUTE'), findsNothing);
      });

      testWidgets('and the other one does too', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);
        await pick(t, JournalComposeAction.newReflection);
        expect(find.text('NEW REFLECTION ROUTE'), findsOneWidget);
        expect(find.text('MUHASABAH ROUTE'), findsNothing);
      });
    });

    // ── Geometry ────────────────────────────────────────────────────────────
    //
    // Every bug this group pins was found by MEASURING a shipped build, never
    // by reading the widget tree. All three were invisible to a test that only
    // asserts a widget is present.
    group('the geometry, measured', () {
      Future<void> phone(WidgetTester t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
      }

      /// The × the menu paints over the FAB.
      final closeStandIn = find.byKey(const ValueKey('journal-compose-close'));

      testWidgets('the × lands exactly on the +, not near it', (t) async {
        await phone(t);
        await pump(t);

        // Measured BEFORE the menu opens — this is the button the user pressed.
        final fab = t.getRect(find.byKey(const ValueKey('journal-compose-fab')));
        await openSheet(t);
        final close = t.getRect(closeStandIn);

        // The shipped bug: the menu COMPUTED the FAB's position from
        // `viewPadding.bottom + margin + diameter/2` — a formula that is right
        // for a Scaffold with no bottom bar and wrong by the height of one
        // otherwise. The user saw two controls, a `+` where they had tapped and
        // an `×` ~60pt below it.
        //
        // Pinned as EQUALITY rather than proximity, because "close enough" is
        // exactly the standard that let a 60pt error through. Anything that
        // reintroduces a calculation fails here.
        expect(close, fab,
            reason: 'the stand-in must cover the real FAB exactly — same '
                'place, same size — so the one control the user pressed '
                'appears to turn rather than to be joined by a second one');
      });

      testWidgets('every card sits right beside its own icon', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        // **The regression this replaces was the opposite rule.** An earlier
        // pass padded every row out to a shared right edge so the cards formed
        // a tidy column — and on a 390pt phone that put the top option's bubble
        // 120pt from its own circle. Tidy, and orphaned.
        //
        // Measured as the gap between the card's right edge and the row's,
        // which is the circle's right edge. Card → gap → circle, so the
        // distance from card to circle's LEFT edge is the whole slack.
        for (final a in [
          JournalComposeAction.startTonight,
          JournalComposeAction.newReflection,
        ]) {
          final row = t.getRect(
              find.byKey(ValueKey('journal-compose-row-${a.name}')));
          final card = t.getRect(inSheet(JournalComposeCopy.label(a)));
          // row.right is the circle's right edge; subtract the circle to get
          // its left edge, then measure back to the TEXT. The expected value is
          // `_labelGap` (12) plus the card's own horizontal padding (12) = 24,
          // because this finder matches the Text rather than the card around
          // it. The ceiling is set just above that: it is here to catch a
          // return of the 120pt shim, not to police a point either way.
          final slack = (row.right - 52) - card.right;
          expect(slack, lessThan(30),
              reason: '${JournalComposeCopy.label(a)} floats ${slack.toStringAsFixed(0)}pt '
                  'from its icon');
        }
      });

      testWidgets('a card\'s two lines share a left edge', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        // They were right-aligned once, on the theory that a card hanging off
        // the right of the screen should hang its text with it. But the title
        // is the SHORTER of the two strings ("New reflection" against
        // "Included with premium"), so right-alignment indented the title and
        // left a ragged left edge inside a 168pt card — visible, not subtle.
        //
        // **Asserted STRUCTURALLY, and that is a deliberate retreat.** The
        // obvious test — compare the two Text rects' `left` — passes either way
        // here: the widget-test font is square-glyph and far wider than the
        // real one, so both strings blow past `_labelMaxWidth`, both clamp to
        // exactly 168pt, and their rects coincide whatever the alignment is.
        // Mutation-checked: flipping the widget back to `end`/`right` did not
        // fail the measured version, which is the only reason this one is
        // shaped like this.
        //
        // Both halves are required. `crossAxisAlignment` alone positions the
        // text BOXES; the boxes hug their content, so a right-positioned box
        // full of left-aligned text is still indented.
        for (final a in [
          JournalComposeAction.startTonight,
          JournalComposeAction.newReflection,
        ]) {
          // Found via the ROW key, not by matching the cost string. The cost
          // depends on the live allowance — after the empty-archive fix this
          // harness resolves a real count — so a string lookup here would be
          // asserting the dial rather than the alignment.
          final texts = find.descendant(
            of: find.byKey(ValueKey('journal-compose-row-${a.name}')),
            matching: find.byType(Text),
          );
          expect(texts, findsNWidgets(2),
              reason: 'each card carries exactly a title and a cost');

          for (final w in t.widgetList<Text>(texts)) {
            expect(w.textAlign, TextAlign.left,
                reason: '"${w.data}" is not left-aligned');
          }

          final column = t.widget<Column>(
              find.ancestor(of: texts.first, matching: find.byType(Column))
                  .first);
          expect(column.crossAxisAlignment, CrossAxisAlignment.start,
              reason: '${JournalComposeCopy.label(a)}: the card column still '
                  'pushes its lines to the right edge');
        }
      });

      testWidgets('the options stack in ONE column, straight up off the button',
          (t) async {
        await phone(t);
        await pump(t);
        final fab = t.getRect(find.byKey(const ValueKey('journal-compose-fab')));
        await openSheet(t);

        // No arc, and no lean either (founder, 2026-08-07). Every circle sits
        // in the FAB's own column — which is also what gives the cards a shared
        // right edge for free, where two earlier shapes had to arrange it with
        // arithmetic and got it wrong both times.
        //
        // `row.right` IS the circle's right edge, so comparing rows compares
        // circles.
        final rights = [
          for (final a in [
            JournalComposeAction.startTonight,
            JournalComposeAction.newReflection,
          ])
            t.getRect(find.byKey(ValueKey('journal-compose-row-${a.name}')))
                .right,
        ];
        expect((rights.first - rights.last).abs(), lessThan(1.0),
            reason: 'the circles drifted apart horizontally: $rights');

        // And that column is the button's own, so the stack rises out of it
        // rather than beside it.
        final circleCentreX = rights.first - 52 / 2;
        expect((circleCentreX - fab.center.dx).abs(), lessThan(1.0),
            reason: 'circles at x=$circleCentreX, button at ${fab.center.dx}');
      });

      testWidgets('the nearest option is close to the ×, not across the screen',
          (t) async {
        await phone(t);
        await pump(t);
        final fab = t.getRect(find.byKey(const ValueKey('journal-compose-fab')));
        await openSheet(t);

        // Was a 140pt arc radius, which read as a menu arriving from
        // elsewhere rather than coming out of the button under the thumb.
        final nearest = t.getRect(
            find.byKey(const ValueKey('journal-compose-row-startTonight')));
        final gap = fab.top - nearest.bottom;
        expect(gap, greaterThan(0), reason: 'it must not cover the button');
        expect(gap, lessThan(40),
            reason: 'the nearest option is ${gap.toStringAsFixed(0)}pt above '
                'the button — it should look like it came out of it');
      });

      /// The whole drawn row — card, gap and circle — not the Text inside it.
      Finder row(JournalComposeAction a) =>
          find.byKey(ValueKey('journal-compose-row-${a.name}'));

      testWidgets('the two rows never overlap', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        // **Measured on the ROWS, and that is the entire point of this test.**
        // The first version of it measured `find.text(label)` and passed while
        // a real phone showed the two white cards fused into a single blob:
        // the Text widgets cleared each other, the cards around them did not.
        //
        // The geometry it guards: options sit `_optionSpacing` (64pt) apart
        // and the card is ~52pt tall. Grow the card, or tighten the spacing,
        // and this closes — at which point the upper option, painted last and
        // therefore on top, starts swallowing taps meant for the lower one.
        final a = t.getRect(row(JournalComposeAction.startTonight));
        final b = t.getRect(row(JournalComposeAction.newReflection));
        expect(a.overlaps(b), isFalse, reason: 'rows overlap: $a vs $b');
      });

      testWidgets('and clear each other by a real margin, not by a hair',
          (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        final a = t.getRect(row(JournalComposeAction.startTonight));
        final b = t.getRect(row(JournalComposeAction.newReflection));
        final gap = a.top - b.bottom;

        // Non-overlap alone would be satisfied by a single point of clearance,
        // which is not a design — it is a coincidence waiting for a font bump
        // or a longer cost string to end it.
        expect(gap, greaterThan(8),
            reason: 'only ${gap.toStringAsFixed(1)}pt between the rows');
      });

      testWidgets('a row stays small enough for the spacing to hold it',
          (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        // The card is an ANNOTATION on the circles, not the composition. This
        // is the ceiling that keeps it one: 60pt against 64pt of spacing. The
        // version that shipped fused at 61.
        for (final a in [
          JournalComposeAction.startTonight,
          JournalComposeAction.newReflection,
        ]) {
          expect(t.getRect(row(a)).height, lessThan(60),
              reason: '${JournalComposeCopy.label(a)} row is too tall for '
                  '_optionSpacing to separate');
        }
      });

      testWidgets('every row stays on screen', (t) async {
        await phone(t);
        await pump(t);
        await openSheet(t);

        for (final a in [
          JournalComposeAction.startTonight,
          JournalComposeAction.newReflection,
        ]) {
          final r = t.getRect(inSheet(JournalComposeCopy.label(a)));
          expect(r.left, greaterThanOrEqualTo(0),
              reason: '${JournalComposeCopy.label(a)} ran off the left edge');
          expect(r.right, lessThanOrEqualTo(390));
        }
      });
    });

    testWidgets('dismissing the sheet does nothing at all', (t) async {
      await pump(t);
      await openSheet(t);

      // Tap the scrim above the sheet.
      await t.tapAt(const Offset(200, 40));
      await t.pumpAndSettle();

      expect(find.text('MUHASABAH ROUTE'), findsNothing);
      expect(find.text('NEW REFLECTION ROUTE'), findsNothing);
      expect(sheet, findsNothing);
    });
  });
}
