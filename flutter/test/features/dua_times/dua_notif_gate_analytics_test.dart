import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/providers/dua_notification_scheduler_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_notification_scheduler.dart';
import 'package:sakina/services/dua_precise_sync_service.dart';
import 'package:sakina/services/notification_service.dart';

/// Minimal doubles via `implements` + `noSuchMethod` so the gate can be
/// exercised without the notifications plugin / Supabase / a real sync.
class _StubScheduler implements DuaNotificationScheduler {
  int reschedules = 0;
  int cancels = 0;
  @override
  Future<void> reschedule(DuaWindowSchedule schedule,
      {required String localTzName, bool force = false}) async {
    reschedules++;
  }

  @override
  Future<void> cancelAllDuaNotifications() async {
    cancels++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubNotif implements NotificationService {
  _StubNotif({this.optedIn = true, this.duaEnabled = true});
  final bool optedIn;
  final bool duaEnabled;
  @override
  bool get isOptedIn => optedIn;
  @override
  Future<Map<String, bool>> getNotificationPreferences() async =>
      {notifyDuaWindowsTagKey: duaEnabled};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSync implements DuaPreciseSyncService {
  _StubSync(this.result);
  final DuaPreciseSyncResult result;
  int syncCalls = 0;
  int clearCalls = 0;
  @override
  Future<DuaPreciseSyncResult> sync() async {
    syncCalls++;
    return result;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DuaWindowSchedule _schedule() => DuaWindowSchedule(
      computedAt: DuaScheduleStamp(
        tz: 'UTC',
        computedThroughUtc: DateTime.utc(2027, 3, 1),
      ),
    );

DateTime _clock() => DateTime.utc(2027, 2, 5, 12);

void main() {
  final events = <String>[];
  final props = <Map<String, dynamic>>[];

  setUp(() {
    events.clear();
    props.clear();
    DuaNotificationGate.onAnalyticsEvent = (e, p) {
      events.add(e);
      props.add(p);
    };
  });

  tearDown(() => DuaNotificationGate.onAnalyticsEvent = null);

  test('apply emits dua_notif_synced{count,outcome} when a sync runs', () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced, count: 7),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      clock: _clock,
    );

    await gate.apply(_schedule());

    expect(sync.syncCalls, 1);
    expect(events, [AnalyticsEvents.duaNotifSynced]);
    expect(props.single[AnalyticsEvents.propCount], 7);
    expect(props.single[AnalyticsEvents.propOutcome], 'synced');
  });

  test('opted-out → clears, emits nothing (no sync ran)', () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced, count: 3),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: false),
      preciseSync: sync,
      clock: _clock,
    );

    await gate.apply(_schedule());

    expect(sync.syncCalls, 0); // disabled path never syncs
    expect(sync.clearCalls, 1); // it clears instead
    expect(events, isEmpty);
  });

  test('skipped outcome (signed-out no-op) → sync runs but emits nothing',
      () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.skipped),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      clock: _clock,
    );

    await gate.apply(_schedule());

    expect(sync.syncCalls, 1); // the sync ran…
    expect(events, isEmpty); // …but a no-op skip isn't a data point
  });

  test('throttled second apply → sync + emit only once', () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced, count: 4),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      clock: _clock, // fixed → the 2nd apply is inside the 6h throttle
    );

    await gate.apply(_schedule());
    await gate.apply(_schedule());

    expect(sync.syncCalls, 1); // second was throttle-skipped
    expect(events, [AnalyticsEvents.duaNotifSynced]); // exactly one emit
  });

  test('forced apply bypasses the throttle → emits each time', () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.cleared),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      clock: _clock,
    );

    await gate.apply(_schedule(), force: true);
    await gate.apply(_schedule(), force: true);

    expect(sync.syncCalls, 2);
    expect(events.length, 2);
    expect(props.last[AnalyticsEvents.propOutcome], 'cleared');
    expect(props.last[AnalyticsEvents.propCount], 0);
  });
}
