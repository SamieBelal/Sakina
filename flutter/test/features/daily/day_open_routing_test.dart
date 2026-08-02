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
  /// Stands the overlay up exactly as `progress_screen` does — pushed opaque on
  /// the ROOT navigator, over a live shell — because the bug under test is a
  /// property of that arrangement and nothing else.
  ///
  /// The route shape mirrors production deliberately: `/` and `/duas` live
  /// INSIDE a `ShellRoute`, `/muhasabah` is root-level. That distinction is the
  /// whole subject of the departure tests below — go_router drops an
  /// imperatively-pushed root route when you `.go()` to another ROOT route, but
  /// not when you `.go()` to a route inside the shell. Flatten these into
  /// top-level routes and the departure test passes while exercising a shape
  /// the app does not have.
  Future<GoRouter> pumpOverlay(WidgetTester t) async {
    final rootKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (_, __, child) => Scaffold(body: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const Text('home')),
            // Stands in for the duʿā-times destination — the one a duʿā widget
            // tap actually reaches, and the reason it has to be in the shell.
            GoRoute(
              path: '/duas',
              builder: (_, __) => const Text('the dua times'),
            ),
          ],
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

    unawaited(rootKey.currentState!.push(
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

  testWidgets('Begin leaves Home under the question for back navigation',
      (t) async {
    final router = await pumpOverlay(t);
    expect(find.byType(DailyLaunchOverlay), findsOneWidget);

    await t.tap(find.text('Begin today'));
    await t.pumpAndSettle();

    expect(find.text('the question'), findsOneWidget);
    expect(find.byType(DailyLaunchOverlay), findsNothing,
        reason: 'an opaque root-navigator route left mounted under '
            '/muhasabah is exactly how a back gesture drops the user back '
            'into the day-open they just left');
    expect(router.canPop(), isTrue,
        reason: 'the standard iOS back gesture needs Home below the question');

    router.pop();
    await t.pumpAndSettle();
    expect(find.text('home'), findsOneWidget,
        reason: 'back from the day-open question must return Home');
  });

  testWidgets('it gets out of the way when the app navigates elsewhere',
      (t) async {
    // F2 from the Wave 4 review. The push site checks the location immediately
    // before presenting, which catches a widget deep link that has ALREADY
    // landed — but not one that lands a moment later. `/duas` lives inside the
    // ShellRoute, so `.go('/duas')` swaps the shell's child UNDERNEATH this
    // opaque root-navigator route and leaves the day-open sitting on top of it.
    //
    // Someone who tapped a duʿā widget would then be looking at a full-screen
    // prompt about their heart with one obvious button, and that button routes
    // into the muḥāsabah. "They tapped it" is not consent to that.
    final router = await pumpOverlay(t);
    expect(find.byType(DailyLaunchOverlay), findsOneWidget);

    router.go('/duas');
    await t.pumpAndSettle();

    expect(find.byType(DailyLaunchOverlay), findsNothing,
        reason: 'the day-open has missed its moment — it must yield to where '
            'the user actually asked to go, and wait for the home CTA');
    expect(find.text('the dua times'), findsOneWidget);
  });

  testWidgets('a departure to a ROOT route does not double-pop', (t) async {
    // The hazard the fix had to survive, and it is invisible without testing
    // both route shapes. go_router removes an imperatively-pushed root route
    // by itself when you `.go()` to another ROOT route — so on `/muhasabah`
    // the overlay is already gone before our listener would act. A listener
    // that popped unconditionally would then pop the question route too and
    // leave the user staring at an empty navigator.
    //
    // The post-frame deferral is what makes this safe: by the time it runs the
    // rebuild has landed, this widget is unmounted, and the `mounted` check
    // declines. That is the real reason it is deferred — mutating the
    // navigator mid-build is only the secondary one.
    final router = await pumpOverlay(t);
    expect(find.byType(DailyLaunchOverlay), findsOneWidget);

    router.go('/muhasabah');
    await t.pumpAndSettle();

    expect(find.byType(DailyLaunchOverlay), findsNothing);
    expect(find.text('the question'), findsOneWidget,
        reason: 'the destination must survive — popping it is a worse bug '
            'than the one the listener exists to fix');
    expect(router.routerDelegate.currentConfiguration.uri.path, '/muhasabah');
  });

  testWidgets('staying on home does NOT dismiss it', (t) async {
    // The other half: the listener must fire on a real departure and on
    // nothing else, or the day-open becomes impossible to show.
    final router = await pumpOverlay(t);

    router.go('/');
    await t.pumpAndSettle();

    expect(find.byType(DailyLaunchOverlay), findsOneWidget,
        reason: 'a navigation back to the same place is not a departure');
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
