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

  group('Day-1 first-bypass event + reason constants (plan 2026-05-23, PR 4)',
      () {
    // Pins for the Day-1 freebie funnel:
    //   daily_cap_hit → first_bypass_offered → first_bypass_claimed
    // Mixpanel dashboards key off these exact strings. Renames must
    // coordinate with analytics, not happen silently.
    test('event names', () {
      expect(AnalyticsEvents.firstBypassOffered, 'first_bypass_offered');
      expect(AnalyticsEvents.firstBypassClaimed, 'first_bypass_claimed');
      expect(AnalyticsEvents.firstBypassRejected, 'first_bypass_rejected');
    });

    test('rejection reason values match server RPC + client fallback', () {
      // `already_consumed`, `window_expired`, `no_signup_at`,
      // `invalid_feature` returned by claim_first_bypass RPC; `network`
      // is the client-side fallback for transport failure.
      expect(AnalyticsEvents.firstBypassRejectedReasonAlreadyConsumed,
          'already_consumed');
      expect(AnalyticsEvents.firstBypassRejectedReasonWindowExpired,
          'window_expired');
      expect(AnalyticsEvents.firstBypassRejectedReasonNoSignupAt,
          'no_signup_at');
      expect(AnalyticsEvents.firstBypassRejectedReasonInvalidFeature,
          'invalid_feature');
      expect(AnalyticsEvents.firstBypassRejectedReasonNetwork, 'network');
    });
  });

  group('AI bypass event + reason constants (plan 2026-05-23, PR 3)', () {
    // Pin the wire-protocol strings. The Mixpanel funnel
    //   daily_cap_hit → ai_bypass_offered → ai_bypass_purchased
    // and the dashboards that read it are keyed off these exact names.
    // Renaming either constant in Dart MUST be a deliberate analytics-team
    // coordination, not a silent refactor — these tests are the tripwire.
    test('event names match Mixpanel funnel + dashboard contract', () {
      expect(AnalyticsEvents.aiBypassOffered, 'ai_bypass_offered');
      expect(AnalyticsEvents.aiBypassPurchased, 'ai_bypass_purchased');
      expect(AnalyticsEvents.aiBypassRejected, 'ai_bypass_rejected');
    });

    test('rejection reason values match server RPC + client fallback', () {
      // `no_tokens` and `bypass_cap` are returned by the server RPC
      // `reserve_ai_bypass`; `network` is the client-side fallback for an
      // RPC that returns null (transport failure). Server SQL test pins
      // the same strings on the backend side.
      expect(AnalyticsEvents.aiBypassRejectedReasonNoTokens, 'no_tokens');
      expect(AnalyticsEvents.aiBypassRejectedReasonBypassCap, 'bypass_cap');
      expect(AnalyticsEvents.aiBypassRejectedReasonNetwork, 'network');
    });
  });

  group('signup_failed reason constants', () {
    // The sign-up password screen's session-race branch (previously a silent
    // SnackBar+return) now fires signup_failed with this exact reason — pin
    // the contract so a rename in either side surfaces as a test failure.
    test('exposes session_race + unknown as typed constants', () {
      expect(AnalyticsEvents.signupFailedReasonSessionRace, 'session_race');
      expect(AnalyticsEvents.signupFailedReasonUnknown, 'unknown');
    });
  });

  group('AnalyticsEvents.stepNames', () {
    test('covers all 27 onboarding pages (rating gate at 25, paywall at 26)', () {
      // Updated 2026-05-14 by rating-gate insertion. The map carries entries
      // for indices 0..26 regardless of `Env.ratingGateEnabled` so analytics
      // funnel queries remain stable across the kill-switch toggle; when the
      // gate is off the PageView simply never emits step_index=25 events.
      for (int i = 0; i <= 26; i++) {
        expect(AnalyticsEvents.stepNames[i], isNotNull,
            reason: 'Missing step name for index $i');
      }
      expect(AnalyticsEvents.stepNames[25], 'rating_gate');
      expect(AnalyticsEvents.stepNames[26], 'paywall');
      expect(AnalyticsEvents.stepNames[27], isNull,
          reason: 'No step at index 27 after rating-gate insertion');
    });

    test('does not include the removed social_proof_interstitial step', () {
      expect(
        AnalyticsEvents.stepNames.values,
        isNot(contains('social_proof_interstitial')),
      );
    });

    test('does not include the removed resonant_name step', () {
      expect(
        AnalyticsEvents.stepNames.values,
        isNot(contains('resonant_name')),
      );
    });
  });
}
