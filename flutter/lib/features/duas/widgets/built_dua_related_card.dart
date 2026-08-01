import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart'
    show SavedRelatedDua;
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/widgets/dua_text_block.dart';

/// A single Related Dua row on the Ameen screen, rendered as an **expandable
/// card**: the title + source are always visible; tapping the header expands
/// the full Arabic + transliteration + translation stack (via [DuaTextBlock]).
/// The section header above this card literally reads "Tap a dua to read it
/// in full" — which is why a **user-initiated expand** (collapsed → expanded)
/// is [AnalyticsEvents.duaRead]'s definition (W6 Wave D): there is no detail
/// route for a dua, so a screen mount can't mean "read", but this can.
///
/// The FIRST related dua is rendered [initiallyExpanded] by default — this is
/// load-bearing: the full onboarding tour anchors `firstRelatedHeart` on the
/// heart of the first card, which must stay visible at rest. The [heart] is
/// supplied by the caller (already anchor-wrapped for index 0) and pinned in
/// the always-visible header so the anchor never hides behind the collapse.
/// Because that first card starts expanded WITHOUT a tap, its initial state
/// must not itself count as a read — only a subsequent collapse→expand does.
class BuiltDuaRelatedCard extends ConsumerStatefulWidget {
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
  ConsumerState<BuiltDuaRelatedCard> createState() =>
      _BuiltDuaRelatedCardState();
}

class _BuiltDuaRelatedCardState extends ConsumerState<BuiltDuaRelatedCard> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggleExpanded() {
    final expanding = !_expanded;
    setState(() => _expanded = expanding);
    if (expanding) {
      final d = widget.dua;
      ref.read(analyticsProvider).track(AnalyticsEvents.duaRead, properties: {
        AnalyticsEvents.propDuaId: SavedRelatedDua.idFor(d.title, d.source),
        AnalyticsEvents.propSource: 'built_dua_related',
      });
    }
  }

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
                    onTap: _toggleExpanded,
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
                  onPressed: _toggleExpanded,
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
