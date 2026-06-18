import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/utils/keyboard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/features/paywall/upgrade_callback.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';
import 'package:sakina/widgets/dua_loading.dart';
import 'package:sakina/widgets/share_card.dart';
import 'package:sakina/widgets/upgrade_required_sheet.dart';

class DuasScreen extends ConsumerStatefulWidget {
  const DuasScreen({super.key});

  @override
  ConsumerState<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends ConsumerState<DuasScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _rippleControllers;
  final TextEditingController _buildController = TextEditingController();
  final ScrollController _buildScrollController = ScrollController();
  final GlobalKey _textFieldKey = GlobalKey();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _rippleControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      );
    });
    // Reconcile the guided-tour suppression flag on mount. The `ref.listen`
    // in build() only fires on duasProvider *changes*, so a stale `true` left
    // over from a previous Duas visit (e.g. a replayed tour) would otherwise
    // persist across this mount with nothing to clear it — permanently hiding
    // the tour's `duas.buildCta` coachmark until the user leaves and re-enters
    // the tab (whose dispose resets the flag). Forcing it to match the current
    // build state here closes that gap. Same stale-suppression class as F-06
    // (which fixed centered steps only). See
    // docs/qa/findings/2026-06-04-tour-buildcta-stale-suppression.md
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTourSuppression(_tourBlockedFor(ref.read(duasProvider)));
    });
  }

  /// True while this screen's multi-screen Build-a-Dua flow (loader + the four
  /// reader beats) is on screen — the window during which the guided tour must
  /// stay hidden because the next step's anchor isn't reachable yet.
  static bool _tourBlockedFor(DuasState s) =>
      s.buildLoading || (s.buildResult != null && s.buildCurrentSection < 4);

  /// Writes [tourSuppressedProvider] only when it differs, so we don't churn
  /// the overlay host with no-op state updates.
  void _syncTourSuppression(bool blocked) {
    if (ref.read(tourSuppressedProvider) != blocked) {
      ref.read(tourSuppressedProvider.notifier).state = blocked;
    }
  }

  void _startRipple() {
    for (var i = 0; i < _rippleControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 530), () {
        if (mounted) _rippleControllers[i].repeat();
      });
    }
  }

  void _stopRipple() {
    for (final c in _rippleControllers) {
      c.stop();
      c.reset();
    }
  }

  @override
  void dispose() {
    // Lift any tour suppression this screen set (e.g. left the tab mid-build)
    // so the guided tour never stays hidden after the Dua flow goes away.
    try {
      if (ref.read(tourSuppressedProvider)) {
        ref.read(tourSuppressedProvider.notifier).state = false;
      }
    } catch (_) {
      // Container already torn down (app shutdown) — nothing to reset.
    }
    for (final c in _rippleControllers) {
      c.dispose();
    }
    _buildController.dispose();
    _buildScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duasProvider);
    final notifier = ref.read(duasProvider.notifier);

    // Surface freemium-gating sheets (daily-cap + warmup-exhausted) when the
    // gating layer blocks a build or signals the warmup→0 transition.
    ref.listen<DuasState>(duasProvider, (prev, next) {
      // Keep the `tourSuppressedProvider` latch in sync with the Build-a-Dua
      // flow. In the slim tour `duas.buildCta` is the FINAL step — the tour
      // completes the instant the user taps Build — so there is no later step
      // to wait for; the latch's remaining job is the stale-flag reconcile (see
      // initState) that clears a leftover `true` from a prior visit so the
      // buildCta coachmark isn't hidden over the build INPUT. Reset in dispose
      // so leaving the tab mid-build never strands a future tour step.
      _syncTourSuppression(_tourBlockedFor(next));
      // Sync the text controller when the provider clears `buildNeed` —
      // resetBuild() (called from Try Again on the off-topic UI and from
      // Build Another Dua on the result screen) wipes the provider state but
      // not the controller. Without this, the previous (rejected) text
      // sticks around in the input on retry. See finding
      // 2026-04-26-build-dua-tryagain-no-clear.md.
      if ((prev?.buildNeed.isNotEmpty ?? false) && next.buildNeed.isEmpty) {
        _buildController.clear();
      }
      if (next.buildGateResult != null && prev?.buildGateResult == null) {
        final sheetContext = context;
        () async {
          final balance = (await getTokens()).balance;
          final bypassesUsed = await daily_usage.getBuiltDuaBypassesUsedToday();
          final premium = await PurchaseService().isPremium();
          final firstBypassEligible =
              await GatingService().firstBypassEligible();
          final displayName = await GatingService().displayName();
          if (!sheetContext.mounted) return;
          DailyCapSheet.show(
            sheetContext,
            feature: GatedFeature.builtDua,
            tokenBalance: balance,
            bypassesUsedToday: bypassesUsed,
            isPremium: premium,
            onBypassRequested: (_) => notifier.submitBuildWithBypass(),
            firstBypassAvailable: firstBypassEligible,
            userDisplayName: displayName,
            onFirstBypassRequested: (_) =>
                notifier.submitBuildWithFirstBypass(),
            onUpgrade: buildPaywallUpgradeCallback(
              reason: next.buildGateResult!.reason,
              pushPaywall: () {
                if (mounted) GoRouter.of(context).push('/paywall');
              },
            ),
          ).whenComplete(notifier.dismissBuildGate);
        }();
      }
      // One-shot warmup-exhaustion sheet — fires on the SUCCESSFUL build that
      // decremented warmup from 1 to 0.
      if (next.buildWarmupJustExhausted != null &&
          prev?.buildWarmupJustExhausted == null) {
        WarmupExhaustedSheet.show(
          context,
          feature: next.buildWarmupJustExhausted!,
          onUpgrade: () => GoRouter.of(context).push('/paywall'),
        ).whenComplete(notifier.dismissBuildWarmupExhausted);
      }
      // Show upgrade sheet when the free saved-dua limit is hit
      if (next.needsUpgrade && !(prev?.needsUpgrade ?? false)) {
        UpgradeRequiredSheet.show(
          context,
          currentCount: next.savedBuiltDuas.length,
          featureLabel: 'dua',
        ).then((_) => notifier.dismissUpgradePrompt());
      }
    });

    if (state.buildLoading) {
      _startRipple();
    } else {
      _stopRipple();
    }

    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: _buildBuildTab(state, notifier),
      ),
    );
  }

  // ===========================================================================
  // BUILD TAB
  // ===========================================================================

  Widget _buildBuildTab(DuasState state, DuasNotifier notifier) {
    if (state.buildLoading) return _buildBuildLoading();
    if (state.buildResult != null && state.buildCurrentSection < 4) {
      return _buildStepViewer(state, notifier);
    }
    if (state.buildResult != null && state.buildCurrentSection == 4) {
      return _buildAmeenScreen(state, notifier);
    }
    return _buildBuildInput(state, notifier);
  }

  Widget _buildBuildInput(DuasState state, DuasNotifier notifier) {
    final enabled = state.buildNeed.trim().isNotEmpty;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _buildScrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                32,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tabHeader('Build a Dua', notifier),
                  const SizedBox(height: 8),
                  Text(
                    'Describe your specific need and we\'ll construct a personal dua following authentic prophetic etiquette.',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondaryLight),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: 24),
                  // Header illustration
                  Center(
                    child: SvgPicture.asset(
                      'assets/illustrations/main_screens/duas_header.svg',
                      height: 140,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(
                      begin: 0.05, end: 0, duration: 600.ms, delay: 300.ms),
                  const SizedBox(height: 24),
                  // Elegant stepped indicator
                  Row(
                    children: [
                      _elegantStepPill('1', 'Praise'),
                      _goldStepLine(),
                      _elegantStepPill('2', 'Salawat'),
                      _goldStepLine(),
                      _elegantStepPill('3', 'Ask'),
                      _goldStepLine(),
                      _elegantStepPill('4', 'Close'),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                  const SizedBox(height: 24),
                  // Text field with focus feedback
                  Focus(
                    onFocusChange: (focused) {
                      setState(() => _hasFocus = focused);
                      if (focused) {
                        Future.delayed(const Duration(milliseconds: 400), () {
                          if (!mounted) return;
                          if (_buildScrollController.hasClients) {
                            _buildScrollController.animateTo(
                              _buildScrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.inputRadius),
                        color: _hasFocus
                            ? AppColors.primaryLight
                            : AppColors.surfaceLight,
                        border: Border.all(
                          color: _hasFocus
                              ? AppColors.primary
                              : AppColors.borderLight,
                          width: _hasFocus ? 1.5 : 1,
                        ),
                      ),
                      child: TextField(
                        key: _textFieldKey,
                        controller: _buildController,
                        minLines: 6,
                        maxLines: 8,
                        onChanged: notifier.setBuildNeed,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.transparent,
                          hintText: 'What do you need a dua for...',
                          hintStyle: AppTypography.bodyMedium
                              .copyWith(color: AppColors.textTertiaryLight),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideY(
                      begin: 0.02, end: 0, duration: 400.ms, delay: 600.ms),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    _errorBox(state.error!),
                  ],
                ],
              ),
            ),
          ),
          // Sticky CTA with cream gradient fade above — matches Reflect screen.
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              12,
              AppSpacing.pagePadding,
              16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundLight.withValues(alpha: 0),
                  AppColors.backgroundLight,
                  AppColors.backgroundLight,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1.0 : 0.5,
              child: TourAnchor(
                surface: TourSurface.duas,
                anchorId: 'buildCta',
                child: GestureDetector(
                  onTap: enabled
                      ? () {
                          HapticFeedback.mediumImpact();
                          notifier.submitBuild();
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: enabled
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.32),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      'Build My Dua',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
          ),
        ],
      ),
    );
  }

  Widget _elegantStepPill(String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EBD9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              number,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _goldStepLine() {
    return Container(
      width: 16,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.secondary.withValues(alpha: 0.35),
    );
  }

  Widget _buildBuildLoading() {
    final progress = ref.watch(duasProvider.select((s) => s.buildProgress));
    return DuaLoading(progress: progress);
  }

  Widget _buildStepViewer(DuasState state, DuasNotifier notifier) {
    final breakdown = state.buildResult!.breakdown;
    if (breakdown.isEmpty) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_outline,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'This place is for your heart',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please describe a sincere need or intention for your dua.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondaryLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    notifier.resetBuild();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final section =
        breakdown[state.buildCurrentSection.clamp(0, breakdown.length - 1)];
    final isLast = state.buildCurrentSection >= breakdown.length - 1;
    final currentStep = state.buildCurrentSection;

    // Editorial breadcrumb labels — short forms of the AI-supplied section
    // labels so all four fit on one row even on narrow phones. Falls back to
    // the raw label if it's already short.
    final breadcrumbLabels = breakdown
        .map((s) => _shortenSectionLabel(s.label))
        .toList(growable: false);

    return Stack(
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
                            // Tiny gold ornament — single restraint dot in place of
                            // the old sparkle row. Anchors the page without confetti.
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary,
                              ),
                            ).animate().fadeIn(duration: 400.ms),
                            const SizedBox(height: AppSpacing.md),
                            // Editorial eyebrow — small gold uppercase label that
                            // reads like a chapter heading in a printed devotional.
                            Text(
                              section.label.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                            const SizedBox(height: AppSpacing.sm),
                            // Hairline gold rule under the eyebrow — quiet ornament
                            // that tells the eye where the section header ends.
                            Container(
                              width: 28,
                              height: 1,
                              color:
                                  AppColors.secondary.withValues(alpha: 0.45),
                            ).animate().scaleX(
                                begin: 0,
                                end: 1,
                                duration: 400.ms,
                                delay: 120.ms,
                                curve: Curves.easeOut),
                            const SizedBox(height: AppSpacing.lg),
                            // Cream Arabic card — replaces saturated emerald block.
                            // Soft warm border + low-alpha gold shadow matches the
                            // _ameenSectionCard family used on the next screen so
                            // the two pages read as one design.
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 28, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius),
                                border:
                                    Border.all(color: AppColors.borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Text(
                                section.arabic,
                                style: AppTypography.quranArabic.copyWith(
                                  color: AppColors.primary,
                                  height: 1.9,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 800.ms, delay: 200.ms)
                                .scaleXY(
                                    begin: 0.97,
                                    end: 1.0,
                                    duration: 800.ms,
                                    delay: 200.ms,
                                    curve: Curves.easeOutBack),
                            const SizedBox(height: AppSpacing.lg),
                            // Transliteration — italic, muted.
                            Text(
                              section.transliteration,
                              style: AppTypography.bodyMedium.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(duration: 500.ms, delay: 380.ms),
                            const SizedBox(height: AppSpacing.md),
                            // Verse-stop ornament — tiny gold dot replaces the harsh
                            // grey divider, like the rosette between Quran ayat.
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    AppColors.secondary.withValues(alpha: 0.85),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 460.ms),
                            const SizedBox(height: AppSpacing.md),
                            // Translation — dark serif-leaning sans, generous height.
                            Text(
                              section.translation,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimaryLight,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(duration: 500.ms, delay: 540.ms),
                            const SizedBox(height: AppSpacing.xl),
                            // Editorial breadcrumb — single-line "Praise · Salawat ·
                            // Ask · Close" with the current section bolded in deep
                            // emerald, others muted. Replaces the dot row.
                            _buildBreadcrumb(breadcrumbLabels, currentStep)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 620.ms),
                            const SizedBox(height: AppSpacing.lg),
                            // Next / Ameen CTA.
                            if (isLast)
                              _buildAmeenCta(notifier)
                                  .animate()
                                  .fadeIn(duration: 500.ms, delay: 700.ms)
                                  .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 500.ms,
                                      delay: 700.ms)
                            else
                              // TourAnchor ('duaSectionNext') for the guided
                              // tour's `duas.sectionNext` step — highlights the
                              // Next button on the first built-dua section so
                              // the user is guided through their dua (the step
                              // is tap-through, so tapping Next advances both
                              // the section and the tour).
                              TourAnchor(
                                surface: TourSurface.duas,
                                anchorId: 'duaSectionNext',
                                child: _buildActionButtonDua('Next', () {
                                  HapticFeedback.mediumImpact();
                                  notifier.nextBuildSection();
                                }),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 700.ms),
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
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
          ),
      ],
    );
  }

  Widget _buildActionButtonDua(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textOnPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Trim AI-supplied section labels to a short breadcrumb form so all four
  /// fit on one line. "Opening Praise" -> "Praise", "Salawat on the
  /// Prophet" -> "Salawat", "Your Ask" -> "Ask", "Closing" -> "Close".
  String _shortenSectionLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('praise') || lower.contains('hamd')) return 'Praise';
    if (lower.contains('salawat') || lower.contains('prophet')) {
      return 'Salawat';
    }
    if (lower.contains('ask') || lower.contains('need')) return 'Ask';
    if (lower.contains('clos') || lower.contains('seal')) return 'Close';
    // Fallback: first word, capitalised.
    final firstWord = label.split(' ').first;
    if (firstWord.isEmpty) return label;
    return firstWord[0].toUpperCase() + firstWord.substring(1).toLowerCase();
  }

  /// Editorial single-line breadcrumb: section names separated by middots,
  /// current step bolded in deep emerald, others muted. Replaces the gold
  /// dot row from the previous design — reads like a printed mushaf
  /// running header rather than a Duolingo step counter.
  Widget _buildBreadcrumb(List<String> labels, int currentStep) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < labels.length; i++) {
      final isCurrent = i == currentStep;
      spans.add(TextSpan(
        text: labels[i],
        style: AppTypography.labelSmall.copyWith(
          color: isCurrent ? AppColors.primary : AppColors.textTertiaryLight,
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ));
      if (i < labels.length - 1) {
        spans.add(TextSpan(
          text: '  \u00B7  ', // middot with breathing room
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.secondary.withValues(alpha: 0.55),
          ),
        ));
      }
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  /// Final-step CTA — emerald pill matching the rest of the app, with a
  /// small gold sparkle on the leading edge and a gold-tinged shadow as a
  /// quiet celebratory cue (this is the gateway to the Ameen screen).
  Widget _buildAmeenCta(DuasNotifier notifier) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        notifier.nextBuildSection();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 18,
              color: AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ameen',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmeenScreen(DuasState state, DuasNotifier notifier) {
    final result = state.buildResult!;

    // Auto-save on first render. Built duas are auto-saved into the journal,
    // so the "save" quest fires from related-dua hearts only — not here.
    //
    // Gate on buildResultSaveHandled: when a free user hits the journal cap,
    // saveCurrentBuiltDua() raises needsUpgrade without persisting, so
    // isBuiltDuaSaved() stays false. Without this flag the widget rebuild
    // (triggered by dismissUpgradePrompt flipping needsUpgrade back to false)
    // would re-enter this branch and re-raise the upgrade sheet in a loop.
    if (!state.buildResultSaveHandled && !notifier.isBuiltDuaSaved()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.saveCurrentBuiltDua();
        ref.read(questsProvider.notifier).onBuiltDuaCompleted();
        checkAchievements(ref);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
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
              // Share button top-right — gold so it reads against cream.
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                    builder: (btnContext) => GestureDetector(
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            HapticFeedback.mediumImpact();
                            final box =
                                btnContext.findRenderObject() as RenderBox;
                            final origin =
                                box.localToGlobal(Offset.zero) & box.size;
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
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  AppColors.secondary.withValues(alpha: 0.10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.share_outlined,
                                color: AppColors.secondary, size: 20),
                          ),
                        )),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── Hero medallion ───────────────────────────────────────────
              // Oversized layered radial-gold glow behind آمين, mirroring the
              // _PaywallHero treatment (gold → cream radial gradient + soft
              // pulsing halo). The Arabic word is the centerpiece in deep
              // gold; the medallion supplies the celebratory "destination"
              // feel without needing a saturated background.
              SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base radial — wide warm gold-into-cream wash.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.05),
                            radius: 0.85,
                            colors: [
                              const Color(0xFFF5EBD9), // gold light tint
                              AppColors.backgroundLight.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.85],
                          ),
                        ),
                      ),
                    ),
                    // Inner halo — slow pulsing concentrated glow.
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.22),
                            AppColors.secondary.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.92, end: 1.08, duration: 2400.ms),
                    // Foreground stack: sparkles → آمين → "Ameen" → tagline
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gold sparkles row.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            return Icon(
                              Icons.auto_awesome,
                              color: AppColors.secondary
                                  .withValues(alpha: i == 2 ? 1.0 : 0.55),
                              size: i == 2 ? 20 : 14,
                            )
                                .animate()
                                .scale(
                                  begin: const Offset(0, 0),
                                  end: const Offset(1, 1),
                                  curve: Curves.elasticOut,
                                  duration: 600.ms,
                                  delay: (i * 80).ms,
                                )
                                .fadeIn(duration: 400.ms, delay: (i * 80).ms);
                          }),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Top spacer absorbs Aref Ruqaa ascender bleed.
                        const SizedBox(height: 33),
                        AdjustedArabicDisplay(
                          text: '\u0622\u0645\u064a\u0646',
                          style: AppTypography.nameOfAllahDisplay.copyWith(
                            color: AppColors.secondary,
                            fontSize: 76,
                            // Hairline shadow for depth on the cream bg —
                            // keeps the gold reading even when the radial
                            // wash is thinnest at the edges.
                            shadows: [
                              Shadow(
                                color:
                                    AppColors.secondary.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 900.ms).scaleXY(
                              begin: 0.82,
                              end: 1.0,
                              duration: 900.ms,
                              curve: Curves.easeOutBack,
                            ),
                        // Bottom spacer compensates for the upward shift in
                        // AdjustedArabicDisplay so the next line doesn't
                        // crowd the calligraphy.
                        const SizedBox(height: 20),
                        Text(
                          'Ameen',
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                            letterSpacing: 1.2,
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'May Allah accept your dua',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Build Another Dua CTA ───────────────────────────────────
              // Emerald-filled pill, white text — matches every other primary
              // CTA in the app. White-on-green pill from the saturated layout
              // is no longer needed now that the bg is cream.
              // TourAnchor ('duaBuildComplete') for the slim guided tour's final
              // step. It anchors here — the Ameen/result screen, i.e. the END of
              // the Build-a-Dua flow — so the tour stays suppressed through the
              // loader + reader beats and only its final coachmark reveals once
              // the user has built and seen their full dua. Completing that step
              // ends the tour, which (when hard_paywall_after_tour_enabled is on)
              // triggers the post-tour hard paywall.
              TourAnchor(
                surface: TourSurface.duas,
                anchorId: 'duaBuildComplete',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _buildController.clear();
                    notifier.resetBuild();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Build Another Dua',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Names Called Upon ───────────────────────────────────────
              _ameenSectionCard(
                title: 'Names Called Upon',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...result.namesUsed.map((n) => Padding(
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
                                      color: AppColors.textPrimaryLight,
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
                                  color: AppColors.textSecondaryLight,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 600.ms),
              const SizedBox(height: AppSpacing.md),

              // ─── Related Duas ────────────────────────────────────────────
              _ameenSectionCard(
                title: 'Related Duas',
                subtitle: 'Save to view full dua in Journal',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...result.relatedDuas.asMap().entries.map((entry) {
                      final i = entry.key;
                      final d = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAltLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.secondary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Builder(builder: (_) {
                                    // Reactive: read saved state off the
                                    // watched `state` (rebuilds on toggle).
                                    final isSaved = state.savedRelatedDuas.any(
                                        (s) =>
                                            s.id ==
                                            SavedRelatedDua.idFor(
                                                d.title, d.source));
                                    final heart = RelatedDuaHeart(
                                      isSaved: isSaved,
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        notifier.toggleSaveRelatedDua(d);
                                        if (!isSaved) {
                                          ref
                                              .read(questsProvider.notifier)
                                              .onDuaSaved();
                                        }
                                        showRelatedDuaSnack(context,
                                            saved: !isSaved);
                                      },
                                    );
                                    if (i == 0) {
                                      return TourAnchor(
                                        surface: TourSurface.duas,
                                        anchorId: 'firstRelatedHeart',
                                        child: heart,
                                      );
                                    }
                                    return heart;
                                  }),
                                  Expanded(
                                    child: Text(
                                      d.arabic,
                                      style: AppTypography.quranArabic
                                          .copyWith(fontSize: 20),
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  d.transliteration,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  d.translation,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimaryLight,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  d.source,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 700.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Cream-tinted section card with a warm border and gold accent-bar header.
  /// Replaces the stark white containers from the saturated-emerald layout
  /// so the cards sit handcrafted on the cream page rather than floating
  /// like tech-y rectangles.
  Widget _ameenSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================

  Widget _tabHeader(String title, DuasNotifier notifier) {
    return Text(
      title,
      style: AppTypography.displayLarge
          .copyWith(color: AppColors.textPrimaryLight),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
    );
  }
}

/// Confirmation toast when a related dua is saved/unsaved from the Ameen
/// screen. The heart fill alone was too quiet to register — especially during
/// the guided tour, where tapping the heart immediately moves the spotlight to
/// the Journal tab. Styled to match the warm gift-card toast. Top-level +
/// visibleForTesting so it can be exercised without pumping the whole screen.
@visibleForTesting
void showRelatedDuaSnack(BuildContext context, {required bool saved}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              saved ? 'Saved to Journal' : 'Removed from Journal',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimaryLight),
            ),
          ],
        ),
      ),
    );
}

/// The save-heart on a Related Dua row. Extracted so the save → fill feedback
/// is a self-contained, testable animation: an [AnimatedSwitcher] cross-scales
/// the outline → filled icon with an `easeOutBack` overshoot, so the "it
/// filled" moment reads as a deliberate pop even if the surrounding card
/// repaints. The keyed [Icon] is what drives the switch when [isSaved] flips.
@visibleForTesting
class RelatedDuaHeart extends StatelessWidget {
  const RelatedDuaHeart({
    super.key,
    required this.isSaved,
    required this.onTap,
  });

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isSaved ? Icons.favorite : Icons.favorite_outline,
            key: ValueKey<bool>(isSaved),
            color: isSaved ? AppColors.primary : AppColors.textTertiaryLight,
            size: 20,
          ),
        ),
      ),
    );
  }
}
