import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:sakina/widgets/primary_card.dart';
import 'package:sakina/services/xp_service.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _showDiscoveryQuiz = true;
  bool _rewardCalendarExpanded = false;
  bool _levelUpShown = false;
  bool _launchGateReady = false;

  @override
  void initState() {
    super.initState();
    _checkDiscoveryQuiz();
    _maybeShowDailyLaunch();
  }

  Future<void> _maybeShowDailyLaunch() async {
    final should = await shouldShowDailyLaunch();
    if (!mounted) return;
    if (should) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (_, __, ___) => const DailyLaunchOverlay(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        setState(() => _launchGateReady = true);
      });
    } else {
      setState(() => _launchGateReady = true);
    }
  }

  Future<void> _checkDiscoveryQuiz() async {
    final anchorNames = await loadSavedDiscoveryQuizAnchorNames();
    if (!mounted) return;
    setState(() => _showDiscoveryQuiz = anchorNames.isEmpty);
  }

  Future<void> _openDiscoveryQuiz() async {
    await GoRouter.of(context).push('/discovery-quiz');
    await _checkDiscoveryQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);
    final todaysName = getTodaysName();

    // Detect level-up event and show overlay
    // Level-up overlay is shown from muhasabah_screen only —
    // clear the flag here so it doesn't re-trigger.
    if (state.leveledUp == true && !_levelUpShown) {
      _levelUpShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.clearLevelUp();
      });
    }
    if (state.leveledUp != true) {
      _levelUpShown = false;
    }

    if (!state.loaded || !_launchGateReady) {
      return SakinaLoader.fullScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Greeting row (outside card)
              _buildGreetingRow(state),
              const SizedBox(height: AppSpacing.md),

              // 2. Unified dashboard card
              _buildDashboardCard(state, todaysName),
              // Just enough to breathe above the bottom nav. The
              // SingleChildScrollView's pagePadding already adds ~24px
              // on its own, and the Scaffold's bottomNavigationBar
              // provides the visual separator — anything more here was
              // dead space (was AppSpacing.xl + AppSpacing.xxl = 80px).
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // Greeting Row (simple, outside the card)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGreetingRow(DailyLoopState state) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${state.greeting}!',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        // Store
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/store');
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAltLight,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 18,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Settings gear
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/settings');
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAltLight,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 18,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Unified Dashboard Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDashboardCard(DailyLoopState state, AllahName todaysName) {
    final xpState = _calculateXpProgress(state.xpTotal);
    final double xpProgress = xpState.xpForNextLevel > 0
        ? (xpState.xpIntoCurrentLevel / xpState.xpForNextLevel).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Single row: Avatar + Lvl/Title + XP bar + pills
          Row(
            children: [
              // Rank avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: Center(
                  child: Text(
                    state.levelTitleArabic,
                    style: AppTypography.nameOfAllahDisplay.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Lvl + Title stacked
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lv ${state.levelNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.levelTitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Streak pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.streakBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: AppColors.streakAmber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${state.streakCount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.streakAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Token pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.toll,
                        size: 12, color: AppColors.secondary),
                    const SizedBox(width: 2),
                    Text(
                      '${state.tokenBalance}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Scroll pill (tappable → store)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/store');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 12, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 2),
                      Text(
                        '${ref.watch(tierUpScrollProvider).balance}',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // XP bar — full width including under avatar
          Padding(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: xpProgress,
                minHeight: 3,
                backgroundColor: AppColors.borderLight,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 14),

          // Today's Name (hero section)
          // Gold sparkles
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Icon(
                Icons.auto_awesome,
                color:
                    AppColors.secondary.withValues(alpha: i == 2 ? 1.0 : 0.6),
                size: i == 2 ? 18 : 12,
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
          ),
          const SizedBox(height: 8),
          Text(
            "Today's Name",
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 44),
          AdjustedArabicDisplay(
            text: todaysName.arabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              color: AppColors.secondary,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${todaysName.transliteration} — ${todaysName.english}',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
          const SizedBox(height: 6),
          Text(
            todaysName.lesson,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms, delay: 500.ms),

          // Muhasabah row
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 14),
          _buildMuhasabahRow(state),

          // Quests
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              GoRouter.of(context).push('/quests');
            },
            child: Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: AppColors.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quests',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Complete daily goals to earn rewards',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textTertiaryLight),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

          // Discover Anchor Names (if not done)
          if (_showDiscoveryQuiz) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.dividerLight),
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                HapticFeedback.lightImpact();
                await _openDiscoveryQuiz();
              },
              child: Row(
                children: [
                  const Icon(Icons.star_outline_rounded,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover Your Anchor Names',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Find the Names that speak to your soul',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textTertiaryLight),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
          ],

          // Daily Rewards
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 14),
          _buildRewardCalendar(),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.03, end: 0, duration: 500.ms, delay: 100.ms);
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // Muhasabah Row (inside dashboard card)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showNotEnoughTokens(BuildContext context) {
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
              'You need $tokenCostReflection tokens for this action.',
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

  Widget _buildMuhasabahRow(DailyLoopState state) {
    final completed = state.currentStep == DailyLoopStep.completed;
    final inProgress =
        state.checkinDone || state.currentStep != DailyLoopStep.checkin;
    final promptLabel = _buildMuhasabahPromptLabel(state);

    if (completed) {
      return GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          final notifier = ref.read(dailyLoopProvider.notifier);
          final result = await spendTokens(tokenCostReflection);
          if (result.success) {
            notifier.refreshTokenBalance(result.newBalance);
            await notifier.resetToday();
            if (mounted) context.push('/muhasabah');
          } else if (mounted) {
            _showNotEnoughTokens(context);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            const Icon(Icons.explore_outlined, color: AppColors.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover a New Name',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    promptLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Token cost indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.toll, size: 12, color: AppColors.secondary),
                  const SizedBox(width: 3),
                  Text(
                    '$tokenCostReflection',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
    }

    // Not started or in progress
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/muhasabah');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inProgress ? 'Continue Muḥāsabah' : 'Begin Muḥāsabah',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    promptLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7), size: 14),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  String _buildMuhasabahPromptLabel(DailyLoopState state) {
    final prompt = state.todaysQuestion?.question.trim();
    if (prompt == null || prompt.isEmpty) {
      return 'Daily spiritual check-in';
    }

    return 'Today: $prompt';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2.5. Daily Reward Calendar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRewardCalendar() {
    final rewards = ref.watch(dailyRewardsProvider);
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    final claimed = rewards.claimedToday;

    // When claimed: show a slim collapsed bar, tap to expand full calendar
    if (claimed && !_rewardCalendarExpanded) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _rewardCalendarExpanded = true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Day ${rewards.currentDay}/7 claimed',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiaryLight, size: 18),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
    }

    // Full calendar (unclaimed or manually expanded)
    return GestureDetector(
      onTap: claimed
          ? () {
              HapticFeedback.lightImpact();
              setState(() => _rewardCalendarExpanded = false);
            }
          : null,
      child: _cardShell(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Daily Rewards',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Day ${claimed ? rewards.currentDay : rewards.nextClaimDay}/7',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (claimed) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_up_rounded,
                      color: AppColors.textTertiaryLight, size: 18),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = i + 1;
                final reward = scaledRewardForDay(day, isPremium: isPremium);
                final isClaimed = day <= rewards.currentDay && claimed
                    ? true
                    : day < rewards.currentDay;
                final isCurrent = !claimed && day == rewards.nextClaimDay;
                final isSpecial = reward.type != RewardType.tokens;

                return Expanded(
                  child: _buildRewardDay(
                    day: day,
                    reward: reward,
                    claimed:
                        isClaimed || (day == rewards.currentDay && claimed),
                    current: isCurrent,
                    special: isSpecial,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            if (claimed && rewards.currentDay < 7)
              Text(
                'Come back tomorrow for ${scaledRewardForDay(rewards.currentDay + 1, isPremium: isPremium).label}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
              )
            else if (claimed && rewards.currentDay == 7)
              Text(
                'Cycle complete! Resets tomorrow.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Complete a Muḥāsabah to claim today\'s reward',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            if (rewards.streakFreezeOwned) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.ac_unit, color: Color(0xFF60A5FA), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Streak Freeze active',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildRewardDay({
    required int day,
    required DayReward reward,
    required bool claimed,
    required bool current,
    required bool special,
  }) {
    final Color borderColor;
    final Color bgColor;
    final Widget icon;

    if (claimed) {
      borderColor = special ? AppColors.secondary : AppColors.primary;
      bgColor = special ? AppColors.secondaryLight : AppColors.primaryLight;
      icon = Icon(
        Icons.check_rounded,
        size: 16,
        color: special ? AppColors.secondary : AppColors.primary,
      );
    } else if (current) {
      borderColor = AppColors.primary;
      bgColor = Colors.transparent;
      icon = _rewardIcon(reward, AppColors.primary);
    } else {
      borderColor = AppColors.borderLight;
      bgColor = Colors.transparent;
      icon = _rewardIcon(
          reward, AppColors.textTertiaryLight.withValues(alpha: 0.5));
    }

    Widget circle = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: current ? 2 : 1.5,
        ),
      ),
      child: Center(child: icon),
    );

    if (current) {
      circle = circle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 1000.ms);
    }

    return Column(
      children: [
        circle,
        const SizedBox(height: 4),
        Text(
          reward.label.replaceAll(' ', '\n'),
          style: AppTypography.labelSmall.copyWith(
            color: claimed
                ? AppColors.textSecondaryLight
                : current
                    ? AppColors.primary
                    : AppColors.textTertiaryLight,
            fontSize: 7,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _rewardIcon(DayReward reward, Color color) {
    switch (reward.icon) {
      case 'freeze':
        return const Icon(Icons.ac_unit, size: 15, color: Color(0xFF60A5FA));
      case 'scroll':
        return const Icon(Icons.receipt_long,
            size: 15, color: Color(0xFF3B82F6));
      case 'star':
        return const Icon(Icons.star_rounded,
            size: 16, color: AppColors.secondary);
      case 'token':
        return Icon(Icons.toll, size: 15, color: color);
      default:
        return Icon(Icons.toll, size: 15, color: color);
    }
  }

  // ── Card Shell ─────────────────────────────────────────────────────────────

  Widget _cardShell({required Widget child}) {
    return SizedBox(
      width: double.infinity,
      child: PrimaryCard(
        padding: const EdgeInsets.all(28),
        child: child,
      ),
    );
  }







  ({int xpIntoCurrentLevel, int xpForNextLevel}) _calculateXpProgress(
      int total) {
    final state = calculateXpState(total);
    return (
      xpIntoCurrentLevel: state.xpIntoCurrentLevel,
      xpForNextLevel: state.xpForNextLevel
    );
  }

}
