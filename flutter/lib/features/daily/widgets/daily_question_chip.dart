import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/widgets/problem_chip_card.dart';

/// One quick-fill option under the daily question's text field (W4 Wave 2).
///
/// The onboarding hook screen's [ProblemChipCard] cannot be reused here: it is
/// built for a cream canvas (`textPrimaryLight` on `backgroundLight`, a
/// `borderLight` hairline) and every one of those colours is unreadable on the
/// emerald sacred canvas. The *taxonomy* is shared — [ProblemChip.label] is
/// verbatim from `problem_chips.dart`, never re-worded here — the treatment is
/// not.
///
/// **A quiet row, not an outlined pill** (density pass, founder 2026-07-30).
/// These were seven full-width bordered pills, which put seven more outlined
/// containers on a screen that already had a field and a button — and on device
/// the result read as a survey rather than a question. Stripping the borders
/// removed more perceived weight than any other single change, because the
/// chrome was most of the noise; the labels themselves were never the problem
/// and are unchanged.
///
/// **The labels stay full sentences.** Shortening them to nouns ("Racing mind",
/// "Unseen") was mocked and rejected: these are the ICP's own words, and being
/// recognised in your own language is the entire job of the option set. A
/// compressed label turns recognition into a taxonomy.
///
/// The gold dot is the only affordance, and it is deliberate — gold as a
/// non-text accent is sanctioned on this canvas (DESIGN.md §2.3), and it marks
/// these as choices rather than a bulleted list without reinstating a border.
///
/// **The label is `bodyLarge`, matching [ProblemChipCard]** (founder,
/// 2026-07-31). Stripping the borders was right; shrinking the words with them
/// was not. The same seven sentences render at 17pt in onboarding, and at 15pt
/// here they read as a caption of the option rather than as the option — which
/// is half of why the screen had no presence. The taxonomy was already shared;
/// now the type is too.
class DailyQuestionChip extends StatelessWidget {
  const DailyQuestionChip({
    required this.chip,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  /// Apple's floor, and the reason this is a `constraints.minHeight` rather
  /// than a fixed height: the row grows with Dynamic Type instead of clipping.
  ///
  /// It survived the density pass untouched. Removing a border does not license
  /// removing a tap target — the row is the same size to a finger and quieter
  /// only to the eye.
  static const double minTapHeight = 44;

  /// The marker's diameter. Small enough to read as punctuation rather than as
  /// a bullet, large enough to be visible at 45% opacity on the sign row.
  static const double _dotSize = 5;

  final ProblemChip chip;

  /// This chip owns the commit in flight.
  final bool selected;

  /// Another chip owns it — recede so the chosen line reads alone.
  final bool dimmed;

  /// Short screens keep the tighter row. At the roomy padding seven 54pt rows
  /// cost 70pt more than seven 44pt ones, which on a 568pt screen is the
  /// difference between the seventh option — "I can't put it into words" —
  /// sitting above the fold or below it. The onboarding twin guards the same
  /// row for the same reason (`hook_problem_screen.dart`).
  final bool compact;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The sign chip ("I can't put it into words") is distinguished by
    // TYPOGRAPHY ONLY — lighter weight and softer ink, never a different
    // surface or spacing. A tinted row would read as pre-selected, and
    // inconsistent spacing reads as a layout bug; that ruling comes from the
    // onboarding hook screen (plan §W2.6) and holds here for the same reason.
    // Someone who genuinely cannot name what they are carrying must not feel
    // they are picking the odd one out.
    final isSign = chip.isSign;

    return Semantics(
      button: true,
      selected: selected,
      label: chip.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: AppMotion.recede,
          curve: AppMotion.enter,
          opacity: dimmed ? ProblemChipCard.unselectedFade : 1,
          child: AnimatedContainer(
            duration: AppMotion.feedback,
            curve: AppMotion.enter,
            constraints: const BoxConstraints(minHeight: minTapHeight),
            padding: EdgeInsets.symmetric(
              vertical: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              // Selection is a wash rather than an outline, so committing does
              // not reintroduce the chrome the pass removed.
              color: selected
                  ? AppColors.sacredInk.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              // A hairline between rows, not around them: it separates without
              // enclosing. 8% cream is under the threshold where it reads as a
              // border in its own right.
              border: Border(
                bottom: BorderSide(
                  color: AppColors.sacredInk.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary
                        .withValues(alpha: isSign ? 0.40 : 0.75),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    chip.label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isSign
                          ? AppColors.sacredInk.withValues(alpha: 0.70)
                          : AppColors.sacredInk,
                      fontWeight: isSign ? FontWeight.w300 : null,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
