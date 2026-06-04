// Pure analytics event-name + step-name constants. Dependency-free (no
// Riverpod/Flutter imports) so service-layer code can reference
// [AnalyticsEvents] WITHOUT transitively pulling in Riverpod. The
// AnalyticsService extension helpers live in analytics_events.dart,
// which re-exports this file (so existing widget imports keep working).

abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';
  static const onboardingStepViewed = 'onboarding_step_viewed';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const firstCheckinSubmitted = 'first_checkin_submitted';

  // Retention core-loop events (2026-06-01 instrumentation — see
  // docs/qa/runs/2026-06-01-full-regression/retention-audit/). check_in_completed
  // is THE recurring DAU event for the daily habit loop; session_started gives a
  // trustworthy warm-start signal (app_opened only fires on cold start).
  static const checkInCompleted = 'check_in_completed';
  static const sessionStarted = 'session_started';
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
  static const cancellationFeedbackSubmitted = 'cancellation_feedback_submitted';
  static const cancellationFeedbackDismissed = 'cancellation_feedback_dismissed';

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
  static const referralSettingsRedeemSubmitted = 'referral_settings_redeem_submitted';

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

  // LEGACY 27-page flow step names (0-26 when Env.ratingGateEnabled is true;
  // 0-25 when false). Active only when `onboarding_trim_enabled=false`.
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

  // TRIMMED 20-page flow step names (0-19 when Env.ratingGateEnabled is true;
  // 0-18 when false — index 18 rating_gate is skipped, paywall shifts to 18).
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
