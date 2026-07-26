import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugQuestBoundariesClock = () => DateTime.now().toUtc();
  });

  test('weekStart returns the UTC Monday midnight, not local Monday', () {
    // 11:30 PM EST on Sunday 2026-05-10 = 04:30 UTC on Monday 2026-05-11.
    // Local week would still be the previous week; UTC week starts at
    // 2026-05-11 00:00 UTC (Monday).
    debugQuestBoundariesClock = () => DateTime.utc(2026, 5, 11, 4, 30);
    final weekStart = debugQuestWeekStart();
    expect(weekStart, DateTime.utc(2026, 5, 11));
    expect(weekStart.isUtc, isTrue);
  });

  test('monthStart returns the 1st of the UTC month', () {
    debugQuestBoundariesClock = () => DateTime.utc(2026, 5, 13, 4, 30);
    final monthStart = debugQuestMonthStart();
    expect(monthStart, DateTime.utc(2026, 5, 1));
    expect(monthStart.isUtc, isTrue);
  });

  // One Ship W1 (decision 0.1.4): rotation labels + pool-selection seeds must
  // derive from debugQuestBoundariesClock — the same clock persistence uses —
  // never from local DateTime.now(). Previously a user west of UTC near
  // midnight built quest IDs (date part AND pool index) that disagreed with
  // the persisted period_start, orphaning in-progress rows.
  group('rotation labels/seeds align with UTC persistence boundaries', () {
    test('daily label matches the UTC date of the clock (11pm ET case)', () {
      // 2026-07-25 03:00 UTC == 11:00 PM ET on July 24 — the bug window.
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 25, 3, 0);
      expect(debugQuestTodayLabel(), '2026-07-25');
    });

    test('labels and seeds are stable across every instant of a UTC day', () {
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 25, 0, 1);
      final earlyLabel = debugQuestTodayLabel();
      final earlyDaily = debugQuestDailySeed();
      final earlyWeekly = debugQuestWeeklySeed();

      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 25, 23, 59);
      expect(debugQuestTodayLabel(), earlyLabel);
      expect(debugQuestDailySeed(), earlyDaily,
          reason: 'pool selection must not flip mid-UTC-day');
      expect(debugQuestWeeklySeed(), earlyWeekly);
    });

    test('daily seed advances exactly with the UTC day', () {
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 25, 12);
      final saturday = debugQuestDailySeed();
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 26, 12);
      expect(debugQuestDailySeed(), saturday + 1);
    });

    test('week label date equals the persisted weekStart across the '
        'Sunday/Monday UTC boundary', () {
      // Sunday 2026-07-26 23:59 UTC → week of Monday July 20.
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 26, 23, 59);
      expect(debugQuestWeekLabel(), '2026-W07-20');
      expect(debugQuestWeekStart(), DateTime.utc(2026, 7, 20));

      // Monday 2026-07-27 00:01 UTC → new week, label and weekStart together.
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 27, 0, 1);
      expect(debugQuestWeekLabel(), '2026-W07-27');
      expect(debugQuestWeekStart(), DateTime.utc(2026, 7, 27));
    });

    test('month label and monthly seed roll together at the UTC 1st', () {
      debugQuestBoundariesClock = () => DateTime.utc(2026, 7, 31, 23, 59);
      expect(debugQuestMonthLabel(), '2026-07');
      expect(debugQuestMonthStart(), DateTime.utc(2026, 7, 1));

      debugQuestBoundariesClock = () => DateTime.utc(2026, 8, 1, 0, 1);
      expect(debugQuestMonthLabel(), '2026-08');
      expect(debugQuestMonthStart(), DateTime.utc(2026, 8, 1));
    });
  });
}
