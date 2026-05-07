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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Captures the most-recently-pushed route so we can assert what AppShell
/// pushed without rendering the full widget tree of the route.
class _CapturingObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
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

      // pump1 — stream microtask delivers event, Future.microtask scheduled
      // pump2 — Future.microtask fires, Navigator.push called
      // pump3 — route entry built and partially rendered (overlay is in tree)
      await tester.pump(); // 1
      await tester.pump(); // 2
      await tester.pump(); // 3

      expect(find.byType(LevelUpOverlay), findsOneWidget,
          reason: 'LevelUpOverlay must be in the widget tree after an '
              'XpGranted{leveledUp: true} event.');

      // Drain the LevelUpOverlay timer sequence (800ms + 500ms) so the test
      // can tear down cleanly. We avoid pumpAndSettle because flutter_animate
      // onPlay:repeat creates looping timers that never settle.
      await tester.pump(const Duration(milliseconds: 800)); // phase 0→1
      await tester.pump(const Duration(milliseconds: 500)); // phase 1→2
      // Phase 2 uses repeat animations — pump a finite slice, not settle.
      await tester.pump(const Duration(milliseconds: 500));
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
  });
}
