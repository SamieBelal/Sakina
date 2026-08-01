import 'package:flutter/foundation.dart';
import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/app_config_service.dart';
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart' as tokens;
import 'package:sakina/services/user_local_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Gating Service
//
// Single source of truth for "can the user use AI feature X right now?".
// Consolidates premium-vs-free, warmup-budget, daily-cap, and lapsed-trialer
// rules so callers (reflect / built-dua / discover-name providers) ask one
// question instead of stitching policy together themselves.
//
// Decision tree (see spec 2026-05-09-free-premium-tier-redesign-design):
//   1. Premium → 30/day fair-use ceiling.
//   2. Free + had_trial==true → skip warmup, apply 1/day cap.
//   3. Free + had_trial==false → consume warmup budget; cap kicks in at 0.
// ---------------------------------------------------------------------------

enum GatedFeature { reflect, builtDua, discoverName }

enum GateReason {
  ok,
  premiumFairUse,
  warmupRemaining,
  dailyCap,
  hadTrialNoBudget,

  /// `reel_v1` only. The combined Reflect + Build-a-Duʿā weekly pool is spent
  /// for this local week. Distinct from [dailyCap] because the reset story the
  /// UI must tell is different — "next Monday", not "tomorrow" (D10③).
  weeklyPool,

  /// `reel_v1` only. `discoverName` re-rolls have no free allowance once the
  /// lifetime warmup is spent — a second Name the same day is premium (D10②).
  /// The day-open reveal is unaffected: it consults no gate at all.
  rerollPremium,
}

/// Outcome of a successful [GatingService.markUsed] call. Most calls return
/// [ok]. The transition moment when a free user's warmup counter decrements
/// from 1 to 0 returns [warmupJustExhausted] so the UI can fire the dedicated
/// "you've completed your free reflections" sheet exactly once per feature.
enum UsageOutcome { ok, warmupJustExhausted }

class GateResult {
  final bool allowed;
  final GateReason reason;
  final int? remaining;
  const GateResult({
    required this.allowed,
    required this.reason,
    this.remaining,
  });
}

/// Successful response from [GatingService.reserveBypass]. Caller must hold
/// [reservationId] for the lifetime of the AI call and pass it to either
/// [GatingService.commitBypass] (on success) or [GatingService.cancelBypass]
/// (on failure / abandonment). If neither fires, the server-side orphan-
/// cleanup cron will cancel the reservation after 15 minutes.
class BypassReservation {
  final String reservationId;
  final int newBalance;
  final int bypassesUsedToday;

  const BypassReservation({
    required this.reservationId,
    required this.newBalance,
    required this.bypassesUsedToday,
  });
}

class GatingService {
  GatingService._();

  static final GatingService instance = GatingService._();

  @visibleForTesting
  GatingService.test();

  factory GatingService() => _debugOverride ?? instance;

  static GatingService? _debugOverride;

  @visibleForTesting
  static void debugSetOverride(GatingService service) {
    _debugOverride = service;
  }

  @visibleForTesting
  static void debugClearOverride() {
    _debugOverride = null;
  }

  /// Telemetry hook for the AI-bypass funnel (PR 3 of plan 2026-05-23).
  /// Set once at app startup in `main.dart` to bridge to `AnalyticsService`.
  /// Left null in tests so no real Mixpanel hits fire; widget/unit tests can
  /// install a spy to assert on emitted events.
  ///
  /// Fires `ai_bypass_purchased` after a successful reservation and
  /// `ai_bypass_rejected` when the RPC returns `ok=false` or null. The
  /// matching `ai_bypass_offered` fires from [DailyCapSheet.show].
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  /// Fires after [hydrateFromProfile] finishes writing all per-user
  /// SharedPreferences keys from a `sync_all_user_data` payload. Wired in
  /// `AppLifecycleObserver` to `ref.invalidate(iapToSubBannerStateProvider)`
  /// so the home-screen banner re-reads its eligibility predicates against
  /// the freshly-hydrated cache. Without this signal, the banner's
  /// FutureProvider would evaluate once at first widget mount — typically
  /// BEFORE sync completes — see a default `lifetime_bypasses_purchased=0`,
  /// resolve to "hidden", and never re-render for the rest of the session.
  ///
  /// Left null in tests so widget tests don't take a dependency on Riverpod
  /// container plumbing. Production wires it exactly once in
  /// `AppLifecycleObserver.initState`.
  static void Function()? onProfileHydrated;

  /// Premium fair-use ceiling per feature per day. Silent — UI must surface
  /// a "take a breath" message, NOT route to a paywall (the user is already
  /// paying).
  static const int premiumDailyFairUseCap = 30;

  /// Token cost to bypass the daily cap for one extra AI use. Seeded server-side
  /// by `20260523000000_ai_bypass_reservations_and_rpcs.sql`.
  ///
  /// **Correction 2026-07-31: this constant is NOT a fallback — it is the only
  /// value the client ever uses.** The docstring here previously claimed the
  /// server was the source of truth and this was "a defensive fallback used by
  /// the DailyCapSheet copy when the server value hasn't been hydrated yet".
  /// There is no hydration: these two comments are the *only* references to
  /// `bypass_token_cost` / `max_bypasses_per_day` anywhere in `lib/`.
  ///
  /// That made the prod dial an operational trap — tuning
  /// `app_config.bypass_token_cost` changes what the RPC charges while the
  /// sheet keeps quoting 25, so the user is told one price and charged another.
  /// Deliberately left unwired rather than fixed: W5 removes the bypass for the
  /// `reel_v1` cohort and the whole subsystem is deleted after the softener wave
  /// (§V6.10), so this is code with a scheduled death. See
  /// [warmupSizeConfigKey] for how a dial that *is* read looks.
  static const int bypassTokenCost = 25;

  /// Maximum number of bypass spends per feature per day. Same story as
  /// [bypassTokenCost] — `app_config.max_bypasses_per_day` exists server-side
  /// and nothing client-side reads it.
  static const int maxBypassesPerDayPerFeature = 2;

  /// Lifetime warmup budgets per feature — **offline fallbacks only**.
  ///
  /// The live numbers are server dials ([warmupSizeConfigKey]); read them
  /// through [warmupBudgetFor], never this map. These constants answer only
  /// when the dial has never been cached AND the fetch fails — an offline
  /// first launch. They are deliberately the MORE GENEROUS legacy values: a
  /// config read that cannot complete must let the user through, never harden
  /// the gate.
  static const Map<GatedFeature, int> warmupBudget = {
    GatedFeature.reflect: 10,
    GatedFeature.builtDua: 10,
    GatedFeature.discoverName: 5,
  };

  /// `app_config` key carrying the live lifetime warmup size for each feature.
  /// Seeded server-side by `20260727100200_free_tier_cohort_weekly_pool.sql`
  /// (reflect / built_dua) and `20260731090000_warmup_discover_name_size.sql`
  /// (discover_name). Permanent tuning knobs, not flags — no deletion date.
  static const Map<GatedFeature, String> warmupSizeConfigKey = {
    GatedFeature.reflect: 'warmup_reflect_size',
    GatedFeature.builtDua: 'warmup_built_dua_size',
    GatedFeature.discoverName: 'warmup_discover_name_size',
  };

