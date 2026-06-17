import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/onboarding/onboarding_stage.dart';
import '../features/tour/providers/onboarding_tour_controller.dart'
    show onboardingTourSeenFlag;
import '../services/app_config_service.dart';
import '../services/auth_service.dart';
import '../services/consumable_grants_service.dart';
import '../services/launch_gate_service.dart';
import '../widgets/achievement_toast.dart';
import '../services/notification_service.dart';
import '../services/onboarding_gate_service.dart';
import '../services/purchase_service.dart';
import '../services/referral_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/user_data_batch_sync_service.dart';

/// Server kill switch key for the new onboarding → tour → hard-paywall gate.
/// Read via [AppConfigService]; defaults OFF so the gate is dark until the flag
/// is flipped on server-side (phased rollout / instant rollback).
const String kHardPaywallAfterTourFlag = 'hard_paywall_after_tour_enabled';

/// Server `app_config` key for the new post-tour paywall MODE (reverse-trial
/// Phase A): one of `off` | `soft` | `hard`. Replaces the overloaded
/// [kHardPaywallAfterTourFlag] boolean. When absent, the mode is derived from
/// the legacy boolean for back-compat (true → hard, false → off) so today's
/// live behaviour is preserved until the new key is set server-side.
const String kPostTourPaywallModeFlag = 'post_tour_paywall_mode';

/// Single source of truth for auth + onboarding state.
/// Used as GoRouter's refreshListenable — redirect reads from this.
class AppSessionNotifier extends ChangeNotifier {
  /// Static hook to reset analytics identity on sign-out. This notifier has no
  /// Riverpod access, so main.dart wires this to `AnalyticsService.reset` the
  /// same way the other service-layer telemetry hooks are bridged. Left null in
  /// tests (best-effort — a null hook is a no-op). Resets Mixpanel's distinct_id
  /// so the next user to sign in on a shared/QA device doesn't inherit the
  /// previous user's identity (cross-user contamination).
  static void Function()? onAnalyticsReset;

  AppSessionNotifier({
    AuthService? authService,
    NotificationService? notificationService,
    required bool initialOnboarded,
    Stream<AuthState>? authStateChanges,
    bool Function()? isAuthenticatedProvider,
    String? Function()? currentUserIdProvider,
    Future<void> Function()? hydrateEconomyCache,
    Future<bool> Function()? hasCompletedOnboarding,
    Future<bool> Function()? isPremiumReader,
    Future<bool> Function()? hardPaywallFlowReader,
    Future<PostTourPaywallMode> Function()? postTourPaywallModeReader,
    Duration? hydrationTimeout,
  })  : _hasOnboarded = initialOnboarded,
        _notificationService = notificationService ?? NotificationService(),
        _isAuthenticatedProvider = isAuthenticatedProvider ??
            (() => Supabase.instance.client.auth.currentUser != null),
        _currentUserIdProvider = currentUserIdProvider ?? _defaultCurrentUserId,
        _hydrateEconomyCache = hydrateEconomyCache ?? _defaultHydrate,
        _hasCompletedOnboarding = hasCompletedOnboarding ??
            authService?.hasCompletedOnboarding ??
            (() async => false),
        _isPremiumReader = isPremiumReader ?? _defaultIsPremium,
        _hardPaywallFlowReader =
            hardPaywallFlowReader ?? _defaultHardPaywallFlow,
        _hydrationTimeout = hydrationTimeout ?? const Duration(seconds: 30) {
    // The mode reader defaults to a derivation over THIS session's hard-flow
    // reader, so legacy `hardPaywallFlowReader`-only callers (incl. tests) keep
    // their hard/off behaviour: `post_tour_paywall_mode` string wins, else the
    // injected legacy boolean (`true → hard`, `false → off`).
    _postTourPaywallModeReader =
        postTourPaywallModeReader ?? _derivePostTourPaywallMode;
    _subscription =
        (authStateChanges ?? Supabase.instance.client.auth.onAuthStateChange)
            .listen(_onAuthChange);
  }

