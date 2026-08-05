import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/duas/widgets/ameen_medallion.dart';
import 'package:sakina/features/duas/widgets/built_dua_related_card.dart';
import 'package:sakina/features/duas/widgets/related_dua_heart.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/analytics_provider.dart';
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
                const SizedBox(height: AppSpacing.md),
                _GiftCta(state: state, result: result)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 550.ms),
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

/// The labeled gift CTA, sitting directly under "Build Another Dua".
///
/// The corner icon alone was effectively invisible: an unlabeled glyph in the
/// slot users read as "share/settings", losing every scan to the large centred
/// pill. A gift box does not self-evidently mean "send this duʿā to someone",
/// so the action is spelled out in words and placed in the primary scan path,
/// at the emotional peak right after "May Allah accept your duʿā".
///
/// Styled as a secondary (outlined gold) so it reads as a companion to
/// "Build Another Dua" rather than competing with it — gold stays a NON-TEXT
/// accent, with the label itself in cream to hold the on-canvas contrast rule.
///
/// Stateful only to own the once-per-result impression beacon: [initState]
/// fires on mount, and since this sits in a `SingleChildScrollView` (not a
/// recycling list) scrolling can't re-trigger it. Building another duʿā
/// replaces the subtree, which correctly counts as a new impression.
class _GiftCta extends ConsumerStatefulWidget {
  const _GiftCta({required this.state, required this.result});

  final DuasState state;
  final BuiltDuaResponse result;

  @override
  ConsumerState<_GiftCta> createState() => _GiftCtaState();
}

class _GiftCtaState extends ConsumerState<_GiftCta> {
  @override
  void initState() {
    super.initState();
    // Post-frame so the very first build isn't doing analytics work, matching
    // how the screen defers its other once-per-result side effects.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsProvider).track(AnalyticsEvents.giftCtaShown);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) => GestureDetector(
        onTap: () async {
          final box = btnContext.findRenderObject() as RenderBox;
          await _openGiftPreview(
            context: context,
            ref: ref,
            state: widget.state,
            result: widget.result,
            placement: AnalyticsEvents.giftPlacementPrimaryCta,
            origin: box.localToGlobal(Offset.zero) & box.size,
          );
        },
        child: Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.75),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Gift this Dua',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.sacredInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the gift preview and instruments the two funnel steps below the
/// impression: which affordance was tapped, and whether a gift was actually
/// sent. Shared by the corner icon and the labeled CTA so the two can only
/// differ by [placement].
Future<void> _openGiftPreview({
  required BuildContext context,
  required WidgetRef ref,
  required DuasState state,
  required BuiltDuaResponse result,
  required String placement,
  Rect? origin,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final analytics = ref.read(analyticsProvider);
  HapticFeedback.mediumImpact();
  analytics.track(AnalyticsEvents.giftPreviewOpened, properties: {
    AnalyticsEvents.propPlacement: placement,
  });
  try {
    await shareBuiltDuaCard(
      context: context,
      need: state.buildNeed,
      sections: duaSectionsForShare(result.breakdown),
      translation: result.translation,
      sharePositionOrigin: origin,
      onShared: (pageCount, shareStatus) =>
          analytics.track(AnalyticsEvents.giftSent, properties: {
        AnalyticsEvents.propPlacement: placement,
        AnalyticsEvents.propPageCount: pageCount,
        AnalyticsEvents.propShareStatus: shareStatus,
      }),
    );
  } catch (e) {
    debugPrint('[SHARE ERROR] $e');
    showShareErrorSnackBar(messenger);
  }
}

/// Gift affordance — top-right, cream (functional chrome ≥80% ink on canvas).
/// Opens the gift-framed dua preview (`shareBuiltDuaCard`).
class _ShareButton extends ConsumerWidget {
  const _ShareButton({required this.state, required this.result});

  final DuasState state;
  final BuiltDuaResponse result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerRight,
      child: Builder(
        builder: (btnContext) => GestureDetector(
          onTap: () async {
            final box = btnContext.findRenderObject() as RenderBox;
            await _openGiftPreview(
              context: context,
              ref: ref,
              state: state,
              result: result,
              placement: AnalyticsEvents.giftPlacementCornerIcon,
              origin: box.localToGlobal(Offset.zero) & box.size,
            );
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sacredTrack,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.card_giftcard_outlined,
                color: AppColors.sacredInk, size: 26),
          ),
        ),
      ),
    );
  }
}
