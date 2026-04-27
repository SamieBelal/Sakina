import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/core/utils/invalidate_providers.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/widgets/level_up_overlay.dart';
import 'package:sakina/services/achievement_checker.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/dev_tools_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/widgets/subpage_header.dart';

class DevToolsScreen extends ConsumerStatefulWidget {
  const DevToolsScreen({super.key});

  @override
  ConsumerState<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends ConsumerState<DevToolsScreen> {
  int _tokens = 0;
  int _xp = 0;
  int _level = 1;
  String _title = 'Seeker';
  int _scrolls = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _dailyRewardDay = 0;
  int _achievementsUnlocked = 0;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final tokenState = await getTokens();
    final xpState = await getXp();
    final scrollState = await getTierUpScrolls();
    final streakState = await getStreak();
    final dailyState = await getDailyRewards();
    final achievements = await getUnlockedAchievements();

    if (!mounted) return;
    setState(() {
      _tokens = tokenState.balance;
      _xp = xpState.totalXp;
      _level = xpState.level;
      _title = xpState.title;
      _scrolls = scrollState.balance;
      _currentStreak = streakState.currentStreak;
      _longestStreak = streakState.longestStreak;
      _dailyRewardDay = dailyState.currentDay;
      _achievementsUnlocked = achievements.length;
      _loading = false;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      invalidateAllUserProviders(ref);
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Award XP through the real flow, showing level-up overlay if triggered.
  Future<void> _awardXpWithOverlay(int amount) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await awardXp(amount);
      invalidateAllUserProviders(ref);
      await _refresh();
      if (result.leveledUp && result.rewards != null && mounted) {
        await _showLevelUpOverlay(result);
      }
      if (mounted) checkAchievements(ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Jump to a target XP, awarding the delta through the real flow.
  Future<void> _jumpToXp(int targetXp) async {
    if (targetXp <= _xp) {
      // Going down — use raw set (no rewards for going backwards)
      await _run(() => devSetXp(targetXp));
      if (mounted) checkAchievements(ref);
      return;
    }
    await _awardXpWithOverlay(targetXp - _xp);
  }

  Future<void> _showLevelUpOverlay(XpAwardResult result) async {
    final nav = Navigator.of(context, rootNavigator: true);
    await nav.push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => LevelUpOverlay(
          levelNumber: result.state.level,
          title: result.state.title,
          titleArabic: result.state.titleArabic,
          rewards: result.rewards,
          onContinue: () => nav.pop(),
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.lg,
                  AppSpacing.pagePadding,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SubpageHeader(
                      title: 'Dev Tools',
                      subtitle: 'Debug mode — manipulate app state for testing.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildOverviewCard(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection('Tokens', _buildTokenButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('XP / Level', _buildXpButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('Scrolls', _buildScrollButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('Streak', _buildStreakButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('Daily Rewards', _buildDailyRewardButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('Quests', _buildQuestButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('Achievements', _buildAchievementButtons()),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSection('Toast Previews', _buildToastPreviewButtons()),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection('Nuclear Options', _buildNuclearButtons()),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Overview
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _overviewItem('Tokens', '$_tokens'),
              _overviewItem('XP', '$_xp'),
              _overviewItem('Level', '$_level'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _overviewItem('Title', _title),
              _overviewItem('Scrolls', '$_scrolls'),
              _overviewItem('Streak', '$_currentStreak/$_longestStreak'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _overviewItem('Daily Day', '$_dailyRewardDay/7'),
              _overviewItem(
                  'Achievements', '$_achievementsUnlocked/${allAchievements.length}'),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sections
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.borderLight, width: 0.5),
          ),
          child: content,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tokens
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTokenButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('+50', () => _run(() => devSetTokens(_tokens + 50))),
        _actionChip('+100', () => _run(() => devSetTokens(_tokens + 100))),
        _actionChip('+500', () => _run(() => devSetTokens(_tokens + 500))),
        _actionChip('Set 0', () => _run(() => devSetTokens(0)),
            destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // XP / Level
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildXpButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('+100 XP', () => _awardXpWithOverlay(100)),
        _actionChip('L5 (375)', () => _jumpToXp(375)),
        _actionChip('L10 (995)', () => _jumpToXp(995)),
        _actionChip('L15 (2495)', () => _jumpToXp(2495)),
        _actionChip('L25 (12195)', () => _jumpToXp(12195)),
        _actionChip('Set 0', () => _run(() => devSetXp(0)), destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Scrolls
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildScrollButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('+10', () => _run(() => devSetScrolls(_scrolls + 10))),
        _actionChip('+50', () => _run(() => devSetScrolls(_scrolls + 50))),
        _actionChip('Set 0', () => _run(() => devSetScrolls(0)),
            destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Streak
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStreakButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('Set 7', () => _run(() => devSetStreak(7, 7))),
        _actionChip('Set 30', () => _run(() => devSetStreak(30, 30))),
        _actionChip('Set 90', () => _run(() => devSetStreak(90, 90))),
        _actionChip('Set 365', () => _run(() => devSetStreak(365, 365))),
        _actionChip('Reset', () => _run(() => devSetStreak(0, 0)),
            destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Daily Rewards
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDailyRewardButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('Advance Day',
            () => _run(() => devAdvanceDailyRewardDay((_dailyRewardDay % 7) + 1))),
        _actionChip('Reset Cycle', () => _run(devResetDailyRewards),
            destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quests
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuestButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip(
            'Reset Progress', () => _run(devResetQuestProgress),
            destructive: true),
        _actionChip(
            'Reset First Steps', () => _run(devResetFirstSteps),
            destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Achievements
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAchievementButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('Unlock All', () => _run(devUnlockAllAchievements)),
        _actionChip('Reset All', () => _run(devResetAchievements),
            destructive: true),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Toast Previews
  // ─────────────────────────────────────────────────────────────────────────

  void _previewToast(Widget Function(VoidCallback onDismissed) builder) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => builder(() => entry.remove()),
    );
    overlay.insert(entry);
  }

  Widget _buildToastPreviewButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionChip('Achievement', () {
          _previewToast((onDismissed) => _PreviewAchievementToast(
                achievement: allAchievements.first,
                onDismissed: onDismissed,
              ));
        }),
        _actionChip('Quest Complete', () {
          _previewToast((onDismissed) => _PreviewQuestToast(
                quest: const Quest(
                  id: 'preview_quest',
                  title: 'Complete a Reflection',
                  description: 'Preview quest',
                  icon: Icons.auto_stories_rounded,
                  cadence: QuestCadence.daily,
                  xpReward: 15,
                  tokenReward: 5,
                  poolIndex: 0,
                ),
                onDismissed: onDismissed,
              ));
        }),
        _actionChip('Quest w/ Scrolls', () {
          _previewToast((onDismissed) => _PreviewQuestToast(
                quest: const Quest(
                  id: 'preview_quest_scrolls',
                  title: 'Discover 3 Names',
                  description: 'Preview quest',
                  icon: Icons.grid_view_rounded,
                  cadence: QuestCadence.weekly,
                  xpReward: 40,
                  tokenReward: 3,
                  scrollReward: 2,
                  poolIndex: 0,
                ),
                onDismissed: onDismissed,
              ));
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Nuclear Options
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNuclearButtons() {
    return Column(
      children: [
        _fullWidthButton(
          'Soft Reset (keep account)',
          () => _run(devSoftResetAll),
          destructive: true,
        ),
        const SizedBox(height: 8),
        _fullWidthButton(
          'Re-Hydrate from Supabase',
          () => _run(devRehydrateFromSupabase),
        ),
        const SizedBox(height: 8),
        _fullWidthButton(
          'Reset Daily Loop',
          () => _run(() async {
            await ref.read(dailyLoopProvider.notifier).resetToday();
            await resetDailyLaunchGate();
          }),
          destructive: true,
        ),
        const SizedBox(height: 8),
        _fullWidthButton(
          'Clear Card Collection',
          () => _run(() async {
            await clearCardCollection();
            await ref.read(dailyLoopProvider.notifier).resetToday();
            await resetDailyLaunchGate();
          }),
          destructive: true,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _actionChip(String label, VoidCallback onTap,
      {bool destructive = false}) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.errorBackground
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: destructive ? AppColors.error.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: destructive ? AppColors.error : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _fullWidthButton(String label, VoidCallback onTap,
      {bool destructive = false}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              destructive ? AppColors.error : AppColors.textPrimaryLight,
          side: BorderSide(
            color: destructive ? AppColors.error.withValues(alpha: 0.3) : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: AppTypography.labelMedium),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview toast widgets (rendered in the local overlay so they appear
// on top of the Dev Tools screen, unlike the real toasts which use
// rootNavigatorKey's overlay)
// ---------------------------------------------------------------------------

class _PreviewAchievementToast extends StatefulWidget {
  const _PreviewAchievementToast({
    required this.achievement,
    required this.onDismissed,
  });

  final Achievement achievement;
  final VoidCallback onDismissed;

  @override
  State<_PreviewAchievementToast> createState() =>
      _PreviewAchievementToastState();
}

class _PreviewAchievementToastState extends State<_PreviewAchievementToast> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onDismissed();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottomPadding + 80,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 1.5),
          duration: const Duration(milliseconds: 400),
          curve: _visible ? Curves.easeOutBack : Curves.easeIn,
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color:
                        widget.achievement.color.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.achievement.color
                          .withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.achievement.color
                            .withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: widget.achievement.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Achievement Unlocked',
                            style: AppTypography.labelSmall.copyWith(
                              color: widget.achievement.color,
                              letterSpacing: 1,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.achievement.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      color: widget.achievement.color
                          .withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewQuestToast extends StatefulWidget {
  const _PreviewQuestToast({
    required this.quest,
    required this.onDismissed,
  });

  final Quest quest;
  final VoidCallback onDismissed;

  @override
  State<_PreviewQuestToast> createState() => _PreviewQuestToastState();
}

class _PreviewQuestToastState extends State<_PreviewQuestToast> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onDismissed();
      });
    });
  }

  String _rewardText() {
    final parts = <String>[];
    if (widget.quest.xpReward > 0) parts.add('+${widget.quest.xpReward} XP');
    if (widget.quest.tokenReward > 0) {
      parts.add('+${widget.quest.tokenReward} Tokens');
    }
    if (widget.quest.scrollReward > 0) {
      parts.add('+${widget.quest.scrollReward} Scrolls');
    }
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottomPadding + 80,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, 1.5),
          duration: const Duration(milliseconds: 400),
          curve: _visible ? Curves.easeOutBack : Curves.easeIn,
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'QUEST COMPLETE',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.quest.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_rewardText().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _rewardText(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.secondary.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
