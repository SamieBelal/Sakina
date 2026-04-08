import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/widgets/reflect_loading.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:sakina/core/constants/checkin_questions.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/widgets/name_reveal_overlay.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/streak_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point — push as a full-screen opaque route
// ─────────────────────────────────────────────────────────────────────────────

class DailyLaunchOverlay extends ConsumerStatefulWidget {
  const DailyLaunchOverlay({super.key});

  @override
  ConsumerState<DailyLaunchOverlay> createState() =>
      _DailyLaunchOverlayState();
}

class _DailyLaunchOverlayState extends ConsumerState<DailyLaunchOverlay> {
  // 0 = streak greeting, 1 = reward claim, 2 = check-in
  int _step = 0;
  bool _rewardClaimed = false;
  DailyRewardClaimResult? _claimResult;
  bool _claimLoading = false;

  @override
  void initState() {
    super.initState();
    // Mark as shown so subsequent opens skip it
    markDailyLaunchShown();
    // Ensure rewards provider has fresh data before we check claimedToday
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(dailyRewardsProvider.notifier).reload();
      if (!mounted) return;
      final rewards = ref.read(dailyRewardsProvider);
      if (rewards.claimedToday) {
        setState(() => _rewardClaimed = true);
      }
    });
  }

  void _advance() {
    HapticFeedback.lightImpact();
    if (_step == 0 && _rewardClaimed) {
      // Reward already claimed — dismiss overlay
      _dismiss();
    } else if (_step == 0) {
      // Show reward claim step
      setState(() => _step = 1);
    } else {
      // After reward claim — dismiss overlay (Muhasabah is on its own screen now)
      _dismiss();
    }
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  Future<void> _claimReward() async {
    if (_claimLoading) return;
    setState(() => _claimLoading = true);
    HapticFeedback.mediumImpact();

    final result = await ref.read(dailyRewardsProvider.notifier).claim();
    if (mounted) {
      setState(() {
        _claimResult = result;
        _rewardClaimed = true;
        _claimLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: switch (_step) {
            0 => _StreakGreetingStep(key: const ValueKey(0), onContinue: _advance),
            1 => _RewardClaimStep(
                key: const ValueKey(1),
                claimed: _rewardClaimed,
                claimLoading: _claimLoading,
                claimResult: _claimResult,
                onClaim: _claimReward,
                onContinue: _advance,
              ),
            _ => _CheckInStep(key: const ValueKey(2), onDismiss: _dismiss),
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Streak Greeting
// ─────────────────────────────────────────────────────────────────────────────

class _StreakGreetingStep extends ConsumerWidget {
  const _StreakGreetingStep({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyLoopProvider);
    final streak = state.streakCount;
    final todaysName = getTodaysName();

    final greeting = _timeGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Streak flame
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.streakBackground,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.streakAmber,
              size: 44,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: 900.ms),
          const SizedBox(height: 24),

          // Streak count
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              children: [
                TextSpan(
                  text: '$streak',
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.streakAmber,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '\nday streak'),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 150.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          Text(
            greeting,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 40),

          // Today's Name teaser
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  "Today's Name",
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  todaysName.arabic,
                  style: AppTypography.nameOfAllahDisplay.copyWith(
                    color: AppColors.secondary,
                    fontSize: 36,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${todaysName.transliteration} — ${todaysName.english}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 450.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 48),

          // CTA
          _PrimaryButton(
            label: 'Begin',
            onTap: onContinue,
          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
        ],
      ),
    );
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Assalamu Alaykum. Allah is with you.';
    if (h < 17) return 'Assalamu Alaykum. Take a moment to reflect.';
    return 'Assalamu Alaykum. End the day with remembrance.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Daily Reward Claim
// ─────────────────────────────────────────────────────────────────────────────

class _RewardClaimStep extends ConsumerWidget {
  const _RewardClaimStep({
    super.key,
    required this.claimed,
    required this.claimLoading,
    required this.claimResult,
    required this.onClaim,
    required this.onContinue,
  });

  final bool claimed;
  final bool claimLoading;
  final DailyRewardClaimResult? claimResult;
  final VoidCallback onClaim;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(dailyRewardsProvider);
    final nextDay = rewards.nextClaimDay;
    final reward = rewardSchedule[nextDay - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Daily Reward',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textTertiaryLight,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),

          // 7-day strip
          _RewardStrip(rewards: rewards)
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.06, end: 0),

          const SizedBox(height: 40),

          // Today's reward highlight
          if (!claimed) ...[
            _RewardHighlight(reward: reward)
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .scaleXY(begin: 0.92, end: 1.0, duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 40),
            claimLoading
                ? const SakinaLoader()
                : _PrimaryButton(label: 'Claim Reward', onTap: onClaim)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 350.ms),
          ] else ...[
            // Post-claim celebration
            _ClaimSuccess(result: claimResult, rewards: rewards)
                .animate()
                .fadeIn(duration: 500.ms)
                .scaleXY(begin: 0.9, end: 1.0, duration: 400.ms),
            const SizedBox(height: 40),
            _PrimaryButton(label: 'Continue', onTap: onContinue)
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),
          ],
        ],
      ),
    );
  }
}

class _RewardStrip extends StatelessWidget {
  const _RewardStrip({required this.rewards});
  final DailyRewardsState rewards;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final reward = rewardSchedule[i];
        final isClaimed = rewards.claimedToday
            ? day <= rewards.currentDay
            : day < rewards.currentDay;
        final isCurrent = !rewards.claimedToday && day == rewards.nextClaimDay;
        final isSpecial = reward.type != RewardType.tokens;

