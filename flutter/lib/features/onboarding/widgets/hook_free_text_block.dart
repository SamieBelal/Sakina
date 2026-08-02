import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The demoted free-text path on the hook screen (One Ship W2-B2, spec ⑤).
///
/// A quiet link under the cards. It never hides them, is never required, and
/// never competes for the primary position the shipped `first_checkin_screen`
/// gave it.
///
/// **It no longer expands in place** (founder, 2026-07-29). The field, its hint
/// and its submit all moved into `showFreeTextDialog` — see that function for
/// why. What is left here is one line, which is all this affordance ever needed
/// to be: everything about composing the answer now happens over a blurred
/// canvas with the keyboard already up.
///
/// The link is emerald because it is the only *action* on a screen whose six
/// options must stay quiet — without it there is no brand colour anywhere before
/// the first tap. `primary` on cream is 6.05:1; gold would be ~2.2:1 and is
/// barred from text (DESIGN.md §2.3).
class HookFreeTextBlock extends StatelessWidget {
  const HookFreeTextBlock({
    required this.onTap,
    required this.enabled,
    super.key,
  });

  /// **Was "Or say it in your own words…"** (founder, 2026-07-29). It sat
  /// directly beneath the row "I can't put it into words", and the shared word
  /// made two opposite affordances read as the same one. The row keeps its
  /// wording — the sign contract's reveal answers it directly ("You couldn't put
  /// it into words. The One this Name belongs to never needed them.", shipped in
  /// `assets/content/name_stories.json`) — so the echo is broken here instead.
  static const String promptLabel = 'Or describe it yourself…';

  /// Opens the modal. Named for what the user does, not for what it used to do
  /// to this widget's own layout.
  final VoidCallback onTap;

  /// False once a commit is in flight, so the beat cannot be interrupted.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: promptLabel,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              promptLabel,
              textAlign: TextAlign.center,
              // No underline (founder, 2026-07-29) — matches `ReelSkipLink`,
              // the same quiet register as every other reel screen. The weight
              // steps up from w300 to w400 now that it carries colour, so it
              // reads as a control rather than as a faded caption.
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
