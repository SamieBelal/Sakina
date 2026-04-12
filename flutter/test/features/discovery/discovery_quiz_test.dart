import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/discovery_quiz.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  AnchorResult makeAnchor(String key, String name) => AnchorResult(
        nameKey: key,
        name: name,
        arabic: 'X',
        score: 10,
        anchor: 'anchor',
        detail: 'detail',
      );

  test('syncDiscoveryResultsFromSupabase hydrates anchors from server',
      () async {
    fakeSync.rows['user_discovery_results:user-1'] = {
      'anchor_names': [
        {
          'nameKey': 'ar-rahman',
          'name': 'Ar-Rahman',
          'arabic': 'الرَّحْمَـٰن',
          'score': 8,
          'anchor': 'mercy',
          'detail': 'detail',
        },
      ],
    };

    await syncDiscoveryResultsFromSupabase();

    final results = await loadSavedDiscoveryQuizResults();
    expect(results, hasLength(1));
    expect(results.first.name, 'Ar-Rahman');
  });

  test('syncDiscoveryResultsFromSupabase seeds server when empty', () async {
    await saveDiscoveryQuizResults([makeAnchor('ar-rahman', 'Ar-Rahman')]);
    fakeSync.upsertCalls.clear();
    // Server has no row.
    fakeSync.rows.remove('user_discovery_results:user-1');

    await syncDiscoveryResultsFromSupabase();

    expect(fakeSync.upsertCalls, hasLength(1));
    expect(
      fakeSync.upsertCalls.single['table'],
      'user_discovery_results',
    );
  });

  test('saveDiscoveryQuizResults upserts to Supabase', () async {
    await saveDiscoveryQuizResults([
      makeAnchor('al-wadud', 'Al-Wadud'),
      makeAnchor('ar-rahman', 'Ar-Rahman'),
    ]);

    expect(fakeSync.upsertCalls, hasLength(1));
    final call = fakeSync.upsertCalls.single;
    expect(call['table'], 'user_discovery_results');
    final data = call['data'] as Map;
    final anchors = data['anchor_names'] as List;
    expect(anchors, hasLength(2));
    expect((anchors.first as Map)['name'], 'Al-Wadud');
  });

  test('scoped key isolation between users', () async {
    await saveDiscoveryQuizResults([makeAnchor('ar-rahman', 'Ar-Rahman')]);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('sakina_discovery_quiz_results_v1:user-1'),
      isNotNull,
    );

    fakeSync.userId = 'user-2';
    final user2Results = await loadSavedDiscoveryQuizResults();
    expect(user2Results, isEmpty);
  });

  test('no userId = no Supabase sync', () async {
    fakeSync.userId = null;

    await syncDiscoveryResultsFromSupabase();

    expect(fakeSync.upsertCalls, isEmpty);
    expect(fakeSync.insertCalls, isEmpty);
  });

  test('repeated saves produce ONE row per user (composite upsert)', () async {
    await saveDiscoveryQuizResults([makeAnchor('ar-rahman', 'Ar-Rahman')]);
    await saveDiscoveryQuizResults([makeAnchor('al-wadud', 'Al-Wadud')]);
    await saveDiscoveryQuizResults([
      makeAnchor('ar-rahman', 'Ar-Rahman'),
      makeAnchor('al-wadud', 'Al-Wadud'),
    ]);

    // Three upsert calls happened…
    expect(fakeSync.upsertCalls, hasLength(3));
    // …but only ONE row should exist for this user.
    final rows = fakeSync.rowLists['user_discovery_results'] ?? const [];
    expect(rows, hasLength(1));
    final anchors = rows.single['anchor_names'] as List;
    expect(anchors, hasLength(2));

    // Every upsert must have passed the user_id onConflict target,
    // otherwise production would create duplicate rows (no UNIQUE by default
    // on the uuid PK).
    for (final call in fakeSync.upsertCalls) {
      expect(call['onConflict'], 'user_id');
    }
  });

  test('legacy scoped key migration happens on load', () async {
    SharedPreferences.setMockInitialValues({
      'sakina_discovery_quiz_results_v1': jsonEncode({
        'version': 1,
        'results': [
          {
            'nameKey': 'ar-rahman',
            'name': 'Ar-Rahman',
            'arabic': 'الرَّحْمَـٰن',
            'score': 8,
            'anchor': 'mercy',
            'detail': 'detail',
          },
        ],
      }),
    });

    final results = await loadSavedDiscoveryQuizResults();
    expect(results, hasLength(1));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('sakina_discovery_quiz_results_v1:user-1'),
      isNotNull,
    );
  });

  test('schema migration enforces unique user_id for discovery result upserts',
      () async {
    final migration = File(
      'supabase/migrations/20260410180000_user_discovery_results_unique_user_id.sql',
    );
    expect(await migration.exists(), isTrue);

    final sql = await migration.readAsString();
    expect(
      sql,
      contains(
          'add constraint user_discovery_results_user_id_key unique (user_id)'),
    );
  });
}
