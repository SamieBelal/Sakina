import '../../services/analytics_event_names.dart';
import '../../services/analytics_service.dart';

/// Analytics emissions for the lapsed-trial Day-3 soft gate (the in-app
/// [LapsedTrialSheet] surfaced from the progress/home screen). Extracted into
/// pure top-level helpers so the event schema is unit-testable without mounting
/// the large `ProgressScreen` ConsumerStatefulWidget.
///
/// The schema MUST stay in lockstep with the sibling emitter in
/// `paywall_screen.dart` (the routing PaywallScreen at `post_trial_soft`):
/// both `trial_paywall_surfaced` and `soft_gate_dismissed` carry an explicit
/// per-event `arm` so the reverse-trial readout segments by experiment arm.
/// The `arm` comes from `appSessionProvider.paywallArm` at the call site (the
/// Riverpod-free service layer has no experiment access). See
/// `lib/core/app_session.dart` ("explicit per-event copy the ADR specifies on
/// the soft-gate events").

/// Emits `trial_paywall_surfaced{placement, arm, hard_gate:false}` for the
/// lapsed-trial soft-gate impression.
void recordLapsedSoftGateSurfaced(
  AnalyticsService analytics, {
  required String placement,
  required String arm,
}) {
  analytics.track(AnalyticsEvents.trialPaywallSurfaced, properties: {
    AnalyticsEvents.propPlacement: placement,
    AnalyticsEvents.propArm: arm,
    AnalyticsEvents.propHardGate: false,
  });
}

/// Emits `soft_gate_dismissed{placement, arm}` for the lapsed-trial soft-gate
/// loss path (any dismissal — button, barrier, swipe, or back).
void recordLapsedSoftGateDismissed(
  AnalyticsService analytics, {
  required String placement,
  required String arm,
}) {
  analytics.track(AnalyticsEvents.softGateDismissed, properties: {
    AnalyticsEvents.propPlacement: placement,
    AnalyticsEvents.propArm: arm,
  });
}
