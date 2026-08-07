/// The Journal's compose chooser — a stack of options above the `+`
/// (2026-08-07).
///
/// The chooser this replaces was a bottom sheet. A sheet is the right shape for
/// a list that might grow, and the wrong one here: this list is two rows, it
/// will stay two rows, and a sheet made two rows travel the full height of the
/// screen to be read. Stacking them straight up out of the button puts them
/// where the thumb already is, and the dim behind says the rest of the screen
/// is out of play, which a sheet only implies.
///
/// ## The FAB is MEASURED, never computed
///
/// [showComposeMenu] takes the real button's global [Rect] and every position
/// here is derived from it. The first draft computed one instead, from
/// `viewPadding.bottom + margin + diameter/2` — the right formula for a Scaffold
/// with no bottom bar, and wrong by the height of one on this screen. What
/// shipped was a SECOND control: the real `+` stayed where it had always been
/// and a stand-in `×` was painted ~60pt below it, so opening the menu put two
/// buttons on screen and neither of them under the finger that had just tapped.
///
/// The lesson is narrow and worth keeping: **`viewPadding` describes the system
/// insets, not the app's own chrome.** A `BottomNavigationBar` appears in
/// neither `viewPadding` nor `viewInsets`, so any arithmetic that guesses the
/// FAB's position is wrong on precisely the screens that have one. The render
/// object knows where it is; ask it.
///
/// ## There was an arc here. It is gone, and this is why
///
/// Three passes tried to fan these options on a circle, in the shape of a
/// speed-dial reference that showed bare icons and no labels. Ours cannot be
/// bare — one row spends a metered allowance and the others do not, and saying
/// so *before* the tap is the whole reason the chooser replaced a shape-
/// shifting FAB. Adding cards to an arc is what broke it, every time:
///
///  1. `R=124, 35°–80°` — 51pt of vertical separation against a 61pt card. The
///     two cards shipped visibly fused into one white blob.
///  2. `R=140, 30°–85°` — overlap fixed, at the cost of putting the nearest
///     option 140pt from the button and the two circles 109pt apart
///     horizontally. Read as scatter.
///  3. A per-row shim pinning every card to a shared right edge, to fix the
///     raggedness of (2) — which put the top card **120pt from its own icon**.
///     A caption that far from what it captions is orphaned, not aligned.
///
/// The cause is structural, not a tuning miss: **on a circle the two axes are
/// coupled.** Vertical separation is `R·(sin θ₂ − sin θ₁)`, so the only way to
/// give two cards room to clear each other is a big radius or a wide angular
/// span, and both throw the options sideways — into the space the cards need.
///
/// A straight stack decouples them. [_optionSpacing] buys vertical room and
/// costs nothing horizontally; every circle shares the FAB's column, so every
/// card shares one right edge for free rather than by arithmetic; and each card
/// sits [_labelGap] from its own circle, so it is never far from what it names.
/// One `Row` per option, so the card and its circle are a single tap target.
///
/// What survives of the fan is the MOTION: the options still unroll out of the
/// button one after another ([_staggerFraction]), and the `+` still turns into
/// an `×` without moving. That was always the part that read as "this came out
/// of the button"; the curve was never doing that work.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/motion_context.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/journal/journal_compose_action.dart';
import 'package:sakina/services/gating_service.dart';

/// One option's circle. Smaller than the FAB so the parent still reads as the
/// primary, comfortably past the 44pt minimum target.
const double _optionDiameter = 52;

/// How far the FIRST option's centre sits above the FAB's centre.
///
/// The floor is 54 — the FAB's half-height plus the circle's — so 72 leaves
/// 18pt of air between the two edges. Was a 140pt arc radius, which put the
/// nearest option a circle-and-a-half away and made the menu read as something
/// that had arrived from elsewhere rather than come out of the button.
const double _firstOptionRise = 72;

/// Vertical centre-to-centre gap between consecutive options.
///
/// **The number the card height has to fit inside**, and the one an arc could
/// not give without also throwing the options sideways — see the library doc.
/// 64 against a ~52pt card leaves 12pt of air between them.
const double _optionSpacing = 64;

/// Between a label card and its circle, at the row's widest point.
const double _labelGap = 12;

/// The widest a label card may ever be, before the screen's own limit applies.
///
/// The circles are the composition; the cards annotate them. A card past this
/// stops reading as an annotation and starts reading as a menu with icons
/// stuck on the side.
const double _labelMaxWidth = 168;

/// How long the whole stack takes to unroll.
///
/// Deliberately shorter than [AppMotion.layer] (400ms), which is the token for
/// a secondary layer settling in behind a primary one. This is not that: it is
/// a menu answering a press, and NN/g puts simple feedback near 100ms. At 400ms
/// the stack read as sluggish — options were still arriving after the thumb
/// had stopped moving.
const Duration _openDuration = Duration(milliseconds: 260);

