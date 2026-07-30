import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

/// How the day-open hands off (W4 Wave 4 — spec M1, plan §6).
///
/// Two things that only show up on a device, pinned here instead:
///   1. the overlay must POP before it routes, or it stays mounted under
///      `/muhasabah` and a back gesture lands the user back in the day-open;
///   2. it must never be a dead end.
class _Loop extends DailyLoopNotifier {
  _Loop() : super(skipInitForTests: true) {
    state = state.copyWith(loaded: true, streakCount: 4);
  }
}

/// Enough of a session for the overlay's post-frame economy hydration to run
/// without reaching Supabase.
AppSessionNotifier _fakeSession() => AppSessionNotifier(
      initialOnboarded: true,
      authStateChanges: const Stream.empty(),
      isAuthenticatedProvider: () => true,
      currentUserIdProvider: () => 'u1',
      hydrateEconomyCache: () async {},
      hasCompletedOnboarding: () async => true,
      isPremiumReader: () async => false,
      hardPaywallFlowReader: () async => false,
      trialExpiredReader: () async => false,
      paywallArmReader: () async => null,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(FakeSupabaseSyncService(userId: 'u1'));
  });

  tearDown(SupabaseSyncService.debugReset);

  /// Stands the overlay up exactly as `progress_screen` does — pushed opaque on
  /// the ROOT navigator, over a live shell — because the bug under test is a
  /// property of that arrangement and nothing else.
  Future<GoRouter> pumpOverlay(WidgetTester t) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/muhasabah',
          builder: (_, __) => const Scaffold(body: Text('the question')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await t.pumpWidget(
      ProviderScope(
        overrides: [
          dailyLoopProvider.overrideWith((_) => _Loop()),
          appSessionProvider.overrideWithValue(_fakeSession()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pump();

    final nav = router.routerDelegate.navigatorKey.currentState!;
    unawaited(nav.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: 'DailyLaunchOverlay'),
        opaque: true,
        pageBuilder: (_, __, ___) => const DailyLaunchOverlay(),
      ),
    ));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    return router;
  }

  testWidgets('the frame shows streak state and no Name at all', (t) async {
    await pumpOverlay(t);

    // `findRichText` because the count and the label are separate spans in one
    // RichText — the streak is the ambient state M1 asks for, so it stays.
    expect(find.text('4\nday streak', findRichText: true), findsOneWidget);
    // The Name card is gone (founder, 2026-07-30). Keeping it would have meant
    // "Today's Name: X" → answer → a DIFFERENT Name from the queue, seconds
    // apart in one unbroken flow — the app contradicting itself inside a single
    // interaction. The Name is what the user is about to earn, not something we
    // show on the way in.
    expect(find.text("Today's Name"), findsNothing);
    expect(find.text('Your Starting Name'), findsNothing);
  });

  testWidgets('Begin pops the day-open BEFORE routing, so back does not '
      'land in it again', (t) async {
    final router = await pumpOverlay(t);
    expect(find.byType(DailyLaunchOverlay), findsOneWidget);

    await t.tap(find.text('Begin today'));
    await t.pumpAndSettle();

    expect(find.text('the question'), findsOneWidget);
    expect(find.byType(DailyLaunchOverlay), findsNothing,
        reason: 'an opaque root-navigator route left mounted under '
            '/muhasabah is exactly how a back gesture drops the user back '
            'into the day-open they just left');
    expect(router.routerDelegate.currentConfiguration.uri.path, '/muhasabah');
  });

  testWidgets('the escape hatch returns home without routing anywhere',
      (t) async {
    final router = await pumpOverlay(t);

    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(DailyLaunchOverlay), findsNothing);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/',
        reason: 'someone who opened the app for their duʿā times must get '
            'past the day-open without being taken into the question');
  });
}
