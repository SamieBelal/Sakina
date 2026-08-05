import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/providers/dua_notification_scheduler_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_notification_scheduler.dart';
import 'package:sakina/services/dua_precise_sync_service.dart';
import 'package:sakina/services/dua_precise_sync_state_store.dart';
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

/// No lat → the gate reads this as "location absent this run".
DuaWindowSchedule _unlocatedSchedule() => _schedule();

/// A lat stamp is the signal the user's location capability is back.
DuaWindowSchedule _locatedSchedule() => DuaWindowSchedule(
      computedAt: DuaScheduleStamp(
        tz: 'UTC',
        lat: 21.4225,
        lon: 39.8262,
        computedThroughUtc: DateTime.utc(2027, 3, 1),
      ),
    );

DateTime _clock() => DateTime.utc(2027, 2, 5, 12);

/// In-memory [DuaPreciseSyncStateStore]. The real one is SharedPreferences-
/// backed; without this, an uninitialised prefs store reads as "never synced"
/// and every apply looks unthrottled.
class _MemStore implements DuaPreciseSyncStateStore {
  DuaPreciseSyncState state = const DuaPreciseSyncState();
  int clearCalls = 0;

  @override
  Future<DuaPreciseSyncState> read() async => state;

  @override
  Future<void> write(DuaPreciseSyncState s) async => state = s;

  @override
  Future<void> clear() async {
    clearCalls++;
    state = const DuaPreciseSyncState();
  }
}

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

  test('apply emits dua_notif_synced{count,outcome,sync_version} on a synced run',
      () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(
        DuaPreciseSyncOutcome.synced,
        count: 7,
        syncVersion: 42,
      ),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      syncStateStore: _MemStore(),
      clock: _clock,
    );

    await gate.apply(_schedule());

    expect(sync.syncCalls, 1);
    expect(events, [AnalyticsEvents.duaNotifSynced]);
    expect(props.single[AnalyticsEvents.propCount], 7);
    expect(props.single[AnalyticsEvents.propOutcome], 'synced');
    // The per-sync join key to server notification_sent.
    expect(props.single[AnalyticsEvents.propSyncVersion], 42);
  });

  test('cleared outcome emits no sync_version (only present on synced)',
      () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.cleared),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      syncStateStore: _MemStore(),
      clock: _clock,
    );

    await gate.apply(_schedule());

    expect(props.single[AnalyticsEvents.propOutcome], 'cleared');
    expect(props.single.containsKey(AnalyticsEvents.propSyncVersion), false);
  });

  test('opted-out → clears, emits nothing (no sync ran)', () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced, count: 3),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: false),
      preciseSync: sync,
      syncStateStore: _MemStore(),
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
      syncStateStore: _MemStore(),
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
      syncStateStore: _MemStore(),
      clock: _clock, // fixed → the 2nd apply is inside the 6h throttle
    );

    await gate.apply(_schedule());
    await gate.apply(_schedule());

    expect(sync.syncCalls, 1); // second was throttle-skipped
    expect(events, [AnalyticsEvents.duaNotifSynced]); // exactly one emit
  });

  // ── The 2026-08 "grant never reached the server" regression ───────────────
  //
  // Cold launch with no location armed the 6h throttle; the user then granted
  // and the repair sync was silently skipped. The reporter's every recorded
  // sync outcome was `cleared`, never once `synced`, across two days on which a
  // located schedule was demonstrably built.
  test('location regained → syncs immediately, throttle notwithstanding',
      () async {
    final store = _MemStore();
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.retained,
          reason: 'no_location'),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      syncStateStore: store,
      clock: _clock, // fixed — everything below is inside the 6h window
    );

    // 1. Cold launch, no location. Arms the throttle, deletes nothing.
    await gate.apply(_unlocatedSchedule());
    expect(sync.syncCalls, 1);
    expect(store.state.lastLocationPresent, isFalse);

    // 2. The user taps "Turn on" and grants. The rebuilt schedule now carries a
    //    lat — and this MUST sync despite being seconds inside the throttle.
    final located = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced,
          count: 12, syncVersion: 3, locationPresent: true),
    );
    final gate2 = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: located,
      syncStateStore: store,
      clock: _clock,
    );
    await gate2.apply(_locatedSchedule());

    expect(located.syncCalls, 1,
        reason: 'the transition must beat the throttle — this IS the bug');
    expect(props.last[AnalyticsEvents.propOutcome], 'synced');
    expect(store.state.lastLocationPresent, isTrue);
  });

  test('retained emits reason + location_present so the gap is queryable',
      () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.retained,
          reason: 'no_location'),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      syncStateStore: _MemStore(),
      clock: _clock,
    );

    await gate.apply(_unlocatedSchedule());

    expect(props.single[AnalyticsEvents.propOutcome], 'retained');
    expect(props.single[AnalyticsEvents.propReason], 'no_location');
    expect(props.single[AnalyticsEvents.propLocationPresent], isFalse);
  });

  test('a failed sync retries sooner than six hours', () async {
    final store = _MemStore();
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.failed),
    );
    var now = DateTime.utc(2027, 2, 5, 12);
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      syncStateStore: store,
      clock: () => now,
    );

    await gate.apply(_unlocatedSchedule());
    expect(sync.syncCalls, 1);

    // Five minutes later — still inside the retry window.
    now = now.add(const Duration(minutes: 5));
    await gate.apply(_unlocatedSchedule());
    expect(sync.syncCalls, 1);

    // Twenty minutes on — past the 15-minute retry throttle, well short of 6h.
    now = now.add(const Duration(minutes: 20));
    await gate.apply(_unlocatedSchedule());
    expect(sync.syncCalls, 2);
  });

  test('the throttle survives a new gate over the same store (cold launch)',
      () async {
    final store = _MemStore();
    final a = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced,
          count: 5, locationPresent: true),
    );
    await DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: a,
      syncStateStore: store,
      clock: _clock,
    ).apply(_locatedSchedule());
    expect(a.syncCalls, 1);

    final b = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.synced,
          count: 5, locationPresent: true),
    );
    await DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: b,
      syncStateStore: store,
      clock: _clock,
    ).apply(_locatedSchedule());

    expect(b.syncCalls, 0,
        reason: 'the per-launch reset is what made the delete-all fire so often');
  });

  test('forced apply bypasses the throttle → emits each time', () async {
    final sync = _StubSync(
      const DuaPreciseSyncResult(DuaPreciseSyncOutcome.cleared),
    );
    final gate = DuaNotificationGate(
      scheduler: _StubScheduler(),
      notificationService: _StubNotif(optedIn: true, duaEnabled: true),
      preciseSync: sync,
      syncStateStore: _MemStore(),
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
