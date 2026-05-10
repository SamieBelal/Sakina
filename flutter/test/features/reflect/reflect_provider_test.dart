import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/gating_service.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    // Default test users into the post-warmup "capped" phase so legacy
    // assertions on daily-counter increments remain meaningful. The warmup
    // phase is exercised in dedicated GatingService tests.
    await GatingService().debugSetHadTrial(true);
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
      'submit blocked by gating service surfaces gateResult and dismissGate '
      'clears it without consuming usage', () async {
    // Drive the user to the daily-cap state by latching had_trial = true
    // (skips warmup) and using up the 1/day reflect.
    await GatingService().debugSetHadTrial(true);
    await incrementReflectUsage();

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-gated',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I need peace');
    await notifier.submit();
    expect(notifier.state.gateResult, isNotNull);
    expect(notifier.state.gateResult!.allowed, isFalse);
    expect(notifier.state.screenState, ReflectScreenState.input);
    // Daily counter unchanged — a blocked submit must not consume usage.
    expect(await getReflectUsageToday(), 1);

    notifier.dismissGate();
    expect(notifier.state.gateResult, isNull);
  });

  test(
      'off-topic responses do NOT consume free usage — retrying consumes only '
      'once (pins _consumeFreeUsageOnSuccess reset on offTopic branch)',
      () async {
    var aiCallCount = 0;
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async {
          aiCallCount++;
          // First call: off-topic. Second call: on-topic.
          return successResponse(offTopic: aiCallCount == 1);
        },
        now: () => fixedNow,
        createId: () => 'reflection-offtopic-retry',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('hi');
    await notifier.submit();
    expect(notifier.state.screenState, ReflectScreenState.offtopic,
        reason: 'first call surfaces off-topic state');
    expect(await getReflectUsageToday(), 0,
        reason: 'off-topic must NOT consume usage');

    notifier.setUserText('I feel lost');
    await notifier.submit();
    expect(notifier.state.screenState, ReflectScreenState.result);
    expect(await getReflectUsageToday(), 1,
        reason:
            'on-topic retry consumes EXACTLY one — flag was reset by off-topic '
            'branch and re-armed by the second submit');
  });

  test(
      'exception in _reflect resets _consumeFreeUsageOnSuccess — retry '
      'consumes only once', () async {
    var aiCallCount = 0;
    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async {
          aiCallCount++;
          if (aiCallCount == 1) throw Exception('first call boom');
          return successResponse();
        },
        now: () => fixedNow,
        createId: () => 'reflection-retry-after-exception',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel lost');
    await notifier.submit();
    expect(notifier.state.error, isNotNull);
    expect(await getReflectUsageToday(), 0);

    notifier.setUserText('I feel lost again');
    await notifier.submit();
    expect(notifier.state.screenState, ReflectScreenState.result);
    expect(await getReflectUsageToday(), 1,
        reason:
            'retry after exception must consume exactly one — flag must have '
            'been reset by the catch block');
  });

  test(
      'warmup 1 → 0 transition surfaces warmupJustExhausted on state; '
      'dismissWarmupExhausted clears it', () async {
    // Reset the global setUp's had_trial=true so we exercise the warmup phase.
    await GatingService().debugSetHadTrial(false);
    await GatingService().debugSetWarmupRemaining(GatedFeature.reflect, 1);

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'reflection-warmup-exhaust',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel lost');
    await notifier.submit();

    expect(notifier.state.screenState, ReflectScreenState.result);
    expect(notifier.state.warmupJustExhausted, GatedFeature.reflect,
        reason: 'one-shot signal must fire on the 1→0 transition');

    notifier.dismissWarmupExhausted();
    expect(notifier.state.warmupJustExhausted, isNull,
        reason: 'dismiss must clear the one-shot signal');
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
