import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/streaks/providers/freeze_burn_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/widgets/name_reveal_overlay.dart';
import 'package:sakina/features/daily/widgets/streak_milestone_overlay.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/widgets/beat_reveal/beat_reveal_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily_usage;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/features/paywall/upgrade_callback.dart';
import 'package:sakina/features/paywall/widgets/daily_cap_sheet.dart';
import 'package:sakina/features/paywall/widgets/warmup_exhausted_sheet.dart';
import 'package:sakina/widgets/coachmark/tour_anchor.dart';
import 'package:sakina/widgets/reflect_loading.dart';

/// Full-screen Muhasabah experience — check-in → deeper → completion.
/// Lives at /muhasabah route. Reads from dailyLoopProvider.
class MuhasabahScreen extends ConsumerStatefulWidget {
  const MuhasabahScreen({super.key});

  @override
  ConsumerState<MuhasabahScreen> createState() => _MuhasabahScreenState();
}

class _MuhasabahScreenState extends ConsumerState<MuhasabahScreen> {
  /// Synchronous re-entry guard for the "Seek Another Name" CTA. Mirrors
  /// the progress_screen home dashboard guard. Set BEFORE any await; the
  /// try/finally clears it on every exit including early returns. Without
  /// this, a double-tap that lands while the first call is still inside
  /// `GatingService.canUse()` passes the gate twice and `markUsed` fires
  /// twice — same shape as the reflect/duas D-E5 race.
  bool _discoverInFlight = false;

  /// Lifetime count of beat-flow advances (decision 4A). Null until loaded from
  /// prefs; the first-run "tap to continue" hint shows while this is < 3 (or
  /// whenever the guided tour is active — decision 10A). Bumped on first advance.
  int? _hintAdvances;
  static const String _hintAdvancesKey = 'beat_hint_advances';

