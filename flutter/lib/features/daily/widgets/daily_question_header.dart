import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';

/// The daily question's title.
///
/// Marked `header: true` so VoiceOver announces the question first and a rotor
/// jump lands on it. Latin script throughout, so no `Text` here mixes
/// directions.
///
/// **The taught gloss is owned by the parent.** `DailyQuestionPrompt` renders
/// the approved definition for day-open and widget entry, where a user may not
/// have seen the Home CTA's explanation. It omits the gloss after that CTA and
/// on re-ask, avoiding duplicate copy on consecutive screens. Keeping the
/// definition outside this header also preserves one clean heading semantic
/// for VoiceOver. The word remains explanatory copy, never a button label.
///
/// **Sized to match its twin, not to the smallest headline in the scale**
/// (founder, 2026-07-31). This rendered `headlineMedium` — 20pt, the bottom of
/// the headline range and 14pt under the "all main screen titles use
/// displayLarge" note in `app_typography.dart`. The onboarding hook screen asks
/// the *same question* over the *same seven options* at `displayMedium` (28pt),
/// dropping to `displaySmall` (24pt) below 700pt of screen. So the daily
/// question was a smaller-typed copy of a screen whose metrics were already
/// tuned on device — which is exactly what "the heading looks very small" was
/// reporting. Every value below is `hook_screen_header.dart`'s, deliberately
/// verbatim; the parity is pinned by `daily_question_type_parity_test.dart`.
class DailyQuestionHeader extends StatelessWidget {
  const DailyQuestionHeader({
    required this.title,
    this.compact = false,
    super.key,
  });

  final String title;

  /// Short screens (SE and friends) take the smaller step. Supplied by the
  /// host so one breakpoint governs the whole screen's rhythm rather than each
  /// widget reading `MediaQuery` and drifting apart.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style:
            (compact ? AppTypography.displaySmall : AppTypography.displayMedium)
                .copyWith(
          color: AppColors.sacredInk,
          fontWeight: FontWeight.w600,
          height: 1.22,
          letterSpacing: -0.6,
        ),
      ),
    );
  }
}
