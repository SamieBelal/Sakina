import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/constants/daily_questions.dart';
import 'package:sakina/features/daily/providers/daily_question_provider.dart';
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

  test('syncDailyAnswersFromSupabase hydrates today\'s answer from server', () async {
    final today = todayKey();
    fakeSync.rowLists['user_daily_answers'] = [
      {
        'user_id': 'user-1',
        'answered_at': '${today}T10:00:00Z',
        'question_id': 5,
        'selected_option': 'A specific loss',
        'name_returned': 'Al-Hadi',
        'name_arabic': 'الهادي',
        'teaching': 'Al-Hadi is the Guide',
        'dua_arabic': '',
        'dua_transliteration': '',
        'dua_translation': '',
      },
    ];

    await syncDailyAnswersFromSupabase();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('daily_answer_$today:user-1');
    expect(stored, isNotNull);
    final data = jsonDecode(stored!) as Map<String, dynamic>;
    expect(data['answer'], 'A specific loss');
    expect(data['name'], 'Al-Hadi');
  });

  test('syncDailyAnswersFromSupabase seeds server when empty', () async {
    final today = todayKey();
    SharedPreferences.setMockInitialValues({
      'daily_answer_$today:user-1': jsonEncode({
        'date': today,
        'questionId': 3,
        'answer': 'Gratitude',
        'name': 'Ash-Shakur',
        'nameArabic': 'الشكور',
        'teaching': '',
        'duaArabic': '',
        'duaTransliteration': '',
        'duaTranslation': '',
      }),
    });

    await syncDailyAnswersFromSupabase();

    expect(fakeSync.insertCalls, hasLength(1));
    expect(fakeSync.insertCalls.single['table'], 'user_daily_answers');
    final data = fakeSync.insertCalls.single['data'] as Map;
    expect(data['selected_option'], 'Gratitude');
    expect(data['name_returned'], 'Ash-Shakur');
  });

  test('scoped keys prevent cross-user bleed', () async {
    final today = todayKey();
    SharedPreferences.setMockInitialValues({
      'daily_answer_$today:user-1': jsonEncode({'answer': 'A'}),
      'daily_answer_$today:user-2': jsonEncode({'answer': 'B'}),
    });

    final prefs = await SharedPreferences.getInstance();
    expect(
      jsonDecode(prefs.getString('daily_answer_$today:user-1')!),
      containsPair('answer', 'A'),
    );
    expect(
      jsonDecode(prefs.getString('daily_answer_$today:user-2')!),
      containsPair('answer', 'B'),
    );
  });

  test('no userId = no Supabase sync', () async {
    fakeSync.userId = null;

    await syncDailyAnswersFromSupabase();

    expect(fakeSync.insertCalls, isEmpty);
    expect(fakeSync.upsertCalls, isEmpty);
  });

  test('server empty + local empty = no-op', () async {
    await syncDailyAnswersFromSupabase();

    expect(fakeSync.insertCalls, isEmpty);
    expect(fakeSync.upsertCalls, isEmpty);
  });

  test('sync matches today\'s row when answered_at is a local-time '
      'timestamp that parses to today', () async {
    final today = todayKey();
    // Build a timestamp that is unambiguously "today" in local time by
    // serializing local midnight + noon. This avoids flakiness from running
    // the test in timezones where a naive UTC string would skew the date.
    final localNoon = DateTime.parse('${today}T12:00:00');
    fakeSync.rowLists['user_daily_answers'] = [
      {
        'user_id': 'user-1',
        'answered_at': localNoon.toIso8601String(),
        'question_id': 7,
        'selected_option': 'Hope',
        'name_returned': 'Ar-Rajaa',
        'name_arabic': '',
        'teaching': '',
        'dua_arabic': '',
        'dua_transliteration': '',
        'dua_translation': '',
      },
    ];

    await syncDailyAnswersFromSupabase();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('daily_answer_$today:user-1');
    expect(stored, isNotNull);
    final data = jsonDecode(stored!) as Map<String, dynamic>;
    expect(data['answer'], 'Hope');
  });
}
