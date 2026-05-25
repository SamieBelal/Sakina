import 'package:flutter_test/flutter_test.dart';
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
}
