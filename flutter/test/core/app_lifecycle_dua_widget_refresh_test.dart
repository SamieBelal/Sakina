import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/core/app_lifecycle_observer.dart';
import 'package:sakina/features/dua_times/providers/dua_window_provider.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/widget_data_service.dart';

/// Records pushes to the duʿā-times payload key.
class _FakeWidgetClient implements HomeWidgetClient {
  final duaPushes = <String>[];
  @override
  Future<void> setAppGroupId(String id) async {}
  @override
  Future<void> saveWidgetData(String key, String? value) async {
    if (key == kDuaTimesPayloadKey) duaPushes.add(value ?? '');
  }
  @override
  Future<void> updateWidget({required String name}) async {}
}

DateTime _fixedClock() => DateTime.utc(2027, 5, 15, 23, 0);

/// A notifier that auto-builds on construction (like production) and observes
/// lifecycle, but with fully faked location/engine so the build is hermetic.
DuaWindowNotifier _autoBuildNotifier(WidgetDataService widgetData) {
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
  final engine = DuaWindowEngine(repository: repo, locationService: location);
  return DuaWindowNotifier(
    engine: engine,
    locationService: location,
    repository: repo,
    clock: _fixedClock,
    resolveTimezone: () async => 'Asia/Riyadh',
    widgetDataService: widgetData,
    observeLifecycle: true,
    autoBuild: true,
    startTicker: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'mounting AppLifecycleObserver keeps duaWindowProvider alive so the '
      'schedule is pushed to the widget even when no screen reads it (RC-1)',
      (tester) async {
    final client = _FakeWidgetClient();
    final widgetData = WidgetDataService(client: client);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Built INSIDE the create fn so it materializes only if something
          // actually reads the provider — proving the observer is what keeps
          // it alive, not the pre-build.
          duaWindowProvider.overrideWith((ref) => _autoBuildNotifier(widgetData)),
        ],
        // The child deliberately does NOT read duaWindowProvider — mirrors
        // opening the app to a screen (e.g. Home) that has no duʿā-times card.
        child: const AppLifecycleObserver(child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      client.duaPushes,
      isNotEmpty,
      reason:
          'cold launch should build + push a schedule to the duʿā-times widget '
          'without the Progress screen ever being visited',
    );
  });
}
