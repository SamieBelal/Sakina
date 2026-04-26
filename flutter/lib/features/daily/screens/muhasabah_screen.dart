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
import 'package:sakina/features/daily/widgets/level_up_overlay.dart';
import 'package:sakina/features/daily/widgets/name_reveal_overlay.dart';
import 'package:sakina/features/daily/widgets/streak_milestone_overlay.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/widgets/reflect_loading.dart';

/// Full-screen Muhasabah experience — check-in → deeper → completion.
/// Lives at /muhasabah route. Reads from dailyLoopProvider.
class MuhasabahScreen extends ConsumerStatefulWidget {
  const MuhasabahScreen({super.key});

  @override
  ConsumerState<MuhasabahScreen> createState() => _MuhasabahScreenState();
}

class _MuhasabahScreenState extends ConsumerState<MuhasabahScreen> {
  bool _revealShown = false;
  bool _levelUpShown = false;
  bool _streakMilestoneShown = false;
  bool _discoverTriggered = false;


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);

    // Streak milestone overlay — fire BEFORE level-up if both trigger.
    if (state.streakMilestoneReached && !_streakMilestoneShown) {
      _streakMilestoneShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
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
      });
    }
    if (!state.streakMilestoneReached) _streakMilestoneShown = false;

    // Level up overlay — gated on streak milestone being cleared first so
    // both overlays don't stack in the same frame.
    if (state.leveledUp == true &&
        !state.streakMilestoneReached &&
        !_levelUpShown) {
      _levelUpShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final levelNav = Navigator.of(context, rootNavigator: true);
        levelNav.push(
          PageRouteBuilder(
            opaque: true,
            barrierDismissible: false,
            pageBuilder: (_, __, ___) => LevelUpOverlay(
              levelNumber: state.newLevelNumber ?? state.levelNumber,
              title: state.newLevelTitle ?? state.levelTitle,
              titleArabic: state.newLevelTitleArabic ?? state.levelTitleArabic,
              rewards: state.levelUpRewards,
              onContinue: () {
                levelNav.pop();
                notifier.clearLevelUp();
              },
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      });
    }
    if (state.leveledUp != true) _levelUpShown = false;

    // Reset flags when state resets (e.g. Seek Another Name)
    if (!state.checkinDone) {
      _revealShown = false;
      _discoverTriggered = false;
    }

    // Gacha reveal after check-in
    if (state.checkinDone &&
        !state.checkinLoading &&
        !_revealShown &&
        state.cardEngageResult != null &&
        state.cardEngageResult!.tierChanged) {
      _revealShown = true;
      ref.read(questsProvider.notifier).updateMonthlyStreak(state.streakCount);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) checkAchievements(ref);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final rootNav = Navigator.of(context, rootNavigator: true);
        rootNav.push(
          PageRouteBuilder(
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
      });
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
    // Auto-trigger discover — skip questions, go straight to gacha
    if (!_discoverTriggered) {
      _discoverTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.discoverName();
      });
    }
    return const ReflectLoading();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN (4 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK-IN RESULT (Name card + Go Deeper)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showNotEnoughTokens() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.toll, size: 32, color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              'Not Enough Tokens',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need $tokenCostReflection tokens. Earn more through quests and daily rewards, or visit the store.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  context.push('/store');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to Store'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetCtx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
          ],
        ),
      ),
    );
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
          GestureDetector(
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
              const SizedBox(height: 16),
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
                GestureDetector(
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
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms)
                    .slideY(begin: 0.1, end: 0, duration: 500.ms, delay: 500.ms)
              else
                GestureDetector(
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
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              // Back button
              if (step > 0) ...[
                const SizedBox(height: 16),
                _backButton(notifier),
              ],
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
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          // Go back one step
          final current = ref.read(dailyLoopProvider).reflectStep;
          if (current > 1) {
            notifier.setReflectStep(current - 1);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceAltLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios_rounded,
                  size: 14, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text('Back',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondaryLight)),
            ],
          ),
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
                  'Muḥāsabah Complete',
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
                    HapticFeedback.mediumImpact();
                    final notifier = ref.read(dailyLoopProvider.notifier);
                    // Charge the 50-token unlock fee here, BEFORE resetting the
                    // cycle. spendTokens returns success=false on insufficient
                    // balance instead of throwing, so we have to inspect the
                    // result — a try/catch would silently let the reset run.
                    final result = await spendTokens(tokenCostReflection);
                    if (!result.success) {
                      if (mounted) _showNotEnoughTokens();
                      return;
                    }
                    notifier.refreshTokenBalance(result.newBalance);
                    await notifier.resetToday();
                    // Stay on this screen — it will rebuild with fresh check-in
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.toll,
                                  size: 10, color: Colors.white),
                              const SizedBox(width: 2),
                              Text('$tokenCostReflection',
                                  style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                const SizedBox(height: 24),
                // Return home
                GestureDetector(
                  onTap: () {
                    // Invalidate economy providers so Home reads fresh
                    // values after muhasabah rewards are granted (fixes the
                    // "token pill shows stale 1004 while DB has 1059" bug).
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
