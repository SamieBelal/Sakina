import 'package:flutter/widgets.dart';

import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/motion_context.dart';

/// Opening a saved entry is not travel — it is the same thing getting closer.
///
/// `MaterialPageRoute` gives a horizontal slide-in on iOS: a navigation-stack
/// idiom that says *"you went somewhere else."* That is right for a settings
/// sub-page and wrong for a reflection you wrote, where the card you tapped and
/// the page you land on are the same content at two distances. A fade-through
/// reads as an unfolding instead.
///
/// **This is not a new pattern.** `PageRouteBuilder` + `FadeTransition` is
/// already the house route for the card reveal (`collection_screen.dart`), so
/// this only gives it a name and puts it on the motion tokens.
///
/// Deliberately NOT a `Hero` flight. It looks impressive in a demo reel, but it
/// moves a large object a large distance — the exact class Val Head names as a
/// vestibular trigger (*"the relative size of the movement"* and *"the distance
/// covered"*) — and Flutter's own docs concede a `Hero` "would really have to be
/// massaged to look good" for a text-dominant destination. Not one of the
/// reflective apps surveyed uses one. Fade-through is cheaper *and* calmer.
///
/// The scale is 0.98 → 1.0: just enough to feel like arrival rather than a
/// crossfade, small enough that it never reads as a zoom. Under reduced motion
/// it collapses to a plain, near-instant fade with no scale at all.
Route<T> fadeThroughRoute<T>(
  BuildContext context,
  Widget page, {
  String? name,
}) {
  final reduce = context.reduceMotion;
  return PageRouteBuilder<T>(
    settings: name == null ? null : RouteSettings(name: name),
    transitionDuration: context.motion(AppMotion.entrance),
    reverseTransitionDuration: context.motion(AppMotion.recede),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final fade = CurvedAnimation(parent: animation, curve: AppMotion.enter);
      if (reduce) return FadeTransition(opacity: fade, child: child);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(fade),
          child: child,
        ),
      );
    },
  );
}
