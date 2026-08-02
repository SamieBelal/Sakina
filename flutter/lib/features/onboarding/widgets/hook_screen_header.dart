import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The hook screen's header (One Ship W2-B2, revised 2026-07-27 after the
/// founder's first simulator pass).
///
/// **What changed and why.** The first build put a basmala ornament directly
/// above a bold question, then seven bordered cards — the founder read the
/// result as cramped and overwhelming, and the onboarding research agrees:
/// every well-regarded app in this category (Duolingo, Daylio, Balance, Finch)
/// opens light, and Noom is specifically criticised for asking something
/// personal before it has earned it. Sakina cannot delay its question — the
/// reel promised it — so the screen instead has to *earn* the question in the
/// same breath it asks it. Three moves:
///
/// 1. **The ornament is gone.** It was decoration in a place that needed air,
///    and the app's sacred register is carried by real content (the Names,
///    the verses) rather than a glyph stamped on a form.
/// 2. **The question is the hero** — larger, with room above it, and it lands
///    on screen alone for a beat before any option exists (the caller's
///    stagger delay does that half).
/// 3. **A promise line answers "why are you asking me this?"** before the
///    choices arrive. That single sentence is what turns an intake form into
///    an invitation, and it is the only thing on this screen that tells a
///    first-time user what happens after they tap.
class HookScreenHeader extends StatelessWidget {
  const HookScreenHeader({
    required this.title,
    required this.promise,
    this.compact = false,
    this.onBack,
    super.key,
  });

  final String title;

  /// The one line that says what the app will do with the answer.
  final String promise;

  /// Short screens step the question down a size so the seventh option — the
  /// escape hatch — still clears the fold.
  final bool compact;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    // Reduce motion = drop the travel, keep the fade. Removing the transition
    // entirely would lose the continuity cue the motion was carrying; the
    // vestibular risk is in the movement, not the opacity.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),
        Semantics(
          header: true,
          child: Text(
            title,
            style: (compact
                    ? AppTypography.displaySmall
                    : AppTypography.displayMedium)
                .copyWith(
              fontWeight: FontWeight.w600,
              height: 1.22,
              letterSpacing: -0.6,
              color: AppColors.textPrimaryLight,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: AppMotion.entrance, curve: AppMotion.enter)
            .moveY(
              begin: reduceMotion ? 0 : AppMotion.riseLarge,
              end: 0,
              duration: AppMotion.entrance,
              curve: AppMotion.enter,
            ),
        SizedBox(height: compact ? AppSpacing.xs + 2 : AppSpacing.sm + 2),
        // Emerald, not grey (founder, 2026-07-29). This is the only line on the
        // screen that can carry the brand before a tap: the six options have to
        // stay quiet or the list reads as a form, and the ink ramp everywhere
        // else on this screen is a cool grey that fights the warm cream. One
        // emerald sentence is what stops the page reading as black-on-white.
        //
        // #1B6B4A on #FBF7F2 is 6.05:1 — comfortably AA at this size, and this
        // is `primary`, NOT `secondary`: gold on cream is ~2.2:1 and is barred
        // from text outright (DESIGN.md §2.3).
        Text(
          promise,
          style: AppTypography.bodyMedium.copyWith(
            // A half-step heavier than the grey it replaces, so the colour
            // reads as deliberate rather than as washed-out body copy.
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: AppColors.primary,
          ),
        )
            .animate(delay: AppMotion.beat)
            .fadeIn(duration: AppMotion.layer, curve: AppMotion.enter)
            .moveY(
              begin: reduceMotion ? 0 : AppMotion.riseMedium,
              end: 0,
              duration: AppMotion.layer,
              curve: AppMotion.enter,
            ),
      ],
    );
  }
}
