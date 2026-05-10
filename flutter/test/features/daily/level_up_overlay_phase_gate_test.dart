// Regression guard for the level-up double-continue bug observed on 2026-05-09.
//
// The level-up overlay had two `GestureDetector`s active during phase 2:
//   1. Full-screen body (`onTap: _phase >= 2 ? _handleContinue : null`)
//   2. The Continue button itself, wrapped in `flutter_animate`'s
//      `.fadeIn(delay: 900.ms, duration: 500.ms)`
//
// During the 0–1400ms fade-in window, gesture arena resolution between the
// two detectors raced — the first tap on the Continue button frequently
// failed to dismiss the overlay. Users had to tap a second time. Same shape
// as the gacha "eager-dismiss" bug guarded by
// `name_reveal_overlay_phase_gate_test.dart`.
//
// Fix in `lib/features/daily/widgets/level_up_overlay.dart`:
//   onTap: _phase >= 3 ? _handleContinue : null
// — phase 3 is set ~1400ms after phase 2 begins, after the button is fully
// on-screen. The Continue button itself is unaffected and remains tappable
// from phase 2 onward; only the full-screen "tap anywhere" affordance waits.
//
// This test pins the gate at the source level. Pumping the full overlay is
// not viable: it uses `flutter_animate` `.repeat(reverse: true)` continuous
// loops that `pumpAndSettle` cannot drain, plus Google Fonts which trip on
// `runAsync` / fake clock combos — the same constraints that drove
// `name_reveal_overlay_phase_gate_test.dart` to use a structural assertion.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'level_up_overlay outer GestureDetector gates Continue on phase 3 '
      '(double-continue regression guard)', () {
    final source = File(
      'lib/features/daily/widgets/level_up_overlay.dart',
    ).readAsStringSync();

    // The exact gate: `onTap: _phase >= 3 ? _handleContinue : null`.
    // Allow whitespace flex but pin both the comparison and the null-fallback.
    final gatePattern = RegExp(
      r'onTap\s*:\s*_phase\s*>=\s*3\s*\?\s*_handleContinue\s*:\s*null',
    );

    expect(gatePattern.hasMatch(source), isTrue,
        reason:
            'Outer GestureDetector must keep `onTap: _phase >= 3 ? '
            '_handleContinue : null`. If you see this fail, you almost '
            'certainly loosened the gate to `>= 2` — that is the '
            'double-continue regression. Confirm on-device that taps '
            'on the Continue button during the 0–1400ms fade-in window '
            'dismiss on first tap before changing.');

    // Belt-and-braces: also forbid the historical buggy form so a careless
    // rewrite that splits onto multiple lines but reintroduces `>= 2` on a
    // tap handler still trips the assertion.
    final buggyPattern = RegExp(
      r'onTap\s*:\s*_phase\s*>=\s*2\s*\?\s*_handleContinue',
    );
    expect(buggyPattern.hasMatch(source), isFalse,
        reason:
            'Found `onTap: _phase >= 2 ? _handleContinue` — this is the '
            'exact pre-fix form that caused the double-continue bug.');

    // Phase 3 must actually be reached by the sequence; otherwise the gate
    // would be permanent and the "tap anywhere" affordance dead.
    final phase3Setter = RegExp(r'setState\(\(\)\s*=>\s*_phase\s*=\s*3\)');
    expect(phase3Setter.hasMatch(source), isTrue,
        reason:
            '`_runSequence` must set `_phase = 3` so the outer gate ever '
            'opens. Without it the user can only dismiss via the Continue '
            'button — losing the documented "tap anywhere to continue" '
            'affordance.');
  });
}
