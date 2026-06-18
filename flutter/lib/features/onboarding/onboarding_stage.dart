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
///   paywallCleared ──────▶ app            (grandfathered / already entered)
///   !tourCompleted ──────▶ tour           (force the guided tour, resume mid-way)
///   premium ─────────────▶ app            (tour done + paying / active trial)
///   else ────────────────▶ hardPaywall    (tour done, must start trial to enter)
/// ```
///
/// IMPORTANT — grandfathering: only `paywallCleared` short-circuits BEFORE the
/// tour. Existing users (onboarded before this feature shipped) are backfilled
/// `onboarding_paywall_cleared = true` by the migration, so they route straight
/// to `app` and never get flashed into the tour or the wall. Brand-new users
/// start with the latch `false` and flow through tour → wall. `premium` is
/// checked AFTER the tour (a reverse-trial TREATMENT user is premium via the
/// granted trial but must still see the same forced tour as control).
enum OnboardingStage {
  /// Not authenticated or not finished onboarding — hand off to /welcome.
  welcome,

  /// Authenticated, onboarded, but the forced guided tour is not complete.
  tour,

  /// Tour complete, but the user has not cleared the entry wall (no trial
  /// started, not premium) — show the no-X hard paywall.
  hardPaywall,

  /// Tour complete, wall not cleared, and the post-tour mode is `soft`
  /// (reverse-trial direction). Show a DISMISSIBLE paywall; on dismiss the user
  /// drops to the free tier and enters the app — the router does NOT block
  /// navigation away from it.
  softPaywall,

  /// Cleared to use the app (grandfathered, started a trial, premium, or the
  /// post-tour mode is `off`).
  app,
}

/// The post-tour paywall behaviour, sourced from the server `app_config`
/// `post_tour_paywall_mode` string. Replaces the overloaded boolean kill switch:
/// `off` = straight to app (legacy rollback), `soft` = dismissible paywall
/// (reverse-trial Phase A), `hard` = the no-X entry wall (legacy hard gate).
enum PostTourPaywallMode {
  /// No post-tour gate — tour-done users go straight to the app.
  off,

  /// Dismissible post-tour paywall; dismiss → free tier + app.
  soft,

  /// No-X post-tour entry wall; exits only via trial / purchase / premium.
  hard,
}

/// Resolves the [OnboardingStage] from explicit state. Pure — no I/O.
///
/// Routing precedence:
///   1. `!auth || !onboarded` → [OnboardingStage.welcome]
///   2. `paywallCleared` → [OnboardingStage.app]  (grandfather latch only)
///   3. `!tourCompleted` → [OnboardingStage.tour]
///   4. `isPremium` → [OnboardingStage.app]  (checked AFTER the tour, so a
///      reverse-trial treatment user still completes the forced tour)
///   5. by post-tour mode: `hard` → [OnboardingStage.hardPaywall],
///      `soft` → [OnboardingStage.softPaywall], `off` → [OnboardingStage.app].
///
/// [paywallMode] is the new `post_tour_paywall_mode` driver. When supplied it
/// fully determines the post-tour branch. When omitted (`null`), the function
/// falls back to the legacy [hardPaywallFlowEnabled] boolean
/// (`hard_paywall_after_tour_enabled`): `true` → `hard`, `false` → `off`. This
/// preserves today's behaviour for the live 1.1.x binary and the existing
/// progress_screen caller that still passes the boolean.
OnboardingStage resolveOnboardingStage({
  required bool isAuthenticated,
  required bool hasOnboarded,
  required bool tourCompleted,
  required bool paywallCleared,
  required bool isPremium,
  bool? hardPaywallFlowEnabled,
  PostTourPaywallMode? paywallMode,
}) {
  if (!isAuthenticated || !hasOnboarded) return OnboardingStage.welcome;

  // Derive the effective post-tour mode: explicit mode wins; otherwise fall
  // back to the legacy boolean (true→hard, false→off). Default `off` keeps the
  // gate dark if neither is provided.
  final mode = paywallMode ??
      ((hardPaywallFlowEnabled ?? false)
          ? PostTourPaywallMode.hard
          : PostTourPaywallMode.off);

  // `off` → legacy behaviour, no gate at all.
  if (mode == PostTourPaywallMode.off) return OnboardingStage.app;

  // CLEARED latch → straight to app. Grandfathered (migration backfill / key
  // absent → defaults cleared), already-entered-then-cleared, or the
  // offerings-fail valve bypass. Checked BEFORE the tour so existing users
  // never flash the gate. This is the cleared latch ONLY — `paywallCleared` is
  // set false exclusively for a brand-new user by `enterOnboardingGate` and
  // defaults true otherwise, so it cleanly identifies "already past the gate".
  if (paywallCleared) return OnboardingStage.app;

  // New (uncleared) user who hasn't finished the forced tour completes it
  // FIRST — even when premium. A reverse-trial TREATMENT user is granted the
  // 3-day trial (→ isPremium) at onboarding-complete; checking premium before
  // this would skip the tour for treatment but not control, confounding the
  // experiment (device repro 2026-06-18). Existing/returning users are already
  // grandfathered by the cleared latch above, so they never reach this.
  if (!tourCompleted) return OnboardingStage.tour;

  // Tour done. Premium (paid OR an active reverse-trial window) makes the wall
  // moot → app.
  if (isPremium) return OnboardingStage.app;

  // Tour done, not cleared, not premium → the configured post-tour gate.
  switch (mode) {
    case PostTourPaywallMode.hard:
      return OnboardingStage.hardPaywall;
    case PostTourPaywallMode.soft:
      return OnboardingStage.softPaywall;
    case PostTourPaywallMode.off:
      return OnboardingStage.app;
  }
}
