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
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/widgets/name_reveal_overlay.dart';
import 'package:sakina/features/daily/widgets/streak_milestone_overlay.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/ai_service.dart';
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

  @override
  void initState() {
    super.initState();
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
    // Back button is only meaningful in the deeper-reflection flow on
    // steps > 1 (step 0 is the gacha-overlay name, step 1 is the first
    // card the user sees and has no prior step to return to).
    final showBack = state.currentStep == DailyLoopStep.deeper &&
        state.reflectStep > 1 &&
        state.reflectResult != null &&
        !state.checkinLoading &&
        !state.reflectLoading;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: _buildContent(state, notifier),
              ),
            ),
          ),
          if (showBack)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: _backButton(notifier),
            ),
        ],
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
    if (state.currentStep == DailyLoopStep.deeper &&
        state.reflectResult != null) {
      return _buildDeeper(state, notifier);
    }
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
          // Go Deeper button — always free. The 50-token unlock for an
          // additional muhasabah is collected at the "Seek Another Name" /
          // "Discover a New Name" entry CTAs, so once the user is in the
          // flow there's no further token gating.
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
  // DEEPER REFLECTION (step-by-step)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDeeper(DailyLoopState state, DailyLoopNotifier notifier) {
    final result = state.reflectResult!;
    final step = state.reflectStep;

    final (
      String headerLabel,
      Widget content,
      String buttonLabel,
      bool isAmeen
    ) = switch (step) {
      0 => (
          'A Name for your heart',
          _nameContent(result),
          'See Reflection',
          false
        ),
      1 => (
          'Reflection',
          _textContent(result.reframe),
          'Read the Story',
          false
        ),
      2 => (
          'A Prophetic Story',
          _textContent(result.story),
          'See the Dua',
          false
        ),
      _ => ('Dua', _duaContent(result), 'Ameen', true),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: KeyedSubtree(
        key: ValueKey(step),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sparkleRow()),
              const SizedBox(height: 16),
              // Card container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gold accent bar
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ).animate().scaleY(
                            begin: 0,
                            end: 1,
                            duration: 300.ms,
                            delay: 200.ms,
                            curve: Curves.easeOut),
                        const SizedBox(width: 8),
                        Text(
                          headerLabel,
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Content
                    content.animate().fadeIn(duration: 600.ms, delay: 300.ms),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Button
              if (isAmeen)
                TourAnchor(
                  surface: TourSurface.muhasabah,
                  anchorId: 'ameenCta',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final tieredUp =
                          state.cardEngageResult?.tierChanged == true;
                      notifier.advanceReflectStep();
                      final qn = ref.read(questsProvider.notifier);
                      qn.onMuhasabahCompleted();
                      // Every Muhasabah pulls a card → mark as a discovery.
                      qn.onNameDiscovered();
                      if (tieredUp) qn.onCardTieredUp();
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
                        'Ameen',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms)
                    .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 500.ms)
              else
                Builder(builder: (context) {
                  // Only the step-1 "Read the Story" button is a tour anchor.
                  // Step 0 ("See Reflection") and step 2 ("See the Dua") are
                  // intentionally NOT wrapped — see tour step list.
                  final isReadStory = step == 1;
                  final button = GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      notifier.advanceReflectStep();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                      child: Text(
                        buttonLabel,
                        style: AppTypography.labelLarge
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                  final wrapped = isReadStory
                      ? TourAnchor(
                          surface: TourSurface.muhasabah,
                          anchorId: 'readStoryCta',
                          child: button,
                        )
                      : button;
                  return wrapped.animate().fadeIn(
                      duration: 400.ms, delay: 500.ms);
                }),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.05, end: 0, duration: 600.ms),
      ),
    );
  }

  Widget _nameContent(ReflectResponse result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            result.nameArabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              color: AppColors.primary,
              fontSize: 40,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms).scaleXY(
              begin: 0.85,
              end: 1.0,
              duration: 800.ms,
              curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.name,
            style:
                AppTypography.headlineMedium.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _textContent(String text) {
    return Text(
      text,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimaryLight,
        height: 1.6,
      ),
    );
  }

  Widget _duaContent(ReflectResponse result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            result.duaArabic,
            style: AppTypography.quranArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(duration: 800.ms, delay: 200.ms).scaleXY(
            begin: 0.9,
            end: 1.0,
            duration: 800.ms,
            delay: 200.ms,
            curve: Curves.easeOutBack),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.dividerLight),
        const SizedBox(height: AppSpacing.md),
        Text(
          result.duaTransliteration,
          style: AppTypography.bodyMedium.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.duaTranslation,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimaryLight,
            height: 1.6,
          ),
        ),
        if (result.duaSource.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.duaSource,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiaryLight),
          ),
        ],
      ],
    );
  }

  Widget _backButton(DailyLoopNotifier notifier) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // startDeeper() lands the user on step 1 (skipping step 0, which is
        // the name-display the user just saw in the gacha overlay). Block
        // navigating back into step 0 — there's no value re-showing the
        // name, and the rendering path assumes reflectResult is non-null.
        final current = ref.read(dailyLoopProvider).reflectStep;
        if (current > 1) {
          notifier.setReflectStep(current - 1);
        }
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
    ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
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