  @override
  void initState() {
    super.initState();
    _loadHintAdvances();
    // One-shot: if the user landed here with no check-in done yet today,
    // fire discoverName once. Every other state-change side effect is
    // dispatched from the ref.listen in build(); no other code path in
    // this widget calls discoverName implicitly. That's what closes the
    // "phantom second gacha on Return to Home" bug class — there's no
    // in-build auto-trigger left to race against provider invalidation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(dailyLoopProvider);
      if (!state.checkinDone && !state.checkinLoading) {
        ref.read(dailyLoopProvider.notifier).discoverName();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Side effects live in ref.listen, NOT in build conditionals. listen
    // callbacks fire on rising edges (prev != next) without triggering a
    // rebuild themselves, which gives exactly-once semantics for free —
    // no guard flags needed. This closes the "phantom second gacha on
    // Return to Home" bug class by construction.
    ref.listen<DailyLoopState>(dailyLoopProvider, (prev, next) {
      // Streak milestone — fire if newly reached.
      if (next.streakMilestoneReached &&
          prev?.streakMilestoneReached != true) {
        _pushStreakMilestoneOverlay(next);
        return;
      }
      // Streak lapse (restorable) is NOT surfaced here — that would slam the
      // rescue modal over the sacred Name reveal. The flag stays set on the
      // daily-loop state; the Home screen offers the paid rescue as a calm
      // epilogue once the whole ritual is done (see progress_screen).
      // Gacha reveal — when a tier-changed engageResult freshly arrives.
      // Identity comparison is sufficient: every discoverName call
      // constructs a new CardEngageResult, so back-to-back discoveries
      // (Seek Another Name) still trigger because instances differ.
      final prevResult = prev?.cardEngageResult;
      final nextResult = next.cardEngageResult;
      if (nextResult != null &&
          nextResult.tierChanged &&
          !next.checkinLoading &&
          !identical(prevResult, nextResult)) {
        _pushNameRevealOverlay(next);
      }
    });

    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);

    // The deeper reflection runs full-screen on the emerald sacred canvas
    // (BeatRevealFlow brings its own Scaffold + chrome + back handling). The
    // canvas is entered the moment the user leaves the gacha, so the wait is
    // part of the ritual — hence we branch on `deeper` even while loading.
    if (state.currentStep == DailyLoopStep.deeper) {
      return _buildBeatFlow(state, notifier);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: _buildContent(state, notifier),
          ),
        ),
      ),
    );
  }

  Future<void> _loadHintAdvances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(_hintAdvancesKey) ?? 0;
      if (mounted) setState(() => _hintAdvances = v);
    } catch (_) {
      if (mounted) setState(() => _hintAdvances = 3); // fail safe: hide hint
    }
  }

  Future<void> _bumpHintAdvances() async {
    final current = _hintAdvances ?? 0;
    if (current >= 3) return;
    final next = current + 1;
    if (mounted) setState(() => _hintAdvances = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hintAdvancesKey, next);
    } catch (_) {
      // Non-critical.
    }
  }

  Widget _buildBeatFlow(DailyLoopState state, DailyLoopNotifier notifier) {
    final status = state.error != null
        ? BeatFlowStatus.error
        : state.reflectLoading || state.reflectResult == null
            ? BeatFlowStatus.loading
            : BeatFlowStatus.ready;

    // Force the hint whenever the tour is active so the `readStoryCta` anchor
    // (which wraps the hint) is present on every tour path, incl. resume — the
    // anchor never times out for want of a target (decision 10A).
    final tourActive =
        ref.watch(onboardingTourControllerProvider.select((s) => s.isActive));
    final showHint = tourActive || ((_hintAdvances ?? 3) < 3);

    return BeatRevealFlow(
      status: status,
      response: state.reflectResult,
      showFirstRunHint: showHint,
      onFirstAdvance: _bumpHintAdvances,
      onAmeen: () {
        HapticFeedback.mediumImpact();
        final tieredUp = state.cardEngageResult?.tierChanged == true;
        final qn = ref.read(questsProvider.notifier);
        qn.onMuhasabahCompleted();
        qn.onNameDiscovered();
        if (tieredUp) qn.onCardTieredUp();
        notifier.completeDeeper();
      },
      onReturnHome: () {
        if (mounted) context.go('/');
      },
      onRetry: () => notifier.startDeeper(),
      onBeatAdvanced: (index, kind) {
        DailyLoopNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectBeatAdvanced,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceMuhasabah,
            AnalyticsEvents.propBeatIndex: index,
            AnalyticsEvents.propBeatKind: kind.name,
          },
        );
      },
      onSkip: (from) {
        DailyLoopNotifier.onAnalyticsEvent?.call(
          AnalyticsEvents.reflectFlowSkipped,
          {
            AnalyticsEvents.propSurface: AnalyticsEvents.surfaceMuhasabah,
            AnalyticsEvents.propFromBeatIndex: from,
          },
        );
      },
      readStoryAnchorBuilder: (child) => TourAnchor(
        surface: TourSurface.muhasabah,
        anchorId: 'readStoryCta',
        child: child,
      ),
      ameenAnchorBuilder: (child) => TourAnchor(
        surface: TourSurface.muhasabah,
        anchorId: 'ameenCta',
        child: child,
      ),
    );
  }

  void _pushStreakMilestoneOverlay(DailyLoopState state) {
    if (!mounted) return;
    final notifier = ref.read(dailyLoopProvider.notifier);
    final nav = Navigator.of(context, rootNavigator: true);
    nav.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => StreakMilestoneOverlay(
          streakCount: state.streakMilestoneCount ?? 0,
          xpAwarded: state.streakMilestoneXp ?? 0,
          scrollsAwarded: state.streakMilestoneScrolls ?? 0,
          onContinue: () {
            nav.pop();
            notifier.clearStreakMilestone();
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _pushNameRevealOverlay(DailyLoopState state) async {
    if (!mounted) return;
    ref.read(questsProvider.notifier).updateMonthlyStreak(state.streakCount);
    final rootNav = Navigator.of(context, rootNavigator: true);
    await rootNav.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: 'NameRevealOverlay'),
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => NameRevealOverlay(
          nameArabic:
              state.engagedCard?.arabic ?? state.checkinNameArabic ?? '',
          nameEnglish:
              state.engagedCard?.transliteration ?? state.checkinName ?? '',
          nameEnglishMeaning: state.engagedCard?.english ?? '',
          teaching: state.engagedCard?.lesson ?? '',
          card: state.engagedCard,
          engageResult: state.cardEngageResult,
          onContinue: rootNav.pop,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    // Check achievements & flush quest toasts after the gacha overlay is
    // dismissed so toasts appear on the muhasabah screen (visible).
    if (!mounted) return;
    await checkAchievements(ref);
  }

  Widget _buildContent(DailyLoopState state, DailyLoopNotifier notifier) {
    if (state.checkinLoading || state.reflectLoading) {
      return const ReflectLoading();
    }
    if (state.currentStep == DailyLoopStep.completed) {
      return _buildCompleted(state);
    }
    // Deeper reflection is handled full-screen in build() via _buildBeatFlow.
    if (state.checkinDone && state.checkinName != null) {
      return _buildCheckinResult(state, notifier);
    }
    // Fresh state — initState's postFrame fires discoverName which flips
    // checkinLoading=true on the next frame. Show loading meanwhile.
    return const ReflectLoading();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN (4 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN RESULT (Name card + Go Deeper)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showDiscoverGateSheet(GateReason reason) {
    () async {
      final balance = (await getTokens()).balance;
      final bypassesUsed =
          await daily_usage.getDiscoverNameBypassesUsedToday();
      final premium = await PurchaseService().isPremium();
      final firstBypassEligible =
          await GatingService().firstBypassEligible();
      final displayName = await GatingService().displayName();
      if (!mounted) return;
      final notifier = ref.read(dailyLoopProvider.notifier);
      DailyCapSheet.show(
        context,
        feature: GatedFeature.discoverName,
        tokenBalance: balance,
        bypassesUsedToday: bypassesUsed,
        isPremium: premium,
        onBypassRequested: (_) => notifier.discoverNameWithBypass(),
        firstBypassAvailable: firstBypassEligible,
        userDisplayName: displayName,
        onFirstBypassRequested: (_) => notifier.discoverNameWithFirstBypass(),
        onUpgrade: buildPaywallUpgradeCallback(
          reason: reason,
          pushPaywall: () {
            if (mounted) GoRouter.of(context).push('/paywall');
          },
        ),
      );
    }();
  }

  Widget _buildCheckinResult(DailyLoopState state, DailyLoopNotifier notifier) {
    // Try engagedCard first, fall back to looking up by name
    final card =
        state.engagedCard ?? findCollectibleByName(state.checkinName ?? '');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text(
            'Your Reflection',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Name card — onboarding style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderLight, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  card?.arabic ?? state.checkinNameArabic ?? '',
                  style: AppTypography.nameOfAllahDisplay.copyWith(
                    color: AppColors.secondary,
                    fontSize: 40,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  card?.transliteration ?? state.checkinName ?? '',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                if (card != null) ...[
                  Text(
                    card.english,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (card.lesson.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(height: 1, color: AppColors.dividerLight),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      card.lesson,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.05, end: 0, duration: 600.ms),
          const SizedBox(height: AppSpacing.lg),
          _sparkleRow(),
          const SizedBox(height: AppSpacing.lg),
          // Go Deeper button — always free. Additional muhasabahs are gated
          // by daily caps (25-token bypass via DailyCapSheet) at the "Seek
          // Another Name" / "Discover a New Name" entry CTAs, so once the
          // user is in the flow there's no further token gating.
          TourAnchor(
            surface: TourSurface.muhasabah,
            anchorId: 'goDeeperCta',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                notifier.startDeeper();
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
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Go Deeper',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETED
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCompleted(DailyLoopState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _sparkleRow(),
          const SizedBox(height: 16),
          // Completion card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/illustrations/main_screens/daily_complete.svg',
                  height: 140,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Muhāsabah Complete',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "You've reflected, gone deeper, and connected with Allah today.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                // Seek Another Name — primary CTA
                GestureDetector(
                  onTap: () async {
                    // Synchronous re-entry guard — see field doc. Set BEFORE
                    // any await; try/finally clears it on every exit.
                    if (_discoverInFlight) return;
                    _discoverInFlight = true;
                    try {
                      HapticFeedback.mediumImpact();
                      final notifier = ref.read(dailyLoopProvider.notifier);
                      // Gating layer enforces the 1/day cap (or warmup) for
                      // discover_name. No tokens are charged — caps replaced
                      // the token economy gate per the freemium redesign.
                      // Resolve premium ONCE so canUse + markUsed share a
                      // single RevenueCat round-trip.
                      final premium = await PurchaseService().isPremium();
                      final gate = await GatingService().canUse(
                        GatedFeature.discoverName,
                        isPremiumHint: premium,
                      );
                      if (!gate.allowed) {
                        if (mounted) _showDiscoverGateSheet(gate.reason);
                        return;
                      }
                      await notifier.resetToday();
                      if (!mounted) return;
                      await notifier.discoverName();
                      // Decrement on success — mirrors reflect provider's
                      // post-success markUsed pattern. discoverName has no
                      // observable failure mode here (it's an in-app card
                      // pick backed by a local lookup), so it's safe to mark
                      // used immediately after the call.
                      final outcome = await GatingService().markUsed(
                        GatedFeature.discoverName,
                        isPremiumHint: premium,
                      );
                      if (outcome == UsageOutcome.warmupJustExhausted &&
                          mounted) {
                        WarmupExhaustedSheet.show(
                          context,
                          feature: GatedFeature.discoverName,
                          onUpgrade: () =>
                              GoRouter.of(context).push('/paywall'),
                        );
                      }
                    } finally {
                      _discoverInFlight = false;
                    }
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
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Seek Another Name',
                            style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                const SizedBox(height: 24),
                // Return home
                TourAnchor(
                  surface: TourSurface.muhasabah,
                  anchorId: 'returnHomeCta',
                  child: GestureDetector(
                    onTap: () {
                      // Invalidate economy providers so Home reads fresh
                      // values after muhasabah rewards are granted (fixes the
                      // "token pill shows stale 1004 while DB has 1059" bug).
                      // Order doesn't matter anymore — there's no in-build
                      // auto-trigger to race against, so the invalidation
                      // can't accidentally re-fire discoverName.
                      ref.invalidate(dailyLoopProvider);
                      ref.invalidate(tierUpScrollProvider);
                      ref.invalidate(dailyRewardsProvider);
                      // The freeze-burn flag is stamped server-side mid-flow
                      // (markActiveToday → consume_streak_freeze), so refresh the
                      // (otherwise once-resolved) provider or Home keeps its
                      // stale pre-burn value and the reunion card never shows.
                      ref.invalidate(pendingFreezeBurnProvider);
                      context.go('/');
                    },
                    child: Text(
                      'Return to Home',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 600.ms),
                const SizedBox(height: 16),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sparkleRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          Icons.auto_awesome,
          color: AppColors.secondary.withValues(alpha: i == 2 ? 1.0 : 0.6),
          size: i == 2 ? 20 : 14,
        )
            .animate()
            .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 600.ms,
                delay: (i * 80).ms)
            .fadeIn(duration: 400.ms, delay: (i * 80).ms);
      }),
    );
  }
}
