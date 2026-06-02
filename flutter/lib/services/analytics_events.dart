import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/onboarding/providers/onboarding_provider.dart';
import 'analytics_service.dart';
import 'analytics_event_names.dart';

// Re-export the pure constants so the ~30 widget/provider files importing
// analytics_events.dart for AnalyticsEvents keep working unchanged.
export 'analytics_event_names.dart';

extension AnalyticsHelpers on AnalyticsService {
  void trackStepViewed(int index, {required bool trimmed}) {
    final name = AnalyticsEvents.stepNamesFor(trimmed: trimmed)[index] ??
        'unknown';
    timeEvent(AnalyticsEvents.onboardingStepCompleted);
    track(AnalyticsEvents.onboardingStepViewed, properties: {
      'step_index': index,
      'step_name': name,
    });
  }

  void trackStepCompleted(int index, {required bool trimmed}) {
    final name = AnalyticsEvents.stepNamesFor(trimmed: trimmed)[index] ??
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
      props['step_name'] = AnalyticsEvents.stepNames[stepIndex] ?? 'unknown';
    }
    track(AnalyticsEvents.onboardingAnswerCaptured, properties: props);
  }
}
