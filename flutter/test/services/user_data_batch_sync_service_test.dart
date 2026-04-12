import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/achievements_service.dart';
import 'package:sakina/services/card_collection_service.dart';
import 'package:sakina/services/checkin_history_service.dart';
import 'package:sakina/services/daily_usage_service.dart';
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

  test('hydrateUserDataFromBatchRpc hydrates all user data caches', () async {
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
          'profile': {
            'selected_title': null,
            'is_auto_title': true,
            'created_at': '2026-04-10T00:00:00Z',
          },
          'achievements': [
            {
              'achievement_id': 'first_name',
              'unlocked_at': '2026-04-09T13:00:00Z',
            },
            {
              'achievement_id': 'reflect_first',
              'unlocked_at': '2026-04-09T14:00:00Z',
            },
          ],
          'discovery_results': {
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
          },
          'daily_usage': {
            'usage_date': todayStr(),
            'reflect_uses': 2,
            'built_dua_uses': 1,
          },
          'daily_answers': [
            {
              'answered_at': '${todayStr()}T10:00:00Z',
              'question_id': 5,
              'selected_option': 'A specific loss',
              'name_returned': 'Al-Hadi',
              'name_arabic': 'الهادي',
              'teaching': 'Al-Hadi is the Guide',
              'dua_arabic': '',
              'dua_transliteration': '',
              'dua_translation': '',
            },
          ],
          'quest_progress': [
            {
              'quest_id': 'first_muhasabah',
              'cadence': 'one_time',
              'progress': 1,
              'completed': true,
              'period_start': '2026-04-10',
              'updated_at': '2026-04-10T15:00:00Z',
            },
            {
              'quest_id': 'first_steps_bundle',
              'cadence': 'one_time',
              'progress': 1,
              'completed': true,
              'period_start': '2026-04-10',
              'updated_at': '2026-04-10T15:30:00Z',
            },
            {
              'quest_id': 'daily_0_2026-04-09',
              'cadence': 'daily',
              'progress': 1,
              'completed': true,
              'period_start': '2026-04-09',
              'updated_at': '2026-04-09T15:00:00Z',
            },
            {
              'quest_id': 'weekly_0_2026-W04-06',
              'cadence': 'weekly',
              'progress': 2,
              'completed': false,
              'period_start': '2026-04-06',
              'updated_at': '2026-04-09T16:00:00Z',
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
    expect(prefs.getBool('first_steps_eligible_v1:user-1'), isTrue);
    expect(
      prefs.getString('first_steps_anchor_date_v1:user-1'),
      '2026-04-10',
    );
    expect(
      prefs.getString('first_steps_completed_v1:user-1'),
      jsonEncode(['first_muhasabah']),
    );
    expect(
      prefs.getBool('first_steps_bundle_claimed_v1:user-1'),
      isTrue,
    );
    expect(await getUnlockedAchievements(), {'first_name', 'reflect_first'});

    final discoveryResults = await loadSavedDiscoveryQuizResults();
    expect(discoveryResults, hasLength(1));
    expect(discoveryResults.first.name, 'Ar-Rahman');

    expect(await getReflectUsageToday(), 2);
    expect(await getBuiltDuaUsageToday(), 1);

    final dailyAnswer = jsonDecode(
      prefs.getString('daily_answer_${todayStr()}:user-1')!,
    ) as Map<String, dynamic>;
    expect(dailyAnswer['answer'], 'A specific loss');
    expect(dailyAnswer['name'], 'Al-Hadi');

    final completedRaw = prefs.getString('quests_completed_v2:user-1');
    final progressRaw = prefs.getString('quests_progress_v2:user-1');
    expect(
      (jsonDecode(completedRaw!) as List).cast<String>(),
      contains('daily_0_2026-04-09'),
    );
    expect(
      (jsonDecode(progressRaw!)
          as Map<String, dynamic>)['weekly_0_2026-W04-06'],
      2,
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

  test(
      'hydrateUserDataFromBatchRpc seeds achievements when server section is empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_achievements_unlocked:user-1': jsonEncode(['bronze_10']),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'achievements': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    expect(fakeSync.batchInsertCalls, hasLength(1));
    final seedCall = fakeSync.batchInsertCalls.single;
    expect(seedCall['table'], 'user_achievements');
    final rows = seedCall['rows'] as List;
    expect(rows, hasLength(1));
    expect(
        (rows.single as Map<String, dynamic>)['achievement_id'], 'bronze_10');
  });

  test(
      'hydrateUserDataFromBatchRpc seeds discovery results when server section is null',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_discovery_quiz_results_v1:user-1': jsonEncode({
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
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'discovery_results': null};

    await hydrateUserDataFromBatchRpc();

    expect(fakeSync.upsertCalls, hasLength(1));
    final call = fakeSync.upsertCalls.single;
    expect(call['table'], 'user_discovery_results');
    expect(call['onConflict'], 'user_id');
  });

  test(
      'hydrateUserDataFromBatchRpc seeds daily usage when server section is null',
      () async {
    SharedPreferences.setMockInitialValues({
      'daily_usage_reflect_${todayStr()}:user-1': 2,
      'daily_usage_built_dua_${todayStr()}:user-1': 1,
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'daily_usage': null};

    await hydrateUserDataFromBatchRpc();

    expect(fakeSync.upsertCalls, hasLength(1));
    final call = fakeSync.upsertCalls.single;
    expect(call['table'], 'user_daily_usage');
    expect(call['onConflict'], 'user_id,usage_date');
    final data = call['data'] as Map<String, dynamic>;
    expect(data['reflect_uses'], 2);
    expect(data['built_dua_uses'], 1);
  });

  test(
      'hydrateUserDataFromBatchRpc seeds daily answers when server section is empty',
      () async {
    final today = todayStr();
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
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'daily_answers': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    expect(fakeSync.insertCalls, hasLength(1));
    final call = fakeSync.insertCalls.single;
    expect(call['table'], 'user_daily_answers');
    final data = call['data'] as Map<String, dynamic>;
    expect(data['selected_option'], 'Gratitude');
    expect(data['name_returned'], 'Ash-Shakur');
  });

  test(
      'hydrateUserDataFromBatchRpc seeds quest progress when server section is empty',
      () async {
    SharedPreferences.setMockInitialValues({
      'quests_completed_v2:user-1': jsonEncode(['daily_0_2026-04-09']),
      'quests_progress_v2:user-1': jsonEncode({'weekly_1_2026-W04-06': 1}),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rpcHandlers['sync_all_user_data'] =
        (params) async => {'quest_progress': <Map<String, dynamic>>[]};

    await hydrateUserDataFromBatchRpc();

    expect(fakeSync.batchInsertCalls, hasLength(1));
    final call = fakeSync.batchInsertCalls.single;
    expect(call['table'], 'user_quest_progress');
    final rows = call['rows'] as List;
    expect(rows, hasLength(2));
  });

  test(
      'hydrateUserDataFromBatchRpc matches today local for a tomorrow UTC daily answer row',
      () async {
    final now = DateTime.now();
    final localLate = DateTime(now.year, now.month, now.day, 23, 30);
    final answeredAt = localLate.toUtc().toIso8601String();
    final answeredLocal = DateTime.parse(answeredAt).toLocal();
    final today = todayStr();

    fakeSync.rpcHandlers['sync_all_user_data'] = (params) async => {
          'daily_answers': [
            {
              'answered_at': answeredAt,
              'question_id': 9,
              'selected_option': 'Hope',
              'name_returned': 'Ar-Raja',
              'name_arabic': '',
              'teaching': '',
              'dua_arabic': '',
              'dua_transliteration': '',
              'dua_translation': '',
            },
          ],
        };

    await hydrateUserDataFromBatchRpc();

    expect(
      '${answeredLocal.year}-${answeredLocal.month.toString().padLeft(2, '0')}-${answeredLocal.day.toString().padLeft(2, '0')}',
      today,
    );
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('daily_answer_$today:user-1');
    expect(stored, isNotNull);
    final data = jsonDecode(stored!) as Map<String, dynamic>;
    expect(data['answer'], 'Hope');
  });

  test(
      'hydrateUserDataFromBatchRpc falls back to standalone syncs when batch RPC omits sections',
      () async {
    SharedPreferences.setMockInitialValues({
      'sakina_achievements_unlocked:user-1': jsonEncode(['existing_local']),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakeSync.rowLists['user_achievements'] = [
      {
        'user_id': 'user-1',
        'achievement_id': 'first_name',
      },
    ];
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
    fakeSync.rowLists['user_daily_usage'] = [
      {
        'user_id': 'user-1',
        'usage_date': todayStr(),
        'reflect_uses': 2,
        'built_dua_uses': 1,
      },
    ];
    fakeSync.rowLists['user_daily_answers'] = [
      {
        'user_id': 'user-1',
        'answered_at': '${todayStr()}T10:00:00Z',
        'question_id': 7,
        'selected_option': 'Hope',
        'name_returned': 'Ar-Raja',
        'name_arabic': '',
        'teaching': '',
        'dua_arabic': '',
        'dua_transliteration': '',
        'dua_translation': '',
      },
    ];
    fakeSync.rowLists['user_quest_progress'] = [
      {
        'user_id': 'user-1',
        'quest_id': 'daily_0_2026-04-09',
        'cadence': 'daily',
        'progress': 1,
        'completed': true,
        'period_start': '2026-04-09',
      },
    ];
    fakeSync.rpcHandlers['sync_all_user_data'] = (params) async => {
          'xp': {'total_xp': 7},
        };

    await hydrateUserDataFromBatchRpc();

    expect((await getXp()).totalXp, 7);
    expect(await getUnlockedAchievements(), {'first_name'});
    expect((await loadSavedDiscoveryQuizResults()).first.name, 'Ar-Rahman');
    expect(await getReflectUsageToday(), 2);
    expect(await getBuiltDuaUsageToday(), 1);
    final prefs = await SharedPreferences.getInstance();
    expect(
      jsonDecode(prefs.getString('daily_answer_${todayStr()}:user-1')!)
          as Map<String, dynamic>,
      containsPair('answer', 'Hope'),
    );
    expect(
      (jsonDecode(prefs.getString('quests_completed_v2:user-1')!) as List)
          .cast<String>(),
      contains('daily_0_2026-04-09'),
    );
    expect(fakeSync.batchInsertCalls, isEmpty);
    expect(fakeSync.upsertCalls, isEmpty);
    expect(fakeSync.insertCalls, isEmpty);
  });
}
