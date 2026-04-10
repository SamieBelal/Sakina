import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('checkin record JSON and Supabase mapping round-trip safely', () {
    const record = CheckInRecord(
      date: '2026-04-10',
      q1: 'Heavy',
      q2: 'Tired',
      q3: 'Hopeful',
      q4: '',
      nameReturned: 'Ar-Rahman',
      nameArabic: 'الرحمن',
    );

    final fromJson = CheckInRecord.fromJson(record.toJson());
    final row = record.toSupabaseRow('user-1');
    final fromRow = CheckInRecord.fromSupabaseRow({
      ...row,
      'checked_in_at': '2026-04-10T09:15:00Z',
    });

    expect(fromJson.date, '2026-04-10');
    expect(row['q4'], isNull);
    expect(fromRow.date, '2026-04-10');
    expect(fromRow.q4, isEmpty);
    expect(fromRow.nameReturned, 'Ar-Rahman');
  });

  test('saveCheckinRecord keeps newest first, dedupes same day, and caps at 14',
      () async {
    for (var i = 0; i < 15; i++) {
      await saveCheckinRecord(
        CheckInRecord(
          date: '2026-04-${(i + 1).toString().padLeft(2, '0')}',
          q1: 'q1-$i',
          q2: 'q2-$i',
          q3: 'q3-$i',
          q4: '',
          nameReturned: 'Name-$i',
          nameArabic: 'ع$i',
        ),
      );
    }

    await saveCheckinRecord(
      const CheckInRecord(
        date: '2026-04-15',
        q1: 'updated',
        q2: 'steady',
        q3: 'grateful',
        q4: 'clear',
        nameReturned: 'Ar-Razzaq',
        nameArabic: 'الرزاق',
      ),
    );

    final history = await getCheckinHistory();

    expect(history, hasLength(14));
    expect(history.first.date, '2026-04-15');
    expect(history.first.q1, 'updated');
    expect(history.first.nameReturned, 'Ar-Razzaq');
    expect(
        history.where((record) => record.date == '2026-04-15'), hasLength(1));
    expect(history.last.date, '2026-04-02');
  });

  test('saveCheckinRecord removes same-day remote duplicate before insert',
      () async {
    fakeSync.rowLists['user_checkin_history'] = [
      {
        'id': 'remote-1',
        'user_id': 'user-1',
        'checked_in_at': '2026-04-10T08:00:00Z',
        'q1': 'old',
        'q2': 'old',
        'q3': 'old',
        'q4': null,
        'name_returned': 'Ar-Rahman',
        'name_arabic': 'الرحمن',
      },
    ];

    await saveCheckinRecord(
      const CheckInRecord(
        date: '2026-04-10',
        q1: 'new',
        q2: 'steady',
        q3: 'hopeful',
        q4: '',
        nameReturned: 'As-Salam',
        nameArabic: 'السلام',
      ),
    );

    expect(fakeSync.deleteCalls, hasLength(1));
    expect(fakeSync.deleteCalls.single['table'], 'user_checkin_history');
    expect(fakeSync.deleteCalls.single['column'], 'id');
    expect(fakeSync.deleteCalls.single['value'], 'remote-1');
    expect(fakeSync.insertCalls, hasLength(1));

    final remoteRows = fakeSync.rowLists['user_checkin_history']!;
    expect(remoteRows.where((row) {
      final checkedInAt = row['checked_in_at'] as String? ?? '';
      return checkedInAt.startsWith('2026-04-10');
    }), hasLength(1));
  });

  test('migrate, seed, hydrate, and buildHistoryContext use scoped cache',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_checkin_history': jsonEncode([
        {
          'date': '2026-04-09',
          'q1': 'Heavy',
          'q2': 'Tired',
          'q3': 'Hopeful',
          'q4': '',
          'nameReturned': 'Ar-Rahman',
          'nameArabic': 'الرحمن',
        },
      ]),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    await migrateCheckinHistoryCache();
    await seedCheckinHistoryToSupabaseFromLocalCache();
    await hydrateCheckinHistoryCacheFromRows([
      {
        'checked_in_at': '2026-04-10T10:00:00Z',
        'q1': 'Calm',
        'q2': 'Present',
        'q3': 'Grateful',
        'q4': null,
        'name_returned': 'As-Salam',
        'name_arabic': 'السلام',
      },
    ]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sakina_checkin_history:user-1'), isNotNull);
    expect(fakeSync.batchInsertCalls, hasLength(1));
    expect(fakeSync.batchInsertCalls.single['table'], 'user_checkin_history');

    final hydrated = await getCheckinHistory();
    expect(hydrated.single.date, '2026-04-10');
    expect(hydrated.single.q4, isEmpty);

    final context = buildHistoryContext(hydrated, n: 1);
    expect(context, contains('Apr 10'));
    expect(context, contains('"Calm" / "Present"'));
    expect(context, contains('As-Salam'));
  });
}
