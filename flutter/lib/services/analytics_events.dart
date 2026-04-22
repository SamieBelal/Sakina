import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import 'analytics_service.dart';

abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const firstCheckinSubmitted = 'first_checkin_submitted';
  static const signupMethodSelected = 'signup_method_selected';
  static const signupCompleted = 'signup_completed';
  static const signupFailed = 'signup_failed';
  static const notificationPermissionResult = 'notification_permission_result';
  static const surveyAnswered = 'survey_answered';
  static const paywallViewed = 'paywall_viewed';
  static const paywallPlanSelected = 'paywall_plan_selected';
  static const paywallCtaTapped = 'paywall_cta_tapped';
  static const paywallClosed = 'paywall_closed';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingAnswerCaptured = 'onboarding_answer_captured';

  // Keep in sync with the PageView in onboarding_screen.dart (26 pages, 0-25).
  static const stepNames = <int, String>{
    0: 'first_checkin',
    1: 'name_input',
    2: 'age_range',
    3: 'intention',
    4: 'prayer_frequency',
    5: 'quran_connection',
    6: 'familiarity',
    7: 'resonant_name',
    8: 'dua_topics',
    9: 'common_emotions',
    10: 'aspirations',
    11: 'daily_commitment',
    12: 'attribution',
    13: 'struggle_support_interstitial',
    14: 'reminder_time',
    15: 'notifications',
    16: 'commitment_pact',
    17: 'generating',
    18: 'personalized_plan',
    19: 'value_prop',
    20: 'social_proof',
    21: 'save_progress',
    22: 'signup_email',
    23: 'signup_password',
    24: 'encouragement',
    25: 'paywall',
  };
}

extension AnalyticsHelpers on AnalyticsService {
  void trackStepViewed(int index) {
    final name = AnalyticsEvents.stepNames[index] ?? 'unknown';
    timeEvent(AnalyticsEvents.onboardingStepCompleted);
    track(AnalyticsEvents.onboardingStepViewed, properties: {
      'step_index': index,
      'step_name': name,
    });
  }

  void trackStepCompleted(int index) {
    final name = AnalyticsEvents.stepNames[index] ?? 'unknown';
    track(AnalyticsEvents.onboardingStepCompleted, properties: {
      'step_index': index,
      'step_name': name,
    });
  }

  void trackSurveyAnswered(String question, dynamic answer) {
    track(AnalyticsEvents.surveyAnswered, properties: {
      'question': question,
      'answer': answer is Set ? answer.toList() : answer,
    });
  }

  void trackOnboardingAnswerWithRef(WidgetRef ref, String key, Object? value) {
    final stepIndex = ref.read(onboardingProvider).currentPage;
    trackOnboardingAnswer(key, value, stepIndex: stepIndex);
  }

  void trackOnboardingAnswer(String key, Object? value, {int? stepIndex}) {
    final props = <String, dynamic>{
      'key': key,
      'value': value is Set ? value.toList() : value,
    };
    if (stepIndex != null) {
      props['step_index'] = stepIndex;
      props['step_name'] = AnalyticsEvents.stepNames[stepIndex] ?? 'unknown';
    }
    track(AnalyticsEvents.onboardingAnswerCaptured, properties: props);
  }
}
