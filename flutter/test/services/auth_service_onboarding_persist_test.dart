import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/content/problem_chips.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Trimmed-flow refactor (2026-05-25, Option α): the
// quranConnection / commonEmotions / aspirations fields were removed.
class _FakeAuthService extends AuthService {
  Map<String, dynamic>? captured;
  @override
  Future<void> saveOnboardingData({
    String? displayName,
    String? intention,
    String? familiarity,
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    int? starterNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool commitmentAccepted = false,
    Map<String, dynamic>? acquisitionPromise,
    String? firstProblemText,
    String? onboardingFlow,
  }) async {
    captured = {
      'displayName': displayName,
      'intention': intention,
      'familiarity': familiarity,
      'attribution': attribution,
      'ageRange': ageRange,
      'prayerFrequency': prayerFrequency,
      'starterNameId': starterNameId,
      'duaTopics': duaTopics,
      'duaTopicsOther': duaTopicsOther,
      'dailyCommitmentMinutes': dailyCommitmentMinutes,
      'reminderTime': reminderTime,
      'commitmentAccepted': commitmentAccepted,
      'acquisitionPromise': acquisitionPromise,
      'firstProblemText': firstProblemText,
      'onboardingFlow': onboardingFlow,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persistOnboardingToSupabase forwards every quiz field', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake);
    notifier
      ..setIntention('spiritualGrowth')
      ..setFamiliarity('some')
      ..toggleAttribution('tiktok')
      ..setAgeRange('25_34')
      ..setPrayerFrequency('someDaily')
      ..setStarterName(2)
      ..toggleDuaTopic('health')
      ..setDuaTopicsOther('exam success')
      ..setDailyCommitmentMinutes(5)
      ..setReminderTime('08:30')
      ..setCommitmentAccepted(true);

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['ageRange'], '25_34');
    expect(fake.captured!['prayerFrequency'], 'someDaily');
    expect(fake.captured!['starterNameId'], 2);
    expect(fake.captured!['duaTopics'], ['health']);
    expect(fake.captured!['duaTopicsOther'], 'exam success');
    expect(fake.captured!['dailyCommitmentMinutes'], 5);
    expect(fake.captured!['reminderTime'], '08:30');
    expect(fake.captured!['commitmentAccepted'], isTrue);
  });

  test('the three W1 columns ride every persist once the hook is answered',
      () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake)
      ..setOnboardingFlow('reel_v1')
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'rizq',
        hookType: HookType.chip,
        chipKey: 'rizq',
        pairNameIds: [13, 23],
        problemTextRaw: 'rent is due and I have nothing',
      ));

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['onboardingFlow'], 'reel_v1');
    expect(fake.captured!['firstProblemText'], 'rent is due and I have nothing');
    expect(fake.captured!['acquisitionPromise'], {
      'hook_type': 'chip',
      'contract': 'problem',
      'problem_category': 'rizq',
    });
  });

  test('the carrying-duration answer rides the promise to the server',
      () async {
    // It is otherwise local-only, and W3 needs it as AI context on a device
    // that may not be the one that onboarded. The DB check constrains only
    // `contract`, so an extra key is free.
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake)
      ..setOnboardingFlow('reel_v1')
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'rizq',
        hookType: HookType.chip,
        chipKey: 'rizq',
        pairNameIds: [13, 23],
      ))
      ..setCarryingDuration('years');

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['acquisitionPromise'], {
      'hook_type': 'chip',
      'contract': 'problem',
      'problem_category': 'rizq',
      'carrying_duration': 'years',
    });
  });

  test('an unanswered carrying duration adds no key at all', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake)
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'rizq',
        hookType: HookType.chip,
        chipKey: 'rizq',
        pairNameIds: [13, 23],
      ));

    await notifier.debugPersistOnboardingForTest();

    expect(
      (fake.captured!['acquisitionPromise'] as Map<String, dynamic>)
          .containsKey('carrying_duration'),
      isFalse,
    );
  });

  test('an unanswered hook sends no promise — the column stays untouched',
      () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake)
      ..setIntention('spiritualGrowth');

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['acquisitionPromise'], isNull);
    expect(fake.captured!['firstProblemText'], isNull);
    expect(fake.captured!['onboardingFlow'], isNull);
  });

  test('a reel arrival persists hook_type reel and carries the reel id',
      () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake)
      ..setOnboardingFlow(OnboardingFlow.reelV1)
      ..setReelArrival(reelId: 'r-42')
      ..applyHookSelection(const ChipSelection(
        contract: HookContract.problem,
        problemCategory: 'rizq',
        hookType: HookType.chip,
        chipKey: 'rizq',
        pairNameIds: [13, 23],
      ));

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['acquisitionPromise'], {
      'reel_id': 'r-42',
      'hook_type': 'reel',
      'contract': 'problem',
      'problem_category': 'rizq',
    });
  });

  group('w1ProfileColumns — the second, separate UPDATE payload', () {
    test('is empty when the flow produced nothing, so no statement is sent',
        () {
      expect(w1ProfileColumns(), isEmpty);
    });

    test('emits only the keys that have a value (never an explicit null)', () {
      expect(
        w1ProfileColumns(onboardingFlow: OnboardingFlow.reelV1),
        {'onboarding_flow': 'reel_v1'},
      );
      expect(
        w1ProfileColumns(
          acquisitionPromise: const {'contract': 'problem'},
          firstProblemText: 'rent is due',
          onboardingFlow: OnboardingFlow.reelV1,
        ),
        {
          'acquisition_promise': {'contract': 'problem'},
          'first_problem_text': 'rent is due',
          'onboarding_flow': 'reel_v1',
        },
      );
    });

    test('carries none of the quiz answers — that is the point of the split',
        () {
      // The two groups ride separate, individually-isolated statements: a
      // check-constraint or freeze-trigger failure on these three columns must
      // not be able to take the onboarding answers down with it, or vice versa.
      final payload = w1ProfileColumns(
        acquisitionPromise: const {'contract': 'problem'},
        firstProblemText: 'rent is due',
        onboardingFlow: OnboardingFlow.reelV1,
      );
      expect(payload.keys, hasLength(3));
      for (final quizColumn in const [
        'display_name',
        'onboarding_intention',
        'age_range',
        'dua_topics',
        'commitment_accepted',
      ]) {
        expect(payload.containsKey(quizColumn), isFalse, reason: quizColumn);
      }
    });
  });

  group('onboardingProfileUpdates — the statement ORDER', () {
    test('W1 goes first: it is the write with a deadline', () {
      // Once `onboarding_completed` flips true the freeze trigger rejects any
      // distinct W1 value, so a W1 write lost behind a failing quiz UPDATE on
      // the LAST persist is lost forever. The quiz columns stay writable and
      // ride every later persist, so they are the ones that can afford to wait.
      final updates = onboardingProfileUpdates(
        intention: 'spiritualGrowth',
        onboardingFlow: OnboardingFlow.reelV1,
        firstProblemText: 'rent is due',
        acquisitionPromise: const {'contract': 'problem'},
      );

      expect(updates.map((u) => u.stage), ['w1', 'quiz']);
      expect(updates.first.columns.keys, [
        'acquisition_promise',
        'first_problem_text',
        'onboarding_flow',
      ]);
      expect(updates.last.columns['onboarding_intention'], 'spiritualGrowth');
    });

    test('a flow with no W1 values sends the quiz statement alone', () {
      final updates = onboardingProfileUpdates(intention: 'spiritualGrowth');

      expect(updates.map((u) => u.stage), ['quiz']);
    });

    test('the quiz payload keeps its explicit nulls', () {
      // Unlike the W1 columns, a null here IS the answer — this path is the
      // only writer of these columns.
      final quiz = onboardingProfileUpdates().single.columns;

      expect(quiz.containsKey('age_range'), isTrue);
      expect(quiz['age_range'], isNull);
      expect(quiz['commitment_accepted'], isFalse);
    });
  });

  group('sendOnboardingProfileUpdates — the statement ISOLATION', () {
    final updates = onboardingProfileUpdates(
      intention: 'spiritualGrowth',
      onboardingFlow: OnboardingFlow.reelV1,
      acquisitionPromise: const {'contract': 'problem'},
    );

    test('a failing W1 statement does not take the quiz statement with it',
        () async {
      // The split is pointless if the first failure aborts the second: the W1
      // columns carry a check constraint and a freeze trigger the quiz columns
      // do not, and either group must survive the other's violations.
      final sent = <String>[];
      await sendOnboardingProfileUpdates(updates, (update) async {
        sent.add(update.stage);
        if (update.stage == 'w1') throw StateError('check constraint');
      });

      expect(sent, ['w1', 'quiz'],
          reason: 'statement 2 must still be attempted');
    });

    test('the failure is reported by stage, with the error CLASS only',
        () async {
      // A raw PostgrestException message is free-form and version-dependent —
      // pushing it through a Mixpanel property would explode the cardinality.
      final failures = <({String stage, String errorClass})>[];
      await sendOnboardingProfileUpdates(
        updates,
        (update) async {
          if (update.stage == 'w1') throw StateError('rls: 42501 denied');
        },
        onFailure: (stage, errorClass) =>
            failures.add((stage: stage, errorClass: errorClass)),
      );

      expect(failures, hasLength(1));
      expect(failures.single.stage, 'w1');
      expect(failures.single.errorClass, 'StateError');
      expect(failures.single.errorClass, isNot(contains('42501')));
    });

    test('a clean run reports nothing', () async {
      final failures = <String>[];
      await sendOnboardingProfileUpdates(
        updates,
        (_) async {},
        onFailure: (stage, _) => failures.add(stage),
      );

      expect(failures, isEmpty);
    });
  });
}
