/// The regression suite for the 2026-08 re-nag bug.
///
/// A tester tapped "Turn on precise times" three times across two days, granted
/// every time (zero `dua_times_location_denied` events), and was asked again on
/// every launch. Cause: the gate was derived entirely from
/// `schedule.computedAt.lat`, a position fix, which evaporates when iOS reverts
/// an "Allow Once" grant — so a user who had said yes was indistinguishable from
/// one who had never been asked.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/features/dua_times/widgets/precise_paused_notice.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';

DateTime _clock() => DateTime.utc(2027, 5, 15, 23, 0);

DuaWindowRepository _repo() => DuaWindowRepository(
      prefs: SharedPreferences.getInstance,
      loadAsset: (_) async => '{"rows":[]}',
    );

/// Location fake driven purely by the constructor seams — no platform channel.
LocationService _location({
  required LocationPermission permission,
  bool servicesOn = true,
}) =>
    LocationService(
      checkPermission: () async => permission,
      requestPermission: () async => permission,
      serviceEnabled: () async => servicesOn,
      // Both Settings routes are stubbed: requestPreciseAccess reaches for one
      // of them on the deniedForever and services-off paths, and an unstubbed
      // seam hits the real platform channel.
      openAppSettings: () async => true,
      openLocationSettings: () async => true,
      prefs: SharedPreferences.getInstance,
    );

