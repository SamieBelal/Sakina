// Regression tests for the two discover-name CTA bugs landed alongside this
// test:
//
//   Bug A — double-tap race on the home dashboard "Seek Another Name" CTA
//   (and the muhasabah completed-state CTA). The GestureDetector onTap did
//   `await GatingService().canUse(...)` then `markUsed(...)` with no
//   synchronous in-flight guard. A double-tap that landed while the first
//   call was still inside `canUse` passed the gate twice and `markUsed`
//   fired twice — `discover_name_uses` advanced by 2 instead of 1.
//
//   Same shape as the reflect/duas D-E5 race already pinned by
//   `test/features/reflect/submit_reentry_guard_test.dart` and
//   `test/features/duas/submit_build_reentry_guard_test.dart`. Fix is the
//   same shape too: a synchronous bool flag set BEFORE any await,
//   wrapped in try/finally so every exit path clears it.
//
//   Bug B — `_showDiscoverGateSheet` on `progress_screen.dart` hardcoded
//   `() => GoRouter.of(context).push('/paywall')` as the upgrade callback
//   and ignored `gate.reason`. Premium users hitting the 30/day fair-use
//   ceiling were routed to the paywall they already paid for. Fix: pass
//   `gate.reason` from the call site and use `buildPaywallUpgradeCallback`,
//   which returns a no-op for `GateReason.premiumFairUse` and pushes
//   /paywall otherwise. The muhasabah_screen call site already followed
//   this pattern; progress_screen now mirrors it.
//
// Wiring the full ProgressScreen is impractical (it watches dailyLoopProvider,
// starterNameProvider, tierUpScrollProvider, dailyRewardsProvider,
// isPremiumProvider, plus initState pushes a daily-launch overlay and a
// lapsed-trial sheet via post-frame callbacks). Instead we pin the bugs at
// two complementary levels:
//
//   1. A behavioral test on a stub widget that mirrors the EXACT
//      production guard pattern (State field + try/finally around
//      GatingService.canUse + markUsed). Exercises real `GatingService` so
//      `discover_name_uses` is a true side-effect probe — same approach as
//      the reflect/duas tests, just lifted into a State-class harness
//      because the guard lives on a screen rather than a notifier.
//
//   2. A source-level invariant on `progress_screen.dart` that fails if
//      anyone reverts to the buggy `_showDiscoverGateSheet(BuildContext)`
//      single-arg shape, the hardcoded `push('/paywall')` upgrade callback,
//      or removes the `_discoverInFlight` guard. Mirrors the muhasabah
//      `muhasabah_screen_source_test.dart` idiom already used in this repo.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SupabaseSyncService.debugSetInstance(
      FakeSupabaseSyncService(userId: 'user-discover-reentry'),
    );
    // Capped phase so the daily counter is the side-effect probe. Without
    // this, the user is in warmup and `discover_name_uses` doesn't
    // increment on every successful call (warmup decrements + 1→0
    // transition rule muddies the assertion).
    await GatingService().debugSetHadTrial(true);
  });

  tearDown(SupabaseSyncService.debugReset);

  group('Bug A — discover-name CTA in-flight guard', () {
    testWidgets(
      'two synchronous taps in the same microtask only fire markUsed once '
      '(pre-loading race — pinned by _discoverInFlight, NOT by any post-await flag)',
      (tester) async {
        // Stub widget mirroring the EXACT production guard pattern from
        // progress_screen.dart `_buildMuhasabahRow` (completed state) and
        // muhasabah_screen.dart `_buildCompleted` "Seek Another Name" CTA.
        // The pattern under test is the State-field flag + try/finally
        // around the GatingService canUse/markUsed sequence.
        final controller = _DiscoverCtaController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _DiscoverCtaStub(controller: controller),
            ),
          ),
        );

        // Tap twice in the same microtask. Without the synchronous
        // `_discoverInFlight` flag, both taps would pass the
        // `GatingService.canUse()` await and both would fire `markUsed`,
        // advancing `discover_name_uses` from 0 to 2.
        await tester.tap(find.text('Seek Another Name'), warnIfMissed: false);
        await tester.tap(find.text('Seek Another Name'), warnIfMissed: false);

        // Let both taps progress through any pending awaits.
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(
          await getDiscoverNameUsageToday(),
          1,
          reason:
              'synchronous _discoverInFlight guard must reject the second '
              'tap even when the first has not yet completed canUse(). '
              'discover_name_uses=2 means the guard regressed.',
        );
        expect(
          controller.markUsedCalls,
          1,
          reason: 'markUsed must fire exactly once across both taps',
        );
      },
    );

    testWidgets(
      'second tap during in-flight first tap is rejected (sequential race)',
      (tester) async {
        // Sequential variant: gate the first tap on a Completer so we can
        // stage the second tap arriving deterministically while the first
        // is still inside the try block. Belt-and-braces vs the microtask
        // test — pins the guard against a slower `canUse` round-trip.
        final controller = _DiscoverCtaController(blockOnFirstCall: true);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _DiscoverCtaStub(controller: controller),
            ),
          ),
        );

        await tester.tap(find.text('Seek Another Name'), warnIfMissed: false);
        // Yield once so the first tap enters the try block and flips
        // `_discoverInFlight = true` before the second tap lands.
        await tester.pump();

        await tester.tap(find.text('Seek Another Name'), warnIfMissed: false);
        await tester.pump();

        expect(controller.markUsedCalls, 0,
            reason: 'first call still in flight; markUsed should not have fired');

        // Release the first call.
        controller.releaseFirstCall();
        await tester.pumpAndSettle();

        expect(controller.markUsedCalls, 1,
            reason: 'after release, exactly one markUsed should have fired');
        expect(await getDiscoverNameUsageToday(), 1);
      },
    );
  });

  group('Bug B + structural pins on progress_screen.dart', () {
    late String source;

    setUpAll(() {
      source = File('lib/features/progress/screens/progress_screen.dart')
          .readAsStringSync();
    });

    test(
      '_showDiscoverGateSheet accepts a GateReason (not just BuildContext)',
      () {
        // The bug was the single-arg signature `_showDiscoverGateSheet(
        // BuildContext context)` which threw away `gate.reason` and
        // hardcoded the paywall push. The fix takes `(BuildContext, GateReason)`.
        final hasGateReasonParam = RegExp(
          r'_showDiscoverGateSheet\s*\(\s*BuildContext\s+\w+\s*,\s*GateReason\s+\w+\s*\)',
        ).hasMatch(source);
        expect(
          hasGateReasonParam,
          isTrue,
          reason:
              '_showDiscoverGateSheet must accept a GateReason so premium '
              'users hitting the 30/day fair-use ceiling get a no-op upgrade '
              'CTA instead of being routed to /paywall (Bug B). If this '
              'fails, someone reverted to the single-arg signature.',
        );
      },
    );

    test(
      '_showDiscoverGateSheet uses buildPaywallUpgradeCallback (not a hardcoded paywall push)',
      () {
        expect(
          source.contains('buildPaywallUpgradeCallback'),
          isTrue,
          reason:
              'progress_screen must use buildPaywallUpgradeCallback so the '
              'premiumFairUse branch returns a no-op. A hardcoded `() => '
              "GoRouter.of(context).push('/paywall')` as the onUpgrade is "
              'the regression we just fixed.',
        );
      },
    );

    test(
      'completed-state CTA passes gate.reason into _showDiscoverGateSheet',
      () {
        // The call site (around line 644) used to be
        // `_showDiscoverGateSheet(context)`. After the fix it must pass
        // `gate.reason` so the no-op-for-premium routing kicks in.
        final hasReasonArg = RegExp(
          r'_showDiscoverGateSheet\s*\(\s*context\s*,\s*gate\.reason\s*\)',
        ).hasMatch(source);
        expect(
          hasReasonArg,
          isTrue,
          reason:
              'The completed-state CTA must call '
              '`_showDiscoverGateSheet(context, gate.reason)`. Without the '
              'reason arg, premium fair-use users get the wrong upgrade CTA.',
        );
      },
    );

    test('completed-state CTA has a synchronous _discoverInFlight guard', () {
      // Bug A pin: regression-fail if the State field is removed or the
      // try/finally around the onTap body disappears.
      expect(
        source.contains('_discoverInFlight'),
        isTrue,
        reason:
            'progress_screen must declare `_discoverInFlight` on the State '
            'class and gate the "Seek Another Name" onTap on it (set BEFORE '
            'any await, cleared in finally). Without it, double-taps race '
            'past `canUse` and `markUsed` fires twice — same shape as the '
            'reflect/duas D-E5 race.',
      );

      // Pattern: `if (_discoverInFlight) return;` followed by
      // `_discoverInFlight = true;` and a `try {` ... `} finally {
      // _discoverInFlight = false; }`.
      final hasGuardShape = RegExp(
        r'if\s*\(\s*_discoverInFlight\s*\)\s*return\s*;'
        r'[\s\S]*?_discoverInFlight\s*=\s*true\s*;'
        r'[\s\S]*?try\s*\{'
        r'[\s\S]*?\}\s*finally\s*\{'
        r'[\s\S]*?_discoverInFlight\s*=\s*false\s*;',
      );
      expect(
        hasGuardShape.hasMatch(source),
        isTrue,
        reason:
            'The "Seek Another Name" onTap must follow the canonical guard '
            'shape: early-return on the flag, set the flag synchronously '
            'BEFORE any await, wrap the whole body in try/finally that '
            'clears the flag. Anything else risks the flag sticking true '
            'on an exception path and locking the CTA permanently.',
      );
    });
  });

  group('Bug B + structural pins on muhasabah_screen.dart', () {
    late String source;

    setUpAll(() {
      source = File('lib/features/daily/screens/muhasabah_screen.dart')
          .readAsStringSync();
    });

    test('completed-state "Seek Another Name" CTA has _discoverInFlight guard',
        () {
      expect(
        source.contains('_discoverInFlight'),
        isTrue,
        reason:
            'muhasabah_screen must declare `_discoverInFlight` on the State '
            'class and gate the completed-state "Seek Another Name" onTap '
            'on it. Without it the same double-tap race as the home '
            'dashboard fires twice.',
      );

      final hasGuardShape = RegExp(
        r'if\s*\(\s*_discoverInFlight\s*\)\s*return\s*;'
        r'[\s\S]*?_discoverInFlight\s*=\s*true\s*;'
        r'[\s\S]*?try\s*\{'
        r'[\s\S]*?\}\s*finally\s*\{'
        r'[\s\S]*?_discoverInFlight\s*=\s*false\s*;',
      );
      expect(hasGuardShape.hasMatch(source), isTrue,
          reason:
              'The completed-state CTA must follow the canonical guard shape '
              '(see progress_screen pin for details).');
    });
  });
}

