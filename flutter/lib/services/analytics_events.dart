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

  // Rating gate (page 25, inserted between YourJourney and Paywall — see
  // docs/superpowers/plans/2026-05-14-rating-gate.md).
  static const ratingGateShown = 'rating_gate_shown';
  static const ratingGatePromptTriggered = 'rating_gate_prompt_triggered';
  static const ratingGateContinueTapped = 'rating_gate_continue_tapped';

  static const paywallViewed = 'paywall_viewed';
  static const paywallPlanSelected = 'paywall_plan_selected';
  static const paywallCtaTapped = 'paywall_cta_tapped';
  static const paywallClosed = 'paywall_closed';
  static const paywallExitOfferShown = 'paywall_exit_offer_shown';
  static const paywallExitOfferAccepted = 'paywall_exit_offer_accepted';
  static const paywallFlowLoaderShown = 'paywall_flow_loader_shown';
  static const paywallFlowLoaderAdvanced = 'paywall_flow_loader_advanced';
  static const paywallFlowPlanShown = 'paywall_flow_plan_shown';
  static const paywallFlowPlanContinued = 'paywall_flow_plan_continued';
  static const paywallFlowJourneyShown = 'paywall_flow_journey_shown';
  static const paywallFlowJourneyContinued = 'paywall_flow_journey_continued';
  static const paywallFlowDropoff = 'paywall_flow_dropoff';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingAnswerCaptured = 'onboarding_answer_captured';

  // Settings → Premium card. Persistent upgrade affordance added 2026-05-13
  // in response to the App Review rejection (reviewer could not find the
  // paywall outside onboarding). See
  // docs/superpowers/specs/2026-05-13-settings-premium-entry-design.md.
  static const settingsPremiumCtaTapped = 'settings_premium_cta_tapped';
  static const settingsPremiumManageTapped = 'settings_premium_manage_tapped';
  static const settingsPremiumBillingIssueTapped =
      'settings_premium_billing_issue_tapped';

  // Refer-to-Unlock (forward-instrumented per CEO review — there's no v1
  // baseline yet; these events power the post-launch cannibalization +
  // dwell + mutual-grant dashboards. See
  // docs/superpowers/plans/2026-05-14-refer-unlock.md Task 5 Step 3).
  static const referUnlockShown = 'refer_unlock_shown';
  static const referUnlockShareTapped = 'refer_unlock_share_tapped';
  /// Fired on every share in v1. Lets Phase 2 dashboards compare the install
  /// funnel before/after universal-link rollout.
  static const referUnlockShareNoUniversalLinks =
      'refer_unlock_share_no_universal_links';
  static const referUnlockStartTrialTapped = 'refer_unlock_start_trial_tapped';
  static const referUnlockBackToPaywall = 'refer_unlock_back_to_paywall';
  /// Fired client-side when apply_referral RPC succeeds (referee side).
  static const refereeSignedUpWithReferral = 'referee_signed_up_with_referral';
  /// Fired client-side when confirm_referral_if_pending returns granted=true
  /// (the referrer just crossed the 3-confirmed threshold).
  static const referrerGranted30dWindow = 'referrer_granted_30d_window';
  /// Fired client-side when apply_referral returns granted_referee_7d=true
  /// (mutual reward fired for the referee).
  static const refereeGranted7dWindow = 'referee_granted_7d_window';

  // Keep in sync with the PageView in onboarding_screen.dart (27 pages, 0-26
  // when Env.ratingGateEnabled is true; 26 pages, 0-25 when false).
  // Updated 2026-05-05 by paywall flow redesign — the GeneratingScreen +
  // PersonalizedPlanScreen pair moved from pages 16-17 into the paywall flow
  // at pages 22-23; YourJourneyScreen new at page 24; paywall at page 25.
  // Updated 2026-05-14 by rating-gate insertion — gate added at index 25
  // (when enabled), paywall shifts to 26. See docs/superpowers/plans/
  // 2026-05-14-rating-gate.md.
  static const stepNames = <int, String>{
    0: 'first_checkin',
    1: 'name_input',
    2: 'age_range',
    3: 'intention',
    4: 'prayer_frequency',
    5: 'quran_connection',
    6: 'familiarity',
    7: 'dua_topics',
    8: 'common_emotions',
    9: 'aspirations',
    10: 'daily_commitment',
    11: 'attribution',
    12: 'struggle_support_interstitial',
    13: 'reminder_time',
    14: 'notifications',
    15: 'commitment_pact',
    16: 'value_prop',
    17: 'social_proof',
    18: 'save_progress',
    19: 'signup_email',
    20: 'signup_password',
    21: 'encouragement',
    22: 'paywall_flow_loader',
    23: 'paywall_flow_plan',
    24: 'paywall_flow_journey',
    25: 'rating_gate',
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
