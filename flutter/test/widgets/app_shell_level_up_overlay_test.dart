// Regression guard: AppShell subscribes to EconomyEvents.stream and pushes
// LevelUpOverlay on every XpGranted{leveledUp: true} event.
//
// LevelUpOverlay uses flutter_animate with `onPlay: (c) => c.repeat(...)` —
// continuous looping animations that cannot be drained by pumpAndSettle. We
// therefore assert by detecting the Navigator push rather than by rendering
// the full overlay. Two strategies are combined:
//
//   1. Widget test — detect that a route is pushed using a NavigatorObserver.
//   2. Source-level test — pin that app_shell.dart subscribes to
//      EconomyEvents.stream and pushes LevelUpOverlay.
//
// This is the same pattern as name_reveal_overlay_phase_gate_test.dart and
// the collection_screen_test.dart §10 C4 note.
//
// IRON RULE: "streak milestone first, level-up second" — push ORDER means
// StreakMilestoneOverlay pushes first (below), LevelUpOverlay pushes second
// (on top / current). User sees level-up first, dismisses, then sees streak.
// Pinned by the race-ordering test in this file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/widgets/streak_milestone_overlay.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/economy_events.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/widgets/app_shell.dart';
import 'package:sakina/features/daily/widgets/level_up_overlay.dart';

import '../support/fake_supabase_sync_service.dart';

/// Minimal QuestsNotifier stub that never touches SharedPreferences or
/// Supabase — just boots with an empty QuestsState so AppShell's
/// [ref.listen] for [QuestsState] can subscribe without side effects.
class _StubQuestsNotifier extends StateNotifier<QuestsState>
    implements QuestsNotifier {
  _StubQuestsNotifier() : super(const QuestsState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Captures push order so we can assert which overlay lands on top.
class _CapturingObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;
  final List<Route<dynamic>> pushOrder = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
    pushOrder.add(route);
  }
}

/// A lightweight stub child widget that mirrors MuhasabahScreen's
/// streak-milestone ref.listen logic without touching Supabase, AI, etc.
/// Used by the race-ordering test to trigger a streak push in the same
/// post-frame batch as AppShell's level-up push.
class _StreakListenerStub extends ConsumerStatefulWidget {
  const _StreakListenerStub({required this.onBuilt});
  final void Function(DailyLoopNotifier notifier) onBuilt;

  @override
  ConsumerState<_StreakListenerStub> createState() =>
      _StreakListenerStubState();
}

