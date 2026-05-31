import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';
import 'cancellation_feedback_service.dart';

/// Wires [CancellationFeedbackService] with the analytics instance. Tests can
/// override this provider, or construct the service directly with fakes.
final cancellationFeedbackServiceProvider =
    Provider<CancellationFeedbackService>(
  (ref) => CancellationFeedbackService(analytics: ref.read(analyticsProvider)),
);
