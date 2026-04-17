import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end persistence integration test for the new 28-page onboarding
/// flow: fills every quiz field via the notifier's public setters (the same
/// setters the screens invoke), then invokes the debug-only persist hook and
/// asserts that each field lands in the single [AuthService.saveOnboardingData]
/// call with exactly the value the "user" picked.
///
/// Reuses the `_FakeAuthService extends AuthService` pattern from Task 3.
class _FakeAuthService extends AuthService {
  Map<String, dynamic>? captured;
  int callCount = 0;

  @override
  Future<void> saveOnboardingData({
    String? intention,
    List<String> struggles = const [],
    String? familiarity,
    String? quranConnection,
    List<String> attribution = const [],
    String? ageRange,
    String? prayerFrequency,
    String? resonantNameId,
    List<String> duaTopics = const [],
    String? duaTopicsOther,
    List<String> commonEmotions = const [],
    List<String> aspirations = const [],
    int? dailyCommitmentMinutes,
    String? reminderTime,
    bool commitmentAccepted = false,
  }) async {
    callCount += 1;
    captured = {
      'intention': intention,
      'struggles': struggles,
      'familiarity': familiarity,
      'quranConnection': quranConnection,
      'attribution': attribution,
      'ageRange': ageRange,
      'prayerFrequency': prayerFrequency,
      'resonantNameId': resonantNameId,
      'duaTopics': duaTopics,
      'duaTopicsOther': duaTopicsOther,
      'commonEmotions': commonEmotions,
      'aspirations': aspirations,
      'dailyCommitmentMinutes': dailyCommitmentMinutes,
      'reminderTime': reminderTime,
      'commitmentAccepted': commitmentAccepted,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
      'completeOnboarding persists every quiz field exactly as the user '
      'answered', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake);

    // Walk through every quiz screen's setter — mirrors what a real user
    // does pressing Continue on each of the new-flow pages.
    notifier
      ..setIntention('spiritualGrowth')
      ..toggleStruggle('anxiety')
      ..toggleStruggle('loneliness')
      ..setFamiliarity('some')
      ..setQuranConnection('weak')
      ..toggleAttribution('tiktok')
      ..toggleAttribution('friend')
      ..setAgeRange('25_34')
      ..setPrayerFrequency('someDaily')
      ..setResonantNameId('ar-rahman')
      ..toggleDuaTopic('health')
      ..toggleDuaTopic('family')
      ..setDuaTopicsOther('exam success')
      ..toggleCommonEmotion('anxious')
      ..toggleCommonEmotion('grateful')
      ..toggleAspiration('morePatient')
      ..toggleAspiration('consistentPrayer')
      ..setDailyCommitmentMinutes(5)
      ..setReminderTime('08:00')
      ..setCommitmentAccepted(true);

    await notifier.debugPersistOnboardingForTest();

    // Exactly one persist call, not multiple.
    expect(fake.callCount, 1,
        reason: 'saveOnboardingData should fire exactly once per completion');
    expect(fake.captured, isNotNull);

    // Every expected key is present.
    for (final key in const [
      'intention',
      'struggles',
      'familiarity',
      'quranConnection',
      'attribution',
      'ageRange',
      'prayerFrequency',
      'resonantNameId',
      'duaTopics',
      'duaTopicsOther',
      'commonEmotions',
      'aspirations',
      'dailyCommitmentMinutes',
      'reminderTime',
      'commitmentAccepted',
    ]) {
      expect(fake.captured!.containsKey(key), isTrue, reason: 'missing $key');
    }

    // Every value is carried through unchanged.
    expect(fake.captured!['intention'], 'spiritualGrowth');
    expect(fake.captured!['struggles'], ['anxiety', 'loneliness']);
    expect(fake.captured!['familiarity'], 'some');
    expect(fake.captured!['quranConnection'], 'weak');
    expect(fake.captured!['attribution'], ['tiktok', 'friend']);
    expect(fake.captured!['ageRange'], '25_34');
    expect(fake.captured!['prayerFrequency'], 'someDaily');
    expect(fake.captured!['resonantNameId'], 'ar-rahman');
    expect(fake.captured!['duaTopics'], ['health', 'family']);
    expect(fake.captured!['duaTopicsOther'], 'exam success');
    expect(fake.captured!['commonEmotions'], ['anxious', 'grateful']);
    expect(fake.captured!['aspirations'], ['morePatient', 'consistentPrayer']);
    expect(fake.captured!['dailyCommitmentMinutes'], 5);
    expect(fake.captured!['reminderTime'], '08:00');
    expect(fake.captured!['commitmentAccepted'], isTrue);
  });

  test(
      'completeOnboarding handles partially-filled state (optional fields '
      'flow through as null / empty)', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake);

    // Only the always-required fields from the new flow.
    notifier
      ..setIntention('justCurious')
      ..setFamiliarity('none')
      ..setQuranConnection('strong')
      ..setAgeRange('18_24')
      ..setPrayerFrequency('rarely')
      ..setResonantNameId('ar-raheem')
      ..setDailyCommitmentMinutes(1)
      ..setReminderTime('21:30')
      ..setCommitmentAccepted(false);

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured, isNotNull);
    expect(fake.captured!['intention'], 'justCurious');
    expect(fake.captured!['struggles'], isEmpty);
    expect(fake.captured!['attribution'], isEmpty);
    expect(fake.captured!['duaTopics'], isEmpty);
    expect(fake.captured!['duaTopicsOther'], isNull);
    expect(fake.captured!['commonEmotions'], isEmpty);
    expect(fake.captured!['aspirations'], isEmpty);
    expect(fake.captured!['commitmentAccepted'], isFalse);
  });
}
