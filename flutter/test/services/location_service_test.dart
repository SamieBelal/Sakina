import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina/services/location_service.dart';

void main() {
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
