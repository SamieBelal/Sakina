// Regression guard for the gacha eager-dismiss bug recorded in
// `docs/qa/findings/2026-04-22-core-loop-fixes.md` (F3).
//
// The outer `GestureDetector` previously called `_handleContinue` whenever
// `_phase >= 2` — opening a ~1200ms window where users could dismiss the
// overlay BEFORE the Continue button (phase 3) rendered, missing reward
// details entirely.
//
// Fix in `lib/features/daily/widgets/name_reveal_overlay.dart`:
//   onTap: _phase >= 3 ? _handleContinue : null
//
// This test pins the gate at the source level. We do NOT pump the full
// overlay because:
//   - It uses `flutter_animate` `.repeat(reverse: true)` continuous loops
//     that `pumpAndSettle` cannot drain (per `collection_screen_test.dart`
//     §10 C4 comment: "would either hang or leak Timers").
//   - It uses Google Fonts which trip on `runAsync` / fake clock combos.
//
// The structural assertion is still valuable: a future refactor that
// replaces the gate with `>= 2` (the regression we're guarding against) or
// removes the gate entirely will fail this test. End-to-end behavior is
// covered by the simulator run in
// `docs/qa/runs/2026-04-27-§12-quests-titles-streaks.md` S-3 (NameReveal
// renders cleanly post-discoverName).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'name_reveal_overlay outer GestureDetector gates Continue on phase 3 '
      '(F3 regression guard)', () {
    final source = File(
      'lib/features/daily/widgets/name_reveal_overlay.dart',
    ).readAsStringSync();

    // The exact gate: `onTap: _phase >= 3 ? _handleContinue : null`.
    // Allow whitespace flex but pin the comparison and the null-fallback so
    // both halves of the fix are protected.
    final gatePattern = RegExp(
      r'onTap\s*:\s*_phase\s*>=\s*3\s*\?\s*_handleContinue\s*:\s*null',
    );

    expect(gatePattern.hasMatch(source), isTrue,
        reason:
            'Outer GestureDetector must keep `onTap: _phase >= 3 ? '
            '_handleContinue : null`. If you see this fail, you almost '
            'certainly loosened the gate to `>= 2` or `>= 1` — that is the '
            'F3 eager-dismiss regression. Confirm on-device that taps '
            'during the 1.6–2.8s window are absorbed before changing.');

    // Belt-and-braces: also forbid the historical buggy form so a careless
    // rewrite that splits onto multiple lines but reintroduces `>= 2` on a
    // tap handler still trips the assertion.
    final buggyPattern = RegExp(
      r'onTap\s*:\s*_phase\s*>=\s*2\s*\?\s*_handleContinue',
    );
    expect(buggyPattern.hasMatch(source), isFalse,
        reason:
            'Found `onTap: _phase >= 2 ? _handleContinue` — this is the '
            'exact pre-fix form that caused F3.');
  });
}
