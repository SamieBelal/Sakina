import 'package:flutter/material.dart';

import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/services/analytics_events.dart';
import 'package:sakina/services/auth_service.dart';
import 'package:sakina/services/gating_service.dart';

import 'warmup_exhausted_sheet.dart'
    show GatedFeature, PaywallSheetScaffold, resolveNewCohortForSheet;

/// The trigger-specific line the condensed `soft_inapp` paywall shows in place
/// of its default, for a user arriving from a cap sheet's "Unlock unlimited".
/// Null means "keep the default", which is true for every cohort.
///
/// **Derived from the [GateReason], never from the cohort**, which makes it
/// exact rather than merely usually-right: `weeklyPool` and `rerollPremium`
/// are produced *only* on the `reel_v1` path, and `dailyCap` /
/// `hadTrialNoBudget` *only* on the legacy one, so the reason already encodes
/// the tier. It also means this needs no async cohort read on the navigation
/// path, and the line can never contradict the limit the user just hit — a
/// "this week" line in front of a legacy daily-cap user would be D.5's bug in
/// a new place.
///
/// Returns null for [GateReason.premiumFairUse]: that user is premium, there
/// is nothing to sell them, and `buildPaywallUpgradeCallback` already makes
/// their CTA a no-op so this paywall never opens. Also null for the
/// allowed-through reasons, which never reach a cap sheet at all.
///
/// **Spells it `duʿā` / `duʿās`.** So does every other string on a purchase
/// surface, including the cap-sheet bodies below — founder decision
/// 2026-07-31, after a count found 33 files in `lib/` using the ʿayn form
/// against a handful (mostly `journal_screen.dart`) that do not.
///
/// This comment previously said the divergence was deliberate and told you to
/// "match the surface, not the other function in this file". That was written
/// when the bodies still said "duas" and it is now wrong in the dangerous
/// direction — following it would reintroduce the split. Two reasons the ʿayn
/// is right everywhere here: `PaywallCondensedPage` renders this line directly
/// above `PaywallBenefitChecklist`, whose first item is "Unlimited
/// reflections, duʿās & Name discoveries" (`AppStrings.paywallPremiumBenefit1`)
/// — two spellings inches apart on the screen where we ask for money; and a
/// user reads a cap-sheet body, taps "Unlock unlimited", and reads this line
/// two taps later in the same flow.
///
/// `'built_dua'` in `_featureKey` is NOT this word — it is a wire value pinned
/// by `GatingService._bypassFeatureKey` and the Mixpanel schema. An ʿayn there
/// silently breaks event attribution. Leave it.
String? softGateValueLine(GatedFeature feature, GateReason reason) {
  switch (reason) {
    case GateReason.weeklyPool:
      switch (feature) {
        case GatedFeature.reflect:
          return 'Your reflections for this week are used — '
              'Premium is unlimited.';
        case GatedFeature.builtDua:
          return 'Your duʿās for this week are used — Premium is unlimited.';
        case GatedFeature.discoverName:
          // discover_name is rejected outright by consume_weekly_allowance,
          // so this pairing cannot occur. Fall back to the default line
          // rather than invent copy for an impossible state.
          return null;
      }
    case GateReason.rerollPremium:
      return 'One Name a day is free — Premium opens as many as you like.';
    case GateReason.dailyCap:
    case GateReason.hadTrialNoBudget:
      switch (feature) {
        case GatedFeature.reflect:
          return "Today's reflection is used — Premium is unlimited.";
        case GatedFeature.builtDua:
          return "Today's duʿā is used — Premium is unlimited.";
        case GatedFeature.discoverName:
          return "Today's discovery is used — Premium is unlimited.";
      }
    case GateReason.premiumFairUse:
    case GateReason.ok:
    case GateReason.warmupRemaining:
      return null;
  }
}

