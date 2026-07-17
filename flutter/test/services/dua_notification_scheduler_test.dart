import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_notification_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A fake [FlutterLocalNotificationsPlugin] that records scheduled/cancelled
/// ids in memory and never touches a platform channel. Implements (not extends,
/// since the real class is a factory singleton) — only the three methods the
/// scheduler calls are provided; any other call throws via [noSuchMethod].
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  /// Currently-pending ids → title (mirrors what the OS holds).
  final Map<int, String> pending = {};

  /// Every `zonedSchedule` call this process, in order (id + fire instant).
  final List<MapEntry<int, DateTime>> scheduleCalls = [];

  /// Every id passed to `cancel`.
  final List<int> cancelledIds = [];

  /// Seed a FOREIGN pending id (e.g. OneSignal's own local) directly.
  void seedForeign(int id, [String title = 'foreign']) => pending[id] = title;

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    UILocalNotificationDateInterpretation? uiLocalNotificationDateInterpretation,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    pending[id] = title ?? '';
    scheduleCalls.add(MapEntry(id, scheduledDate.toUtc()));
  }

  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => [
            for (final e in pending.entries)
              PendingNotificationRequest(e.key, e.value, e.value, null),
          ];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
    pending.remove(id);
  }

  // Any method the scheduler does not use must never be called in these tests.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Build an all-day calendar [DuaWindow] whose start is local midnight of
/// [y]/[m]/[d] in the given [zoneName]. Mirrors the engine contract (all-day
/// windows carry the device-local-midnight span as UTC).
DuaWindow _calendarWindow({
  required DuaWindowType type,
  required int y,
  required int m,
  required int d,
  required String zoneName,
}) {
  final loc = tz.getLocation(zoneName);
  final start = tz.TZDateTime(loc, y, m, d).toUtc();
  final end = tz.TZDateTime(loc, y, m, d + 1).toUtc();
  return DuaWindow(
    type: type,
    tier: DuaWindowTier.special,
    titleKey: 'dua_window.${type.name}',
    sourceRef: null,
    startUtc: start,
    endUtc: end,
    isAllDay: true,
    locationDependent: false,
  );
}

/// A location-dependent (precise) window — the scheduler MUST drop these.
DuaWindow _preciseWindow({
  required DateTime startUtc,
  required DateTime endUtc,
}) {
  return DuaWindow(
    type: DuaWindowType.lastThirdOfNight,
    tier: DuaWindowTier.hero,
    titleKey: 'dua_window.last_third_of_night',
    sourceRef: null,
    startUtc: startUtc,
    endUtc: endUtc,
    isAllDay: false,
    locationDependent: true,
  );
}

DuaWindowSchedule _schedule(List<DuaWindow> upcoming, {String tz = 'UTC'}) {
  return DuaWindowSchedule(
    upcoming: upcoming,
    computedAt: DuaScheduleStamp(
      tz: tz,
      computedThroughUtc: DateTime.utc(2027, 6, 1),
    ),
  );
}

