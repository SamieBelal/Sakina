/// The Journal's compose chooser, as an arc off the `+` (2026-08-07).
///
/// The chooser this replaces was a bottom sheet. A sheet is the right shape for
/// a list that might grow, and the wrong one here: this list is two rows, it
/// will stay two rows, and a sheet made two rows travel the full height of the
/// screen to be read. The arc puts them where the thumb already is — beside the
/// control that summoned them — and the dim behind it says the rest of the
/// screen is out of play, which a sheet only implies.
///
/// **Anchored to the FAB, not to the screen.** Every position below is measured
/// from the real button's centre, so the fan appears to come out of the control
/// the user pressed rather than to arrive from somewhere else.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/motion_context.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/journal/journal_compose_action.dart';

/// Standard Material FAB. The arc is measured from the centre of one.
const double _fabDiameter = 56;

/// The FAB's inset from the screen edges — `FloatingActionButtonLocation
/// .endFloat`'s own margin.
const double _fabMargin = 16;

/// One option's circle. Smaller than the FAB so the parent still reads as the
/// primary, comfortably past the 44pt minimum target.
const double _optionDiameter = 52;

/// How far each option sits from the FAB's centre.
///
/// Was 132 with a 22° start, which put the first label's left edge at x = -10
/// on a 390pt screen — off the side of the phone. The shallower the angle, the
/// further left an option travels, and the label hangs further left again. 108
/// with a 30° floor keeps the whole row on screen; [_labelMaxWidth] is the
/// belt-and-braces that makes it true at any width.
const double _arcRadius = 120;

/// The fan, in degrees from horizontal-left (0°) toward straight-up (90°).
///
/// Not the full quarter: a shallow option sits level with the FAB and drags its
/// label off the left edge, and at 90° it stacks directly above and the arc
/// reads as a column. Insetting both ends keeps it legible as an arc AND on the
/// screen.
const double _arcStartDeg = 20;
const double _arcEndDeg = 80;

/// Opens the arc. [onPick] fires once, after the menu has closed.
///
/// A route rather than an overlay in the screen's own tree, so the system back
/// gesture closes it for free and it cannot be left open by a rebuild.
///
/// [onPick] rather than a `Future<JournalComposeAction?>` return: the caller
/// navigates, and a navigation queued off a route's own completion future runs
/// a beat later than the pop it is chained to. A callback invoked after the pop
/// keeps the two in the same frame, which is also what makes it testable
/// without sprinkling extra pumps at every call site.
Future<void> showRadialComposeMenu(
  BuildContext context, {
  required List<JournalComposeAction> options,
  required bool isPremium,
  required ValueChanged<JournalComposeAction> onPick,
}) {
  final motion = context.motion(AppMotion.layer);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    // Painted by the menu itself so the dim can animate with the arc rather
    // than snapping in ahead of it.
    barrierColor: Colors.transparent,
    transitionDuration: motion,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) => _RadialComposeMenu(
      animation: animation,
      options: options,
      isPremium: isPremium,
      onPick: onPick,
    ),
  );
}

class _RadialComposeMenu extends StatelessWidget {
  const _RadialComposeMenu({
    required this.animation,
    required this.options,
    required this.isPremium,
    required this.onPick,
  });

  final Animation<double> animation;
  final List<JournalComposeAction> options;
  final bool isPremium;
  final ValueChanged<JournalComposeAction> onPick;

  /// Where option [i] of [n] sits on the arc, in radians.
  ///
  /// A single option takes the midpoint rather than an end: one item at 22° is
  /// a button that fell out of the FAB, and at 72° it is a column of one.
  static double angleFor(int i, int n) {
    final deg = n == 1
        ? (_arcStartDeg + _arcEndDeg) / 2
        : _arcStartDeg + (_arcEndDeg - _arcStartDeg) * (i / (n - 1));
    return deg * math.pi / 180;
  }

