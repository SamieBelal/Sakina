import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_window_engine.dart';
import 'package:sakina/services/dua_window_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A minimal self-describing bundled-asset payload mirroring the real
/// `assets/dua_calendar/dua_windows.json` shape.
const _bundledAssetJson = '''
{
  "version": 1,
  "last_seeded_through": "2027-06-20",
  "rows": [
    { "id": "arafah_1448", "kind": "arafah", "tier": "hero",
      "title_key": "dua_window.arafah", "start_date": "2027-05-15",
      "end_date": "2027-05-15", "source_ref": "Tirmidhi 3585" }
  ]
}
''';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('cold-start offline', () {
    test('empty cache + no network reads the bundled asset', () async {
      final repo = DuaWindowRepository(
        prefs: SharedPreferences.getInstance,
        loadAsset: (_) async => _bundledAssetJson,
      );
      final cal = await repo.load();
      expect(cal.fromBundledAsset, isTrue);
      expect(cal.rows, hasLength(1));
      expect(cal.rows.first.kind, 'arafah');
      expect(cal.lastSeededThrough, DateTime(2027, 6, 20));
    });

    test('engine surfaces a dated window from the bundled asset offline',
        () async {
      final repo = DuaWindowRepository(
        prefs: SharedPreferences.getInstance,
        loadAsset: (_) async => _bundledAssetJson,
      );
      final engine = DuaWindowEngine(
        repository: repo,
        // Honolulu-style fixed offset so ʿArafah opens at a known instant.
        localMidnightUtc: (y, m, d) =>
            DateTime.utc(y, m, d).subtract(const Duration(hours: -10)),
      );
      // No location → calendar-only. Local noon 2027-05-15 (UTC-10) = UTC 22:00.
      final s = await engine.buildSchedule(
        now: DateTime.utc(2027, 5, 15, 22, 0),
      );
      expect(s.active, isNotNull);
      expect(s.active!.type, DuaWindowType.arafah);
    });
  });

  group('cache preferred over asset', () {
    test('a populated cache short-circuits the bundled asset', () async {
      final cachePayload = jsonEncode({
        'version': 1,
        'last_seeded_through': '2027-06-20',
        'rows': [
          {
            'id': 'ashura_1449',
            'kind': 'ashura',
            'tier': 'special',
            'title_key': 'dua_window.ashura',
            'start_date': '2027-06-14',
            'end_date': '2027-06-15',
            'source_ref': 'Muslim 1162',
          }
        ],
      });
      SharedPreferences.setMockInitialValues({
        DuaWindowRepository.cacheKey: cachePayload,
      });
      final repo = DuaWindowRepository(
        prefs: SharedPreferences.getInstance,
        loadAsset: (_) async =>
            throw StateError('asset must not be read when cache is warm'),
      );
      final cal = await repo.load();
      expect(cal.fromBundledAsset, isFalse);
      expect(cal.rows.single.kind, 'ashura');
    });
  });

  group('seed-horizon health check', () {
    test('warns when now is within the warn lead of the horizon', () async {
      final repo = DuaWindowRepository(
        prefs: SharedPreferences.getInstance,
        loadAsset: (_) async => _bundledAssetJson,
      );
      final cal = await repo.load();
      // 2027-06-20 horizon; 2027-06-01 is within 90d → warn.
      expect(repo.isNearSeedHorizon(cal, DateTime(2027, 6, 1)), isTrue);
      // 2027-01-01 is well before the warn lead → no warn.
      expect(repo.isNearSeedHorizon(cal, DateTime(2027, 1, 1)), isFalse);
    });
  });
}
