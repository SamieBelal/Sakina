import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  final fixedNow = DateTime.parse('2026-04-10T12:00:00Z');

  ai.ReflectResponse successResponse({bool offTopic = false}) =>
      ai.ReflectResponse(
        name: 'As-Salam',
        nameArabic: 'السلام',
        reframe: 'Steadiness can return, even slowly.',
        story: 'A story of steadiness.',
        verses: const [
          ReflectVerse(
            arabic: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
            translation:
                'Verily, in the remembrance of Allah do hearts find rest.',
            reference: 'Ar-Ra\'d 13:28',
          ),
        ],
        duaArabic: 'دعاء',
        duaTransliteration: 'dua',
        duaTranslation: 'supplication',
        duaSource: 'source',
        relatedNames: const [
          ai.RelatedName(name: 'Al-Lateef', nameArabic: 'اللطيف'),
        ],
        offTopic: offTopic,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('loads saved reflections from scoped cache on init', () async {
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
          'relatedNames': [
            {'name': 'Al-Halim', 'nameArabic': 'الحليم'},
          ],
        },
      ]),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final notifier = ReflectNotifier(
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-loaded',
      ),
    );
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.savedReflections, hasLength(1));
    expect(notifier.state.savedReflections.single.name, 'As-Sabur');
    expect(notifier.state.savedReflections.single.verses, isEmpty);
  });

  test('follow-up flow builds combined text and saves successful reflection',
      () async {
    String? reflectedText;
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [
          ai.FollowUpQuestion(
            type: ai.FollowUpQuestionType.choice,
            question: 'What feels heaviest right now?',
            options: ['Fear', 'Loneliness'],
          ),
        ],
        reflect: (text) async {
          reflectedText = text;
          return successResponse();
        },
        now: () => fixedNow,
        createId: () => 'reflection-123',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel overwhelmed');
    notifier.toggleEmotion('Anxious');
    notifier.toggleEmotion('Tired');

    await notifier.submit();

    expect(notifier.state.screenState, ReflectScreenState.followup);
    expect(await getReflectUsageToday(), 0);

    await notifier.answerFollowUp('It feels constant');

    expect(reflectedText, contains('I feel overwhelmed'));
    expect(reflectedText, contains('Emotions: Anxious, Tired'));
    expect(reflectedText, contains('Q: What feels heaviest right now?'));
    expect(reflectedText, contains('A: It feels constant'));
    expect(notifier.state.screenState, ReflectScreenState.result);
    expect(await getReflectUsageToday(), 1);
    expect(notifier.state.savedReflections, hasLength(1));
    expect(notifier.state.savedReflections.single.id, 'reflection-123');
    expect(notifier.state.savedReflections.single.date,
        fixedNow.toIso8601String());
    expect(notifier.state.savedReflections.single.verses, hasLength(1));

    await notifier.continueStep();
    await notifier.continueStep();
    expect(notifier.state.currentStep, ReflectStep.story);
    notifier.previousStep();
    expect(notifier.state.currentStep, ReflectStep.reflection);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('saved_reflections:user-1'), isNotNull);
    final reflectionWrites = fakeSync.insertCalls
        .where((call) => call['table'] == 'user_reflections')
        .toList();
    expect(reflectionWrites, hasLength(1));
    expect(
      (reflectionWrites.single['data'] as Map<String, dynamic>)['verses'],
      [
        {
          'arabic': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
          'translation':
              'Verily, in the remembrance of Allah do hearts find rest.',
          'reference': 'Ar-Ra\'d 13:28',
        },
      ],
    );
  });

  test('deleteReflection updates cache and removes remote row', () async {
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

    final notifier = ReflectNotifier(
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'unused',
      ),
    );
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);
    await notifier.deleteReflection('reflection-1');

    expect(notifier.state.savedReflections, isEmpty);
    expect(fakeSync.deleteCalls, hasLength(1));
    expect(fakeSync.deleteCalls.single['table'], 'user_reflections');
    expect(fakeSync.deleteCalls.single['value'], 'reflection-1');
  });

  test(
      'token-gated submit can continue with token without consuming free usage',
      () async {
    for (var i = 0; i < dailyFreeReflects; i++) {
      await incrementReflectUsage();
    }

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-token',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I need peace');
    await notifier.submit();
    expect(notifier.state.needsToken, isTrue);
    expect(await getReflectUsageToday(), dailyFreeReflects);

    await notifier.submitWithToken();
    expect(notifier.state.screenState, ReflectScreenState.result);
    expect(await getReflectUsageToday(), dailyFreeReflects);
  });

  test('AI failures do not consume free usage and surface an error', () async {
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => throw Exception('boom'),
        now: () => fixedNow,
        createId: () => 'reflection-error',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel lost');
    await notifier.submit();

    expect(notifier.state.screenState, ReflectScreenState.input);
    expect(notifier.state.error, 'Something went wrong. Please try again.');
    expect(await getReflectUsageToday(), 0);
    expect(notifier.state.savedReflections, isEmpty);
  });
}