/// How far each option lags the one before it, as a fraction of [_openDuration].
///
/// Enough that the stack unrolls rather than appearing whole; small enough that
/// the last option is not still travelling when the first is done. Was 0.12,
/// which at 400ms left the second row starting 48ms after the first and
/// finishing well after it.
const double _staggerFraction = 0.07;

/// The FAB's corner radius. Material 3 gives `FloatingActionButton` a rounded
/// squircle, not a circle — the stand-in has to agree or it reads as a
/// different button appearing rather than the same one turning.
const double _fabCornerRadius = 16;

/// Opens the menu. [onPick] fires once, after the menu has closed.
///
/// [fabRect] is the real FAB's rect in GLOBAL coordinates — see the library doc
/// for why this is a parameter and not a calculation. The caller measures it
/// from a `GlobalKey` on the very button this is about to cover.
///
/// A route rather than an overlay in the screen's own tree, so the system back
/// gesture closes it for free and it cannot be left open by a rebuild.
///
/// [onPick] rather than a `Future<JournalComposeAction?>` return: the caller
/// navigates, and a navigation queued off a route's own completion future runs
/// a beat later than the pop it is chained to. A callback invoked after the pop
/// keeps the two in the same frame, which is also what makes it testable
/// without sprinkling extra pumps at every call site.
Future<void> showComposeMenu(
  BuildContext context, {
  required List<JournalComposeAction> options,
  required Rect fabRect,
  required ValueChanged<JournalComposeAction> onPick,
  AllowanceSnapshot? allowance,
}) {
  final motion = context.motion(_openDuration);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    // Painted by the menu itself so the dim can animate with the options
    // rather than snapping in ahead of them.
    barrierColor: Colors.transparent,
    transitionDuration: motion,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) => _ComposeMenu(
      animation: animation,
      options: options,
      fabRect: fabRect,
      allowance: allowance,
      onPick: onPick,
    ),
  );
}

class _ComposeMenu extends StatelessWidget {
  const _ComposeMenu({
    required this.animation,
    required this.options,
    required this.fabRect,
    required this.allowance,
    required this.onPick,
  });

  final Animation<double> animation;
  final List<JournalComposeAction> options;

  /// The real FAB, in global coordinates. Measured by the host, never guessed.
  final Rect fabRect;

  /// The live allowance, or null. Resolved by the host BEFORE the tap — see
  /// [JournalComposeCopy.subtitle] for why that timing is the whole trick, why
  /// this is a snapshot rather than a bare count, and why it is also the ONLY
  /// thing here that knows whether the user is premium.
  final AllowanceSnapshot? allowance;
  final ValueChanged<JournalComposeAction> onPick;

  /// How far option [i] settles above the FAB's centre.
  ///
  /// A straight stack: no horizontal component at all, so every circle sits in
  /// the FAB's own column and every card therefore shares one right edge
  /// without any arithmetic having to arrange it. See the library doc for the
  /// three arcs this replaced.
  static double riseFor(int i) => _firstOptionRise + _optionSpacing * i;

  IconData _iconFor(JournalComposeAction action) => switch (action) {
        JournalComposeAction.startTonight => Icons.nightlight_round,
        JournalComposeAction.addToTonight => Icons.add_comment_outlined,
        JournalComposeAction.newReflection => Icons.auto_awesome_outlined,
      };

  @override
  Widget build(BuildContext context) {
    // **The size comes from LAYOUT, not from `MediaQuery`.** Those two can
    // disagree, and when they do everything here is wrong by the difference:
    // measured on this very menu, a dialog route reported `MediaQuery.sizeOf`
    // = 800×600 while the FAB underneath had been laid out on a 390×844
    // surface, which put `fabCentreFromBottom` at −200 and threw the label
    // column 384pt off the left edge of the screen.
    //
    // `fabRect` is a real render object's real rect. The only honest frame to
    // express it in is the one this widget is actually given, which is what
    // `LayoutBuilder` reports and `MediaQuery` merely predicts.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // The FAB's centre, restated as insets from the bottom-right corner —
        // the frame every `Positioned` below is expressed in.
        final fabCentreFromRight = width - fabRect.center.dx;
        final fabCentreFromBottom = height - fabRect.center.dy;

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
                        screenWidth: width,
                        fromRight: fabCentreFromRight,
                        fromBottom: fabCentreFromBottom,
                      ),

