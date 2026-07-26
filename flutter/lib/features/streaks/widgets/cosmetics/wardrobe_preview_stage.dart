import 'package:flutter/material.dart';

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
    return SizedBox(
      height: height,
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
    );
  }
}
