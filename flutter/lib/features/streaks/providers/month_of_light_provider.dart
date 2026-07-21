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
/// - [litLocalDates]  — YYYY-MM-DD days a reflection landed on this month.
/// - [excusedDates]   — YYYY-MM-DD excused rest days.
/// - [currentStreak]  — `user_streaks.current_streak`.
/// - [lastActiveLocal]— `user_streaks.last_active` as YYYY-MM-DD (UTC, stored by
///                      streak_service._todayString which calls .toUtc()), or null.
/// - [now]            — the current instant **as UTC** (pass DateTime.now().toUtc()
///                      from the provider so both sides agree with the streak service
///                      which also operates on the UTC calendar date).
///
/// There is NO record of WHICH past days a freeze bridged, so "held" is derived
/// from the streak invariant: if the streak is currently unbroken (last_active
/// is today-or-yesterday UTC), the last N UTC days ending at last_active are
/// all covered — any such day with no checkin row (and not today) was bridged and
/// renders as "held", never as a "missed" gap (§6 guardrail).
Map<DateTime, MonthCellState> deriveMonthCells({
  required Set<String> litLocalDates,
  required Set<String> excusedDates,
  required int currentStreak,
  required String? lastActiveLocal,
  required DateTime now,
}) {
  // Use UTC constructor when now is UTC so all DateTime keys are UTC — this
  // keeps the calendar aligned with streak_service._todayString() which also
  // derives the calendar date from DateTime.now().toUtc().
  DateTime makeDay(int y, int m, int d) =>
      now.isUtc ? DateTime.utc(y, m, d) : DateTime(y, m, d);

  final today = makeDay(now.year, now.month, now.day);
  final monthStart = makeDay(now.year, now.month, 1);
  final nextMonth = makeDay(now.year, now.month + 1, 1);
  final daysInMonth = nextMonth.difference(monthStart).inDays;

  // The current unbroken streak span, if any. It's "unbroken" when last_active
  // is today or yesterday (UTC) — matching the streak service's continuity
  // rule. When unbroken, days in (spanStart, lastActive] are covered.
  DateTime? spanStart;
  DateTime? spanEnd;
  if (lastActiveLocal != null && currentStreak > 0) {
    // last_active is stored as a UTC date string by streak_service._todayString().
    // Append 'T00:00:00Z' so DateTime.tryParse treats it as UTC midnight, matching
    // the source clock. A bare "YYYY-MM-DD" (no suffix) is parsed as local time.
    final la = DateTime.tryParse('${lastActiveLocal}T00:00:00Z');
    if (la != null) {
      final lastActive = makeDay(la.year, la.month, la.day);
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
    final day = makeDay(now.year, now.month, i + 1);
    final key = _dayKey(day);

    MonthCellState state;
    if (day.isAfter(today)) {
      state = MonthCellState.future;
    } else if (litLocalDates.contains(key)) {
      state = MonthCellState.lit;
    } else if (excusedDates.contains(key)) {
      // Excused rest day (menstruation / illness) — checked before todayPending
      // so that today-as-excused renders as "rest day, gently held" not as
      // "today, not yet reflected" (the two states are mutually exclusive in
      // intent; excused explicitly overrides the open-invitation framing).
      state = MonthCellState.excused;
    } else if (day == today) {
      // Today, not yet lit and not excused — an open invitation.
      state = MonthCellState.todayPending;
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
  // Use UTC so this calendar's "today" aligns with streak_service._todayString()
  // which also derives the calendar date via DateTime.now().toUtc(). Without this,
  // east-of-UTC users see a mismatched "today" cell after local midnight while the
  // UTC date (and last_active) haven't rolled over yet.
  final now = DateTime.now().toUtc();
  final litDates = await fetchLitLocalDatesThisMonth();
  final excused = await getExcusedDates();
  final streak = await getStreak();

  // last_active is stored as a UTC date string by the streak service; pass it
  // through directly — deriveMonthCells now parses it as UTC (appends 'Z').
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
    month: DateTime.utc(now.year, now.month, 1),
  );
});

String? _lastActiveDayKey(String? lastActive) {
  if (lastActive == null || lastActive.isEmpty) return null;
  // last_active is stored as a UTC date string (streak_service uses .toUtc()).
  // Append 'T00:00:00Z' so DateTime.tryParse treats it as UTC midnight — without
  // this, a bare "2026-07-21" is parsed as local midnight, diverging from the
  // UTC clock used by the streak service for east-of-UTC users after local midnight.
  final parsed = DateTime.tryParse('${lastActive}T00:00:00Z');
  if (parsed == null) return null;
  // Normalize to midnight UTC for day-level comparisons.
  final utc = parsed.toUtc();
  return _dayKey(DateTime.utc(utc.year, utc.month, utc.day));
}