class _StreakListenerStubState extends ConsumerState<_StreakListenerStub> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    // Notify the test of the notifier handle on first build.
    if (!_notified) {
      _notified = true;
      // Schedule outside of build to avoid "reading during build" assertion.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onBuilt(ref.read(dailyLoopProvider.notifier));
      });
    }

    // Mirror MuhasabahScreen's streak-milestone listener.
    ref.listen<DailyLoopState>(dailyLoopProvider, (prev, next) {
      if (next.streakMilestoneReached &&
          prev?.streakMilestoneReached != true) {
        _pushStreakMilestoneOverlay(next);
      }
    });

    return const SizedBox();
  }

  void _pushStreakMilestoneOverlay(DailyLoopState state) {
    if (!mounted) return;
    final notifier = ref.read(dailyLoopProvider.notifier);
    final nav = Navigator.of(context, rootNavigator: true);
    nav.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => StreakMilestoneOverlay(
          streakCount: state.streakMilestoneCount ?? 0,
          xpAwarded: state.streakMilestoneXp ?? 0,
          scrollsAwarded: state.streakMilestoneScrolls ?? 0,
          onContinue: () {
            nav.pop();
            notifier.clearStreakMilestone();
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

void main() {
  group('app_shell.dart source invariants', () {
    late String source;
    setUpAll(() {
      source =
          File('lib/widgets/app_shell.dart').readAsStringSync();
    });

    test('subscribes to EconomyEvents.stream in initState', () {
      expect(
        source.contains('EconomyEvents.stream'),
        isTrue,
        reason: 'AppShell must subscribe to EconomyEvents.stream to catch '
            'XpGranted events from any source (quests, streaks, etc.).',
      );
      expect(
        source.contains('initState'),
        isTrue,
        reason: 'AppShell must be a ConsumerStatefulWidget with initState '
            'to set up the StreamSubscription lifecycle.',
      );
    });

    test('cancels subscription in dispose', () {
      expect(
        source.contains('_econSub?.cancel()'),
        isTrue,
        reason: 'StreamSubscription must be cancelled in dispose() to '
            'prevent memory leaks.',
      );
    });

    test('pushes LevelUpOverlay when leveledUp is true', () {
      expect(
        source.contains('LevelUpOverlay'),
        isTrue,
        reason: 'AppShell must push LevelUpOverlay when it receives an '
            'XpGranted{leveledUp: true} event.',
      );
      expect(
        source.contains('event.leveledUp'),
        isTrue,
        reason: 'AppShell must gate on event.leveledUp.',
      );
      expect(
        source.contains('event.rewards != null'),
        isTrue,
        reason: 'AppShell must guard on rewards being non-null before pushing '
            'the overlay (rewards are required to render reward details).',
      );
    });
  });

  group('AppShell widget: LevelUpOverlay push via EconomyEvents', () {
    late FakeSupabaseSyncService fakeSync;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeSync = FakeSupabaseSyncService(userId: null);
      SupabaseSyncService.debugSetInstance(fakeSync);
    });

    tearDown(SupabaseSyncService.debugReset);

    testWidgets(
        'pushes a route whose page widget is LevelUpOverlay on '
        'XpGranted{leveledUp: true}', (tester) async {
      final observer = _CapturingObserver();

      final router = GoRouter(
        initialLocation: '/',
        observers: [observer],
        routes: [
          ShellRoute(
            builder: (_, __, child) => AppShell(child: child),
            routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          questsProvider.overrideWith((_) => _StubQuestsNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      await tester.pump();

      EconomyEvents.publish(const XpGranted(
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
      ));

      // The stream listener fires synchronously when publish() is called,
      // registering addPostFrameCallback + scheduleFrame().
      // scheduleFrame() ensures the next pump processes the frame.
      // addPostFrameCallback fires at the end of that frame → Navigator.push.
      // Then additional pumps build and render the overlay widget.
      await tester.pump(); // frame scheduled → post-frame fires → push called
      await tester.pump(); // route entry built
      await tester.pump(); // overlay widget rendered
      await tester.pump(); // settle any initial overlay animations

      expect(find.byType(LevelUpOverlay), findsOneWidget,
          reason: 'LevelUpOverlay must be in the widget tree after an '
              'XpGranted{leveledUp: true} event.');

      // Drain the LevelUpOverlay timer sequence (800ms + 500ms) so the test
      // can tear down cleanly. We avoid pumpAndSettle because flutter_animate
      // onPlay:repeat creates looping timers that never settle.
      await tester.pump(const Duration(milliseconds: 800)); // phase 0→1
      await tester.pump(const Duration(milliseconds: 500)); // phase 1→2
      await tester.pump(const Duration(milliseconds: 500)); // finite slice
    });

    testWidgets(
        'does NOT push LevelUpOverlay on XpGranted{leveledUp: false}',
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

      await tester.pumpWidget(ProviderScope(
        overrides: [
          questsProvider.overrideWith((_) => _StubQuestsNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      await tester.pump();

      EconomyEvents.publish(const XpGranted(
        amount: 10,
        newTotal: 10,
        newState: XpState(
          totalXp: 10,
          level: 1,
          title: 'Seeker',
          titleArabic: 'طَالِب',
          xpForNextLevel: 75,
          xpIntoCurrentLevel: 10,
        ),
        leveledUp: false,
        source: EconomyEventSource.quest,
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(LevelUpOverlay), findsNothing,
          reason: 'XpGranted{leveledUp: false} must NOT push LevelUpOverlay.');
    });

    testWidgets(
        'streak milestone overlay pushes BEFORE level-up overlay on same tick',
        (tester) async {
      // IRON RULE: "streak milestone first, level-up second" in push order.
      // StreakMilestoneOverlay pushes first (sits below), LevelUpOverlay
      // pushes second (sits on top / isCurrent). User sees level-up first,
      // dismisses, then sees streak.
      //
      // Mechanism: MuhasabahScreen's ref.listen fires
      // _pushStreakMilestoneOverlay via a direct call during the build/notify
      // phase. AppShell's stream listener uses addPostFrameCallback, which
      // fires AFTER the build phase. So streak pushes first (build phase),
      // level-up pushes second (post-frame) → level-up on top. CORRECT.
      //
      // If AppShell uses Future.microtask instead of addPostFrameCallback,
      // the level-up push fires BEFORE the build phase (microtasks run before
      // post-frame), pushing level-up first → streak ends up on top. WRONG.
      // This test catches that regression.

      final observer = _CapturingObserver();

      // We need a stub DailyLoopNotifier so debugSetStreakMilestone is
      // available without touching Supabase.
      late DailyLoopNotifier dailyLoopNotifier;

      final router = GoRouter(
        initialLocation: '/',
        observers: [observer],
        routes: [
          ShellRoute(
            builder: (_, __, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                // Use a plain widget — MuhasabahScreen is too heavy (calls
                // discoverName, Supabase, etc). Instead, inline the same
                // ref.listen streak-overlay logic that MuhasabahScreen uses.
                builder: (_, __) => _StreakListenerStub(
                  onBuilt: (notifier) {
                    dailyLoopNotifier = notifier;
                  },
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          questsProvider.overrideWith((_) => _StubQuestsNotifier()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump(); // settle initial frame
      await tester.pump(); // second settle for GoRouter

      // Same-tick: set streak milestone state (triggers ref.listen in
      // _StreakListenerStub) AND publish XpGranted level-up.
      // Both will schedule their Navigator.push in the next post-frame batch.
      dailyLoopNotifier.debugSetStreakMilestone(
          streak: 7, xp: 50, scrolls: 1);
      EconomyEvents.publish(const XpGranted(
        amount: 100,
        newTotal: 100,
        newState: XpState(
          totalXp: 100,
          level: 2,
          title: 'Listener',
          titleArabic: 'مُسْتَمِع',
          xpForNextLevel: 150,
          xpIntoCurrentLevel: 0,
        ),
        leveledUp: true,
        rewards: LevelUpRewards(
          levelsGained: 1,
          tokensAwarded: 10,
          scrollsAwarded: 1,
          titleUnlocked: false,
        ),
        source: EconomyEventSource.quest,
      ));

      // Deliver stream event + process Riverpod state change.
      await tester.pump();
      // Run all post-frame callbacks — this is where both overlays push.
      await tester.pump();
      await tester.pump();

      // Both overlays should now be in the tree.
      expect(find.byType(StreakMilestoneOverlay), findsOneWidget,
          reason: 'StreakMilestoneOverlay must be pushed.');
      expect(find.byType(LevelUpOverlay), findsOneWidget,
          reason: 'LevelUpOverlay must be pushed.');

      // IRON RULE: "streak milestone first, level-up second" means push ORDER:
      // StreakMilestoneOverlay pushes first (sits below), LevelUpOverlay pushes
      // second (sits on top / isCurrent). The user dismisses level-up first,
      // then sees the streak milestone — intentional celebration ordering.
      //
      // With addPostFrameCallback: streak fires via ref.listen (build phase,
      // first), level-up fires via post-frame callback (second) → level-up
      // on top. CORRECT.
      //
      // With Future.microtask (the old bug): level-up fires first (microtasks
      // beat post-frame), streak fires second → streak on top. WRONG.
      // This test catches that regression.
      final levelUpElement = tester.element(find.byType(LevelUpOverlay));
      final levelUpRoute = ModalRoute.of(levelUpElement);
      expect(
        levelUpRoute?.isCurrent,
        isTrue,
        reason: 'LevelUpOverlay must be the current (top) route (pushed '
            'second). If StreakMilestoneOverlay is on top instead, '
            'AppShell is scheduling its push via Future.microtask (which '
            'runs before post-frame callbacks, pushing level-up first and '
            'leaving streak on top). Fix: use addPostFrameCallback so '
            'level-up pushes after streak.',
      );

      // Drain pending timers for clean teardown.
      // StreakMilestoneOverlay: 1200ms + 400ms + 1200ms phases.
      // LevelUpOverlay: 800ms + 500ms phases.
      // Use finite pumps (not pumpAndSettle) since flutter_animate repeat
      // animations never settle. Pump zero-duration first to flush any queued
      // 0ms timers (e.g. from scheduleFrame calls).
      await tester.pump(Duration.zero);                      // flush 0ms timers
      await tester.pump(const Duration(milliseconds: 1200)); // streak phase 0→1
      await tester.pump(const Duration(milliseconds: 400));  // streak phase 1→2
      await tester.pump(const Duration(milliseconds: 1200)); // streak phase 2→3
      await tester.pump(const Duration(milliseconds: 800));  // level-up phase 0→1
      await tester.pump(const Duration(milliseconds: 500));  // level-up phase 1→2
      await tester.pump(const Duration(milliseconds: 500));  // extra settle
    });
  });
}
