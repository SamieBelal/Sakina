import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/widget_data_service.dart';

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
  final name = allahNames.firstWhere((n) => n.transliteration == 'Al-Malik');
  var tick = DateTime(2026, 7, 14, 9);

  WidgetDataService build(_FakeHomeWidgetClient client) => WidgetDataService(
        client: client,
        clock: () => tick,
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

  test('clearWidget wipes BOTH payload keys (privacy) and reloads both widgets',
      () async {
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
  });
}
