import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import 'paywall_gate_page.dart';

/// Page 2 of the gate — `trial_timeline`.
///
/// Transparency, not selling: the three moments of the trial stated once, in
/// order. The middle beat is Apple's own trial-ending notice — the only clock
/// the gate is allowed, and true whatever the user's notification permission
/// says, because it is a system receipt rather than something Sakina schedules.
///
/// The beats SPAN the page rather than stacking at the top: seven days (or
/// three) is a stretch of time, and a long thread says so without a word of
/// copy. Filling the middle with more selling is precisely what this page's
/// job forbids.
class PaywallTrialTimelinePage extends StatelessWidget {
  const PaywallTrialTimelinePage({
    required this.trialLabel,
    required this.trialDays,
    super.key,
  });

  /// `"7 days"` — from the store, never a constant.
  final String trialLabel;

  /// Whole days. The reminder lands the day before the charge, so this must be
  /// ≥ 2 for the three-beat shape to make sense; `PaywallScreen` does not
  /// build this page otherwise.
  final int trialDays;

  @override
  Widget build(BuildContext context) {
    final reminderDay = trialDays - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        paywallEntry(
          context,
          0,
          Text(
            AppStrings.paywallTrialTimelineHeadlineTemplate
                .replaceAll('{trial}', trialLabel),
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // The first two beats take the slack, so the threads between them grow
        // with the screen instead of leaving a dead middle.
        Expanded(
          child: paywallEntry(
            context,
            1,
            const _Beat(
              heading: AppStrings.paywallTrialTimelineTodayHeading,
              body: AppStrings.paywallTrialTimelineTodayBody,
              node: _NodeStyle.now,
              thread: _ThreadStyle.nowToReminder,
            ),
          ),
        ),
        Expanded(
          child: paywallEntry(
            context,
            2,
            _Beat(
              heading: AppStrings.paywallTrialTimelineDayHeadingTemplate
                  .replaceAll('{day}', '$reminderDay'),
              body: AppStrings.paywallTrialTimelineReminderBody,
              node: _NodeStyle.reminder,
              thread: _ThreadStyle.reminderToCharge,
            ),
          ),
        ),
        paywallEntry(
          context,
          3,
          _Beat(
            heading: AppStrings.paywallTrialTimelineDayHeadingTemplate
                .replaceAll('{day}', '$trialDays'),
            body: AppStrings.paywallTrialTimelineChargeBody,
            node: _NodeStyle.charge,
          ),
        ),
      ],
    );
  }
}

enum _NodeStyle { now, reminder, charge }

/// The thread carries the progression: emerald → gold → resolved grey.
enum _ThreadStyle { nowToReminder, reminderToCharge }

/// One moment of the trial: a rail on the left, heading + body on the right.
///
/// A [Stack], not a [Row] with `CrossAxisAlignment.stretch`. The page lives
/// inside an `IntrinsicHeight` (so the beats can span a tall screen and scroll
/// on a short one), and a stretched cross axis cannot be measured before the
/// final height exists — the layout asserts `RenderBox was not laid out`. Here
/// the text column is the only non-positioned child, so it defines the beat's
/// intrinsic height, and the rail is a `Positioned` fill that takes whatever
/// height the beat ends up with.
class _Beat extends StatelessWidget {
  const _Beat({
    required this.heading,
    required this.body,
    required this.node,
    this.thread,
  });

  final String heading;
  final String body;
  final _NodeStyle node;
  final _ThreadStyle? thread;

  static const double _railWidth = 18;
  static const double _gutter = _railWidth + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: _gutter,
            top: 2,
            bottom: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                heading,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _railWidth,
          child: ExcludeSemantics(child: _Rail(node: node, thread: thread)),
        ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.node, required this.thread});

  final _NodeStyle node;
  final _ThreadStyle? thread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (thread != null)
          Positioned(
            top: 28,
            bottom: 8,
            left: 8,
            width: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: thread == _ThreadStyle.nowToReminder
                      ? const [AppColors.primary, AppColors.secondary]
                      : const [AppColors.secondary, AppColors.borderLight],
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          left: 1,
          width: 16,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (node) {
                // Gold is a FILL here, carrying no text — the one place
                // DESIGN.md §2.3 permits `secondary`.
                _NodeStyle.now => AppColors.primary,
                _NodeStyle.reminder => AppColors.secondary,
                _NodeStyle.charge => AppColors.backgroundLight,
              },
              border: node == _NodeStyle.charge
                  ? Border.all(color: AppColors.borderLight, width: 2)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
