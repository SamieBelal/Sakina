import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/analytics_event_names.dart';
import '../../../services/analytics_provider.dart';
import '../content/onboarding_widgets.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';
import '../widgets/widget_preview_card.dart';

/// The home-screen widget offer (One Ship W2 Wave G, spec §7).
///
/// Placed straight after the notification ask so the two "keep this alive"
/// moments sit together, and immediately after the lantern has been lit so the
/// first card continues that beat rather than introducing a new idea.
///
/// **iOS cannot add a widget programmatically.** There is no API; Duolingo's
/// equivalent button is instructional too, which is why theirs is paired with a
/// phone mockup. Our CTA opens a short how-to and installs nothing — so the
/// analytics here measure INTENT, never installs.
///
/// Three cards rather than one dominant option is a deliberate founder call
/// (2026-07-28), overriding the choice-overload recommendation: browsing and
/// picking a favourite is itself the moment worth having.
class WidgetOfferScreen extends ConsumerStatefulWidget {
  const WidgetOfferScreen({
    required this.onNext,
    required this.onBack,
    required this.progressSegment,
    this.totalSegments,
    super.key,
  });

  static const String headline = 'Keep it on your home screen.';
  static const String subline = 'Three ways to carry Sakina with you.';
  static const String ctaLabel = 'Show me how';
  static const String skipLabel = 'Not now';

  final VoidCallback onNext;
  final VoidCallback onBack;
  final int progressSegment;
  final int? totalSegments;

  @override
  ConsumerState<WidgetOfferScreen> createState() => _WidgetOfferScreenState();
}

class _WidgetOfferScreenState extends ConsumerState<WidgetOfferScreen> {
  // viewportFraction < 1 so the neighbouring cards peek. The peek IS the
  // affordance — it says "there are more" without a hint label telling them so.
  late final PageController _pages = PageController(viewportFraction: 0.84);

  int _index = 0;

  /// Previews are emitted once per card per visit. Without this a lazy swipe
  /// back and forth inflates the count and makes the carousel look far more
  /// engaging than it was.
  final Set<String> _previewed = {};

  @override
  void initState() {
    super.initState();
    // Card 0 is on screen from the first frame, so it counts as previewed
    // without any swipe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emitPreview(0);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _emitPreview(int index) {
    final option = onboardingWidgetOptions[index];
    if (!_previewed.add(option.kind)) return;
    ref.read(analyticsProvider).track(
      AnalyticsEvents.onboardingWidgetPreviewed,
      properties: {AnalyticsEvents.propWidgetKind: option.kind},
    );
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _emitPreview(index);
  }

  void _onCta() {
    ref.read(analyticsProvider).track(
      AnalyticsEvents.onboardingWidgetCtaTapped,
      properties: {
        AnalyticsEvents.propWidgetKind: onboardingWidgetOptions[_index].kind,
      },
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HowToSheet(option: onboardingWidgetOptions[_index]),
    );
  }

  void _onSkip() {
    ref.read(analyticsProvider).track(AnalyticsEvents.onboardingWidgetSkipped);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: widget.progressSegment,
      totalSegments: widget.totalSegments,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              WidgetOfferScreen.headline,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: AppMotion.entrance, curve: AppMotion.enter),
          const SizedBox(height: AppSpacing.sm),
          Text(
            WidgetOfferScreen.subline,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          )
              .animate(delay: AppMotion.beat)
              .fadeIn(duration: AppMotion.layer, curve: AppMotion.enter),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              onPageChanged: _onPageChanged,
              itemCount: onboardingWidgetOptions.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: WidgetPreviewCard(
                  option: onboardingWidgetOptions[i],
                  active: i == _index,
                ),
              ),
            )
                .animate(delay: AppMotion.listStart)
                .fadeIn(duration: AppMotion.item, curve: AppMotion.enter),
          ),
          const SizedBox(height: AppSpacing.md),
          _Dots(count: onboardingWidgetOptions.length, index: _index),
          const SizedBox(height: AppSpacing.lg),
          OnboardingContinueButton(
            label: WidgetOfferScreen.ctaLabel,
            onPressed: _onCta,
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton(
              onPressed: _onSkip,
              child: Text(
                WidgetOfferScreen.skipLabel,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppMotion.feedback,
          curve: AppMotion.enter,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.borderLight.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// The how-to. Plain instructions, because that is genuinely all we can offer —
/// naming the gallery entry exactly is the whole value, so the strings come
/// from [OnboardingWidgetOption.galleryName] rather than being retyped here.
class _HowToSheet extends StatelessWidget {
  const _HowToSheet({required this.option});

  final OnboardingWidgetOption option;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Touch and hold an empty area of your home screen.',
      'Tap the + button in the corner.',
      'Search for "Sakina", then choose "${option.galleryName}".',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adding ${option.galleryName}',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          e.value,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
