import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';

/// One 36px, 9px-radius cell in the "month of light" grid (spec §6). Renders the
/// exact light/dark values per state, with a per-state `Semantics` label (§7).
/// Gold is a NON-TEXT accent only (glyph fill), never functional text.
class MonthOfLightCell extends StatelessWidget {
  const MonthOfLightCell({
    super.key,
    required this.day,
    required this.state,
    this.size = 36,
    this.dense = false,
  });

  final DateTime? day;
  final MonthCellState state;
  final double size;

  /// Legend swatches: no day number, tighter glyph.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = _resolve(state, isDark);

    final Widget cell = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: v.fill,
        borderRadius: BorderRadius.circular(9),
        border: v.borderColor == null
            ? null
            : Border.all(color: v.borderColor!, width: v.borderWidth),
      ),
      alignment: Alignment.center,
      child: v.glyph == null
          ? null
          : Icon(v.glyph, size: size * 0.42, color: v.glyphColor),
    );

    if (dense || day == null) {
      return SizedBox(width: size, height: size, child: cell);
    }

    return Semantics(
      label: '${day!.day}, ${_semanticFor(state)}',
      child: ExcludeSemantics(child: cell),
    );
  }
}

String _semanticFor(MonthCellState state) {
  switch (state) {
    case MonthCellState.lit:
      return 'Reflected';
    case MonthCellState.missed:
      return 'Missed';
    case MonthCellState.held:
      return 'Freeze protected';
    case MonthCellState.excused:
      return 'Rest day, gently held';
    case MonthCellState.todayPending:
      return 'Today, not yet reflected';
    case MonthCellState.future:
      return 'Upcoming';
  }
}

class _CellVisual {
  const _CellVisual({
    this.fill,
    this.glyph,
    this.glyphColor,
    this.borderColor,
    this.borderWidth = 1,
  });
  final Color? fill;
  final IconData? glyph;
  final Color? glyphColor;
  final Color? borderColor;
  final double borderWidth;
}

/// Exact per-state values from spec §6 (light / dark). Raw hex only for these
/// cell-state values, as the spec directs.
_CellVisual _resolve(MonthCellState state, bool isDark) {
  switch (state) {
    case MonthCellState.lit:
      return _CellVisual(
        fill: isDark ? const Color(0x24C8985E) : const Color(0xFFEAF1EC),
        glyph: Icons.brightness_1,
        glyphColor: isDark ? const Color(0xFFD9AE72) : AppColors.secondary,
      );
    case MonthCellState.missed:
      return _CellVisual(
        borderColor: isDark ? const Color(0xFF3A342C) : const Color(0xFFDDD3C4),
      );
    case MonthCellState.held:
      return _CellVisual(
        fill: isDark ? const Color(0x2E3E7F86) : const Color(0xFFE4EEF0),
        glyph: Icons.shield,
        glyphColor: isDark ? const Color(0xFF6FB7BE) : const Color(0xFF3E7F86),
      );
    case MonthCellState.excused:
      return _CellVisual(
        fill: isDark ? const Color(0x0DFFFFFF) : const Color(0xFFF3EEE6),
        glyph: Icons.circle,
        glyphColor: isDark ? const Color(0xFF8C8478) : const Color(0xFFB7AC99),
      );
    case MonthCellState.todayPending:
      return _CellVisual(
        borderColor: isDark ? const Color(0xFF3E9A6E) : AppColors.primary,
        borderWidth: 2,
      );
    case MonthCellState.future:
      return _CellVisual(
        fill: isDark ? const Color(0x08FFFFFF) : const Color(0xFFEFE8DC),
      );
  }
}
