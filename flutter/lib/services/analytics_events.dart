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

  // Keep in sync with the PageView in onboarding_screen.dart (27 pages, 0-26).
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
    12: 'social_proof_interstitial',
    13: 'attribution',
    14: 'struggle_support_interstitial',
    15: 'reminder_time',
    16: 'notifications',
    17: 'commitment_pact',
    18: 'generating',
    19: 'personalized_plan',
    20: 'value_prop',
    21: 'social_proof',
    22: 'save_progress',
    23: 'signup_email',
    24: 'signup_password',
    25: 'encouragement',
    26: 'paywall',
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

  void trackOnboardingAnswer(String key, Object? value) {
    track(AnalyticsEvents.onboardingAnswerCaptured, properties: {
      'key': key,
      'value': value is Set ? value.toList() : value,
    });
  }
}
