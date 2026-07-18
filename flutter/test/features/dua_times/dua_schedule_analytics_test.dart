import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/dua_times/models/dua_window_schedule.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';

/// Engine that throws on build, to exercise the `dua_schedule_build_failed` path.
class _ThrowingEngine extends DuaWindowEngine {
  _ThrowingEngine(DuaWindowRepository repo, LocationService loc)
      : super(repository: repo, locationService: loc);

  @override
  Future<DuaWindowSchedule> buildSchedule({
    required DateTime now,
    EngineLocation? location,
    String tzName = 'local',
    bool promptLocation = false,
  }) async {
    throw Exception('engine boom');
  }
}

DateTime _clock() => DateTime.utc(2027, 5, 15, 23, 0);

DuaWindowRepository _repo() => DuaWindowRepository(
      prefs: SharedPreferences.getInstance,
      loadAsset: (_) async => '{"rows":[]}',
    );

LocationService _deniedLocation() => LocationService(
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () async => LocationPermission.denied,
      serviceEnabled: () async => false,
      prefs: SharedPreferences.getInstance,
    );

DuaWindowNotifier _notifier({DuaWindowEngine? engine}) {
  final repo = _repo();
  final location = _deniedLocation();
  return DuaWindowNotifier(
    engine: engine ?? DuaWindowEngine(repository: repo, locationService: location),
    locationService: location,
    repository: repo,
    clock: _clock,
    resolveTimezone: () async => 'Asia/Riyadh',
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
    SharedPreferences.setMockInitialValues({});
    DuaWindowNotifier.onAnalyticsEvent = (e, p) {
      events.add(e);
      props.add(p);
    };
  });

  tearDown(() => DuaWindowNotifier.onAnalyticsEvent = null);

  test('successful rebuild emits dua_schedule_built with health props', () async {
    final notifier = _notifier();

    await notifier.rebuild();

    expect(events, contains(AnalyticsEvents.duaScheduleBuilt));
    final p = props[events.indexOf(AnalyticsEvents.duaScheduleBuilt)];
    // Denied location → calendar-only, so location_present must be false — the
    // key precise-vs-calendar signal.
    expect(p[AnalyticsEvents.propLocationPresent], false);
    // The health shape is present.
    expect(p.containsKey(AnalyticsEvents.propHasActive), true);
    expect(p.containsKey(AnalyticsEvents.propHasNext), true);
    expect(p[AnalyticsEvents.propUrgency], isA<String>());
    // No failure event on the happy path.
    expect(events, isNot(contains(AnalyticsEvents.duaScheduleBuildFailed)));
  });

  test('repeated rebuilds with the same shape emit dua_schedule_built ONCE '
      '(resumed-bounce dedup)', () async {
    final notifier = _notifier();

    await notifier.rebuild();
    await notifier.rebuild(); // e.g. a transient Control-Center resumed bounce
    await notifier.rebuild();

    expect(
      events.where((e) => e == AnalyticsEvents.duaScheduleBuilt).length,
      1,
      reason: 'unchanged eligibility state must not re-emit on every resumed',
    );
  });

  test('build failure emits dua_schedule_build_failed (engine-health alarm)',
      () async {
    final repo = _repo();
    final location = _deniedLocation();
    final notifier = _notifier(engine: _ThrowingEngine(repo, location));

    await notifier.rebuild();

    expect(events, contains(AnalyticsEvents.duaScheduleBuildFailed));
    expect(events, isNot(contains(AnalyticsEvents.duaScheduleBuilt)));
  });
}
