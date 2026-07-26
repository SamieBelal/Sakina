import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/backdrop_stage.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'package:sakina/features/streaks/widgets/cosmetics/lantern_share_preview.dart';

/// E1 — the share-worthy composed lantern: equipped backdrop + equipped skin +
/// the lantern's name + the streak, on the sacred canvas.
///
/// [preview] renders the on-screen size; the export renders the same tree at
/// 3× so one widget defines both frames. The stage and medallion are frozen
/// (`animate: false`) so the exported frame is deterministic.
class LanternShareCard extends StatelessWidget {
  const LanternShareCard({
    super.key,
    required this.skinId,
    required this.backdropId,
    required this.lanternName,
    required this.streak,
    this.preview = false,
  });

  final String skinId;
  final String backdropId;
  final String lanternName;
  final int streak;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final double scale = preview ? 1 : 3;
    final double medallion = 200 * scale;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 360 * scale,
        height: 480 * scale,
        child: CompanionStage(
          backdrop: resolveBackdrop(backdropId),
          animate: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: medallion,
                  height: medallion,
                  child: CompanionMedallion(
                    state: const CompanionState(
                        brightness: CompanionBrightness.fullyLit,
                        protected: false),
                    size: medallion,
                    animate: false,
                    skin: resolveSkin(skinId),
                  ),
                ),
                SizedBox(height: AppSpacing.lg * scale),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.lg * scale),
                  child: Text(
                    lanternName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.sacredInk,
                      fontSize: 28 * scale,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xs * scale),
                Text(
                  _streakLine,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.sacredInkSoft,
                    fontSize: 14 * scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // One whole sentence per string so it stays extractable for translation.
  String get _streakLine => streak == 1
      ? 'Lit for 1 day on Sakina'
      : 'Lit for $streak days on Sakina';
}

/// Signature of [shareLanternCard]. Exposed so callers (and tests) can swap in
/// a fake instead of driving a real Navigator + platform share sheet.
typedef ShareLanternFn = Future<void> Function({
  required BuildContext context,
  required String skinId,
  required String backdropId,
  required String lanternName,
  int streak,
});

/// Opens the share preview for the composed lantern. Overridable for tests.
ShareLanternFn shareLanternCard = defaultShareLanternCard;

Future<void> defaultShareLanternCard({
  required BuildContext context,
  required String skinId,
  required String backdropId,
  required String lanternName,
  int streak = 0,
}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => LanternSharePreview(
      skinId: skinId,
      backdropId: backdropId,
      lanternName: lanternName,
      streak: streak,
    ),
  ));
}
