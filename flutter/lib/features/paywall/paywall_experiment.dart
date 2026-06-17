import '../tour/models/onboarding_tour_step.dart' show tourBucket;

/// The two arms of the reverse-trial 2-arm experiment (see
/// `docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md`, addendum
/// 2026-06-16). The single variable tested is the trial; paywall *hardness* is
/// held constant at `soft` in both arms.
///
/// - [controlNoTrial]: onboarding → slim tour → immediate soft paywall → free
///   tier (1/day). No trial.
/// - [treatmentReverseTrial]: onboarding → slim tour → 3-day reverse trial
///   (full premium) → Day-3 soft paywall → free tier.
///
/// The `.name` values (`controlNoTrial` / `treatmentReverseTrial`) are NOT the
/// Mixpanel wire strings — use [PaywallArm.analyticsValue] for the
/// `paywall_exp_arm` super/people property contract.
enum PaywallArm {
  controlNoTrial,
  treatmentReverseTrial;

  /// Mixpanel `paywall_exp_arm` value. Snake-case to match the existing
  /// `flag_*` / event-name conventions and the ADR's analytics table
  /// (`control_no_trial` | `treatment_reverse_trial`). The third state,
  /// `unassigned` (pre-experiment users), is a bare string registered by the
  /// boot path — it has no enum case because no code path *assigns* it.
  String get analyticsValue {
    switch (this) {
      case PaywallArm.controlNoTrial:
        return 'control_no_trial';
      case PaywallArm.treatmentReverseTrial:
        return 'treatment_reverse_trial';
    }
  }
}

/// Stable, deterministic 50/50 arm assignment for [userId].
///
/// Hashes **`userId + ':paywall'`** (NOT the raw [userId]) through the same
/// FNV-1a [tourBucket] used by the tour A/B. The `:paywall` salt is load-
/// bearing: without it the paywall bucket would be byte-identical to
/// `assignTourVariant`'s bucket, so the two experiments could never run
/// concurrently without confounding (eng-review finding #2 / regression G2).
///
/// Lower half of the salted bucket space → [PaywallArm.controlNoTrial], upper
/// half → [PaywallArm.treatmentReverseTrial]. Pure: same id → same arm every
/// launch, no persistence needed. Callers only invoke this when
/// `reverse_trial_experiment_enabled` is on; pre-flag users stay `unassigned`.
PaywallArm assignPaywallArm(String userId) =>
    tourBucket('$userId:paywall') < 50
        ? PaywallArm.controlNoTrial
        : PaywallArm.treatmentReverseTrial;
