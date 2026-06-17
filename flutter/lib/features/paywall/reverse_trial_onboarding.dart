import 'package:shared_preferences/shared_preferences.dart';

import '../../services/analytics_events.dart';
import '../../services/analytics_service.dart';
import '../../services/purchase_service.dart';
import '../../services/supabase_sync_service.dart';
import 'paywall_experiment.dart';

/// One-shot flag base key guarding `experiment_assigned`. Set once a user has
/// been assigned an arm so a reinstall / re-onboard does not double-count the
/// experiment denominator (eng-review #3 / regression G1).
const String paywallExperimentAssignedBaseKey = 'paywall_experiment_assigned';

/// Resolves and applies the reverse-trial paywall experiment at
/// onboarding-complete (eng-review #3: flag-gated + idempotent).
///
/// - When [experimentEnabled] is false: a no-op. Pre-flag users stay
///   `unassigned` (no arm property, no events) so the pre-experiment cohort is
///   cleanly separable.
/// - When enabled: buckets [userId] into an arm via [assignPaywallArm], records
///   `paywall_exp_arm` (super + people) and fires `experiment_assigned` ONCE
///   (deduped on [paywallExperimentAssignedBaseKey]). The treatment arm
///   additionally calls the `activate_trial(3)` SECURITY DEFINER RPC, refreshes
///   the trial cache, and fires `trial_activated`. The control arm gets no
///   trial (it falls to the immediate soft paywall after the tour).
///
/// Trial length is hardcoded 3 days (the duration A/B is deferred — see the ADR
/// cut note on `reverse_trial_duration_days`). Best-effort throughout: a failed
/// RPC / prefs read must never block onboarding completion.
Future<void> resolveAndApplyPaywallExperiment({
  required bool experimentEnabled,
  required String userId,
  required AnalyticsService analytics,
}) async {
  if (!experimentEnabled) return;

  final arm = assignPaywallArm(userId);
  // Record the arm as super + people property on EVERY pass (cheap, idempotent)
  // so a process that lost the Mixpanel registration still re-applies it.
  analytics.recordPaywallArm(arm);

  final prefs = await SharedPreferences.getInstance();
  final assignedKey =
      supabaseSyncService.scopedKey(paywallExperimentAssignedBaseKey);
  final alreadyAssigned = prefs.getBool(assignedKey) ?? false;
  if (alreadyAssigned) return;
  await prefs.setBool(assignedKey, true);

  analytics.track(AnalyticsEvents.experimentAssigned, properties: {
    'experiment': AnalyticsEvents.experimentReverseTrial,
    AnalyticsEvents.propArm: arm.analyticsValue,
  });

  if (arm != PaywallArm.treatmentReverseTrial) return;

  // Treatment: activate the 3-day reverse trial server-side. SECURITY DEFINER +
  // idempotent (greatest()), so even if this races a retry the user can't
  // extend the window. Hardcoded 3 days.
  try {
    await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'activate_trial',
      const {'p_days': 3},
    );
    // Surface the new trial window to PurchaseService.isPremium() immediately.
    await PurchaseService().refreshTrialPremiumCache();
    analytics.track(AnalyticsEvents.trialActivated, properties: {
      AnalyticsEvents.propDays: 3,
      'source': AnalyticsEvents.trialSourceReverseTrial,
      AnalyticsEvents.propArm: arm.analyticsValue,
    });
  } catch (_) {
    // Trial activation is best-effort — a failed RPC leaves the user on the
    // free tier (degrades to control-like behavior), never blocks onboarding.
  }
}
