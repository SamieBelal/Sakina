import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/location_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every call so we can assert the perf guard and clear behavior.
class _FakeHomeWidgetClient implements HomeWidgetClient {
  final List<MapEntry<String, String?>> saved = [];
  int updates = 0;
  String? appGroupId;

  @override
  Future<void> setAppGroupId(String id) async => appGroupId = id;

  @override
  Future<void> saveWidgetData(String key, String? value) async =>
      saved.add(MapEntry(key, value));

  @override
  Future<void> updateWidget({required String name}) async => updates++;

  String? get lastSavedValue => saved.isEmpty ? null : saved.last.value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final name = allahNames.firstWhere((n) => n.transliteration == 'Al-Malik');
  var tick = DateTime(2026, 7, 14, 9);

  /// A LocationService wired to in-memory mock prefs so clearWidget's
  /// clearCache() call is exercised (not swallowed by an uninitialized binding).
  LocationService buildLocation() => LocationService(
        checkPermission: () async => LocationPermission.always,
        prefs: SharedPreferences.getInstance,
      );

  WidgetDataService build(_FakeHomeWidgetClient client) => WidgetDataService(
        client: client,
        clock: () => tick,
        locationService: buildLocation(),
      );

  test('syncWidget writes a well-formed payload and reloads once', () async {
    final client = _FakeHomeWidgetClient();
    await build(client).syncWidget(
      name: name,
      anchor: 'He is sovereign over what feels out of your hands.',
      streak: 12,
      checkedInToday: true,
      personalized: true,
    );

    expect(client.updates, 1);
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['mode'], 'personalized');
    expect(json['name_key'], 'al-malik');
    expect(json['arabic'], name.arabic);
    expect(json['streak'], 12);
    expect(json['checked_in_today'], true);
    expect(json['updated_at'], isNotEmpty);
  });

  test('perf guard: identical payload (only timestamp differs) does not reload',
      () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    Future<void> sync() => svc.syncWidget(
          name: name,
          anchor: 'anchor',
          streak: 12,
          checkedInToday: true,
          personalized: true,
        );

    await sync();
    tick = tick.add(const Duration(minutes: 5)); // timestamp changes only
    await sync();

    expect(client.updates, 1, reason: 'second identical sync must be skipped');
  });

  test('changed streak reloads the widget', () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 12, checkedInToday: true, personalized: true);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 13, checkedInToday: true, personalized: true);
    expect(client.updates, 2);
  });

  test('saveDuaTimesSchedule: identical JSON does not re-save or reload',
      () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    const scheduleJson = '{"active":null,"urgency":"upcoming"}';

    await svc.saveDuaTimesSchedule(scheduleJson);
    await svc.saveDuaTimesSchedule(scheduleJson); // byte-identical
    expect(client.updates, 1,
        reason: 'second identical schedule push must be deduped');
    expect(client.saved.where((e) => e.key == kDuaTimesPayloadKey), hasLength(1),
        reason: 'second identical schedule must not re-save');

    // A changed schedule pushes again.
    await svc.saveDuaTimesSchedule('{"active":null,"urgency":"comfortable"}');
    expect(client.updates, 2, reason: 'a changed schedule reloads the widget');
  });

  test(
      'clearWidget wipes BOTH payload keys + location cache (privacy) '
      'and reloads both widgets', () async {
    SharedPreferences.setMockInitialValues({
      'dua_times_last_lat': 21.4225,
      'dua_times_last_lon': 39.8262,
    });
    final client = _FakeHomeWidgetClient();
    await build(client).clearWidget();

    // clearWidget now erases the Name payload AND the duʿā-times payload (the
    // sign-out leak fix, spec §7) and reloads both widgets.
    final wipedKeys = client.saved.map((e) => e.key).toSet();
    expect(
      wipedKeys,
      containsAll(<String>[kWidgetPayloadKey, kDuaTimesPayloadKey]),
      reason: 'both the Name and duʿā-times payloads must be erased',
    );
    expect(client.saved.every((e) => e.value == null), isTrue,
        reason: 'payloads erased to null');
    expect(client.updates, 2, reason: 'both widgets reload');

    // The raw coarse lat/lon cache must be wiped too.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('dua_times_last_lat'), isNull);
    expect(prefs.getDouble('dua_times_last_lon'), isNull);
  });
}
