import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/streak_service.dart';

/// The post-expiry paid buy-back (§2g). A *calm, dismissible* rescue — never a
/// "your streak died!" guilt gate. The free effort/freeze paths have already
/// been exhausted by the time this shows; this only offers to relight an
/// already-expired streak worth ≥7 days.
Future<void> showStreakRescueSheet(
  BuildContext context,
  WidgetRef ref, {
  required int preLapseStreak,
}) {
  final cost = _repairCost(preLapseStreak);
  if (cost == null) {
    ref.read(dailyLoopProvider.notifier).clearStreakLapse();
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // The sheet's OWN surface is the solid cream — so it rises from the bottom,
    // full-width, flush to the bottom edge (covering the navbar area), with only
    // the top corners rounded. (Was transparent + an inset floating card.)
    backgroundColor: AppColors.surfaceLight,
    clipBehavior: Clip.antiAlias,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _StreakRescueSheet(preLapseStreak: preLapseStreak, cost: cost),
  );
}

int? _repairCost(int preLapseStreak) {
  if (preLapseStreak < 7) return null;
  if (preLapseStreak <= 29) return 100;
  if (preLapseStreak <= 89) return 250;
  return 500;
}

class _StreakRescueSheet extends ConsumerStatefulWidget {
  const _StreakRescueSheet({required this.preLapseStreak, required this.cost});
  final int preLapseStreak;
  final int cost;

  @override
  ConsumerState<_StreakRescueSheet> createState() => _StreakRescueSheetState();
}

class _StreakRescueSheetState extends ConsumerState<_StreakRescueSheet> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final isPremium =
        ref.read(premiumStateProvider).valueOrNull?.isPremium ?? false;
    _emit(AnalyticsEvents.streakRepairOfferShown, {
      'pre_lapse_streak': widget.preLapseStreak,
      'cost_tokens': widget.cost,
      'is_premium_free': isPremium,
    });
  }

  void _emit(String event, Map<String, dynamic> props) {
    try {
      StreakAnalytics.onAnalyticsEvent?.call(event, props);
    } catch (_) {}
  }

  void _dismiss() {
    _emit(AnalyticsEvents.streakRepairOfferDismissed, {
      'pre_lapse_streak': widget.preLapseStreak,
    });
    ref.read(dailyLoopProvider.notifier).clearStreakLapse();
    Navigator.of(context).pop();
  }

  Future<void> _buyBack() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.lightImpact();

    // Premium-free vs paid is decided server-side; we don't assert it here.
    final result = await repairStreakPaid(preLapseStreak: widget.preLapseStreak);
    if (!mounted) return;

    if (result.success) {
      ref
          .read(dailyLoopProvider.notifier)
          .applyRestoredStreak(result.restoredStreak);
      // Keep the freeze/token surfaces fresh.
      ref.read(dailyRewardsProvider.notifier).reload();
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = false);
    switch (result.reason) {
      case RepairFailReason.insufficientTokens:
        // Route to the Store to buy tokens — but do NOT clear the lapse. The
        // offer must survive the round-trip so the user can relight after buying
        // (Home re-shows the rescue sheet on return). Clearing it here stranded
        // the user with no way back. Capture the router BEFORE popping: after pop
        // this sheet's element is defunct, so `context.push` would look up an
        // ancestor on a deactivated widget and throw.
        final router = GoRouter.of(context);
        Navigator.of(context).pop();
        router.push('/store');
      case RepairFailReason.rateLimited:
        // Correct-but-final: a paid restore is limited to once a month. Retrying
        // won't help, so dismiss with a clear message instead of "try again".
        ref.read(dailyLoopProvider.notifier).clearStreakLapse();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can restore a streak once a month.'),
          ),
        );
      case RepairFailReason.windowPassed:
      case RepairFailReason.nothingToRestore:
        // Nothing (left) to restore — dismiss quietly.
        ref.read(dailyLoopProvider.notifier).clearStreakLapse();
        Navigator.of(context).pop();
      case RepairFailReason.none:
      case RepairFailReason.unknown:
        // Genuinely transient — keep the sheet open so they can retry.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Couldn’t relight just now — try again.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        ref.watch(premiumStateProvider).valueOrNull?.isPremium ?? false;
    final balance = ref.watch(dailyLoopProvider).tokenBalance;

    // Bottom-only SafeArea INSIDE the solid modal surface: the sheet background
    // (set on showModalBottomSheet) still reaches the physical bottom edge, while
    // this keeps the buttons clear of the home indicator.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 108,
              child: Center(
                child: CompanionMedallion(
                  state: CompanionState(
                    brightness: CompanionBrightness.dormant,
                    protected: false,
                  ),
                  size: 108,
                  // On the white card — no full-canvas cold vignette (it renders
                  // as a grey square); just the dead lantern object.
                  ambient: false,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Disambiguates the dead lamp from the live (day-1) lantern behind —
            // this medallion is a portrait of the streak that was LOST.
            Text('Your ${widget.preLapseStreak}-day lantern',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Relight your lantern',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.preLapseStreak}-day journey rested. '
              'You can restore it and carry on where you left off.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                onPressed: _busy ? null : _buyBack,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        isPremium
                            ? 'Restore my streak — free with Premium'
                            : 'Restore for ${widget.cost} tokens',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 6),
              Text('You have $balance tokens',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondaryLight)),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: _busy ? null : _dismiss,
              child: Text('Start fresh instead',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondaryLight)),
            ),
          ],
        ),
      ),
    );
  }
}
