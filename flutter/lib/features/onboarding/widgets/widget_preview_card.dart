import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../streaks/models/companion_state.dart';
import '../../streaks/providers/cosmetics_ui_providers.dart';
import '../../streaks/widgets/companion_medallion.dart';
import '../content/onboarding_widgets.dart';

/// One card in the onboarding widget carousel (Wave G, spec §7).
///
/// **These are diagrams, not screenshots.** Only the lantern card is rendered
/// from the real source — it uses the live [CompanionMedallion], the same
/// painter that generates the widget's `companion_*.png` frames, so it cannot
/// drift and it follows the equipped skin for free. The other two are
/// simplified impressions built from the real palette and type; they say what
/// the widget is *for* rather than claiming pixel fidelity, which is the honest
/// thing to show given they will evolve independently. If they ever start
/// looking like promises, replace them with generated frames the way the
/// companion ones are (`REGEN_WIDGET_FRAMES` precedent).
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
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.6),
                    ),
                  ),
                  child: _preview(),
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

  Widget _preview() {
    switch (option.kind) {
      case 'lantern':
        // The real thing: same painter as the shipped widget frames.
        // ambient:false — this card is a light surface.
        return Center(
          child: Consumer(
            builder: (_, ref, __) => CompanionMedallion(
              state: const CompanionState(
                brightness: CompanionBrightness.endowedDim,
                protected: false,
              ),
              size: 104,
              ambient: false,
              skin: ref.watch(renderableLanternSkinProvider),
            ),
          ),
        );
      case 'daily_name':
        return const _NamePreview();
      case 'dua_times':
      default:
        return const _DuaTimesPreview();
    }
  }
}

/// An impression of the daily-Name widget. Arabic and Latin are in separate
/// `Text` widgets with explicit directions — never one mixed string.
class _NamePreview extends StatelessWidget {
  const _NamePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY',
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 1.4,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'ٱلرَّحْمَٰن',
          textDirection: TextDirection.rtl,
          style: AppTypography.arabicClassical.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ar-Rahman',
          textDirection: TextDirection.ltr,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'The Most Merciful',
          textDirection: TextDirection.ltr,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// An impression of the duʿā-times widget — the next window and its countdown.
class _DuaTimesPreview extends StatelessWidget {
  const _DuaTimesPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: AppColors.secondary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 4),
            Text(
              'NEXT WINDOW',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Last third',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'in 3h 12m',
          style: AppTypography.bodyMedium.copyWith(
            // goldInk, never `secondary`: bright gold is ~2.2:1 on a light
            // surface and fails WCAG 4.5:1 for text (DESIGN.md 2.3). The icon
            // above may stay `secondary` — the rule is about text.
            color: AppColors.goldInk,
          ),
        ),
      ],
    );
  }
}
