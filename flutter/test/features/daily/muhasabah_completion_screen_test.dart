// The completion screen stops dead-ending (Wave C2).
//
// Before this, the night ended on "Muhāsabah Complete" → a premium-gated card
// re-roll → "Return to Home". Nothing on the screen was the thing the user had
// just written, because nothing was written down. Now it shows what was saved,
// keeps tonight open, reveals one night from the archive, and asks for one line
// of resolve.
//
// The thing this file protects most carefully is the boundary: `Seek Another
// Name` is a CARD RE-ROLL, gated and charged, and it must never be reachable by
// mistake from any of the journaling affordances. Every append and every resolve
// goes through the provider's own no-economy path, which
// `muhasabah_thread_append_test.dart` pins from the other side.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sakina/features/daily/content/muhasabah_completion_copy.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/muhasabah_screen.dart';
import 'package:sakina/features/daily/widgets/add_to_tonight_card.dart';
import 'package:sakina/features/daily/widgets/azm_field.dart';
import 'package:sakina/features/daily/widgets/daily_question_opening_line.dart';
import 'package:sakina/features/daily/widgets/time_machine_card.dart';
import 'package:sakina/features/daily/widgets/tonight_entry_summary.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// A notifier the screen can drive without touching Supabase, gating or the AI
/// seam. The two journaling writes are recorded rather than performed — what is
/// under test here is the wiring, not the persistence (which has its own suite).
class _StubLoop extends DailyLoopNotifier {
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }

  final List<String> appends = [];
  final List<String> azms = [];
  int discoverCalls = 0;
  bool appendSucceeds = true;

  @override
  Future<void> discoverName({
    bool consumeFreeUsage = true,
    bool? isPremiumHint,
  }) async {
    discoverCalls++;
  }

  @override
  Future<bool> appendToTonight(String text) async {
    appends.add(text);
    if (!appendSucceeds) return false;
    final entry = state.tonightEntry!;
    state = state.copyWith(
      tonightEntry: entry.copyWith(
        thread: [
          ...entry.thread,
          ReflectionThreadEntry(at: '', text: text),
        ],
      ),
    );
    return true;
  }

  @override
  Future<bool> setTonightAzm(String azm) async {
    azms.add(azm);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
    debugDailyQuestionGateClock = () => DateTime.utc(2026, 8, 2, 12);
  });

  tearDown(() {
    debugResetUserLocalDay();
    debugDailyQuestionGateClock = null;
    SupabaseSyncService.debugReset();
  });

  SavedReflection entry({
    String id = 'entry-today',
    String day = '2026-08-02',
    String words = 'I snapped at my brother and I have been sitting with it.',
    String azm = '',
    List<ReflectionThreadEntry> thread = const [],
  }) =>
      SavedReflection(
        id: id,
        date: '${day}T21:00:00.000Z',
        userText: words,
        name: 'Al-Halim',
        nameArabic: 'الحليم',
        reframePreview: '',
        duaTranslation: 'O Allah, make me forbearing.',
        source: reflectionSourceMuhasabah,
        entryLocalDay: day,
        thread: thread,
        azm: azm,
      );

  DailyLoopState completed({
    SavedReflection? tonight,
    SavedReflection? anchor,
  }) =>
      DailyLoopState(
        loaded: true,
        checkinDone: true,
        deeperDone: true,
        questDone: true,
        currentStep: DailyLoopStep.completed,
        checkinName: 'Al-Halim',
        checkinNameArabic: 'الحليم',
        tonightEntry: tonight,
        timeMachineEntry: anchor,
      );

  Future<_StubLoop> pump(WidgetTester t, DailyLoopState initial) async {
    final notifier = _StubLoop(initial);
    final router = GoRouter(
      initialLocation: '/muhasabah',
      routes: [
        GoRoute(
            path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
        GoRoute(
            path: '/muhasabah', builder: (_, __) => const MuhasabahScreen()),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      ProviderScope(
        overrides: [dailyLoopProvider.overrideWith((_) => notifier)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    return notifier;
  }

  /// The two fields are found through their owning widget, not by index: the
  /// ʿazm field renders ABOVE "add to tonight" on this screen, so `.first` and
  /// `.last` are exactly the wrong way round and would pass while testing the
  /// other control.
  Finder fieldIn(Type widget) => find.descendant(
        of: find.byType(widget),
        matching: find.byType(TextField),
      );

  /// The completion screen is taller than the 800x600 test viewport, so a tap on
  /// a control below the fold has to scroll to it first — the same thing a
  /// finger does.
  Future<void> tapText(WidgetTester t, String label) async {
    await t.ensureVisible(find.text(label));
    await t.pump();
    await t.tap(find.text(label));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }

  group('what was saved', () {
    testWidgets('the words, the Name and the duʿā are shown back',
        (t) async {
      await pump(t, completed(tonight: entry()));

      expect(find.text(MuhasabahCompletionCopy.header), findsOneWidget);
      expect(find.byType(TonightEntrySummary), findsOneWidget);
      expect(
        find.text('I snapped at my brother and I have been sitting with it.'),
        findsOneWidget,
      );
      expect(find.text('Al-Halim'), findsOneWidget);
      expect(find.text('الحليم'), findsOneWidget);
      expect(find.text('O Allah, make me forbearing.'), findsOneWidget);
    });

    testWidgets(
        'a night with no row claims nothing was saved, and shows no '
        'journaling affordance', (t) async {
      // An offline night, a refused write, or a legacy completion restored from
      // a day blob. Promising a journal entry that does not exist would be the
      // one lie this screen cannot tell.
      await pump(t, completed());

      expect(find.byType(TonightEntrySummary), findsNothing);
      expect(find.byType(AddToTonightCard), findsNothing);
      expect(find.byType(AzmField), findsNothing);
      expect(find.byType(TimeMachineCard), findsNothing);
      expect(find.text(MuhasabahCompletionCopy.subheader), findsNothing);
      // …and the way out still works.
      expect(find.text(MuhasabahCompletionCopy.returnHome), findsOneWidget);
    });
  });

  group('add to tonight', () {
    testWidgets('typing and tapping Add appends, and clears the field',
        (t) async {
      final notifier = await pump(t, completed(tonight: entry()));

      await t.enterText(
          fieldIn(AddToTonightCard), 'One more thing before I sleep.');
      await tapText(t, MuhasabahCompletionCopy.addAction);

      expect(notifier.appends, ['One more thing before I sleep.']);
      expect(notifier.discoverCalls, 0,
          reason: 'an append must never reach the re-roll');
      expect(
        t.widget<TextField>(fieldIn(AddToTonightCard)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('a refused append keeps the words in the field', (t) async {
      final notifier = await pump(t, completed(tonight: entry()));
      notifier.appendSucceeds = false;

      await t.enterText(fieldIn(AddToTonightCard), 'this one does not land');
      await tapText(t, MuhasabahCompletionCopy.addAction);

      expect(
        t.widget<TextField>(fieldIn(AddToTonightCard)).controller!.text,
        'this one does not land',
        reason: 'losing what the user wrote to a failed round-trip is the one '
            'outcome a journaling affordance cannot have',
      );
      expect(find.text(MuhasabahCompletionCopy.addFailed), findsOneWidget);
    });

    testWidgets('appends already made tonight are listed', (t) async {
      await pump(
        t,
        completed(
          tonight: entry(thread: const [
            ReflectionThreadEntry(at: '', text: 'still turning it over'),
            ReflectionThreadEntry(at: '', text: 'I called him'),
          ]),
        ),
      );

      expect(find.text(MuhasabahCompletionCopy.threadLabel), findsOneWidget);
      expect(find.text('still turning it over'), findsOneWidget);
      expect(find.text('I called him'), findsOneWidget);
    });

    testWidgets('a full entry says so instead of offering a field that fails',
        (t) async {
      await pump(
        t,
        completed(
          tonight: entry(thread: [
            for (var i = 0; i < 20; i++)
              ReflectionThreadEntry(at: '', text: 'append $i'),
          ]),
        ),
      );

      expect(find.text(MuhasabahCompletionCopy.addFull), findsOneWidget);
      expect(find.text(MuhasabahCompletionCopy.addAction), findsNothing);
    });
  });

  group('ʿazm', () {
    testWidgets('the field carries what is stored and saves an edit',
        (t) async {
      final notifier =
          await pump(t, completed(tonight: entry(azm: 'Hold my tongue.')));

      expect(find.byType(AzmField), findsOneWidget);
      expect(find.text('Hold my tongue.'), findsOneWidget);

      await t.enterText(fieldIn(AzmField), 'Call him in the morning.');
      await tapText(t, MuhasabahCompletionCopy.azmAction);

      expect(notifier.azms, ['Call him in the morning.']);
      expect(notifier.discoverCalls, 0);
      expect(find.text(MuhasabahCompletionCopy.azmSaved), findsOneWidget);
    });
  });

  group('the time machine', () {
    testWidgets('renders the anchor when one is on state', (t) async {
      await pump(
        t,
        completed(
          tonight: entry(),
          anchor: entry(
            id: 'entry-month-ago',
            day: '2026-07-03',
            words: 'A month ago, I was angry at the same person.',
          ),
        ),
      );

      expect(find.byType(TimeMachineCard), findsOneWidget);
      expect(find.text(MuhasabahCompletionCopy.timeMachineMonth),
          findsOneWidget);
      expect(find.text('A month ago, I was angry at the same person.'),
          findsOneWidget);
    });

    testWidgets('renders nothing at all when there is no anchor', (t) async {
      await pump(t, completed(tonight: entry()));
      expect(find.byType(TimeMachineCard), findsNothing);
    });

    testWidgets('the year-ago lead is used for a year-ago anchor', (t) async {
      await pump(
        t,
        completed(
          tonight: entry(),
          anchor: entry(
            id: 'entry-year-ago',
            day: '2025-08-02',
            words: 'A year ago.',
          ),
        ),
      );
      expect(
          find.text(MuhasabahCompletionCopy.timeMachineYear), findsOneWidget);
    });
  });

  group('the way onward', () {
    testWidgets('exactly one forward action ends the night', (t) async {
      await pump(t, completed(tonight: entry()));

      expect(find.text(MuhasabahCompletionCopy.returnHome), findsOneWidget);
      // The re-roll is still here and still itself — a card pull, not the
      // journaling path. Wave C must not have quietly deleted or renamed it.
      expect(find.text('Seek Another Name'), findsOneWidget);
    });
  });

  group('the ʿazm comes back round', () {
    testWidgets('the next night\'s question opens on the last resolve',
        (t) async {
      await pump(
        t,
        const DailyLoopState(
          loaded: true,
          lastNightAzm: 'Tomorrow I will call my mother.',
        ),
      );

      expect(find.byType(DailyQuestionOpeningLine), findsOneWidget);
      expect(find.text(MuhasabahCompletionCopy.azmResurfaceLead),
          findsOneWidget);
      expect(find.text('Tomorrow I will call my mother.'), findsOneWidget);
    });

    testWidgets('no resolve means no opener', (t) async {
      await pump(t, const DailyLoopState(loaded: true));
      expect(find.byType(DailyQuestionOpeningLine), findsNothing);
    });

    testWidgets('a re-ask does not repeat the opener — a rephrase is mid-night',
        (t) async {
      await pump(
        t,
        const DailyLoopState(
          loaded: true,
          checkinDone: true,
          awaitingReAnswer: true,
          lastNightAzm: 'Tomorrow I will call my mother.',
        ),
      );

      expect(find.byType(DailyQuestionOpeningLine), findsNothing);
    });
  });
}
