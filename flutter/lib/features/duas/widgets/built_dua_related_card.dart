import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/widgets/dua_text_block.dart';

/// A single Related Dua row on the Ameen screen, rendered as an **expandable
/// card**: the title + source are always visible; tapping the header expands
/// the full Arabic + transliteration + translation stack (via [DuaTextBlock]).
///
/// The FIRST related dua is rendered [initiallyExpanded] by default — this is
/// load-bearing: the full onboarding tour anchors `firstRelatedHeart` on the
/// heart of the first card, which must stay visible at rest. The [heart] is
/// supplied by the caller (already anchor-wrapped for index 0) and pinned in
/// the always-visible header so the anchor never hides behind the collapse.
class BuiltDuaRelatedCard extends StatefulWidget {
  const BuiltDuaRelatedCard({
    super.key,
    required this.dua,
    required this.heart,
    this.initiallyExpanded = false,
  });

  final FindDuasDuaEntry dua;
  final Widget heart;
  final bool initiallyExpanded;

  @override
  State<BuiltDuaRelatedCard> createState() => _BuiltDuaRelatedCardState();
}

class _BuiltDuaRelatedCardState extends State<BuiltDuaRelatedCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final d = widget.dua;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: const Border(
          left: BorderSide(color: AppColors.secondary, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — title + source (always visible) with the heart pinned
            // (its anchor must stay renderable) and an expand chevron.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.heart,
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (d.source.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            d.source,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondaryLight,
                    size: 22,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: DuaTextBlock(
                  arabic: d.arabic,
                  transliteration: d.transliteration,
                  translation: d.translation,
                  // Source already shown in the header — omit from the block.
                  source: '',
                ),
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