/// Bottom sheet shown to a free user who has exhausted their allowance for
/// Reflect / Built Dua / Discover Name, OR for narrative high-point triggers
/// (post-streak-milestone, post-card-collected) — in which case the caller
/// passes [headlineOverride] for context-specific copy.
///
/// **Two tiers, two sheets** — selected by [gateReason] when the caller knows
/// the gate outcome, else by [isNewCohort]:
///
///  * **legacy** — a 1/day cap and the token bypass, exactly as shipped.
///  * **`reel_v1`** — Reflect and Build-a-Duʿā draw on a *combined weekly
///    pool* that resets on the local Monday, `discoverName` keeps a
///    permanently-free once-a-day reveal, and the bypass is gone (plan
///    D.4/D10④). The sheet collapses to headline + "Unlock unlimited" +
///    "Maybe later".
///
/// The bypass slot — LEGACY ONLY — renders in one of three states depending
/// on [tokenBalance], [bypassesUsedToday], and [isPremium]:
///
///   STATE A — enough tokens + bypasses_today < cap: enabled "Use 25 tokens
///             for one more (you have N)"
///   STATE B — tokens < 25 + bypasses_today < cap:   disabled, hint
///             "You have N tokens. Need 25."
///   STATE C — bypasses_today >= cap:                disabled, hint
///             "Bypass cap reached. Resets tomorrow."
///   isPremium == true:                              bypass slot hidden
///             entirely (premium uses fair-use ceiling, not this sheet).
///   new tier (either input):                        bypass slot hidden
///             entirely, STATE D included.
///
/// When [onBypassRequested] is null, the sheet renders the legacy two-CTA
/// layout (primary + tertiary) so existing callers without the bypass props
/// stay backward-compatible.
class DailyCapSheet extends StatelessWidget {
  final GatedFeature feature;
  final String? headlineOverride;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  /// Required for the bypass slot. When null, the bypass CTA is hidden.
  final ValueChanged<GatedFeature>? onBypassRequested;
  final int? tokenBalance;
  final int? bypassesUsedToday;
  final bool isPremium;

  /// Day-1 freebie variant (STATE D). When [firstBypassAvailable] is true and
  /// [onFirstBypassRequested] is wired, the sheet renders gold-themed copy +
  /// "X one more time, free" primary CTA INSTEAD of the standard "Unlock
  /// unlimited" + token-bypass layout. EXP-2 of plan 2026-05-23 — the point
  /// is product discovery of the bypass mechanic, not monetization, so the
  /// "Unlock unlimited" CTA is intentionally hidden in this state.
  final bool firstBypassAvailable;
  final ValueChanged<GatedFeature>? onFirstBypassRequested;
  final String? userDisplayName;

  /// True when this account is on the tightened `reel_v1` free tier: the copy
  /// describes a weekly allowance instead of a daily one, and the bypass slot
  /// (STATE A-D) does not render at all.
  ///
  /// Defaults to `false` — the legacy tier — so a caller that has not been
  /// taught about cohorts keeps today's still-true copy AND keeps its bypass,
  /// rather than silently tightening someone's allowance on a default.
  /// [show] resolves the real value.
  final bool isNewCohort;

  /// The gate outcome that caused this sheet, when the caller knows it.
  ///
  /// **Preferred over [isNewCohort] as the copy input**, because it is the
  /// more honest one: this sheet's job is to explain *the limit the user just
  /// hit*, and a cohort flag is only a proxy for that. Passing the reason
  /// makes it impossible for the copy to contradict the gate that produced
  /// it — a user who hits `GateReason.weeklyPool` sees weekly-pool copy even
  /// if the cohort cache were somehow stale or wrong.
  ///
  /// Combined **monotonically** with [isNewCohort] in [_describesNewTier]:
  /// the two tightened reasons force the new-tier copy, and every other
  /// reason (including `null`) defers to the cohort. Deliberately not a
  /// two-way switch — mapping `dailyCap` back to "legacy" would hand legacy
  /// copy to a `reel_v1` user the moment the gate returned a reason this
  /// sheet did not anticipate. Additive can only ever be right; a two-way
  /// map can be wrong in a new way.
  ///
  /// `null` today at all four call sites, so behaviour is unchanged until
  /// they pass `gateReason: reason` — they already hold it, they hand it to
  /// `buildPaywallUpgradeCallback`. `GatingService.canUse` already returns
  /// both reasons, so this needs no further gating-side work.
  final GateReason? gateReason;

  const DailyCapSheet({
    super.key,
    required this.feature,
    required this.onUpgrade,
    required this.onDismiss,
    this.headlineOverride,
    this.onBypassRequested,
    this.tokenBalance,
    this.bypassesUsedToday,
    this.isPremium = false,
    this.firstBypassAvailable = false,
    this.onFirstBypassRequested,
    this.userDisplayName,
    this.isNewCohort = false,
    this.gateReason,
  });

