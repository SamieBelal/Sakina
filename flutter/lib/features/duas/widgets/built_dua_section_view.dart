import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/duas/widgets/built_dua_section_controls.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';

/// The Build-a-Dua section (Praise → Salawat → Ask → Close) step viewer, moved
/// onto the emerald **sacred canvas** (decision 11A). One section per screen:
/// a gold eyebrow label, the Arabic, transliteration and translation fade in
/// sequentially (staggered reveal, all end visible together), above a
/// segmented gold-on-`sacredTrack` progress bar and the Next / Ameen CTA.
///
/// The RTL rule is owned inline here per the existing hand-rolled stack (the
/// three parts have per-part `textDirection`); Arabic and Latin never share a
/// `Text`.
///
/// Tour: the `duaSectionNext` anchor wraps the Next button and is rendered at
/// rest with only a short fade — never gated behind a conditional or a long
/// animation — so the full-tour anchor-settle gate (~400ms) always finds it.
class BuiltDuaSectionView extends StatelessWidget {
  const BuiltDuaSectionView({
    super.key,
    required this.state,
    required this.notifier,
  });

  final DuasState state;
  final DuasNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final breakdown = state.buildResult!.breakdown;
    if (breakdown.isEmpty) {
      return DuaEmptyBreakdown(onRetry: notifier.resetBuild);
    }

    final currentStep = state.buildCurrentSection.clamp(0, breakdown.length - 1);
    final section = breakdown[currentStep];
    final isLast = state.buildCurrentSection >= breakdown.length - 1;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: KeyedSubtree(
                key: ValueKey(currentStep),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePadding,
                          AppSpacing.lg,
                          AppSpacing.pagePadding,
                          AppSpacing.pagePadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight -
                                AppSpacing.lg -
                                AppSpacing.pagePadding,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(),
                                // Gold eyebrow — chapter-heading label. Non-text
                                // gold is fine; this is the accent, but the copy
                                // is short and the canvas rule reserves gold for
                                // accents — so keep the label in sacredInk-soft
                                // for contrast and let the rule below carry gold.
                                Text(
                                  section.label.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.sacredInkSoft,
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(duration: 300.ms),
                                const SizedBox(height: AppSpacing.sm),
                                // Hairline gold rule under the eyebrow.
                                Container(
                                  width: 28,
                                  height: 1,
                                  color: AppColors.secondary,
                                ).animate().scaleX(
                                      begin: 0,
                                      end: 1,
                                      duration: 300.ms,
                                      delay: 80.ms,
                                      curve: Curves.easeOut,
                                    ),
                                const SizedBox(height: AppSpacing.lg),
                                // Arabic — the visual anchor.
                                Text(
                                  section.arabic,
                                  style: AppTypography.quranArabic.copyWith(
                                    color: AppColors.sacredInk,
                                    height: 1.9,
                                  ),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(
                                    duration: 400.ms, delay: 140.ms),
                                const SizedBox(height: AppSpacing.lg),
                                // Transliteration — italic, muted cream.
                                Text(
                                  section.transliteration,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.sacredInkSoft,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(
                                    duration: 300.ms, delay: 240.ms),
                                const SizedBox(height: AppSpacing.md),
                                // Verse-stop ornament — gold dot.
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.secondary,
                                  ),
                                ).animate().fadeIn(
                                    duration: 300.ms, delay: 300.ms),
                                const SizedBox(height: AppSpacing.md),
                                // Translation — cream, generous height.
                                Text(
                                  section.translation,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.sacredInk,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(
                                    duration: 300.ms, delay: 340.ms),
                                const SizedBox(height: AppSpacing.xl),
                                // Segmented progress bar — gold fill on
                                // sacredTrack, one segment per section.
                                DuaSegmentedProgress(
                                  count: breakdown.length,
                                  current: currentStep,
                                ).animate().fadeIn(
                                    duration: 300.ms, delay: 380.ms),
                                const SizedBox(height: AppSpacing.lg),
                                // Next / Ameen CTA. The Next path stays wrapped
                                // in the `duaSectionNext` anchor with only a
                                // short fade so the tour settle gate finds it.
                                // The CTA fades in fast (settles well under the
                                // tour's ~400ms anchor-settle gate) — the anchor
                                // is laid out from frame 1 regardless, but the
                                // short fade keeps the highlight from landing on
                                // a half-faded control.
                                if (isLast)
                                  DuaAmeenCta(
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      notifier.nextBuildSection();
                                    },
                                  ).animate().fadeIn(
                                      duration: 200.ms, delay: 120.ms)
                                else
                                  TourAnchor(
                                    surface: TourSurface.duas,
                                    anchorId: 'duaSectionNext',
                                    child: DuaNextButton(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        notifier.nextBuildSection();
                                      },
                                    ),
                                  ).animate().fadeIn(
                                      duration: 200.ms, delay: 120.ms),
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (currentStep > 0)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.previousBuildSection();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sacredTrack,
                      border: Border.all(color: AppColors.sacredInkFaint),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.sacredInk,
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
              ),
          ],
        ),
      ),
    );
  }
}
