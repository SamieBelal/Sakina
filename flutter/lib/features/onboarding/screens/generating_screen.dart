import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/env.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/onboarding_provider.dart';

class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({
    required this.onNext,
    this.testimonialsEnabledOverride,
    super.key,
  });

  final VoidCallback onNext;

  /// Test seam: when non-null, replaces the compile-time
  /// `Env.paywallTestimonialsEnabled` flag for this instance. The test
  /// runner does not pick up `env.json`, so unit tests pass `true` to
  /// exercise the rotation path or omit (null → falls through to the
  /// Env flag, which defaults to `false` in v1). Production code must
  /// never pass this — flip the env flag instead.
  @visibleForTesting
  final bool? testimonialsEnabledOverride;

  bool get _testimonialsEnabled =>
      testimonialsEnabledOverride ?? Env.paywallTestimonialsEnabled;

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends ConsumerState<GeneratingScreen> {
  bool _hasAdvanced = false;

  // Testimonial rotation state. Only initialized when testimonials are
  // enabled — when off, _testimonialIndex stays 0 and _testimonialTimer
  // stays null. Three testimonials × ~1100ms each fits comfortably in the
  // existing 3500ms loader window with ~200ms of outro headroom.
  int _testimonialIndex = 0;
  Timer? _testimonialTimer;
  static const _testimonialInterval = Duration(milliseconds: 1100);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).runGeneratingTheater(() {
        if (mounted && !_hasAdvanced) {
          _hasAdvanced = true;
          widget.onNext();
        }
      });
    });

    if (widget._testimonialsEnabled) {
      _testimonialTimer = Timer.periodic(_testimonialInterval, (_) {
        if (!mounted) return;
        setState(() {
          _testimonialIndex =
              (_testimonialIndex + 1) % AppStrings.generatingTestimonials.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _testimonialTimer?.cancel();
    super.dispose();
  }

  // 4 steps spread across the 3.5s timeline (0.0 → 1.0). The 4th step
  // activates at 0.70 so it has ~1.05s of "active" time before auto-advance.
  static const _steps = [
    (threshold: 0.0, label: AppStrings.paywallFlowGeneratingStep1),
    (threshold: 0.20, label: AppStrings.paywallFlowGeneratingStep2),
    (threshold: 0.45, label: AppStrings.paywallFlowGeneratingStep3),
    (threshold: 0.70, label: AppStrings.paywallFlowGeneratingStep4),
  ];

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(
      onboardingProvider.select((s) => s.generateProgress),
    );
    final percentage = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
            children: [
              const Spacer(flex: 3),
              // Decorative Arabic at low opacity
              Opacity(
                opacity: 0.75,
                child: Text(
                  AppStrings.generatingBismillah,
                  style: AppTypography.nameOfAllahDisplay.copyWith(
                    color: AppColors.secondary,
                    fontSize: 32,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ).animate().fadeIn(duration: 800.ms),
              const SizedBox(height: AppSpacing.xxl),
              // Percentage display
              Text(
                '$percentage%',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.generatingTitle,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Step labels
              ...List.generate(_steps.length, (index) {
                final step = _steps[index];
                final isActive = progress >= step.threshold;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.primaryLight
                              : AppColors.surfaceAltLight,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        step.label,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isActive
                              ? AppColors.textPrimaryLight
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms);
              }),

              // Rotating testimonials — flag-gated by
              // Env.paywallTestimonialsEnabled (default OFF in v1 because
              // Sakina is pre-launch and has no real reviews to quote).
              // When the flag is off this entire subtree is omitted (no
              // empty SizedBox) so layout shifts the moment the flag
              // flips on don't show a height jump. AnimatedSwitcher keyed
              // on the index gives a 240ms cross-fade between testimonials.
              // Per RevenueCat 2026 research, loading interstitials with
              // rotating social proof lift conversion in established apps.
              if (widget._testimonialsEnabled) ...[
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Text(
                    AppStrings.generatingTestimonials[_testimonialIndex],
                    key: ValueKey<int>(_testimonialIndex),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(flex: 4),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
