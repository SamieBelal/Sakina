import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/analytics_events.dart';

class TrackingSpy extends AnalyticsService {
  final List<(String event, Map<String, dynamic>? props)> tracked = [];
  final List<String> timedEvents = [];

  @override
  void track(String event, {Map<String, dynamic>? properties}) {
    tracked.add((event, properties));
  }

  @override
  void timeEvent(String event) {
    timedEvents.add(event);
  }
}

void main() {
  late TrackingSpy spy;

  setUp(() {
    spy = TrackingSpy();
  });

  group('trackStepViewed', () {
    test('fires timeEvent and track with correct properties', () {
      spy.trackStepViewed(3);

      expect(spy.timedEvents, [AnalyticsEvents.onboardingStepCompleted]);
      expect(spy.tracked.length, 1);
      expect(spy.tracked[0].$1, AnalyticsEvents.onboardingStepViewed);
      expect(spy.tracked[0].$2, {'step_index': 3, 'step_name': 'intention'});
    });

    test('uses unknown for unmapped index', () {
      spy.trackStepViewed(99);
      expect(spy.tracked[0].$2?['step_name'], 'unknown');
    });
  });

  group('trackStepCompleted', () {
    test('fires track with correct properties', () {
      spy.trackStepCompleted(0);
      expect(spy.tracked[0].$1, AnalyticsEvents.onboardingStepCompleted);
      expect(spy.tracked[0].$2, {'step_index': 0, 'step_name': 'first_checkin'});
    });
  });

  group('trackSurveyAnswered', () {
    test('passes String answer directly', () {
      spy.trackSurveyAnswered('intention', 'Spiritual Growth');
      expect(spy.tracked[0].$2, {
        'question': 'intention',
        'answer': 'Spiritual Growth',
      });
    });

    test('converts Set answer to List', () {
      spy.trackSurveyAnswered('common_emotions', {'anxious', 'grief'});
      final answer = spy.tracked[0].$2?['answer'];
      expect(answer, isA<List>());
      expect(answer, containsAll(['anxious', 'grief']));
    });

    test('handles null answer', () {
      spy.trackSurveyAnswered('familiarity', null);
      expect(spy.tracked[0].$2?['answer'], isNull);
    });
  });

  group('trackOnboardingAnswer', () {
    test('fires onboarding_answer_captured with key + value', () {
      spy.trackOnboardingAnswer('age_range', '25_34');
      expect(spy.tracked.length, 1);
      expect(spy.tracked[0].$1, AnalyticsEvents.onboardingAnswerCaptured);
      expect(spy.tracked[0].$2, {'key': 'age_range', 'value': '25_34'});
    });

    test('converts Set value to List', () {
      spy.trackOnboardingAnswer('common_emotions', {'anxious', 'hopeful'});
      final value = spy.tracked[0].$2?['value'];
      expect(value, isA<List>());
      expect(value, containsAll(['anxious', 'hopeful']));
    });

    test('handles null value', () {
      spy.trackOnboardingAnswer('reminder_time', null);
      expect(spy.tracked[0].$2, {'key': 'reminder_time', 'value': null});
    });

    test('passes int value through', () {
      spy.trackOnboardingAnswer('daily_commitment_minutes', 5);
      expect(spy.tracked[0].$2, {
        'key': 'daily_commitment_minutes',
        'value': 5,
      });
    });
  });

  group('AnalyticsEvents.stepNames', () {
    test('covers all 26 onboarding pages', () {
      for (int i = 0; i <= 25; i++) {
        expect(AnalyticsEvents.stepNames[i], isNotNull,
            reason: 'Missing step name for index $i');
      }
    });

    test('does not include the removed social_proof_interstitial step', () {
      expect(
        AnalyticsEvents.stepNames.values,
        isNot(contains('social_proof_interstitial')),
      );
    });
  });
}