// ---------------------------------------------------------------------------
// Stub widget — mirrors the production guard pattern.
//
// Production lives on a `ConsumerState` (Riverpod) but the guard is a plain
// `bool` field on the State, independent of Riverpod. This stub uses a plain
// `StatefulWidget` so the test doesn't need a `ProviderScope`. The
// `GatingService` calls are real — that's what makes
// `getDiscoverNameUsageToday()` a true side-effect probe.
// ---------------------------------------------------------------------------

class _DiscoverCtaController {
  _DiscoverCtaController({this.blockOnFirstCall = false});

  /// When true, the first tap's `markUsed` await is gated on
  /// [_firstCallCompleter] so the test can stage the second tap arriving
  /// deterministically mid-flight. Subsequent taps run unblocked.
  final bool blockOnFirstCall;

  int markUsedCalls = 0;
  final Completer<void> _firstCallCompleter = Completer<void>();

  void releaseFirstCall() {
    if (!_firstCallCompleter.isCompleted) {
      _firstCallCompleter.complete();
    }
  }
}

class _DiscoverCtaStub extends StatefulWidget {
  const _DiscoverCtaStub({required this.controller});

  final _DiscoverCtaController controller;

  @override
  State<_DiscoverCtaStub> createState() => _DiscoverCtaStubState();
}

class _DiscoverCtaStubState extends State<_DiscoverCtaStub> {
  // Mirrors the production State field. Same name, same type, same
  // semantics — set BEFORE any await, cleared in finally.
  bool _discoverInFlight = false;

  Future<void> _onTap() async {
    if (_discoverInFlight) return;
    _discoverInFlight = true;
    try {
      final gate = await GatingService().canUse(GatedFeature.discoverName);
      if (!gate.allowed) return;

      if (widget.controller.blockOnFirstCall &&
          !widget.controller._firstCallCompleter.isCompleted) {
        await widget.controller._firstCallCompleter.future;
      }

      await GatingService().markUsed(GatedFeature.discoverName);
      widget.controller.markUsedCalls++;
    } finally {
      _discoverInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Seek Another Name'),
      ),
    );
  }
}
