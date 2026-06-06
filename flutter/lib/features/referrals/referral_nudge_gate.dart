/// Pure decision core for the home-screen referral nudge card.
///
/// Kept dependency-free (no Flutter / Riverpod / Supabase imports) so every
/// branch is unit-testable without RevenueCat or a network — same leaf-module
/// discipline as `onboarding_stage.dart`. The widget gathers the inputs (RC
/// entitlement, referral progress, prefs) and calls [resolveReferralNudge];
/// this function holds the timing + eligibility rules and nothing else.
///
/// ```
///                    resolveReferralNudge
///   premiumStartedAt == null ──────────────────────► hidden  (not RC premium)
///   hasEarnedGrant || progress >= 3 ───────────────► hidden  (already rewarded)
///   now < premiumStartedAt + graceDelay ───────────► hidden  (in grace window)
///   lastShownAt != null
///     && now < lastShownAt + reshowInterval
///     && progress <= lastShownProgress ────────────► hidden  (cooldown, no bump)
///   else ──────────────────────────────────────────► show
/// ```
library;

enum ReferralNudgeDecision { hidden, show }

/// Decide whether the referral nudge card should render this pass.
///
/// - [premiumStartedAt]: when the user's RevenueCat `premium` entitlement first
///   began (`originalPurchaseDate`), or null when there is no active RC premium.
///   Null here is the audience gate: trial OR paid only, never gift/referral.
/// - [now]: current instant (injected for deterministic tests).
/// - [progressTowardNext]: confirmed referees toward the next reward, 0..3.
/// - [hasEarnedGrant]: the user already earned at least one referral grant
///   (`MyReferralsState.grants.isNotEmpty`) — card disappears for good.
/// - [lastShownAt]: when the card was last shown/dismissed (prefs), or null.
/// - [lastShownProgress]: [progressTowardNext] at the last show (prefs); a
///   strictly higher current value bypasses the cooldown so "1 of 3 joined!"
///   surfaces promptly instead of waiting out [reshowInterval].
ReferralNudgeDecision resolveReferralNudge({
  required DateTime? premiumStartedAt,
  required DateTime now,
  required int progressTowardNext,
  required bool hasEarnedGrant,
  required DateTime? lastShownAt,
  required int lastShownProgress,
  Duration graceDelay = const Duration(days: 2),
  Duration reshowInterval = const Duration(days: 7),
}) {
  // 1. Audience: must be an active RC subscriber (trial or paid).
  if (premiumStartedAt == null) return ReferralNudgeDecision.hidden;

  // 2. Already rewarded — card is done for good.
  if (hasEarnedGrant || progressTowardNext >= 3) {
    return ReferralNudgeDecision.hidden;
  }

  // 3. Grace: don't ask in the first couple of days after they first paid.
  if (now.isBefore(premiumStartedAt.add(graceDelay))) {
    return ReferralNudgeDecision.hidden;
  }

  // 4. Cooldown — unless a friend joined since we last showed it.
  if (lastShownAt != null) {
    final cooldownOver = !now.isBefore(lastShownAt.add(reshowInterval));
    final progressClimbed = progressTowardNext > lastShownProgress;
    if (!cooldownOver && !progressClimbed) {
      return ReferralNudgeDecision.hidden;
    }
  }

  return ReferralNudgeDecision.show;
}
