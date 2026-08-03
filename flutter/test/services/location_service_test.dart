import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Position _position({double lat = 51.5, double lon = -0.12}) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.utc(2026),
      accuracy: 100,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService.getCoarseLocation — permission gates the cache', () {
    test('deniedForever → null even when a fix is cached (no stale precise)',
        () async {
      SharedPreferences.setMockInitialValues({
        'dua_times_last_lat': 21.4225,
        'dua_times_last_lon': 39.8262,
      });
      final svc = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        serviceEnabled: () async => true,
        prefs: SharedPreferences.getInstance,
      );
      expect(await svc.getCoarseLocation(), isNull);
    });

    test('denied → null', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        serviceEnabled: () async => true,
      );
      expect(await svc.getCoarseLocation(), isNull);
    });

    test('granted + services off → cached fix (legitimate offline)', () async {
      SharedPreferences.setMockInitialValues({
        'dua_times_last_lat': 21.4225,
        'dua_times_last_lon': 39.8262,
      });
      final svc = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        serviceEnabled: () async => false,
        prefs: SharedPreferences.getInstance,
      );
      final loc = await svc.getCoarseLocation();
      expect(loc?.fromCache, isTrue);
      expect(loc?.lat, 21.4225);
    });

    test('granted + services on → fresh fix', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = LocationService(
        checkPermission: () async => LocationPermission.always,
        serviceEnabled: () async => true,
        currentPosition: () async => _position(),
        prefs: SharedPreferences.getInstance,
      );
      final loc = await svc.getCoarseLocation();
      expect(loc?.fromCache, isFalse);
      expect(loc?.lat, 51.5);
    });

    // Secondary defect 2: a hanging first fix used to leave the enable banner up
    // forever while analytics happily reported `granted`.
    test('hanging fix → times out and falls back to the cache', () async {
      SharedPreferences.setMockInitialValues({
        'dua_times_last_lat': 21.4225,
        'dua_times_last_lon': 39.8262,
      });
      final svc = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        serviceEnabled: () async => true,
        // Never completes — exactly the hang we are bounding.
        currentPosition: () => Completer<Position>().future,
        fixTimeout: const Duration(milliseconds: 20),
        prefs: SharedPreferences.getInstance,
      );
      final loc = await svc.getCoarseLocation();
      expect(loc?.fromCache, isTrue);
      expect(loc?.lat, 21.4225);
    });

    test('hanging fix with no cache → null, and does not hang the caller',
        () async {
      SharedPreferences.setMockInitialValues({});
      final svc = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        serviceEnabled: () async => true,
        currentPosition: () => Completer<Position>().future,
        fixTimeout: const Duration(milliseconds: 20),
        prefs: SharedPreferences.getInstance,
      );
      expect(await svc.getCoarseLocation(), isNull);
    });
  });

  group('LocationService.readiness — observe only', () {
    test('whileInUse + services on → granted', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        serviceEnabled: () async => true,
      );
      expect(await svc.readiness(), LocationReadiness.granted);
    });

    test('always + services off → servicesOff', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.always,
        serviceEnabled: () async => false,
      );
      expect(await svc.readiness(), LocationReadiness.servicesOff);
    });

    test('denied → denied', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        serviceEnabled: () async => true,
      );
      expect(await svc.readiness(), LocationReadiness.denied);
    });

    test('deniedForever → deniedForever', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        serviceEnabled: () async => true,
      );
      expect(await svc.readiness(), LocationReadiness.deniedForever);
    });

    test('unableToDetermine → undetermined', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.unableToDetermine,
        serviceEnabled: () async => true,
      );
      expect(await svc.readiness(), LocationReadiness.undetermined);
    });

    // readiness() runs on the `resumed` hot path. If it threw, rebuild()'s catch
    // would fire dua_schedule_build_failed and poison the engine-health alarm
    // with location noise.
    test('platform throw → undetermined, never rethrows', () async {
      final svc = LocationService(
        checkPermission: () async => throw StateError('channel down'),
        serviceEnabled: () async => true,
      );
      expect(await svc.readiness(), LocationReadiness.undetermined);
    });

    test('never prompts, and never reads the cache', () async {
      SharedPreferences.setMockInitialValues({
        'dua_times_last_lat': 21.4225,
        'dua_times_last_lon': 39.8262,
      });
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async =>
            throw StateError('readiness must never prompt'),
        serviceEnabled: () async => true,
        currentPosition: () async =>
            throw StateError('readiness must never take a fix'),
        prefs: SharedPreferences.getInstance,
      );
      expect(await svc.readiness(), LocationReadiness.denied);
    });
  });

  group('LocationService.requestPreciseAccess', () {
    test('deniedForever → routes to app settings, returns openedSettings',
        () async {
      // The "Never" case: iOS/Android won't re-show the system prompt, so the
      // tap must open Settings instead of being a dead button. Reported as
      // openedSettings, NOT denied — the user denied nothing here, and many
      // grant seconds later in Settings.
      var opened = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async => LocationPermission.deniedForever,
        serviceEnabled: () async => true,
        openAppSettings: () async {
          opened = true;
          return true;
        },
      );
      expect(await svc.requestPreciseAccess(),
          LocationGrantOutcome.openedSettings);
      expect(opened, isTrue, reason: 'must open Settings when deniedForever');
    });

    test('denied → prompt granted → granted, never opens Settings', () async {
      var opened = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.whileInUse,
        serviceEnabled: () async => true,
        openAppSettings: () async {
          opened = true;
          return true;
        },
      );
      expect(await svc.requestPreciseAccess(), LocationGrantOutcome.granted);
      expect(opened, isFalse, reason: 'askable path shows the system prompt');
    });

    test('denied → prompt still denied → denied, no Settings', () async {
      var opened = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.denied,
        serviceEnabled: () async => true,
        openAppSettings: () async {
          opened = true;
          return true;
        },
      );
      expect(await svc.requestPreciseAccess(), LocationGrantOutcome.denied);
      expect(opened, isFalse);
    });

    test('already granted → granted without prompting', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async =>
            throw StateError('should not prompt when already granted'),
        serviceEnabled: () async => true,
        openAppSettings: () async => true,
      );
      expect(await svc.requestPreciseAccess(), LocationGrantOutcome.granted);
    });

    // Secondary defect 1 — the dead button. Permission is granted but the
    // device's Location Services are off, so there is no OS dialog to show and
    // the old code short-circuited into doing nothing at all.
    test('granted but services off → opens Location Settings, returns servicesOff',
        () async {
      var openedApp = false;
      var openedLocation = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async =>
            throw StateError('should not prompt when already granted'),
        serviceEnabled: () async => false,
        openAppSettings: () async {
          openedApp = true;
          return true;
        },
        openLocationSettings: () async {
          openedLocation = true;
          return true;
        },
      );
      expect(
          await svc.requestPreciseAccess(), LocationGrantOutcome.servicesOff);
      expect(openedLocation, isTrue,
          reason: 'services-off must route to Location Services, not nowhere');
      expect(openedApp, isFalse,
          reason: 'the app permission page is the wrong destination here');
    });

    test('fresh prompt granted but services off → servicesOff', () async {
      var openedLocation = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.whileInUse,
        serviceEnabled: () async => false,
        openLocationSettings: () async {
          openedLocation = true;
          return true;
        },
      );
      expect(
          await svc.requestPreciseAccess(), LocationGrantOutcome.servicesOff);
      expect(openedLocation, isTrue);
    });
  });
}
