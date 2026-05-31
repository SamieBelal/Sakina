import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end persistence integration test for the trimmed (v7) onboarding
/// flow: fills every still-captured quiz field via the notifier's public
/// setters, then invokes the debug-only persist hook and asserts that each
/// field lands in the single [AuthService.saveOnboardingData] call.
///
/// Trimmed-flow refactor (2026-05-25, Option α): the
/// quranConnection / commonEmotions / aspirations fields were removed.
class _FakeAuthService extends AuthService {
  Map<String, dynamic>? captured;
  int callCount = 0;

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
  }) async {
    callCount += 1;
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
    };
  }

  int seedCallCount = 0;
  int? seededNameId;
  @override
  Future<void> seedStarterCard(int nameId) async {
    seedCallCount += 1;
    seededNameId = nameId;
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

    notifier
      ..setIntention('spiritualGrowth')
      ..setFamiliarity('some')
      ..toggleAttribution('tiktok')
      ..toggleAttribution('friend')
      ..setAgeRange('25_34')
      ..setPrayerFrequency('someDaily')
      ..setStarterName(2)
      ..toggleDuaTopic('health')
      ..toggleDuaTopic('family')
      ..setDuaTopicsOther('exam success')
      ..setDailyCommitmentMinutes(5)
      ..setReminderTime('08:00')
      ..setCommitmentAccepted(true);

    await notifier.debugPersistOnboardingForTest();

    expect(fake.callCount, 1,
        reason: 'saveOnboardingData should fire exactly once per completion');
    expect(fake.captured, isNotNull);

    for (final key in const [
      'intention',
      'familiarity',
      'attribution',
      'ageRange',
      'prayerFrequency',
      'starterNameId',
      'duaTopics',
      'duaTopicsOther',
      'dailyCommitmentMinutes',
      'reminderTime',
      'commitmentAccepted',
    ]) {
      expect(fake.captured!.containsKey(key), isTrue, reason: 'missing $key');
    }

    expect(fake.captured!['intention'], 'spiritualGrowth');
    expect(fake.captured!['familiarity'], 'some');
    expect(fake.captured!['attribution'], ['tiktok', 'friend']);
    expect(fake.captured!['ageRange'], '25_34');
    expect(fake.captured!['prayerFrequency'], 'someDaily');
    expect(fake.captured!['starterNameId'], 2);
    expect(fake.captured!['duaTopics'], ['health', 'family']);
    expect(fake.captured!['duaTopicsOther'], 'exam success');
    expect(fake.captured!['dailyCommitmentMinutes'], 5);
    expect(fake.captured!['reminderTime'], '08:00');
    expect(fake.captured!['commitmentAccepted'], isTrue);
  });

  test(
      'completeOnboarding handles partially-filled state (optional fields '
      'flow through as null / empty)', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake);

    notifier
      ..setIntention('justCurious')
      ..setFamiliarity('none')
      ..setAgeRange('18_24')
      ..setPrayerFrequency('rarely')
      ..setStarterName(3)
      ..setDailyCommitmentMinutes(1)
      ..setReminderTime('21:30')
      ..setCommitmentAccepted(false);

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured, isNotNull);
    expect(fake.captured!['intention'], 'justCurious');
    expect(fake.captured!['attribution'], isEmpty);
    expect(fake.captured!['duaTopics'], isEmpty);
    expect(fake.captured!['duaTopicsOther'], isNull);
    expect(fake.captured!['commitmentAccepted'], isFalse);
  });
}
