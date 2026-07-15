import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/duas/widgets/ameen_medallion.dart';
import 'package:sakina/features/duas/widgets/built_dua_related_card.dart';
import 'package:sakina/features/duas/widgets/related_dua_heart.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';
import 'package:sakina/widgets/share_card.dart';

/// The Build-a-Dua result / Ameen screen, moved onto the emerald **sacred
/// canvas** (decision 11A) so both dua rituals share one visual language.
///
/// Behaviour preserved from the old inline `_buildAmeenScreen`:
///  - auto-save-once on first render (guarded by [saveHandled] so a capped
///    free-user save can't loop), delegated to [onFirstRender];
///  - the `duaBuildComplete` tour anchor on Build-Another (end-of-flow step);
///  - the `firstRelatedHeart` tour anchor on the first related dua's heart —
///    the first related card renders **expanded by default** so that anchor
///    stays visible at rest;
///  - share, related-dua save toggles + quest hook, snackbars.
class BuiltDuaAmeenScreen extends StatelessWidget {
  const BuiltDuaAmeenScreen({
    super.key,
    required this.state,
    required this.notifier,
    required this.saveHandled,
    required this.onFirstRender,
    required this.onRelatedDuaSaved,
    required this.onBuildAnother,
  });

  final DuasState state;
  final DuasNotifier notifier;

  /// Whether the auto-save attempt for the current result was already handled
  /// (mirror of `state.buildResultSaveHandled && notifier.isBuiltDuaSaved()`
  /// resolved by the screen so this widget stays provider-agnostic).
  final bool saveHandled;

  /// Runs the auto-save + quest + achievement side effects once, post-frame.
  final VoidCallback onFirstRender;

  /// Fired after a related dua is newly saved (never on un-save) so the caller
  /// can advance the save quest.
  final VoidCallback onRelatedDuaSaved;

  /// Clears the input and resets the build (Build Another Dua).
  final VoidCallback onBuildAnother;

  @override
  Widget build(BuildContext context) {
    final result = state.buildResult!;

    if (!saveHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onFirstRender());
    }

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.sacredCanvasGradient),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                _ShareButton(state: state, result: result),
                const SizedBox(height: AppSpacing.lg),
                const AmeenMedallion(),
                const SizedBox(height: AppSpacing.xl),
                _buildAnotherCta(),
                const SizedBox(height: AppSpacing.xl),
                _namesCalledUpon(result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 600.ms),
                const SizedBox(height: AppSpacing.md),
                _relatedDuas(context, result)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAnotherCta() {
    return TourAnchor(
      surface: TourSurface.duas,
      anchorId: 'duaBuildComplete',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onBuildAnother();
        },
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.sacredInk,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Build Another Dua',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
      ),
    );
  }

  Widget _namesCalledUpon(BuiltDuaResponse result) {
    return AmeenSectionCard(
      title: 'Names Called Upon',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...result.namesUsed.map<Widget>((n) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          n.name,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.sacredInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          n.nameArabic,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.secondary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.why,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.sacredInkSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _relatedDuas(BuildContext context, BuiltDuaResponse result) {
    return AmeenSectionCard(
      title: 'Related Duas',
      subtitle: 'Tap a dua to read it in full',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...result.relatedDuas.asMap().entries.map<Widget>((entry) {
            final i = entry.key;
            final d = entry.value;
            final isSaved = state.savedRelatedDuas
                .any((s) => s.id == SavedRelatedDua.idFor(d.title, d.source));
            void onHeartTap() {
              HapticFeedback.mediumImpact();
              notifier.toggleSaveRelatedDua(d);
              if (!isSaved) onRelatedDuaSaved();
              showRelatedDuaSnack(context, saved: !isSaved);
            }

            final heart = RelatedDuaHeart(isSaved: isSaved, onTap: onHeartTap);
            final anchoredHeart = i == 0
                ? TourAnchor(
                    surface: TourSurface.duas,
                    anchorId: 'firstRelatedHeart',
                    child: heart,
                  )
                : heart;
            return BuiltDuaRelatedCard(
              // The first card is expanded by default so `firstRelatedHeart`
              // (and the full text) is visible at rest for the tour.
              initiallyExpanded: i == 0,
              dua: d,
              heart: anchoredHeart,
            );
          }),
        ],
      ),
    );
  }
}

/// Share affordance — top-right, cream (functional chrome ≥80% ink on canvas).
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.state, required this.result});

  final DuasState state;
  final BuiltDuaResponse result;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Builder(
        builder: (btnContext) => GestureDetector(
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            HapticFeedback.mediumImpact();
            final box = btnContext.findRenderObject() as RenderBox;
            final origin = box.localToGlobal(Offset.zero) & box.size;
            try {
              await shareBuiltDuaCard(
                context: context,
                need: state.buildNeed,
                sections: duaSectionsForShare(result.breakdown),
                translation: result.translation,
                sharePositionOrigin: origin,
              );
            } catch (e) {
              debugPrint('[SHARE ERROR] $e');
              showShareErrorSnackBar(messenger);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sacredTrack,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.share_outlined,
                color: AppColors.sacredInk, size: 20),
          ),
        ),
      ),
    );
  }
}
