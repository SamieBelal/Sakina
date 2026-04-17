import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingState v3', () {
    test('defaults all new fields to null/empty', () {
      const s = OnboardingState();
      expect(s.ageRange, isNull);
      expect(s.prayerFrequency, isNull);
      expect(s.resonantNameId, isNull);
      expect(s.duaTopics, isEmpty);
      expect(s.duaTopicsOther, isNull);
      expect(s.commonEmotions, isEmpty);
      expect(s.aspirations, isEmpty);
      expect(s.dailyCommitmentMinutes, isNull);
      expect(s.reminderTime, isNull);
      expect(s.commitmentAccepted, isFalse);
    });

    test('toJson/fromJson round-trips all new fields', () {
      const original = OnboardingState(
        ageRange: '25_34',
        prayerFrequency: 'someDaily',
        resonantNameId: 'ar-rahman-id',
        duaTopics: {'health', 'family'},
        duaTopicsOther: 'success in school',
        commonEmotions: {'anxiety', 'gratitude'},
        aspirations: {'morePatient'},
        dailyCommitmentMinutes: 3,
        reminderTime: '08:30',
        commitmentAccepted: true,
      );
      final json = original.toJson();
      expect(json['version'], 3);
      final decoded = OnboardingState.fromJson(json);
      expect(decoded.ageRange, '25_34');
      expect(decoded.prayerFrequency, 'someDaily');
      expect(decoded.resonantNameId, 'ar-rahman-id');
      expect(decoded.duaTopics, {'health', 'family'});
      expect(decoded.duaTopicsOther, 'success in school');
      expect(decoded.commonEmotions, {'anxiety', 'gratitude'});
      expect(decoded.aspirations, {'morePatient'});
      expect(decoded.dailyCommitmentMinutes, 3);
      expect(decoded.reminderTime, '08:30');
      expect(decoded.commitmentAccepted, isTrue);
    });

    test('fromJson with version < 3 discards stored state and starts fresh', () {
      // Pre-refactor (v2) blob. Per spec: no users, no migration logic; drop it.
      final legacy = {
        'version': 2,
        'currentPage': 5,
        'intention': 'legacy',
        'struggles': ['anxiety'],
      };
      final decoded = OnboardingState.fromJson(legacy);
      expect(decoded.currentPage, 0);
      expect(decoded.intention, isNull);
      expect(decoded.struggles, isEmpty);
    });

    test('fromJson accepts v3 blob as authoritative', () {
      final v3 = {
        'version': 3,
        'currentPage': 5,
        'intention': 'spiritualGrowth',
        'struggles': ['anxiety'],
        'ageRange': '25_34',
      };
      final decoded = OnboardingState.fromJson(v3);
      expect(decoded.currentPage, 5);
      expect(decoded.intention, 'spiritualGrowth');
      expect(decoded.struggles, {'anxiety'});
      expect(decoded.ageRange, '25_34');
    });
  });

  group('OnboardingNotifier setters', () {
    test('each setter updates the corresponding field', () {
      final notifier = OnboardingNotifier();
      notifier.setAgeRange('25_34');
      notifier.setPrayerFrequency('someDaily');
      notifier.setResonantNameId('ar-rahman-id');
      notifier.toggleDuaTopic('health');
      notifier.toggleDuaTopic('family');
      notifier.toggleDuaTopic('health'); // toggle off
      notifier.setDuaTopicsOther('school');
      notifier.toggleCommonEmotion('anxiety');
      notifier.toggleAspiration('morePatient');
      notifier.setDailyCommitmentMinutes(5);
      notifier.setReminderTime('08:30');
      notifier.setCommitmentAccepted(true);

      final s = notifier.state;
      expect(s.ageRange, '25_34');
      expect(s.prayerFrequency, 'someDaily');
      expect(s.resonantNameId, 'ar-rahman-id');
      expect(s.duaTopics, {'family'});
      expect(s.duaTopicsOther, 'school');
      expect(s.commonEmotions, {'anxiety'});
      expect(s.aspirations, {'morePatient'});
      expect(s.dailyCommitmentMinutes, 5);
      expect(s.reminderTime, '08:30');
      expect(s.commitmentAccepted, isTrue);
    });

    test('setDuaTopicsOther caps at 280 chars and trims', () {
      final notifier = OnboardingNotifier();
      notifier.setDuaTopicsOther('  ${'x' * 500}  ');
      expect(notifier.state.duaTopicsOther!.length, 280);
    });

    test('setDuaTopicsOther caps by graphemes (emoji not split)', () {
      final notifier = OnboardingNotifier();
      // Each 🤲 is 2 UTF-16 code units. 300 of them would be 600 code units.
      // Grapheme-aware truncation must keep exactly 280 emoji (=560 code units).
      final input = '🤲' * 300;
      notifier.setDuaTopicsOther(input);
      final out = notifier.state.duaTopicsOther!;
      expect(out.characters.length, 280);
      expect(out.length, 560); // 280 emoji × 2 UTF-16 units each
    });

    test('setDuaTopicsOther with empty/whitespace clears', () {
      final notifier = OnboardingNotifier();
      notifier.setDuaTopicsOther('hello');
      expect(notifier.state.duaTopicsOther, 'hello');
      notifier.setDuaTopicsOther('   ');
      expect(notifier.state.duaTopicsOther, isNull);
    });
  });
}
