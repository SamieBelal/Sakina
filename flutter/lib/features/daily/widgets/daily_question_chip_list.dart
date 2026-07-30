import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_motion.dart';
import 'package:sakina/features/daily/widgets/daily_question_chip.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';

/// The seven approved [problemChips], demoted beneath the daily question's text
/// field as quick-fill (spec M2).
///
/// **The taxonomy is shared, not forked.** Labels come straight from
/// `problem_chips.dart` in its approved order, so a tap here segments
/// identically to the same tap in onboarding — which is the whole reason
/// `problem_category` stays comparable across the two surfaces.
/// **No lead label** (density pass, founder 2026-07-30). This list used to be
/// introduced by "Or start from one of these". Once the rows stopped being
/// outlined pills and became a quiet list, the label was doing nothing the
/// layout did not already say — and it was one of five prose blocks on a screen
/// whose complaint was that it asked for too much reading before it asked its
/// question. The "or, never instead" framing it carried now lives in the
/// arrangement: the field is first and the rows sit under it.
class DailyQuestionChipList extends StatelessWidget {
  const DailyQuestionChipList({
    required this.selectedChipKey,
    required this.onChipTapped,
    super.key,
  });

  /// The chip whose commit is in flight; every other chip recedes.
  final String? selectedChipKey;

  final ValueChanged<ProblemChip> onChipTapped;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final anySelected = selectedChipKey != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Staggered so the rows arrive while the field above is still
        // settling rather than queuing behind it (`app_motion.dart` — layers
        // overlap). 40ms × 7 keeps the tail inside the ~900ms budget.
        for (var i = 0; i < problemChips.length; i++)
          Padding(
            // No gap: the rows are separated by their own hairline now, and a
            // margin between them would reintroduce the list-of-cards rhythm
            // the pass removed.
            padding: EdgeInsets.zero,
            child: DailyQuestionChip(
              chip: problemChips[i],
              selected: selectedChipKey == problemChips[i].chipKey,
              dimmed:
                  anySelected && selectedChipKey != problemChips[i].chipKey,
              onTap: () => onChipTapped(problemChips[i]),
            )
                .animate(
                    delay: AppMotion.listStart + AppMotion.stagger * (i + 1))
                .fadeIn(duration: AppMotion.item, curve: AppMotion.enter)
                .moveY(
                  begin: reduceMotion ? 0 : AppMotion.riseSmall,
                  end: 0,
                  duration: AppMotion.item,
                  curve: AppMotion.enter,
                ),
          ),
      ],
    );
  }
}