DuaWindowNotifier _notifier(LocationService location) {
  final repo = _repo();
  return DuaWindowNotifier(
    engine: DuaWindowEngine(repository: repo, locationService: location),
    locationService: location,
    repository: repo,
    clock: _clock,
    resolveTimezone: () async => 'Asia/Riyadh',
    prefs: SharedPreferences.getInstance,
    userId: () => 'user-1',
    observeLifecycle: false,
    autoBuild: false,
    startTicker: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('opt-in memory survives the grant lapsing', () {
    test('never asked → neverAsked (the pitch is still owed)', () async {
      final n = _notifier(_location(permission: LocationPermission.denied));
      await n.rebuild();
      expect(n.state.preciseState, PreciseTimesState.neverAsked);
    });

    // THE bug, end to end. Notifier A taps and is granted; a FRESH notifier over
    // the same prefs (a new cold launch) sees the grant gone — and must land on
    // permissionLapsed, never back on neverAsked.
    test('tap → granted, then a cold launch with the grant gone → lapsed',
        () async {
      final a = _notifier(_location(permission: LocationPermission.whileInUse));
      final outcome = await a.promptLocation();
      expect(outcome, LocationPromptOutcome.granted);

      final b = _notifier(_location(permission: LocationPermission.denied));
      await b.rebuild();

      expect(b.state.preciseState, PreciseTimesState.permissionLapsed,
          reason: 'the tap must be remembered across launches');
      expect(b.state.preciseState, isNot(PreciseTimesState.neverAsked));
    });

    test('the opt-in is written on TAP, even when the user then denies',
        () async {
      final a = _notifier(_location(permission: LocationPermission.denied));
      expect(await a.promptLocation(), LocationPromptOutcome.denied);

      final b = _notifier(_location(permission: LocationPermission.denied));
      await b.rebuild();
      // NOT permissionLapsed: iOS reset nothing, they declined. Telling them
      // "iOS reset location access" would be a lie, and it would inflate the
      // Allow-Once cohort that dua_times_precise_state{permission_lapsed} sizes.
      expect(b.state.preciseState, PreciseTimesState.declined,
          reason: 'asked-and-answered — never re-pitch, but never blame iOS');
      expect(await b.claimLapseNotice(b.state.preciseState), isFalse,
          reason: 'a decline is not a lapse and earns no notice');
    });

    test('deniedForever → openedSettings, not denied', () async {
      var opened = false;
      final loc = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async => LocationPermission.deniedForever,
        serviceEnabled: () async => true,
        openAppSettings: () async {
          opened = true;
          return true;
        },
        prefs: SharedPreferences.getInstance,
      );
      final n = _notifier(loc);
      expect(await n.promptLocation(), LocationPromptOutcome.openedSettings);
      expect(opened, isTrue);
    });

    test('granted but services off → servicesOff state', () async {
      final n = _notifier(_location(
        permission: LocationPermission.whileInUse,
        servicesOn: false,
      ));
      await n.promptLocation();
      await n.rebuild();
      expect(n.state.preciseState, PreciseTimesState.servicesOff);
    });

    test('cached location does not mask services-off state', () async {
      SharedPreferences.setMockInitialValues({
        'dua_times_last_lat': 21.4225,
        'dua_times_last_lon': 39.8262,
      });
      final n = _notifier(_location(
        permission: LocationPermission.whileInUse,
        servicesOn: false,
      ));

      await n.rebuild();

      expect(n.state.schedule?.computedAt.lat, 21.4225);
      expect(n.state.preciseState, PreciseTimesState.servicesOff);
    });

    // Protects the install base: anyone who already granted before this shipped
    // is stamped on their first rebuild and never sees the pitch again.
    test('migration back-fill: a live grant stamps the opt-in with no tap',
        () async {
      final n = _notifier(_location(permission: LocationPermission.whileInUse));
      await n.rebuild();

      final fresh = _notifier(_location(permission: LocationPermission.denied));
      await fresh.rebuild();
      expect(fresh.state.preciseState, PreciseTimesState.permissionLapsed,
          reason: 'back-filled users must not fall back to neverAsked');
    });

    test('keys are user-scoped — a second user gets their own first run',
        () async {
      final a = _notifier(_location(permission: LocationPermission.whileInUse));
      await a.promptLocation();

      final repo = _repo();
      final loc = _location(permission: LocationPermission.denied);
      final b = DuaWindowNotifier(
        engine: DuaWindowEngine(repository: repo, locationService: loc),
        locationService: loc,
        repository: repo,
        clock: _clock,
        resolveTimezone: () async => 'Asia/Riyadh',
        prefs: SharedPreferences.getInstance,
        userId: () => 'user-2',
        observeLifecycle: false,
        autoBuild: false,
        startTicker: false,
      );
      await b.rebuild();
      expect(b.state.preciseState, PreciseTimesState.neverAsked);
    });
  });

  group('the lapse notice waits to be dealt with, but is bounded', () {
    // Founder decision 2026-08-03, after device QA: the notice used to auto-fade
    // after 6s and be spent by any tap anywhere, so a tester hunting for it
    // still never saw it. It now persists until dismissed — bounded by a count
    // instead of a timer, so it still cannot become a permanent resident.
    test('shows on up to three opens, then goes quiet on its own', () async {
      final n = _notifier(_location(permission: LocationPermission.whileInUse));
      await n.promptLocation();

      for (var open = 1;
          open <= DuaWindowNotifier.lapseNoticeMaxShows;
          open++) {
        final launch =
            _notifier(_location(permission: LocationPermission.denied));
        await launch.rebuild();
        expect(await launch.claimLapseNotice(launch.state.preciseState), isTrue,
            reason: 'open $open is still within the budget');
      }

      final tooMany =
          _notifier(_location(permission: LocationPermission.denied));
      await tooMany.rebuild();
      expect(
          await tooMany.claimLapseNotice(tooMany.state.preciseState), isFalse,
          reason: 'past the budget Settings holds the state alone');
    });

    test('acknowledging closes the episode immediately', () async {
      final n = _notifier(_location(permission: LocationPermission.whileInUse));
      await n.promptLocation();

      final lapsed =
          _notifier(_location(permission: LocationPermission.denied));
      await lapsed.rebuild();
      expect(await lapsed.claimLapseNotice(lapsed.state.preciseState), isTrue);

      // The ✕ (or a tap through to the steps) — the user has dealt with it, so
      // the remaining budget is forfeited rather than spent.
      await lapsed.acknowledgeLapseNotice(lapsed.state.preciseState);

      final nextLaunch =
          _notifier(_location(permission: LocationPermission.denied));
      await nextLaunch.rebuild();
      expect(await nextLaunch.claimLapseNotice(nextLaunch.state.preciseState),
          isFalse,
          reason: 'dismissing means dismissed, not "two more to go"');
    });

    // Upgrade path: under the pre-✕ build, merely rendering the notice wrote a
    // bare wire name. Those users already had their one notice; re-opening the
    // episode with a fresh budget would read as the app nagging again.
    test('a pre-✕ record reads as already acknowledged', () async {
      SharedPreferences.setMockInitialValues({
        '${DuaWindowNotifier.preciseNoticeShownBaseKey}:user-1':
            'permission_lapsed',
        '${DuaWindowNotifier.preciseOptInBaseKey}:user-1':
            _clock().millisecondsSinceEpoch,
        // Both stamps: opted-in WITHOUT an observed grant is `declined`, not a
        // lapse — the notice is silent there on purpose.
        '${DuaWindowNotifier.preciseGrantedBaseKey}:user-1':
            _clock().millisecondsSinceEpoch,
      });
      final lapsed =
          _notifier(_location(permission: LocationPermission.denied));
      await lapsed.rebuild();
      expect(lapsed.state.preciseState, PreciseTimesState.permissionLapsed);
      expect(await lapsed.claimLapseNotice(lapsed.state.preciseState), isFalse);
    });

    test('a different lapse state earns its own notice', () async {
      final n = _notifier(_location(permission: LocationPermission.whileInUse));
      await n.promptLocation();

      final denied =
          _notifier(_location(permission: LocationPermission.denied));
      await denied.rebuild();
      expect(await denied.claimLapseNotice(denied.state.preciseState), isTrue);
      await denied.acknowledgeLapseNotice(denied.state.preciseState);

      // Services off says something else and names a different fix, so the
      // acknowledged permission notice must not silence it.
      final off = _notifier(_location(
        permission: LocationPermission.whileInUse,
        servicesOn: false,
      ));
      await off.rebuild();
      expect(off.state.preciseState, PreciseTimesState.servicesOff);
      expect(await off.claimLapseNotice(off.state.preciseState), isTrue);
    });

    test('recovering then lapsing again re-arms the notice', () async {
      final n = _notifier(_location(permission: LocationPermission.whileInUse));
      await n.promptLocation();

      final lapsed =
          _notifier(_location(permission: LocationPermission.denied));
      await lapsed.rebuild();
      expect(await lapsed.claimLapseNotice(lapsed.state.preciseState), isTrue);

      // Grant again — the notice is spent and must be re-armed.
      final recovered =
          _notifier(_location(permission: LocationPermission.whileInUse));
      await recovered.rebuild();
      // No position fix is stubbed, so this lands on `unresolved` rather than
      // `working` — either way it is a NON-lapse state, which is what re-arms.
      expect(
          PrecisePausedNotice.messageFor(recovered.state.preciseState), isNull,
          reason: 'a non-lapse state must re-arm the notice');

      final lapsedAgain =
          _notifier(_location(permission: LocationPermission.denied));
      await lapsedAgain.rebuild();
      expect(await lapsedAgain.claimLapseNotice(lapsedAgain.state.preciseState),
          isTrue,
          reason: 'a NEW lapse is a new transition, so it earns a new notice');
    });
  });

  group('dua_times_precise_state analytics', () {
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

    test('emits once, deduped across identical rebuilds', () async {
      final n = _notifier(_location(permission: LocationPermission.denied));
      await n.rebuild();
      await n.rebuild();

      final emitted = events
          .where((e) => e == AnalyticsEvents.duaTimesPreciseState)
          .toList();
      expect(emitted, hasLength(1),
          reason: 'rebuild() runs on every Control-Center bounce');
      final p = props[events.indexOf(AnalyticsEvents.duaTimesPreciseState)];
      expect(p[AnalyticsEvents.propPreciseState], 'never_asked');
      expect(p[AnalyticsEvents.propPermission], 'denied');
    });
  });
}
