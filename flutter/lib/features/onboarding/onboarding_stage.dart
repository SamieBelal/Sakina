/// Post-authentication onboarding gate stages.
///
/// This is the single source of truth for "where in the new-user funnel is this
/// user right now?" — consumed by the GoRouter `redirect` (see
/// `lib/core/router.dart`). It is a PURE function of explicit booleans so every
/// branch is unit-testable without a live router, Supabase, or RevenueCat.
///
/// ```
///                         ┌──────────────────────────────┐
///   !auth || !onboarded ─▶│ OnboardingStage.welcome       │
///                         └──────────────────────────────┘
///   flow flag OFF ───────▶ app            (kill switch: legacy behaviour)
///   paywallCleared|premium▶ app            (grandfathered / entered / paying)
///   !tourCompleted ──────▶ tour           (force the guided tour, resume mid-way)
///   else ────────────────▶ hardPaywall    (tour done, must start trial to enter)
/// ```
///
/// IMPORTANT — grandfathering: `paywallCleared` short-circuits BEFORE the tour
/// check. Existing users (onboarded before this feature shipped) are backfilled
/// `onboarding_paywall_cleared = true` by the migration, so they route straight
/// to `app` and never get flashed into the tour or the wall. Brand-new users
/// start with the latch `false` and flow through tour → wall.
enum OnboardingStage {
  /// Not authenticated or not finished onboarding — hand off to /welcome.
  welcome,

  /// Authenticated, onboarded, but the forced guided tour is not complete.
  tour,

  /// Tour complete, but the user has not cleared the entry wall (no trial
  /// started, not premium) — show the no-X hard paywall.
  hardPaywall,

  /// Cleared to use the app (grandfathered, started a trial, premium, or the
  /// kill switch is off).
  app,
}

/// Resolves the [OnboardingStage] from explicit state. Pure — no I/O.
///
/// [hardPaywallFlowEnabled] is the `hard_paywall_after_tour_enabled` server
/// kill switch. When `false`, the whole tour+wall gate is bypassed and the user
/// goes straight to the app (legacy behaviour, instant rollback).
OnboardingStage resolveOnboardingStage({
  required bool isAuthenticated,
  required bool hasOnboarded,
  required bool tourCompleted,
  required bool paywallCleared,
  required bool isPremium,
  required bool hardPaywallFlowEnabled,
}) {
  if (!isAuthenticated || !hasOnboarded) return OnboardingStage.welcome;

  // Kill switch off → legacy behaviour, no gate.
  if (!hardPaywallFlowEnabled) return OnboardingStage.app;

  // Grandfathered (migration backfill), already entered (latch), or paying
  // (gift/referral/RC). Checked BEFORE the tour so existing users never flash
  // the gate. Premium also implies the wall is moot.
  if (paywallCleared || isPremium) return OnboardingStage.app;

  // New user who has not finished the forced tour.
  if (!tourCompleted) return OnboardingStage.tour;

  // Tour done, wall not cleared → the hard paywall.
  return OnboardingStage.hardPaywall;
}
