import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/referrals/referral_nudge_gate.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/referral_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Surface state for the home-screen referral nudge card:
///
/// 1. `loading` — the async resolve (streak → optional Supabase referral read)
///    is in flight. Renders `SizedBox.shrink()`, not a skeleton: the card is
///    eligible for a small slice of users, so a loader would flash-then-collapse
///    on most loads. Silent resolve is correct UX — when eligible, the card fades
///    in once `_resolve()` flips to `show`.
/// 2. `hidden` — ineligible (streak below the "Consistent" milestone, already
///    rewarded, or inside the cooldown without a progress bump). Renders
///    nothing.
/// 3. `show(progress)` — eligible. Renders the share card with the live
///    "n / 3 joined" progress baked into the CTA.
@immutable
sealed class _NudgeState {
  const _NudgeState();
}

class _NudgeLoading extends _NudgeState {
  const _NudgeLoading();
}

class _NudgeHidden extends _NudgeState {
  const _NudgeHidden();
}

class _NudgeShow extends _NudgeState {
  const _NudgeShow(this.progress);
  final int progress;
}

/// The referral nudge. Shown to anyone who has held a streak to the app's first
/// milestone — the one that unlocks the title "Consistent" — until they earn
/// their first referral grant.
///
/// **This is the only place the share ask lives** (founder, 2026-07-29). It used
/// to also appear at the onboarding paywall's first dismiss, via
/// `ReferUnlockScreen`, which asked someone who had just declined to pay twice
/// to go and recommend an app they had never used. That screen was deleted; see
/// [resolveReferralNudge]'s library doc for why consistency, not payment, is the
/// audience.
///
/// Render gating lives in [resolveReferralNudge]; this widget only gathers the
/// inputs and renders. It self-collapses to `SizedBox.shrink()` whenever it
/// shouldn't show, so the host `Column` needs no conditional around it.
class ReferralNudgeCard extends ConsumerStatefulWidget {
  const ReferralNudgeCard({
    super.key,
    DateTime Function()? clock,
    Future<void> Function(String)? shareOverride,
  })  : _clock = clock,
        _shareOverride = shareOverride;

  /// Injectable clock for deterministic tests (mirrors `GiftService`'s
  /// `debugGiftClock`). Production omits it → `DateTime.now`.
  final DateTime Function()? _clock;

  /// Test seam forwarded to [ReferralService.shareMyCode]'s `override` so the
  /// widget test can assert the share fired without invoking the OS sheet.
  final Future<void> Function(String)? _shareOverride;

  /// User-scoped (via [SupabaseSyncService.scopedKey]) prefs holding when the
  /// card was last shown/dismissed and the progress count at that moment. The
  /// pair drives the 7-day cooldown plus the progress-bump bypass.
  static const String lastShownBaseKey = 'home_referral_nudge_last_shown';
  static const String lastProgressBaseKey = 'home_referral_nudge_last_progress';

  @override
  ConsumerState<ReferralNudgeCard> createState() => _ReferralNudgeCardState();
}

class _ReferralNudgeCardState extends ConsumerState<ReferralNudgeCard> {
  _NudgeState _state = const _NudgeLoading();
  bool _shownEventFired = false;
  bool _sharing = false;

  DateTime _now() => (widget._clock ?? DateTime.now)();

