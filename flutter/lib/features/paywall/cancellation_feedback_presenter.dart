import 'package:flutter/material.dart';

import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/analytics_service.dart';
import 'package:sakina/services/cancellation_feedback_service.dart';
import 'widgets/cancellation_feedback_sheet.dart';

/// Shows the cancellation survey for [cancellation] and persists the outcome.
/// Shared by all three entry points (instant post-Customer-Center, reactive
/// home-screen, and the push deep-link) so presentation + persistence stay in
/// one place. Submit/dismiss are fire-and-forget — feedback must never block
/// or error in the user's face.
Future<void> presentCancellationFeedback(
  BuildContext context, {
  required CancellationContext cancellation,
  required CancellationFeedbackService service,
  required AnalyticsService analytics,
}) {
  analytics.track(
    AnalyticsEvents.cancellationFeedbackShown,
    properties: <String, dynamic>{
      'period_type': cancellation.periodType,
      'source': cancellation.source.value,
      'is_trial': cancellation.isTrial,
    },
  );

  return CancellationFeedbackSheet.show(
    context,
    isTrial: cancellation.isTrial,
    onSubmit: (reason, text) {
      service.submit(cancellation, reason: reason, reasonText: text);
    },
    onSkip: () {
      service.dismiss(cancellation);
    },
  );
}
