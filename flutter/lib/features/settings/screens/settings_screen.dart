import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/constants/app_strings.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/features/dua_times/providers/dua_notification_scheduler_provider.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/launch_gate_service.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/services/title_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/core/app_session.dart';
import 'package:sakina/core/utils/invalidate_providers.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/features/settings/widgets/delete_account_dialogs.dart';
import 'package:sakina/features/settings/widgets/redeem_code_sheet.dart';
import 'package:sakina/features/settings/widgets/settings_premium_card.dart';
import 'package:sakina/features/tour/providers/onboarding_tour_controller.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/widgets/sakina_loader.dart';
import 'package:sakina/widgets/subpage_header.dart';
import 'package:sakina/widgets/summary_metric_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// F1 fix (2026-04-26): pure resolver for the Settings profile-card display
/// name. Tries `user_profiles.display_name` first (canonical onboarding
/// value), then auth metadata `full_name` (set on social sign-up), then
/// email, then 'Guest'. Top-level so it can be unit tested without
/// instantiating SettingsScreen.
String resolveProfileDisplayName({
  String? profileDisplayName,
  String? fullName,
  String? email,
}) {
  final cached = profileDisplayName?.trim();
  if (cached != null && cached.isNotEmpty) return cached;
  final meta = fullName?.trim();
  if (meta != null && meta.isNotEmpty) return meta;
  final mail = email?.trim();
  if (mail != null && mail.isNotEmpty) return mail;
  return 'Guest';
}

