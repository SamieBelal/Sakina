import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';

/// The wardrobe's live preview: the previewed (or equipped) backdrop composed
/// with the previewed (or equipped) lantern skin. Pure display — the screen
/// resolves which ids to show.
class WardrobePreviewStage extends StatelessWidget {
  const WardrobePreviewStage({
    super.key,
    required this.skinId,
    required this.backdropId,
    this.height = 220,
    this.medallionSize = 160,
  });

  final String skinId;
  final String backdropId;
  final double height;
  final double medallionSize;

  @override
  Widget build(BuildContext context) {
    // Framed as an inset card rather than a full-bleed band.
    //
    // Full-bleed, the stage paints the backdrop edge-to-edge and butts against
    // the page behind the grid. Those two surfaces are never the same colour —
    // the plain backdrop ends on #F3ECE1 against a #FBF7F2 page, and a night
    // backdrop ends on near-black — so the join reads as a torn screen rather
    // than a boundary. Matching the page colour would only fix the plain case.
    // Insetting it and rounding the corners makes the difference deliberate for
    // EVERY backdrop: it becomes a window you are looking through.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CompanionStage(
            backdrop: resolveBackdrop(backdropId),
            child: Center(
              child: CompanionMedallion(
                state: const CompanionState(
                    brightness: CompanionBrightness.glowing, protected: false),
                size: medallionSize,
                skin: resolveSkin(skinId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