  /// Whether the copy must describe the tightened `reel_v1` tier.
  ///
  /// See [gateReason] for why the reason/cohort part is a one-way OR rather
  /// than a switch.
  ///
  /// **[isPremium] vetoes both inputs, and that is a bug fix, not a nicety.**
  /// `free_tier_cohort` is stamped by `handle_new_user` at signup regardless of
  /// whether the account later subscribes, so a *paying* account created after
  /// the cohort flip reports `isNewCohort == true` forever. The only limit such
  /// a user can hit is the premium fair-use ceiling
  /// (`GatingService.premiumDailyFairUseCap`, 30 per feature per **day**,
  /// counted by `_getUsageToday`) — `canUse` returns `premiumFairUse` from its
  /// premium branch and never reaches the weekly pool at all. Without this
  /// veto they were shown "Your reflections for this week are used / Your free
  /// reflections and duʿās return together on Monday", every clause of which is
  /// false for them: no weekly allowance, nothing returns Monday, and they
  /// already have unlimited. The fair-use ceiling is daily, so the legacy line
  /// is the accurate one.
  ///
  /// Keyed off [isPremium] rather than mapping `premiumFairUse` to `false`,
  /// so it holds even if a caller omits the reason — the same posture as the
  /// bypass slot's premium suppression.
  static bool describesNewTier({
    required GateReason? gateReason,
    required bool isNewCohort,
    required bool isPremium,
  }) {
    if (isPremium) return false;
    return gateReason == GateReason.weeklyPool ||
        gateReason == GateReason.rerollPremium ||
        isNewCohort;
  }

