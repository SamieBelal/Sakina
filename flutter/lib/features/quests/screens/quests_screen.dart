import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/token_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:sakina/widgets/subpage_header.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  AppSessionNotifier? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = ref.read(appSessionProvider);
      _session = session;
      // Reload now in case hydration finished before this screen mounted,
      // then recompute threshold progress from current data sources.
      ref.read(questsProvider.notifier).reload();
      recomputeQuestProgress(ref);
      if (!session.economyHydrated) {
        session.addListener(_onSessionChange);
      }
    });
  }

  void _onSessionChange() {
    if (!mounted) {
      _session?.removeListener(_onSessionChange);
      return;
    }
    final session = _session;
    if (session != null && session.economyHydrated) {
      session.removeListener(_onSessionChange);
      ref.read(questsProvider.notifier).reload();
      recomputeQuestProgress(ref);
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questsProvider);
    final tokenState = ref.watch(tokenProvider);

    // Bundle celebration listener is in AppShell so it fires from any tab.

    if (!state.loaded) {
      return SakinaLoader.fullScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SubpageHeader(
                      title: 'Quests',
                      subtitle: 'Complete quests to earn XP and tokens.',
                      trailing: _TokenChip(balance: tokenState.balance),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Daily progress bar
                    _DailyProgressBar(state: state),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),

            // ── First Steps (one-time, new users only) ──────────────────────
            if (state.showFirstSteps) ...[
              const _FirstStepsHeader(),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final quest = beginnerQuests[i];
                    return _FirstStepsCard(
                      quest: quest,
                      completed: state.isBeginnerCompleted(quest.id),
                      delay: i * 60,
                    );
                  },
                  childCount: beginnerQuests.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],

            // ── Daily ────────────────────────────────────────────────────────
            const _SectionHeader(label: 'Daily', sublabel: 'Resets at midnight'),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _QuestCard(
                  quest: state.daily[i],
                  completed: state.isCompleted(state.daily[i].id),
                  progress: state.getProgress(state.daily[i].id),
                  delay: i * 60,
                ),
                childCount: state.daily.length,
              ),
            ),

            // ── Weekly ───────────────────────────────────────────────────────
            const _SectionHeader(label: 'Weekly', sublabel: 'Resets on Monday'),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _QuestCard(
                  quest: state.weekly[i],
                  completed: state.isCompleted(state.weekly[i].id),
                  progress: state.getProgress(state.weekly[i].id),
                  delay: (state.daily.length + i) * 60,
                ),
                childCount: state.weekly.length,
              ),
            ),

            // ── Monthly ──────────────────────────────────────────────────────
            const _SectionHeader(label: 'Monthly', sublabel: 'Resets on the 1st'),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _QuestCard(
                  quest: state.monthly[i],
                  completed: state.isCompleted(state.monthly[i].id),
                  progress: state.getProgress(state.monthly[i].id),
                  delay: (state.daily.length + state.weekly.length + i) * 60,
                ),
                childCount: state.monthly.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token chip
// ─────────────────────────────────────────────────────────────────────────────

class _TokenChip extends StatelessWidget {
  const _TokenChip({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll_rounded, color: AppColors.secondary, size: 16),
          const SizedBox(width: 6),
          Text(
            '$balance',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _DailyProgressBar extends StatelessWidget {
  const _DailyProgressBar({required this.state});
  final QuestsState state;

  @override
  Widget build(BuildContext context) {
    final completed = state.dailyCompletedCount;
    final total = state.daily.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Progress',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            Text(
              '$completed / $total',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header sliver
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.sublabel});
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          8,
          AppSpacing.pagePadding,
          8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              sublabel,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quest card
// ─────────────────────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.completed,
    this.delay = 0,
    this.progress = 0,
  });