        final Color border = isClaimed
            ? (isSpecial ? AppColors.secondary : AppColors.primary)
            : isCurrent
                ? AppColors.primary
                : AppColors.borderLight;
        final Color bg = isClaimed
            ? (isSpecial ? AppColors.secondaryLight : AppColors.primaryLight)
            : Colors.transparent;

        Widget circle = Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: border, width: isCurrent ? 2 : 1.5),
          ),
          child: Center(
            child: isClaimed
                ? Icon(Icons.check_rounded,
                    size: 15,
                    color: isSpecial ? AppColors.secondary : AppColors.primary)
                : _rewardIcon(reward, isCurrent ? AppColors.primary : AppColors.textTertiaryLight),
          ),
        );

        if (isCurrent) {
          circle = circle
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.1, duration: 900.ms);
        }

        return Column(
          children: [
            circle,
            const SizedBox(height: 4),
            Text(
              'D$day',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                color: isClaimed
                    ? AppColors.textSecondaryLight
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.textTertiaryLight,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _rewardIcon(DayReward reward, Color color) {
    switch (reward.icon) {
      case 'freeze':
        return const Icon(Icons.ac_unit, size: 14, color: Color(0xFF60A5FA));
      case 'card':
        return const Icon(Icons.style, size: 14, color: Color(0xFF7C3AED));
      case 'star':
        return Icon(Icons.star_rounded, size: 15, color: AppColors.secondary);
      default:
        return Icon(Icons.toll, size: 14, color: color);
    }
  }
}

class _RewardHighlight extends StatelessWidget {
  const _RewardHighlight({required this.reward});
  final DayReward reward;

  @override
  Widget build(BuildContext context) {
    final isSpecial = reward.type != RewardType.tokens;
    final color = isSpecial ? AppColors.secondary : AppColors.primary;
    final bgColor = isSpecial ? AppColors.secondaryLight : AppColors.primaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            _iconData(reward),
            color: color,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            reward.label,
            style: AppTypography.headlineLarge.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Day ${reward.day} reward',
            style: AppTypography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconData(DayReward reward) {
    switch (reward.icon) {
      case 'freeze':
        return Icons.ac_unit;
      case 'card':
        return Icons.style;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.toll;
    }
  }
}

class _ClaimSuccess extends StatelessWidget {
  const _ClaimSuccess({this.result, required this.rewards});
  final DailyRewardClaimResult? result;
  final DailyRewardsState rewards;

  @override
  Widget build(BuildContext context) {
    final day = result?.day ?? rewards.currentDay;
    final reward = rewardSchedule[(day - 1).clamp(0, 6)];
    final isSpecial = reward.type != RewardType.tokens;
    final color = isSpecial ? AppColors.secondary : AppColors.primary;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSpecial ? AppColors.secondaryLight : AppColors.primaryLight,
          ),
          child: Icon(Icons.check_rounded, color: color, size: 36),
        )
            .animate()
            .scaleXY(begin: 0.0, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text(
          'Reward Claimed!',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          reward.label,
          style: AppTypography.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        if (rewards.currentDay < 7) ...[
          const SizedBox(height: 8),
          Text(
            'Come back tomorrow for Day ${rewards.currentDay + 1}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Check-in (wraps existing loop UI inline)
// ─────────────────────────────────────────────────────────────────────────────

class _CheckInStep extends ConsumerStatefulWidget {
  const _CheckInStep({super.key, required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  ConsumerState<_CheckInStep> createState() => _CheckInStepState();
}

class _CheckInStepState extends ConsumerState<_CheckInStep> {
  bool _revealShown = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyLoopProvider);
    final notifier = ref.read(dailyLoopProvider.notifier);

    // Fire the reveal exactly once when checkinDone becomes true and loading finishes.
    if (state.checkinDone && !state.checkinLoading && !_revealShown) {
      _revealShown = true;
      // Wire quest: update monthly streak
      ref.read(questsProvider.notifier).updateMonthlyStreak(state.streakCount);
      // Check achievements (delayed to avoid during gacha reveal)
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) checkAchievements(ref);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Only show gacha overlay for new cards or tier upgrades
        if (state.cardEngageResult != null && state.cardEngageResult!.tierChanged) {
          Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder(
              opaque: true,
              barrierDismissible: false,
              pageBuilder: (_, __, ___) => NameRevealOverlay(
                nameArabic: state.engagedCard?.arabic ?? state.checkinNameArabic ?? '',
                nameEnglish: state.engagedCard?.transliteration ?? state.checkinName ?? '',
                nameEnglishMeaning: state.engagedCard?.english ?? '',
                teaching: state.engagedCard?.lesson ?? '',
                card: state.engagedCard,
                engageResult: state.cardEngageResult,
                onContinue: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  widget.onDismiss();
                },
              ),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        } else {
          // No new card / tier change — skip overlay, go straight to home
          widget.onDismiss();
        }
      });
    }

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 4-dot progress
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i <= idx && !state.checkinLoading;
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
          ),
          const SizedBox(height: 32),

          if (state.checkinLoading)
            const ReflectLoading().animate().fadeIn(duration: 300.ms)
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
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
                  const SizedBox(height: 28),
                  ...question.options.map((option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            notifier.answerCheckin(option);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              option,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),

          if (!state.checkinLoading) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onDismiss,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Skip for now',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared — Primary button
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
