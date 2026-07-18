import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_live_activity_service.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/widget_data_service.dart';

/// Records every native Live-Activity call the provider drives through the seam.
class _FakeChannel implements LiveActivityChannel {
  final List<String> calls = <String>[];
  @override
  Future<bool> isSupported() async => true;
  @override
  Future<void> start(Map<String, dynamic> content) async => calls.add('start');
  @override
  Future<void> update(Map<String, dynamic> content) async =>
      calls.add('update');
  @override
  Future<void> end(Map<String, dynamic> args) async => calls.add('end');
}

/// No-op widget client so `_pushToWidget` doesn't hit the real plugin.
class _NoopWidgetClient implements HomeWidgetClient {
  @override
  Future<void> setAppGroupId(String id) async {}
  @override
  Future<void> saveWidgetData(String key, String? value) async {}
  @override
  Future<void> updateWidget({required String name}) async {}
}

DateTime _clock() => DateTime.utc(2027, 5, 15, 23, 0);

DuaScheduleStamp _stamp() => DuaScheduleStamp(
      tz: 'Asia/Riyadh',
      lat: 21.4,
      lon: 39.8,
      computedThroughUtc: DateTime.utc(2027, 5, 22, 21, 0),
    );

/// Active, time-boxed (last third of the night), closing.
DuaWindowSchedule _timeBoxedActive() => DuaWindowSchedule(
      active: DuaWindow(
        type: DuaWindowType.lastThirdOfNight,
        tier: DuaWindowTier.hero,
        titleKey: 'dua_window.last_third.title',
        startUtc: DateTime.utc(2027, 5, 15, 22, 0),
        endUtc: DateTime.utc(2027, 5, 16, 2, 0),
        isAllDay: false,
        locationDependent: true,
      ),
      urgency: UrgencyState.closing,
      computedAt: _stamp(),
    );

/// Active but ALL-DAY (ʿArafah) — must be skipped (O1/O2).
DuaWindowSchedule _allDayActive() => DuaWindowSchedule(
      active: DuaWindow(
        type: DuaWindowType.arafah,
        tier: DuaWindowTier.hero,
        titleKey: 'dua_window.arafah',
        startUtc: DateTime.utc(2027, 5, 15, 0, 0),
        endUtc: DateTime.utc(2027, 5, 16, 0, 0),
        isAllDay: true,
        locationDependent: false,
      ),
      urgency: UrgencyState.allDay,
      computedAt: _stamp(),
    );

/// No active window (between).
DuaWindowSchedule _between() => DuaWindowSchedule(
      active: null,
      urgency: UrgencyState.upcoming,
      computedAt: _stamp(),
    );

DuaWindowNotifier _notifier(DuaLiveActivityService liveActivity) {
  final repo = DuaWindowRepository(
    prefs: SharedPreferences.getInstance,
    loadAsset: (_) async => '{"rows":[]}',
  );
  final location = LocationService(
    checkPermission: () async => LocationPermission.denied,
    requestPermission: () async => LocationPermission.denied,
    serviceEnabled: () async => false,
    prefs: SharedPreferences.getInstance,
  );
  return DuaWindowNotifier(
    engine: DuaWindowEngine(repository: repo, locationService: location),
    locationService: location,
    repository: repo,
    clock: _clock,
    resolveTimezone: () async => 'Asia/Riyadh',
    widgetDataService: WidgetDataService(client: _NoopWidgetClient()),
    liveActivityService: liveActivity,
    observeLifecycle: false,
    autoBuild: false,
    startTicker: false,
  );
}

void main() {
  final events = <String>[];
  final props = <Map<String, dynamic>>[];

  setUp(() {
    events.clear();
    props.clear();
    DuaWindowNotifier.onAnalyticsEvent = (e, p) {
      events.add(e);
      props.add(p);
    };
  });

  tearDown(() => DuaWindowNotifier.onAnalyticsEvent = null);

  // debugPreview drives the same `_syncLiveActivity` path as `rebuild()`, so it
  // is the deterministic way to exercise the wiring without the async engine.
  test('active time-boxed window → starts activity + started analytics',
      () async {
    final channel = _FakeChannel();
    final notifier = _notifier(DuaLiveActivityService(channel: channel));

    notifier.debugPreview(_timeBoxedActive());
    await pumpEventQueue();

    expect(channel.calls, ['start']);
    expect(events, contains(AnalyticsEvents.duaLiveActivityStarted));
    final started = props[events.indexOf(AnalyticsEvents.duaLiveActivityStarted)];
    expect(started[AnalyticsEvents.propActiveWindow], 'last_third_of_night');
    expect(started[AnalyticsEvents.propUrgency], 'closing');
  });

  test('window closes (between) → ends activity + ended{window_closed}',
      () async {
    final channel = _FakeChannel();
    final notifier = _notifier(DuaLiveActivityService(channel: channel));

    notifier.debugPreview(_timeBoxedActive());
    await pumpEventQueue();
    notifier.debugPreview(_between());
    await pumpEventQueue();

    expect(channel.calls, ['start', 'end']);
    expect(events.last, AnalyticsEvents.duaLiveActivityEnded);
    expect(props.last['reason'], AnalyticsEvents.liveActivityEndWindowClosed);
  });

  test('all-day active window is skipped (O1): no start, ends any live one',
      () async {
    final channel = _FakeChannel();
    final notifier = _notifier(DuaLiveActivityService(channel: channel));

    // First a time-boxed window starts one...
    notifier.debugPreview(_timeBoxedActive());
    await pumpEventQueue();
    // ...then an all-day window becomes active → must END, not keep/replace.
    notifier.debugPreview(_allDayActive());
    await pumpEventQueue();

    expect(channel.calls, ['start', 'end']);
    // No second start for the all-day window.
    expect(channel.calls.where((c) => c == 'start').length, 1);
  });

  test('idempotent (O4): re-previewing the same active window does not restart',
      () async {
    final channel = _FakeChannel();
    final notifier = _notifier(DuaLiveActivityService(channel: channel));

    notifier.debugPreview(_timeBoxedActive());
    await pumpEventQueue();
    notifier.debugPreview(_timeBoxedActive()); // identical → perf guard
    await pumpEventQueue();

    expect(channel.calls, ['start']); // exactly one start, no update
    expect(
      events.where((e) => e == AnalyticsEvents.duaLiveActivityStarted).length,
      1,
    );
  });
}
