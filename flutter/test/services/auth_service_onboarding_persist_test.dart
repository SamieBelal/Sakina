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
}
