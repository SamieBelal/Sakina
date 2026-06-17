import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/gift_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseService {
  PurchaseService._();

  @visibleForTesting
  PurchaseService.test();

  static final PurchaseService instance = PurchaseService._();

  factory PurchaseService() => _debugOverride ?? instance;

  static PurchaseService? _debugOverride;

  bool _initialized = false;
  Future<void>? _initializationFuture;

  Future<void> initialize({
    required String appleApiKey,
    required String googleApiKey,
  }) async {
    if (_initialized) return;

    final apiKey = _platformApiKey(
      appleApiKey: appleApiKey,
      googleApiKey: googleApiKey,
    );
    if (apiKey.isEmpty) return;

    final inFlightInitialization = _initializationFuture;
    if (inFlightInitialization != null) {
      await inFlightInitialization;
      return;
    }

    final completer = Completer<void>();
    _initializationFuture = completer.future;

    try {
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _initialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _initializationFuture = null;
    }
  }

  /// Base SharedPreferences key for the cached `referral_premium_until` ISO
  /// string. Scoped to the user via [SupabaseSyncService.scopedKey] before
  /// read/write so a shared device doesn't bleed referral premium across
  /// accounts.
  @visibleForTesting
  static const String referralPremiumUntilPrefsBaseKey =
      'referral_premium_until';

  /// Base SharedPreferences key for the cached `trial_premium_until` ISO
  /// string (the reverse-trial source). Scoped to the user via
  /// [SupabaseSyncService.scopedKey] before read/write so a shared device
  /// doesn't bleed trial premium across accounts. Sibling to
  /// [referralPremiumUntilPrefsBaseKey] / [giftPremiumUntilPrefsBaseKey];
  /// populated by [refreshTrialPremiumCache] and OR'd into [isPremium].
  ///
  /// NOT `@visibleForTesting` (unlike the referral key): the reverse-trial
  /// resume re-check in `trial_expiry_service.dart` reads this scoped key from
  /// production code, mirroring [giftPremiumUntilPrefsBaseKey]'s cross-service
  /// visibility.
  static const String trialPremiumUntilPrefsBaseKey = 'trial_premium_until';

  /// True iff any premium source is active: Sakina Gift window, RevenueCat
  /// `premium` entitlement, the local referral-premium cache, or the local
  /// reverse-trial cache.
  ///
  /// Order matters:
  /// 1. Gift check first — reads SharedPrefs only, doesn't require RC init,
  ///    so a kill-switched / not-yet-initialized RC build still honors an
  ///    active gift.
  /// 2. RC entitlement next — authoritative billing source when initialized.
  /// 3. Referral cache, then trial cache last — SharedPrefs only, populated at
  ///    deterministic refresh moments (auth foreground, post-signup, post-RPC,
  ///    app-resume) via [refreshReferralPremiumCache] / [refreshTrialPremiumCache].
  ///
  /// Hot-path constraint: called from 8+ providers / services on every render
  /// pass. None of the gift / referral / trial paths hit Supabase from the hot
  /// path — all read user-scoped SharedPreferences.
  Future<bool> isPremium() async {
    if (await _isGiftPremium()) return true;
    if (_initialized) {
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        if (customerInfo.entitlements.active.containsKey('premium')) {
          return true;
        }
      } catch (_) {
        // Fall through to referral / trial check.
      }
    }
    if (await _isTimedPremium(referralPremiumUntilPrefsBaseKey)) return true;
    return _isTimedPremium(trialPremiumUntilPrefsBaseKey);
  }

  /// Shared timed-premium predicate for the SharedPreferences-cached server
  /// columns (referral / trial). Reads the user-scoped [prefKey] ONLY — never
  /// Supabase from the hot path — and returns true when the cached ISO is in
  /// the future relative to [now]. The gift source has its own
  /// [GiftService.currentClock]-driven variant ([_isGiftPremium]); referral and
  /// trial both share this helper (no third copy).
  ///
  /// [now] defaults to `DateTime.now().toUtc()`; the comparison is timezone-
  /// stable because Supabase timestamptz ISO strings carry an explicit offset
  /// that `DateTime.parse` resolves.
  Future<bool> _isTimedPremium(
    String prefKey, {
    DateTime Function()? now,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iso = prefs.getString(supabaseSyncService.scopedKey(prefKey));
      if (iso == null || iso.isEmpty) return false;
      // DateTime.parse handles all the timestamptz ISO shapes Supabase emits:
      //   "2026-06-13T12:34:56.789+00:00", "2026-06-13T12:34:56Z", etc.
      final clock = (now ?? () => DateTime.now().toUtc())();
      return DateTime.parse(iso).isAfter(clock);
    } catch (_) {
      // SharedPreferences unavailable or unparseable ISO — treat as not
      // premium (fall through to the next source in isPremium()).
      return false;
    }
  }

  /// Fetches [column] from `user_profiles` and writes it into the user-scoped
  /// [prefKey] cache. Shared writer for the referral / trial timed-premium
  /// columns (no third copy). Best-effort — silently swallows network errors;
  /// a stale cache is acceptable until the next refresh moment.
  Future<void> refreshTimedPremiumCache(String prefKey, String column) async {
    final uid = _safeCurrentUserId();
    if (uid == null || uid.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select(column)
          .eq('id', uid)
          .maybeSingle();
      final iso = row?[column] as String?;
      final prefs = await SharedPreferences.getInstance();
      final scopedKey = supabaseSyncService.scopedKey(prefKey);
      if (iso == null) {
        await prefs.remove(scopedKey);
      } else {
        await prefs.setString(scopedKey, iso);
      }
    } catch (_) {
      // Best-effort; next refresh moment will retry.
    }
  }

  /// Fetches `referral_premium_until` from Supabase and updates the local
  /// cache. Call at: app foreground (authenticated), after
  /// [OnboardingNotifier.completeOnboarding], after `apply_referral` /
  /// `confirm_referral_if_pending` RPC returns.
  Future<void> refreshReferralPremiumCache() => refreshTimedPremiumCache(
        referralPremiumUntilPrefsBaseKey,
        'referral_premium_until',
      );

  /// Fetches `trial_premium_until` from Supabase and updates the local cache
  /// (the reverse-trial source). Call at: app foreground (authenticated),
  /// app-resume + home-load (so a just-expired Day-3 trial is detected
  /// promptly — see the reverse-trial ADR resume re-check), and immediately
  /// after `activate_trial` returns. Best-effort — sibling to
  /// [refreshReferralPremiumCache].
  Future<void> refreshTrialPremiumCache() => refreshTimedPremiumCache(
        trialPremiumUntilPrefsBaseKey,
        'trial_premium_until',
      );

  String? _safeCurrentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Fetches `user_profiles.gift_premium_until` from Supabase and updates the
  /// local cache. Sibling to [refreshReferralPremiumCache] — call at the same
  /// moments (app foreground while authenticated, after signup) so
  /// cross-device sign-in restores gift entitlement without requiring the
  /// user to re-tap Accept.
  ///
  /// Best-effort — silently swallows network errors. Next refresh moment will
  /// retry.
  Future<void> refreshGiftPremiumCache() async {
    final uid = _safeCurrentUserId();
    if (uid == null || uid.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('user_profiles')
          .select('gift_premium_until')
          .eq('id', uid)
          .maybeSingle();
      final iso = row?['gift_premium_until'] as String?;
      final prefs = await SharedPreferences.getInstance();
      final scopedKey =
          supabaseSyncService.scopedKey(giftPremiumUntilPrefsBaseKey);
      if (iso == null) {
        await prefs.remove(scopedKey);
      } else {
        await prefs.setString(scopedKey, iso);
      }
    } catch (_) {
      // Best-effort; next refresh moment will retry.
    }
  }

  /// Returns true when the current user has an active Sakina Gift window —
  /// i.e. SharedPrefs holds a `gift_premium_until:<uid>` timestamp in the
  /// future relative to [GiftService.debugGiftClock].
  ///
  /// The SharedPrefs cache is populated by `GiftService.claim()` at claim
  /// time. user_profiles.gift_premium_until on the server is authoritative;
  /// the cache is best-effort for cold-launch entitlement checks without a
  /// network round-trip.
  ///
  /// Sibling to the [_isReferralPremium] path. Kept structurally separate so
  /// refer-unlock and gift unlock can be reasoned about independently and so
  /// analytics can attribute "what kept premium on" when both paths overlap.
  Future<bool> _isGiftPremium() => _isTimedPremium(
        giftPremiumUntilPrefsBaseKey,
        // Gift honors the [GiftService.debugGiftClock] seam so QA can fast-
        // forward into / out of a seeded occasion window. `now` is compared
        // with `cachedIso.isAfter(now)`, equivalent to the prior
        // `currentClock().isBefore(until)`.
        now: GiftService.currentClock,
      );

  /// Returns the ISO-8601 timestamp when RevenueCat last detected a billing
  /// issue on the user's `premium` entitlement, or `null` if payment is
  /// healthy or the user is not subscribed.
  ///
  /// We read `entitlements.active` (not `.all`) because RevenueCat keeps
  /// grace-period entitlements in `.active` by design — that is how the
  /// "still has premium but payment is failing" state is represented.
  /// `.all` additionally contains long-expired entitlements, which would
  /// cause the billing banner to stick around for users whose subs lapsed
  /// months ago.
  Future<String?> getBillingIssueDetectedAt() async {
    if (!_initialized) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final premium = customerInfo.entitlements.active['premium'];
      return premium?.billingIssueDetectedAt;
    } catch (_) {
      return null;
    }
  }

  /// Snapshot of a *voluntary* cancellation read from the client
  /// `entitlements.all['premium']`. Powers the instant survey shown right after
  /// the in-app Customer Center sheet closes (Flutter exposes no cancel
  /// callback, so we await its dismissal then re-read).
  ///
  /// Returns null unless the premium entitlement is cancelled (`willRenew ==
  /// false` with an `unsubscribeDetectedAt`), is NOT a billing failure, and has
  /// a known `expirationDate` — `expirationDate` is the dedupe key shared with
  /// the server `user_subscriptions.expires_at`.
  ///
  /// Pass [forceRefresh] (the instant path does) to invalidate the up-to-5-min
  /// customerInfo cache before reading, so a just-completed cancel is seen.
  Future<
      ({
        DateTime expiresAt,
        DateTime? canceledAt,
        String? periodType,
      })?> getVoluntaryCancellation({bool forceRefresh = false}) async {
    if (!_initialized) return null;
    try {
      if (forceRefresh) {
        await Purchases.invalidateCustomerInfoCache();
      }
      final customerInfo = await Purchases.getCustomerInfo();
      final premium = customerInfo.entitlements.all['premium'];
      if (premium == null) return null;
      if (premium.willRenew) return null;
      if (premium.unsubscribeDetectedAt == null) return null;
      if (premium.billingIssueDetectedAt != null) return null;

      final expiresAt = DateTime.tryParse(premium.expirationDate ?? '');
      if (expiresAt == null) return null;

      return (
        expiresAt: expiresAt,
        canceledAt: DateTime.tryParse(premium.unsubscribeDetectedAt ?? ''),
        periodType: premium.periodType == PeriodType.trial
            ? 'trial'
            : premium.periodType == PeriodType.intro
                ? 'intro'
                : 'normal',
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the user has ever had a premium trial period — active or
  /// expired. One-way latch: once true, it stays true forever for this user
  /// (so the gating layer can apply lapsed-trialer rules without depending on
  /// RevenueCat history at every check).
  ///
  /// Reads `customerInfo.entitlements.all['premium'].periodType` and treats
  /// `PeriodType.trial` as a positive signal. Active paid subscriptions
  /// converted from a prior trial generally still report `periodType=trial`
  /// only during the trial window, but RevenueCat keeps the historical
  /// entitlement under `.all` so the latch fires on the first observation.
  ///
  /// IDEMPOTENT: once the local SharedPreferences flag is `true`, this method
  /// short-circuits and avoids both a RevenueCat round-trip and a Supabase
  /// write. That matters because RC reports a trial period for every paid
  /// trialer on every app launch — without the latch we'd write to Supabase
  /// on every launch.
  Future<bool> hadTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final scopedKey =
        supabaseSyncService.scopedKey(GatingService.hadTrialPrefsBaseKey);
    final cached = prefs.getBool(scopedKey);
    if (cached == true) return true;

    if (!_initialized) return false;

    final detected = await _detectTrialFromRevenueCat();
    if (!detected) return false;

    // First-time detection: persist locally + remotely. user_profiles uses
    // `id` (matching auth.uid()) as its primary key, NOT `user_id` — so we
    // use upsertRawRow which doesn't inject `user_id`. Including `id` in the
    // payload lets the upsert match on the existing row instead of trying
    // to insert a duplicate.
    await prefs.setBool(scopedKey, true);

    final userId = supabaseSyncService.currentUserId;
    if (userId != null) {
      await supabaseSyncService.upsertRawRow(
        'user_profiles',
        {'id': userId, 'had_trial': true},
        onConflict: 'id',
      );
    }
    return true;
  }

  Future<bool> _detectTrialFromRevenueCat() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final premium = customerInfo.entitlements.all['premium'];
      if (premium == null) return false;
      return premium.periodType == PeriodType.trial;
    } catch (_) {
      return false;
    }
  }

  /// When the user's RevenueCat `premium` entitlement FIRST began
  /// (`originalPurchaseDate`), or null when there is no active RC premium.
  ///
  /// Audience helper for the home referral nudge. Reads `entitlements.active`
  /// so it covers trial AND paid subscribers, and deliberately EXCLUDES
  /// gift/referral premium — those are never RC entitlements (they're separate
  /// `user_profiles` columns OR'd in by [isPremium]), so a user whose premium
  /// came *from* referrals reads null here and never gets nudged to refer.
  ///
  /// Uses `originalPurchaseDate` (first time premium began) rather than
  /// `latestPurchaseDate` (resets on every renewal) so a monthly subscriber
  /// isn't repeatedly re-gated after each renewal and a long-time subscriber
  /// reads as well past any grace window.
  ///
  /// Returns null when RC isn't initialized, no active premium exists, or the
  /// timestamp is missing/unparseable — all of which the caller treats as
  /// "not eligible, render nothing".
  Future<DateTime?> getActivePremiumStartedAt() async {
    if (!_initialized) return null;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final premium = customerInfo.entitlements.active['premium'];
      if (premium == null) return null;
      return DateTime.tryParse(premium.originalPurchaseDate);
    } catch (_) {
      return null;
    }
  }

  Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];

    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? [];
    // Defense-in-depth: even if the RC dashboard's `default` offering is
    // misconfigured with a monthly package, the client never surfaces it.
    // Weekly + annual only — 2026 research shows monthly cannibalizes
    // annual LTV without lifting trial-start rate. The paywall screen
    // already picks by PackageType, but defending at the service boundary
    // protects every future consumer (winback sheets, debug surfaces, A/B
    // variants) without each having to remember the rule.
    return packages.where((p) {
      return p.packageType != PackageType.monthly &&
          p.packageType != PackageType.twoMonth &&
          p.packageType != PackageType.threeMonth &&
          p.packageType != PackageType.sixMonth;
    }).toList();
  }

  /// Returns packages from the `consumables` offering — the token and scroll
  /// SKUs the Store screen sells. Lives in a non-current offering on purpose:
  /// the paywall reads `offerings.current` (subscriptions only), and mixing
  /// consumables into that offering would surface them on the paywall.
  ///
  /// Returns an empty list when the SDK isn't initialized or when the
  /// `consumables` offering is missing — callers handle the empty case as
  /// "pack not available" rather than crashing.
  Future<List<Package>> getConsumablePackages() async {
    if (!_initialized) return [];

    final offerings = await Purchases.getOfferings();
    return offerings.all['consumables']?.availablePackages ?? [];
  }

  /// Purchases a subscription package and returns `true` if the `premium`
  /// entitlement is now active. Use this for the paywall; subscriptions
  /// flip the entitlement on success.
  ///
  /// Includes a single fallback fetch via [Purchases.getCustomerInfo] when
  /// the immediate `customerInfo` from `purchasePackage` doesn't yet show
  /// `premium` active. RevenueCat's docs say the post-purchase customerInfo
  /// is current, but Apple's server-to-server validation can lag in rare
  /// cases — surfacing a false "purchase failed" then leads to a retry +
  /// double-charge attempt. The fallback closes that window. If the
  /// fallback also returns no entitlement, treat as genuinely failed.
  Future<bool> purchaseSubscription(Package package) async {
    _assertInitialized();
    final customerInfo = await Purchases.purchasePackage(package);
    if (customerInfo.entitlements.active.containsKey('premium')) {
      return true;
    }
    try {
      final fresh = await Purchases.getCustomerInfo();
      return fresh.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  /// Purchases a consumable package (tokens, scrolls) and returns the fresh
  /// [CustomerInfo] that StoreKit + RevenueCat produced for the transaction.
  /// RevenueCat's contract is throw-on-failure (cancellation, payment
  /// error) and return-on-success, so reaching the return statement means
  /// the user has been charged and `customerInfo.nonSubscriptionTransactions`
  /// contains the just-completed transaction.
  ///
  /// Consumables do NOT flip any entitlement, so the entitlement check used
  /// by [purchaseSubscription] is wrong here and would silently skip the
  /// local grant — that was the 2026-04-26 P0 bug.
  ///
  /// Callers MUST pass the returned [CustomerInfo] to
  /// `ConsumableGrantsService.grantForMostRecentPurchase` — otherwise the
  /// service re-fetches via `Purchases.getCustomerInfo()`, which races
  /// with RC's internal cache update and often returns stale data,
  /// reproducing the 2026-04-28 stale-balance bug.
  Future<CustomerInfo> purchaseConsumable(Package package) async {
    _assertInitialized();
    return await Purchases.purchasePackage(package);
  }

  /// Restores previous purchases and returns `true` if the `premium`
  /// entitlement is now active.
  Future<bool> restorePurchases() async {
    _assertInitialized();
    final customerInfo = await Purchases.restorePurchases();
    return customerInfo.entitlements.active.containsKey('premium');
  }

  /// Identifies the user to RevenueCat. No-op when already logged in with the
  /// same id — this matters because Supabase's `tokenRefreshed` event fires
  /// roughly hourly while the app is running; without the guard, each refresh
  /// would trigger a `Purchases.logIn` backend round-trip and a redundant
  /// `CustomerInfo` listener update.
  Future<void> setUserId(String userId) async {
    if (!_initialized || userId.isEmpty) return;

    try {
      final current = await Purchases.appUserID;
      if (current == userId) return;
    } catch (_) {
      // Fall through to logIn if the current id can't be read.
    }

    await Purchases.logIn(userId);
  }

  String _platformApiKey({
    required String appleApiKey,
    required String googleApiKey,
  }) {
    if (Platform.isIOS) return appleApiKey;
    if (Platform.isAndroid) return googleApiKey;
    return '';
  }

  void _assertInitialized() {
    if (_initialized) return;
    throw StateError('RevenueCat has not been initialized.');
  }

  @visibleForTesting
  static void debugSetOverride(PurchaseService service) {
    _debugOverride = service;
  }

  @visibleForTesting
  static void debugClearOverride() {
    _debugOverride = null;
  }

  @visibleForTesting
  void debugMarkInitialized({bool initialized = true}) {
    _initialized = initialized;
  }
}
