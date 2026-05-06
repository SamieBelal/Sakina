// Architecture regression guard for the muhasabah_screen race-condition fix
// landed alongside this test. See:
//   docs/qa/findings/<add-when-written>.md (or this commit's PR description)
//
// Background: Before the refactor, `MuhasabahScreen.build()` had four blocks
// of side-effecting code:
//
//   1. Streak-milestone overlay push (gated on `_streakMilestoneShown`)
//   2. Level-up overlay push           (gated on `_levelUpShown`)
//   3. Gacha-reveal overlay push       (gated on `_revealShown`)
//   4. Auto-trigger `discoverName()`   (gated on `_discoverTriggered`)
//
// Plus a fifth "reset flags when state.checkinDone goes false" block. Riverpod
// rebuilds the screen any time `dailyLoopProvider` notifies, so all four
// effects could fire (or fire twice) on rebuilds the user did NOT consciously
// trigger. The user-visible bug: after tapping "Return to Home" on the
// Muhāsabah Complete screen, `ref.invalidate(dailyLoopProvider)` flipped
// state.checkinDone back to false, the reset block re-armed
// `_discoverTriggered`, and the auto-trigger fired `discoverName()` for a new
// random Name — pushing a phantom NameRevealOverlay on top of the home
// screen. A `_returningHome` flag was added as a workaround but only closed
// the one specific exit path. Any future invalidation from any other code
// path could repro the bug.
//
// The architectural fix:
//
//   - All four side effects move to a `ref.listen<DailyLoopState>(...)`
//     callback in build(). Listen fires on rising edges (`prev != next`)
//     without triggering rebuilds, giving exactly-once semantics for free.
//   - The auto-trigger moves to `initState()` as a one-shot postFrame
//     callback. It runs once per screen mount, not once per state condition.
//   - "Seek Another Name" calls `discoverName()` explicitly after
//     `resetToday()` — it no longer relies on a rebuild to re-trigger.
//   - The five guard flags (`_revealShown`, `_levelUpShown`,
//     `_streakMilestoneShown`, `_discoverTriggered`, `_returningHome`)
//     are deleted. Rising-edge detection in `ref.listen` replaces them.
//
// This test pins the source-level structure. Re-introducing any of the
// old guard flags or the in-build `addPostFrameCallback(_ => discoverName)`
// pattern fails this test. Behavioral coverage of the happy path is
// validated by the simulator run logged in this PR.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('muhasabah_screen architectural invariants', () {
    late String source;

    setUpAll(() {
      source = File('lib/features/daily/screens/muhasabah_screen.dart')
          .readAsStringSync();
    });

    test('no guard flags from the old in-build side-effect pattern', () {
      // Each flag was the scaffolding propping up a side-effect block in
      // build(). With ref.listen + initState the flags are unnecessary
      // AND harmful (they make the screen state-machine fragile).
      const forbiddenFlags = [
        '_revealShown',
        '_levelUpShown',
        '_streakMilestoneShown',
        '_discoverTriggered',
        '_returningHome',
      ];

      for (final flag in forbiddenFlags) {
        expect(source.contains(flag), isFalse,
            reason:
                'Flag `$flag` was deleted in the muhasabah_screen race-fix '
                'refactor. If you see this fail, you almost certainly added a '
                'guard flag back to a side-effect block in build(). Move the '
                'side effect to `ref.listen<DailyLoopState>(...)` instead — '
                'rising-edge detection (`prev?.X != next.X`) replaces the '
                'flag and prevents the "phantom second gacha on Return to '
                'Home" bug class from regressing.');
      }
    });

    test('build() uses ref.listen for state-driven side effects', () {
      // The fix REQUIRES ref.listen to be present. Without it, side effects
      // would have to live in build conditionals again — which is the bug
      // we just fixed.
      final hasListen = RegExp(
        r'ref\.listen\s*<\s*DailyLoopState\s*>\s*\(\s*dailyLoopProvider',
      ).hasMatch(source);
      expect(hasListen, isTrue,
          reason:
              'build() must call `ref.listen<DailyLoopState>(dailyLoopProvider, ...)` '
              'to dispatch overlay pushes (streak milestone, level-up, name '
              'reveal). If you see this fail, the side effects probably moved '
              'back into build conditionals, which re-opens the race fixed in '
              'this commit.');
    });

    test('initState exists and contains the one-shot discoverName trigger',
        () {
      // The cold-load auto-trigger lives in initState — runs ONCE per
      // mount. If it moves back into build() it can fire on every
      // provider notification, which is the race we just fixed.
      expect(source.contains('void initState()'), isTrue,
          reason:
              'MuhasabahScreen must override initState. The one-shot '
              'auto-trigger that fires discoverName on cold load lives '
              'there; without it, the screen never starts a new check-in '
              'cycle when the user lands on /muhasabah fresh.');

      // The one-shot pattern: postFrame callback inside initState that
      // calls discoverName when checkinDone is false. Match the structure
      // loosely to allow whitespace/formatting drift.
      final initStateOneShot = RegExp(
        r'void\s+initState[\s\S]*?addPostFrameCallback[\s\S]*?'
        r'!state\.checkinDone[\s\S]*?discoverName',
      );
      expect(initStateOneShot.hasMatch(source), isTrue,
          reason:
              'initState must contain the one-shot pattern: '
              'addPostFrameCallback → check `!state.checkinDone` → call '
              'discoverName(). If this is missing, cold-load on /muhasabah '
              'will hang on a loading spinner because nothing kicks off '
              'the discover flow.');
    });
  });
}
