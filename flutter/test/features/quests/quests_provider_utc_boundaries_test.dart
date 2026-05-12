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
}
