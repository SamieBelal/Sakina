import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  String todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('incrementReflectUsage increments and upserts to Supabase', () async {
    final count = await incrementReflectUsage();

    expect(count, 1);
    expect(fakeSync.upsertCalls, hasLength(1));
    final data = fakeSync.upsertCalls.single['data'] as Map;
    expect(data['usage_date'], todayDate());
    expect(data['reflect_uses'], 1);
    expect(data['built_dua_uses'], 0);
    expect(data['discover_name_uses'], 0);
  });

  test('incrementBuiltDuaUsage increments and upserts', () async {
    await incrementReflectUsage();
    fakeSync.upsertCalls.clear();

    final count = await incrementBuiltDuaUsage();

    expect(count, 1);
    expect(fakeSync.upsertCalls, hasLength(1));
    final data = fakeSync.upsertCalls.single['data'] as Map;
    expect(data['reflect_uses'], 1);
    expect(data['built_dua_uses'], 1);
    expect(data['discover_name_uses'], 0);
  });

  test('incrementDiscoverNameUsage increments and upserts', () async {
    final count = await incrementDiscoverNameUsage();

    expect(count, 1);
    expect(fakeSync.upsertCalls, hasLength(1));
    final data = fakeSync.upsertCalls.single['data'] as Map;
    expect(data['reflect_uses'], 0);
    expect(data['built_dua_uses'], 0);
    expect(data['discover_name_uses'], 1);
  });

  test('upsert payload always includes discover_name_uses (regression)',
      () async {
    await incrementReflectUsage();
    final data = fakeSync.upsertCalls.single['data'] as Map;
    expect(
      data.containsKey('discover_name_uses'),
      isTrue,
      reason:
          'discover_name_uses must be present in every upsert so the '
          'composite row is fully reflected on the server',
    );
  });

  test('syncDailyUsageFromSupabase hydrates from server', () async {
    fakeSync.rowLists['user_daily_usage'] = [
      {
        'user_id': 'user-1',
        'usage_date': todayDate(),
        'reflect_uses': 2,
        'built_dua_uses': 1,
        'discover_name_uses': 3,
      },
    ];

    await syncDailyUsageFromSupabase();

    expect(await getReflectUsageToday(), 2);
    expect(await getBuiltDuaUsageToday(), 1);
    expect(await getDiscoverNameUsageToday(), 3);
  });

  test('syncDailyUsageFromSupabase seeds server when empty', () async {
    await incrementReflectUsage();
    await incrementReflectUsage();
    fakeSync.rowLists.clear();
    fakeSync.upsertCalls.clear();

    await syncDailyUsageFromSupabase();

    expect(fakeSync.upsertCalls, hasLength(1));
    final data = fakeSync.upsertCalls.single['data'] as Map;
    expect(data['reflect_uses'], 2);
  });

  test('canReflectFree respects 1/day free limit', () async {
    expect(await canReflectFree(), true);
    expect(await reflectFreeRemaining(), dailyFreeReflects);

    await incrementReflectUsage();

    expect(await canReflectFree(), false);
    expect(await reflectFreeRemaining(), 0);
  });

  test('canBuildDuaFree respects 1/day free limit', () async {
    expect(await canBuildDuaFree(), true);
    expect(await builtDuaFreeRemaining(), dailyFreeBuiltDuas);

    await incrementBuiltDuaUsage();

    expect(await canBuildDuaFree(), false);
    expect(await builtDuaFreeRemaining(), 0);
  });

  test('canDiscoverNameFree respects 1/day free limit', () async {
    expect(await canDiscoverNameFree(), true);
    expect(await discoverNameFreeRemaining(), dailyFreeDiscoverNames);

    await incrementDiscoverNameUsage();

    expect(await canDiscoverNameFree(), false);
    expect(await discoverNameFreeRemaining(), 0);
  });

  test('daily caps lock to 1 per spec (regression)', () {
    expect(dailyFreeReflects, 1);
    expect(dailyFreeBuiltDuas, 1);
    expect(dailyFreeDiscoverNames, 1);
  });

  test('scoped keys prevent cross-user bleed', () async {
    await incrementReflectUsage();
    expect(await getReflectUsageToday(), 1);

    fakeSync.userId = 'user-2';
    expect(await getReflectUsageToday(), 0);
  });

  test('no userId = no Supabase calls', () async {
    fakeSync.userId = null;

    await incrementReflectUsage();

    expect(fakeSync.upsertCalls, isEmpty);
  });

  test('repeated increments produce ONE row per day (composite upsert)',
      () async {
    await incrementReflectUsage();
    await incrementReflectUsage();
    await incrementReflectUsage();
    await incrementBuiltDuaUsage();
    await incrementDiscoverNameUsage();
    await incrementDiscoverNameUsage();

    // Six upsert calls happened…
    expect(fakeSync.upsertCalls, hasLength(6));
    // …but only ONE row should exist for today's (user_id, usage_date).
    final rows = fakeSync.rowLists['user_daily_usage'] ?? const [];
    expect(rows, hasLength(1));
    expect(rows.single['reflect_uses'], 3);
    expect(rows.single['built_dua_uses'], 1);
    expect(rows.single['discover_name_uses'], 2);

    // Every upsert must have passed the composite onConflict target,
    // otherwise production would silent-fail after the first insert.
    for (final call in fakeSync.upsertCalls) {
      expect(call['onConflict'], 'user_id,usage_date');
    }
  });
}
