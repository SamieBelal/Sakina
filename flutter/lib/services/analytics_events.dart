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

  static const stepNames = <int, String>{
    0: 'first_checkin',
    1: 'feature_collect',
    2: 'feature_reflect',
    3: 'feature_dua',
    4: 'feature_quests',
    5: 'feature_journal',
    6: 'save_progress',
    7: 'signup_email',
    8: 'signup_password',
    9: 'signup_name',
    10: 'encouragement',
    11: 'notifications',
    12: 'intention',
    13: 'value_prop',
    14: 'familiarity',
    15: 'quran_connection',
    16: 'struggles',
    17: 'attribution',
    18: 'social_proof',
    19: 'paywall',
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
}
