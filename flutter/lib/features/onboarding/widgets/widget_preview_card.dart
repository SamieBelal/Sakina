import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../content/onboarding_widgets.dart';

/// One card in the onboarding widget carousel (Wave G, spec §7).
///
/// **These are real screenshots** (founder, 2026-07-29). They were previously
/// re-drawn Flutter impressions — honest about not claiming pixel fidelity, but
/// they did not look like widgets on a Home Screen, which is the one thing this
/// screen has to sell. Each asset is a medium widget captured on a device and
/// cropped to the card plus ~8pt of wallpaper.
///
/// **Apple permits exactly this and no more.** Its Marketing Resources
/// guidelines allow showing your own widget on the Home Screen "as long as no
/// third-party content is depicted" — so the crop deliberately excludes the
/// status bar, the dock and the "Sakina" caption iOS draws under the widget.
/// Re-crop, do not re-frame, if these are ever regenerated.
///
/// **They can go stale silently.** A widget redesign will not fail any test
/// here; the screenshot simply keeps showing the old one. Regeneration recipe is
/// in `docs/qa/widget-preview-screenshots.md`. The `REGEN_WIDGET_FRAMES`
/// generator is the precedent for making this automatic if it becomes a problem.
class WidgetPreviewCard extends StatelessWidget {
  const WidgetPreviewCard({
    required this.option,
    this.active = true,
    super.key,
  });

  final OnboardingWidgetOption option;

  /// The centered card. Off-center cards recede slightly so the focused one
  /// reads as the subject — opacity only, no scale, so nothing is moving
  /// underneath a swipe.
  final bool active;

  /// Native crop is 1094x524 @3x. Pinned as a constant because all three assets
  /// are cropped by the same script to the same box — if one ever differs, the
  /// carousel would jump height between pages.
  static const double previewAspectRatio = 1094 / 524;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${option.galleryName}. ${option.line}',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppMotion.recede,
        curve: AppMotion.enter,
        opacity: active ? 1 : 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: Image.asset(
                    option.previewAsset,
                    fit: BoxFit.contain,
                    // The screenshot IS the artwork — no fill or border behind
                    // it. Its own wallpaper margin is the frame.
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              option.galleryName,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.line,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
