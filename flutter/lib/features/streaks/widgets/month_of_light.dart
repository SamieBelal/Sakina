import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';
import 'package:sakina/features/streaks/widgets/month_of_light_cell.dart';

/// Open the full current-month "month of light" grid on its own surface (T3 /
/// S3 / D1): a bottom-anchored cream sheet, top-rounded 28px — matching the
/// pattern in `streak_rescue_sheet.dart`. Read-only.
Future<void> showMonthOfLightSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Mount on the ROOT navigator so the sheet + scrim rise over the AppShell's
    // bottom nav bar. On the default shell navigator the sheet mounts inside the
    // scaffold body, so the nav bar (a separate scaffold slot) renders on top of
    // it. Inner SafeArea(top:false) keeps content clear of the home indicator.
    useRootNavigator: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    clipBehavior: Clip.antiAlias,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _MonthOfLightSheet(),
  );
}

class _MonthOfLightSheet extends ConsumerWidget {
  const _MonthOfLightSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(monthOfLightProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your month of light',
                style: AppTypography.headlineMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // The "N days lit" stat lives here now (moved off the hero so the
              // Home screen keeps a single status line above the Name reveal).
              if (data != null) ...[
                const SizedBox(height: 4),
                Text(
                  data.litCount == 0
                      ? 'Your month begins today'
                      : '${data.litCount} ${data.litCount == 1 ? 'day' : 'days'} lit this month',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (data == null)
                const _GridSkeleton()
              else
                _MonthGrid(data: data),
              const SizedBox(height: 20),
              const _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A calm fixed-height placeholder while the provider resolves (no spinner —
/// keep it quiet, §7 respects reduced motion by using none).
class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 240, child: SizedBox.shrink());
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.data});
  final MonthOfLight data;

  static const double _rowSpacing = 6;

  @override
  Widget build(BuildContext context) {
    final month = data.month;
    // Weekday of the 1st (Mon=1..Sun=7). Grid is Sunday-first, so leading blanks
    // = weekday % 7 (Sun→0, Mon→1, ... Sat→6).
    final leadingBlanks = month.weekday % 7;
    final days = data.cells.keys.toList()..sort();

    // Size the 7 columns to the FULL available width so the grid stretches
    // edge-to-edge (a fixed-width Wrap left the right side short). spaceBetween
    // then pins the first cell to the left edge and the last to the right edge,
    // filling perfectly regardless of sub-pixel rounding.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - _rowSpacing * 6) / 7;

        // Flatten leading blanks + day cells into a single stream, then pad the
        // final partial week with trailing blanks so every Row holds exactly 7.
        final cells = <Widget>[
          for (var i = 0; i < leadingBlanks; i++)
            SizedBox(width: cellSize, height: cellSize),
          for (final day in days)
            MonthOfLightCell(day: day, state: data.cells[day]!, size: cellSize),
        ];
        while (cells.length % 7 != 0) {
          cells.add(SizedBox(width: cellSize, height: cellSize));
        }

        final rows = <Widget>[];
        for (var i = 0; i < cells.length; i += 7) {
          rows.add(Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cells.sublist(i, i + 7),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeekdayHeader(cellSize: cellSize),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: _rowSpacing),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.cellSize});

  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.textSecondaryDark : AppColors.textTertiaryLight;
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final l in labels)
          SizedBox(
            width: cellSize,
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const entries = <MapEntry<MonthCellState, String>>[
      MapEntry(MonthCellState.lit, 'Lit'),
      MapEntry(MonthCellState.held, 'Frozen'),
      MapEntry(MonthCellState.excused, 'Excused'),
      MapEntry(MonthCellState.missed, 'Missed'),
      MapEntry(MonthCellState.todayPending, 'Today'),
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        for (final e in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MonthOfLightCell(day: null, state: e.key, size: 18, dense: true),
              const SizedBox(width: 6),
              Text(
                e.value,
                style: AppTypography.labelSmall.copyWith(color: labelColor),
              ),
            ],
          ),
      ],
    );
  }
}
