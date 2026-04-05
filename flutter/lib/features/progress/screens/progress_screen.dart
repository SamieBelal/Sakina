import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/core/constants/checkin_questions.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/screens/daily_launch_overlay.dart';
import 'package:sakina/features/daily/widgets/name_reveal_overlay.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _showDiscoveryQuiz = true;
  bool _revealDone = false;
  bool _wasLoading = false;
  bool _rewardCalendarExpanded = false;


  @override
  void initState() {
    super.initState();
    _checkDiscoveryQuiz();
    _maybeShowDailyLaunch();
  }

  Future<void> _maybeShowDailyLaunch() async {
    final should = await shouldShowDailyLaunch();
    if (!should || !mounted) return;
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
    });
  }

  Future<void> _checkDiscoveryQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final anchorNames = prefs.getStringList('anchor_names');
    if (mounted && anchorNames != null && anchorNames.isNotEmpty) {
      setState(() => _showDiscoveryQuiz = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);
    final todaysName = getTodaysName();

    // Detect transition from loading → checkin done to trigger full-screen reveal
    if (_wasLoading && !state.checkinLoading && state.checkinDone && state.checkinName != null && !_revealDone) {
      _revealDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFullScreenReveal(state);
      });
    }
    _wasLoading = state.checkinLoading;

    if (!state.loaded) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar
              _buildTopBar(state),
              const SizedBox(height: AppSpacing.lg),

              // 2. Streak + XP Strip
              _buildStreakXpStrip(state),
              const SizedBox(height: AppSpacing.lg),

              // 3. Daily Practice Card (Hero) — moved above rewards
              _buildDailyPracticeCard(state, notifier),
              const SizedBox(height: AppSpacing.lg),

              // 4. Daily Reward Calendar — collapsed bar when claimed
              _buildRewardCalendar(),
              const SizedBox(height: AppSpacing.lg),

              // 5. Daily Quest Strip
              _DailyQuestStrip(),
              const SizedBox(height: AppSpacing.lg),

              // 6. Today's Name of Allah
              _buildTodaysNameCard(todaysName),
              const SizedBox(height: AppSpacing.lg),

              // 6. Discovery Quiz CTA
              if (_showDiscoveryQuiz) ...[
                _buildDiscoveryQuizCta(),
                const SizedBox(height: AppSpacing.lg),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Top Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(DailyLoopState state) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${state.greeting}, ready to reflect?',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/settings');
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAltLight,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. Streak + XP Strip
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStreakXpStrip(DailyLoopState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.streakAmber,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text(
            '${state.streakCount}',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'days',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          // Token balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll, size: 13, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '${state.tokenBalance}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.xpTotal} XP',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2.5. Daily Reward Calendar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRewardCalendar() {
    final rewards = ref.watch(dailyRewardsProvider);
    final claimed = rewards.claimedToday;

    // When claimed: show a slim collapsed bar, tap to expand full calendar
    if (claimed && !_rewardCalendarExpanded) {
      final nextDay = rewards.currentDay < 7 ? rewards.currentDay + 1 : null;
      final nextReward = nextDay != null ? rewardSchedule[nextDay - 1] : null;

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
              if (nextReward != null)
                Text(
                  'Tomorrow: ${nextReward.label}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
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
                Text(
                  'Daily Rewards',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const Spacer(),
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
                final reward = rewardSchedule[i];
                final isClaimed = day <= rewards.currentDay && claimed
                    ? true
                    : day < rewards.currentDay;
                final isCurrent =
                    !claimed && day == rewards.nextClaimDay;
                final isSpecial = reward.type != RewardType.tokens;

                return _buildRewardDay(
                  day: day,
                  reward: reward,
                  claimed: isClaimed ||
                      (day == rewards.currentDay && claimed),
                  current: isCurrent,
                  special: isSpecial,
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),

            if (claimed && rewards.currentDay < 7)
              Text(
                'Come back tomorrow for ${rewardSchedule[rewards.currentDay].label}',
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
                'Check in to claim today\'s reward',
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
                  const Icon(Icons.ac_unit,
                      color: Color(0xFF60A5FA), size: 14),
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
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0);
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
      icon = _rewardIcon(reward, AppColors.textTertiaryLight.withValues(alpha: 0.5));
    }

    Widget circle = Container(
      width: 38,
      height: 38,
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
          reward.label.length > 6
              ? reward.label.replaceAll(' ', '\n')
              : reward.label,
          style: AppTypography.labelSmall.copyWith(
            color: claimed
                ? AppColors.textSecondaryLight
                : current
                    ? AppColors.primary
                    : AppColors.textTertiaryLight,
            fontSize: 8,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _rewardIcon(DayReward reward, Color color) {
    switch (reward.icon) {
      case 'freeze':
        return const Icon(Icons.ac_unit, size: 15, color: Color(0xFF60A5FA));
      case 'card':
        return const Icon(Icons.style, size: 15, color: Color(0xFF7C3AED));
      case 'star':
        return const Icon(Icons.star_rounded, size: 16, color: AppColors.secondary);
      case 'token':
        return Icon(Icons.toll, size: 15, color: color);
      default:
        return Icon(Icons.toll, size: 15, color: color);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Daily Practice Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDailyPracticeCard(
    DailyLoopState state,
    DailyLoopNotifier notifier,
  ) {
    // Loading states
    if (state.checkinLoading || state.reflectLoading) {
      return _buildLoadingCard(state);
    }

    // Completed
    if (state.currentStep == DailyLoopStep.completed) {
      return _buildCompletedCard(context, state);
    }

    // Quest
    if (state.currentStep == DailyLoopStep.quest) {
      return _buildQuestCard(state, notifier);
    }

    // Deeper reflect in progress
    if (state.currentStep == DailyLoopStep.deeper &&
        state.reflectResult != null) {
      return _buildDeeperCard(state, notifier);
    }

    // Check-in done, deeper not started
    if (state.checkinDone && state.checkinName != null) {
      return _buildCheckinResultCard(state, notifier);
    }

    // Not started
    return _buildCheckinCard(state, notifier);
  }

  // ── Progress Ring ──────────────────────────────────────────────────────────

  Widget _buildProgressRing(int filled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isFilled = i < filled;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.primary : AppColors.borderLight,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  // ── Card Shell ─────────────────────────────────────────────────────────────

  Widget _cardShell({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  // ── Not Started ────────────────────────────────────────────────────────────

  Widget _buildCheckinCard(DailyLoopState state, DailyLoopNotifier notifier) {
    final idx = state.checkinQuestionIndex;
    final answers = state.checkinAnswers;
    final CheckInQuestion question = switch (idx) {
      0 => q1,
      1 => getQ2(answers.isNotEmpty ? answers[0] : ''),
      2 => getQ3(
          answers.isNotEmpty ? answers[0] : '',
          answers.length > 1 ? answers[1] : '',
        ),
      _ => q4,
    };

    return _cardShell(
      child: Column(
        children: [
          // 4-dot progress indicator
          _buildCheckinProgress(idx),
          const SizedBox(height: AppSpacing.lg),
          // Calligraphy header only on Q1
          if (idx == 0) ...[
            Text(
              'محاسبة',
              style: AppTypography.nameOfAllahDisplay.copyWith(
                color: AppColors.secondary,
                fontSize: 40,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'MUḤĀSABAH',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiaryLight,
                letterSpacing: 3,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.dividerLight, indent: 40, endIndent: 40),
            const SizedBox(height: AppSpacing.lg),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(idx),
              children: [
                Text(
                  question.question,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ...question.options.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildOptionButton(option, notifier),
                    )),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 100.ms)
        .slideY(begin: 0.08, end: 0);
  }

  Widget _buildCheckinProgress(int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i <= currentIndex;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.borderLight,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOptionButton(String text, DailyLoopNotifier notifier) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        notifier.answerCheckin(text);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAltLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoadingCard(DailyLoopState state) {
    final message = state.checkinLoading
        ? 'Finding the right Name...'
        : 'Preparing your reflection...';

    return _cardShell(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRippleRing(60, 0.ms),
                _buildRippleRing(45, 200.ms),
                _buildRippleRing(30, 400.ms),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildRippleRing(double size, Duration delay) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 0.8, end: 1.3, duration: 1500.ms, delay: delay)
        .fadeOut(duration: 1500.ms, delay: delay);
  }

  // ── Check-in Result ────────────────────────────────────────────────────────

  Widget _buildCheckinResultCard(
    DailyLoopState state,
    DailyLoopNotifier notifier,
  ) {
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressRing(1)),
          const SizedBox(height: AppSpacing.lg),

          // New card discovered banner
          if (state.cardEngageResult != null && state.cardEngageResult!.tierChanged && state.engagedCard != null) ...[
            _buildNewCardBanner(state.engagedCard!, state.cardEngageResult!),
            const SizedBox(height: AppSpacing.md),
          ],

          // Name pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.checkinName} ${state.checkinNameArabic ?? ''}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Teaching — clamped so Go Deeper stays visible
          if (state.checkinTeaching != null)
            Text(
              state.checkinTeaching!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Go Deeper button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.startDeeper();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(
                'Go Deeper',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Skip to Quest
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.skipToQuest();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Skip to Dua Quest',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Deeper Reflect ─────────────────────────────────────────────────────────

  Widget _buildDeeperCard(DailyLoopState state, DailyLoopNotifier notifier) {
    final result = state.reflectResult!;
    final step = state.reflectStep;

    // Each step: scrollable text block + pinned action button below
    final (Widget content, String buttonLabel, VoidCallback onButton) = switch (step) {
      0 => (
          _deeperNameContent(result),
          'See Reflection',
          () { HapticFeedback.lightImpact(); notifier.advanceReflectStep(); },
        ),
      1 => (
          _deeperTextContent(result.reframe),
          'Read the Story',
          () { HapticFeedback.lightImpact(); notifier.advanceReflectStep(); },
        ),
      2 => (
          _deeperTextContent(result.story),
          'See the Dua',
          () { HapticFeedback.lightImpact(); notifier.advanceReflectStep(); },
        ),
      _ => (
          _deeperDuaContent(result),
          'Continue to Quest',
          () { HapticFeedback.lightImpact(); notifier.advanceReflectStep(); },
        ),
    };

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressRing(2)),
          const SizedBox(height: AppSpacing.lg),

          // Scrollable content — max 280px so button always shows
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildActionButton(buttonLabel, onButton),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _deeperNameContent(ReflectResponse result) {
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
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.name,
            style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _deeperTextContent(String text) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondaryLight,
        height: 1.7,
      ),
    );
  }

  Widget _deeperDuaContent(ReflectResponse result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            result.duaArabic,
            style: AppTypography.quranArabic.copyWith(color: AppColors.secondary),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          result.duaTransliteration,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondaryLight,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.duaTranslation,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          result.duaSource,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiaryLight),
        ),
      ],
    );
  }

  // ── Quest ──────────────────────────────────────────────────────────────────

  Widget _buildQuestCard(DailyLoopState state, DailyLoopNotifier notifier) {
    final dua = state.questDua;
    if (dua == null) return const SizedBox.shrink();

    final int filled = state.deeperDone ? 2 : 2;

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildProgressRing(filled)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Your Dua Quest',
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quest dua card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAltLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    dua.arabic,
                    style: AppTypography.quranArabic.copyWith(
                      color: AppColors.secondary,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  dua.transliteration,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  dua.translation,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  dua.source,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Reason text
          if (dua.whenToRecite != null)
            Text(
              dua.whenToRecite!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Ameen button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.completeQuest();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(
                'Ameen',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
  }

  // ── Completed ──────────────────────────────────────────────────────────────

  Widget _buildCompletedCard(BuildContext context, DailyLoopState state) {
    return _cardShell(
      child: Column(
        children: [
          _buildProgressRing(3),
          const SizedBox(height: AppSpacing.xl),

          // Checkmark circle
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Muḥāsabah Complete',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "You've reflected, gone deeper, and completed your dua quest today.",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Streak flame
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppColors.streakAmber,
                size: 24,
              ),
              const SizedBox(width: 6),
              Text(
                '${state.streakCount} day streak',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // XP + Tokens summary
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.xpTotal} XP',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.toll, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '+${tokenRewardDeeperReflection + tokenRewardQuestComplete} tokens earned',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/reflect');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'Reflect More',
                          style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go('/duas');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'Build a Dua',
                          style: AppTypography.labelMedium.copyWith(
                              color: AppColors.secondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/quests');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            color: Color(0xFF7C3AED), size: 20),
                        const SizedBox(height: 4),
                        Text(
                          'Quests',
                          style: AppTypography.labelMedium.copyWith(
                              color: const Color(0xFF7C3AED)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Come back tomorrow',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 100.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. Today's Name of Allah
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTodaysNameCard(AllahName name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
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
          Text(
            "Today's Name",
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.secondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name.arabic,
            style: AppTypography.nameOfAllahDisplay.copyWith(
              color: AppColors.secondary,
              fontSize: 40,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${name.transliteration} — ${name.english}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name.lesson,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.08, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. Discovery Quiz CTA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoveryQuizCta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Discover your anchor Names',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              GoRouter.of(context).push('/discovery-quiz');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Text(
                'Start Quiz',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Full-Screen Name Reveal
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFullScreenReveal(DailyLoopState state) {
    final engageResult = state.cardEngageResult;
    final engagedCard = state.engagedCard;

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => NameRevealOverlay(
          nameArabic: state.checkinNameArabic ?? '',
          nameEnglish: state.checkinName ?? '',
          nameEnglishMeaning: engagedCard?.english ?? '',
          teaching: engagedCard?.lesson ?? '',
          card: engagedCard,
          engageResult: engageResult,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // New Card Banner
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNewCardBanner(CollectibleName card, CardEngageResult result) {
    final tierColor = Color(result.tier.colorValue);
    final title = result.isNew ? 'New Card Discovered!' : '${result.tier.label} Tier Unlocked!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.12),
            AppColors.streakBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: tierColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${card.transliteration} — ${result.tier.label}',
                  style: AppTypography.bodySmall.copyWith(
                    color: tierColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/collection');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'View',
                style: AppTypography.labelSmall.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .shimmer(duration: 1200.ms, color: tierColor.withValues(alpha: 0.15));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButton(String label, VoidCallback onTap) {
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
}

// (NameRevealOverlay lives in features/daily/widgets/name_reveal_overlay.dart)

// ─────────────────────────────────────────────────────────────────────────────
// Daily Quest Strip — compact 3-dot progress shown on home screen
// ─────────────────────────────────────────────────────────────────────────────

class _DailyQuestStrip extends ConsumerWidget {
  const _DailyQuestStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider);
    if (!quests.loaded || quests.daily.isEmpty) return const SizedBox.shrink();

    final daily = quests.daily;
    final completedCount = quests.dailyCompletedCount;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/quests');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Quests',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completedCount of ${daily.length} completed',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // 3 dots
            Row(
              children: List.generate(daily.length, (i) {
                final done = quests.isCompleted(daily[i].id);
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: done ? AppColors.primary : AppColors.borderLight,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiaryLight,
              size: 18,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0);
  }
}