                    // ── The FAB, wearing an × ──
                    //
                    // Drawn at the MEASURED rect, so it lands exactly on top of the
                    // real one: same place, same size, same corner radius. The
                    // Scaffold beneath this route cannot be told the menu is open,
                    // so the real button keeps painting its `+` underneath —
                    // completely covered, which is the point. To the user, the one
                    // control they pressed simply turned.
                    Positioned(
                      key: const ValueKey('journal-compose-close'),
                      left: fabRect.left,
                      top: fabRect.top,
                      width: fabRect.width,
                      height: fabRect.height,
                      child: Semantics(
                        button: true,
                        label: 'Close',
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(_fabCornerRadius),
                            ),
                            child: Center(
                              child: Transform.rotate(
                                // A + turned an eighth of a turn IS an ×. Rotating
                                // the same glyph rather than swapping icons is what
                                // makes the control read as continuous with the one
                                // that was pressed.
                                angle: t * math.pi / 4,
                                child: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 28),
                              ),
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
      },
    );
  }

  Widget _positioned(
    BuildContext context, {
    required int index,
    required double t,
    required double screenWidth,
    required double fromRight,
    required double fromBottom,
  }) {
    final action = options[index];
    final settled = riseFor(index);

    // Staggered so the stack unrolls rather than appearing whole. Under reduced
    // motion `t` arrives at 1 in a single frame, so this collapses to nothing
    // on its own — no branch needed.
    final delay = index * _staggerFraction;
    final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);

    // Rises straight out of the button. This is the only travel there is: no
    // horizontal component, so an option never appears to arrive from the side.
    final dy = settled * local;

    // Where every label ends, as an inset from the screen's right — the SAME
    // number for every row, because every circle shares the FAB's column.
    //
    // Two earlier shapes got here the hard way. Pinning each card to its own
    // circle on an arc left them ~80pt apart horizontally; padding them out to
    // a shared edge with a per-row shim fixed that and left the top card 120pt
    // from its own icon. A straight stack gives the shared edge for free AND
    // keeps every card [_labelGap] from the circle it names.
    final labelRight = fromRight + _optionDiameter / 2 + _labelGap;
    // TWO ceilings, and both are load-bearing.
    //
    // The first keeps the row on the phone: 12pt of air on the left, hard
    // rather than hoped for, because the label is the widest part of the row
    // and a row that overflows can neither be read nor tapped.
    //
    // The second keeps it from becoming a SLAB. At
    // "Free, as often as you like" the widest card was 175pt on a 390pt
    // screen, for a caption. The copy is shorter now; this is the guard that
    // stops the next long string undoing it, by ellipsising rather than
    // expanding.
    final labelMaxWidth = math.min(
      _labelMaxWidth,
      math.max(0.0, screenWidth - labelRight - 12),
    );

    return Positioned(
      // Every circle in the FAB's own column; only the height varies. The card
      // rides along beside it.
      right: fromRight - _optionDiameter / 2,
      bottom: fromBottom + dy - _optionDiameter / 2,
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
              // Keyed so a test can measure the row's REAL footprint. The
              // previous non-overlap test measured `find.text(label)` — the
              // Text widgets inside the cards — which stayed clear of each
              // other while the cards around them visibly fused into one white
              // blob on a real phone. Measure the thing that is drawn.
              key: ValueKey('journal-compose-row-${action.name}'),
              // Right-aligned and hugging: a full-width row would make every
              // option an invisible screen-wide slab, and the one higher on the
              // stack — painted later, therefore on top — would swallow taps
              // meant for the one beneath it.
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: labelMaxWidth),
                  child: _label(action),
                ),
                const SizedBox(width: _labelGap),
                _circle(action),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The label card.
  ///
  /// **The circles are the composition; the cards are an annotation.** That is
  /// the rule that keeps two facts per row from turning into clutter, so the
  /// card is trimmed to the smallest thing that can carry them — 13pt title,
  /// 11pt cost, 12/8 padding, ~50pt tall against an earlier 61 — and never
  /// competes with its circle for attention. A bigger card does not read as
  /// more informative; it reads as a menu that happens to have icons.
  Widget _label(JournalComposeAction action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        // Softer than `AppSpacing.cardRadius` (20) and closer to the circles
        // beside it — at 20 on a 50pt-tall card the corners read as a dialog.
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimaryLight.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        // **The two lines share a LEFT edge, not a right one.**
        //
        // They used to be right-aligned, on the theory that the card hangs off
        // the right of the screen so its text should hang with it. In practice
        // the title is the shorter string of the two ("New reflection" against
        // "Included with premium"), so right-alignment indented the title —
        // the eye read a ragged left edge inside a card only 168pt wide, which
        // at two lines is a visible defect rather than a subtlety.
        //
        // The card still hugs its widest line and still sits against its
        // circle, so nothing about the row's placement changes; only the
        // relationship of the two lines to each other does.
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            JournalComposeCopy.label(action),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 1),
          // The consequence, still stated before the tap — the whole reason the
          // chooser exists. A bare icon ring would have thrown it away.
          //
          // ONE line each, ellipsised, and at 11pt. Height here is not
          // cosmetic: options sit [_optionSpacing] apart, and every point this
          // card grows is a point of clearance spent. It was a 61pt card
          // against 51pt of separation once, and the two rows fused into a
          // single white blob on a real phone.
          Text(
            JournalComposeCopy.subtitle(action, allowance: allowance),
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              height: 1.25,
              color: AppColors.textSecondaryLight,
            ),
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
