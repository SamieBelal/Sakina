import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/wardrobe_tile.dart';

/// The 2-up grid of one wardrobe axis. Pure display: statuses and names are
/// resolved by the screen and passed in, so the grid makes no service calls.
class WardrobeGrid extends StatelessWidget {
  const WardrobeGrid({
    super.key,
    required this.entries,
    required this.statusFor,
    required this.nameFor,
    required this.previewedId,
    required this.onPreview,
  });

  final List<CosmeticCatalogEntry> entries;
  final WardrobeTileStatus Function(CosmeticCatalogEntry) statusFor;
  final String Function(CosmeticCatalogEntry) nameFor;
  final String? previewedId;
  final void Function(CosmeticCatalogEntry) onPreview;

  @override
  Widget build(BuildContext context) {
    // The grid scrolls between a pinned preview card and a pinned action bar,
    // so at both edges a tile is inevitably mid-slice. That slice is loud here
    // because a tile is near-white (#FBF7F2) on a beige page (#F3ECE1): a
    // dead-straight, high-contrast line reads as a torn screen rather than as
    // "there is more content".
    //
    // `dstIn` multiplies only the child's ALPHA, so tiles keep their own
    // colours and simply dissolve into whatever page colour is behind them.
    //
    // The stops are computed in PIXELS, not as fractions of the viewport: a
    // percentage fade is invisible on a tall phone and swallows a whole tile on
    // a short one. The top fade is the longer of the two because that edge
    // borders the preview card, where the eye is already resting.
    return LayoutBuilder(
      builder: (context, constraints) {
        const topFade = 56.0;
        const bottomFade = 40.0;
        final h = constraints.maxHeight;
        // clamp() guards a degenerate/unbounded height (fade stops must stay
        // ordered and inside 0..1, or the shader throws).
        final top = h <= 0 ? 0.0 : (topFade / h).clamp(0.0, 0.35);
        final bottom = h <= 0 ? 1.0 : 1.0 - (bottomFade / h).clamp(0.0, 0.35);
        return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const <Color>[
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            stops: <double>[0.0, top, bottom, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: GridView.count(
            crossAxisCount: 2,
            // Extra bottom room so the final row clears the pinned action bar
            // instead of hiding behind it (52pt button + its padding + breathing
            // space), and a little top room so row one starts clear of the fade.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md + 96,
            ),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.82,
            children: [
              for (final e in entries)
                WardrobeTile(
                  itemType: e.itemType,
                  itemId: e.itemId,
                  name: nameFor(e),
                  status: statusFor(e),
                  selected: e.itemId == previewedId,
                  onTap: () => onPreview(e),
                ),
            ],
          ),
        );
      },
    );
  }
}