  late final StreamSubscription<AuthState> _subscription;
  final NotificationService _notificationService;
  final bool Function() _isAuthenticatedProvider;
  final String? Function() _currentUserIdProvider;
  final Future<void> Function() _hydrateEconomyCache;
  final Future<bool> Function() _hasCompletedOnboarding;
  final Future<bool> Function() _isPremiumReader;
  final Future<bool> Function() _hardPaywallFlowReader;
  late final Future<PostTourPaywallMode> Function() _postTourPaywallModeReader;
  final Duration _hydrationTimeout;
  bool _hasOnboarded;

  bool get isAuthenticated => _isAuthenticatedProvider();
  bool get hasOnboarded => _hasOnboarded;

  // ---------------------------------------------------------------------------
  // Onboarding gate flags — synchronously readable by the GoRouter redirect.
  //
  // All default to the "ungated" value (tour done, wall cleared, flow off) so a
  // returning/existing user is NEVER flashed into the tour or the wall before
  // [hydrateOnboardingGate] resolves real values. A brand-new user is put INTO
  // the gate explicitly by [enterOnboardingGate] from completeOnboarding.
  // ---------------------------------------------------------------------------
  bool _tourCompleted = true;
  bool _paywallCleared = true;
  bool _isPremiumCached = false;
  bool _hardPaywallFlowEnabled = false;
  // Defaults to `off` — the ungated value, mirroring `_hardPaywallFlowEnabled`'s
  // `false`. A returning/existing user is never flashed into a post-tour gate
  // before [hydrateOnboardingGate] resolves the real mode.
  PostTourPaywallMode _postTourPaywallMode = PostTourPaywallMode.off;

  bool get tourCompleted => _tourCompleted;
  bool get paywallCleared => _paywallCleared;
  bool get isPremiumCached => _isPremiumCached;
  bool get hardPaywallFlowEnabled => _hardPaywallFlowEnabled;

  /// The effective post-tour paywall mode (reverse-trial Phase A). Derived from
  /// the `post_tour_paywall_mode` app_config string, falling back to the legacy
  /// `hard_paywall_after_tour_enabled` boolean. Read synchronously by the
  /// GoRouter redirect to decide between the hard wall, the soft paywall, or
  /// straight-through.
  PostTourPaywallMode get postTourPaywallMode => _postTourPaywallMode;

  /// Session-only escape used by the offerings-load-failure safety valve. When
  /// the hard wall can't load plans (StoreKit/Apple outage) and the user taps
  /// "Continue", we let them into the app for THIS session WITHOUT persisting
  /// the durable [paywallCleared] latch — so the next cold launch re-walls them
  /// once offerings can load. In-memory only; reset on sign-out and never saved.
  bool _gateValveBypass = false;
  bool get gateValveBypass => _gateValveBypass;
  void bypassGateForSession() {
    if (_gateValveBypass) return;
    _gateValveBypass = true;
    notifyListeners();
  }

