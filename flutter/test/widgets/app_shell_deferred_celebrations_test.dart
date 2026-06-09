// Verifies the deferred-celebration feature in AppShell:
//   1. While the guided tour is active, a level-up is WITHHELD (not shown) and
//      enqueued instead — it must not interrupt the coachmark flow.
//   2. Once the tour resolves and the user lands back on a tab screen (modeled
//      here by AppShell unmounting for a paywall route then remounting at home),
//      the queue drains and the celebration replays.
//
// LevelUpOverlay uses flutter_animate repeat() loops that never settle, so we
// assert via presence after finite pumps (same approach as
// app_shell_level_up_overlay_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/tour/providers/deferred_celebrations_provider.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/features/tour/providers/tour_route_observer.dart';
import 'package:sakina/features/daily/widgets/level_up_overlay.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/widgets/app_shell.dart';

import '../support/fake_supabase_sync_service.dart';

class _StubQuestsNotifier extends StateNotifier<QuestsState>
    implements QuestsNotifier {
  _StubQuestsNotifier() : super(const QuestsState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Controllable tour controller: starts active, [resolve] flips it to completed.
class _TourStub extends OnboardingTourController {
  _TourStub(super.ref, {required bool active}) {
    state = OnboardingTourState(
      index: active ? 0 : -1,
      status: active ? TourStatus.active : TourStatus.completed,
    );
  }
  void resolve() =>
      state = state.copyWith(index: -1, status: TourStatus.completed);
}

const _xpEvent = XpGranted(
  amount: 80,
  newTotal: 80,
  newState: XpState(
    totalXp: 80,
    level: 2,
    title: 'Listener',
    titleArabic: 'مُسْتَمِع',
    xpForNextLevel: 100,
    xpIntoCurrentLevel: 5,
  ),
  leveledUp: true,
  rewards: LevelUpRewards(
    levelsGained: 1,
    tokensAwarded: 5,
    scrollsAwarded: 0,
    titleUnlocked: false,
  ),
  source: EconomyEventSource.quest,
);

void main() {
  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: null);
    SupabaseSyncService.debugSetInstance(fakeSync);
    // The route observer is a global singleton; ensure no stale blocking route
    // leaks in from another test and suppresses the drain.
    tourRouteObserver.topRouteName.value = null;
  });

  tearDown(() async {
    SupabaseSyncService.debugReset();
    await EconomyEvents.resetForTest();
  });

  testWidgets(
      'level-up is withheld (not shown) and queued while the tour is active',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
        ),
      ],
    );

    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        questsProvider.overrideWith((_) => _StubQuestsNotifier()),
        onboardingTourControllerProvider
            .overrideWith((ref) => _TourStub(ref, active: true)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    container = ProviderScope.containerOf(tester.element(find.byType(AppShell)));

    EconomyEvents.publish(_xpEvent);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(LevelUpOverlay), findsNothing,
        reason: 'while the tour is active the rank-up must be withheld');
    final queue = container.read(deferredCelebrationsProvider);
    expect(queue.length, 1);
    expect(queue.single, isA<LevelUpCelebration>());
  });

  testWidgets(
      'deferred celebrations replay once the tour resolves and AppShell '
      'rebuilds on a tab screen', (tester) async {
    // The drain fires from AppShell.build (post-frame). In production the first
    // post-tour build is AppShell remounting at home after the paywall; here we
    // exercise the same build-time drain via an in-shell tab navigation, which
    // avoids GoRouter's transient page-key churn on top-level remounts.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, __, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const SizedBox()),
            GoRoute(
                path: '/collection', builder: (_, __) => const SizedBox()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        questsProvider.overrideWith((_) => _StubQuestsNotifier()),
        onboardingTourControllerProvider
            .overrideWith((ref) => _TourStub(ref, active: true)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppShell)));

    // Tour active → level-up is queued, not shown.
    EconomyEvents.publish(_xpEvent);
    await tester.pump();
    await tester.pump();
    expect(find.byType(LevelUpOverlay), findsNothing);
    expect(container.read(deferredCelebrationsProvider).length, 1);

    // Tour resolves; the next AppShell build (a tab navigation) drains.
    (container.read(onboardingTourControllerProvider.notifier) as _TourStub)
        .resolve();
    router.go('/collection');
    await tester.pump(); // rebuild + post-frame drain → push
    await tester.pump(); // route entry built
    await tester.pump(); // overlay rendered

    expect(find.byType(LevelUpOverlay), findsOneWidget,
        reason: 'the withheld rank-up must replay on the first post-tour build');
    expect(container.read(deferredCelebrationsProvider), isEmpty,
        reason: 'queue is drained exactly once');

    // Drain LevelUpOverlay animation timers for clean teardown.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
