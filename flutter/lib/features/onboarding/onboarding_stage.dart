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
///   mode == off ─────────▶ app            (kill switch: legacy behaviour)
///   paywallCleared ──────▶ app            (grandfathered / already entered)
///   premium ─────────────▶ app            (paying / active trial)
///   else ────────────────▶ hard|softPaywall
/// ```
///
/// **The guided tour was deleted 2026-07-28 (One Ship W2, plan §F1a).** There is
/// no longer a `tour` stage: nothing in the app can enter one, so no user can be
/// parked on a stage that has neither a tour nor a paywall surface. That was the
/// stranding bug class §F0 describes — a user with `tour_seen = false` used to
/// route to `tour` while the controller declined to start, leaving them with no
/// gate at all. Removing the branch RELEASES those users: on their next launch
/// they fall through to the paywall stage (or `app` when
/// `post_tour_paywall_mode` is `off`), which is where they should have been.
///
/// IMPORTANT — grandfathering: `paywallCleared` short-circuits the paywall
/// stages. Existing users (onboarded before this feature shipped) are backfilled
/// `onboarding_paywall_cleared = true` by the migration, so they route straight
/// to `app` and never get flashed into the wall. Brand-new users start with the
/// latch `false` and flow through to the wall.
enum OnboardingStage {
  /// Not authenticated or not finished onboarding — hand off to /welcome.
  welcome,

  /// The user has not cleared the entry wall (no trial started, not premium)
  /// — show the no-X hard paywall.
  hardPaywall,

  /// Wall not cleared and the post-onboarding mode is `soft` (reverse-trial
  /// direction). Show a DISMISSIBLE paywall; on dismiss the user drops to the
  /// free tier and enters the app — the router does NOT block navigation away
  /// from it.
  softPaywall,

  /// Cleared to use the app (grandfathered, started a trial, premium, or the
  /// post-onboarding mode is `off`).
  app,
}

/// The post-onboarding paywall behaviour, sourced from the server `app_config`
/// `post_tour_paywall_mode` string. (The key keeps its historical name — the
/// tour it once followed is gone, the gate it drives is not.) Replaces the
/// overloaded boolean kill switch: `off` = straight to app (legacy rollback),
/// `soft` = dismissible paywall (reverse-trial Phase A), `hard` = the no-X entry
/// wall (legacy hard gate).
enum PostTourPaywallMode {
  /// No post-onboarding gate — users go straight to the app.
  off,

  /// Dismissible post-onboarding paywall; dismiss → free tier + app.
  soft,

  /// No-X post-onboarding entry wall; exits only via trial / purchase / premium.
  hard,
}

/// Resolves the [OnboardingStage] from explicit state. Pure — no I/O.
///
/// Routing precedence:
///   1. `!auth || !onboarded` → [OnboardingStage.welcome]
///   2. mode `off` → [OnboardingStage.app]  (kill switch)
///   3. `paywallCleared` → [OnboardingStage.app]  (grandfather latch only)
///   4. `isPremium` → [OnboardingStage.app]
///   5. by mode: `hard` → [OnboardingStage.hardPaywall],
///      `soft` → [OnboardingStage.softPaywall].
///
/// [paywallMode] is the `post_tour_paywall_mode` driver. When supplied it fully
/// determines the gate branch. When omitted (`null`), the function falls back to
/// the legacy [hardPaywallFlowEnabled] boolean
/// (`hard_paywall_after_tour_enabled`): `true` → `hard`, `false` → `off`.
OnboardingStage resolveOnboardingStage({
  required bool isAuthenticated,
  required bool hasOnboarded,
  required bool paywallCleared,
  required bool isPremium,
  bool? hardPaywallFlowEnabled,
  PostTourPaywallMode? paywallMode,
}) {
  if (!isAuthenticated || !hasOnboarded) return OnboardingStage.welcome;

  // Derive the effective gate mode: explicit mode wins; otherwise fall back to
  // the legacy boolean (true→hard, false→off). Default `off` keeps the gate
  // dark if neither is provided.
  final mode = paywallMode ??
      ((hardPaywallFlowEnabled ?? false)
          ? PostTourPaywallMode.hard
          : PostTourPaywallMode.off);

  // `off` → legacy behaviour, no gate at all.
  if (mode == PostTourPaywallMode.off) return OnboardingStage.app;

  // CLEARED latch → straight to app. Grandfathered (migration backfill / key
  // absent → defaults cleared), already-entered-then-cleared, or the
  // offerings-fail valve bypass. This is the cleared latch ONLY —
  // `paywallCleared` is set false exclusively for a brand-new user by
  // `enterOnboardingGate` and defaults true otherwise, so it cleanly identifies
  // "already past the gate".
  if (paywallCleared) return OnboardingStage.app;

  // Premium (paid OR an active reverse-trial window) makes the wall moot → app.
  // Before the tour was deleted this check sat AFTER the tour branch so a
  // reverse-trial TREATMENT user (premium via the granted trial) still took the
  // same forced tour as control. With no tour to confound, premium can
  // short-circuit directly.
  if (isPremium) return OnboardingStage.app;

  // Not cleared, not premium → the configured gate.
  switch (mode) {
    case PostTourPaywallMode.hard:
      return OnboardingStage.hardPaywall;
    case PostTourPaywallMode.soft:
      return OnboardingStage.softPaywall;
    case PostTourPaywallMode.off:
      return OnboardingStage.app;
  }
}