void main() {
  // The scheduler + fixtures need the tz DB loaded (no plugin channel).
  setUpAll(tzdata.initializeTimeZones);

  // A fixed clock well before every fixture window so nothing is "past".
  final baseNow = DateTime.utc(2027, 1, 1);

  group('targeted cancel', () {
    test('a FOREIGN pending id outside the dua band SURVIVES a reschedule',
        () async {
      final plugin = _FakePlugin();
      // OneSignal-style foreign id, far outside the dua band.
      const foreignId = 42;
      plugin.seedForeign(foreignId);

      final scheduler = DuaNotificationScheduler(
        plugin: plugin,
        clock: () => baseNow,
      );

      await scheduler.reschedule(
        _schedule([
          _calendarWindow(
              type: DuaWindowType.arafah,
              y: 2027,
              m: 5,
              d: 15,
              zoneName: 'UTC'),
        ]),
        localTzName: 'UTC',
      );

      expect(plugin.cancelledIds.contains(foreignId), isFalse,
          reason: 'foreign id must never be cancelled');
      expect(plugin.pending.containsKey(foreignId), isTrue,
          reason: 'foreign id survives');
      // The dua window was scheduled inside the reserved band.
      expect(plugin.scheduleCalls, isNotEmpty);
      final scheduledId = plugin.scheduleCalls.single.key;
      expect(scheduledId >= kDuaIdBase, isTrue);
      expect(scheduledId < kDuaIdBase + kDuaIdBandSize, isTrue);
    });
  });

  group('cap enforcement', () {
    test('>40 eligible ⇒ exactly 40 scheduled, lowest priorityOf dropped',
        () async {
      final plugin = _FakePlugin();
      final scheduler = DuaNotificationScheduler(
        plugin: plugin,
        clock: () => baseNow,
      );

      // 45 white-days windows (lowest priority) + 3 arafah (highest). Distinct
      // days so ids don't collide.
      final windows = <DuaWindow>[];
      for (var i = 0; i < 45; i++) {
        windows.add(_calendarWindow(
          type: DuaWindowType.whiteDays,
          y: 2027,
          m: 3,
          d: 1 + i, // Mar 1..Apr 14
          zoneName: 'UTC',
        ));
      }
      for (var i = 0; i < 3; i++) {
        windows.add(_calendarWindow(
          type: DuaWindowType.arafah,
          y: 2027,
          m: 5,
          d: 10 + i,
          zoneName: 'UTC',
        ));
      }

      await scheduler.reschedule(_schedule(windows), localTzName: 'UTC');

      expect(plugin.scheduleCalls.length, kDuaMaxScheduled);

      // All 3 arafah (priority 100) must survive — they beat white_days (30).
      // Recompute the arafah ids and assert every one was scheduled.
      final plannedArafah = scheduler.debugPlan(
        _schedule(windows.where((w) => w.type == DuaWindowType.arafah).toList()),
        localTzName: 'UTC',
        nowUtc: baseNow,
      );
      final scheduledIds = plugin.scheduleCalls.map((e) => e.key).toSet();
      for (final e in plannedArafah) {
        expect(scheduledIds.contains(e.key), isTrue,
            reason: 'high-priority arafah must survive the cap');
      }
    });
  });

  group('deterministic / idempotent ids', () {
    test('same windows ⇒ same ids, no dupes across two reschedules', () async {
      final windows = [
        _calendarWindow(
            type: DuaWindowType.arafah, y: 2027, m: 5, d: 15, zoneName: 'UTC'),
        _calendarWindow(
            type: DuaWindowType.eid, y: 2027, m: 5, d: 16, zoneName: 'UTC'),
      ];

      // First scheduler run.
      final plugin1 = _FakePlugin();
      final s1 = DuaNotificationScheduler(plugin: plugin1, clock: () => baseNow);
      await s1.reschedule(_schedule(windows), localTzName: 'UTC');
      final ids1 = plugin1.scheduleCalls.map((e) => e.key).toList()..sort();

      // Fresh scheduler, same windows → identical ids.
      final plugin2 = _FakePlugin();
      final s2 = DuaNotificationScheduler(plugin: plugin2, clock: () => baseNow);
      await s2.reschedule(_schedule(windows), localTzName: 'UTC');
      final ids2 = plugin2.scheduleCalls.map((e) => e.key).toList()..sort();

      expect(ids2, ids1, reason: 'ids are deterministic across runs');
      // No duplicate ids within a single schedule.
      expect(ids1.toSet().length, ids1.length);

      // Re-run on plugin2 past the throttle → cancels prior band, reschedules
      // the SAME ids, still no duplicates.
      final s3 = DuaNotificationScheduler(
        plugin: plugin2,
        clock: () => baseNow.add(const Duration(hours: 1)),
      );
      await s3.reschedule(_schedule(windows), localTzName: 'UTC', force: true);
      final ids3 = plugin2.scheduleCalls
          .sublist(ids2.length)
          .map((e) => e.key)
          .toList()
        ..sort();
      expect(ids3, ids1, reason: 'reschedule reproduces the same ids');
      expect(plugin2.pending.keys.toSet().length, plugin2.pending.length,
          reason: 'no duplicate pending ids after reschedule');
    });
  });

  group('tz correctness under a non-UTC zone', () {
    test('all-day window fires at the local fire-hour in Honolulu (UTC-10)',
        () async {
      const zone = 'Pacific/Honolulu'; // UTC-10, no DST.
      final plugin = _FakePlugin();
      final scheduler = DuaNotificationScheduler(
        plugin: plugin,
        clock: () => baseNow,
      );

      final loc = tz.getLocation(zone);
      // Arafah local-midnight of 2027-05-15 in Honolulu.
      final win = _calendarWindow(
          type: DuaWindowType.arafah, y: 2027, m: 5, d: 15, zoneName: zone);

      await scheduler.reschedule(_schedule([win], tz: zone), localTzName: zone);

      expect(plugin.scheduleCalls, hasLength(1));
      final fireUtc = plugin.scheduleCalls.single.value;
      // Expected: 2027-05-15 09:00 local Honolulu = 19:00 UTC.
      final expected =
          tz.TZDateTime(loc, 2027, 5, 15, kDuaAllDayFireHour).toUtc();
      expect(fireUtc, expected);
      expect(fireUtc, DateTime.utc(2027, 5, 15, 19, 0));
    });
  });

  group('skip-if-unchanged', () {
    test('second identical reschedule issues zero new schedule calls',
        () async {
      final plugin = _FakePlugin();
      final windows = [
        _calendarWindow(
            type: DuaWindowType.arafah, y: 2027, m: 5, d: 15, zoneName: 'UTC'),
      ];

      final s1 =
          DuaNotificationScheduler(plugin: plugin, clock: () => baseNow);
      await s1.reschedule(_schedule(windows), localTzName: 'UTC');
      final firstCount = plugin.scheduleCalls.length;
      expect(firstCount, greaterThan(0));

      // Same instance, force past the throttle, identical set → no-op.
      await s1.reschedule(_schedule(windows), localTzName: 'UTC', force: true);
      expect(plugin.scheduleCalls.length, firstCount,
          reason: 'byte-identical set must not re-schedule');
    });
  });

  group('empty schedule', () {
    test('nothing scheduled, cancel still targets only the band', () async {
      final plugin = _FakePlugin();
      plugin.seedForeign(7); // foreign survivor
      final scheduler = DuaNotificationScheduler(
        plugin: plugin,
        clock: () => baseNow,
      );

      await scheduler.reschedule(_schedule(const []), localTzName: 'UTC');

      expect(plugin.scheduleCalls, isEmpty);
      expect(plugin.pending.containsKey(7), isTrue);
      expect(plugin.cancelledIds.contains(7), isFalse);
    });

    test('precise (location-dependent) windows are filtered out', () async {
      final plugin = _FakePlugin();
      final scheduler = DuaNotificationScheduler(
        plugin: plugin,
        clock: () => baseNow,
      );

      await scheduler.reschedule(
        _schedule([
          _preciseWindow(
            startUtc: DateTime.utc(2027, 5, 15, 2),
            endUtc: DateTime.utc(2027, 5, 15, 5),
          ),
        ]),
        localTzName: 'UTC',
      );

      expect(plugin.scheduleCalls, isEmpty,
          reason: 'precise windows are the server-push path, never local');
    });
  });
}
