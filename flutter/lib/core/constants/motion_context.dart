import 'package:flutter/widgets.dart';

import 'package:sakina/core/constants/app_motion.dart';

/// Reduced-motion access, in one place.
///
/// ## Why this exists
///
/// `MediaQuery.disableAnimations` was already read ad-hoc in ten-plus files —
/// `beat_reveal_flow`, `sacred_canvas_threshold`, `card_reveal_overlay`,
/// `companion_medallion`, `tour_overlay_host`, the daily-question widgets and
/// three onboarding screens — each re-deriving the same boolean and then
/// hand-rolling its own collapsed timings.
///
/// `lib/features/journal/` read it **nowhere**, which is why every fade, slide
/// and stagger in the archive played at full length regardless of the setting.
/// `DESIGN.md §5` already mandates the opposite — *"Any new canvas motion must
/// honor a reduced-motion path — never gate content behind an animation that
/// can't be turned off"* — and Apple's HIG is explicit: *"When the option to
/// reduce motion is enabled… your app should minimize or eliminate application
/// animations."*
///
/// ## The rule this encodes
///
/// Reduced motion means **less movement, not less content, and not a slower
/// app.** So durations collapse toward instant and translation collapses to
/// zero — but nothing is hidden, nothing is skipped, and no tap changes
/// meaning. A user with the setting on should reach the same screen in the same
/// number of taps, sooner.
///
/// Deliberately NOT zero: [collapsed] is 1ms rather than `Duration.zero`.
/// `flutter_animate` treats a zero-duration effect as a degenerate case in
/// places, and one frame is already imperceptible — the same value
/// `beat_reveal_flow` settled on for the canvas.
extension MotionContext on BuildContext {
  /// True when the OS asks for reduced motion.
  ///
  /// `maybeOf` rather than `of`: this is read from widgets that are also built
  /// in tests without a `MediaQuery` ancestor, and the honest default there is
  /// "animations are fine".
  bool get reduceMotion =>
      MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  /// [full] normally; effectively instant under reduced motion.
  Duration motion(Duration full) => reduceMotion ? AppMotion.collapsed : full;

  /// Entrance travel in logical pixels — zero under reduced motion, because
  /// translation is the part that actually causes vestibular trouble. The fade
  /// survives, so the element still announces itself.
  double rise(double full) => reduceMotion ? 0 : full;

  /// Per-item stagger delay for a list at [index].
  ///
  /// Two things happen here that did not before:
  ///
  /// * **It is clamped.** The journal previously used a raw `index * 50ms` with
  ///   no ceiling, so item 40 waited 1,950ms and item 100 waited 4,950ms. In a
  ///   `ListView.builder` the delay is keyed to the LIST index rather than to
  ///   when the item was built, so scrolling fast into a long journal produced
  ///   blank cards that faded in seconds later. `AppMotion`'s own doc names the
  ///   ceiling that broke: *"a staggered reveal should settle inside ~800-900ms
  ///   total."*
  /// * **It stops under reduced motion**, where a stagger is pure delay with no
  ///   movement to justify it.
  ///
  /// [maxSteps] 6 gives a seven-item span at 240ms, which is the span
  /// `AppMotion.stagger` was chosen for.
  Duration stagger(int index, {int maxSteps = 6}) {
    if (reduceMotion) return Duration.zero;
    final steps = index < 0 ? 0 : (index > maxSteps ? maxSteps : index);
    return AppMotion.stagger * steps;
  }
}
