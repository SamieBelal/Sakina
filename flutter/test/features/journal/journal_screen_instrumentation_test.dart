// Wave H — the Journal screen's own events.
//
// The provider-side half lives in `journaling_instrumentation_test.dart`. What
// can only go wrong here is the wiring: an event emitted from `build` counts
// rebuilds instead of visits, an `origin` hard-coded at one of three doors
// makes the other two invisible, and a compose control whose three meanings
// collapse into one property value stops answering the only question D3 has.
//
// The screen emits through `ref.read(analyticsProvider).track` (it has Riverpod,
// unlike the notifiers), so the spy is a provider override.
//
// MUTATION: move the `journal_resurfacing_shown` emit out of the
// `_resurfacingFired` latch → the "exactly once per visit" test fails with a
// count that tracks frames.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';
import 'package:sakina/features/journal/journal_compose_action.dart';
import 'package:sakina/features/journal/screens/journal_screen.dart';
import 'package:sakina/features/journal/screens/new_reflection_screen.dart'
    show newReflectionRoutePath;
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
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }

  @override
  Future<bool> appendToTonight(
    String text, {
    String surface = AnalyticsEvents.surfaceMuhasabah,
  }) async =>
      true;
}

/// Captures what would reach Mixpanel. Extends the real service so the screen's
/// `ref.read(analyticsProvider)` is satisfied by type, not by a mock protocol.
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

  SavedReflection muhasabah({
    required String day,
    String words = 'I could not sleep.',
    bool withStory = false,
  }) =>
      SavedReflection(
        id: 'm-$day',
        date: '${day}T21:00:00.000',
        userText: words,
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: 'Forbearance is not indifference.',
        source: reflectionSourceMuhasabah,
        entryLocalDay: day,
        // Beats are what make an entry re-readable AS A STORY (D2). Without
        // them the same tap lands on the detail page, and `format` is the only
        // thing that tells the two re-reads apart.
        reframeKey: withStory ? 'He gave you room to return.' : '',
        reframeBody: withStory ? 'Forbearance is not indifference.' : '',
        takeaway: withStory ? 'A choice made when it costs most.' : '',
      );

  SavedReflection reflectSave() => const SavedReflection(
        id: 'r1',
        date: '2026-08-01T10:00:00.000',
        userText: 'The interview is tomorrow and I cannot sleep.',
        name: 'Al-Wakeel',
        nameArabic: 'الوكيل',
        reframePreview: 'You are not carrying the outcome.',
      );

  Future<_Spy> pump(
    WidgetTester t, {
    List<SavedReflection> reflections = const [],
    DailyLoopState? loop,
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
          dailyLoopProvider
              .overrideWith((_) => _StubLoop(loop ?? const DailyLoopState(loaded: true))),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // The local day is a future; every Wave E resolver returns null while it is
    // loading, so the first frame is not the visit.
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    return spy;
  }

  List<Map<String, dynamic>?> propsFor(_Spy spy, String event) =>
      spy.tracked.where((e) => e.$1 == event).map((e) => e.$2).toList();

  group('journal_resurfacing_shown — once per visit, session-aggregated', () {
    testWidgets('names the surfaces the archive opened with', (t) async {
      final spy = await pump(t, reflections: [
        // Exactly 30 nights back → "On This Night". Two more inside the week
        // put the recap over its two-entry floor.
        muhasabah(day: '2026-07-03', words: 'The result comes Thursday.'),
        muhasabah(day: '2026-08-01'),
        muhasabah(day: '2026-07-31'),
      ]);

      final shown = propsFor(spy, AnalyticsEvents.journalResurfacingShown);
      expect(shown, hasLength(1));
      expect(shown.single![AnalyticsEvents.propOnThisNight], isTrue);
      expect(shown.single![AnalyticsEvents.propWeeklyRecap], isTrue);
      expect(shown.single![AnalyticsEvents.propAnsweredPrompt], isFalse);
      expect(shown.single![AnalyticsEvents.propOffsetDays], 30);
    });

    testWidgets('an archive with nothing to resurface still reports', (t) async {
      // The all-false row is the common case AND the honest denominator: without
      // it, "how often does Wave E have anything to say" has no bottom half.
      final spy = await pump(t, reflections: [reflectSave()]);

      final shown = propsFor(spy, AnalyticsEvents.journalResurfacingShown);
      expect(shown, hasLength(1));
      expect(shown.single![AnalyticsEvents.propOnThisNight], isFalse);
      expect(shown.single![AnalyticsEvents.propWeeklyRecap], isFalse);
      expect(shown.single![AnalyticsEvents.propAnsweredPrompt], isFalse);
      expect(shown.single!.containsKey(AnalyticsEvents.propOffsetDays), isFalse);
    });

    testWidgets('rebuilds do not re-emit it', (t) async {
      final spy = await pump(t, reflections: [muhasabah(day: '2026-08-01')]);

      // A tab switch rebuilds the whole screen through the TabController's
      // `setState`. If the emit were not latched, this alone would double it.
      await t.tap(find.byKey(const ValueKey('journal-tab-1')));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.byKey(const ValueKey('journal-tab-0')));
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      expect(propsFor(spy, AnalyticsEvents.journalResurfacingShown),
          hasLength(1));
    });
  });

  group('journal_entry_opened — one event, three doors', () {
    // 2026-08-06: the two doors SWAPPED. Tapping a card opens the STORY, and
    // the footer's "View full" hint — which was always drawn there — is now the
    // detail page's door. The format the archive was rebuilt around had been
    // the one you must opt into, which left D2's own complaint (two lines of
    // grey text) as the default the whole time.
    testWidgets('the feed opens an entry as a STORY', (t) async {
      final spy = await pump(
        t,
        reflections: [muhasabah(day: '2026-08-01', withStory: true)],
      );

      await t.tap(find.text('Al-Halim').first);
      await t.pumpAndSettle();

      expect(propsFor(spy, AnalyticsEvents.journalEntryOpened).single, {
        AnalyticsEvents.propOrigin: AnalyticsEvents.originJournalFeed,
        AnalyticsEvents.propFormat: AnalyticsEvents.entryFormatStory,
        AnalyticsEvents.propSource: AnalyticsEvents.journalSourceMuhasabah,
      });
    });

    testWidgets('an entry with nothing to render still opens the detail page '
        '— the story would be a cover card and nothing else', (t) async {
      // No Name and no beats: `canRenderAsStory` builds an EMPTY screen list,
      // which is the case the fallback exists for. (A Name alone is enough to
      // pass that check — see the note in `reflection_story_page.dart`.)
      final spy = await pump(t, reflections: [
        const SavedReflection(
          id: 'bare',
          date: '2026-08-01T21:00:00.000',
          userText: 'Just a hard day.',
          name: '',
          nameArabic: '',
          reframePreview: 'preview',
          source: reflectionSourceMuhasabah,
          entryLocalDay: '2026-08-01',
        ),
      ]);

      await t.tap(find.textContaining('Just a hard day').first);
      await t.pumpAndSettle();

      expect(
        propsFor(spy, AnalyticsEvents.journalEntryOpened)
            .single![AnalyticsEvents.propFormat],
        AnalyticsEvents.entryFormatDetail,
      );
    });

    testWidgets('"View full" is the same event with a different format — the '
        'detail page must stay reachable, it is the only home of share, '
        'delete and edit', (t) async {
      final spy = await pump(
        t,
        reflections: [muhasabah(day: '2026-08-01', withStory: true)],
      );

      await t.tap(find.text('View full'));
      await t.pumpAndSettle();

      final opened = propsFor(spy, AnalyticsEvents.journalEntryOpened).single;
      expect(opened![AnalyticsEvents.propFormat],
          AnalyticsEvents.entryFormatDetail);
      expect(opened[AnalyticsEvents.propOrigin],
          AnalyticsEvents.originJournalFeed,
          reason: 'the second door is a second FORMAT from the feed, not a '
              'second origin — forking it would make "entries re-read" a union');
    });

    testWidgets('the "Read as story" link is gone — the story is what a tap '
        'does, so a control for it is a control for nothing', (t) async {
      await pump(
        t,
        reflections: [muhasabah(day: '2026-08-01', withStory: true)],
      );

      expect(find.text('Read as story'), findsNothing);
    });

    testWidgets('a Reflect save is separable from a night', (t) async {
      final spy = await pump(t, reflections: [reflectSave()]);

      await t.tap(find.text('Al-Wakeel').first);
      await t.pumpAndSettle();

      expect(
        propsFor(spy, AnalyticsEvents.journalEntryOpened)
            .single![AnalyticsEvents.propSource],
        AnalyticsEvents.journalSourceReflect,
      );
    });

    testWidgets('"On This Night" carries its own origin', (t) async {
      final spy = await pump(t, reflections: [
        muhasabah(day: '2026-07-03', words: 'The result comes Thursday.'),
      ]);

      await t.tap(find.text(JournalResurfacingCopy.onThisNightOpen));
      await t.pumpAndSettle();

      expect(
        propsFor(spy, AnalyticsEvents.journalEntryOpened)
            .single![AnalyticsEvents.propOrigin],
        AnalyticsEvents.originOnThisNight,
        reason: 'E1 is the reason Wave E exists; if its opens are filed under '
            'the feed, the card can never be shown to work',
      );
    });
  });

  group('the two controls D4 and D3 promoted', () {
    testWidgets('the calendar emits its own denominator', (t) async {
      final spy = await pump(t, reflections: [muhasabah(day: '2026-08-01')]);

      await t.tap(find.byTooltip('Browse by month'));
      await t.pumpAndSettle();

      expect(propsFor(spy, AnalyticsEvents.journalBrowseOpened), hasLength(1),
          reason: 'without it, a calendar nobody converts from reads exactly '
              'like one nobody opens');
    });

    testWidgets('the compose control reports its meaning and its rendering',
        (t) async {
      final spy = await pump(t, reflections: [muhasabah(day: '2026-08-01')]);

      // 2026-08-07: the FAB opens a chooser, so pressing it is no longer an
      // ACT. `journal_compose_opened` is the denominator; `..._tapped` still
      // fires once per chosen action, with the same shape it always had, so
      // the existing series is unbroken.
      await t.tap(find.byKey(const ValueKey('journal-compose-fab')));
      await t.pumpAndSettle();

      expect(propsFor(spy, AnalyticsEvents.journalComposeOpened).single, {
        AnalyticsEvents.propOptionCount: 2,
      });
      expect(propsFor(spy, AnalyticsEvents.journalComposeTapped), isEmpty,
          reason: 'opening the chooser is not composing — counting it as one '
              'would inflate every conversion built on this event');

      await t.tap(find.descendant(
        of: find.byKey(const ValueKey('journal-compose-menu')),
        matching: find.text(
            JournalComposeCopy.label(JournalComposeAction.startTonight)),
      ));
      await t.pumpAndSettle();

      expect(propsFor(spy, AnalyticsEvents.journalComposeTapped).single, {
        AnalyticsEvents.propAction: AnalyticsEvents.composeActionStartTonight,
        AnalyticsEvents.propEntryPoint: AnalyticsEvents.composeEntryFab,
      });
    });

    testWidgets('the empty state is a different entry point, same event',
        (t) async {
      final spy = await pump(t);

      // The empty All tab renders the same control with its own copy. Whether
      // THAT one converts is a different question from the FAB's, and one event
      // with two entry points is how both get asked.
      // The label renders twice — once in the empty state, once on the FAB.
      // The FAB is the Scaffold's, so it comes last in the tree.
      await t.tap(find.text('Begin Muḥāsabah').first);
      await t.pumpAndSettle();

      expect(
        propsFor(spy, AnalyticsEvents.journalComposeTapped)
            .single![AnalyticsEvents.propEntryPoint],
        AnalyticsEvents.composeEntryEmptyState,
      );
    });
  });

  // NOTE: there was a test here called "this suite would notice a payload
  // carrying words". It asserted `AnalyticsEvents.propSource == 'source'` and
  // would have passed with this entire file deleted. Removed rather than
  // repaired: a test whose NAME claims a privacy guarantee its BODY does not
  // check is worse than no test, because the next reader trusts the name.
  //
  // What actually guards this screen: every payload above is asserted verbatim
  // and consists only of booleans, ints and fixed constants, so a user string
  // could not appear without failing one of those exact-match expectations. The
  // named-field sweep in `no_free_text_reaches_analytics_test.dart` is the
  // other half — and note its own honest ceiling: it is an allowlist and cannot
  // see a field nobody added to it.
}
