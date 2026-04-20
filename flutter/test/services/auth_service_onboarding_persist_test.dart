import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  Map<String, dynamic>? captured;
  @override
  Future<void> saveOnboardingData({
    String? intention,
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
    captured = {
      'intention': intention,
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

  test('persistOnboardingToSupabase forwards every quiz field', () async {
    final fake = _FakeAuthService();
    final notifier = OnboardingNotifier(authService: fake);
    notifier
      ..setIntention('spiritualGrowth')
      ..setFamiliarity('some')
      ..setQuranConnection('weak')
      ..toggleAttribution('tiktok')
      ..setAgeRange('25_34')
      ..setPrayerFrequency('someDaily')
      ..setResonantNameId('ar-rahman-id')
      ..toggleDuaTopic('health')
      ..setDuaTopicsOther('exam success')
      ..toggleCommonEmotion('anxiety')
      ..toggleAspiration('morePatient')
      ..setDailyCommitmentMinutes(5)
      ..setReminderTime('08:30')
      ..setCommitmentAccepted(true);

    await notifier.debugPersistOnboardingForTest();

    expect(fake.captured!['ageRange'], '25_34');
    expect(fake.captured!['prayerFrequency'], 'someDaily');
    expect(fake.captured!['resonantNameId'], 'ar-rahman-id');
    expect(fake.captured!['duaTopics'], ['health']);
    expect(fake.captured!['duaTopicsOther'], 'exam success');
    expect(fake.captured!['commonEmotions'], ['anxiety']);
    expect(fake.captured!['aspirations'], ['morePatient']);
    expect(fake.captured!['dailyCommitmentMinutes'], 5);
    expect(fake.captured!['reminderTime'], '08:30');
    expect(fake.captured!['commitmentAccepted'], isTrue);
  });
}