  /// Telemetry hook for `ai_bypass_offered` (PR 3 of plan 2026-05-23).
  /// Set once at app startup in `main.dart` to bridge to `AnalyticsService`.
  /// Fires inside [show] whenever the bypass middle slot will actually
  /// render (`!isPremium && onBypassRequested != null && counters supplied`).
  /// Matching `ai_bypass_purchased` / `ai_bypass_rejected` fire from the
  /// `GatingService.reserveBypass` hook.
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  static Future<void> show(
    BuildContext context, {
    required GatedFeature feature,
    required VoidCallback onUpgrade,
    String? headlineOverride,
    ValueChanged<GatedFeature>? onBypassRequested,
    int? tokenBalance,
    int? bypassesUsedToday,
    bool isPremium = false,
    bool firstBypassAvailable = false,
    ValueChanged<GatedFeature>? onFirstBypassRequested,
    String? userDisplayName,
    GateReason? gateReason,
  }) async {
    // Resolved before the sheet is built so the copy is final on frame zero —
    // a FutureBuilder would flash the daily promise and then swap it for the
    // weekly one, which on a purchase surface is worse than the wait.
    //
    // Skipped only when [gateReason] already settles it: a weekly-pool or
    // reroll-premium gate IS the new tier, so there is nothing a cohort read
    // could add and skipping it drops an await from the path. Any OTHER
    // reason — `dailyCap`, `hadTrialNoBudget`, null — still needs the cohort,
    // because those reasons occur in both tiers and say nothing about which.
    // `!isPremium` leads so a premium account short-circuits before the await
    // as well as before the copy branch — see [describesNewTier].
    final reasonSettlesIt = gateReason == GateReason.weeklyPool ||
        gateReason == GateReason.rerollPremium;
    final newTier =
        !isPremium && (reasonSettlesIt || await resolveNewCohortForSheet());
    if (!context.mounted) return;

    // STATE D takes precedence over the token-bypass slot — when the user
    // qualifies for the Day-1 freebie, the sheet shows ONLY the freebie CTA
    // (the paid-bypass slot is hidden so we don't ask someone to spend
    // tokens 1ms before offering them the same thing for free).
    //
    // Both predicates carry `!newTier` for the same reason they carry
    // `!isPremium`: they gate ANALYTICS as well as layout, and the two must
    // agree. The new tier renders no bypass slot, so firing
    // `ai_bypass_offered` / `first_bypass_offered` for it would inflate the
    // top of a funnel whose remaining steps can never fire — the
    // offer→purchase rate would sink and read as a conversion regression
    // rather than a bypass that no longer exists.
    final willRenderStateD = firstBypassAvailable &&
        !isPremium &&
        !newTier &&
        onFirstBypassRequested != null;
    final willRenderBypassSlot = !willRenderStateD &&
        !isPremium &&
        !newTier &&
        onBypassRequested != null &&
        tokenBalance != null &&
        bypassesUsedToday != null;
    if (willRenderStateD) {
      onAnalyticsEvent?.call(AnalyticsEvents.firstBypassOffered, {
        'feature': _featureKey(feature),
      });
    } else if (willRenderBypassSlot) {
      onAnalyticsEvent?.call(AnalyticsEvents.aiBypassOffered, {
        'feature': _featureKey(feature),
        'token_balance': tokenBalance,
        'bypasses_used_today': bypassesUsedToday,
      });
    }
    return showModalBottomSheet<void>(
      context: context,
      // Push on the ROOT navigator with a named route so the singleton
      // `tourRouteObserver` (wired into the root GoRouter) registers this
      // route's `DailyCapSheet` name and the tour overlay suppresses itself
      // while the sheet is up. Without this the sheet pushes on the nested
      // shell navigator, the root observer never sees it, and an in-flight
      // guided tour overlaps the sheet AND intercepts its buttons. Mirrors
      // the LapsedTrialSheet fix.
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: 'DailyCapSheet'),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (sheetContext) {
        return DailyCapSheet(
          feature: feature,
          headlineOverride: headlineOverride,
          onBypassRequested: onBypassRequested,
          tokenBalance: tokenBalance,
          bypassesUsedToday: bypassesUsedToday,
          isPremium: isPremium,
          firstBypassAvailable: firstBypassAvailable,
          onFirstBypassRequested: onFirstBypassRequested,
          userDisplayName: userDisplayName,
          isNewCohort: newTier,
          gateReason: gateReason,
          onUpgrade: () {
            Navigator.of(sheetContext).pop();
            onUpgrade();
          },
          onDismiss: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  /// Mirrors `GatingService._bypassFeatureKey` — kept duplicated rather than
  /// exported because (a) the gating service version is private to that
  /// file's RPC contract and (b) this is the analytics-side string, which
  /// we want frozen against accidental renames in either layer. Tests pin
  /// both values to the same 3 literals.
  static String _featureKey(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return 'reflect';
      case GatedFeature.builtDua:
        return 'built_dua';
      case GatedFeature.discoverName:
        return 'discover_name';
    }
  }

  /// See [gateReason]: the gate outcome wins when the caller supplies one,
  /// otherwise the cohort decides.
  bool get _describesNewTier => describesNewTier(
        gateReason: gateReason,
        isNewCohort: isNewCohort,
        isPremium: isPremium,
      );

  String get _defaultHeadline =>
      _describesNewTier ? _newCohortHeadline : _legacyHeadline;

  /// LEGACY tier — a genuine 1/day cap, so "today" is accurate.
  String get _legacyHeadline {
    switch (feature) {
      case GatedFeature.reflect:
        return "You've reflected today";
      case GatedFeature.builtDua:
        return "You've built today's duʿā";
      case GatedFeature.discoverName:
        return "You've discovered today's Name";
    }
  }

  /// `reel_v1` tier. The pooled features change their headline because the
  /// unit changed: under a Monday-reset weekly pool the user has not
  /// necessarily done anything *today* — they may have spent the allowance on
  /// Monday and met this sheet on Thursday, which makes "You've reflected
  /// today" plainly false. Phrasing mirrors the founder-approved `soft_inapp`
  /// line in the paywall draft ("Your reflections for this week are used").
  ///
  /// `discoverName` is unchanged and shares the legacy headline: it is NOT
  /// pooled, its reveal really is once a day, so "today" stays exactly true.
  String get _newCohortHeadline {
    switch (feature) {
      case GatedFeature.reflect:
        return 'Your reflections for this week are used';
      case GatedFeature.builtDua:
        return 'Your duʿās for this week are used';
      case GatedFeature.discoverName:
        return _legacyHeadline;
    }
  }

  String get _body => _describesNewTier ? _newCohortBody : _legacyBody;

  /// LEGACY tier — a 1/day cap really does mean tomorrow is on us.
  String get _legacyBody {
    switch (feature) {
      case GatedFeature.reflect:
        return "Tomorrow's reflection is on us. Or unlock unlimited now.";
      case GatedFeature.builtDua:
        return "Tomorrow's duʿā is on us. Or unlock unlimited now.";
      case GatedFeature.discoverName:
        return "Tomorrow's discovery is on us. Or unlock unlimited now.";
    }
  }

  /// `reel_v1` tier — states the real reset.
  ///
  /// The pooled line names BOTH features on purpose. The pool is combined
  /// (`consume_weekly_allowance` charges one counter for `reflect` and
  /// `built_dua` alike), so a user told only that their reflections return
  /// Monday, who then finds Build-a-Duʿā closed too, has been misled by
  /// omission — the same broken promise on the same surface that D10③ exists
  /// to prevent. Naming both is the load-bearing part; keep it through any
  /// future rewording.
  ///
  /// "share a free allowance" was dropped at the founder's direction
  /// (2026-07-31) as too bureaucratic; **"together" carries that meaning now**
  /// and is load-bearing, not a flourish. Without it the sheet has no signal
  /// at all that the two features draw on one pool, and a user who spent the
  /// week on reflections would read "Your duʿās for this week are used" —
  /// having built zero duas — as two separate buckets, one of which
  /// inexplicably emptied. Pinned by test; do not drop it in a reword.
  ///
  /// No number appears, deliberately: the pool size is the server dial
  /// `weekly_pool_size`, which nothing client-side reads. Quoting it here
  /// would rebuild the trap documented at `GatingService.bypassTokenCost` —
  /// ops tunes the dial, the sheet keeps quoting the old figure, and the copy
  /// is false again. "Return on Monday" holds at any pool size.
  String get _newCohortBody {
    switch (feature) {
      case GatedFeature.reflect:
      case GatedFeature.builtDua:
        return 'Your free reflections and duʿās return together on Monday. '
            'Or unlock unlimited now.';
      case GatedFeature.discoverName:
        // Never pooled. The once-a-day reveal consults no gate and is free
        // permanently (D10②) — only a SECOND Name in a day is premium, which
        // is the only thing "unlock unlimited" is selling here.
        return 'One Name a day stays free, always. '
            'Or unlock unlimited to meet another today.';
    }
  }

  /// STATE D is a bypass state, so it dies with the bypass on `reel_v1`
  /// (D.4 — "`claimFirstBypass` included"). Legacy keeps it.
  bool get _isStateD =>
      firstBypassAvailable &&
      !isPremium &&
      !_describesNewTier &&
      onFirstBypassRequested != null;

  /// STATE D headline. Uses the user's display_name when set and not the
  /// default "Friend" placeholder — greeting someone by a generic
  /// placeholder is worse than no greeting at all.
  String get _stateDHeadline {
    final name = userDisplayName;
    if (name == null ||
        name.isEmpty ||
        name == AuthService.defaultDisplayName) {
      return 'One more on us';
    }
    return 'One more on us, $name';
  }

  /// LEGACY ONLY — reachable exclusively through [_isStateD], which is now
  /// false for `reel_v1`. That is why "Tomorrow you'll get one a day" is left
  /// standing here while the same claim was removed from [_body]: on the only
  /// cohort that can still see this text, it remains true. It dies with the
  /// bypass subsystem after the softener wave.
  String get _stateDBody {
    switch (feature) {
      case GatedFeature.reflect:
        return 'We saved you an extra reflection for today. '
            "Tomorrow you'll get one a day.";
      case GatedFeature.builtDua:
        return 'We saved you an extra duʿā for today. '
            "Tomorrow you'll get one a day.";
      case GatedFeature.discoverName:
        return 'We saved you an extra Name discovery for today. '
            "Tomorrow you'll get one a day.";
    }
  }

  String get _stateDPrimaryLabel {
    switch (feature) {
      case GatedFeature.reflect:
        return 'Reflect one more time, free';
      case GatedFeature.builtDua:
        return 'Build one more duʿā, free';
      case GatedFeature.discoverName:
        return 'Discover one more Name, free';
    }
  }

  /// True when the sheet should render the AI-bypass middle CTA at all.
  ///
  /// Hidden for premium users (defense-in-depth — premium should never reach
  /// this sheet, but if they do, never offer the bypass CTA), when the caller
  /// didn't wire the callback, and for the `reel_v1` cohort, whose sheet is
  /// headline + "Unlock unlimited" + "Maybe later" and nothing else.
  ///
  /// Removing it for `reel_v1` also removes a dead end rather than only a
  /// button: under 25 tokens the slot rendered disabled with a hint and there
  /// was no route from this sheet to buying tokens (D10④). Legacy keeps both
  /// the button and the dead end until the softener wave retires the whole
  /// bypass subsystem.
  bool get _shouldRenderBypassSlot {
    return !isPremium &&
        !_describesNewTier &&
        onBypassRequested != null &&
        tokenBalance != null &&
        bypassesUsedToday != null;
  }

  bool get _bypassEnabled {
    if (!_shouldRenderBypassSlot) return false;
    final balance = tokenBalance ?? 0;
    final used = bypassesUsedToday ?? 0;
    return balance >= GatingService.bypassTokenCost &&
        used < GatingService.maxBypassesPerDayPerFeature;
  }

  String get _bypassLabel {
    final balance = tokenBalance ?? 0;
    return 'Use ${GatingService.bypassTokenCost} tokens for one more '
        '(you have $balance)';
  }

  String? get _bypassDisabledHint {
    if (!_shouldRenderBypassSlot) return null;
    final balance = tokenBalance ?? 0;
    final used = bypassesUsedToday ?? 0;
    if (used >= GatingService.maxBypassesPerDayPerFeature) {
      return "You've used today's bypasses. They reset tomorrow.";
    }
    if (balance < GatingService.bypassTokenCost) {
      return 'You have $balance tokens. Need ${GatingService.bypassTokenCost}.';
    }
    return null;
  }

  /// True when this sheet is being shown to someone who already pays.
  ///
  /// Either signal is enough. `isPremium` is what the four call sites resolve
  /// from `PurchaseService`; `premiumFairUse` is what `canUse` returns from
  /// its premium branch. Requiring both would make the veto depend on a
  /// caller remembering to pass the reason.
  bool get _isPremiumFairUse =>
      isPremium || gateReason == GateReason.premiumFairUse;

  /// **Premium fair-use headline.** `gating_service.dart` has specified since
  /// May that this case must be "silent — UI must surface a 'take a breath'
  /// message, NOT route to a paywall (the user is already paying)". The rule
  /// was written; the sheet never followed it, and `buildPaywallUpgradeCallback`
  /// quietly no-opping the CTA is what let a live "Unlock unlimited" button
  /// sit in front of subscribers without anything looking broken.
  String get _premiumHeadline => "You've done a lot today";

  /// Says plainly that the limit is daily and lifts tomorrow. Sells nothing,
  /// blames nothing, apologises for nothing, and does not explain that a
  /// fair-use ceiling exists — none of that is the user's problem.
  String get _premiumBody {
    switch (feature) {
      case GatedFeature.reflect:
        return 'Reflections open again tomorrow.';
      case GatedFeature.builtDua:
        return 'Duʿās open again tomorrow.';
      case GatedFeature.discoverName:
        return 'Name discoveries open again tomorrow.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ordered FIRST, ahead of STATE D and the standard layout, so no later
    // branch can reintroduce a CTA for a subscriber.
    if (_isPremiumFairUse) {
      return PaywallSheetScaffold(
        icon: Icons.wb_sunny_outlined,
        headline: headlineOverride ?? _premiumHeadline,
        body: _premiumBody,
        // No primaryLabel and no onPrimary: the upgrade CTA is ABSENT, not
        // disabled and not a no-op. A dismiss is the whole sheet.
        secondaryLabel: 'Close',
        onSecondary: onDismiss,
      );
    }
    if (_isStateD) {
      return PaywallSheetScaffold(
        icon: Icons.workspace_premium,
        headline: _stateDHeadline,
        body: _stateDBody,
        // STATE D collapses to a single gold primary + tertiary dismiss.
        // "Unlock unlimited" is intentionally hidden — the freebie's job is
        // product discovery, not sub upsell. Token-bypass slot also hidden
        // because asking someone to pay 1ms after offering a freebie would
        // be insulting.
        primaryLabel: _stateDPrimaryLabel,
        primaryColor: AppColors.secondary,
        secondaryLabel: 'Maybe later',
        onPrimary: () {
          Navigator.of(context).pop();
          onFirstBypassRequested!(feature);
        },
        onSecondary: onDismiss,
      );
    }
    return PaywallSheetScaffold(
      icon: Icons.wb_sunny_outlined,
      headline: headlineOverride ?? _defaultHeadline,
      body: _body,
      primaryLabel: 'Unlock unlimited',
      secondaryLabel: 'Maybe later',
      onPrimary: onUpgrade,
      onSecondary: onDismiss,
      middleLabel: _shouldRenderBypassSlot ? _bypassLabel : null,
      middleEnabled: _bypassEnabled,
      middleDisabledHint: _bypassDisabledHint,
      onMiddle: _shouldRenderBypassSlot
          ? () {
              // Sheet closes synchronously; provider takes over the
              // reserve → AI → commit/cancel flow. If reserve fails, the
              // provider surfaces a toast or re-opens the sheet.
              Navigator.of(context).pop();
              onBypassRequested!(feature);
            }
          : null,
    );
  }
}