  IconData _iconFor(JournalComposeAction action) => switch (action) {
        JournalComposeAction.startTonight => Icons.nightlight_round,
        JournalComposeAction.addToTonight => Icons.add_comment_outlined,
        JournalComposeAction.newReflection => Icons.auto_awesome_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The real FAB's centre, measured from the bottom-right corner. It sits
    // above the system inset, which is why `viewPadding.bottom` is in here.
    const fabCentreFromRight = _fabMargin + _fabDiameter / 2;
    final fabCentreFromBottom =
        media.viewPadding.bottom + _fabMargin + _fabDiameter / 2;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeOut.transform(animation.value.clamp(0.0, 1.0));
        return Material(
          type: MaterialType.transparency,
          // `SizedBox.expand`, and it is load-bearing rather than tidiness: a
          // Stack whose children are ALL `Positioned` has nothing to size
          // itself from, so under the loose constraints a dialog route hands
          // down it collapses and clips every child. The widgets still exist
          // and still read as present to `find.byType` — they simply cannot be
          // hit, which is the most confusing shape this bug has.
          child: SizedBox.expand(
            child: Stack(
              key: const ValueKey('journal-compose-menu'),
              children: [
                // ── The dim ──
                //
                // Its own tap target, so the scrim dismisses. `showGeneralDialog`
                // would do that via `barrierDismissible` alone, but only outside
                // the (transparent) barrier colour — painting it here keeps the
                // two the same surface.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      color: AppColors.textPrimaryLight
                          .withValues(alpha: 0.58 * t),
                    ),
                  ),
                ),

                // ── The options ──
                for (var i = 0; i < options.length; i++)
                  _positioned(
                    context,
                    index: i,
                    t: t,
                    fromRight: fabCentreFromRight,
                    fromBottom: fabCentreFromBottom,
                  ),

                // ── The FAB, wearing an × ──
                //
                // A stand-in painted over the real one at the same coordinates:
                // the real FAB belongs to the Scaffold under this route and
                // cannot be told the menu is open.
                Positioned(
                  right: _fabMargin,
                  bottom: media.viewPadding.bottom + _fabMargin,
                  child: Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: _fabDiameter,
                        height: _fabDiameter,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Transform.rotate(
                          // A + turned an eighth of a turn IS an ×. Rotating the
                          // same glyph rather than swapping icons keeps the
                          // control continuous with the one that was pressed.
                          angle: t * math.pi / 4,
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _positioned(
    BuildContext context, {
    required int index,
    required double t,
    required double fromRight,
    required double fromBottom,
  }) {
    final action = options[index];
    final angle = angleFor(index, options.length);

    // Staggered so the arc unrolls rather than appearing whole. Under reduced
    // motion `t` arrives at 1 in a single frame, so this collapses to nothing
    // on its own — no branch needed.
    final delay = index * 0.12;
    final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
    final reach = _arcRadius * local;

    return Positioned(
      // Both edges pinned, so the child is laid out under BOUNDED width — the
      // only thing that reliably stops the label running off the phone. Two
      // arithmetic attempts at a width (a `maxWidth` constraint, then a
      // definite `SizedBox`) both failed to bind here and shipped a label
      // starting at x = -30 on a 390pt screen; real constraints do not miss.
      //
      // The `Align` + `MainAxisSize.min` below is what keeps that bounded box
      // from also becoming the TAP target: pinning `left` alone made every row
      // a full-width invisible slab, and the option higher on the arc — painted
      // later, so on top — swallowed taps meant for the one beneath it.
      left: 12,
      right: fromRight + reach * math.cos(angle) - _optionDiameter / 2,
      bottom: fromBottom + reach * math.sin(angle) - _optionDiameter / 2,
      child: Align(
        // Hugs the arc position; the row grows leftward from it.
        alignment: Alignment.centerRight,
        child: Opacity(
          opacity: local,
        // The WHOLE row is the target, label included. The label is the wider
        // half of it by a factor of four, and a 210pt caption sitting inert
        // beside a 52pt circle is a target that looks like one and is not —
        // the exact complaint that got the old shape-shifting FAB replaced.
        child: Semantics(
          button: true,
          label: JournalComposeCopy.label(action),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
              onPick(action);
            },
            child: Row(
              // Right-aligned: the circle holds the arc position and the label
              // grows away from it, into the space toward the screen's left.
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // The label sits LEFT of its circle, so the whole row grows
                // away from the screen edge the FAB is pinned to.
                Flexible(child: _label(action)),
                const SizedBox(width: 12),
                _circle(action),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(JournalComposeAction action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            JournalComposeCopy.label(action),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          // The consequence, still stated before the tap — the whole reason the
          // chooser exists. A bare icon ring would have thrown it away.
          // ONE line each, ellipsised. Two arc positions on a phone are ~77pt
          // apart vertically; a label that wraps to two lines makes the row
          // ~80pt tall, the rows overlap, and the option higher on the arc
          // (painted last, therefore on top) swallows taps meant for the one
          // below it. Measured, twice, before this constraint went in.
          Text(
            JournalComposeCopy.subtitle(action, isPremium: isPremium),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondaryLight, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// Presentation only — the tap lives on the whole row, in [_positioned].
  Widget _circle(JournalComposeAction action) {
    return Container(
      width: _optionDiameter,
      height: _optionDiameter,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimaryLight.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(_iconFor(action), color: AppColors.primary, size: 24),
    );
  }
}
