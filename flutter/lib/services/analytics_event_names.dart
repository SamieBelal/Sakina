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
  // The onboarding story-deck reveal (One Ship W2). It reuses the beat-flow
  // events above — `surface` is what separates it from the two AI surfaces in
  // every beat funnel. `reveal_deck_completed` fires on Ameen,
  // `reveal_deck_abandoned` when the deck is left unfinished. Constants only in
  // W2-A4; the emitters land with the reveal screen.
  static const surfaceOnboardingReveal = 'onboarding_reveal';
  // The Day-1 queue unseal's deck reveal (One Ship W3 Wave 3). It rides the
  // SAME beat spine — `reflect_beat_advanced`, `reveal_deck_completed`,
  // `reveal_deck_abandoned` — and is separated only by this surface value.
  // Deliberately NOT `onboarding_reveal`: reusing it would fold D1 completions
  // into the onboarding deck-completion rate, which is a named T0+2wk health
  // metric, and the two must stay separable (plan §4, OQ-3 decided).
  static const surfaceDailyUnseal = 'daily_unseal';
  static const revealDeckCompleted = 'reveal_deck_completed';
  static const revealDeckAbandoned = 'reveal_deck_abandoned';
  // The 7-Name queue seed failing at the end of onboarding (One Ship W2-C2).
  // Degrade-don't-abort means completion still finishes, so this event is the
  // ONLY signal that a shipped user has an acquisition promise with nothing
  // behind it — their daily unseal opens on an empty queue.
  //   props: id_count, error_class (the class, never the raw driver message)
  static const nameQueueSeedFailed = 'name_queue_seed_failed';

  /// A seed that failed during onboarding was retried successfully at app
  /// open. Props: `id_count`, `seeded` (false = rows already existed, i.e. an
  /// earlier attempt had landed and only its response was lost).
  ///
  /// Read against [nameQueueSeedFailed]: the two should converge. A gap that
  /// does not close is users still walking around without their D1 promise.
  static const nameQueueSeedRepaired = 'name_queue_seed_repaired';
  // "Where did you find us?" (One Ship W2-D3). The screen buys the user
  // nothing, so this event is its ENTIRE reason to exist: organic reels carry
  // no attributed click, and the tap is the only source signal there is. A
  // decline ("Rather not say") emits nothing — the screen-view event is what
  // separates a decline from an unseen screen.
  //   props: [propSource] — one of the screen's stable snake_case keys
  static const reelSourceSelected = 'reel_source_selected';
  // The onboarding widget carousel (One Ship W2 Wave G). iOS has no API to add
  // a widget, so the CTA can only instruct — which makes `..._cta_tapped` an
  // INTENT signal, never an install. Nothing here should ever be read as
  // "widgets added"; the real installs show up later as `widget_opened`.
  //   props on all three: [propWidgetKind] — 'lantern' | 'daily_name' |
  //   'dua_times', the stable keys in onboarding_widgets.dart
  static const onboardingWidgetPreviewed = 'onboarding_widget_previewed';
  static const onboardingWidgetCtaTapped = 'onboarding_widget_cta_tapped';
  static const onboardingWidgetSkipped = 'onboarding_widget_skipped';

  /// How the onboarding location ask resolved, fired only on the Duʿā Times
  /// card's CTA path. Carries [propOutcome]:
  /// `granted|denied|openedSettings|servicesOff`.
  ///
  /// This is the leading indicator for the whole precise-times funnel: the
  /// system dialog is a one-shot resource, so the granted rate HERE bounds
  /// everything downstream. Pair it with `dua_times_precise_state` to see how
  /// many of the grants later lapse.
  static const onboardingLocationResult = 'onboarding_location_result';
  static const String propWidgetKind = 'widget_kind';
  // First-visit hints (Wave F3 — what replaced the deleted tour). Without
  // these we cannot tell whether the Reflect hint moves the 13.0%-vs-36.8%
  // payer/free usage gap, which is the entire reason that hint exists.
  //   props: [propHintId] — 'reflect' | 'companion' | 'noor'
  static const firstVisitHintShown = 'first_visit_hint_shown';
  static const String propHintId = 'hint_id';
  // The lantern's first lighting, at the reveal's opening beat. The single
  // moment Wave G exists for, so a drop here is worth seeing on its own rather
  // than inferred from the surrounding step events.
  static const lanternKindled = 'lantern_kindled';
  // An onboarding profile UPDATE that failed (One Ship W2). The persist is
  // best-effort by design — it must never block completion — which means a
  // silently-dropped answer is otherwise invisible outside a debug console.
  //   props: stage ('w1' | 'quiz'), error_class (the class, never the raw
  //   driver message, which would explode the property cardinality)
  static const onboardingPersistFailed = 'onboarding_persist_failed';
  static const propStage = 'stage';
  static const propErrorClass = 'error_class';
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
  /// Fired on ✕ / dismiss of ANY paywall placement. Props: `{placement}` —
  /// `arm` arrives free via the `paywall_exp_arm` super property.
  ///
  /// The only cross-placement dismissal event: [softGateDismissed] fires for
  /// the post-tour soft gate alone, so this is the sole signal for onboarding,
  /// hard-wall, soft-inapp and post-trial-soft closes. `placement` was added
  /// 2026-08-01; events before that release carry none, so segment with an
  /// explicit "is set" filter rather than reading the empty bucket as a
  /// placement.
  static const paywallClosed = 'paywall_closed';

  // W5 Wave C — the 3-page gate. `paywall_viewed` fires once per mount; this
  // fires once per PAGE so the ceremony's internal drop-off is measurable.
  // Segment by [propPageId], never by page index: the ineligible-user variant
  // has no `trial_timeline` page, so index 1 means different things to
  // different users while the id never does.
  static const String paywallPageViewed = 'paywall_page_viewed';
  static const String propPageId = 'page_id';
  static const String paywallPageValueDepth = 'value_depth';
  static const String paywallPageTrialTimeline = 'trial_timeline';
  static const String paywallPagePlanSelect = 'plan_select';
  static const String paywallPageCondensed = 'condensed';

  /// The user dismissed the gate and was shown the one-time "always free"
  /// card — the free tier's entry moment, and the denominator for every later
  /// free→paid conversion read.
  static const String freeTierEntered = 'free_tier_entered';

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

  // ── Streak retention (spec §8) ──────────────────────────────────────────
  // Client-emitted. The server-side streak-notification events
  // (`streak_notif_sent` / `_opened` / `streak_saver_converted`) are emitted as
  // string literals inside send-scheduled-notifications (Deno) — see T5.
  /// User expanded the "month of light" calendar from the Home summary.
  static const String chainCalendarExpanded = 'chain_calendar_expanded';

  /// The freeze-burn reunion card was shown on Home. Property: `streak`.
  static const String freezeBurnShown = 'freeze_burn_ack_shown';

  /// The hero next-milestone bar was shown (once per session). Properties:
  /// `next_tier`, `days_remaining`.
  static const String milestoneSliverShown = 'milestone_sliver_shown';

  /// `streak` property on streak-retention events.
  static const String propStreak = 'streak';

  /// `next_tier` / `days_remaining` properties on `milestone_sliver_shown`.
  static const String propNextTier = 'next_tier';
  static const String propDaysRemaining = 'days_remaining';

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
  ///
  /// **Emitted ONLY when a free trial was actually granted** (2026-08-01).
  /// Before that it fired on every successful activation, including users
  /// Apple had already spent their one-per-subscription-group intro offer on
  /// — they see "Subscribe", are charged immediately, and were nonetheless
  /// counted as trial starts. Pair with [subscriptionStartedNoTrial]; the
  /// union of the two is "every client-observed subscription activation".
  static const trialStarted = 'trial_started';

  /// A subscription that activated with **no trial** — the user was
  /// ineligible for the introductory offer (Apple grants one per Apple ID per
  /// subscription group, ever) and paid from the first moment.
  ///
  /// Split out from [trialStarted] rather than folded into it as a property,
  /// because the event NAME is what asserts a trial began: a `trial: false`
  /// property still leaves every existing `trial_started` funnel counting
  /// people who never had one. Carries the same `plan` / `origin` /
  /// `hard_gate` / `placement` properties so the two can be unioned wherever
  /// "all conversions" is the question.
  ///
  /// **New event — populates only from the release that ships it.** Do not
  /// compare its volume against pre-release windows.
  static const subscriptionStartedNoTrial = 'subscription_started_no_trial';

  /// Fired when the offerings fetch fails at the hard entry wall and the
  /// safety valve is shown (so we can monitor how often the brick-prevention
  /// path triggers in production).
  static const paywallOfferingsLoadFailed = 'paywall_offerings_load_failed';
  // ---- Exit offer (the ✕-interception weekly downsell) ---------------------
  // The mechanic has shipped for months with `shown` and `accepted` wired but
  // nothing to answer "does it earn anything". These three plus [propOrigin]
  // close that: shown → accepted → purchase started → purchase completed.
  //
  // All three carry [propPlacement], so a soft-gate exit offer is
  // distinguishable from an in-app one.
  static const paywallExitOfferShown = 'paywall_exit_offer_shown';
  static const paywallExitOfferAccepted = 'paywall_exit_offer_accepted';

  /// Fired on EVERY route out of the sheet that is not an accept: the "No
  /// thanks" button, a scrim tap, and the back gesture.
  ///
  /// Without it, `shown` and `accepted` give a ratio with no visibility into
  /// the decline path — you cannot tell "nobody saw it" from "everybody saw it
  /// and refused". A decline route that missed one exit would quietly
  /// understate declines and flatter the mechanic.
  ///
  /// Props: `{placement, route}` — see [propDismissRoute].
  static const String paywallExitOfferDeclined = 'paywall_exit_offer_declined';

  /// How the user left a dismissible sheet: [dismissRouteButton] (an explicit
  /// decline tap) or [dismissRouteDismissed] (scrim tap / back gesture, which
  /// the framework reports identically).
  static const String propDismissRoute = 'route';
  static const String dismissRouteButton = 'button';
  static const String dismissRouteDismissed = 'dismissed';

  /// What started the purchase attempt this event belongs to —
  /// [originPaywall] (the CTA on the gate itself) or [originExitOffer].
  ///
  /// A PROPERTY on the existing `paywall_cta_tapped` / `purchase_sheet_*` /
  /// `trial_started` chain, deliberately NOT a parallel set of events: forking
  /// a live funnel is what the plan forbids, and "accepted" only means the CTA
  /// was tapped — if the StoreKit sheet is then abandoned, an exit offer that
  /// earns nothing would still look like it works. Segmenting the existing
  /// chain on this property is what makes the money visible.
  static const String propOrigin = 'origin';
  static const String originPaywall = 'paywall';
  static const String originExitOffer = 'exit_offer';
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

  // Home → Premium strip. Second in-app upgrade entry point (alongside the
  // Settings → Premium card), shown to free users above the muḥāsabah CTA.
  static const homePremiumStripTapped = 'home_premium_strip_tapped';

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

  /// Fired when the user denies location from the card affordance — the card
  /// degrades to calendar + soft-night windows.
  ///
  /// **Narrowed 2026-08.** This used to also fire for the `deniedForever`
  /// Settings round-trip, which was a lie: the user denied nothing there and
  /// many granted seconds later in Settings. That case is now
  /// [duaTimesLocationSettingsOpened]. Comparisons of the granted:denied ratio
  /// across that date are not valid.
  static const String duaTimesLocationDenied = 'dua_times_location_denied';

  /// Fired when the tap routed the user to an OS Settings page instead of
  /// resolving in-flow — permission was `deniedForever`, or the app grant is
  /// held but device Location Services are off. Props: `precise_state`.
  static const String duaTimesLocationSettingsOpened =
      'dua_times_location_settings_opened';

  /// The deduped state-of-the-world event for precise times: fired when the
  /// state CHANGES, not per rebuild (same rationale as [duaScheduleBuilt] —
  /// `rebuild()` runs on every Control-Center bounce).
  ///
  /// THE event that verifies the 2026-08 re-nag fix: `never_asked` following a
  /// prompt must go to zero, and `permission_lapsed` sizes the iOS "Allow Once"
  /// cohort this fix exists to rescue. Props: `precise_state`, `permission`.
  static const String duaTimesPreciseState = 'dua_times_precise_state';

  /// The paused notice actually rendered. Without this we cannot tell "shown
  /// and ignored" from "silently spent on a frame nobody saw" — the ambiguity
  /// that made the 2026-08-03 device QA inconclusive. Props: `precise_state`.
  static const String duaTimesPreciseNoticeShown =
      'dua_times_precise_notice_shown';

  /// The user dealt with that notice. `action` is `opened` (tapped through to
  /// the steps) or `dismissed` (the ✕) — the ratio is the whole readout on
  /// whether the notice is a help or a nuisance.
  static const String duaTimesPreciseNoticeAction =
      'dua_times_precise_notice_action';

  // ── Duʿā Times Live Activity (Lock Screen + Dynamic Island) ──
  // Phase 2 of Duʿā Times: the same active-window countdown promoted to the
  // Lock Screen / Dynamic Island (spec plan
  // docs/superpowers/plans/2026-07-16-dua-live-activities.md §10 O5). v1 is a
  // local, foreground-started ticking countdown (no push). The north star is
  // identical to the card/home widget: every glance + tap drives Build-a-Duʿā.
  // Emitted from DuaWindowNotifier via its static onAnalyticsEvent hook (no
  // Riverpod in the service layer), mirroring the widget's onAnalyticsEvent
  // pattern. The tap event is emitted from the router redirect (single owner).
  /// Fired when a Live Activity is started for a newly-active window.
  /// Props: `active_window` (window type), `urgency`.
  static const String duaLiveActivityStarted = 'dua_live_activity_started';

  /// Fired when the Live Activity (or a Dynamic Island element) is tapped and
  /// deep-links into Build-a-Duʿā. Distinguished from a home-widget tap by the
  /// `source: live_activity` param on the deep link (plan correction #5).
  /// Props: `active_window`, `urgency`.
  static const String duaLiveActivityTapped = 'dua_live_activity_tapped';

  /// Fired when the Live Activity is ended. Props: `active_window`, `reason`
  /// (window_closed|window_changed). Sign-out teardown is intentionally NOT
  /// instrumented (the user is leaving; low signal), so there is no
  /// `signed_out` reason — the wipe still happens, it's just not measured.
  static const String duaLiveActivityEnded = 'dua_live_activity_ended';

  // ── Duʿā-windows engine + notification-sync health (prod observability) ──
  // The card / notification-open / notification-sent(server) / live-activity
  // events cover CONSUMPTION; these cover GENERATION so the whole machine is
  // observable end-to-end in prod (see the review 2026-07-18):
  //   • dua_schedule_built    — the engine is alive + the eligibility denominator
  //   • dua_notif_synced       — the denominator for server `notification_sent`
  // NOTE: the home-screen WIDGET extension itself cannot emit (no network in the
  // WidgetKit process) — its only client-observable signal is the tap
  // (`widget_opened{source: dua_times_widget}`, see below).
  /// Fired when a SUCCESSFUL schedule build changes the schedule's SHAPE
  /// (deduped — rebuild runs on every `resumed`, so an event = a distinct
  /// eligibility state, NOT an app-open count). The engine-liveness +
  /// eligibility signal. Props: `has_active`, `active_window` (type|null),
  /// `urgency`, `has_next`, `location_present`. NOTE: `location_present` is a
  /// *capability* flag (location was resolvable, so precise windows COULD be
  /// computed) — it is not proof any precise window is active or was pushed;
  /// pair it with `dua_notif_synced.count > 0` for that. Query rates PER USER
  /// (unique users), not per event.
  static const String duaScheduleBuilt = 'dua_schedule_built';

  /// Fired when a schedule build THROWS (engine / repository failure) — the
  /// engine-health alarm. No props (the error is logged, not shipped).
  static const String duaScheduleBuildFailed = 'dua_schedule_build_failed';

  /// Fired when the precise notification instants are synced to the server
  /// (`dua_precise_notifications`) — the client-side COUNTERPART to the
  /// server-side `notification_sent{type: dua_window}`. Only fires for opted-in
  /// users when a sync actually runs (past the 6h throttle); `skipped` no-ops
  /// are suppressed. Props: `count` (rows synced — 0 for non-`synced`
  /// outcomes), `outcome` (synced|cleared|failed), `sync_version` (on `synced`
  /// only — the PER-SYNC join key: the server `notification_sent{dua_window}`
  /// carries the same version, so a specific sync can be traced to the exact
  /// pushes it produced). CAVEAT: this does NOT measure OPT-IN RATE — the
  /// opted-out path emits nothing (by design, to avoid per-rebuild noise);
  /// derive opt-in from the notification-preference events.
  static const String duaNotifSynced = 'dua_notif_synced';

  // Property keys for the dua-times events.
  static const String propActiveWindow = 'active_window';
  static const String propNextWindow = 'next_window';
  static const String propUrgency = 'urgency';
  static const String propReason = 'reason';
  static const String propHasActive = 'has_active';
  static const String propHasNext = 'has_next';
  static const String propLocationPresent = 'location_present';

  /// `working|never_asked|permission_lapsed|services_off|unresolved` — keep in
  /// sync with `PreciseTimesState.wireName`.
  static const String propPreciseState = 'precise_state';

  /// What the user did with a surface that offers more than one exit — today
  /// only [duaTimesPreciseNoticeAction] (`opened` vs `dismissed`).
  static const String propAction = 'action';

  /// `granted|services_off|denied|denied_forever|undetermined` — what the OS
  /// said at the moment the state was resolved.
  static const String propPermission = 'permission';
  static const String propCount = 'count';
  static const String propOutcome = 'outcome';

  /// The `sync_version` the precise rows were written under — the per-sync join
  /// key between `dua_notif_synced` (client) and `notification_sent{dua_window}`
  /// (server, whose rows carry the same version). Present only on a `synced`
  /// outcome. Lets a specific sync be traced to the exact pushes it produced.
  static const String propSyncVersion = 'sync_version';

  /// `source` on `widget_opened` — disambiguates which surface drove the tap so
  /// the duʿā-times widget is separable from the daily-Name widget (both can
  /// deep-link to Build-a-Duʿā). The duʿā-times widget tags its link
  /// `source=dua_times_widget`; taps without the param default to `home_widget`.
  ///
  /// Also carries the answer on [reelSourceSelected], where the value space is
  /// that screen's own keys rather than the widget ones below.
  static const String propSource = 'source';
  static const String widgetSourceHomeWidget = 'home_widget';
  static const String widgetSourceDuaTimes = 'dua_times_widget';

  /// Reason values for [duaLiveActivityEnded].
  static const String liveActivityEndWindowClosed = 'window_closed';
  static const String liveActivityEndWindowChanged = 'window_changed';

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
  // are tierToEnum strings (bronze/silver/gold/emerald). Emerald is the premium
  // ceiling: free users cap at gold; premium reaches emerald via the tier
  // ceiling and the backfill_emerald_cards retro-bump.
  static const String cardRevealed = 'card_revealed';
  static const String tierUp = 'tier_up';
  static const String collectionCompleted = 'collection_completed';

  // Tiered card-reveal overlay (Bronze→Emerald gacha hero moment). Emitted from
  // CardRevealOverlay via its `onEvent` callback (no Riverpod in the pushed
  // route widget — the muḥāsabah caller wires the dispatch). `card_reveal_shown`
  // fires when the sequence starts; `card_reveal_completed` fires when the user
  // continues. Props: `tier` (bronze/silver/gold/emerald), `dwell_ms` (elapsed
  // since shown), `auto` (true only for the dev/preview auto-loop).
  static const String cardRevealShown = 'card_reveal_shown';
  static const String cardRevealCompleted = 'card_reveal_completed';

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

  // ─────────────────────────────────────────────────────────────────────────
  // Journaling (Wave H, 2026-08-02). See
  // docs/superpowers/plans/2026-08-02-journaling-and-name-mastery-plan.md.
  // ─────────────────────────────────────────────────────────────────────────

  /// `source` on [journalEntryCreated] — WHICH WRITER of `user_reflections`
  /// produced the row, mirroring the column of the same name that Wave B added.
  ///
  /// **The event was extended, not forked** (plan Wave H, design §12.1): the
  /// nightly muḥāsabah is a journal entry like any other, and a sibling event
  /// would have split every historical journal chart in two at T0.
  ///
  /// Present **only when `entry_type = reflection`** — the two duʿā entry types
  /// are rows in `user_built_duas`, which has no `source` column and no
  /// muḥāsabah concept, and inventing a third value for them would make
  /// `source` mean "surface" on some events and "table column" on others. Break
  /// down by `entry_type` first; `source` splits the reflection slice.
  ///
  /// The key itself is [propSource], reused (its value space is per-event
  /// already — cf. the widget vs. reel-source values above).
  static const String journalSourceReflect = 'reflect';
  static const String journalSourceMuhasabah = 'muhasabah';

  /// Once per completed night, at `completeDeeper()` — the denominator for
  /// every other Wave C event and the only thing that answers "did the night
  /// leave an artifact at all".
  ///
  /// Props: [propHasEntry] (a row was written / already existed for the day —
  /// false means an offline night, a refused write, or a legacy blob restore),
  /// [propHasTimeMachine] + [propOffsetDays] (C3's anchor: 30 / 90 / 365, or
  /// absent), [propThreadLength] and [propHasAzm] (what the night already
  /// carried when it completed — non-zero only on a re-completion).
  static const String muhasabahCompletionShown = 'muhasabah_completion_shown';

  /// One durable append (C1). Fires only on a COMMITTED write, so a blank line,
  /// a rolled-over day with no row, an exhausted twenty-append budget and a
  /// server refusal are all silent — the event counts what the journal kept.
  ///
  /// Props: [propSurface] ([surfaceMuhasabah] = the completion screen,
  /// [surfaceJournal] = D3's compose sheet — the one number that says whether
  /// the Journal's compose control earns its place), [propThreadLength] (the
  /// count AFTER the append, so "appended once" is separable from "kept going"
  /// without a session aggregate).
  static const String muhasabahThreadAppended = 'muhasabah_thread_appended';

  /// The night's forward resolve was written or changed (C4).
  ///
  /// Aggregated by outcome rather than emitted per keystroke-save: an ʿazm is
  /// editable until the day rolls over, so a save that changes nothing is
  /// silent, and [propFirstTime] separates the night's first resolve from a
  /// later edit of it. [propCleared] marks an ʿazm emptied back out.
  ///
  /// [propCharCountBucket] and NEVER the line itself — same rule, and the same
  /// helper, as the daily question's answer.
  static const String muhasabahAzmSet = 'muhasabah_azm_set';

  /// The Journal's one primary control (D3), tapped. [propAction] is the
  /// meaning it had at the moment of the tap
  /// ([composeActionStartTonight] | [composeActionAddToTonight] |
  /// [composeActionFreeWrite]) and [propEntryPoint] is which of its two
  /// renderings was used ([composeEntryFab] | [composeEntryEmptyState]) — the
  /// empty-state copy is aimed at a user with nothing in the archive yet, and
  /// its conversion is a different question from the FAB's.
  static const String journalComposeTapped = 'journal_compose_tapped';

  /// An archived entry was opened for re-reading (D2/D4/E1) — the whole point
  /// of Wave D, and unmeasurable before it.
  ///
  /// One event with three segments rather than three events: [propOrigin]
  /// ([originJournalFeed] | [originJournalCalendar] | [originOnThisNight]),
  /// [propFormat] ([entryFormatStory] = the tap-through beats, [entryFormatDetail]
  /// = the page), and [propSource] (`muhasabah` | `reflect`, the same value
  /// space as [journalEntryCreated]) so "people re-read their nights" is
  /// separable from "people re-read their Reflect saves".
  static const String journalEntryOpened = 'journal_entry_opened';

  /// The Month of Light calendar was opened as the Journal's browse control
  /// (D4). The denominator for `journal_entry_opened{origin: journal_calendar}`
  /// — without it, a calendar nobody converts from is indistinguishable from a
  /// calendar nobody opens.
  static const String journalBrowseOpened = 'journal_browse_opened';

  /// **Session-aggregated, once per Journal visit**, and deliberately not three
  /// per-card `shown` events: all three Wave E surfaces are passive, they are
  /// resolved in the same build, and the question is always "what did the
  /// archive open with", never "which card rendered first".
  ///
  /// Props: [propOnThisNight], [propWeeklyRecap], [propAnsweredPrompt] (booleans
  /// — every resolver returns null far more often than not, so the all-false
  /// row is the common case and is the honest denominator), plus
  /// [propOffsetDays] when "On This Night" resolved.
  ///
  /// **The answered-duʿā boolean records that the APP ASKED, never what the user
  /// answered.** Marking a duʿā answered emits nothing, by an explicit Wave E
  /// decision pinned by a test — see `duas_provider.setBuiltDuaAnswered`.
  static const String journalResurfacingShown = 'journal_resurfacing_shown';

  /// [surfaceMuhasabah]'s sibling for the Journal — which of the two surfaces
  /// an append came from.
  static const String surfaceJournal = 'journal';

  static const String propHasEntry = 'has_entry';
  static const String propHasTimeMachine = 'has_time_machine';

  /// How many nights back a resurfaced entry came from — 30, 90 or 365, never a
  /// fuzzy window (see `selectTimeMachineAnchor`). On
  /// [muhasabahCompletionShown] and [journalResurfacingShown].
  static const String propOffsetDays = 'offset_days';
  static const String propThreadLength = 'thread_length';
  static const String propHasAzm = 'has_azm';
  static const String propFirstTime = 'first_time';
  static const String propCleared = 'cleared';
  // `propAction` is declared once, above, next to the duʿā-times notice that
  // introduced it. Both branches added their own copy of the same `'action'`
  // key, so the 2026-08-05 merge produced two declarations of one wire key —
  // which Dart rejects, and which is how a later rename silently splits a
  // funnel in half. Collapsed to the documented one.
  static const String propEntryPoint = 'entry_point';
  static const String propFormat = 'format';
  static const String propOnThisNight = 'on_this_night';
  static const String propWeeklyRecap = 'weekly_recap';
  static const String propAnsweredPrompt = 'answered_prompt';

  static const String composeActionStartTonight = 'start_tonight';
  static const String composeActionAddToTonight = 'add_to_tonight';
  static const String composeActionFreeWrite = 'free_write';
  static const String composeEntryFab = 'fab';
  static const String composeEntryEmptyState = 'empty_state';

  static const String entryFormatStory = 'story';
  static const String entryFormatDetail = 'detail';

  /// [propOrigin] values for [journalEntryOpened]. Namespaced `journal_*` where
  /// the surface is ambiguous, because `origin` already carries the paywall's
  /// values on a different event.
  static const String originJournalFeed = 'journal_feed';
  static const String originJournalCalendar = 'journal_calendar';
  static const String originOnThisNight = 'on_this_night';
  // Gift-a-Dua funnel (2026-08-02). The gift affordance shipped with NO
  // instrumentation at all, so its discoverability — the thing we actually
  // doubt — was unmeasurable. Three steps, so a drop can be located:
  //
  //   gift_cta_shown     the Ameen screen rendered a gift affordance (once per
  //                      result, NOT per rebuild — a scroll must not inflate it)
  //   gift_preview_opened the user tapped through to the gift preview
  //   gift_sent          the share sheet was invoked with the rendered pages
  //
  // shown → opened is the DISCOVERABILITY rate (does anyone find it?);
  // opened → sent is the INTENT rate (having seen it, do they send it?).
  // Conflating them would hide which half is broken.
  //
  // gift_cta_shown fires ONCE per result and carries NO placement: both the
  // corner icon and the labeled CTA render together, so emitting one per
  // affordance would double the impression count and halve every rate below it.
  // gift_preview_opened and gift_sent DO carry [propPlacement], which is what
  // actually answers "did the labeled CTA beat the corner icon" — the question
  // the labeled CTA was added to settle.
  //
  // gift_sent carries [propPageCount] since a multi-page gift can be truncated
  // by a share target that only accepts one image, and [propShareStatus]
  // because `shareXFiles` completes when the sheet CLOSES however it closed:
  // a dismissed sheet is not a sent gift and is never reported, while
  // `unavailable` (platform can't tell) IS reported but stays separable from a
  // confirmed `success` so the send rate can be read with the right caveat.
  static const String giftCtaShown = 'gift_cta_shown';
  static const String giftPreviewOpened = 'gift_preview_opened';
  static const String giftSent = 'gift_sent';

  // Values for [propPlacement] on the gift funnel.
  static const String giftPlacementCornerIcon = 'ameen_corner_icon';
  static const String giftPlacementPrimaryCta = 'ameen_labeled_cta';

  static const String propPageCount = 'page_count';

  /// `success` | `unavailable` — the platform's own verdict on the share.
  static const String propShareStatus = 'share_status';

  // Economy: streaks, quests, XP, levels. Streak events come from the
  // streak_service chokepoint via StreakAnalytics.onAnalyticsEvent; XP/level/
  // quest events are emitted directly from AppShell (has Riverpod ref).
  static const String streakExtended = 'streak_extended';
  static const String streakMilestone = 'streak_milestone';
  static const String streakFreezeConsumed = 'streak_freeze_consumed';
  // Streak-defense (Phase 2). Lapse → outcome funnel + the paid-rescue funnel.
  static const String streakLapsed = 'streak_lapsed';
  // streak_repaired {method: 'effort'|'freeze'|'paid'|'premium_free',
  //                  pre_lapse_streak, tokens_spent}
  static const String streakRepaired = 'streak_repaired';
  static const String streakExpired = 'streak_expired';
  static const String streakRepairOfferShown = 'streak_repair_offer_shown';
  static const String streakRepairOfferDismissed = 'streak_repair_offer_dismissed';
  static const String streakExcusedUsed = 'streak_excused_used';
  static const String endowedStart = 'endowed_start';
  // streak_repaired `method` values.
  static const String repairMethodEffort = 'effort';
  static const String repairMethodFreeze = 'freeze';
  static const String repairMethodPaid = 'paid';
  static const String repairMethodPremiumFree = 'premium_free';
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

  // REEL 13-page flow step names (0-12, paywall at 12). Active by default once
  // `reel_first_onboarding_enabled` ships (One Ship W2-E1); the two maps above
  // serve the kill-switch flows.
  //
  // The reel-only screens carry a `reel_` prefix; the six screens the reel flow
  // REUSES keep their existing names on purpose, so a funnel keyed on
  // `step_name` joins the same step across all three flows and the
  // `flag_onboarding_trim` / flow super properties do the segmenting. Copy on
  // these screens may change; these ids may not.
  static const reelStepNames = <int, String>{
    0: 'reel_hook',
    1: 'reel_reveal',
    // Wave H — the intake block. `step_id` strings are the funnel's join key
    // across page-order changes, so the stable ones are preserved verbatim and
    // only the indices move.
    2: 'reel_carrying_duration',
    3: 'reel_heaviest',
    4: 'reel_told_anyone',
    5: 'reel_names_known',
    6: 'reel_help_with',
    7: 'reel_daily_time',
    8: 'reel_note',
    // The payoff, then every ask behind it.
    9: 'reel_queue_plan',
    10: 'rating_gate',
    11: 'notifications',
    12: 'reel_widget_offer',
    13: 'reel_source',
    14: 'name_input',
    15: 'save_progress',
    16: 'signup_email',
    17: 'signup_password',
    18: 'paywall',
  };

  /// Resolves the step-name map for the active onboarding flow. Centralized so
  /// callers in onboarding_screen.dart pick the correct labels at runtime.
  ///
  /// [reel] wins over [trimmed] — the reel flow is its own page order, not a
  /// trim of either legacy one.
  static Map<int, String> stepNamesFor({
    required bool trimmed,
    bool reel = false,
  }) =>
      reel ? reelStepNames : (trimmed ? trimmedStepNames : stepNames);

  // ── Lantern Cosmetics (Noor economy + skins/backdrops) ──────────────────
  // Spec §7. Emitted from cosmetics_service.dart via the static
  // CosmeticsAnalytics.onAnalyticsEvent hook (no Riverpod in the service).
  // These exact strings are the Mixpanel dashboard contract — renames must be
  // a deliberate analytics-team coordination (pinned by
  // cosmetics_analytics_names_test).

  /// Noor was minted for the user. Props: `amount`, `reason`
  /// (daily|milestone:N). Fired only on a NON-idempotent-replay grant (the
  /// server returns the granted amount; a deduped replay — or an ineligible
  /// caller — returns 0 and emits nothing). `quest` is reserved but not
  /// currently emitted: the quest earn path is disabled because quest
  /// completion has no server-authoritative record to verify (see
  /// 20260726200600_lock_down_award_noor.sql).
  static const String noorEarned = 'noor_earned';

  /// A cosmetic was unlocked by spending Noor. Props: `item_type`, `item_id`,
  /// `via` ('noor').
  static const String cosmeticUnlocked = 'cosmetic_unlocked';

  /// A cosmetic was equipped. Props: `item_type`, `item_id`.
  static const String cosmeticEquipped = 'cosmetic_equipped';

  /// An à-la-carte skin was purchased with real money and granted
  /// server-side. Props: `item_id`, `product_id`.
  static const String cosmeticIapPurchased = 'cosmetic_iap_purchased';

  /// A milestone-gated skin was auto-unlocked after a confirmed
  /// claim_streak_milestone. Props: `item_id`, `milestone_day`.
  static const String milestoneSkinUnlocked = 'milestone_skin_unlocked';

  /// An unlock/equip RPC was rejected (insufficient noor, unowned, inactive,
  /// premium-exclusive). Props: `item_type`, `item_id`, `reason`.
  static const String cosmeticUnlockRejected = 'cosmetic_unlock_rejected';

  // Property keys + values for the cosmetics events.
  static const String propItemType = 'item_type';
  static const String propItemId = 'item_id';
  static const String propAmount = 'amount';
  static const String propVia = 'via';
  static const String propProductId = 'product_id';
  static const String propMilestoneDay = 'milestone_day';
  static const String cosmeticViaNoor = 'noor';
  static const String cosmeticViaIap = 'iap';

  /// The Companion stage was opened (Home medallion tap → /companion). No props.
  static const String companionScreenOpened = 'companion_screen_opened';

  /// The wardrobe was opened. Props: `tab` ('lantern_skin' | 'backdrop').
  static const String wardrobeOpened = 'wardrobe_opened';

  /// The wardrobe's axis was switched. Props: `tab` ('lantern_skin' |
  /// 'backdrop'). Distinct from [wardrobeOpened] on purpose: emitting the open
  /// event on every tab tap inflated the open count and understated the
  /// open → preview → unlock funnel.
  static const String wardrobeTabChanged = 'wardrobe_tab_changed';

  /// A wardrobe tile was tapped to preview it on the stage. Props: `item_type`,
  /// `item_id`.
  static const String cosmeticPreviewed = 'cosmetic_previewed';

  /// Which wardrobe axis/tab. Value is an item_type ('lantern_skin'|'backdrop').
  static const String propTab = 'tab';

  // ── The daily question (One Ship W4 Wave 7) ────────────────────────────────
  // Plan §9, spec §2/§9. W4 ships alongside the paywall wave, so the T0+6wk
  // keep read CANNOT separate their contributions — this within-wave funnel is
  // the only way to find out whether the question itself is carrying its
  // weight. Emitted through `DailyQuestionAnalytics.onAnalyticsEvent` (the
  // surface) and `DailyLoopNotifier.onAnalyticsEvent` (the provider); see
  // daily_question_analytics.dart for the wire values and the buckets.
  //
  // **The verbatim answer NEVER leaves the device.** Length is reported as a
  // bucket and the meaning as a chip category; no event on this funnel — or
  // anywhere else — carries the text the user typed. Pinned by
  // `daily_question_analytics_test.dart`.
  //
  // `check_in_completed` is NOT forked for this wave: it gains
  // [propProblemCategory] and [propInputMode] as properties and its `path`
  // stays `'discover'`, because it is the recurring DAU event and the D1/D7
  // retention spine.

  /// The daily question was put to the user. Props: [propEntrySource].
  static const String dailyQuestionShown = 'daily_question_shown';

  /// The user answered it. Props: [propProblemCategory], [propInputMode],
  /// [propCharCountBucket], [propAttempt].
  static const String dailyQuestionAnswered = 'daily_question_answered';

  /// "Not right now" — the explicit defer. Props: [propDwellMsBucket]. A skip
  /// says the *placement* was wrong for that moment; the whole loop stays
  /// collectible from the home CTA for the rest of the day.
  ///
  /// **Never merge this with [dailyQuestionAbandoned].** The difference between
  /// "people want this later" and "people don't want this" is the entire
  /// readout for the defer design (plan §9).
  static const String dailyQuestionSkipped = 'daily_question_skipped';

  /// Backgrounded or navigated away without deciding. Props:
  /// [propDwellMsBucket]. An abandon says the *question* was wrong.
  static const String dailyQuestionAbandoned = 'daily_question_abandoned';

  /// The daily reward was claimed. Props: [propTrigger], [propLadderDay].
  /// Exists so the W4 re-timing of the claim (open → answer-submit) is visible
  /// in the data rather than inferred from the absence of something else.
  static const String dailyRewardClaimed = 'daily_reward_claimed';

  /// The off-topic classifier rejected an answer and the user was asked to
  /// rephrase. Props: [propAttempt].
  ///
  /// **This exists because the classifier has never fired on real daily text.**
  /// Before W4 the daily loop sent the revealed card's own blurb to the
  /// reflection engine, so `classifyOffTopic` was structurally unreachable on
  /// this path; it has only ever run against Reflect, which is opt-in and
  /// self-selected. W4 points it at every daily user's sentence about grief,
  /// money and prayer at once, with no measured false-positive rate. Counted
  /// against [dailyQuestionAnswered] this gives that rate — and if it is high,
  /// it is a large number of people being asked to re-type something that was
  /// hard to type once, which would otherwise surface only as an unexplained
  /// retention dip.
  static const String dailyQuestionOffTopic = 'daily_question_off_topic';

  /// How the user arrived at the question: `day_open` | `widget` | `home_cta`.
  /// The widget path must stay separable from day-open.
  static const String propEntrySource = 'entry_source';

  /// The chip taxonomy's reading of the answer — a `ProblemChip.problemCategory`
  /// or `unmatched`. Deliberately the CHIP taxonomy and not the 30-question
  /// option bank, so the daily loop stays comparable with
  /// `acquisition_promise.problem_category`.
  static const String propProblemCategory = 'problem_category';

  /// `typed` | `chip` — whether the answer was written or tapped.
  static const String propInputMode = 'input_mode';

  /// Bucketed answer length. NEVER the answer.
  static const String propCharCountBucket = 'char_count_bucket';

  /// Bucketed time on the question before the user skipped or abandoned.
  static const String propDwellMsBucket = 'dwell_ms_bucket';

  /// Which try at answering this is — `1` for the first, `2`+ after an
  /// off-topic re-ask. On [dailyQuestionAnswered] and [dailyQuestionOffTopic].
  ///
  /// **A dimension, never a stage.** The funnel is shown → answered →
  /// completed, and minting a separate re-ask event would fork it at step two,
  /// leaving every existing segment silently under-counting the people who had
  /// to try twice. Segment on this instead.
  static const String propAttempt = 'attempt';

  /// What caused a [dailyRewardClaimed]. [triggerAnswerSubmit] today.
  static const String propTrigger = 'trigger';

  /// The 7-day escalating ladder position a [dailyRewardClaimed] landed on
  /// (1-7). The claim was re-timed to answer-submit specifically to protect
  /// this ladder from a single missed day resetting it, so this is the field
  /// that says whether the re-timing worked: users climbing to 6 and 7 means
  /// yes, everyone stuck at 1 means no.
  static const String propLadderDay = 'day';

  /// The only [propTrigger] value W4 ships. Named rather than inlined so that
  /// if a later wave adds a second claim trigger, the two are obviously the
  /// same vocabulary.
  static const String triggerAnswerSubmit = 'answer_submit';

  // ─────────────────────────────────────────────────────────────────────────
  // W6 Wave A — SUPER properties.
  //
  // These are not event properties. They are registered once and stamped onto
  // every subsequent event AT SEND TIME, which has one consequence that governs
  // all of them: **Mixpanel never backfills.** A property registered one line
  // too late is absent on every event before it, permanently, and an absent
  // property renders as a large "unknown" bucket that reads like organic
  // traffic rather than like a bug.
  //
  // The whole One Ship is meant to be ONE funnel segmented by these, never
  // separate event streams per flow. See docs/analytics/funnel-flags-and-querying.md.
  // ─────────────────────────────────────────────────────────────────────────

  /// Which onboarding experience this user actually ran (`reel_v1` | the legacy
  /// kill-switch value). Registered at onboarding entry for new users and at
  /// boot from `AppSession` for returning ones.
  ///
  /// **Never union this with the frozen `paywall_exp_arm`.** They are different
  /// questions and the reverse-trial close-out froze that one as history.
  static const String propOnboardingFlow = 'onboarding_flow';

  /// Which promise the user arrived on — `problem` or `sign` (`HookContract`).
  ///
  /// **The primary reel-of-origin dimension (D3).** Behavioural, taken at
  /// arrival, near-total coverage: every reel user picks a chip or types, and
  /// typed input resolves to `problem`. Its limit is real and belongs in the
  /// readout doc rather than in a surprise at the read: it has TWO values, so
  /// it separates the two shipped reels but cannot separate two future reels
  /// that make the same promise.
  static const String propContract = 'contract';

  /// The 7-chip category the user ARRIVED with.
  ///
  /// **Deliberately not `problem_category` (D4).** That name is already a live
  /// EVENT property meaning *today's answer* (`check_in_completed`,
  /// `daily_question_answered`). Registering a super property under the same
  /// name would put two meanings behind one key — event-level properties win
  /// where both exist, so some events would report today's answer and others
  /// the acquisition one, under the same name, with nothing to signal the
  /// switch. Every chart built on it would be right some of the time.
  ///
  /// Same vocabulary as [propProblemCategory] on purpose: "arrived with X,
  /// answers Y today" is then exactly one breakdown.
  static const String propAcquisitionProblemCategory =
      'acquisition_problem_category';

  /// Which reel the user came from — a `reel_id` from a `sakina://reel/<id>`
  /// deep link, the self-reported source, or `unknown`.
  ///
  /// Always read alongside [propReelHookSource]. A value that silently mixes a
  /// confirmed deep link with a half-remembered tap looks authoritative and is
  /// not.
  static const String propReelHook = 'reel_hook';

  /// How [propReelHook] was learned: [reelHookSourceDeepLink] |
  /// [reelHookSourceSelfReport] | [reelHookSourceUnknown].
  ///
  /// Two properties instead of one encoded string (`self_report:tiktok`)
  /// because a breakdown should not require parsing, and because the two axes
  /// answer different questions: *which reel* vs *how sure are we*.
  static const String propReelHookSource = 'reel_hook_source';

  /// Confirmed: the user arrived through a `sakina://reel/<id>` deep link.
  static const String reelHookSourceDeepLink = 'deep_link';

  /// The user told us, on the source screen at index 13 — after the payoff and
  /// every ask, and declinable. Weaker than [reelHookSourceDeepLink].
  static const String reelHookSourceSelfReport = 'self_report';

  /// We do not know. **Registered at onboarding ENTRY, not when learned** — if
  /// it were only set once known it would be *absent* rather than `unknown` on
  /// every event before the source screen, which is most of the funnel. Absent
  /// and `unknown` break down differently and only one of them is honest.
  static const String reelHookSourceUnknown = 'unknown';

  /// Which free tier governs this user (`reel_v1` | `legacy`).
  ///
  /// **Cannot be registered at boot.** It is a user-scoped value written only
  /// by `GatingService.hydrateFromProfile`, so on a fresh install it does not
  /// exist until the first `sync_all_user_data`. Registered from
  /// `GatingService.onProfileHydrated` instead — which also means it is
  /// expected to be absent on the earliest events of a brand-new user's first
  /// session, by construction rather than by accident.
  static const String propFreeTierCohort = 'free_tier_cohort';

  // ─────────────────────────────────────────────────────────────────────────
  // W6 Wave C — the gate's meter.
  //
  // The gate could say when it BLOCKED someone (`daily_cap_hit`) and never when
  // it let them through, so the cap-hit rate had no denominator. And the sheets
  // that carry the block were emitting nothing at all for the `reel_v1` cohort:
  // `warmup_exhausted_sheet.dart` had zero analytics, and `daily_cap_sheet.dart`
  // had exactly two events, both on the token-bypass slot that W5 REMOVES for
  // that cohort. The single most important monetization surface in the ship was
  // dark for the tier it was built for.
  // ─────────────────────────────────────────────────────────────────────────

  /// A gated AI use was SPENT successfully — the denominator `daily_cap_hit`
  /// has always been the numerator of. Carries [propFeature],
  /// [propAllowance] and [propRemaining].
  ///
  /// Never fires for premium: `markUsed` short-circuits on the premium check
  /// before the cohort read, so a payer spending an unlimited use is not a
  /// "taste".
  static const String aiTasteConsumed = 'ai_taste_consumed';

  /// Which budget [aiTasteConsumed] came out of: [allowanceWarmup] |
  /// [allowanceWeeklyPool] | [allowanceDaily].
  static const String propAllowance = 'allowance';

  /// How many uses are left in that budget AFTER this spend.
  static const String propRemaining = 'remaining';

  /// The lifetime per-feature warmup (`reel_v1`).
  static const String allowanceWarmup = 'warmup';

  /// The shared Reflect + Build-a-Duʿā weekly pool (`reel_v1`).
  static const String allowanceWeeklyPool = 'weekly_pool';

  /// The legacy per-day counter.
  static const String allowanceDaily = 'daily';

  // `daily_cap_hit` gains [propReason] (already defined above) rather than
  // spawning a second exhaustion event (D5). Minting `ai_allowance_exhausted`
  // for the new tier would fork the cap-hit→upgrade funnel exactly across the
  // T0 boundary the pre/post comparison depends on. These are the `GateReason`
  // wire values it carries.

  /// Legacy per-day cap.
  static const String gateReasonDailyCap = 'daily_cap';

  /// `reel_v1` shared weekly pool spent.
  static const String gateReasonWeeklyPool = 'weekly_pool';

  /// `reel_v1` re-roll past the lifetime warmup — a second Name today is
  /// premium. The day-open reveal is unaffected; it consults no gate.
  static const String gateReasonRerollPremium = 'reroll_premium';

  /// A lapsed trialer with no remaining budget.
  static const String gateReasonHadTrialNoBudget = 'had_trial_no_budget';

  /// A cap or warmup sheet was SHOWN. Carries [propFeature], [propReason] and
  /// [propSheet].
  ///
  /// Without this there is no impression to divide the upgrade tap by, so
  /// "did hitting the cap drive upgrades?" is unanswerable — which is the
  /// question the whole free-tier change exists to move.
  static const String capSheetShown = 'cap_sheet_shown';

  /// A cap or warmup sheet was dismissed WITHOUT taking the upgrade. Carries
  /// [propSheet] and [propMethod].
  ///
  /// **Must fire exactly once across all four dismissal routes** (button,
  /// scrim tap, swipe-down, Android back) — see [propMethod] for why "four
  /// routes" nonetheless yields two reportable values. Copy
  /// `LapsedTrialSheet.show`'s
  /// `fireDismissOnce` reconciliation — an undercounted dismissal against an
  /// already-fired impression makes every rate computed from the pair wrong.
  static const String capSheetDismissed = 'cap_sheet_dismissed';

  /// Which sheet: [sheetDailyCap] | [sheetWarmupExhausted].
  static const String propSheet = 'sheet';

  static const String sheetDailyCap = 'daily_cap';
  static const String sheetWarmupExhausted = 'warmup_exhausted';

  /// How a sheet was closed: [methodButton] or [methodDismissed]. **Two values,
  /// not four**, and the reason is a framework constraint rather than a
  /// shortcut.
  ///
  /// A sheet can be closed four ways — the CTA, a scrim tap, a swipe-down, and
  /// Android back — but `showModalBottomSheet` completes its route future
  /// *identically* for the last three. Its public API exposes no way to tell
  /// them apart, so a literal `scrim` / `swipe` / `back` split would require
  /// intercepting gestures at the route level: real work, real regression risk,
  /// on a wave whose job is to measure rather than to change behaviour.
  ///
  /// This doc originally promised four values, before the code existed. It was
  /// wrong. Recorded here rather than quietly narrowed, so nobody "restores"
  /// the missing three and ships strings that cannot be produced.
  ///
  /// The distinction that actually earns its place is kept: an explicit
  /// decline ([methodButton]) versus getting out of the way
  /// ([methodDismissed]). Those are different intents. Which flavour of
  /// getting-out-of-the-way is not.
  static const String propMethod = 'method';

  /// The user pressed the sheet's own dismiss/secondary control — an explicit
  /// decline.
  static const String methodButton = 'button';

  /// Scrim tap, swipe-down, or Android back. Indistinguishable from each other
  /// through `showModalBottomSheet`; see [propMethod].
  static const String methodDismissed = 'dismissed';

  /// Restore Purchases was tapped. Previously untracked entirely, which made a
  /// silently-failing restore indistinguishable from nobody tapping it — on a
  /// path that is both a churn risk and a support burden.
  static const String restoreStarted = 'restore_started';

  /// Restore finished. Carries [propPremiumActive] — a restore that succeeds
  /// and finds no entitlement is a different outcome from one that finds one,
  /// and the user experiences them very differently.
  static const String restoreCompleted = 'restore_completed';

  /// Restore threw. Carries [propReason].
  static const String restoreFailed = 'restore_failed';

  static const String propPremiumActive = 'premium_active';

  // ─────────────────────────────────────────────────────────────────────────
  // W6 Wave D — the never-superseded v1 Phase-4 holes.
  //
  // Reflect was ZERO-instrumented at the v1 diagnosis and still is: it emits
  // `reflect_beat_advanced`, `reflect_flow_skipped` and `journal_entry_created`
  // and nothing that marks a start or a finish. Verified before minting these
  // that no near-miss spelling already exists to collide with.
  // ─────────────────────────────────────────────────────────────────────────

  /// A Reflect submission passed the gate and began. The pair's denominator.
  static const String reflectStarted = 'reflect_started';

  /// A Reflect submission returned a response. Carries [propOffTopic] so the
  /// classifier's cost on Reflect stays comparable with the daily loop's.
  ///
  /// A gated submit fires NEITHER; a failed AI call fires `started` only — that
  /// asymmetry is what makes an outage distinguishable from an abandonment.
  static const String reflectCompleted = 'reflect_completed';

  static const String propOffTopic = 'off_topic';

  /// The 99 Names browse surface was opened. Deduped per session so a tab
  /// switcher cannot inflate it.
  static const String namesBrowseViewed = 'names_browse_viewed';

  /// A duʿā was actually READ — a specific interaction (card expanded/opened),
  /// **not** a screen mount. There is one duas screen and no detail route, so
  /// "read" had to be defined before it could be emitted; the chosen
  /// interaction is named here so the definition travels with the constant.
  /// Carries [propDuaId] and a `source`.
  static const String duaRead = 'dua_read';

  static const String propDuaId = 'dua_id';

  // ─────────────────────────────────────────────────────────────────────────
  // W6 Wave B — the Second-Name lifecycle.
  //
  // Inherited scope: W3 specified this as its Wave 5, W3 shipped its other four
  // slices, and the fifth never landed — `grep -rn second_name lib/` returned
  // nothing until this wave. It is FEATURE work that arrived inside an
  // instrumentation plan, which is why it was split out and costed separately
  // rather than smuggled in as "a few more events".
  //
  // It measures the seven-day queue: the ship's central retention mechanic, and
  // the one thing the T0+6wk keep decision would otherwise be blind to. Without
  // these, "did the queue run?" cannot be asked at all — only "did people come
  // back", which conflates the queue with everything else in the app.
  // ─────────────────────────────────────────────────────────────────────────

  /// A second Name was TEASED at the end of the onboarding reveal — the promise
  /// the seven-day queue is made of. Carries [propNameId], [propDeckId] and
  /// [propContract].
  ///
  /// Latched alongside `kindledFired` so a rebuild cannot re-fire it; one tease
  /// per user, ever.
  static const String secondNameTeased = 'second_name_teased';

  /// The teased Name became unsealable. Carries [propNameId] and
  /// [propDaysSinceTease].
  ///
  /// **Deduped on the USER-LOCAL date**, not per launch: four app opens in one
  /// day are one availability, and counting them four times would make the
  /// unseal rate (unsealed ÷ available) look four times worse than it is.
  static const String secondNameUnsealAvailable =
      'second_name_unseal_available';

  /// The user actually met the second Name. Carries [propSource],
  /// [propNameId] and [propDaysSinceTease].
  ///
  /// Position 2 only — a third or later Name is ordinary discovery, not the
  /// queue's promise being kept.
  static const String secondNameUnsealed = 'second_name_unsealed';

  static const String propNameId = 'name_id';
  static const String propDeckId = 'deck_id';

  /// Days between the tease and this event. The queue promises a Name on a
  /// schedule; this is whether the schedule held.
  static const String propDaysSinceTease = 'days_since_tease';

  // [propSource] on [secondNameUnsealed] — how the user got back to the app for
  // it. **DIRECTIONAL, NOT EXACT, and it must be documented that way wherever
  // it is charted.**
  //
  // The stamp is a process-global `(source, timestamp)` with a ~10-minute TTL,
  // written by the widget deep-link handler and the notification click
  // listener and read once by the unseal. A cold-launch race, or a user who
  // wanders through the app before revealing, both degrade to
  // [revealSourceOrganic]. So `organic` means "widget/push not observed",
  // NOT "arrived organically" — it is a floor on organic, not a measurement of
  // it. Treating it as exact would over-credit organic and under-credit the
  // two surfaces the queue actually depends on.

  /// The user came back via the home-screen widget.
  static const String revealSourceWidget = 'widget';

  /// The user came back via a push notification.
  static const String revealSourcePush = 'push';

  /// Neither was observed within the TTL. See the caveat above — this is the
  /// residual bucket, not a positive finding.
  static const String revealSourceOrganic = 'organic';

  /// On `check_in_completed`: whether this Name came from the seven-day queue
  /// or from the gacha. [nameSourceQueue] | [nameSourceGacha].
  ///
  /// **Rides alongside `path`, which stays `'discover'`.** Do not fork the
  /// event and do not change `path` — the binding rule from W3/W4. The daily
  /// funnel already divides into `check_in_completed`, and a fork would break
  /// every series that crosses the T0 boundary.
  static const String propNameSource = 'name_source';

  static const String nameSourceQueue = 'queue';
  static const String nameSourceGacha = 'gacha';

  /// Which position in the seven-day queue this Name was. Answers whether users
  /// get through the queue or stall at position 2.
  static const String propQueuePosition = 'queue_position';
}