/// Wipes the user's card collection AND today's daily-loop state on both
/// local prefs and the server. Top-level so it can be unit tested without
/// pumping the Settings widget.
///
/// Why server-side `resetDailyRewardsOnServer` matters: if the user already
/// claimed today, the `user_daily_rewards` row marks today complete. Without
/// resetting it, the next reconcile re-hydrates the stale "today claimed"
/// state and the launch overlay refuses to re-fire — same F1/F5 bug fixed
/// for `_resetDailyLoop`. Pinned by
/// `test/features/settings/reset_card_collection_test.dart`.
Future<void> performCardCollectionDangerReset({
  required Future<void> Function() resetDailyLoopState,
}) async {
  await clearCardCollection();
  await resetDailyRewardsOnServer();
  await resetDailyLoopState();
  await resetDailyLaunchGate();
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.autoAction});

  /// Optional deep-link action consumed on first build. Today the only
  /// supported value is `replay_tour` — see [_handleAutoAction]. Propagated
  /// from the GoRouter `/settings?action=` query param so the E5 win-back
  /// push (`sakina://settings?action=replay_tour`) can trigger Replay
  /// without the user tapping the row.
  final String? autoAction;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  XpState? _xpState;
  StreakState? _streakState;
  List<AnchorResult> _anchorResults = [];
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
  bool _duaWindowsEnabled = true;
  bool _loading = true;
  // F1 fix (2026-04-26): cache display_name from user_profiles so the
  // profile card shows the user's name instead of email-twice. Email is
  // pulled from auth.user.email and shown as the subtitle.
  String? _profileDisplayName;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Handle deep-link auto-actions (E5 win-back). Schedules a post-frame
    // callback so context.go() during the autoAction handler runs after
    // build, not during it.
    if (widget.autoAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleAutoAction(widget.autoAction!);
      });
    }
  }

  /// Programmatic Replay-tour invocation (E5 win-back push deep link).
  /// Mirrors the user-tap path in [_replayTour] exactly so both ingress
  /// surfaces behave identically.
  Future<void> _handleAutoAction(String action) async {
    if (action == 'replay_tour') {
      await _replayTour();
    }
  }

  Future<void> _replayTour() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Clear the unified tour-seen flag so the controller can re-arm.
    await prefs.remove(onboardingTourSeenFlag(userId));
    if (!mounted) return;
    // Jump to Home so step 1's anchor (Begin Muhasabah) is mounted.
    context.go('/');
    // Restart the tour controller.
    ref.read(onboardingTourControllerProvider.notifier).replay();
    // Existing analytics track
    ref.read(analyticsProvider).track(AnalyticsEvents.tourReplayTapped);
  }

  Future<void> _loadData() async {
    final xp = await getXp();
    final streak = await getStreak();
    final displayTitle = await getDisplayTitle(xp.level);
    final unlockedTitles = getUnlockedTitles(
      currentLevel: xp.level,
      longestStreak: streak.longestStreak,
    );

    final anchorResults = await loadSavedDiscoveryQuizResults();
    final notificationService = ref.read(notificationServiceProvider);
    final notificationPreferences =
        await notificationService.getNotificationPreferences();

    // F1 fix: pull display_name from user_profiles (saveOnboardingData
    // writes it there). userMetadata['full_name'] is only set on social
    // sign-up, so email-flow users always fell back to email. This is
    // best-effort — failure leaves _profileDisplayName null and the email
    // fallback still renders.
    String? profileDisplayName;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final row = await Supabase.instance.client
            .from('user_profiles')
            .select('display_name')
            .eq('id', user.id)
            .maybeSingle();
        final value = row?['display_name'] as String?;
        if (value != null && value.trim().isNotEmpty) {
          profileDisplayName = value.trim();
        }
      } catch (_) {
        // Network failure / RLS denial — silent fallback to email.
      }
    }

    if (!mounted) return;
    setState(() {
      _xpState = xp;
      _streakState = streak;
      _anchorResults = anchorResults;
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
      _duaWindowsEnabled =
          notificationPreferences[notifyDuaWindowsTagKey] ?? true;
      _profileDisplayName = profileDisplayName;
      _loading = false;
    });
  }

  Future<void> _setPushNotificationsEnabled(bool enabled) async {
    if (_pushNotificationsEnabled == enabled) return;

    final notificationService = ref.read(notificationServiceProvider);
    final previousValue = _pushNotificationsEnabled;
    setState(() => _pushNotificationsEnabled = enabled);

    try {
      final isOptedIn = enabled
          ? await notificationService.optIn()
          : await notificationService.optOut();

      if (!mounted || _pushNotificationsEnabled != enabled) return;

      // A fresh permission grant re-opens the local duʿā calendar band:
      // reschedule once push is on and the `notify_dua_windows` category is
      // enabled (the gate checks both). Best-effort — the gate degrades
      // silently and never throws.
      if (isOptedIn) {
        final gate = ref.read(duaNotificationGateProvider);
        final schedule = ref.read(duaWindowProvider).schedule;
        if (gate != null && schedule != null) {
          await gate.apply(schedule, force: true);
        }
        if (!mounted) return;
      }

      if (_pushNotificationsEnabled != isOptedIn) {
        setState(() => _pushNotificationsEnabled = isOptedIn);
        // User toggled ON but the OS denied permission. OneSignal's
        // requestPermission(fallbackToSettings: true) already opens iOS
        // Settings in this case — surface a snackbar so the silent
        // snap-back to OFF isn't mysterious.
        if (enabled && !isOptedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications are blocked in your device settings. '
                'Enable them there to turn this on.',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (!mounted || _pushNotificationsEnabled != enabled) return;
      setState(() => _pushNotificationsEnabled = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update notifications. Please try again.'),
        ),
      );
    }
  }

  Future<void> _setNotificationPreference(String key, bool enabled) async {
    final previousValue = _notificationPreferenceValue(key);
    if (previousValue == enabled) return;

    setState(() => _setLocalNotificationPreference(key, enabled));

    try {
      await ref
          .read(notificationServiceProvider)
          .setNotificationPreference(key, enabled);
    } catch (_) {
      if (!mounted || _notificationPreferenceValue(key) != enabled) return;
      setState(() => _setLocalNotificationPreference(key, previousValue));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update notification preference.'),
        ),
      );
    }
  }

  /// The duʿā-window toggle carries a scheduler side effect the other rows
  /// don't: turning it OFF clears the reserved local calendar id band (the
  /// mirror of toggle-on); turning it ON reschedules the current calendar
  /// schedule so reminders reappear without waiting for the next foreground
  /// rebuild. Both go through the opt-in gate.
  Future<void> _setDuaWindowsEnabled(bool enabled) async {
    // Persist the preference first (local cache + server) via the shared path,
    // so the gate below reads the just-written value.
    await _setNotificationPreference(notifyDuaWindowsTagKey, enabled);
    if (!mounted) return;

    final gate = ref.read(duaNotificationGateProvider);
    if (gate == null) return;

    if (!enabled) {
      // Toggle-OFF symmetry: clear the reserved dua calendar band immediately.
      // TODO(dua-notif): delete synced dua_precise_notifications rows on
      // toggle-off (server precise-row deletion is a later slice).
      await gate.clear();
      return;
    }
    // Toggle-ON: reschedule from the current built schedule, if any. Force past
    // the throttle so the flip takes effect now.
    final schedule = ref.read(duaWindowProvider).schedule;
    if (schedule != null) {
      await gate.apply(schedule, force: true);
    }
  }

  bool _notificationPreferenceValue(String key) {
    if (key == notifyDailyTagKey) return _dailyReminderEnabled;
    if (key == notifyStreakTagKey) return _streakReminderEnabled;
    if (key == notifyReengagementTagKey) return _reengagementEnabled;
    if (key == notifyWeeklyTagKey) return _weeklyReflectionEnabled;
    if (key == notifyUpdatesTagKey) return _newContentEnabled;
    if (key == notifyDuaWindowsTagKey) return _duaWindowsEnabled;
    throw ArgumentError.value(
        key, 'key', 'Unsupported notification preference');
  }

  void _setLocalNotificationPreference(String key, bool enabled) {
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
    } else if (key == notifyDuaWindowsTagKey) {
      _duaWindowsEnabled = enabled;
    } else {
      throw ArgumentError.value(
          key, 'key', 'Unsupported notification preference');
    }
  }

  void _invalidateAllUserProviders(WidgetRef ref) {
    invalidateAllUserProviders(ref);
  }

  Future<void> _openDiscoveryQuiz() async {
    await context.push('/discovery-quiz');
    if (!mounted) return;
    await _loadData();
  }

  void _openRedeemCodeSheet() {
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.referralSettingsRedeemOpened);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: RedeemCodeSheet(userId: userId),
      ),
    );
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    await performCardCollectionDangerReset(
      resetDailyLoopState: () =>
          ref.read(dailyLoopProvider.notifier).resetToday(),
    );
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
    // 2-step confirmation extracted to delete_account_dialogs.dart so the
    // flow can be widget-tested in isolation. Step 1 is a plain warning
    // (Cancel / Continue); Step 2 requires the user to type DELETE before
    // the destructive button enables.
    final warned = await showDeleteAccountWarningDialog(context);
    if (!warned || !mounted) return;

    final confirmed = await showDeleteAccountConfirmDialog(context);
    if (!confirmed || !mounted) return;

    // Step 3: Perform deletion
    try {
      final authService = ref.read(authServiceProvider);
      final uid = supabaseSyncService.currentUserId;
      await authService.deleteAccount();
      // The account is gone server-side — sign out NEXT, before the best-effort
      // local cleanup below. If sign-out ran last (after reset/clearSession/
      // invalidate) a throw in any of those steps would strand a still-valid
      // session pointing at a deleted account. That session survives an app
      // reinstall (iOS persists it), so the next launch silently boots back into
      // the ghost account and skips onboarding. Clearing the session first makes
      // a successful delete always end signed out, regardless of cleanup errors.
      await authService.signOut();
      ref.read(onboardingProvider.notifier).reset();
      await ref.read(appSessionProvider).clearSession(userId: uid);
      // Reset Mixpanel identity so the deleted account's distinct_id doesn't
      // leak into a fresh account created on this device. Best-effort — never
      // let an analytics error mask a successful deletion. Note: signedOut above
      // already fires AppSessionNotifier.onAnalyticsReset; this is a belt-and-
      // suspenders reset on the explicit-deletion path and is idempotent.
      try {
        ref.read(analyticsProvider).resetForSignOut();
      } catch (_) {/* analytics best-effort */}
      // JUSTIFIED: hard reset of all Riverpod provider state on full account
      // deletion. No EconomyEvents equivalent — the user session is gone.
      _invalidateAllUserProviders(ref);
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
                  AppSpacing.lg,
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
                    const SizedBox(height: AppSpacing.md),
                    const SettingsPremiumCard(),
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
    return resolveProfileDisplayName(
      profileDisplayName: _profileDisplayName,
      fullName: user?.userMetadata?['full_name'] as String?,
      email: user?.email,
    );
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
            // Aref Ruqaa clips/bleeds when rendered bare — route it through
            // AdjustedArabicDisplay AND reserve vertical room above/below so the
            // tall ascenders + diacritics aren't cut (mirrors progress_screen).
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 22),
                AdjustedArabicDisplay(
                  text: _displayTitleArabic,
                  textAlign: TextAlign.right,
                  style: AppTypography.nameOfAllahDisplay.copyWith(
                    fontSize: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
              ],
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

  Future<void> _showAnchorNameDetails(
    AnchorResult anchor,
    int index,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxHeight = MediaQuery.sizeOf(dialogContext).height * 0.78;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${index + 1}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          anchor.name,
                          style: AppTypography.headlineLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      anchor.arabic,
                      textAlign: TextAlign.center,
                      style: AppTypography.nameOfAllahDisplay.copyWith(
                        fontSize: 36,
                        color: AppColors.secondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    anchor.anchor,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    anchor.detail,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        if (_anchorResults.isEmpty)
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
            children: _anchorResults.asMap().entries.map((entry) {
              final index = entry.key;
              final anchor = entry.value;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showAnchorNameDetails(anchor, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      anchor.name,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
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
        // Referral entry points. "Refer a friend" sits ABOVE the receiver
        // action ("Redeem a referral code") so the referrer flow leads — the
        // re-share loop is the higher-leverage retention surface. See
        // docs/superpowers/plans/2026-05-23-my-referrals-screen.md.
        _buildSettingsCard([
          _buildSettingsRow(
            icon: Icons.send_rounded,
            label: 'Refer a friend',
            onTap: () => context.push('/my-referrals'),
          ),
          _buildSettingsRow(
            icon: Icons.card_giftcard_rounded,
            label: 'Redeem a referral code',
            onTap: _openRedeemCodeSheet,
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
                  // JUSTIFIED: hard reset of all Riverpod provider state on
                  // sign-out. No EconomyEvents equivalent — user session ends.
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
          // Replay the unified interactive guided tour from step 1. Clears
          // the onboarding_tour_v1_seen flag and calls
          // OnboardingTourController.replay() — see _replayTour.
          _buildSettingsRow(
            icon: Icons.info_outline,
            label: 'Replay app tour',
            onTap: _replayTour,
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

        // Developer (debug builds only)
        // NOTE: Commented out so it never reaches production. To use Dev Tools
        // during local dev/QA, uncomment the block below. For PROFILE builds
        // (on-device QA) change the guard to `!kReleaseMode`; `kDebugMode` is
        // false in profile so Dev Tools would be unreachable there.
        // if (kDebugMode) ...[
        //   _buildSectionLabel('Developer'),
        //   const SizedBox(height: AppSpacing.sm),
        //   _buildSettingsCard([
        //     _buildSettingsRow(
        //       icon: Icons.bug_report_rounded,
        //       label: 'Dev Tools',
        //       onTap: () => context.push('/dev-tools'),
        //     ),
        //   ]),
        //   const SizedBox(height: AppSpacing.lg),
        // ],

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
    final subTogglesEnabled = _pushNotificationsEnabled;

    return _buildSettingsCard([
      _buildToggleRow(
        icon: Icons.notifications_outlined,
        label: 'Push Notifications',
        value: _pushNotificationsEnabled,
        onChanged: _setPushNotificationsEnabled,
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
      _buildDivider(),
      _buildToggleRow(
        icon: Icons.nights_stay_outlined,
        label: 'Duʿā Window Reminders',
        subtitle: 'When a time of accepted duʿā is open',
        value: _duaWindowsEnabled,
        onChanged: subTogglesEnabled ? _setDuaWindowsEnabled : null,
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
