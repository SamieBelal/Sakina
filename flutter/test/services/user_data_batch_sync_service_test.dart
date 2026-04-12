import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/daily_rewards_service.dart';
import 'package:sakina/services/streak_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';
import 'package:sakina/services/xp_service.dart';

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

  String todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  test('hydrateUserDataFromBatchRpc hydrates Wave 1-2 caches', () async {
    SharedPreferences.setMockInitialValues({
      'saved_related_duas': jsonEncode([
        {
          'id': 'related-1',
          'title': 'Ease',
          'arabic': 'arabic',
          'transliteration': 'translit',
          'translation': 'translation',
          'source': 'source',
        },
      ]),
      'saved_browse_dua_ids': ['browse-1'],
      'sakina_card_collection': jsonEncode({
        'ids': [5],
        'dates': {'5': '2026-04-01'},
        'tiers': {'5': 2},
        'tierUpDates': {'5': '2026-04-02'},
      }),
      'sakina_card_seen': ['5'],
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    fakeSync.rpcHandlers['sync_all_user_data'] = (params) async => {
          'xp': {'total_xp': 42},
          'tokens': {
            'balance': 145,
            'total_spent': 30,
            'tier_up_scrolls': 9,
          },
          'streak': {
            'current_streak': 4,
            'longest_streak': 10,
            'last_active': '2026-04-09',
          },
          'daily_rewards': {
            'current_day': 3,
            'last_claim_date': todayStr(),
            'streak_freeze_owned': true,
            'last_premium_grant_month': '2026-04',
          },
          'checkin_history': [
            {
              'checked_in_at': '2026-04-09T10:00:00Z',
              'q1': 'Heavy',
              'q2': 'Tired',
              'q3': 'Hopeful',
              'q4': null,
              'name_returned': 'Ar-Rahman',
              'name_arabic': 'الرحمن',
            },
          ],
          'reflections': [
            {
              'id': 'reflection-1',
              'saved_at': '2026-04-09T11:00:00Z',
              'user_text': 'Need patience',
              'name': 'As-Sabur',
              'name_arabic': 'الصبور',
              'reframe_preview': 'Stay steady',
              'reframe': 'Stay steady',
              'story': 'Story',
              'dua_arabic': 'dua',
              'dua_transliteration': 'translit',
              'dua_translation': 'translation',
              'dua_source': 'source',
              'related_names': [
                {'name': 'Al-Halim', 'nameArabic': 'الحليم'},
              ],
            },
          ],
          'built_duas': [
            {
              'id': 'dua-1',
              'saved_at': '2026-04-09T12:00:00Z',
              'need': 'calm',
              'arabic': 'arabic',
              'transliteration': 'translit',
              'translation': 'translation',
            },
          ],
          'card_collection': [
            {
              'name_id': 5,
              'tier': 'silver',
              'discovered_at': '2026-04-01T00:00:00Z',
              'last_engaged_at': '2026-04-02T00:00:00Z',
            },
          ],
        };

    await hydrateUserDataFromBatchRpc();

    expect((await getXp()).totalXp, 42);
    expect((await getTokens()).balance, 145);
    expect(await getTotalTokensSpent(), 30);
    expect((await getTierUpScrolls()).balance, 9);

    final streak = await getStreak();
    expect(streak.currentStreak, 4);
    expect(streak.longestStreak, 10);
    expect(streak.lastActive, '2026-04-09');

    final rewards = await getDailyRewards();
    expect(rewards.currentDay, 3);
    expect(rewards.streakFreezeOwned, isTrue);

    final history = await getCheckinHistory();
    expect(history, hasLength(1));
    expect(history.first.nameReturned, 'Ar-Rahman');

    final collection = await getCardCollection();
    expect(collection.discoveredIds, contains(5));
    expect(collection.tierFor(5), 2);
    expect(collection.seenIds, containsAll({'5:1', '5:2'}));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('saved_related_duas:user-1'), isNotNull);
    expect(prefs.getStringList('saved_browse_dua_ids:user-1'), ['browse-1']);
    expect(
      prefs.getString('sakina_premium_last_grant:user-1'),
      '2026-04',
    );
  });

  test(
      'hydrateUserDataFromBatchRpc seeds checkin history when server section is empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_checkin_history:user-1': jsonEncode([
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
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'checkin_history': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    final seedCall = fakeSync.batchInsertCalls.single;
    expect(seedCall['table'], 'user_checkin_history');
    expect((seedCall['rows'] as List), hasLength(1));
  });

  test(
      'hydrateUserDataFromBatchRpc seeds reflections when server section is empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'saved_reflections:user-1': jsonEncode([
        {
          'id': 'reflection-1',
          'date': '2026-04-09T11:00:00Z',
          'userText': 'Need patience',
          'name': 'As-Sabur',
          'nameArabic': 'الصبور',
          'reframePreview': 'Stay steady',
          'reframe': 'Stay steady',
          'story': 'Story',
          'duaArabic': 'dua',
          'duaTransliteration': 'translit',
          'duaTranslation': 'translation',
          'duaSource': 'source',
          'relatedNames': <Map<String, String>>[],
        },
      ]),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'reflections': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    final seedCall = fakeSync.batchInsertCalls.single;
    expect(seedCall['table'], 'user_reflections');
    expect((seedCall['rows'] as List), hasLength(1));
  });

  test(
      'hydrateUserDataFromBatchRpc seeds built duas when server section is empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'saved_built_duas:user-1': jsonEncode([
        {
          'id': 'dua-1',
          'savedAt': '2026-04-09T12:00:00Z',
          'need': 'calm',
          'arabic': 'arabic',
          'transliteration': 'translit',
          'translation': 'translation',
        },
      ]),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'built_duas': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    final seedCall = fakeSync.batchInsertCalls.single;
    expect(seedCall['table'], 'user_built_duas');
    expect((seedCall['rows'] as List), hasLength(1));
  });

  test(
      'hydrateUserDataFromBatchRpc seeds card collection when server section is empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_card_collection:user-1': jsonEncode({
        'ids': [5],
        'dates': {'5': '2026-04-01'},
        'tiers': {'5': 2},
        'tierUpDates': {'5': '2026-04-02'},
      }),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'card_collection': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    final seedCall = fakeSync.batchInsertCalls.single;
    expect(seedCall['table'], 'user_card_collection');
    final rows = seedCall['rows'] as List;
    expect(rows, hasLength(1));
    expect((rows.first as Map<String, dynamic>)['name_id'], 5);
    expect((rows.first)['tier'], 'silver');
  });

  test(
      'hydrateUserDataFromBatchRpc leaves existing scroll cache when payload omits scroll field',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_tier_up_scrolls:user-1': 4,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] = (params) async => {
          'tokens': {
            'balance': 145,
            'total_spent': 30,
          },
        };

    await hydrateUserDataFromBatchRpc();

    expect((await getTierUpScrolls()).balance, 4);
  });

  test(
      'hydrateUserDataFromBatchRpc preserves premium grant cache when payload omits new field',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_premium_last_grant:user-1': '2026-03',
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] = (params) async => {
          'daily_rewards': {
            'current_day': 2,
            'last_claim_date': '2026-04-10',
            'streak_freeze_owned': false,
          },
        };

    await hydrateUserDataFromBatchRpc();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sakina_premium_last_grant:user-1'), '2026-03');
  });
}
