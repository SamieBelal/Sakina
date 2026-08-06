import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/journal/journal_resurfacing.dart';

/// E2 in the Journal — the recap as a **door**, not a block.
///
/// [WeeklyRecapCard] still exists and is still right where it is: the muḥāsabah
/// completion screen is already a reflective moment, the card there is the
/// night's own closing card, and sending someone out to a second story mid-
/// completion would break the night. In the ARCHIVE the same card cost ~19% of
/// the viewport and pushed the first entry to ~57% down the screen — a summary
/// of the journal standing in front of the journal.
///
/// **It leads with the user's own words.** The quote is what earns a tap;
/// *"your last seven nights"* is a filing category, and a line that leads with
/// the category is a header. So the row reads as one sentence the user half
/// wrote:
///
/// > `✦  "I can't sleep because I keep worrying…" — your last seven nights  ›`
///
/// Same sand, same border, same 12px radius as the lifetime insight container it
/// shares a slot with — swapping one for the other must not read as the layout
/// changing under the user. Nothing new is introduced: the emerald on the trail
/// and the chevron is [AppColors.primary], exactly the colour every other inline
/// text control in the archive uses to say *this is a control*.
///
/// Contrast, measured against the `#F5EBD9` sand: the quote at
/// [AppColors.textPrimaryLight] is 14.4:1, the trail at [AppColors.primary] is
/// 5.5:1 — both clear AA for body text. (`textSecondaryLight`, which the block
/// card uses for its secondary lines, is 4.1:1 and would not have.)
class WeeklyRecapLine extends StatelessWidget {
  const WeeklyRecapLine({
    required this.recap,
    required this.onOpen,
    super.key,
  });

  final WeeklyRecap recap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // `oneLine` is documented as possibly empty — a week where nobody wrote a
    // line worth handing back. Then the category IS the line, capitalised so it
    // reads as a sentence rather than the tail of one.
    final quote = recap.oneLine.trim();

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          // ~44 tall: a full tap target, and a fifth of what the block cost.
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBD9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.secondary, size: 16),
              const SizedBox(width: 10),
              if (quote.isNotEmpty) ...[
                // Flexible, and it is the only flexible child: the quote is what
                // gives way on a narrow screen, because a truncated quote still
                // reads as a quote while a truncated "…seven nig" does not.
                // One line — the block's three-line quote is what the story is
                // for now.
                Flexible(
                  child: Text(
                    '“$quote”',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                quote.isEmpty
                    ? JournalResurfacingCopy.recapHeader
                    : JournalResurfacingCopy.recapLineTrail,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