  /// Current shown progress, read straight off the sealed state so there's a
  /// single source of truth (no separate mutable field to drift out of sync).
  /// 0 in any non-show state — the share/dismiss handlers are only reachable
  /// from the rendered card, so in practice this is always the shown value.
  int get _shownProgress {
    final state = _state;
    return state is _NudgeShow ? state.progress : 0;
  }

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  /// Evaluation order is intentional: the cheap streak read gates the Supabase
  /// referral read, so everyone below the milestone — the large majority of
  /// loads — incurs ZERO referral queries. Users at or past it do query; that is
  /// how a progress bump or an earned grant is detected. `getStreak()` is
  /// cache-first, so the short-circuit costs no network either. Any failure
  /// (Supabase 5xx, unhydrated cache) collapses to hidden; the card never throws
  /// on a dashboard.
  Future<void> _resolve() async {
    try {
      final uid = supabaseSyncService.currentUserId;
      if (uid == null || uid.isEmpty) {
        _setHidden();
        return;
      }

      final streak = await getStreak();
      final now = _now();
      if (streak.currentStreak < consistentStreakDays) {
        _setHidden();
        return;
      }

      final referrals =
          await ref.read(referralServiceProvider).getMyReferralsState(uid);
      final prefs = await SharedPreferences.getInstance();
      final lastShownIso = prefs.getString(
          supabaseSyncService.scopedKey(ReferralNudgeCard.lastShownBaseKey));
      final lastShownAt =
          lastShownIso == null ? null : DateTime.tryParse(lastShownIso);
      final lastShownProgress = prefs.getInt(supabaseSyncService
              .scopedKey(ReferralNudgeCard.lastProgressBaseKey)) ??
          0;

      final decision = resolveReferralNudge(
        currentStreak: streak.currentStreak,
        now: now,
        progressTowardNext: referrals.progressTowardNext,
        hasEarnedGrant: referrals.grants.isNotEmpty,
        lastShownAt: lastShownAt,
        lastShownProgress: lastShownProgress,
      );

      if (!mounted) return;
      if (decision == ReferralNudgeDecision.show) {
        setState(() => _state = _NudgeShow(referrals.progressTowardNext));
        await _onShown(referrals.progressTowardNext);
      } else {
        _setHidden();
      }
    } catch (_) {
      _setHidden();
    }
  }

  void _setHidden() {
    if (mounted) setState(() => _state = const _NudgeHidden());
  }

  Future<void> _onShown(int progress) async {
    if (!_shownEventFired) {
      _shownEventFired = true;
      ref.read(analyticsProvider).track(
        AnalyticsEvents.homeReferralNudgeShown,
        properties: {'progress': progress},
      );
    }
    await _persistShown(progress);
  }

  Future<void> _persistShown(int progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(ReferralNudgeCard.lastShownBaseKey),
      _now().toIso8601String(),
    );
    await prefs.setInt(
      supabaseSyncService.scopedKey(ReferralNudgeCard.lastProgressBaseKey),
      progress,
    );
  }

  Future<void> _onShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.lightImpact();
    ref.read(analyticsProvider).track(
      AnalyticsEvents.homeReferralNudgeShareTapped,
      properties: {'progress': _shownProgress},
    );
    try {
      final uid = supabaseSyncService.currentUserId;
      if (uid != null && uid.isNotEmpty) {
        final svc = ref.read(referralServiceProvider);
        await svc.ensureReferralCode(uid);
        final code = await svc.getMyReferralCode(uid);
        if (code != null && code.isNotEmpty && mounted) {
          await svc.shareMyCode(context, code, override: widget._shareOverride);
        }
      }
    } catch (_) {
      // Best-effort — a failed share leaves the card in place to retry.
    }
    if (mounted) setState(() => _sharing = false);
  }

  Future<void> _onDismiss() async {
    final progress = _shownProgress;
    ref.read(analyticsProvider).track(
      AnalyticsEvents.homeReferralNudgeDismissed,
      properties: {'progress': progress},
    );
    await _persistShown(progress);
    if (mounted) setState(() => _state = const _NudgeHidden());
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _NudgeLoading() => const SizedBox.shrink(),
      _NudgeHidden() => const SizedBox.shrink(),
      _NudgeShow(:final progress) => _NudgeCard(
          progress: progress,
          sharing: _sharing,
          onShare: _onShare,
          onDismiss: _onDismiss,
        ),
    };
  }
}

class _NudgeCard extends StatelessWidget {
  const _NudgeCard({
    required this.progress,
    required this.sharing,
    required this.onShare,
    required this.onDismiss,
  });

  final int progress;
  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // Card owns its bottom margin so a hidden card (the common case) leaves no
    // dead space in the home Column — the insertion site adds no spacer.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + headline + dismiss. The dismiss sits IN the row
            // (not a Positioned overlay) so it reserves its own width and the
            // Expanded headline can never run underneath it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.volunteer_activism_rounded,
                      color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Send a dua to 3 friends',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unlock 30 days of Sakina + a Gold card when 3 friends join.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sharing ? null : onShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: sharing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(
                        'Send to friends · $progress/3 joined',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .moveY(begin: 8, end: 0, duration: 400.ms),
    );
  }
}
