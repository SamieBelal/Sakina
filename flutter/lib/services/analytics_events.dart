import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import 'analytics_service.dart';
import 'analytics_event_names.dart';
import 'install_id_service.dart' show installIdPropertyName;

// Re-export the pure constants so the ~30 widget/provider files importing
// analytics_events.dart for AnalyticsEvents keep working unchanged.
export 'analytics_event_names.dart';

/// SharedPreferences key guarding the once-ever `app_install` event. Fired
/// exactly once in the app's lifetime — NOT the `onboarding_completed` proxy
/// (a user can complete onboarding on a reinstall, or be sideloaded mid-flow).
/// Extracted here so the boot bootstrap is unit-testable.
const String analyticsAppInstallFiredPrefsKey = 'analytics_app_install_fired';

/// Registers the boot-time experiment-context super properties and fires the
/// once-ever `app_install` event. Extracted from `main.dart` so the
/// flag/super-property/install-guard logic is unit-testable without booting the
/// whole app.
///
/// Sets `platform`, `app_version`, the `flag_*` experiment-context super
/// properties, and `is_premium` (so every event — and thus any funnel — is
/// segmentable by flag combination, release, and conversion state). Then fires
/// `app_install` exactly once, guarded by [analyticsAppInstallFiredPrefsKey].
///
/// `main.dart` resolves the flags + version + premium state and passes them in;
/// behavior must remain identical to the previous inline implementation.
/// Best-effort: callers fire-and-forget; a slow/failed read defaults upstream
/// (see `main.dart`) and never blocks launch.
Future<void> registerBootstrapAnalytics({
  required AnalyticsService analytics,
  required SharedPreferences prefs,
  required String platform,
  required String appVersion,
  required bool flagOnboardingTrim,
  required bool flagHardPaywall,
  required bool flagGuidedTour,
  required bool isPremium,
  String? installId,
}) async {
  // Device/build/experiment super properties — durable across a sign-out reset
  // (re-applied by AnalyticsService.resetForSignOut). is_premium is registered
  // separately below because it is USER-scoped and must not carry to the next
  // user who signs in on the same device.
  analytics.cacheDeviceSuperProperties({
    'platform': platform,
    'app_version': appVersion,
    'flag_onboarding_trim': flagOnboardingTrim,
    'flag_hard_paywall': flagHardPaywall,
    // flag_tour_ab retired 2026-07-25 (slim-vs-full A/B concluded; flag off
    // since 06-15). Mixpanel super properties PERSIST on-device and merge, so
    // omission alone is not retirement — the explicit unregister below scrubs
    // upgraded installs. Historical events keep the property.
    'flag_guided_tour': flagGuidedTour,
    // flag_reverse_trial_exp retired 2026-08-01 with the reverse-trial
    // close-out — same posture as flag_tour_ab: omitted here, explicitly
    // unregistered below, historical events keep it.
    // Install id (W2-E3): DEVICE-scoped, so it rides `cacheDeviceSuperProperties`
    // and survives the sign-out reset. It is the join key between pre-signup
    // reel events and the RevenueCat subscriber (same value, set as a custom RC
    // subscriber attribute at purchase-service init). Omitted rather than
    // registered null when the read failed — a null super property is worse than
    // an absent one, since it looks like a real value in a breakdown.
    if (installId != null && installId.isNotEmpty)
      installIdPropertyName: installId,
  });
  // One-shot scrub of retired super properties from upgraded installs'
  // persisted store — cheap and idempotent, so it runs every bootstrap.
  // Omission alone is NOT retirement: Mixpanel super properties persist
  // on-device and merge into every subsequent event, so an install that once
  // registered these would keep stamping a stale value forever.
  analytics.removeSuperProperty('flag_tour_ab');
  // Reverse-trial close-out (W5 Wave A, 2026-08-01). `paywall_exp_arm` is
  // FROZEN as history — historical events only, never re-added, never recycled.
  // The next paywall experiment ships a NEW property (`gate_exp_arm`), and
  // `onboarding_flow` is a different property that must never be unioned with
  // it.
  analytics.removeSuperProperty(AnalyticsEvents.flagReverseTrialExp);
  analytics.removeSuperProperty(AnalyticsEvents.paywallExpArm);
  analytics.setSuperProperties({AnalyticsEvents.isPremium: isPremium});
  // app_install: fire EXACTLY ONCE in the app's lifetime, guarded by its own
  // SharedPreferences flag. Set the flag immediately after firing so a crash
  // between track + setBool can at most double-fire, never silently lose it on
  // the happy path.
  if (!(prefs.getBool(analyticsAppInstallFiredPrefsKey) ?? false)) {
    analytics.track(AnalyticsEvents.appInstall);
    await prefs.setBool(analyticsAppInstallFiredPrefsKey, true);
  }
}

extension AnalyticsHelpers on AnalyticsService {
  void trackStepViewed(int index, {required bool trimmed, bool reel = false}) {
    final name =
        AnalyticsEvents.stepNamesFor(trimmed: trimmed, reel: reel)[index] ??
            'unknown';
    timeEvent(AnalyticsEvents.onboardingStepCompleted);
    track(AnalyticsEvents.onboardingStepViewed, properties: {
      'step_index': index,
      'step_name': name,
    });
  }

  void trackStepCompleted(
    int index, {
    required bool trimmed,
    bool reel = false,
  }) {
    final name =
        AnalyticsEvents.stepNamesFor(trimmed: trimmed, reel: reel)[index] ??
            'unknown';
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
      // `step_name` intentionally omitted: it previously hardcoded the LEGACY
      // 27-page name map (`AnalyticsEvents.stepNames`) while the live flow is
      // trimmed, so every answer from index 4+ carried the WRONG name. `key`
      // already identifies the question unambiguously, `step_index` gives the
      // position, and the `flag_onboarding_trim` super property identifies the
      // flow — so the redundant, corruptible step_name is dropped rather than
      // patched. (2026-06-15 funnel-instrumentation audit, gap G1.)
    }
    track(AnalyticsEvents.onboardingAnswerCaptured, properties: props);
  }
}
