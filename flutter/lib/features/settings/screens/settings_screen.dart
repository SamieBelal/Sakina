import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/streak_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  XpState? _xpState;
  StreakState? _streakState;
  List<String> _anchorNames = [];
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final xp = await getXp();
    final streak = await getStreak();

    final prefs = await SharedPreferences.getInstance();
    final anchorsJson = prefs.getString('anchor_names');
    List<String> anchors = [];
    if (anchorsJson != null) {
      try {
        final decoded = json.decode(anchorsJson);
        if (decoded is List) {
          anchors = decoded.map((item) {
            if (item is String) return item;
            if (item is Map) return item['name']?.toString() ?? '';
            return item.toString();
          }).where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _xpState = xp;
      _streakState = streak;
      _anchorNames = anchors;
      _loading = false;
    });
  }


  Future<void> _resetDailyLoop() async {
    await ref.read(dailyLoopProvider.notifier).resetToday();
    await resetDailyLaunchGate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily loop reset. Go back to Home to start fresh.')),
      );
    }
  }

  Future<void> _resetCardCollection() async {
    await clearCardCollection();
    await ref.read(dailyLoopProvider.notifier).resetToday();
    await resetDailyLaunchGate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card collection wiped. Every check-in will now discover a new card.')),
      );
    }
  }

  Future<void> _resetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text(
            'This will reset your onboarding progress. You will see the onboarding screens again next time you open the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Onboarding reset')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete all your local data including streaks, XP, saved reflections, and preferences. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Clear All', style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAnchorNamesSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSettingsList(),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppColors.surfaceAltLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Guest',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign up to save your progress',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final streak = _streakState?.currentStreak ?? 0;
    final xp = _xpState?.totalXp ?? 0;
    final level = _xpState?.title ?? 'Seeker';

    return Row(
      children: [
        Expanded(child: _buildStatCard('🔥', '$streak', 'Day Streak')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildStatCard('✦', '$xp', 'Total XP')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildStatCard('◈', level, 'Level')),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorNamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Anchor Names',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_anchorNames.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.borderLight, width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  'Take the quiz to discover your anchor Names',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: navigate to quiz
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                    ),
                    child: Text('Take the Quiz',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.textOnPrimary)),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _anchorNames.map((name) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSettingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account
        _buildSectionLabel('Account'),
        const SizedBox(height: AppSpacing.sm),
        _buildSettingsCard([
          _buildSettingsRow(
            icon: Icons.login_rounded,
            label: 'Sign In / Sign Up',
            onTap: () {
              // TODO: navigate to auth
            },
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),

        // Preferences
        _buildSectionLabel('Preferences'),
        const SizedBox(height: AppSpacing.sm),
        _buildSettingsCard([
          _buildToggleRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() => _notificationsEnabled = val);
            },
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),

        // About
        _buildSectionLabel('About'),
        const SizedBox(height: AppSpacing.sm),
        _buildSettingsCard([
          _buildSettingsRow(
            icon: Icons.info_outline_rounded,
            label: 'Version 1.0.0',
            showChevron: false,
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {
              // TODO: open privacy policy
            },
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {
              // TODO: open terms
            },
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),

        // Danger Zone
        _buildSectionLabel('Danger Zone'),
        const SizedBox(height: AppSpacing.sm),
        _buildSettingsCard([
          _buildSettingsRow(
            icon: Icons.replay_rounded,
            label: 'Reset Daily Loop',
            onTap: _resetDailyLoop,
            isDestructive: true,
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.style_outlined,
            label: 'Clear Card Collection',
            onTap: _resetCardCollection,
            isDestructive: true,
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.refresh_rounded,
            label: 'Reset Onboarding',
            onTap: _resetOnboarding,
            isDestructive: true,
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.delete_outline_rounded,
            label: 'Clear All Data',
            onTap: _clearAllData,
            isDestructive: true,
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool showChevron = true,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? AppColors.error : AppColors.textPrimaryLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: color),
              ),
            ),
            if (showChevron && onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimaryLight),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.dividerLight,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
    );
  }
}
