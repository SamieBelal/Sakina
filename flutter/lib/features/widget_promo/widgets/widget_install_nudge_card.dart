import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/widget_promo/widget_install_nudge_gate.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_provider.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home-dashboard nudge to add the Sakina home-screen widget.
///
/// The single biggest lever for widget retention is ADOPTION — a widget nobody
/// installs retains nobody. iOS gives no API to add a widget programmatically,
/// so this teaches the (short) manual steps at the "aha" moment: once the user
/// has a muḥāsabah streak ≥ 1 (they've felt the daily loop). Shown until
/// dismissed. Render gating lives in [resolveWidgetInstallNudge]; this widget
/// gathers inputs and renders, self-collapsing to `SizedBox.shrink()` otherwise
/// so the home `Column` needs no conditional around it.
class WidgetInstallNudgeCard extends ConsumerStatefulWidget {
  const WidgetInstallNudgeCard({super.key, Future<int> Function()? streakOverride})
      : _streakOverride = streakOverride;

  /// Test seam — supplies the streak without the prefs-backed StreakService.
  final Future<int> Function()? _streakOverride;

  /// Device-level (NOT user-scoped): the widget lives on the device regardless
  /// of who's signed in, so once dismissed we don't re-nag a different account.
  static const String dismissedKey = 'widget_install_nudge_dismissed';

  @override
  ConsumerState<WidgetInstallNudgeCard> createState() =>
      _WidgetInstallNudgeCardState();
}

sealed class _State {
  const _State();
}

class _Loading extends _State {
  const _Loading();
}

class _Hidden extends _State {
  const _Hidden();
}

class _Show extends _State {
  const _Show(this.streak);
  final int streak;
}

class _WidgetInstallNudgeCardState
    extends ConsumerState<WidgetInstallNudgeCard> {
  _State _state = const _Loading();
  bool _shownEventFired = false;
  bool _howToOpen = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed =
          prefs.getBool(WidgetInstallNudgeCard.dismissedKey) ?? false;
      final streak = widget._streakOverride != null
          ? await widget._streakOverride!()
          : (await getStreak()).currentStreak;

      final decision = resolveWidgetInstallNudge(
        dismissed: dismissed,
        currentStreak: streak,
      );
      if (!mounted) return;
      if (decision == WidgetInstallNudgeDecision.show) {
        setState(() => _state = _Show(streak));
        if (!_shownEventFired) {
          _shownEventFired = true;
          ref.read(analyticsProvider).track(
                AnalyticsEvents.widgetInstallNudgeShown,
                properties: {'streak': streak},
              );
        }
      } else {
        setState(() => _state = const _Hidden());
      }
    } catch (_) {
      if (mounted) setState(() => _state = const _Hidden());
    }
  }

  void _toggleHowTo() {
    HapticFeedback.lightImpact();
    if (!_howToOpen) {
      ref
          .read(analyticsProvider)
          .track(AnalyticsEvents.widgetInstallNudgeHowtoTapped);
    }
    setState(() => _howToOpen = !_howToOpen);
  }

  Future<void> _dismiss() async {
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvents.widgetInstallNudgeDismissed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WidgetInstallNudgeCard.dismissedKey, true);
    if (mounted) setState(() => _state = const _Hidden());
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _Loading() => const SizedBox.shrink(),
      _Hidden() => const SizedBox.shrink(),
      _Show(:final streak) => _Card(
          streak: streak,
          howToOpen: _howToOpen,
          onToggleHowTo: _toggleHowTo,
          onDismiss: _dismiss,
        ),
    };
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.streak,
    required this.howToOpen,
    required this.onToggleHowTo,
    required this.onDismiss,
  });

  final int streak;
  final bool howToOpen;
  final VoidCallback onToggleHowTo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.add_to_home_screen_rounded,
                      color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Keep Sakina on your Home Screen',
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
              streak > 0
                  ? "Add a Sakina widget — today's Name and your $streak-day streak, or the best times for duʿā with a live countdown — right where you'll see it."
                  : "Add a Sakina widget — today's Name and your streak, or the best times for duʿā with a live countdown — right where you'll see it.",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            if (howToOpen) ...[
              const SizedBox(height: AppSpacing.md),
              const _HowToSteps(),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onToggleHowTo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: Text(
                  howToOpen ? 'Got it' : 'Show me how',
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

class _HowToSteps extends StatelessWidget {
  const _HowToSteps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Touch and hold an empty spot on your Home Screen.',
      'Tap the + in the top corner.',
      'Search “Sakina” and pick a widget (you’ll see two) and a size.',
      'Tap Add Widget — you’re done.',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAltLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: i == steps.length - 1 ? 0 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(steps[i],
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                            height: 1.4,
                          )),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
