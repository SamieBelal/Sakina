/// Which plan the gate has selected.
enum PaywallPlanType { annual, weekly }

/// Everything the gate's pages need to render prices, durations and terms —
/// resolved once in `PaywallScreen` from the live RevenueCat packages and this
/// user's per-user intro eligibility, then handed down.
///
/// The pages take strings, not packages: they must be renderable in a widget
/// test at a fixed size without a store, and the one place a duration or a
/// price is computed should be the one place that reads the store.
class PaywallOfferView {
  const PaywallOfferView({
    required this.annualPriceLine,
    required this.weeklyRowLabel,
    required this.termsLine,
    required this.ctaLabel,
    this.trialLabel,
    this.trialDays,
  });

  /// `"$49.99/year · $0.96 a week"`.
  final String annualPriceLine;

  /// `"Weekly — $4.99/week · 7 days free first"`, or without the trial clause
  /// when this user gets no trial.
  final String weeklyRowLabel;

  /// The plain terms under the CTA. Always states the post-trial charge, the
  /// period, and how to cancel.
  final String termsLine;

  /// `"Start my 7 days free"` or `"Subscribe"`.
  final String ctaLabel;

  /// `"7 days"` — `null` when this user is not eligible for the intro offer.
  /// Its nullness is what removes every trial promise from the gate at once.
  final String? trialLabel;

  /// The trial in whole days, when it converts. Drives the timeline page's
  /// "Day N-1 / Day N" beats; `null` suppresses the page entirely rather than
  /// render a day number the store did not give us.
  final int? trialDays;

  /// Whether the gate may make any trial promise at all.
  bool get hasTrial => trialLabel != null;
}
