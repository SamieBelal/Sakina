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
import 'package:sakina/features/duas/widgets/built_dua_ameen_screen.dart';
import 'package:sakina/features/duas/widgets/built_dua_section_view.dart';
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
import 'package:sakina/widgets/coachmark/tour_anchor.dart';
import 'package:sakina/widgets/dua_loading.dart';
import 'package:sakina/widgets/upgrade_required_sheet.dart';

// RelatedDuaHeart + showRelatedDuaSnack moved to the extracted widget file
// (decision 19A). Re-exported here so existing importers of duas_screen.dart
// (widget tests, the Ameen screen) keep resolving them without churn.
export 'package:sakina/features/duas/widgets/related_dua_heart.dart'
    show RelatedDuaHeart, showRelatedDuaSnack;

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
      // flow. After `duas.buildCta` the tour advances to `duas.sectionNext`
      // (the Next-button coachmark on the section reader) and then
      // `duas.buildComplete` on the result screen — so the latch suppresses the
      // section-reader/loader beats whose later anchors aren't on screen yet
      // (a step whose anchor IS present, like sectionNext, isn't suppression-
      // hidden). It also does the stale-flag reconcile (see initState) that
      // clears a leftover `true` from a prior visit so the buildCta coachmark
      // isn't hidden over the build INPUT. Reset in dispose so leaving the tab
      // mid-build never strands a future tour step.
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

  /// The Build-a-Dua section step viewer — now on the sacred canvas with the
  /// staggered reveal + segmented progress bar. Delegates to
  /// [BuiltDuaSectionView]; this method stays purely as orchestration. The
  /// `duaSectionNext` tour anchor lives inside that widget.
  Widget _buildStepViewer(DuasState state, DuasNotifier notifier) {
    return BuiltDuaSectionView(state: state, notifier: notifier);
  }

  /// The Build-a-Dua result / Ameen screen — now on the sacred canvas with the
  /// related-dua cards collapsed (first one expanded so `firstRelatedHeart`
  /// stays visible). Delegates to [BuiltDuaAmeenScreen]; this method keeps only
  /// the ref-bound side effects (auto-save, quest + achievement hooks) that
  /// belong to the screen's provider scope. The `firstRelatedHeart` and
  /// `duaBuildComplete` tour anchors live inside that widget.
  Widget _buildAmeenScreen(DuasState state, DuasNotifier notifier) {
    return BuiltDuaAmeenScreen(
      state: state,
      notifier: notifier,
      // Mirror the original gate: skip auto-save side effects once handled or
      // already saved (prevents the journal-cap upgrade-sheet loop).
      saveHandled: state.buildResultSaveHandled || notifier.isBuiltDuaSaved(),
      onFirstRender: () {
        notifier.saveCurrentBuiltDua();
        ref.read(questsProvider.notifier).onBuiltDuaCompleted();
        checkAchievements(ref);
      },
      onRelatedDuaSaved: () => ref.read(questsProvider.notifier).onDuaSaved(),
      onBuildAnother: () {
        _buildController.clear();
        notifier.resetBuild();
      },
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
