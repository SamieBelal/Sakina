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
//   1. A behavioral test on a stub widget that mirrors the production guard
//      shape (State field + try/finally around an async CTA body). Exercises
//      real `GatingService` so `discover_name_uses` is a true side-effect
//      probe — same approach as the reflect/duas tests, just lifted into a
//      State-class harness because the guard lives on a screen rather than a
//      notifier.
//
//   2. A source-level invariant on `progress_screen.dart` that fails if
//      anyone reverts to the buggy `_showDiscoverGateSheet(BuildContext)`
//      single-arg shape, the hardcoded `push('/paywall')` upgrade callback,
//      or removes the `_discoverInFlight` guard. Mirrors the muhasabah
//      `muhasabah_screen_source_test.dart` idiom already used in this repo.
//
// UPDATED by W4 Wave 1 (plan 2026-07-30-one-ship-04): `markUsed` no longer
// lives at either CTA — it moved into `DailyLoopNotifier.discoverName`, so that
// opening the daily question and backing out cannot burn the user's one free
// reveal. `canUse` STAYS at the CTA, and so does `_discoverInFlight`.
//
// What that does to this file:
//   - The stub below still pins the guard SHAPE, which is what Bug A was
//     about, but the work it guards is now `canUse` + the provider call. It is
//     a model of the shape, not a copy of the current CTA body.
//   - Two new source-level pins assert the negative: neither screen may call
//     `GatingService().markUsed` again. That is the regression this wave is
//     protecting against, and it is invisible to any behavioral test that does
//     not wire the whole screen.
//   - The consumption contract itself (charged once, on success only, never on
//     the bypass paths) is pinned behaviorally in
//     `test/features/daily/discover_name_mark_used_test.dart`.

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
        // Stub widget mirroring the production guard shape from
        // progress_screen.dart `_buildMuhasabahRow` (completed state) and
        // muhasabah_screen.dart `_buildCompleted` "Seek Another Name" CTA.
        // The pattern under test is the State-field flag + try/finally around
        // an async CTA body. `markUsed` stands in here for the work the real
        // CTAs now delegate to `discoverName` — the point is that a second tap
        // must not reach it, wherever it lives.
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

  group('progress_screen.dart no longer hosts a re-roll at all', () {
    // 2026-08-01 (founder): the home CTA's completed state was deleted — once
    // the day's muḥāsabah is done the slot closes rather than swapping to a
    // "Today's muḥāsabah is complete" panel. That panel was the only host of
    // "Meet another Name", so `_rerollName`, `_showDiscoverGateSheet` and the
    // `_discoverInFlight` guard went with it.
    //
    // Bug A and Bug B were NOT unpinned by that deletion. They were re-pointed
    // at the surviving call site — the muḥāsabah completion screen's "Seek
    // Another Name", which carries the identical gate, cap sheet and
    // rerollPremium wall and is the screen the user is standing on the instant
    // the loop completes. Those pins are the group below, and they are now the
    // only ones, so treat them as load-bearing.
    //
    // What this group pins is the negative: if a second copy of the gated
    // re-roll is ever rebuilt on the home screen, it must come back WITH its
    // guard rather than without it. A bare `canUse` here — no in-flight flag,
    // no `buildPaywallUpgradeCallback` — is exactly the pair of bugs above.
    late String source;

    setUpAll(() {
      // COMMENTS STRIPPED. The doc on `_buildMuhasabahCta` names the deleted
      // helpers on purpose — it is the note telling the next reader not to
      // rebuild them — and a raw `contains` would read that prose as the code
      // coming back.
      source = File('lib/features/progress/screens/progress_screen.dart')
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//') &&
              !l.trimLeft().startsWith('///'))
          .join('\n');
    });

    test('no gated action is invoked from the home screen', () {
      expect(
        RegExp(r'canUse\s*\(').hasMatch(source),
        isFalse,
        reason: 'progress_screen gates nothing since the completed card was '
            'deleted. If you are adding a gated action back, add the '
            '_discoverInFlight guard shape and the buildPaywallUpgradeCallback '
            'routing WITH it — see the muhasabah_screen pins below for the '
            'shape, and re-point this test rather than deleting it.',
      );
      expect(
        source.contains('_showDiscoverGateSheet'),
        isFalse,
        reason: 'the cap sheet presenter left with the re-roll; a second copy '
            'is a second thing to keep correct',
      );
    });

    test('the home screen still never CONSUMES (W4 Wave 1)', () {
      // The negative pin survives the deletion unchanged: with a question
      // between the tap and the reveal, marking at the tap means opening the
      // prompt and backing out burns the day's free reveal. The charge lives at
      // the tail of `DailyLoopNotifier.discoverName`, where a Name has
      // demonstrably been engaged.
      expect(
        RegExp(r'markUsed\s*\(').hasMatch(source),
        isFalse,
        reason: 'progress_screen must not call GatingService.markUsed. If this '
            'fails, someone moved consumption back onto the tap and a user who '
            'opens the daily question and backs out is charged for a reveal '
            'they never saw.',
      );
    });
  });

  group('Bug B + structural pins on muhasabah_screen.dart', () {
    // SINCE 2026-08-01 THIS IS THE ONLY COPY. The home screen's completed-state
    // re-roll was deleted with the card that hosted it, so every Bug B pin that
    // used to be duplicated against progress_screen.dart now lives here alone.
    // Relaxing one of these no longer leaves a second guarded call site behind.
    late String source;

    setUpAll(() {
      source = File('lib/features/daily/screens/muhasabah_screen.dart')
          .readAsStringSync();
    });

    test('_showDiscoverGateSheet accepts a GateReason', () {
      // The original bug was a signature that threw `gate.reason` away and
      // hardcoded the paywall push, so premium users hitting the 30/day
      // fair-use ceiling were routed to the paywall they had already paid for.
      expect(
        RegExp(r'_showDiscoverGateSheet\s*\(\s*GateReason\s+\w+\s*\)')
            .hasMatch(source),
        isTrue,
        reason: '_showDiscoverGateSheet must take the reason so the '
            'premiumFairUse branch can be told apart. If this fails, someone '
            'reverted to a reason-less signature.',
      );
    });

    test('it uses buildPaywallUpgradeCallback, not a hardcoded paywall push',
        () {
      expect(
        source.contains('buildPaywallUpgradeCallback'),
        isTrue,
        reason: 'muhasabah_screen must use buildPaywallUpgradeCallback so the '
            'premiumFairUse branch returns a no-op. A hardcoded '
            "`push('/paywall')` as the onUpgrade is the Bug B regression.",
      );
    });

    test('the CTA passes gate.reason into the sheet', () {
      expect(
        RegExp(r'_showDiscoverGateSheet\s*\(\s*gate\.reason\s*\)')
            .hasMatch(source),
        isTrue,
        reason: 'without the reason arg, premium fair-use users get the wrong '
            'upgrade CTA — they are sold what they already bought.',
      );
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

    test('the "Seek Another Name" CTA gates but does not CONSUME (W4 Wave 1)',
        () {
      expect(source.contains('canUse('), isTrue,
          reason: 'the gate check must stay at the CTA');
      expect(
        RegExp(r'markUsed\s*\(').hasMatch(source),
        isFalse,
        reason: 'muhasabah_screen must not call GatingService.markUsed — the '
            'charge belongs to discoverName, which only marks once a Name has '
            'actually been engaged. See the progress_screen pin for why.',
      );
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
