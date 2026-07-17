// Pure analytics event-name + step-name constants. Dependency-free (no
// Riverpod/Flutter imports) so service-layer code can reference
// [AnalyticsEvents] WITHOUT transitively pulling in Riverpod. The
// AnalyticsService extension helpers live in analytics_events.dart,
// which re-exports this file (so existing widget imports keep working).

abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  // Funnel-entry events (2026-06-15 audit, Phase 4). `app_install` fires exactly
  // once ever (guarded by its own SharedPreferences flag, NOT the
  // onboarding_completed proxy) so install→onboarding_start is computable;
  // `onboarding_started` is the clean funnel entry (denominator).
  static const appInstall = 'app_install';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const firstCheckinSubmitted = 'first_checkin_submitted';
  // Auth sub-flow (Phase 4): fired when the email screen is submitted, so an
  // email-screen drop is distinguishable from a password-screen drop.
  static const signupEmailSubmitted = 'signup_email_submitted';
  // Super-property key (Phase 4): registered when premium state resolves so any
  // funnel can exclude already-converted users.
  static const String isPremium = 'is_premium';

  // Retention core-loop events (2026-06-01 instrumentation — see
  // docs/qa/runs/2026-06-01-full-regression/retention-audit/). check_in_completed
  // is THE recurring DAU event for the daily habit loop; session_started gives a
  // trustworthy warm-start signal (app_opened only fires on cold start).
  static const checkInCompleted = 'check_in_completed';
  static const sessionStarted = 'session_started';

  // Beat reveal flow (bite-sized reflection). `reflect_beat_advanced` fires on
  // each forward advance; `reflect_flow_skipped` fires when the user taps "Skip
  // to duʿa". Both segment where readers bail inside the flow — the redesign's
  // whole point is completion of the read, so it must be instrumented.
  //   reflect_beat_advanced props: surface, beat_index, beat_kind
  //   reflect_flow_skipped  props: surface, from_beat_index
  static const reflectBeatAdvanced = 'reflect_beat_advanced';
  static const reflectFlowSkipped = 'reflect_flow_skipped';
  static const propSurface = 'surface';
  static const propBeatIndex = 'beat_index';
  static const propBeatKind = 'beat_kind';
  static const propFromBeatIndex = 'from_beat_index';
  static const surfaceMuhasabah = 'muhasabah';
  static const surfaceReflect = 'reflect';
  // Re-engagement: fired when a user taps a push notification (client). Pairs
  // with a future server-side `notification_sent` to compute push CTR and
  // notification→session lift.
  static const notificationOpened = 'notification_opened';
  static const signupMethodSelected = 'signup_method_selected';
  static const signupCompleted = 'signup_completed';
  static const signupFailed = 'signup_failed';

  // Reason values for `signup_failed.error` — typed here so the password
  // screen's failure branches and the analytics test stay in lockstep. These
  // MUST stay a small bounded set: `signup_failed.error` feeds a Mixpanel
  // segmentation, so pushing raw gotrue messages (free-form, localized,
  // version-dependent) through it would explode the property cardinality and
  // break the funnel.
  static const signupFailedReasonSessionRace = 'session_race';
  static const signupFailedReasonEmailTaken = 'email_taken';
  static const signupFailedReasonInvalidCredentials = 'invalid_credentials';
  static const signupFailedReasonWeakPassword = 'weak_password';
  static const signupFailedReasonRateLimited = 'rate_limited';
  static const signupFailedReasonAuthError = 'auth_error';
  static const signupFailedReasonUnknown = 'unknown';

  /// Maps a gotrue [AuthException.code] to one of the bounded
  /// `signup_failed.error` reason constants above. Keeps Mixpanel cardinality
  /// low while preserving enough signal to tell apart the failure modes that
  /// matter (taken email vs weak password vs rate limit vs everything else).
  /// A null code (error thrown before any HTTP response) maps to
  /// [signupFailedReasonUnknown]; callers handle the no-error session-race
  /// miss separately with [signupFailedReasonSessionRace].
  static String signupFailedReasonForCode(String? code) {
    switch (code) {
      case 'user_already_exists':
      case 'email_exists':
        return signupFailedReasonEmailTaken;
      case 'invalid_credentials':
        return signupFailedReasonInvalidCredentials;
      case 'weak_password':
        return signupFailedReasonWeakPassword;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return signupFailedReasonRateLimited;
      case null:
        return signupFailedReasonUnknown;
      default:
        return signupFailedReasonAuthError;
    }
  }

  static const notificationPermissionResult = 'notification_permission_result';
  static const surveyAnswered = 'survey_answered';

  // Rating gate (page 25, inserted between YourJourney and Paywall — see
  // docs/superpowers/plans/2026-05-14-rating-gate.md).
  static const ratingGateShown = 'rating_gate_shown';
  static const ratingGatePromptTriggered = 'rating_gate_prompt_triggered';
  static const ratingGateContinueTapped = 'rating_gate_continue_tapped';
  static const ratingGateSkipped = 'rating_gate_skipped';

  static const paywallViewed = 'paywall_viewed';
  static const paywallPlanSelected = 'paywall_plan_selected';
  static const paywallCtaTapped = 'paywall_cta_tapped';
  static const paywallClosed = 'paywall_closed';

  // Paywall funnel instrumentation (2026-06-15 audit, Phase 2). The native
  // StoreKit sheet was a dark step between paywall_cta_tapped and trial_started;
  // these make the CTA→trial drop measurable. `placement` distinguishes the
  // three surfaces so they don't collapse into one funnel.
  static const String purchaseSheetPresented = 'purchase_sheet_presented';
  static const String purchaseSheetCancelled = 'purchase_sheet_cancelled';
  static const String purchaseSheetFailed = 'purchase_sheet_failed';
  static const String paywallSafetyValveUsed = 'paywall_safety_valve_used';
  // `placement` property — which paywall surface the event came from.
  static const String propPlacement = 'placement';
  static const String placementOnboarding = 'onboarding';
  static const String placementHardWall = 'hard_wall';
  static const String placementSoftInApp = 'soft_inapp';
  // Reverse-trial Phase A: the dismissible post-tour soft paywall surface
  // shown to the CONTROL arm (immediately after the tour) and as the generic
  // post-tour soft gate.
  static const String placementPostTourSoft = 'post_tour_soft';
  // Reverse-trial Phase A: the TREATMENT arm's Day-3 soft gate — the same
  // dismissible post-tour soft `PaywallScreen`, but surfaced after the 3-day
  // reverse trial has lapsed. Distinct placement so the two arms' soft-gate
  // views segment cleanly (paired with `trial_paywall_surfaced`).
  static const String placementPostTrialSoft = 'post_trial_soft';

  // ---- Reverse-trial 2-arm experiment (Lane C) -------------------------------
  // ONE funnel segmented by the `paywall_exp_arm` super-property (NOT separate
  // event streams). See the addendum in
  // docs/decisions/2026-06-14-onboarding-paywall-reverse-trial.md. These exact
  // strings are the Mixpanel dashboard contract — pinned by
  // analytics_reverse_trial_test.

  /// Fired once at arm assignment (onboarding complete, experiment on) — the
  /// shared denominator for both arms. Props: `{experiment, arm}`.
  static const String experimentAssigned = 'experiment_assigned';

  /// Treatment entry — fired on a successful `activate_trial(3)` RPC.
  /// Props: `{days, source:'reverse_trial', arm}`.
  static const String trialActivated = 'trial_activated';

  /// First client detection that the reverse trial has lapsed
  /// (`trial_premium_until < now()`). Fires once per expiry, from the app-resume
  /// re-check in `app_lifecycle_observer.dart`.
  ///
  /// Carries NO explicit `arm` property: by the time the trial expires (Day 3+,
  /// a later session than onboarding-complete) the assigned arm is not in scope
  /// on the resume path. Segmentation relies entirely on the durable
  /// [paywallExpArm] super-property (`paywall_exp_arm`), which is re-applied at
  /// boot and survives sign-out — every event, this one included, carries it.
  /// Only a treatment-arm user can ever have a `trial_premium_until`, so the
  /// super-property already cleanly attributes this event to the treatment arm.
  static const String trialExpired = 'trial_expired';

  /// Treatment's Day-3 soft gate view (distinct from onboarding / in-app
  /// placements). Props: `{placement:'post_tour_soft', arm, hard_gate:false}`.
  static const String trialPaywallSurfaced = 'trial_paywall_surfaced';

  /// Fired when a free / lapsed user is blocked at the daily cap — numerator
  /// for "cap-hit → upgrade". Promoted from a documented-but-never-emitted
  /// comment to a real constant + emission in `GatingService`. Props:
  /// `{feature, arm}`.
  static const String dailyCapHit = 'daily_cap_hit';

  /// Fired on X / dismiss of any soft paywall. Props: `{placement, arm}`.
  static const String softGateDismissed = 'soft_gate_dismissed';

  /// `experiment` property value identifying the reverse-trial test.
  static const String experimentReverseTrial = 'reverse_trial';

  /// `source` property value on `trial_activated`.
  static const String trialSourceReverseTrial = 'reverse_trial';

  /// `arm` event property — the per-event copy of the experiment arm (the
  /// super-property [paywallExpArm] carries it on EVERY event; this is the
  /// explicit prop on the experiment's own events).
  static const String propArm = 'arm';

  /// `days` property on `trial_activated`.
  static const String propDays = 'days';

  /// `hard_gate` property on paywall-surface events (always false for the
  /// reverse-trial soft gate).
  static const String propHardGate = 'hard_gate';

  /// `feature` property on `daily_cap_hit`.
  static const String propFeature = 'feature';

  /// Super-property AND people-property key for the experiment arm. Values:
  /// `control_no_trial` | `treatment_reverse_trial` | [armUnassigned]. The
  /// primary breakdown dimension that makes the two arms separable on every
  /// funnel step.
  static const String paywallExpArm = 'paywall_exp_arm';

  /// `paywall_exp_arm` value for users assigned before the experiment was
  /// active (no enum case — no code path assigns it; only the boot default).
  static const String armUnassigned = 'unassigned';

  /// Boot super-property: was the reverse-trial experiment active for this
  /// user (separates the pre-experiment cohort from the in-experiment one).
  static const String flagReverseTrialExp = 'flag_reverse_trial_exp';

  /// Fired the moment a subscription purchase / trial actually succeeds
  /// (entitlement active), NOT on CTA tap. This is the first true conversion
  /// signal in Mixpanel — nothing downstream of `paywall_cta_tapped` was
  /// measurable before. `plan` property = 'annual' | 'weekly'; `hard_gate` =
  /// whether it was the post-tour entry wall.
  static const trialStarted = 'trial_started';

  /// Fired when the offerings fetch fails at the hard entry wall and the
  /// safety valve is shown (so we can monitor how often the brick-prevention
  /// path triggers in production).
  static const paywallOfferingsLoadFailed = 'paywall_offerings_load_failed';
  static const paywallExitOfferShown = 'paywall_exit_offer_shown';
  static const paywallExitOfferAccepted = 'paywall_exit_offer_accepted';
  static const paywallFlowLoaderShown = 'paywall_flow_loader_shown';
  static const paywallFlowLoaderAdvanced = 'paywall_flow_loader_advanced';
  static const paywallFlowPlanShown = 'paywall_flow_plan_shown';
  static const paywallFlowPlanContinued = 'paywall_flow_plan_continued';
  static const paywallFlowJourneyShown = 'paywall_flow_journey_shown';
  static const paywallFlowJourneyContinued = 'paywall_flow_journey_continued';
  static const paywallFlowDropoff = 'paywall_flow_dropoff';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingAnswerCaptured = 'onboarding_answer_captured';

  /// Fired on app resume when the user was paused for 24h+ mid-onboarding.
  /// Properties: `page` (int index), `gone_hours` (int hours since pause).
  /// Powers the Phase A abandonment funnel for the trimmed onboarding flow.
  static const onboardingAbandonedAtPage = 'onboarding_abandoned_at_page';

  // Settings → Premium card. Persistent upgrade affordance added 2026-05-13
  // in response to the App Review rejection (reviewer could not find the
  // paywall outside onboarding). See
  // docs/superpowers/specs/2026-05-13-settings-premium-entry-design.md.
  static const settingsPremiumCtaTapped = 'settings_premium_cta_tapped';
  static const settingsPremiumManageTapped = 'settings_premium_manage_tapped';
  static const settingsPremiumBillingIssueTapped =
      'settings_premium_billing_issue_tapped';

  // Subscription cancellation feedback survey. Shown instantly after an in-app
  // Customer Center cancel, or reactively (next open / push) for OS-Settings
  // cancels. See docs/superpowers/specs/2026-05-31-cancellation-feedback-design.md.
  //   cancellation_feedback_shown → submitted | dismissed
  static const cancellationFeedbackShown = 'cancellation_feedback_shown';
  static const cancellationFeedbackSubmitted =
      'cancellation_feedback_submitted';
  static const cancellationFeedbackDismissed =
      'cancellation_feedback_dismissed';

  // AI bypass funnel (plan 2026-05-23, PR 3 of 5). Funnel:
  //   daily_cap_hit → ai_bypass_offered → ai_bypass_purchased
  // ai_bypass_rejected branches off the path between offered and purchased
  // when the server RPC declines (insufficient tokens / cap reached / race).
  static const aiBypassOffered = 'ai_bypass_offered';
  static const aiBypassPurchased = 'ai_bypass_purchased';
  static const aiBypassRejected = 'ai_bypass_rejected';

  // Reason values for `ai_bypass_rejected.reason` — typed here so the
  // gating-service RPC error mapping and the analytics test stay in
  // lockstep. `no_tokens` and `bypass_cap` are returned by the server
  // RPC `reserve_ai_bypass`; `network` is the client-side fallback when
  // the RPC returns null (transport / connectivity failure).
  static const aiBypassRejectedReasonNoTokens = 'no_tokens';
  static const aiBypassRejectedReasonBypassCap = 'bypass_cap';
  static const aiBypassRejectedReasonNetwork = 'network';

  // Day-1 freebie funnel (PR 4 of plan 2026-05-23, EXP-2). Mirrors the
  // ai_bypass_* triplet but with no token cost — the Day-1 path is
  // demonstration of the bypass mechanic, not monetization.
  // Funnel:
  //   daily_cap_hit (signup<24h, !consumed) → first_bypass_offered
  //     → first_bypass_claimed
  // first_bypass_rejected branches off when the server RPC declines
  // (already_consumed, window_expired, no_signup_at, network, etc.)
  static const firstBypassOffered = 'first_bypass_offered';
  static const firstBypassClaimed = 'first_bypass_claimed';
  static const firstBypassRejected = 'first_bypass_rejected';

  // Reason values for `first_bypass_rejected.reason` — server RPC returns
  // these strings on the failure path. `network` is the client-side
  // fallback for transport failure. Pinned by analytics_events_test.
  static const firstBypassRejectedReasonAlreadyConsumed = 'already_consumed';
  static const firstBypassRejectedReasonWindowExpired = 'window_expired';
  static const firstBypassRejectedReasonNoSignupAt = 'no_signup_at';
  static const firstBypassRejectedReasonInvalidFeature = 'invalid_feature';
  static const firstBypassRejectedReasonNetwork = 'network';

  // IAP→sub upsell banner (PR 5 of plan 2026-05-23, EXP-3). Surfaced on home
  // after a free user commits 6+ paid bypasses lifetime. Trigger string flows
  // through `paywall_viewed.trigger` so the dashboard can attribute trial
  // starts from the upsell path vs. other entry points (settings card,
  // daily_cap sheet, onboarding).
  static const iapToSubBannerShown = 'iap_to_sub_banner_shown';
  static const iapToSubBannerTapped = 'iap_to_sub_banner_tapped';
  static const iapToSubBannerDismissed = 'iap_to_sub_banner_dismissed';
  // P2-4 (2026-05-25): paired failure event for when the dismiss RPC fails.
  // Lets the funnel model retry behavior without silent skew. See
  // docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md.
  static const String iapToSubBannerDismissFailed =
      'iap_to_sub_banner_dismiss_failed';

  // Paywall trigger string — passed as the `trigger` property on
  // `paywall_viewed`. New entry point introduced by PR 5; coexists with
  // the implicit "onboarding" trigger (no property set today).
  static const paywallTriggerIapToSubUpsell = 'iap_to_sub_upsell';

  // Refer-to-Unlock (forward-instrumented per CEO review — there's no v1
  // baseline yet; these events power the post-launch cannibalization +
  // dwell + mutual-grant dashboards. See
  // docs/superpowers/plans/2026-05-14-refer-unlock.md Task 5 Step 3).
  static const referUnlockShown = 'refer_unlock_shown';
  static const referUnlockShareTapped = 'refer_unlock_share_tapped';

  /// Fired on every share in v1. Lets Phase 2 dashboards compare the install
  /// funnel before/after universal-link rollout.
  static const referUnlockShareNoUniversalLinks =
      'refer_unlock_share_no_universal_links';
  static const referUnlockStartTrialTapped = 'refer_unlock_start_trial_tapped';
  static const referUnlockBackToPaywall = 'refer_unlock_back_to_paywall';

  /// Fired client-side when apply_referral RPC succeeds (referee side).
  static const refereeSignedUpWithReferral = 'referee_signed_up_with_referral';

  /// Fired client-side when confirm_referral_if_pending returns granted=true
  /// (the referrer just crossed the 3-confirmed threshold).
  static const referrerGranted30dWindow = 'referrer_granted_30d_window';

  /// Fired client-side when apply_referral returns granted_referee_7d=true
  /// (mutual reward fired for the referee).
  static const refereeGranted7dWindow = 'referee_granted_7d_window';

  // In-onboarding referral code entry + Settings redeem (hybrid pattern).
  // Forward-instrumented for the v1 launch — pairs with refereeSignedUpWithReferral's
  // new `source` property ('deep_link' / 'onboarding_field' / 'settings_redeem') so
  // the post-launch funnel dashboards can split the 3 ingress paths. See
  // docs/superpowers/plans/2026-05-23-onboarding-referral-code-entry.md.

  /// Fired when the onboarding "Did a friend send you a gift?" disclosure
  /// is expanded by the user. Funnel start for the code-entry path.
  static const referralFieldRevealed = 'referral_field_revealed';

  /// Fired when a code (>= 8 chars) is persisted to pending_referral prefs
  /// via the onboarding field. Debounced 300ms (one event per settled code,
  /// not one per keystroke).
  static const referralFieldCodeEntered = 'referral_field_code_entered';

  /// Fired when a user clears a previously-entered code via the onboarding
  /// field.
  static const referralFieldCodeCleared = 'referral_field_code_cleared';

  /// Fired when the Settings → Redeem a referral code row is tapped (the
  /// sheet opens).
  static const referralSettingsRedeemOpened = 'referral_settings_redeem_opened';

  /// Fired when Redeem is tapped in the Settings sheet (whether successful
  /// or not — paired with refereeSignedUpWithReferral for the success case
  /// and refereeGranted7dWindow when a window was actually granted).
  static const referralSettingsRedeemSubmitted =
      'referral_settings_redeem_submitted';

  // My Referrals screen (Settings → Refer a friend). Forward-instrumented
  // per docs/superpowers/plans/2026-05-23-my-referrals-screen.md so the
  // post-launch dashboards can measure whether the permanent Settings entry
  // actually drives re-shares + opens at different progress states.
  /// Fired in initState after the screen loads its referrals state. Carries
  /// `confirmed_count` + `grants_count` properties so Mixpanel can slice
  /// "how many people open the screen with 0 vs 2 referrals".
  static const myReferralsShown = 'my_referrals_shown';

  /// Fired when the Share button on the My Referrals screen is tapped.
  static const myReferralsShareTapped = 'my_referrals_share_tapped';

  /// Fired when the user taps the code card to copy their referral code
  /// to the clipboard on the My Referrals screen.
  static const myReferralsCodeCopied = 'my_referrals_code_copied';

  // Home-screen post-conversion referral nudge card (shown to active RC
  // subscribers — trial or paid — until they earn their first referral grant).
  // Replaces the referral entry point lost when the onboarding paywall went
  // hard-gate (no X → the ReferUnlockScreen exit reframe is unreachable).
  // Forward-instrumented so the shown → share funnel and dismiss rate are
  // measurable from launch.
  /// Fired once per session when the nudge card resolves to its visible state.
  static const homeReferralNudgeShown = 'home_referral_nudge_shown';

  /// Fired when the card's "Send to friends" CTA is tapped (opens share sheet).
  static const homeReferralNudgeShareTapped =
      'home_referral_nudge_share_tapped';

  /// Fired when the user dismisses the card via its "×" (starts the cooldown).
  static const homeReferralNudgeDismissed = 'home_referral_nudge_dismissed';

  // ── Home-screen widget install nudge ──
  // Adoption is the gating factor for widget retention (a widget nobody adds
  // retains nobody), so the shown → how-to → dismiss funnel is instrumented.
  /// Fired once per session when the widget-install nudge resolves to visible.
  static const widgetInstallNudgeShown = 'widget_install_nudge_shown';

  /// Fired when the user taps "Show me how" (expands the add-widget steps).
  static const widgetInstallNudgeHowtoTapped = 'widget_install_nudge_howto_tapped';

  /// Fired when the user dismisses the widget-install nudge (hidden for good).
  static const widgetInstallNudgeDismissed = 'widget_install_nudge_dismissed';

  /// Fired when a home-screen/Lock-Screen widget tap deep-links into the app —
  /// the core "are users engaging the widgets" metric. Props: `target`
  /// (muhasabah|build_dua), `launch` (cold|warm). Correlate with
  /// `check_in_completed` for widget→reflection conversion.
  static const widgetOpened = 'widget_opened';

  /// Fired once per app session with the current widget-install snapshot —
  /// the adoption metric. Props: `installed` (bool), `count`, `families`
  /// (e.g. systemSmall/systemMedium/accessoryRectangular). Also set as user
  /// properties so DAU can be segmented by "has widget".
  static const widgetInstalledState = 'widget_installed_state';

  // ── Duʿā Times (awqāt al-ijābah) home card ──
  // Time-aware "best time to make duʿā" surface (spec
  // docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md
  // §11). The card is render-gated like the gift card, so `impression` fires
  // once per session when it resolves to a visible active/between state. Every
  // CTA (card body + pill) points at Build-a-Duʿā — this feature's north star.
  /// Fired once per session when the card resolves to a visible state.
  /// Props: `active_window` (window type of the active window, or null),
  /// `next_window` (window type of the upcoming window, or null),
  /// `urgency` (comfortable|closing|last_call|all_day|upcoming).
  static const String duaTimesCardImpression = 'dua_times_card_impression';

  /// Fired when the card (or its CTA pill) is tapped → navigates to Build-a-Duʿā.
  /// Props: `active_window`, `urgency`.
  static const String duaTimesCardCtaTap = 'dua_times_card_cta_tap';

  /// Fired when the lazy location permission prompt is presented (the card
  /// would show a precise window and permission was not yet granted).
  static const String duaTimesLocationPrompt = 'dua_times_location_prompt';

  /// Fired when the user grants location permission from the card affordance.
  static const String duaTimesLocationGranted = 'dua_times_location_granted';

  /// Fired when the user denies (or has permanently denied) location from the
  /// card affordance — the card degrades to calendar + soft-night windows.
  static const String duaTimesLocationDenied = 'dua_times_location_denied';

  // Property keys for the dua-times events.
  static const String propActiveWindow = 'active_window';
  static const String propNextWindow = 'next_window';
  static const String propUrgency = 'urgency';

  // Source values for the `source` property attached to
  // refereeSignedUpWithReferral and refereeGranted7dWindow events. Enables
  // funnel-splitting across the 3 referral ingress paths.
  static const referralSourceDeepLink = 'deep_link';
  static const referralSourceOnboardingField = 'onboarding_field';
  static const referralSourceSettingsRedeem = 'settings_redeem';

  // Ramadan / Eid Sakina Gift. Brand-additive 7-day premium window granted
  // once per Islamic occasion per user. See
  // docs/superpowers/plans/2026-05-14-ramadan-gift.md.
  static const ramadanGiftShown = 'ramadan_gift_shown';
  static const ramadanGiftClaimed = 'ramadan_gift_claimed';
  static const ramadanGiftWindowExpired = 'ramadan_gift_window_expired';

  // Engagement & economy analytics (retention audit 2026-06-01, backlog
  // #6/#7/#10/#11). Closes the three dark core-loop surfaces: the monetized
  // Store, the collection/gacha progression loop, and the streak/quest/XP
  // economy. See docs/superpowers/plans/2026-06-01-engagement-economy-analytics.md.
  // These exact strings are the Mixpanel dashboard contract — renames must be
  // a deliberate analytics-team coordination (pinned by analytics_events_test).

  // Store — real-money consumable packs (tokens / scrolls). Emitted directly
  // from StoreScreen (a ConsumerStatefulWidget). `kind` ∈ {tokens, scrolls};
  // `pack_id` is the StoreKit product identifier; `amount` is the pack size.
  static const String storeViewed = 'store_viewed';
  static const String packSelected = 'pack_selected';
  static const String storePurchaseSucceeded = 'store_purchase_succeeded';
  static const String storePurchaseFailed = 'store_purchase_failed';
  static const String storePurchaseCancelled = 'store_purchase_cancelled';

  // Reason values for `store_purchase_failed.reason`.
  static const String storePurchaseFailedReasonUnavailable = 'unavailable';
  static const String storePurchaseFailedReasonPlatform = 'platform';
  static const String storePurchaseFailedReasonUnknown = 'unknown';

  // Collection / cards / gacha. Emitted from the `engageCard` chokepoint via
  // CardCollectionAnalytics.onAnalyticsEvent (no Riverpod in that service).
  // card_revealed = first discovery; tier_up = an owned card upgrading;
  // mutually exclusive per engage so Mixpanel counts stay clean. tier values
  // are tierToEnum strings (bronze/silver/gold/emerald — gold is the current
  // ceiling, engageCard never produces emerald).
  static const String cardRevealed = 'card_revealed';
  static const String tierUp = 'tier_up';
  static const String collectionCompleted = 'collection_completed';

  // Duas + Journal (2026-06-15 — instrument the two guided-tour features the
  // 6/19 reassessment can't otherwise evaluate; see the onboarding-paywall ADR).
  // dua_built = a Build-a-Dua call that returned a real dua (non-empty
  // breakdown; off-topic/rejected builds do NOT fire). journal_entry_created =
  // anything saved into the Journal, with `entry_type` in {built_dua, saved_dua,
  // reflection} and `auto` true only for the always-auto-saved built dua, so
  // deliberate saves (hearted related duas, reflections) are separable.
  // Emitted via DuasNotifier/ReflectNotifier.onAnalyticsEvent (no Riverpod in
  // those notifiers — wired in main.dart like DailyLoopNotifier).
  static const String duaBuilt = 'dua_built';
  static const String journalEntryCreated = 'journal_entry_created';

  // Property keys + values for journal_entry_created.
  static const String propEntryType = 'entry_type';
  static const String propAuto = 'auto';
  static const String entryTypeBuiltDua = 'built_dua';
  static const String entryTypeSavedDua = 'saved_dua';
  static const String entryTypeReflection = 'reflection';

  // Economy: streaks, quests, XP, levels. Streak events come from the
  // streak_service chokepoint via StreakAnalytics.onAnalyticsEvent; XP/level/
  // quest events are emitted directly from AppShell (has Riverpod ref).
  static const String streakExtended = 'streak_extended';
  static const String streakMilestone = 'streak_milestone';
  static const String streakFreezeConsumed = 'streak_freeze_consumed';
  static const String questCompleted = 'quest_completed';
  static const String xpAwarded = 'xp_awarded';
  static const String levelUp = 'level_up';

  // `quest_type` values on quest_completed — distinguishes the standard
  // daily/weekly quest pool from the one-time First Steps beginner quests.
  static const String questTypeStandard = 'standard';
  static const String questTypeBeginner = 'beginner';

  // Guided tour (post-onboarding teach moments). See
  // docs/superpowers/plans/2026-05-25-onboarding-trim-guided-tour.md.
  static const String tourStarted = 'tour_started';
  static const String tourStepViewed = 'tour_step_viewed';
  static const String tourStepAdvanced = 'tour_step_advanced';
  static const String tourCompleted = 'tour_completed';
  static const String tourSkipped = 'tour_skipped';
  static const String tourReplayTapped = 'tour_replay_tapped';
  static const String tourAnchorTimeout = 'tour_anchor_timeout';
  static const String tourStartSkipped = 'tour_start_skipped';
  // Slim-vs-full A/B (2026-06-15). Set as a USER property at tour start so EVERY
  // event (retention, conversion) is breakable down by the variant a user saw,
  // and added to `tour_started` props. Values: 'slim' | 'full'.
  static const String tourVariant = 'tour_variant';
  static const String propVariant = 'variant';
  // Tour funnel completeness (2026-06-15 audit, Phase 3). `tour_offered` closes
  // the onboarding_completed→tour_started gap; `tour_backgrounded` separates
  // silent mid-tour abandonment from explicit skip/timeout. `tour_start_skipped`
  // gains a reason for EVERY non-start path (only 'disabled' fired before).
  static const String tourOffered = 'tour_offered';
  static const String tourBackgrounded = 'tour_backgrounded';
  static const String tourSkipReasonDisabled = 'disabled';
  static const String tourSkipReasonAlreadyCheckedIn = 'already_checked_in';
  static const String tourSkipReasonColdOffline = 'cold_offline';
  static const String tourSkipReasonNoAuth = 'no_auth';
  static const String tourSkipReasonAlreadySeen = 'already_seen';

  // LEGACY 27-page flow step names (0-26, rating gate at 25).
  // Active only when `onboarding_trim_enabled=false`.
  // Updated 2026-05-05 by paywall flow redesign — the GeneratingScreen +
  // PersonalizedPlanScreen pair moved from pages 16-17 into the paywall flow
  // at pages 22-23; YourJourneyScreen new at page 24; paywall at page 25.
  // Updated 2026-05-14 by rating-gate insertion — gate added at index 25
  // (when enabled), paywall shifts to 26. See docs/superpowers/plans/
  // 2026-05-14-rating-gate.md.
  static const stepNames = <int, String>{
    0: 'first_checkin',
    1: 'name_input',
    2: 'age_range',
    3: 'intention',
    4: 'prayer_frequency',
    5: 'quran_connection',
    6: 'familiarity',
    7: 'dua_topics',
    8: 'common_emotions',
    9: 'aspirations',
    10: 'daily_commitment',
    11: 'attribution',
    12: 'struggle_support_interstitial',
    13: 'reminder_time',
    14: 'notifications',
    15: 'commitment_pact',
    16: 'value_prop',
    17: 'social_proof',
    18: 'save_progress',
    19: 'signup_email',
    20: 'signup_password',
    21: 'encouragement',
    22: 'paywall_flow_loader',
    23: 'paywall_flow_plan',
    24: 'paywall_flow_journey',
    25: 'rating_gate',
    26: 'paywall',
  };

  // TRIMMED 20-page flow step names (0-19, rating gate at 18, paywall at 19).
  // Active by default (`onboarding_trim_enabled=true`). Must stay in sync with
  // _trimmedChildren() in onboarding_screen.dart and the trimmed page-index
  // doc in onboarding_provider.dart. See docs/superpowers/plans/
  // 2026-05-25-onboarding-trim-guided-tour.md.
  static const trimmedStepNames = <int, String>{
    0: 'first_checkin',
    1: 'name_input',
    2: 'age_range',
    3: 'intention',
    4: 'prayer_frequency',
    5: 'familiarity',
    6: 'dua_topics',
    7: 'daily_commitment',
    8: 'attribution',
    9: 'reminder_time',
    10: 'notifications',
    11: 'commitment_pact',
    12: 'social_proof',
    13: 'save_progress',
    14: 'signup_email',
    15: 'signup_password',
    16: 'paywall_flow_loader',
    17: 'paywall_flow_plan',
    18: 'rating_gate',
    19: 'paywall',
  };

  /// Resolves the step-name map for the active onboarding flow. Centralized so
  /// callers in onboarding_screen.dart pick the correct labels at runtime.
  static Map<int, String> stepNamesFor({required bool trimmed}) =>
      trimmed ? trimmedStepNames : stepNames;
}
