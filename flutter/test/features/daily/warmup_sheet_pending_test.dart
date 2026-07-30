// The warmup-exhaustion sheet must survive the user leaving (W4 Wave 1 review,
// F1).
//
// `dailyLoopProvider` is a plain `StateNotifierProvider`, NOT autoDispose, so
// the notifier outlives this route. `markUsed` sits at the tail of
// `discoverName` behind a Supabase round-trip, so a user who taps Return to
// Home right after their card reveal leaves while the charge is still in
// flight: the flag gets set with nobody watching, and `ref.listen` only fires
// on transitions that happen after it subscribes. Coming back never fired it —
// `prev` was already non-null — and `dismissWarmupExhausted` is only called
// from the sheet, so the flag stuck and the exhaustion was announced never.
//
// Nothing about the charge or the cap was wrong. What was lost is the one
// moment where the free tier explains itself, in the wave whose defining
// decision was refusing to quietly reduce that tier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/screens/muhasabah_screen.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

class _StubLoop extends DailyLoopNotifier {
  _StubLoop(DailyLoopState initial) : super(skipInitForTests: true) {
    state = initial;
  }

  @override
  Future<void> discoverName({
    bool consumeFreeUsage = true,
    bool? isPremiumHint,
  }) async {}

  void emit(DailyLoopState next) => state = next;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-1'),
    );
    debugResetUserLocalDay();
    debugUserTimeZoneOverride = 'UTC';
  });

  tearDown(() {
    debugResetUserLocalDay();
    SupabaseSyncService.debugReset();
  });

  DailyLoopState loaded({GatedFeature? warmupJustExhausted}) => DailyLoopState(
        loaded: true,
        currentStep: DailyLoopStep.checkin,
        checkinDone: true,
        warmupJustExhausted: warmupJustExhausted,
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
    // Advanced rather than settled: the loading views breathe forever, so
    // `pumpAndSettle` would time out. Two pumps drain the post-frame callback
    // and the sheet's entrance.
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    return notifier;
  }

  testWidgets('a flag ALREADY set at mount still shows the sheet', (t) async {
    // THE REGRESSION. Before this fix the mount produced no transition, so
    // `ref.listen` never fired and the user was never told — they met the cap
    // sheet cold on their next re-roll instead.
    await pump(t, loaded(warmupJustExhausted: GatedFeature.discoverName));

    expect(find.byType(WarmupExhaustedSheet), findsOneWidget,
        reason: 'the flag was set while the user was off this route — coming '
            'back has to announce it, because nothing else ever will');
  });

  testWidgets('the rising edge still fires it (no regression)', (t) async {
    final notifier = await pump(t, loaded());
    expect(find.byType(WarmupExhaustedSheet), findsNothing);

    notifier.emit(loaded(warmupJustExhausted: GatedFeature.discoverName));
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.byType(WarmupExhaustedSheet), findsOneWidget);
  });

  testWidgets('the two entry points cannot show it twice', (t) async {
    // The mount read and the listener are mutually exclusive in principle, but
    // showing this sheet twice is exactly what the single-listener rule on this
    // screen exists to prevent — so the guard is pinned rather than reasoned
    // about.
    final notifier =
        await pump(t, loaded(warmupJustExhausted: GatedFeature.discoverName));
    expect(find.byType(WarmupExhaustedSheet), findsOneWidget);

    // A further state change carrying the same still-pending flag.
    notifier.emit(
      loaded(warmupJustExhausted: GatedFeature.discoverName)
          .copyWith(streakCount: 3),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.byType(WarmupExhaustedSheet), findsOneWidget,
        reason: 'one exhaustion, one sheet');
  });

  testWidgets('a cleared flag shows nothing — no re-show loop', (t) async {
    // `dismissWarmupExhausted` clears the flag, and that is what stops the new
    // mount-time read from re-showing the sheet on every subsequent visit to
    // this route. Without it the fix would trade a lost sheet for a nagging
    // one.
    await pump(t, loaded());

    expect(find.byType(WarmupExhaustedSheet), findsNothing);
  });

  test('dismissing clears the flag the mount read consults', () async {
    final notifier = _StubLoop(
      loaded(warmupJustExhausted: GatedFeature.discoverName),
    );
    addTearDown(notifier.dispose);

    expect(notifier.state.warmupJustExhausted, isNotNull);
    notifier.dismissWarmupExhausted();
    expect(notifier.state.warmupJustExhausted, isNull,
        reason: 'the provider flag is the latch — a mount after this must find '
            'nothing pending');
  });
}
