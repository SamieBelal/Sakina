import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

/// Pins the streak analytics chokepoint (retention audit 2026-06-01). Events
/// emit only from the committed path, exactly once per real increment — the
/// already-active-today early return must NOT double-fire.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late List<(String, Map<String, dynamic>)> events;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    events = [];
    StreakAnalytics.onAnalyticsEvent =
        (event, props) => events.add((event, props));
  });

  tearDown(() {
    StreakAnalytics.onAnalyticsEvent = null;
    SupabaseSyncService.debugReset();
  });

  Iterable<(String, Map<String, dynamic>)> of(String name) =>
      events.where((e) => e.$1 == name);

  test('markActiveToday on a fresh day fires streak_extended with the new day',
      () async {
    final result = await markActiveToday();

    final ext = of(AnalyticsEvents.streakExtended).toList();
    expect(ext.length, 1);
    expect(result.currentStreak, 1);
    expect(ext.first.$2['streak_day'], 1);
    expect(of(AnalyticsEvents.streakFreezeConsumed), isEmpty);
  });

  test('already-active-today does NOT double-fire streak_extended', () async {
    await markActiveToday();
    events.clear();

    await markActiveToday(); // same day → early return

    expect(of(AnalyticsEvents.streakExtended), isEmpty);
  });

  test('streak_freeze_consumed fires when a gap is bridged by a freeze',
      () async {
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 5,
      'longest_streak': 10,
      'last_active': '2026-04-01',
    };
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => true;

    final result = await markActiveToday();

    expect(result.currentStreak, 6, reason: 'freeze bridged the gap');
    expect(of(AnalyticsEvents.streakFreezeConsumed).length, 1);
    expect(of(AnalyticsEvents.streakFreezeConsumed).first.$2['streak_day'], 6);
    expect(of(AnalyticsEvents.streakExtended).length, 1);
  });

  test(
      'streak_extended is suppressed (but streak_freeze_consumed still fires) '
      'when the user_streaks upsert fails on a freeze day', () async {
    fakeSync.rows['user_streaks:user-1'] = {
      'current_streak': 5,
      'longest_streak': 10,
      'last_active': '2026-04-01', // multi-day gap → needs a freeze
    };
    fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => true;
    // Force the user_streaks upsert to fail. The freeze already committed
    // server-side, so the code falls through (caches locally) but must NOT
    // report a server-unpersisted streak_extended day.
    fakeSync.nextUpsertShouldFail = true;

    await markActiveToday();

    expect(of(AnalyticsEvents.streakExtended), isEmpty,
        reason: 'unpersisted streak increment must not emit streak_extended');
    expect(of(AnalyticsEvents.streakFreezeConsumed).length, 1,
        reason: 'the freeze committed server-side, so it still fires');
  });

  test('checkStreakMilestones emits streak_milestone for a newly crossed day',
      () async {
    final reached = await checkStreakMilestones(7);

    expect(reached, isNotEmpty);
    final ms = of(AnalyticsEvents.streakMilestone).toList();
    expect(ms.length, 1);
    expect(ms.first.$2['streak_day'], 7);
  });

  test('checkStreakMilestones does not re-emit an already-claimed milestone',
      () async {
    await checkStreakMilestones(7);
    events.clear();

    await checkStreakMilestones(7); // already claimed

    expect(of(AnalyticsEvents.streakMilestone), isEmpty);
  });

  // ---------------------------------------------------------------------------
  // streak_lapsed outcome discrimination (analytics-correctness fix)
  // streak_lapsed must carry an 'outcome' property so Mixpanel can segment
  // forgiven returns from truly-lost streaks.
  // ---------------------------------------------------------------------------
  group('streak_lapsed outcome property', () {
    String utcDay(int deltaDays) {
      final d = DateTime.now().toUtc().add(Duration(days: deltaDays));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    test(
        '(a) gap within 48h free window → streak_lapsed fires with outcome==effort',
        () async {
      // Last active yesterday: one missed day, still within 48h free window.
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 5,
        'longest_streak': 10,
        'last_active': utcDay(-2), // missed yesterday, within 48h
      };
      fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

      await markActiveToday();

      final lapsed = of(AnalyticsEvents.streakLapsed).toList();
      expect(lapsed.length, 1,
          reason: 'a gap occurred, so streak_lapsed must fire');
      expect(lapsed.first.$2['outcome'], AnalyticsEvents.repairMethodEffort,
          reason: 'within 48h free window → outcome must be "effort"');
    });

    test(
        '(b) gap past 48h WITH freeze available/consumed → streak_lapsed fires '
        'with outcome==freeze', () async {
      // Last active 4 days ago: well past 48h window, but freeze is available.
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 8,
        'longest_streak': 10,
        'last_active': utcDay(-4), // 3 missed days → past window
      };
      fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => true;

      await markActiveToday();

      final lapsed = of(AnalyticsEvents.streakLapsed).toList();
      expect(lapsed.length, 1,
          reason: 'a gap occurred, so streak_lapsed must fire');
      expect(lapsed.first.$2['outcome'], AnalyticsEvents.repairMethodFreeze,
          reason: 'freeze consumed → outcome must be "freeze"');
    });

    test(
        '(c) gap past 48h with NO freeze → streak_lapsed fires with '
        'outcome==expired (and streak truly resets)', () async {
      // Last active 4 days ago, no freeze.
      fakeSync.rows['user_streaks:user-1'] = {
        'current_streak': 15,
        'longest_streak': 20,
        'last_active': utcDay(-4), // past window
      };
      fakeSync.rpcHandlers['consume_streak_freeze'] = (_) async => false;

      final result = await markActiveToday();

      expect(result.currentStreak, 1,
          reason: 'expired streak resets to 1');
      expect(result.preLapseStreak, 15,
          reason: 'pre-lapse streak saved for buy-back');

      final lapsed = of(AnalyticsEvents.streakLapsed).toList();
      expect(lapsed.length, 1,
          reason: 'a gap occurred, so streak_lapsed must fire');
      expect(lapsed.first.$2['outcome'], 'expired',
          reason: 'no freeze, past window → outcome must be "expired"');
    });
  });
}
