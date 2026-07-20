import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/providers/month_of_light_provider.dart';

/// Pure derivation tests for the "month of light" chain calendar (T3 / §6).
/// No Supabase — `deriveMonthCells` is a pure top-level function.
void main() {
  String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  group('deriveMonthCells', () {
    // Anchor "now" mid-month so there's room for past and future days.
    final now = DateTime(2026, 7, 20, 10, 0);
    final today = DateTime(2026, 7, 20);

    test('a lit day → lit', () {
      final litDay = DateTime(2026, 7, 5);
      final cells = deriveMonthCells(
        litLocalDates: {key(litDay)},
        excusedDates: const {},
        currentStreak: 0,
        lastActiveLocal: null,
        now: now,
      );
      expect(cells[litDay], MonthCellState.lit);
    });

    test('a within-streak-span no-checkin day → held (NOT missed)', () {
      // Streak of 5 ending today (last_active = today). Days 16..20 are covered.
      // Day 18 has no checkin row → it must read as held (freeze/excused bridge).
      final bridged = DateTime(2026, 7, 18);
      final cells = deriveMonthCells(
        litLocalDates: {key(DateTime(2026, 7, 16)), key(DateTime(2026, 7, 17))},
        excusedDates: const {},
        currentStreak: 5,
        lastActiveLocal: key(today),
        now: now,
      );
      expect(cells[bridged], MonthCellState.held);
      expect(cells[bridged], isNot(MonthCellState.missed));
    });

    test('an excused day → excused', () {
      final rest = DateTime(2026, 7, 10);
      final cells = deriveMonthCells(
        litLocalDates: const {},
        excusedDates: {key(rest)},
        currentStreak: 0,
        lastActiveLocal: null,
        now: now,
      );
      expect(cells[rest], MonthCellState.excused);
    });

    test('excused wins over held when a day is both excused and in span', () {
      final rest = DateTime(2026, 7, 18);
      final cells = deriveMonthCells(
        litLocalDates: const {},
        excusedDates: {key(rest)},
        currentStreak: 5,
        lastActiveLocal: key(today),
        now: now,
      );
      expect(cells[rest], MonthCellState.excused);
    });

    test('today with no checkin → today-pending', () {
      final cells = deriveMonthCells(
        litLocalDates: const {},
        excusedDates: const {},
        currentStreak: 0,
        lastActiveLocal: null,
        now: now,
      );
      expect(cells[today], MonthCellState.todayPending);
    });

    test('today lit → lit (not today-pending)', () {
      final cells = deriveMonthCells(
        litLocalDates: {key(today)},
        excusedDates: const {},
        currentStreak: 1,
        lastActiveLocal: key(today),
        now: now,
      );
      expect(cells[today], MonthCellState.lit);
    });

    test('a genuine pre-streak gap → missed', () {
      // Streak of 2 ending today covers 19..20. Day 5 is a real past gap.
      final gap = DateTime(2026, 7, 5);
      final cells = deriveMonthCells(
        litLocalDates: {key(DateTime(2026, 7, 19)), key(today)},
        excusedDates: const {},
        currentStreak: 2,
        lastActiveLocal: key(today),
        now: now,
      );
      expect(cells[gap], MonthCellState.missed);
    });

    test('future days of the month → future', () {
      final future = DateTime(2026, 7, 25);
      final cells = deriveMonthCells(
        litLocalDates: const {},
        excusedDates: const {},
        currentStreak: 0,
        lastActiveLocal: null,
        now: now,
      );
      expect(cells[future], MonthCellState.future);
    });

    test('broken streak (last_active older than yesterday) → no held span', () {
      // last_active 5 days ago → streak not currently unbroken → prior no-checkin
      // days are genuine gaps (missed), not held.
      final oldActive = DateTime(2026, 7, 12);
      final cells = deriveMonthCells(
        litLocalDates: {key(oldActive)},
        excusedDates: const {},
        currentStreak: 3,
        lastActiveLocal: key(oldActive),
        now: now,
      );
      // A day just before oldActive with no checkin is missed, not held.
      expect(cells[DateTime(2026, 7, 11)], MonthCellState.missed);
    });

    test('day-0 new user: empty lit set → zero lit, only today-pending', () {
      final cells = deriveMonthCells(
        litLocalDates: const {},
        excusedDates: const {},
        currentStreak: 0,
        lastActiveLocal: null,
        now: now,
      );
      final litCount =
          cells.values.where((s) => s == MonthCellState.lit).length;
      expect(litCount, 0);
      expect(cells[today], MonthCellState.todayPending);
      // Past days for a brand-new user are missed/pre-account, never held.
      expect(cells.values.contains(MonthCellState.held), isFalse);
    });

    test('grid covers exactly the days in the current month', () {
      final cells = deriveMonthCells(
        litLocalDates: const {},
        excusedDates: const {},
        currentStreak: 0,
        lastActiveLocal: null,
        now: now,
      );
      expect(cells.length, 31); // July has 31 days
    });
  });
}
