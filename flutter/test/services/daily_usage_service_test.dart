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
  });

  test('syncDailyUsageFromSupabase hydrates from server', () async {
    fakeSync.rowLists['user_daily_usage'] = [
      {
        'user_id': 'user-1',
        'usage_date': todayDate(),
        'reflect_uses': 2,
        'built_dua_uses': 1,
      },
    ];

    await syncDailyUsageFromSupabase();

    expect(await getReflectUsageToday(), 2);
    expect(await getBuiltDuaUsageToday(), 1);
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

  test('canReflectFree respects free limit', () async {
    expect(await canReflectFree(), true);

    await incrementReflectUsage();
    await incrementReflectUsage();
    await incrementReflectUsage();

    expect(await canReflectFree(), false);
    expect(await reflectFreeRemaining(), 0);
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

    // Four upsert calls happened…
    expect(fakeSync.upsertCalls, hasLength(4));
    // …but only ONE row should exist for today's (user_id, usage_date).
    final rows = fakeSync.rowLists['user_daily_usage'] ?? const [];
    expect(rows, hasLength(1));
    expect(rows.single['reflect_uses'], 3);
    expect(rows.single['built_dua_uses'], 1);

    // Every upsert must have passed the composite onConflict target,
    // otherwise production would silent-fail after the first insert.
    for (final call in fakeSync.upsertCalls) {
      expect(call['onConflict'], 'user_id,usage_date');
    }
  });
}
