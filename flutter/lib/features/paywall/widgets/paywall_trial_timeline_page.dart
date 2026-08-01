import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
/// The threads between beats are DELIBERATELY long — seven days (or three) is
/// a stretch of time, and a long thread says so without a word of copy.
/// Filling the middle with more selling is precisely what this page's job
/// forbids.
///
/// But long is not the same as unbounded (2026-08-01). The first two beats
/// used to be `Expanded`, which poured *every* pixel of leftover screen into
/// the two threads: ~127pt a gap on a 390×844 frame. Past roughly 60pt the
/// body text stops reading as attached to its heading and the thread stops
/// reading as duration — it just looks like the page broke. The threads are
/// now a fixed [_Beat.bottomSpace], and the slack collects once at the bottom
/// where it is ordinary page whitespace rather than a hole inside a connected
/// diagram.
class PaywallTrialTimelinePage extends StatelessWidget {
  const PaywallTrialTimelinePage({
    required this.trialLabel,
    required this.trialDays,
    this.today,
    super.key,
  });

  /// The user's LOCAL today, injectable for tests.
  ///
  /// Local, never UTC — and the arithmetic below builds each date from
  /// calendar fields rather than adding `Duration(days: n)`. Both matter:
  /// a UTC read puts anyone east of the line on tomorrow's date for part of
  /// their evening, and duration-adding drifts an hour across a DST boundary,
  /// which is enough to print the wrong day. This is the same day-boundary
  /// class of bug W4 fixed twice; a paywall that names the wrong charge date
  /// is worse than one that names none.
  final DateTime? today;

  /// `"7 days"` — from the store, never a constant.
  final String trialLabel;

  /// Whole days. The reminder lands the day before the charge, so this must be
  /// ≥ 2 for the three-beat shape to make sense; `PaywallScreen` does not
  /// build this page otherwise.
  final int trialDays;

  /// `"Fri 1 Aug"` for the calendar day [offset] days after [today].
  ///
  /// Day 1 is today, so the beat labelled "Day N" is `N - 1` days out.
  String _dateFor(int offset) {
    final base = today ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day + offset);
    return DateFormat('EEE d MMM').format(day);
  }

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
        paywallEntry(
          context,
          1,
          _Beat(
            heading: AppStrings.paywallTrialTimelineTodayHeading,
            date: _dateFor(0),
            body: AppStrings.paywallTrialTimelineTodayBody,
            node: _NodeStyle.now,
            thread: _ThreadStyle.nowToReminder,
          ),
        ),
        paywallEntry(
          context,
          2,
          _Beat(
            heading: AppStrings.paywallTrialTimelineDayHeadingTemplate
                .replaceAll('{day}', '$reminderDay'),
            date: _dateFor(reminderDay - 1),
            body: AppStrings.paywallTrialTimelineReminderBody,
            node: _NodeStyle.reminder,
            thread: _ThreadStyle.reminderToCharge,
          ),
        ),
        paywallEntry(
          context,
          3,
          _Beat(
            heading: AppStrings.paywallTrialTimelineDayHeadingTemplate
                .replaceAll('{day}', '$trialDays'),
            date: _dateFor(trialDays - 1),
            body: AppStrings.paywallTrialTimelineChargeBody,
            node: _NodeStyle.charge,
            // The last beat ends the diagram; a thread-length gap under it
            // would imply a fourth moment that never comes.
            bottomSpace: AppSpacing.sm,
          ),
        ),
        const Spacer(),
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
    this.date,
    this.thread,
    this.bottomSpace = AppSpacing.xxl,
  });

  final String heading;

  /// `"Fri 1 Aug"`. Sits beside the heading rather than under it — a second
  /// line per beat would push the diagram past the fold on an SE, and the
  /// date is an attribute of the moment, not a statement of its own.
  final String? date;
  final String body;
  final _NodeStyle node;
  final _ThreadStyle? thread;

  /// Space under the body, which IS the visible thread length — the rail is a
  /// `Positioned` fill, so it takes whatever height this padding produces.
  ///
  /// 48 reads as a span of days while keeping each body attached to its own
  /// heading. It is a considered figure, not a spacing-scale default: below
  /// ~32 the beats crowd into one block and the diagram stops being a
  /// timeline; past ~60 the thread reads as a gap rather than a connection.
  final double bottomSpace;

  static const double _railWidth = 18;
  static const double _gutter = _railWidth + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: _gutter,
            top: 2,
            bottom: bottomSpace,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      heading,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // The dot separator is decorative; the date carries its
                    // own meaning, so only the glyph is hidden.
                    const ExcludeSemantics(
                      child: Text(
                        '·',
                        style: TextStyle(color: AppColors.textTertiaryLight),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      date!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiaryLight,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                body,
                // 18, up from 16 — this page is three short paragraphs on an
                // otherwise empty screen, and 16 left it reading as a caption
                // under a heading rather than as the page's content.
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontSize: 18,
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
