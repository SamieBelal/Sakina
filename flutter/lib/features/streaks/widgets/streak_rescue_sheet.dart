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
    backgroundColor: Colors.transparent,
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
    final result = await repairStreakPaid();
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
    if (result.needsTokens) {
      Navigator.of(context).pop();
      ref.read(dailyLoopProvider.notifier).clearStreakLapse();
      context.push('/store');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t relight just now — try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium =
        ref.watch(premiumStateProvider).valueOrNull?.isPremium ?? false;
    final balance = ref.watch(dailyLoopProvider).tokenBalance;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
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
                ),
              ),
            ),
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
