import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/streak_service.dart';

/// One cell's derived state in the "month of light" calendar (T3 / spec §6).
enum MonthCellState {
  /// A reflection landed on this local day.
  lit,

  /// Today, no reflection yet — an open invitation, not a gap.
  todayPending,

  /// A rest day (menstruation / travel-illness), gently held — NOT a gap.
  excused,

  /// Bridged by a freeze/excused run inside the current unbroken streak span.
  /// There is no per-day freeze log; derived from the streak invariant.
  held,

  /// A genuine past gap (before the current streak) or a pre-account day.
  missed,

  /// A future day in the current month — faint, not yet reached.
  future,
}

/// The immutable view model the "month of light" surface renders: the ordered
/// day→state map for the current month plus the lit count for the collapsed
/// summary. Plain immutable class (Freezed not needed for this small model).
class MonthOfLight {
  const MonthOfLight({
    required this.cells,
    required this.litCount,
    required this.month,
  });

  /// Ordered day → derived state, for every day of the current month.
  final Map<DateTime, MonthCellState> cells;

  /// Count of days lit this month (drives the collapsed summary line).
  final int litCount;

  /// First day of the current month (local), so the grid knows the offset.
  final DateTime month;

  /// A brand-new user with zero history this month — collapsed summary shows
  /// "Your month begins today ›" instead of a wall of empty cells.
  bool get isEmpty => litCount == 0;
}

String _dayKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// Pure, Supabase-free derivation of every current-month cell's state — extracted
/// so it can be unit-tested in isolation (T3 verify step 2).
///
/// Inputs:
/// - [litLocalDates]  — LOCAL YYYY-MM-DD days a reflection landed on this month.
/// - [excusedDates]   — LOCAL YYYY-MM-DD excused rest days.
/// - [currentStreak]  — `user_streaks.current_streak`.
/// - [lastActiveLocal]— `user_streaks.last_active` as YYYY-MM-DD (local), or null.
/// - [now]            — the current local instant (for "today" + month bounds).
///
/// There is NO record of WHICH past days a freeze bridged, so "held" is derived
/// from the streak invariant: if the streak is currently unbroken (last_active
/// is today-or-yesterday-local), the last N local days ending at last_active are
/// all covered — any such day with no checkin row (and not today) was bridged and
/// renders as "held", never as a "missed" gap (§6 guardrail).
Map<DateTime, MonthCellState> deriveMonthCells({
  required Set<String> litLocalDates,
  required Set<String> excusedDates,
  required int currentStreak,
  required String? lastActiveLocal,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  final daysInMonth = nextMonth.difference(monthStart).inDays;

  // The current unbroken streak span, if any. It's "unbroken" when last_active
  // is today or yesterday (local) — matching the streak service's continuity
  // rule. When unbroken, days in (spanStart, lastActive] are covered.
  DateTime? spanStart;
  DateTime? spanEnd;
  if (lastActiveLocal != null && currentStreak > 0) {
    final la = DateTime.tryParse(lastActiveLocal);
    if (la != null) {
      final lastActive = DateTime(la.year, la.month, la.day);
      final daysSince = today.difference(lastActive).inDays;
      if (daysSince == 0 || daysSince == 1) {
        // Unbroken: last N days ENDING at lastActive are all covered.
        spanEnd = lastActive;
        spanStart = lastActive.subtract(Duration(days: currentStreak - 1));
      }
    }
  }

  final localSpanStart = spanStart;
  final localSpanEnd = spanEnd;
  bool inStreakSpan(DateTime day) {
    if (localSpanStart == null || localSpanEnd == null) return false;
    // day within [spanStart, spanEnd] inclusive.
    return !day.isBefore(localSpanStart) && !day.isAfter(localSpanEnd);
  }

  final cells = <DateTime, MonthCellState>{};
  for (var i = 0; i < daysInMonth; i++) {
    final day = DateTime(now.year, now.month, i + 1);
    final key = _dayKey(day);

    MonthCellState state;
    if (day.isAfter(today)) {
      state = MonthCellState.future;
    } else if (litLocalDates.contains(key)) {
      state = MonthCellState.lit;
    } else if (day == today) {
      // Today, not yet lit (lit is handled above).
      state = MonthCellState.todayPending;
    } else if (excusedDates.contains(key)) {
      state = MonthCellState.excused;
    } else if (inStreakSpan(day)) {
      // Covered by the current unbroken streak but no checkin row → bridged.
      state = MonthCellState.held;
    } else {
      state = MonthCellState.missed;
    }
    cells[day] = state;
  }
  return cells;
}

/// Assembles the "month of light" view model from the service layer. Read-only:
/// a month-scoped checkin query + the cached streak/excused state. Degrades
/// gracefully — on error the widget falls back to "begins today" via
/// `.valueOrNull` (mirrors `pendingFreezeBurnProvider`).
final monthOfLightProvider = FutureProvider<MonthOfLight>((ref) async {
  final now = DateTime.now();
  final litDates = await fetchLitLocalDatesThisMonth();
  final excused = await getExcusedDates();
  final streak = await getStreak();

  // Normalize last_active (stored UTC YYYY-MM-DD) to a local day key. The streak
  // service persists last_active as a UTC date string; treat it as a calendar
  // day directly — the derivation only compares day-granularity against today.
  final lastActiveLocal = _lastActiveDayKey(streak.lastActive);

  final cells = deriveMonthCells(
    litLocalDates: litDates,
    excusedDates: excused,
    currentStreak: streak.currentStreak,
    lastActiveLocal: lastActiveLocal,
    now: now,
  );

  // Count lit CELLS within the month (not litDates.length) — the month-scoped
  // query floor is UTC month-start, so litDates can include a boundary day that
  // normalizes to the previous local month; counting cells keeps the summary
  // exact for far-from-UTC timezones.
  final litCount =
      cells.values.where((s) => s == MonthCellState.lit).length;

  return MonthOfLight(
    cells: cells,
    litCount: litCount,
    month: DateTime(now.year, now.month, 1),
  );
});

String? _lastActiveDayKey(String? lastActive) {
  if (lastActive == null || lastActive.isEmpty) return null;
  final parsed = DateTime.tryParse(lastActive);
  if (parsed == null) return null;
  return _dayKey(DateTime(parsed.year, parsed.month, parsed.day));
}
