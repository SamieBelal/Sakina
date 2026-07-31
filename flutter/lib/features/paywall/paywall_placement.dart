import '../../services/analytics_event_names.dart';

/// Which paywall surface a `PaywallScreen` instance represents.
///
/// This is a REQUIRED parameter on `PaywallScreen` (and the only thing the
/// `/paywall` route accepts as its `extra`) so that adding a new entry point
/// without deciding on a surface is a compile error rather than a silently
/// mis-attributed funnel. See W5 Wave C.1.
///
/// [analyticsValue] is the stable wire value for the `placement` property on
/// every paywall event (`paywall_viewed`, `paywall_cta_tapped`,
/// `purchase_sheet_*`, `soft_gate_dismissed`, …). It is deliberately sourced
/// from the existing `AnalyticsEvents.placement*` constants — these strings are
/// already live in Mixpanel and MUST NOT drift.
enum PaywallPlacement {
  /// The onboarding ceremony's paywall page (the PageView at pages 22-26).
  onboarding(AnalyticsEvents.placementOnboarding),

  /// The post-tour HARD entry wall (no X, navigation blocked).
  hardWall(AnalyticsEvents.placementHardWall),

  /// The in-app upsell reached from a cap sheet, a settings card, the home
  /// premium strip, the collection teaser, or an upgrade sheet.
  softInApp(AnalyticsEvents.placementSoftInApp),

  /// The dismissible post-tour soft gate (control arm / generic).
  postTourSoft(AnalyticsEvents.placementPostTourSoft),

  /// The dismissible Day-3 soft gate shown after a reverse trial lapsed.
  postTrialSoft(AnalyticsEvents.placementPostTrialSoft);

  const PaywallPlacement(this.analyticsValue);

  /// The `placement` event-property value for this surface. Stable — Mixpanel
  /// history depends on it.
  final String analyticsValue;

  /// Whether this surface is one of the two post-tour soft gates, which carry
  /// the extra arm-segmentable `trial_paywall_surfaced` / `soft_gate_dismissed`
  /// emissions.
  bool get isPostTourSoftGate =>
      this == PaywallPlacement.postTourSoft ||
      this == PaywallPlacement.postTrialSoft;
}