  /// Loads the gate flags from local caches + the kill switch. Safe to call
  /// repeatedly; each external read is independently guarded so one failure
  /// can't strand the others. Fires [notifyListeners] so the router re-runs
  /// its redirect against fresh values.
  Future<void> hydrateOnboardingGate() async {
    final uid = _currentUserIdProvider();
    if (uid != null && uid.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _tourCompleted = prefs.getBool(onboardingTourSeenFlag(uid)) ?? false;
      } catch (_) {/* keep default */}
      try {
        _paywallCleared = await OnboardingGateService().isPaywallCleared();
      } catch (_) {/* keep default */}
    }
    // Read the gate-critical flag (cached app_config, fast) BEFORE the premium
    // check (a potentially-slow RevenueCat round-trip). progress_screen's
    // tour-start and the router both read `hardPaywallFlowEnabled` directly, so
    // it must be set ASAP; the premium short-circuit can hydrate a beat later
    // (a non-premium new user's `false` default is correct until then).
    try {
      _hardPaywallFlowEnabled = await _hardPaywallFlowReader();
    } catch (_) {/* keep default */}
    // Resolve the new post-tour mode (string flag → legacy-bool fallback). Read
    // alongside the legacy bool, before the slower premium check, so the router
    // sees the right gate ASAP.
    try {
      _postTourPaywallMode = await _postTourPaywallModeReader();
    } catch (_) {/* keep default (off) */}
    try {
      _isPremiumCached = await _isPremiumReader();
    } catch (_) {/* keep default */}
    notifyListeners();
  }

  /// Back-compat derivation of the post-tour paywall MODE:
  ///   mode = post_tour_paywall_mode (string)
  ///        ?? (hard_paywall_after_tour_enabled ? 'hard' : 'off')
  ///
  /// Reads the new string flag first; an unrecognised / absent value falls back
  /// to THIS session's legacy boolean reader ([_hardPaywallFlowReader]). This
  /// preserves today's behaviour — the DB boolean is currently `true`, so until
  /// the new `post_tour_paywall_mode` key is set server-side the mode resolves
  /// to `hard`, exactly as the live binary behaves — and keeps legacy
  /// `hardPaywallFlowReader`-only callers (incl. tests) consistent.
  Future<PostTourPaywallMode> _derivePostTourPaywallMode() async {
    try {
      final raw = await AppConfigService(Supabase.instance.client)
          .getString(kPostTourPaywallModeFlag);
      switch (raw) {
        case 'off':
          return PostTourPaywallMode.off;
        case 'soft':
          return PostTourPaywallMode.soft;
        case 'hard':
          return PostTourPaywallMode.hard;
      }
    } catch (_) {/* fall through to the legacy boolean */}
    // Key absent / unrecognised / fetch failed → legacy boolean (true → hard).
    bool legacyHard;
    try {
      legacyHard = await _hardPaywallFlowReader();
    } catch (_) {
      legacyHard = false;
    }
    return legacyHard ? PostTourPaywallMode.hard : PostTourPaywallMode.off;
  }

  /// New user just finished onboarding → put them INTO the gate so the router
  /// routes them to the forced tour. Persists the latch=false so a force-kill
  /// before clearing the wall re-gates them on relaunch.
  Future<void> enterOnboardingGate() async {
    _tourCompleted = false;
    _paywallCleared = false;
    try {
      await OnboardingGateService().setPaywallCleared(false);
    } catch (_) {/* best-effort; in-memory still gates this session */}
    notifyListeners();
  }

  /// The forced tour finished → router advances the user to the hard paywall.
  void markTourCompleted() {
    if (_tourCompleted) return;
    _tourCompleted = true;
    notifyListeners();
  }

  /// The user cleared the entry wall (started a trial / restored premium).
  /// Persistence is the caller's responsibility; this updates the in-memory
  /// flag and kicks the router.
  void markPaywallCleared() {
    if (_paywallCleared) return;
    _paywallCleared = true;
    notifyListeners();
  }

  /// `true` while an economy hydration is in flight.
  bool _hydrating = false;

  /// Whether the economy cache has been hydrated at least once this session.
  bool get economyHydrated => _economyHydrated;
  bool _economyHydrated = false;

  /// Whether the last hydration attempt failed or timed out.
  bool get hydrationFailed => _hydrationFailed;
  bool _hydrationFailed = false;

  void _onAuthChange(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        if (isAuthenticated) {
          unawaited(_handleAuthenticatedChange(data));
        }
        if (isAuthenticated && !_hasOnboarded) {
          unawaited(_checkOnboardingStatus());
        }
        notifyListeners();
        break;
      case AuthChangeEvent.signedOut:
        unawaited(_notificationService.logout());
        // Reset analytics identity LAST among the telemetry side effects so any
        // final events queued before sign-out keep the outgoing user's
        // distinct_id; reset() then severs the identity so the next sign-in on
        // this device starts clean. Best-effort — a null hook (tests) is a no-op.
        try {
          onAnalyticsReset?.call();
        } catch (_) {/* analytics best-effort; never block sign-out */}
        _hasOnboarded = false;
        _economyHydrated = false;
        _hydrationFailed = false;
        // Reset gate flags to the ungated defaults so the next user to sign in
        // on this device isn't gated by the previous user's in-memory state.
        _tourCompleted = true;
        _paywallCleared = true;
        _isPremiumCached = false;
        _postTourPaywallMode = PostTourPaywallMode.off;
        _gateValveBypass = false;
        notifyListeners();
        break;
      default:
        notifyListeners();
        break;
    }
  }

  Future<void> _handleAuthenticatedChange(AuthState data) async {
    final sessionUserId = data.session?.user.id;

    // Eager gate hydration: read the local gate flags (latch, tour-seen) + the
    // kill switch ASAP, in parallel with the slower economy batch sync below.
    // Without this, the synchronous GoRouter redirect and the one-shot
    // tour-start in progress_screen both run with ungated defaults on cold
    // launch, briefly dropping a mid-gate user into the app / the legacy
    // skippable tour until batch sync finally hydrates the flags. Idempotent —
    // _hydrateAndNotify runs it again after batch sync to pick up any
    // server-mirrored values. notifyListeners inside re-runs the redirect.
    unawaited(hydrateOnboardingGate());

    if (sessionUserId != null && sessionUserId.isNotEmpty) {
      try {
        await _notificationService.identifyUser(sessionUserId);
      } catch (_) {
        // Non-critical — keep hydrating even if OneSignal login fails.
      }
    }

    final purchaseUserId = _currentUserIdProvider();
    if (purchaseUserId != null && purchaseUserId.isNotEmpty) {
      try {
        await PurchaseService().setUserId(purchaseUserId);
        // Baseline the consumable-grants credited set for this user on
        // first signin to this device. Without this, the orphan-recovery
        // listener would treat every transaction in the user's lifetime
        // history as "new" and re-grant them all on the first listener
        // fire (e.g., after `Purchases.syncPurchases()` in main.dart
        // pulled the full state). Idempotent — second call is a no-op.
        try {
          final customerInfo = await Purchases.getCustomerInfo();
          await ConsumableGrantsService().initializeForUser(customerInfo);
        } catch (e) {
          debugPrint('app_session: ConsumableGrants baseline failed: $e');
        }
      } catch (e) {
        debugPrint('app_session: RevenueCat setUserId failed: $e');
      }

      // Refresh the referral-premium cache so PurchaseService.isPremium()
      // picks up any server-side grant for the user without paying a
      // Supabase round-trip on the hot path. Fire-and-forget — failure
      // here is non-critical (the cache will refresh again on the next
      // auth change or RPC return).
      unawaited(PurchaseService().refreshReferralPremiumCache());

      // Same shape for the Sakina Gift window — cross-device sign-in restores
      // entitlement without requiring the user to tap Accept again. Server is
      // authoritative; we just refresh the SharedPrefs cache.
      unawaited(PurchaseService().refreshGiftPremiumCache());

      // Defensive cold-launch reconciliation for Refer-to-Unlock. There's a
      // kill-window between signup completing and applyPendingReferralIfAny
      // succeeding (or its RPC being submitted): the user could force-quit.
      // After relaunch they're authenticated AND `pending_referral` is still
      // in prefs, but no referrals row exists. The RPC is idempotent on the
      // referrals.(referee_id) unique constraint — calling twice is safe.
      unawaited(_reconcilePendingReferralOnAuth(purchaseUserId));
    }

    await _hydrateAndNotify();
  }

  Future<void> _reconcilePendingReferralOnAuth(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString(referralPendingReferralPrefsKey);
      if (pending == null || pending.isEmpty) return;
      await ReferralService(Supabase.instance.client)
          .applyPendingReferralIfAny(userId);
    } catch (e) {
      debugPrint('app_session: defensive applyPendingReferral failed: $e');
    }
  }

  Future<void> _hydrateAndNotify() async {
    if (_hydrating) return; // Avoid overlapping hydrations
    _hydrating = true;
    _hydrationFailed = false;
    try {
      await _hydrateEconomyCache().timeout(
        _hydrationTimeout,
        onTimeout: () => throw TimeoutException(
          'Economy hydration timed out',
          _hydrationTimeout,
        ),
      );
      _economyHydrated = true;
      // Refresh the onboarding-gate flags now that the batch sync has run
      // (it mirrors server `user_profiles` columns into the local caches via
      // OnboardingGateService.hydrateFromProfile). Fire-and-forget — it calls
      // notifyListeners itself when done.
      unawaited(hydrateOnboardingGate());
      unawaited(_notificationService.syncTimezone());
      if (_hasOnboarded) {
        unawaited(_notificationService.requestPermissionIfPreviouslyEnabled());
      }
    } catch (_) {
      _hydrationFailed = true;
    } finally {
      _hydrating = false;
      notifyListeners(); // Kick providers to re-read fresh cache / failure UI
    }
  }

  /// Manually retry hydration after an error or timeout.
  Future<void> retryHydration() async {
    if (_hydrating || !_hydrationFailed) return;
    await _hydrateAndNotify();
  }

  Future<void> _checkOnboardingStatus() async {
    final onboarded = await _hasCompletedOnboarding();
    if (onboarded && !_hasOnboarded) {
      _hasOnboarded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      notifyListeners();
      // Reinstall recovery: a returning user starts the session with
      // `initialOnboarded = false` (fresh prefs after a fresh install), so
      // _hydrateAndNotify's gate on `_hasOnboarded` races with this method
      // and usually loses. Fire the permission request here too — it's
      // idempotent (no-op if already granted, or if prefs row shows none
      // were ever enabled). Without this, reinstalled users never see the
      // iOS push prompt and have to enable in Settings manually.
      unawaited(_notificationService.requestPermissionIfPreviouslyEnabled());
    }
  }

  /// Await this after sign-in to ensure hasOnboarded is resolved before navigating.
  Future<void> ensureOnboardingChecked() async {
    if (!isAuthenticated) return;
    if (_hasOnboarded) return;
    final onboarded = await _hasCompletedOnboarding();
    if (onboarded) {
      _hasOnboarded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      notifyListeners();
      unawaited(_notificationService.requestPermissionIfPreviouslyEnabled());
    }
  }

  /// Called when a new user finishes onboarding (paywall dismiss).
  /// Sets local + in-memory flag; server flag is already set by saveOnboardingData().
  Future<void> markOnboarded() async {
    _hasOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  /// Called on sign-out or account deletion to clear local cache.
  /// [userId] must be captured BEFORE signOut() — after sign-out the auth
  /// user is null and scoped keys can't be resolved.
  Future<void> clearSession({String? userId}) async {
    _hasOnboarded = false;
    resetLaunchGateSessionState();
    resetAchievementToastSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await prefs.remove('onboarding_state');

    // Clear user-scoped SharedPreferences keys to prevent cross-user data bleed.
    final uid = userId ?? supabaseSyncService.currentUserId;
    if (uid != null) {
      final allKeys = prefs.getKeys().toList();
      final scopedSuffix = ':$uid';
      for (final key in allKeys) {
        if (key.endsWith(scopedSuffix)) {
          await prefs.remove(key);
        }
      }
    }
    // Don't call notifyListeners() — the auth stream's signedOut event will do that
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appSessionProvider = Provider<AppSessionNotifier>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// ---------------------------------------------------------------------------
// Default hydration path
//
// Hydrates batched user data via the batch RPC.
// ---------------------------------------------------------------------------

Future<void> _defaultHydrate() async {
  await hydrateUserDataFromBatchRpc();
}

String? _defaultCurrentUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

Future<bool> _defaultIsPremium() async {
  try {
    return await PurchaseService().isPremium();
  } catch (_) {
    return false;
  }
}

Future<bool> _defaultHardPaywallFlow() async {
  try {
    // fallback:false → gate stays dark until the server flag is flipped on.
    return await AppConfigService(Supabase.instance.client)
        .getBool(kHardPaywallAfterTourFlag, fallback: false);
  } catch (_) {
    return false;
  }
}

