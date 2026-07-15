/// Pure decision core for the home-screen "add the Sakina widget" nudge.
///
/// Dependency-free (no Flutter / Riverpod / prefs imports) so every branch is
/// unit-testable — same leaf-module discipline as `referral_nudge_gate.dart`.
/// The card gathers the inputs (dismissed flag, current streak) and calls
/// [resolveWidgetInstallNudge]; this holds only the eligibility rules.
///
/// Why a streak gate: research on widget stickiness is blunt that a widget only
/// retains users who INSTALL it, and adoption is a minority by default. We wait
/// until the user has felt the value (completed at least one muḥāsabah → streak
/// ≥ 1) so the ask lands at the "aha" moment, then show it until dismissed.
///
/// ```
///                 resolveWidgetInstallNudge
///   dismissed ─────────────────────────────► hidden  (user said no, forever)
///   currentStreak < minStreak ─────────────► hidden  (not engaged yet)
///   else ──────────────────────────────────► show
/// ```
library;

enum WidgetInstallNudgeDecision { hidden, show }

/// Decide whether the widget-install nudge card should render this pass.
///
/// - [dismissed]: the user tapped the card's dismiss (persisted); once true the
///   card never returns.
/// - [currentStreak]: the user's muḥāsabah streak. The nudge waits for ≥
///   [minStreak] so it lands after they've experienced the daily loop.
WidgetInstallNudgeDecision resolveWidgetInstallNudge({
  required bool dismissed,
  required int currentStreak,
  int minStreak = 1,
}) {
  if (dismissed) return WidgetInstallNudgeDecision.hidden;
  if (currentStreak < minStreak) return WidgetInstallNudgeDecision.hidden;
  return WidgetInstallNudgeDecision.show;
}
