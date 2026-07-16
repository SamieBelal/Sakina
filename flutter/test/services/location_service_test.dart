import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        currentPosition: () async => Position(
          latitude: 51.5,
          longitude: -0.12,
          timestamp: DateTime.utc(2026),
          accuracy: 100,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
        prefs: SharedPreferences.getInstance,
      );
      final loc = await svc.getCoarseLocation();
      expect(loc?.fromCache, isFalse);
      expect(loc?.lat, 51.5);
    });
  });

  group('LocationService.ensureOrOpenSettings', () {
    test('deniedForever → routes to app settings, returns false', () async {
      // The "Never" case: iOS/Android won't re-show the system prompt, so the
      // tap must open Settings instead of being a dead button.
      var opened = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.deniedForever,
        requestPermission: () async => LocationPermission.deniedForever,
        openAppSettings: () async {
          opened = true;
          return true;
        },
      );
      final granted = await svc.ensureOrOpenSettings();
      expect(opened, isTrue, reason: 'must open Settings when deniedForever');
      expect(granted, isFalse);
    });

    test('denied → prompt granted → returns true, never opens Settings',
        () async {
      var opened = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.whileInUse,
        openAppSettings: () async {
          opened = true;
          return true;
        },
      );
      final granted = await svc.ensureOrOpenSettings();
      expect(granted, isTrue);
      expect(opened, isFalse, reason: 'askable path shows the system prompt');
    });

    test('denied → prompt still denied → returns false, no Settings', () async {
      var opened = false;
      final svc = LocationService(
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.denied,
        openAppSettings: () async {
          opened = true;
          return true;
        },
      );
      expect(await svc.ensureOrOpenSettings(), isFalse);
      expect(opened, isFalse);
    });

    test('already granted → returns true without prompting', () async {
      final svc = LocationService(
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async =>
            throw StateError('should not prompt when already granted'),
        openAppSettings: () async => true,
      );
      expect(await svc.ensureOrOpenSettings(), isTrue);
    });
  });
}