  /// The live lifetime warmup budget for [feature], read from `app_config`
  /// with [warmupBudget] as the offline fallback.
  ///
  /// Cheap on the hot path by construction: [AppConfigService.getInt] answers
  /// from a SharedPreferences cache (6h stale-while-revalidate) and never
  /// awaits the network — a stale entry is returned immediately while a
  /// refresh runs detached. And the gate only reaches here when the user's
  /// per-feature warmup counter has no cached value at all (see
  /// [_readWarmupRemaining]'s `??`), so the steady-state gate check does not
  /// touch config at all.
  ///
  /// A dial of `0` is legitimate ("no warmup for this feature"); a negative
  /// one is corruption and falls back rather than inverting the gate.
  Future<int> warmupBudgetFor(GatedFeature feature) async {
    final fallback = warmupBudget[feature]!;
    final value = await AppConfigService.resolve().getInt(
      warmupSizeConfigKey[feature]!,
      fallback: fallback,
    );
    return value < 0 ? fallback : value;
  }

  // ---- free-tier cohort ---------------------------------------------------

  /// `user_profiles.free_tier_cohort` value meaning "the tightened W5 tier".
  static const String cohortReelV1 = 'reel_v1';

  /// True when this account is on the tightened `reel_v1` free tier.
  ///
  /// Reads the cached `free_tier_cohort` written by [hydrateFromProfile] from
  /// the `sync_all_user_data` payload. NULL, `'legacy'`, an unrecognised
  /// string, or no cache at all → **false**.
  ///
  /// **Fails to `false` by construction, and that direction is the point.**
  /// `false` selects the LEGACY tier, which is the more generous of the two:
  /// 10/10 warmups, a daily cap rather than a weekly pool, the bypass
  /// available. An account whose cohort cannot be determined — a fresh
  /// install before the first batch sync, a sync that timed out, a signed-out
  /// read — must never be handed the tighter rules on a guess. The cost of
  /// being wrong is a handful of extra free uses until the next sync lands;
  /// the cost of the opposite default is silently tightening a paying-adjacent
  /// user's allowance because the network blinked.
  ///
  /// Deliberately cache-only — no network read, no fetch-on-miss. The value is
  /// server-assigned once in `handle_new_user` and never changes for the life
  /// of the account (the softener wave migrates cohorts server-side, and that
  /// arrives through the same sync), so there is nothing a round-trip could
  /// learn that the next `hydrateFromProfile` will not. It also keeps this
  /// callable from the gate hot path without an await on the wire.
  ///
  /// ---
  /// **⚠️ THIS IS NOT A "USER IS ON THE FREE TIER" PREDICATE. Do not use it as
  /// one.** `free_tier_cohort` is stamped at signup and is never cleared when
  /// the account subscribes, so **every payer created after the T0 flip reports
  /// `true` here forever.** It answers only "which free-tier RULES would apply
  /// to this account", not "are those rules currently in force".
  ///
  /// It is safe everywhere in this file because every caller sits behind a
  /// premium short-circuit that returns first — [canUse], [markUsed],
  /// [reserveBypass], [claimFirstBypass], [firstBypassEligible] and
  /// [iapToSubBannerEligible] all resolve `PurchaseService().isPremium()` and
  /// return before reading the cohort. **That ordering is a load-bearing
  /// invariant maintained by inspection, not by the type system: a seventh
  /// call site added without a premium check ahead of it silently applies
  /// free-tier logic to a paying customer.** If you add one, put the premium
  /// check first.
  ///
  /// It has already caused this bug once, outside this file: the W5 cap-sheet
  /// copy keyed off the cohort alone and told paying users *"your free
  /// reflections return on Monday"*. The fix there was an entitlement veto
  /// (`DailyCapSheet.describesNewTier`, which returns false for premium
  /// regardless of cohort), not a more careful cohort read. UI that a premium
  /// user can reach should prefer the [GateReason] — `weeklyPool` /
  /// `rerollPremium` can only be produced by an actual free-tier block — or
  /// veto on premium explicitly.
  Future<bool> isNewCohort() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(
      supabaseSyncService.scopedKey(_freeTierCohortBaseKey),
    );
    return cached == cohortReelV1;
  }

  static const String _freeTierCohortBaseKey = 'free_tier_cohort';

  // ---- weekly pool (reel_v1) ----------------------------------------------

  /// `app_config` key carrying the size of the combined Reflect +
  /// Build-a-Duʿā weekly pool. Seeded by
  /// `20260727100200_free_tier_cohort_weekly_pool.sql` at `3`, and read by
  /// `consume_weekly_allowance` itself — so client and server share one dial.
  static const String weeklyPoolSizeConfigKey = 'weekly_pool_size';

  /// Offline fallback for [weeklyPoolSizeConfigKey]. Matches both the seeded
  /// dial and the RPC's own `coalesce(..., 3)`, so a client that cannot reach
  /// config still agrees with the server.
  static const int weeklyPoolSizeFallback = 3;

  /// The live weekly pool size. Same posture as [warmupBudgetFor]: cheap
  /// (SharedPreferences-backed, never awaits the network), and a negative dial
  /// is corruption and falls back rather than inverting the gate. A dial of
  /// `0` is legitimate.
  Future<int> weeklyPoolSize() async {
    final value = await AppConfigService.resolve().getInt(
      weeklyPoolSizeConfigKey,
      fallback: weeklyPoolSizeFallback,
    );
    return value < 0 ? weeklyPoolSizeFallback : value;
  }

  /// Cached uses remaining in this local week's pool.
  ///
  /// **Advisory only — the server is the authority.** This answers the gate
  /// check (`canUse`) so a capped user meets the sheet without a round-trip;
  /// the actual spend goes through `consume_weekly_allowance`, and its verdict
  /// overwrites this cache. When the two disagree the error is one extra AI
  /// call, never a denial.
  ///
  /// **The stale-week rule is not an optimisation, it prevents a permanent
  /// lockout.** `weekly_pool_used` only resets INSIDE the RPC. A user who
  /// spent their pool last week syncs `used = 3` with LAST Monday's
  /// `week_start` on launch — so a cache that trusted `used` alone would deny
  /// forever: the gate refuses, the RPC is therefore never called, and the
  /// reset that only the RPC performs never happens. Treating a `week_start`
  /// strictly before the current local ISO Monday as "unspent" lets the call
  /// through so the server can reset. If the server's 6-day wall-clock anchor
  /// declines that reset it returns `allowed:false`, and
  /// [_consumeWeeklyPool] writes the cache back to full — self-correcting.
  ///
  /// Local-only by construction. `weekly_pool_used` is guarded RPC-only
  /// server-side, so nothing here is ever pushed to `user_profiles`; the
  /// destructive-guess-into-a-ratcheted-column failure mode does not apply.
  Future<int> weeklyPoolRemaining() async {
    final pool = await weeklyPoolSize();
    final prefs = await SharedPreferences.getInstance();
    final storedWeek = prefs.getString(
      supabaseSyncService.scopedKey(_weeklyPoolWeekStartBaseKey),
    );
    if (storedWeek == null) return pool;
    if (storedWeek.compareTo(await _localWeekStart()) < 0 &&
        !await _staleWeekProbeSpentToday()) {
      return pool;
    }
    final used =
        prefs.getInt(supabaseSyncService.scopedKey(_weeklyPoolUsedBaseKey)) ?? 0;
    return (pool - used).clamp(0, pool);
  }

  /// True when the stale-week optimism above has already been cashed in today
  /// and the server answered for a week it had NOT rolled over.
  ///
  /// **The optimism has to be a probe, not a standing permission.** The marker
  /// [weeklyPoolRemaining] compares against is the SERVER's week, so when the
  /// two sides disagree about which week it is, "stale" never clears on its
  /// own: the client waves a call through, the server declines, the client
  /// writes the decline into a cache the stale branch then ignores, and the
  /// loop runs forever — an unlimited pool of real AI calls, each one already
  /// refused by the server.
  ///
  /// That disagreement is ordinary rather than adversarial. `handle_new_user`
  /// creates `user_notification_preferences` with no timezone and
  /// `safe_user_tz` answers `'UTC'` for a blank one, so until the device syncs
  /// its zone the server computes the week in UTC while
  /// [userLocalDay] computes it in the device zone — for the opening hours of
  /// a user east of UTC's local Monday the client is in the new week and the
  /// server is not. A device clock set forward has the same shape and never
  /// expires at all.
  ///
  /// Bounded to ONE probe per local day rather than refused outright, because
  /// the client cannot learn that the server has rolled over without asking:
  /// a permanent refusal here would restore exactly the lockout the stale-week
  /// rule exists to prevent. The residual cost is one extra AI call per day of
  /// skew, against the unbounded one it replaces.
  Future<bool> _staleWeekProbeSpentToday() async {
    final prefs = await SharedPreferences.getInstance();
    final probed = prefs.getString(
      supabaseSyncService.scopedKey(_weeklyPoolProbeDayBaseKey),
    );
    if (probed == null) return false;
    return probed == await userLocalDayString();
  }

  /// The current local ISO week's Monday as `YYYY-MM-DD` — the same shape and
  /// the same boundary `consume_weekly_allowance` computes with
  /// `date_trunc('week', now() at time zone safe_user_tz(uid))`. Resolved
  /// through [userLocalDay] so both sides read the one timezone source
  /// (`user_notification_preferences.timezone`), exactly as the daily-cap key
  /// does.
  Future<String> _localWeekStart() async {
    final day = await userLocalDay();
    // `day` is a date-only DateTime.utc, so day arithmetic has no DST to trip
    // over. ISO weekday: Monday = 1 … Sunday = 7.
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}'
        '-${monday.day.toString().padLeft(2, '0')}';
  }

  /// Spends one weekly-pool use via the SECURITY DEFINER RPC and mirrors the
  /// server's answer into the local cache.
  ///
  /// **Fails OPEN, and writes nothing when it does.** A null result covers
  /// both "the server refused" and "we never reached the server"; in either
  /// case the client does not know what happened, so it must neither charge
  /// the user locally (the RPC may not have run — that would be a double
  /// charge on the next successful call) nor lock them out (the RPC may have
  /// run — but a network blip is not a reason to withhold the app). Leaving
  /// the cache untouched means the user keeps whatever the last authoritative
  /// sync said, and the next `hydrateFromProfile` reconciles.
  ///
  /// Every number written here has server provenance: `remaining` comes from
  /// the RPC, `week_start` comes from the RPC. `pool - remaining` uses the
  /// shared [weeklyPoolSizeConfigKey] dial the RPC itself read, so a stale
  /// client dial can skew the cached `used` by the dial delta — bounded, local
  /// only, and healed by the next sync, which writes the server's own
  /// `weekly_pool_used`.
  Future<void> _consumeWeeklyPool(GatedFeature feature) async {
    Map<String, dynamic>? result;
    try {
      result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
        'consume_weekly_allowance',
        {'p_feature': _bypassFeatureKey(feature)},
      );
    } catch (_) {
      // Belt and braces. Production's `callRpc` already swallows into null,
      // but "fails open" is a property of this function, not of its callee —
      // a throw escaping here would propagate out of `markUsed` and, for the
      // discover path, flip a reveal that HAPPENED into `state.error`.
      return;
    }
    if (result == null) return;

    final remaining = (result['remaining'] as num?)?.toInt();
    if (remaining == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pool = await weeklyPoolSize();
    await prefs.setInt(
      supabaseSyncService.scopedKey(_weeklyPoolUsedBaseKey),
      (pool - remaining).clamp(0, pool),
    );

    // Stamped LAST and only alongside a usable `remaining`: the week marker is
    // what makes the cached `used` readable at all, so a marker without a
    // count would make a fresh week look spent.
    final weekStartRaw = result['week_start'];
    final serverWeek =
        weekStartRaw is String && weekStartRaw.isNotEmpty ? weekStartRaw : null;
    if (serverWeek != null) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_weeklyPoolWeekStartBaseKey),
        serverWeek,
      );
    }
    await _recordStaleWeekProbe(serverWeek);
  }

  /// Records whether the server, having just been asked, agreed that the week
  /// has rolled over — the expiry for [_staleWeekProbeSpentToday].
  ///
  /// The server's `week_start` is the only evidence available: if it comes
  /// back still behind the client's local Monday, the server did NOT reset,
  /// and asking again today buys nothing but a free AI call. If it has caught
  /// up, the disagreement is over and the marker is dropped so the next
  /// genuine week boundary gets its probe immediately.
  ///
  /// A null [serverWeekStart] — a usable `remaining` with no week alongside it
  /// — counts as "did not roll over", and must. That response leaves the
  /// cached marker at whatever stale value it already held, so treating the
  /// silence as agreement would reopen the same unbounded loop through the
  /// malformed path.
  Future<void> _recordStaleWeekProbe(String? serverWeekStart) async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(_weeklyPoolProbeDayBaseKey);
    if (serverWeekStart == null ||
        serverWeekStart.compareTo(await _localWeekStart()) < 0) {
      await prefs.setString(key, await userLocalDayString());
    } else {
      await prefs.remove(key);
    }
  }

  static const String _weeklyPoolUsedBaseKey = 'weekly_pool_used';
  static const String _weeklyPoolWeekStartBaseKey = 'weekly_pool_week_start';
  static const String _weeklyPoolProbeDayBaseKey = 'weekly_pool_probe_day';

  /// [isPremiumHint] lets the caller skip a duplicate RevenueCat round-trip
  /// when premium status was already resolved upstream. Pair with
  /// [markUsed]'s identical hint to keep the whole submit cycle to a single
  /// `PurchaseService().isPremium()` call.
  Future<GateResult> canUse(
    GatedFeature feature, {
    bool? isPremiumHint,
  }) async {
    final isPremium = isPremiumHint ?? await PurchaseService().isPremium();
    if (isPremium) {
      final usedToday = await _getUsageToday(feature);
      if (usedToday >= premiumDailyFairUseCap) {
        return const GateResult(
          allowed: false,
          reason: GateReason.premiumFairUse,
        );
      }
      return const GateResult(allowed: true, reason: GateReason.ok);
    }

    // Free user.
    final newCohort = await isNewCohort();

    final hadTrial = await _readHadTrial();
    if (hadTrial) {
      // Skip warmup; apply the post-warmup allowance immediately.
      return _applyPostWarmupCap(feature, hadTrial: true, newCohort: newCohort);
    }

    final warmup = await _readWarmupRemaining(feature);
    if (warmup > 0) {
      return GateResult(
        allowed: true,
        reason: GateReason.warmupRemaining,
        remaining: warmup,
      );
    }

    return _applyPostWarmupCap(feature, hadTrial: false, newCohort: newCohort);
  }

  /// Records a successful AI call. Increments the daily counter when the
  /// user is in capped/premium phase, decrements the warmup counter when
  /// they're still in warmup. Never touches both.
  ///
  /// Returns [UsageOutcome.warmupJustExhausted] only on the transition moment
  /// when this call decrements warmup from 1 to 0 — the screen layer uses that
  /// signal to fire [WarmupExhaustedSheet] exactly once per feature. All other
  /// paths return [UsageOutcome.ok].
  ///
  /// [isPremiumHint] lets the caller skip a duplicate RevenueCat round-trip
  /// when premium status was already resolved during the same submit cycle
  /// (typically in [canUse]). Pass the boolean returned from there. Falls back
  /// to a fresh `PurchaseService().isPremium()` check when omitted.
  Future<UsageOutcome> markUsed(
    GatedFeature feature, {
    bool? isPremiumHint,
  }) async {
    final isPremium = isPremiumHint ?? await PurchaseService().isPremium();
    if (isPremium) {
      await _incrementDaily(feature);
      return UsageOutcome.ok;
    }

    final newCohort = await isNewCohort();

    final hadTrial = await _readHadTrial();
    if (hadTrial) {
      await _consumePostWarmup(feature, newCohort: newCohort);
      return UsageOutcome.ok;
    }

    final warmup = await _readWarmup(feature);
    if (warmup.remaining > 0) {
      await _decrementWarmup(
        feature,
        warmup.remaining,
        pushToServer: warmup.fromStore,
      );
      // The "1 → 0" transition is the one-shot moment the WarmupExhaustedSheet
      // fires on. Subsequent decrements are clamped to 0 in _decrementWarmup
      // and never re-trigger this signal because warmup will already be 0
      // before this branch runs.
      //
      // Critically, we ALSO charge the DAILY counter on this transition.
      // Without it, canUse() falls through to the cap on the very next attempt
      // and — since the counter is still 0 — allows ONE MORE use TODAY. The
      // user would get N+1 free uses instead of N. By recording today's
      // exhaust call, the next attempt is blocked, and tomorrow rolls over via
      // the per-day key in daily_usage_service.
      //
      // The weekly pool is deliberately NOT charged here, and the daily
      // reasoning above is exactly why it must not be. That rule buys back a
      // use inside the SAME DAY on a PER-FEATURE counter. The pool is neither:
      // it is one shared Reflect + Build-a-Duʿā budget that only refills on
      // Monday, and the warmup is a separate lifetime grant that has already
      // paid for this call. Charging it would take a use for a call the user
      // has already earned — and, because the pool is shared, exhausting
      // `reflect`'s warmup would quietly spend `builtDua`'s allowance. A
      // reel_v1 user finishing both 3-use warmups in one week would arrive at
      // the post-warmup tier with 1 of 3 uses left having made no post-warmup
      // call at all, while WarmupExhaustedSheet promised them three.
      //
      // Nothing is bought back by skipping it: past warmup, canUse() reads the
      // pool, and the pool is the whole post-warmup allowance for the week —
      // there is no same-day double-grant to prevent. `discoverName` stays on
      // the daily counter (it is exempt from the pool), so it keeps the rule.
      if (warmup.remaining == 1) {
        if (!newCohort || feature == GatedFeature.discoverName) {
          await _incrementDaily(feature);
        }
        return UsageOutcome.warmupJustExhausted;
      }
      return UsageOutcome.ok;
    }

    await _consumePostWarmup(feature, newCohort: newCohort);
    return UsageOutcome.ok;
  }

  /// Charges one post-warmup use against whichever allowance this cohort is on.
  ///
  /// `legacy` — and `reel_v1`'s `discoverName`, which is exempt from the pool —
  /// increment the local daily counter, which also mirrors to
  /// `user_daily_usage` server-side. For `reel_v1` `discoverName` that counter
  /// no longer gates anything (`_applyPostWarmupCap` refuses re-rolls outright)
  /// but is still written, because `user_daily_usage.discover_name_uses` is the
  /// row the analytics and multi-device reconciliation read.
  ///
  /// `reel_v1` `reflect` / `builtDua` spend the weekly pool instead — server
  /// authoritative, and never both. Charging both would take two uses for one.
  Future<void> _consumePostWarmup(
    GatedFeature feature, {
    required bool newCohort,
  }) async {
    if (!newCohort || feature == GatedFeature.discoverName) {
      await _incrementDaily(feature);
      return;
    }
    await _consumeWeeklyPool(feature);
  }

  // ---- helpers ------------------------------------------------------------

  /// The post-warmup allowance, which is where the two cohorts diverge.
  ///
  /// `legacy` keeps today's behaviour byte for byte — the local 1/day cap, and
  /// `discoverName` at an effective 2/day (one free day-open reveal that
  /// consults no gate, plus one metered re-roll). Nothing about the existing
  /// base changes here; the softener wave owns migrating them.
  ///
  /// `reel_v1` gets the tightened tier:
  ///  * `reflect` / `builtDua` share a **weekly pool** ([weeklyPoolRemaining]),
  ///    not a per-feature daily cap.
  ///  * `discoverName` is **exempt from the pool and has no free allowance at
  ///    all** past its warmup — a second Name the same day is premium (D10②).
  ///    The day-open reveal is untouched and stays free forever: it never
  ///    reaches this function, because it never asks the gate.
  Future<GateResult> _applyPostWarmupCap(
    GatedFeature feature, {
    required bool hadTrial,
    required bool newCohort,
  }) async {
    if (!newCohort) return _applyDailyCap(feature, hadTrial: hadTrial);

    if (feature == GatedFeature.discoverName) {
      _emitCapHit(feature);
      return const GateResult(
        allowed: false,
        reason: GateReason.rerollPremium,
        remaining: 0,
      );
    }

    final remaining = await weeklyPoolRemaining();
    if (remaining <= 0) {
      _emitCapHit(feature);
      return const GateResult(
        allowed: false,
        reason: GateReason.weeklyPool,
        remaining: 0,
      );
    }
    return GateResult(
      allowed: true,
      reason: GateReason.ok,
      remaining: remaining,
    );
  }

  /// The free/lapsed user just ran out of allowance — the numerator for the
  /// "cap-hit → upgrade" loop in the funnel. Kept as one event across both
  /// cohorts on purpose: renaming it for the weekly pool would fork the funnel
  /// that already exists. Segmentation by cohort belongs to W6's
  /// instrumentation pass, not here.
  ///
  /// Premium fair-use blocks NEVER reach this — they short-circuit in [canUse]
  /// with [GateReason.premiumFairUse], a silent "take a breath", not a paywall.
  void _emitCapHit(GatedFeature feature) {
    onAnalyticsEvent?.call(AnalyticsEvents.dailyCapHit, {
      AnalyticsEvents.propFeature: _bypassFeatureKey(feature),
    });
  }

  Future<GateResult> _applyDailyCap(
    GatedFeature feature, {
    required bool hadTrial,
  }) async {
    final used = await _getUsageToday(feature);
    final cap = _dailyCap(feature);
    if (used >= cap) {
      // `daily_cap_hit{feature}` — the `arm` rides as the `paywall_exp_arm`
      // Mixpanel super-property set at assignment, so the event segments by arm
      // without this Riverpod-free service needing the experiment flag.
      _emitCapHit(feature);
      return GateResult(
        allowed: false,
        reason: hadTrial ? GateReason.hadTrialNoBudget : GateReason.dailyCap,
      );
    }
    return const GateResult(allowed: true, reason: GateReason.ok);
  }

  int _dailyCap(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.dailyFreeReflects;
      case GatedFeature.builtDua:
        return daily.dailyFreeBuiltDuas;
      case GatedFeature.discoverName:
        return daily.dailyFreeDiscoverNames;
    }
  }

  Future<int> _getUsageToday(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.getReflectUsageToday();
      case GatedFeature.builtDua:
        return daily.getBuiltDuaUsageToday();
      case GatedFeature.discoverName:
        return daily.getDiscoverNameUsageToday();
    }
  }

  Future<int> _incrementDaily(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.incrementReflectUsage();
      case GatedFeature.builtDua:
        return daily.incrementBuiltDuaUsage();
      case GatedFeature.discoverName:
        return daily.incrementDiscoverNameUsage();
    }
  }

  String _warmupPrefsKey(GatedFeature feature) {
    return supabaseSyncService.scopedKey(
      'warmup_${feature.name}_remaining',
    );
  }

  String _warmupColumn(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return 'warmup_reflect_remaining';
      case GatedFeature.builtDua:
        return 'warmup_built_dua_remaining';
      case GatedFeature.discoverName:
        return 'warmup_discover_name_remaining';
    }
  }

  /// The per-feature warmup counter, plus where it came from.
  ///
  /// `fromStore` is false when no local counter exists yet and the value was
  /// SYNTHESIZED from the [warmupBudgetFor] dial. That distinction is load-
  /// bearing: a synthesized number is a guess about a user whose server row
  /// already holds the truth, and [_decrementWarmup] must not write a guess
  /// back to `user_profiles` (see its `pushToServer` doc).
  Future<({int remaining, bool fromStore})> _readWarmup(
    GatedFeature feature,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_warmupPrefsKey(feature));
    // Short-circuits: once the counter has been written locally (first use, or
    // `hydrateFromProfile` on any sync) the config read never runs.
    if (stored != null) return (remaining: stored, fromStore: true);
    return (remaining: await warmupBudgetFor(feature), fromStore: false);
  }

  Future<int> _readWarmupRemaining(GatedFeature feature) async {
    return (await _readWarmup(feature)).remaining;
  }

  /// [pushToServer] false means [current] was synthesized from the config dial
  /// rather than read from a local counter — so the server's own value is the
  /// only real one and MUST NOT be overwritten.
  ///
  /// Why this matters: the dial (3) is the `reel_v1` number, while every
  /// `legacy`-cohort row still carries the column default 10. A user who
  /// reinstalls, switches accounts, or launches with a batch sync that times
  /// out reaches the gate with no local counter, reads 3 from the dial, and
  /// would push `2` into `user_profiles` — and
  /// `guard_user_profiles_freemium_fields` is decrement-only, so those 8 uses
  /// could never be given back. Skipping the write leaves the server
  /// authoritative; the next `hydrateFromProfile` restores the real number.
  /// The local counter still decrements, so the gate stays consistent for the
  /// rest of the session, and the error direction is one extra free use — the
  /// same fail-OPEN posture as the offline fallback.
  Future<void> _decrementWarmup(
    GatedFeature feature,
    int current, {
    bool pushToServer = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Clamp at zero only. The old upper clamp was the budget constant, which
    // was harmless while the budget was fixed — but once the budget is a
    // server dial, clamping to it would SILENTLY CONFISCATE uses: a user
    // holding 10 remaining (the legacy server default) would drop to 3 on
    // their next use the moment the dial reads 3. Decrement means decrement.
    final next = current > 0 ? current - 1 : 0;
    await prefs.setInt(_warmupPrefsKey(feature), next);

    if (!pushToServer) return;

    final userId = supabaseSyncService.currentUserId;
    if (userId == null) return;
    // user_profiles uses `id` (matching auth.uid()) as its primary key,
    // NOT `user_id`. Use upsertRawRow so `user_id` isn't auto-injected,
    // and pass `id` in the payload so the upsert matches the existing row.
    await supabaseSyncService.upsertRawRow(
      'user_profiles',
      {'id': userId, _warmupColumn(feature): next},
      onConflict: 'id',
    );
  }

  // ---- AI bypass (reserve / commit / cancel) ------------------------------

  /// Reads the local bypass-counter cache for [feature]. Server is the source
  /// of truth — the cache is hydrated on each `sync_all_user_data` and
  /// mutated optimistically by [reserveBypass] / [cancelBypass].
  Future<int> bypassesUsedToday(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.getReflectBypassesUsedToday();
      case GatedFeature.builtDua:
        return daily.getBuiltDuaBypassesUsedToday();
      case GatedFeature.discoverName:
        return daily.getDiscoverNameBypassesUsedToday();
    }
  }

  /// Reserves a bypass on [feature]. Calls the `reserve_ai_bypass` RPC which
  /// atomically debits [bypassTokenCost] tokens, increments the daily bypass
  /// counter, and inserts a pending row in `ai_bypass_reservations`. On
  /// success, returns a [BypassReservation] whose `reservationId` the caller
  /// MUST hold and pass to [commitBypass] (on AI success) or [cancelBypass]
  /// (on AI failure).
  ///
  /// Returns null when:
  /// - The user is premium ([PurchaseService.isPremium] short-circuit — the
  ///   bypass path is a free-tier mechanic).
  /// - The RPC rejects (insufficient tokens, bypass cap reached, bad feature).
  /// - The RPC call itself fails (network, auth). In that case the local
  ///   cache stays untouched — the user can retry.
  ///
  /// TEST-C (defense-in-depth, plan 2026-05-23 line 247): the premium
  /// short-circuit happens BEFORE the RPC fires. Premium users should never
  /// reach this surface — but pinning it at the service layer means a
  /// future UI bug that surfaces the bypass CTA to a premium user cannot
  /// accidentally debit their tokens.
  Future<BypassReservation?> reserveBypass(GatedFeature feature) async {
    if (await PurchaseService().isPremium()) return null;

    // W5 D.4: the bypass does not exist for `reel_v1`. The cap sheet's middle
    // slot is gone for them, so nothing should be calling this — refusing here
    // as well means a stray surface cannot debit a new-cohort user's tokens.
    //
    // Ordered strictly AFTER the premium short-circuit above, which stays the
    // first statement in this function (CLAUDE.md; pinned by TEST-C). Premium
    // must never reach the RPC regardless of cohort, so its check cannot sit
    // behind a cohort read that could answer differently.
    if (await isNewCohort()) return null;

    final featureKey = _bypassFeatureKey(feature);
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'reserve_ai_bypass',
      {
        'p_feature': featureKey,
        'p_idempotency_key': const Uuid().v4(),
      },
    );
    if (result == null) {
      onAnalyticsEvent?.call(AnalyticsEvents.aiBypassRejected, {
        'feature': featureKey,
        'reason': AnalyticsEvents.aiBypassRejectedReasonNetwork,
      });
      return null;
    }
    if (result['ok'] != true) {
      onAnalyticsEvent?.call(AnalyticsEvents.aiBypassRejected, {
        'feature': featureKey,
        'reason': result['reason'] ?? 'unknown',
      });
      return null;
    }

    final reservationId = result['reservation_id'] as String?;
    final balance = (result['balance'] as num?)?.toInt();
    final bypassesUsed = (result['bypasses_used'] as num?)?.toInt();
    final replayed = result['replayed'] == true;
    if (reservationId == null || balance == null || bypassesUsed == null) {
      onAnalyticsEvent?.call(AnalyticsEvents.aiBypassRejected, {
        'feature': featureKey,
        'reason': 'malformed_response',
      });
      return null;
    }

    // Mirror server state into local caches so the next DailyCapSheet build
    // sees the debited balance + incremented counter without a round-trip.
    // Always hydrate the token cache — server's reported balance is the
    // source of truth.
    await tokens.hydrateTokenCache(balance: balance);

    // P2-1 (2026-05-25): only increment the local bypass counter on a TRUE
    // reservation, not a replay. On a replay the original call already
    // incremented the counter; double-incrementing would over-count the
    // local cache. Defense-in-depth against future key-reuse code paths —
    // today's fresh-UUID-per-call flow doesn't trip this branch, but a
    // future caller that retries with the same idempotency key would.
    // See docs/qa/findings/2026-05-24-ai-bypass-p1-p2-review.md (P2-1).
    if (!replayed) {
      await _incrementBypassCache(feature);
    }

    onAnalyticsEvent?.call(AnalyticsEvents.aiBypassPurchased, {
      'feature': featureKey,
      'token_balance_after': balance,
      'bypasses_used_today': bypassesUsed,
    });

    return BypassReservation(
      reservationId: reservationId,
      newBalance: balance,
      bypassesUsedToday: bypassesUsed,
    );
  }

  /// Marks a reservation as committed. Fire-and-forget — failures here are
  /// not surfaced to the user because the server-side orphan-cleanup cron
  /// will NOT touch already-committed reservations, and the orphan window
  /// (15 min) only triggers cancel on `status='pending'` rows. So a missed
  /// commit means: the reservation stays pending in the DB for up to 15 min,
  /// then gets cancelled and tokens get refunded. The user already received
  /// the AI value at that point — they got a free use. Acceptable failure.
  Future<void> commitBypass(String reservationId) async {
    await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'commit_ai_bypass',
      {'p_reservation_id': reservationId},
    );
  }

  /// Cancels a pending reservation. Atomic on the server: flips status,
  /// refunds [bypassTokenCost] tokens, decrements the bypass counter. The
  /// returned bool lets the UI distinguish "cancel succeeded, show refunded
  /// toast" from "cancel failed (network) — orphan cron will rescue within
  /// 15 min, show 'reservation will refund shortly' toast".
  Future<bool> cancelBypass(
    String reservationId,
    GatedFeature feature,
  ) async {
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'cancel_ai_bypass',
      {'p_reservation_id': reservationId},
    );
    if (result == null) return false;
    if (result['ok'] != true) return false;

    final refundedBalance = (result['balance'] as num?)?.toInt();
    if (refundedBalance != null) {
      await tokens.hydrateTokenCache(balance: refundedBalance);
    }
    await _decrementBypassCache(feature);
    return true;
  }

  String _bypassFeatureKey(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return 'reflect';
      case GatedFeature.builtDua:
        return 'built_dua';
      case GatedFeature.discoverName:
        return 'discover_name';
    }
  }

  Future<void> _incrementBypassCache(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.incrementReflectBypassUsage();
      case GatedFeature.builtDua:
        return daily.incrementBuiltDuaBypassUsage();
      case GatedFeature.discoverName:
        return daily.incrementDiscoverNameBypassUsage();
    }
  }

  Future<void> _decrementBypassCache(GatedFeature feature) {
    switch (feature) {
      case GatedFeature.reflect:
        return daily.decrementReflectBypassUsage();
      case GatedFeature.builtDua:
        return daily.decrementBuiltDuaBypassUsage();
      case GatedFeature.discoverName:
        return daily.decrementDiscoverNameBypassUsage();
    }
  }

  // ---- Day-1 freebie (EXP-2 / PR 4 of plan 2026-05-23) -------------------

  /// True when the user is within 24h of signup AND hasn't yet consumed
  /// the global one-shot Day-1 freebie. Drives DailyCapSheet STATE D —
  /// the "One more on us, {name}" gold-accent variant that lets a brand-
  /// new user blow past their first cap-hit without spending tokens.
  ///
  /// Server is the final arbiter — `claim_first_bypass` re-checks the
  /// same predicates inside a `FOR UPDATE` lock so a client whose cache
  /// is stale or has been tampered with cannot double-claim. The cached
  /// flag exists only to render the sheet variant without a round-trip.
  ///
  /// Returns false for: premium users (they never see DailyCapSheet),
  /// users whose signup is unknown (defense against profile corruption),
  /// users past the 24h window, and anyone who has already claimed.
  Future<bool> firstBypassEligible() async {
    if (await PurchaseService().isPremium()) return false;

    // W5 D.4: no bypass for `reel_v1`, so no Day-1 freebie either — STATE D
    // would offer a door that [claimFirstBypass] now refuses to open.
    if (await isNewCohort()) return false;

    final prefs = await SharedPreferences.getInstance();
    final consumed = prefs.getBool(
          supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
        ) ??
        false;
    if (consumed) return false;

    final signupAtIso = prefs.getString(
      supabaseSyncService.scopedKey(_signupAtBaseKey),
    );
    if (signupAtIso == null) return false;

    final signupAt = DateTime.tryParse(signupAtIso);
    if (signupAt == null) return false;

    return signupAt.isAfter(_nowUtc().subtract(const Duration(hours: 24)));
  }

  /// Returns the cached display_name set on `user_profiles`, falling back
  /// to `AuthService.defaultDisplayName` ("Friend"). STATE D renders the
  /// "One more on us, {name}" headline when this is NOT the default —
  /// otherwise it shows "One more on us" so we don't greet someone as
  /// "Friend".
  Future<String> displayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(
          supabaseSyncService.scopedKey(_displayNameBaseKey),
        ) ??
        defaultDisplayName;
  }

  /// One-shot per-user, atomic on the server. Increments the per-feature
  /// bypass counter WITHOUT debiting tokens, flips the consumed latch.
  /// Different shape from [reserveBypass] — no reservation flow because
  /// nothing is at stake (no token spend → nothing to refund on AI failure;
  /// the user just retries the freebie, which is now ineligible — so they
  /// fall back to the normal token-spend bypass on retry).
  ///
  /// Returns true on success (server flipped the flag + incremented the
  /// counter; client caches mirrored). Returns false on any rejection —
  /// the [GatingService.onAnalyticsEvent] hook fires with the typed
  /// reason for funnel attribution.
  Future<bool> claimFirstBypass(GatedFeature feature) async {
    if (await PurchaseService().isPremium()) return false;

    // W5 D.4: removed for `reel_v1`, `claimFirstBypass` included. Refused
    // before the RPC so the one-shot server latch is never burned by a caller
    // that should not have been offered it.
    if (await isNewCohort()) return false;

    final featureKey = _bypassFeatureKey(feature);
    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'claim_first_bypass',
      {'p_feature': featureKey},
    );
    if (result == null) {
      onAnalyticsEvent?.call(AnalyticsEvents.firstBypassRejected, {
        'feature': featureKey,
        'reason': AnalyticsEvents.firstBypassRejectedReasonNetwork,
      });
      return false;
    }
    if (result['ok'] != true) {
      onAnalyticsEvent?.call(AnalyticsEvents.firstBypassRejected, {
        'feature': featureKey,
        'reason': result['reason'] ?? 'unknown',
      });
      return false;
    }

    final bypassesUsed = (result['bypasses_used'] as num?)?.toInt();
    if (bypassesUsed == null) {
      onAnalyticsEvent?.call(AnalyticsEvents.firstBypassRejected, {
        'feature': featureKey,
        'reason': 'malformed_response',
      });
      return false;
    }

    // Mirror server state. Flip the consumed latch so the very next
    // DailyCapSheet render across the app shows STATE A/B/C (not STATE D
    // again), and increment the local bypass counter so the bypass-cap
    // arithmetic stays consistent with the server.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
      true,
    );
    await _incrementBypassCache(feature);

    onAnalyticsEvent?.call(AnalyticsEvents.firstBypassClaimed, {
      'feature': featureKey,
      'bypasses_used_today': bypassesUsed,
    });

    return true;
  }

  /// Lifetime count of COMMITTED bypass purchases (cancelled reservations
  /// never increment). Mirrors `user_profiles.lifetime_bypasses_purchased`
  /// hydrated from `sync_all_user_data`. Used by the IAP→sub upsell banner
  /// to decide whether the user has demonstrated enough IAP velocity to be
  /// worth converting to subscription.
  Future<int> lifetimeBypassesPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(
          supabaseSyncService.scopedKey(_lifetimeBypassesPurchasedBaseKey),
        ) ??
        0;
  }

  /// Returns the cached dismissal timestamp for the IAP→sub upsell banner,
  /// or null if never dismissed. Server is the source of truth (the close-
  /// tap writes via `dismiss_iap_upsell_banner` RPC); this cache exists
  /// only so the banner can decide whether to render without a round-trip.
  Future<DateTime?> iapBannerDismissedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(
      supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
    );
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Returns true when the IAP→sub upsell banner should render. ALL of:
  ///
  ///   * user is NOT premium (premium users are already on the destination
  ///     surface — the banner would be insulting), AND
  ///   * lifetime_bypasses_purchased >= 6 (demonstrated IAP intent), AND
  ///   * days_since_signup >= 7 (don't harass brand-new heavy users), AND
  ///   * (never dismissed OR dismissed > 14 days ago) — re-prompt cadence.
  ///
  /// Defensive: returns false if signup_at is missing or unparseable —
  /// same posture as `firstBypassEligible`. A corrupted profile must not
  /// silently qualify for the upsell.
  Future<bool> iapToSubBannerEligible() async {
    if (await PurchaseService().isPremium()) return false;

    // W5 D.4: retire the trigger for `reel_v1`. The banner's whole premise is
    // "you have bought 6+ bypasses, buy the subscription instead" — a cohort
    // that can never buy a bypass can never mean it, and their
    // `lifetime_bypasses_purchased` is frozen at 0 anyway. Checked explicitly
    // rather than left to the threshold so the intent survives a data import
    // or a cohort migration that carries a non-zero count across.
    if (await isNewCohort()) return false;

    final lifetime = await lifetimeBypassesPurchased();
    if (lifetime < iapToSubBannerLifetimeBypassesThreshold) return false;

    final prefs = await SharedPreferences.getInstance();
    final signupAtIso = prefs.getString(
      supabaseSyncService.scopedKey(_signupAtBaseKey),
    );
    if (signupAtIso == null) return false;
    final signupAt = DateTime.tryParse(signupAtIso);
    if (signupAt == null) return false;

    final now = _nowUtc();
    final daysSinceSignup = now.difference(signupAt).inDays;
    if (daysSinceSignup < iapToSubBannerMinDaysSinceSignup) return false;

    final dismissedAt = await iapBannerDismissedAt();
    if (dismissedAt != null) {
      final age = now.difference(dismissedAt);
      if (age < iapToSubBannerDismissalSuppression) return false;
    }

    return true;
  }

  /// Writes the dismissal timestamp server-side via `dismiss_iap_upsell_banner`
  /// RPC and mirrors it locally. Returns true on RPC success (banner will
  /// suppress for 14 days), false on network/RPC failure (banner stays —
  /// the user can dismiss again on next render).
  ///
  /// Premium users short-circuit to true with no RPC call — the banner is
  /// already hidden for them; nothing to persist.
  Future<bool> dismissIapToSubBanner() async {
    if (await PurchaseService().isPremium()) return true;

    final result = await supabaseSyncService.callRpc<Map<String, dynamic>>(
      'dismiss_iap_upsell_banner',
      const {},
    );
    if (result == null || result['ok'] != true) return false;

    final dismissedAtIso = result['dismissed_at'];
    if (dismissedAtIso is! String) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
      dismissedAtIso,
    );
    return true;
  }

  static const String _firstBypassConsumedBaseKey = 'first_bypass_consumed';
  static const String _signupAtBaseKey = 'signup_at';
  static const String _displayNameBaseKey = 'display_name';
  static const String _lifetimeBypassesPurchasedBaseKey =
      'lifetime_bypasses_purchased';
  static const String _iapBannerDismissedAtBaseKey =
      'iap_upsell_banner_dismissed_at';

  /// IAP→sub upsell threshold — the banner appears once a free user has
  /// committed 6+ paid bypasses lifetime. Pinned in plan; encoded here so a
  /// dashboard tune can move it via constant-flip rather than RPC redeploy.
  static const int iapToSubBannerLifetimeBypassesThreshold = 6;

  /// Days-since-signup floor — don't harass brand-new heavy IAP users. A user
  /// who hits 6 bypasses in their first week is already on the consideration
  /// path; surfacing the upsell on Day 8 lets the natural friction land first.
  static const int iapToSubBannerMinDaysSinceSignup = 7;

  /// Suppression window after the user dismisses the banner. Re-shows after
  /// 14 days if they're still ineligible-by-IAP-velocity for premium. CEO
  /// review's cadence — long enough not to annoy, short enough not to forget.
  static const Duration iapToSubBannerDismissalSuppression =
      Duration(days: 14);

  /// Fallback display name — mirrors `AuthService.defaultDisplayName`.
  /// Kept in lockstep here so gating_service doesn't take a dependency on
  /// auth_service for a single 6-char string. Pinned by widget test.
  static const String defaultDisplayName = 'Friend';

  /// Test seam for the 24h Day-1 window. Production reads UTC `now()`.
  @visibleForTesting
  static DateTime Function()? debugNowUtc;
  DateTime _nowUtc() => (debugNowUtc ?? () => DateTime.now().toUtc())();

  // ---- had_trial latch ----------------------------------------------------

  /// Shared SharedPreferences base key for the had_trial latch. Both
  /// [PurchaseService.hadTrial] (writer) and [_readHadTrial] (reader) MUST use
  /// the same key — declared here as the single source of truth.
  static const String hadTrialPrefsBaseKey = 'had_trial';

  static const String _hadTrialBaseKey = hadTrialPrefsBaseKey;

  Future<bool> _readHadTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final scoped =
        supabaseSyncService.scopedKey(_hadTrialBaseKey);
    return prefs.getBool(scoped) ?? false;
  }

  // ---- hydration ----------------------------------------------------------

  /// Hydrates the per-user warmup counters and `had_trial` latch from the
  /// `profile` section of the `sync_all_user_data` RPC payload. Called by
  /// `user_data_batch_sync_service` on app launch and any subsequent re-sync.
  ///
  /// Without this, fresh installs (or re-installs / multi-device users) would
  /// show their local default values (the [warmupBudgetFor] dial,
  /// had_trial=false) even when the server says otherwise — letting a lapsed trialer get a fresh
  /// warmup budget by reinstalling the app.
  Future<void> hydrateFromProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();

    final warmupKeys = <GatedFeature, String>{
      GatedFeature.reflect: 'warmup_reflect_remaining',
      GatedFeature.builtDua: 'warmup_built_dua_remaining',
      GatedFeature.discoverName: 'warmup_discover_name_remaining',
    };
    for (final entry in warmupKeys.entries) {
      final raw = profile[entry.value];
      if (raw is num) {
        await prefs.setInt(_warmupPrefsKey(entry.key), raw.toInt());
      }
    }

    // Free-tier cohort (W5 D.2/D.3/D.4). Server-assigned in `handle_new_user`,
    // never client-writable, returned by `sync_all_user_data` since
    // `20260727100300`. Only ever WRITTEN from the server's own value — this
    // is the whole provenance rule: the cohort selects which economy applies,
    // so a locally-guessed one would silently move a user between tiers.
    //
    // An absent / null / unrecognised value CLEARS the cache rather than
    // leaving a stale one. A pre-`20260727100300` backend and a genuine
    // legacy account both land on "not reel_v1", which is the generous
    // default `isNewCohort` documents.
    final cohortRaw = profile['free_tier_cohort'];
    if (cohortRaw == cohortReelV1) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_freeTierCohortBaseKey),
        cohortReelV1,
      );
    } else {
      await prefs.remove(
        supabaseSyncService.scopedKey(_freeTierCohortBaseKey),
      );
    }

    // Weekly pool (reel_v1). Both values are the server's own columns — no
    // derivation, no guess — and the pair is written together so the count is
    // never readable without the week marker that dates it. `week_start`
    // arrives as `YYYY-MM-DD` (a Postgres `date`), the same shape
    // [_localWeekStart] produces and [weeklyPoolRemaining] compares against.
    final poolUsedRaw = profile['weekly_pool_used'];
    if (poolUsedRaw is num) {
      await prefs.setInt(
        supabaseSyncService.scopedKey(_weeklyPoolUsedBaseKey),
        poolUsedRaw.toInt(),
      );
    }
    final poolWeekRaw = profile['weekly_pool_week_start'];
    if (poolWeekRaw is String && poolWeekRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_weeklyPoolWeekStartBaseKey),
        // Tolerate a full timestamp if the column shape ever widens.
        poolWeekRaw.length >= 10 ? poolWeekRaw.substring(0, 10) : poolWeekRaw,
      );
    } else if (poolWeekRaw == null) {
      // Never consumed (or a pre-`20260727100300` backend): drop the marker so
      // the pool reads full rather than inheriting another week's count.
      await prefs.remove(
        supabaseSyncService.scopedKey(_weeklyPoolWeekStartBaseKey),
      );
    }

    final hadTrialRaw = profile['had_trial'];
    if (hadTrialRaw is bool) {
      await prefs.setBool(
        supabaseSyncService.scopedKey(_hadTrialBaseKey),
        hadTrialRaw,
      );
    }

    // Day-1 freebie hydration (PR 4 of plan 2026-05-23). Server is the
    // source of truth for both fields; absence in the payload means a
    // pre-PR4 backend — leave the cache untouched so the gate falls
    // back to "ineligible" (default false) rather than silently flipping
    // a flag the server can't validate.
    final firstBypassConsumedRaw = profile['first_bypass_consumed'];
    if (firstBypassConsumedRaw is bool) {
      await prefs.setBool(
        supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
        firstBypassConsumedRaw,
      );
    }

    final createdAtRaw = profile['created_at'];
    if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_signupAtBaseKey),
        createdAtRaw,
      );
    }

    final displayNameRaw = profile['display_name'];
    if (displayNameRaw is String && displayNameRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_displayNameBaseKey),
        displayNameRaw,
      );
    }

    // EXP-3 IAP→sub upsell banner hydration (PR 5 of plan 2026-05-23). Server
    // is the source of truth: `lifetime_bypasses_purchased` is incremented by
    // `commit_ai_bypass` RPC; `iap_upsell_banner_dismissed_at` by the
    // `dismiss_iap_upsell_banner` RPC.
    final lifetimeBypassesRaw = profile['lifetime_bypasses_purchased'];
    if (lifetimeBypassesRaw is num) {
      await prefs.setInt(
        supabaseSyncService.scopedKey(_lifetimeBypassesPurchasedBaseKey),
        lifetimeBypassesRaw.toInt(),
      );
    }

    final iapDismissedAtRaw = profile['iap_upsell_banner_dismissed_at'];
    if (iapDismissedAtRaw is String && iapDismissedAtRaw.isNotEmpty) {
      await prefs.setString(
        supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
        iapDismissedAtRaw,
      );
    } else if (iapDismissedAtRaw == null) {
      // Server says never dismissed (or pre-PR5 backend): clear the local
      // cache so a stale dismissal can't keep the banner suppressed forever
      // after an admin reset.
      await prefs.remove(
        supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
      );
    }

    // Signal listeners (currently: the IAP→sub banner provider) that the
    // per-user cache is fresh and they should re-evaluate. See the
    // [onProfileHydrated] docstring for the why.
    onProfileHydrated?.call();
  }

  // ---- test helpers -------------------------------------------------------

  /// Resets per-user gating state. Test-only.
  @visibleForTesting
  Future<void> debugResetForUser() async {
    final prefs = await SharedPreferences.getInstance();
    for (final f in GatedFeature.values) {
      await prefs.remove(_warmupPrefsKey(f));
    }
    await prefs.remove(supabaseSyncService.scopedKey(_hadTrialBaseKey));
    await prefs.remove(
      supabaseSyncService.scopedKey(_firstBypassConsumedBaseKey),
    );
    await prefs.remove(supabaseSyncService.scopedKey(_signupAtBaseKey));
    await prefs.remove(supabaseSyncService.scopedKey(_displayNameBaseKey));
    await prefs.remove(
      supabaseSyncService.scopedKey(_lifetimeBypassesPurchasedBaseKey),
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_iapBannerDismissedAtBaseKey),
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_freeTierCohortBaseKey),
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_weeklyPoolUsedBaseKey),
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_weeklyPoolWeekStartBaseKey),
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_weeklyPoolProbeDayBaseKey),
    );
  }

  /// Force the cached weekly-pool state for tests. `weekStart` is `YYYY-MM-DD`;
  /// null clears the marker (the never-consumed case). Also clears the
  /// stale-week probe marker, so a test that pins a week starts from "the
  /// server has not been asked yet".
  @visibleForTesting
  Future<void> debugSetWeeklyPool({
    required int used,
    String? weekStart,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      supabaseSyncService.scopedKey(_weeklyPoolUsedBaseKey),
      used,
    );
    await prefs.remove(
      supabaseSyncService.scopedKey(_weeklyPoolProbeDayBaseKey),
    );
    final key = supabaseSyncService.scopedKey(_weeklyPoolWeekStartBaseKey);
    if (weekStart == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, weekStart);
    }
  }

  /// Force the free-tier cohort for tests. `null` clears it (the
  /// unknown-cohort case [isNewCohort] must answer `false` for).
  @visibleForTesting
  Future<void> debugSetCohort(String? cohort) async {
    final prefs = await SharedPreferences.getInstance();
    final key = supabaseSyncService.scopedKey(_freeTierCohortBaseKey);
    if (cohort == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, cohort);
    }
  }

  /// Force a specific warmup remaining count for tests.
  @visibleForTesting
  Future<void> debugSetWarmupRemaining(GatedFeature feature, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_warmupPrefsKey(feature), value);
  }

  /// Force the had_trial latch on (test-only).
  @visibleForTesting
  Future<void> debugSetHadTrial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      supabaseSyncService.scopedKey(_hadTrialBaseKey),
      value,
    );
  }
}