  final Quest quest;
  final bool completed;
  final int delay;
  final int progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        12,
      ),
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: completed ? AppColors.surfaceAltLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: completed
                  ? AppColors.borderLight
                  : AppColors.borderLight,
            ),
            boxShadow: completed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.borderLight
                      : _iconBg(quest.cadence),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : quest.icon,
                  color: completed
                      ? AppColors.textTertiaryLight
                      : _iconColor(quest.cadence),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: completed
                            ? AppColors.textTertiaryLight
                            : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quest.target > 0 && !completed) ...[
                      const SizedBox(height: 8),
                      _QuestProgressBar(
                        current: progress,
                        target: quest.target,
                        color: _iconColor(quest.cadence),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Rewards column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _RewardBadge(
                    icon: Icons.bolt_rounded,
                    value: '+${quest.xpReward} XP',
                    color: AppColors.primary,
                    done: completed,
                  ),
                  if (quest.tokenReward > 0) ...[
                    const SizedBox(height: 4),
                    _RewardBadge(
                      icon: Icons.toll_rounded,
                      value: '+${quest.tokenReward}',
                      color: AppColors.secondary,
                      done: completed,
                    ),
                  ],
                  if (quest.scrollReward > 0) ...[
                    const SizedBox(height: 4),
                    _RewardBadge(
                      icon: Icons.receipt_long,
                      value: '+${quest.scrollReward}',
                      color: const Color(0xFF3B82F6),
                      done: completed,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: delay.ms)
        .slideY(begin: 0.06, end: 0, duration: 350.ms, delay: delay.ms);
  }

  Color _iconBg(QuestCadence cadence) {
    switch (cadence) {
      case QuestCadence.daily:
        return AppColors.primaryLight;
      case QuestCadence.weekly:
        return AppColors.secondaryLight;
      case QuestCadence.monthly:
        return const Color(0xFFEDE9FE); // soft purple
    }
  }

  Color _iconColor(QuestCadence cadence) {
    switch (cadence) {
      case QuestCadence.daily:
        return AppColors.primary;
      case QuestCadence.weekly:
        return AppColors.secondary;
      case QuestCadence.monthly:
        return const Color(0xFF7C3AED);
    }
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.icon,
    required this.value,
    required this.color,
    required this.done,
  });
  final IconData icon;
  final String value;
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = done ? AppColors.textTertiaryLight : color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: effectiveColor, size: 13),
        const SizedBox(width: 2),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quest progress bar for threshold quests
// ─────────────────────────────────────────────────────────────────────────────

class _QuestProgressBar extends StatelessWidget {
  const _QuestProgressBar({
    required this.current,
    required this.target,
    required this.color,
  });

  final int current;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = current.clamp(0, target);
    final progress = target > 0 ? clamped / target : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$clamped / $target',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// First Steps section (one-time beginner quests)
// ─────────────────────────────────────────────────────────────────────────────

class _FirstStepsHeader extends StatelessWidget {
  const _FirstStepsHeader();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          8,
          AppSpacing.pagePadding,
          12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'First Steps',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Learn the basics — disappears once complete',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstStepsCard extends StatelessWidget {
  const _FirstStepsCard({
    required this.quest,
    required this.completed,
    this.delay = 0,
  });

  final BeginnerQuest quest;
  final bool completed;
  final int delay;

  void _handleTap(BuildContext context) {
    if (completed) return;
    HapticFeedback.lightImpact();
    GoRouter.of(context).go(quest.route);
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: completed
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondaryLight,
                  AppColors.surfaceLight,
                ],
              ),
        color: completed ? AppColors.surfaceAltLight : null,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: completed
              ? AppColors.borderLight
              : AppColors.secondary.withValues(alpha: 0.35),
          width: completed ? 1 : 1.5,
        ),
        boxShadow: completed
            ? null
            : [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.borderLight
                  : AppColors.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              completed ? Icons.check_rounded : quest.icon,
              color: completed
                  ? AppColors.textTertiaryLight
                  : AppColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: completed
                        ? AppColors.textTertiaryLight
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quest.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Rewards column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RewardBadge(
                icon: Icons.bolt_rounded,
                value: '+${quest.xpReward} XP',
                color: AppColors.primary,
                done: completed,
              ),
              const SizedBox(height: 4),
              _RewardBadge(
                icon: Icons.toll_rounded,
                value: '+${quest.tokenReward}',
                color: AppColors.secondary,
                done: completed,
              ),
              const SizedBox(height: 4),
              _RewardBadge(
                icon: Icons.receipt_long,
                value: '+${quest.scrollReward}',
                color: const Color(0xFF3B82F6),
                done: completed,
              ),
            ],
          ),
          // Chevron hint that the card is tappable
          if (!completed) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondary.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        12,
      ),
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: completed ? null : () => _handleTap(context),
          child: card,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: delay.ms)
        .slideY(begin: 0.06, end: 0, duration: 350.ms, delay: delay.ms);
  }
}
