import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/collection/providers/card_collection_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_question_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/providers/token_provider.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:sakina/widgets/subpage_header.dart';
import 'package:sakina/widgets/summary_metric_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  XpState? _xpState;
  StreakState? _streakState;
  List<String> _anchorNames = [];
  List<String> _unlockedTitles = [];
  String _displayTitle = 'Seeker';
  String _displayTitleArabic = 'طَالِب';
  bool _isAutoTitle = true;
  bool _pushNotificationsEnabled = false;
  bool _dailyReminderEnabled = true;
  bool _streakReminderEnabled = true;
  bool _reengagementEnabled = true;
  bool _weeklyReflectionEnabled = true;
  bool _newContentEnabled = true;
  bool _notificationsBusy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final xp = await getXp();
    final streak = await getStreak();
    final displayTitle = await getDisplayTitle(xp.level);
    final unlockedTitles = getUnlockedTitles(
      currentLevel: xp.level,
      longestStreak: streak.longestStreak,
    );

    final anchors = await loadSavedDiscoveryQuizAnchorNames();
    final notificationService = ref.read(notificationServiceProvider);
    final notificationPreferences =
        await notificationService.getNotificationPreferences();

    if (!mounted) return;
    setState(() {
      _xpState = xp;
      _streakState = streak;
      _anchorNames = anchors;
      _unlockedTitles = unlockedTitles;
      _displayTitle = displayTitle.title;
      _displayTitleArabic = displayTitle.titleArabic;
      _isAutoTitle = displayTitle.isAuto;
      _pushNotificationsEnabled = notificationService.isOptedIn;
      _dailyReminderEnabled =
          notificationPreferences[notifyDailyTagKey] ?? true;
      _streakReminderEnabled =
          notificationPreferences[notifyStreakTagKey] ?? true;
      _reengagementEnabled =
          notificationPreferences[notifyReengagementTagKey] ?? true;
      _weeklyReflectionEnabled =
          notificationPreferences[notifyWeeklyTagKey] ?? true;
      _newContentEnabled = notificationPreferences[notifyUpdatesTagKey] ?? true;
      _loading = false;
    });
  }

  Future<void> _setPushNotificationsEnabled(bool enabled) async {
    if (_notificationsBusy) return;

    final notificationService = ref.read(notificationServiceProvider);
    setState(() => _notificationsBusy = true);

    bool isOptedIn;
    if (enabled) {
      isOptedIn = await notificationService.optIn();
    } else {
      isOptedIn = await notificationService.optOut();
    }

    if (!mounted) return;
    setState(() {
      _pushNotificationsEnabled = isOptedIn;
      _notificationsBusy = false;
    });
  }

  Future<void> _setNotificationPreference(String key, bool enabled) async {
    if (_notificationsBusy) return;

    setState(() => _notificationsBusy = true);
    await ref
        .read(notificationServiceProvider)
        .setNotificationPreference(key, enabled);

    if (!mounted) return;
    setState(() {
      if (key == notifyDailyTagKey) {
        _dailyReminderEnabled = enabled;
      } else if (key == notifyStreakTagKey) {
        _streakReminderEnabled = enabled;
      } else if (key == notifyReengagementTagKey) {
        _reengagementEnabled = enabled;
      } else if (key == notifyWeeklyTagKey) {
        _weeklyReflectionEnabled = enabled;
      } else if (key == notifyUpdatesTagKey) {
        _newContentEnabled = enabled;
      }
      _notificationsBusy = false;
    });
  }

  void _invalidateAllUserProviders(WidgetRef ref) {
    ref.invalidate(reflectProvider);
    ref.invalidate(duasProvider);
    ref.invalidate(cardCollectionProvider);
    ref.invalidate(dailyRewardsProvider);
    ref.invalidate(questsProvider);
    ref.invalidate(dailyLoopProvider);
    ref.invalidate(tokenProvider);
    ref.invalidate(tierUpScrollProvider);
    ref.invalidate(discoveryQuizProvider);
    ref.invalidate(dailyQuestionProvider);
    ref.invalidate(isPremiumProvider);
  }

  Future<void> _openDiscoveryQuiz() async {
    await context.push('/discovery-quiz');
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the page. Try again.')),
      );
    }
  }

  Future<void> _resetDailyLoop() async {
    final confirmed = await _confirmDangerAction(
      title: 'Reset Daily Loop',
      message:
          'This will clear today\'s daily loop progress so you can start fresh from Home. This cannot be undone.',
      confirmLabel: 'Reset',
    );
    if (confirmed != true) return;

    // Wipe both local AND server state so the overlay actually re-fires.
    // Previously only local was cleared, which made the next reconcile
    // re-hydrate from the stale server row. F1/F5 fix items #3 in
    // docs/qa/findings/2026-04-22-core-loop-fixes.md.
    await resetDailyRewardsOnServer();
    await ref.read(dailyLoopProvider.notifier).resetToday();
    await resetDailyLaunchGate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Daily loop reset. Go back to Home to start fresh.')),
      );
    }
  }

  Future<void> _resetCardCollection() async {
    final confirmed = await _confirmDangerAction(
      title: 'Clear Card Collection',
      message:
          'This will wipe your entire card collection and reset today\'s loop so new cards can be discovered again. This cannot be undone.',
      confirmLabel: 'Clear Collection',
    );
    if (confirmed != true) return;

    await clearCardCollection();
    await ref.read(dailyLoopProvider.notifier).resetToday();
    await resetDailyLaunchGate();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Card collection wiped. Every check-in will now discover a new card.')),
      );
    }
  }

  Future<bool?> _confirmDangerAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Step 1: Warning dialog
    final warned = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data — '
          'streaks, saved reflections, journal entries, and preferences. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Continue',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (warned != true || !mounted) return;

    // Step 2: Type DELETE to confirm
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isValid = controller.text.trim() == 'DELETE';
            return AlertDialog(
              title: const Text('Are you sure?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type DELETE to confirm account deletion.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'DELETE',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isValid ? () => Navigator.pop(ctx, true) : null,
                  child: Text(
                    'Delete My Account',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isValid
                          ? AppColors.error
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    // Don't dispose controller here — the dialog's dismiss animation may still
    // reference it when signOut() triggers a synchronous GoRouter rebuild.
    // It will be garbage collected when this method returns.
    if (confirmed != true || !mounted) return;

    // Step 3: Perform deletion
    try {
      final authService = ref.read(authServiceProvider);
      final uid = supabaseSyncService.currentUserId;
      await authService.deleteAccount();
      ref.read(onboardingProvider.notifier).reset();
      await ref.read(appSessionProvider).clearSession(userId: uid);
      _invalidateAllUserProviders(ref);
      await authService.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete account. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: SakinaLoader())
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
                      title: 'Settings',
                      subtitle:
                          'Profile, titles, preferences, and account controls.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildProfileCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTitleSelector(),
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

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  String get _displayName {
    final user = _currentUser;
    if (user == null) return 'Guest';
    final meta = user.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      return meta['full_name'] as String;
    }
    return user.email ?? 'Guest';
  }

  String get _subtitle {
    final user = _currentUser;
    if (user == null) return 'Sign up to save your progress';
    return user.email ?? '';
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAltLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final streak = _streakState?.currentStreak ?? 0;
    final xp = _xpState?.totalXp ?? 0;

    return Row(
      children: [
        Expanded(
          child: SummaryMetricCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.streakAmber,
            label: 'Day Streak',
            value: '$streak',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SummaryMetricCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.secondary,
            label: 'Total XP',
            value: '$xp',
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSelector() {
    return GestureDetector(
      onTap: _showTitlePicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Title',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiaryLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _displayTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isAutoTitle)
                    Text(
                      'Auto (follows rank)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              _displayTitleArabic,
              style: AppTypography.nameOfAllahDisplay.copyWith(
                fontSize: 28,
                color: AppColors.primary,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showTitlePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
            const SizedBox(height: 16),
            Text(
              'Choose Your Title',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Auto option
            _titleOption(
              title: 'Auto (Current Rank)',
              subtitle: 'Follows your level',
              isSelected: _isAutoTitle,
              isUnlocked: true,
              onTap: () async {
                await setAutoTitle();
                if (!sheetCtx.mounted) return;
                Navigator.of(sheetCtx).pop();
                if (!mounted) return;
                await _loadData();
              },
            ),
            const Divider(height: 24),

            // Title list — level titles + streak titles
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Level milestone titles
                  ...xpLevels.where((l) => l.unlocksTitle).map((level) {
                    final isUnlocked = _unlockedTitles.contains(level.title);
                    final isSelected =
                        !_isAutoTitle && _displayTitle == level.title;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _titleOption(
                        title: level.title,
                        titleArabic: level.titleArabic,
                        subtitle:
                            isUnlocked ? null : 'Reach Level ${level.level}',
                        isSelected: isSelected,
                        isUnlocked: isUnlocked,
                        onTap: isUnlocked
                            ? () async {
                                await selectTitle(level.title);
                                if (!sheetCtx.mounted) return;
                                Navigator.of(sheetCtx).pop();
                                if (!mounted) return;
                                await _loadData();
                              }
                            : null,
                      ),
                    );
                  }),

                  // Streak milestone titles
                  ...streakMilestones
                      .where((m) => m.titleUnlock != null)
                      .map((milestone) {
                    final isUnlocked =
                        _unlockedTitles.contains(milestone.titleUnlock!);
                    final isSelected =
                        !_isAutoTitle && _displayTitle == milestone.titleUnlock;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _titleOption(
                        title: milestone.titleUnlock!,
                        titleArabic: milestone.titleUnlockArabic,
                        subtitle:
                            isUnlocked ? null : '${milestone.days}-day streak',
                        isSelected: isSelected,
                        isUnlocked: isUnlocked,
                        onTap: isUnlocked
                            ? () async {
                                await selectTitle(milestone.titleUnlock!);
                                if (!sheetCtx.mounted) return;
                                Navigator.of(sheetCtx).pop();
                                if (!mounted) return;
                                await _loadData();
                              }
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleOption({
    required String title,
    String? titleArabic,
    String? subtitle,
    required bool isSelected,
    required bool isUnlocked,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight
              : (isUnlocked
                  ? AppColors.surfaceLight
                  : AppColors.surfaceAltLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isUnlocked
                          ? AppColors.textPrimaryLight
                          : AppColors.textTertiaryLight,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiaryLight,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (titleArabic != null)
              Text(
                titleArabic,
                style: AppTypography.nameOfAllahDisplay.copyWith(
                  fontSize: 20,
                  color: isUnlocked
                      ? AppColors.primary
                      : AppColors.textTertiaryLight.withValues(alpha: 0.5),
                ),
                textDirection: TextDirection.rtl,
              ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.primary,
              ),
            ],
            if (!isUnlocked) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textTertiaryLight,
              ),
            ],
          ],
        ),
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
                  'Take the quiz to discover your anchor names.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openDiscoveryQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
        // Store
        _buildSettingsCard([
          _buildSettingsRow(
            icon: Icons.storefront_rounded,
            label: 'Store',
            onTap: () => context.push('/store'),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),

        // Account
        _buildSectionLabel('Account'),
        const SizedBox(height: AppSpacing.sm),
        _buildSettingsCard([
          _buildSettingsRow(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Sign Out',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                try {
                  ref.read(onboardingProvider.notifier).reset();
                  await ref.read(appSessionProvider).clearSession();
                  _invalidateAllUserProviders(ref);
                  await ref.read(authServiceProvider).signOut();
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not sign out. Please try again.'),
                    ),
                  );
                }
              }
            },
            isDestructive: true,
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),

        // Preferences
        _buildSectionLabel('Preferences'),
        const SizedBox(height: AppSpacing.sm),
        _buildNotificationsCard(),
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
            onTap: () => _openLegalUrl(AppStrings.privacyPolicyUrl),
          ),
          _buildDivider(),
          _buildSettingsRow(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () => _openLegalUrl(AppStrings.termsOfServiceUrl),
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
            icon: Icons.delete_forever_rounded,
            label: 'Delete Account',
            onTap: _deleteAccount,
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
    final color = isDestructive ? AppColors.error : AppColors.textPrimaryLight;

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
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final labelColor = onChanged == null
        ? AppColors.textTertiaryLight
        : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: labelColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(color: labelColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final subTogglesEnabled = _pushNotificationsEnabled && !_notificationsBusy;

    return _buildSettingsCard([
      _buildToggleRow(
        icon: Icons.notifications_outlined,
        label: 'Push Notifications',
        value: _pushNotificationsEnabled,
        onChanged: _notificationsBusy ? null : _setPushNotificationsEnabled,
      ),
      _buildDivider(),
      _buildToggleRow(
        icon: Icons.wb_sunny_outlined,
        label: 'Daily Reminder',
        subtitle: 'Check-in, rewards & quests',
        value: _dailyReminderEnabled,
        onChanged: subTogglesEnabled
            ? (value) => _setNotificationPreference(
                  notifyDailyTagKey,
                  value,
                )
            : null,
      ),
      _buildDivider(),
      _buildToggleRow(
        icon: Icons.local_fire_department_outlined,
        label: 'Streak Reminders',
        subtitle: 'At-risk alerts & milestones',
        value: _streakReminderEnabled,
        onChanged: subTogglesEnabled
            ? (value) => _setNotificationPreference(
                  notifyStreakTagKey,
                  value,
                )
            : null,
      ),
      _buildDivider(),
      _buildToggleRow(
        icon: Icons.auto_stories_outlined,
        label: 'Weekly Reflection',
        subtitle: 'Friday evening lookback',
        value: _weeklyReflectionEnabled,
        onChanged: subTogglesEnabled
            ? (value) => _setNotificationPreference(
                  notifyWeeklyTagKey,
                  value,
                )
            : null,
      ),
      _buildDivider(),
      _buildToggleRow(
        icon: Icons.favorite_border,
        label: 'Come Back Nudge',
        subtitle: 'Gentle reminder after a few days',
        value: _reengagementEnabled,
        onChanged: subTogglesEnabled
            ? (value) => _setNotificationPreference(
                  notifyReengagementTagKey,
                  value,
                )
            : null,
      ),
      _buildDivider(),
      _buildToggleRow(
        icon: Icons.campaign_outlined,
        label: 'New Content & Updates',
        subtitle: 'Features & seasonal content',
        value: _newContentEnabled,
        onChanged: subTogglesEnabled
            ? (value) => _setNotificationPreference(
                  notifyUpdatesTagKey,
                  value,
                )
            : null,
      ),
    ]);
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
