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
///
/// Any way the sheet closes records a row for the `(user_id, expires_at)`
/// episode so it is never re-shown: Submit → `submitted`, Skip → `dismissed`,
/// and a swipe-down / tap-outside (no explicit choice) is treated as an
/// implicit Skip → `dismissed`. Without that last case the survey would
/// re-appear on every app open until the user explicitly tapped a button.
Future<void> presentCancellationFeedback(
  BuildContext context, {
  required CancellationContext cancellation,
  required CancellationFeedbackService service,
  required AnalyticsService analytics,
}) async {
  analytics.track(
    AnalyticsEvents.cancellationFeedbackShown,
    properties: <String, dynamic>{
      'period_type': cancellation.periodType,
      'source': cancellation.source.value,
      'is_trial': cancellation.isTrial,
    },
  );

  var handled = false;
  await CancellationFeedbackSheet.show(
    context,
    isTrial: cancellation.isTrial,
    onSubmit: (reason, text) {
      handled = true;
      service.submit(cancellation, reason: reason, reasonText: text);
    },
    onSkip: () {
      handled = true;
      service.dismiss(cancellation);
    },
  );

  // Sheet dismissed by swipe-down / tap-outside (neither button tapped):
  // record it as a Skip so the episode is deduped and never re-prompts.
  if (!handled) {
    service.dismiss(cancellation);
  }
}
