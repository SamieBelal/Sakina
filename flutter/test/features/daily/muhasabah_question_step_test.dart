import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/muhasabah_screen.dart';
import 'package:sakina/features/daily/widgets/daily_question_defer_link.dart';
import 'package:sakina/features/daily/widgets/daily_question_prompt.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/daily_question_gate.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// The question surface's wiring into `MuhasabahScreen` (W4 Wave 2 — plan §4,
/// spec M2 "Skip = defer, not dismiss").
///
/// The screen is stood up against a notifier with `skipInitForTests`, so these
/// tests exercise the branch selection and the defer contract without dragging
/// in Supabase, gating or the AI seam — which the queue/deck suites already
/// cover from the other side.
class _StubLoop extends DailyLoopNotifier {
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }

  int discoverCalls = 0;

  @override
  Future<void> discoverName({
    bool consumeFreeUsage = true,
    bool? isPremiumHint,
  }) async {
    discoverCalls++;
  }

  /// Pushes a state change the way the real provider would, so the screen's
  /// `ref.listen` sees a rising edge.
  void emit(DailyLoopState next) => state = next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    debugResetUserLocalDay();
    // Short-circuits the zone ladder so the marker's day is deterministic and
    // no test reaches for the device timezone plugin.
    debugUserTimeZoneOverride = 'UTC';
    debugDailyQuestionGateClock = () => DateTime.utc(2026, 8, 4, 12);
  });

  tearDown(() {
    debugResetUserLocalDay();
    debugDailyQuestionGateClock = null;
    SupabaseSyncService.debugReset();
  });

  /// A loaded day sitting on the step under test.
  DailyLoopState stateOn(
    DailyLoopStep step, {
    bool checkinDone = false,
  }) =>
      DailyLoopState(
        loaded: true,
        currentStep: step,
        checkinDone: checkinDone,
      );

  Future<_StubLoop> pump(WidgetTester t, DailyLoopState initial) async {
    final notifier = _StubLoop(initial);
    final router = GoRouter(
      initialLocation: '/muhasabah',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/muhasabah',
          builder: (_, __) => const MuhasabahScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      ProviderScope(
        overrides: [dailyLoopProvider.overrideWith((_) => notifier)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Advanced rather than settled: the entrance animations are one-shot
    // delays that must be drained (or the test ends on pending timers), while
    // the loading views on the other branches breathe forever and would make
    // `pumpAndSettle` time out.
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    return notifier;
  }

  testWidgets('the checkin step asks the question', (t) async {
    final notifier = await pump(t, stateOn(DailyLoopStep.checkin));

    expect(find.byType(DailyQuestionPrompt), findsOneWidget);
    // The removed one-shot is the point: mounting the route no longer starts a
    // reveal. Nothing is consumed until the user answers.
    expect(notifier.discoverCalls, 0);
  });

  testWidgets('the deeper step does not', (t) async {
    await pump(t, stateOn(DailyLoopStep.deeper, checkinDone: true));

    expect(find.byType(DailyQuestionPrompt), findsNothing);
  });

  testWidgets('a completed day does not', (t) async {
    await pump(t, stateOn(DailyLoopStep.completed, checkinDone: true));

    expect(find.byType(DailyQuestionPrompt), findsNothing);
  });

  testWidgets('an unloaded state does not — the question must not flash '
      'before today has been restored', (t) async {
    await pump(t, const DailyLoopState());

    expect(find.byType(DailyQuestionPrompt), findsNothing);
  });

  testWidgets('"Not right now" goes home having changed nothing but the '
      'day marker', (t) async {
    final notifier = await pump(t, stateOn(DailyLoopStep.checkin));
    final before = notifier.state;

    expect(await dailyQuestionDeferredToday(), isFalse);

    await t.tap(find.byType(DailyQuestionDeferLink));
    await t.pump();
    await t.pump(const Duration(seconds: 2));

    expect(find.text('home'), findsOneWidget);
    // No reveal, no reward, nothing consumed — the whole loop stays
    // collectible from the home CTA for the rest of the day (spec M2).
    expect(notifier.discoverCalls, 0);
    expect(identical(notifier.state, before), isTrue,
        reason: 'a defer writes no daily-loop state at all');
    // The one thing it does write: auto-entry happens at most once per local
    // day, so the next open does not re-throw the question at someone who
    // already said "not right now".
    expect(await dailyQuestionDeferredToday(), isTrue);
  });

  testWidgets('the day marker expires with the local day', (t) async {
    await pump(t, stateOn(DailyLoopStep.checkin));
    await t.tap(find.byType(DailyQuestionDeferLink));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(await dailyQuestionDeferredToday(), isTrue);

    debugDailyQuestionGateClock = () => DateTime.utc(2026, 8, 5, 12);
    expect(await dailyQuestionDeferredToday(), isFalse,
        reason: 'tomorrow the question is asked again — the defer was for '
            'today, not forever');
  });

  testWidgets('the warmup-exhausted sheet still fires on the rising edge',
      (t) async {
    // W4 Wave 1 moved `markUsed` into `discoverName()`, so the exhaustion
    // signal now comes back through `DailyLoopState.warmupJustExhausted` and
    // ONLY this screen's `ref.listen` fires the sheet — progress_screen is
    // already behind the pushed route by then. Wave 2 rewrote this screen's
    // initState and its canvas branching; nothing else here would notice if
    // that listener were dropped or reordered in the process.
    final notifier = await pump(t, stateOn(DailyLoopStep.checkin));
    expect(find.byType(WarmupExhaustedSheet), findsNothing);

    notifier.emit(
      stateOn(DailyLoopStep.checkin)
          .copyWith(warmupJustExhausted: GatedFeature.discoverName),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.byType(WarmupExhaustedSheet), findsOneWidget,
        reason: 'the free user has to be told their warmup is spent');
  });

  testWidgets('the marker is scoped to the account', (t) async {
    await pump(t, stateOn(DailyLoopStep.checkin));
    await t.tap(find.byType(DailyQuestionDeferLink));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(await dailyQuestionDeferredToday(), isTrue);

    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-2'),
    );
    expect(await dailyQuestionDeferredToday(), isFalse,
        reason: "one device's second account must not inherit the first's "
            'defer');
  });
}
