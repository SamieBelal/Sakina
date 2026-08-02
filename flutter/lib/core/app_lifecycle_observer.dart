import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/daily/providers/daily_rewards_provider.dart';
import '../features/dua_times/providers/dua_window_provider.dart';
import '../features/tour/providers/onboarding_tour_controller.dart';
import '../services/analytics_events.dart';
import '../services/analytics_provider.dart';
import '../services/gating_service.dart';
import '../widgets/iap_to_sub_upsell_banner.dart';
import 'app_session.dart';

/// Invalidates `premiumStateProvider` whenever the app returns to the
/// foreground.
///
/// Why this exists: RevenueCat entitlement state can change while the app is
/// backgrounded (user cancels via App Store, subscription expires, webhook
/// updates server state). Without this observer, the UI keeps showing stale
/// premium state until the user forces a full restart. The
/// `premiumStateProvider` is a FutureProvider that caches its result —
/// invalidating on resume forces a fresh read from the RevenueCat SDK.
///
/// Mount under `ProviderScope` and above any widget that reads
/// `premiumStateProvider`.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  const AppLifecycleObserver({required this.child, super.key});

  final Widget child;

  /// Minimum time backgrounded before a resume counts as a new warm-start
  /// session. `@visibleForTesting` so the `>= threshold` branch is exercisable
  /// without a real multi-second sleep (mirrors `debugDailyLoopClock` /
  /// `GiftService.debugGiftClock`). Production always uses the 3s default.
  @visibleForTesting
  static Duration warmStartThreshold = const Duration(seconds: 3);

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  AppSessionNotifier? _session;
  bool? _lastAuth;
  // Started only when the app truly backgrounds (paused/detached). Used to fire
  // `session_started` on a genuine return from background, and to suppress
  // transient `inactive` resumes and the cold-start resume. A monotonic
  // Stopwatch (NOT DateTime.now()) so a wall-clock change while backgrounded —
  // timezone travel, NTP correction, DST — can't drop or spuriously fire the
  // signal the retention metric depends on.
  final Stopwatch _backgroundElapsed = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen to auth state transitions. When a user signs out or a new user
    // signs in, the cached `premiumStateProvider` value belongs to the
    // previous user — invalidate so the next read hits RevenueCat fresh
    // for the new (or anonymous) user.
    //
    // Guarded because appSessionProvider is not always overridden in tests
    // that only care about lifecycle-state behavior. Skipping the auth-hook
    // is acceptable in that case (the resume path still invalidates).
    // Bridge GatingService's post-hydration signal into Riverpod-land: every
    // sync_all_user_data hydration writes new lifetime_bypasses_purchased /
    // iap_upsell_banner_dismissed_at values into SharedPrefs, but the
    // FutureProvider that drives the IAP→sub banner has no other way to learn
    // those keys changed. Without this, the banner evaluates once at mount
    // (with stale defaults) and never re-renders.
    GatingService.onProfileHydrated = () {
      if (!mounted) return;
      ref.invalidate(iapToSubBannerStateProvider);
      // W6 Wave A: `free_tier_cohort` cannot be registered at boot — it's a
      // user-scoped prefs key `hydrateFromProfile` itself just wrote, so a
      // fresh install has no value until this, the first `sync_all_user_data`.
      // Same hook, a second statement — not a second hook. Best-effort: a
      // throwing read must never break the banner-refresh signal above it.
      unawaited(_registerFreeTierCohort());
    };

    try {
      _session = ref.read(appSessionProvider);
      _lastAuth = _session?.isAuthenticated;
      _session?.addListener(_onSessionChanged);
    } catch (_) {
      _session = null;
    }

    // Keep the duʿā-times schedule alive for the whole app session. The
    // `duaWindowProvider` notifier is lazy and its only card lives on the
    // Progress screen, so a user who opens the app to Home never constructs it —
    // meaning the schedule is never rebuilt and the home/lock-screen widget
    // keeps rendering a stale (e.g. yesterday's Friday) payload. Reading
    // `.notifier` here (this observer is always mounted at app root) forces the
    // notifier to exist from launch: its constructor auto-builds + pushes on
    // cold start, and its own lifecycle observer re-pushes on every foreground.
    // Best-effort — the notifier degrades silently on any build failure.
    try {
      ref.read(duaWindowProvider.notifier);
    } catch (_) {
      // Never let widget-refresh wiring block the app-root observer.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session?.removeListener(_onSessionChanged);
    GatingService.onProfileHydrated = null;
    super.dispose();
  }

  void _onSessionChanged() {
    final nextAuth = _session?.isAuthenticated ?? false;
    if (nextAuth != _lastAuth) {
      _lastAuth = nextAuth;
      ref.invalidate(premiumStateProvider);
    }
  }

  /// Registers the `free_tier_cohort` super property (`reel_v1` | `legacy`)
  /// now that [GatingService.hydrateFromProfile] has written a fresh cache.
  /// `isNewCohort()` is the same cache-only read every gate check already
  /// trusts, so this can never disagree with the app's own gating behaviour.
  Future<void> _registerFreeTierCohort() async {
    try {
      final newCohort = await GatingService().isNewCohort();
      if (!mounted) return;
      ref.read(analyticsProvider).setSuperProperties({
        AnalyticsEvents.propFreeTierCohort:
            newCohort ? GatingService.cohortReelV1 : 'legacy',
      });
    } catch (_) {
      // Analytics best-effort — must never surface to the hydration signal.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundElapsed
        ..reset()
        ..start();
      // Flush queued analytics on every background. Mixpanel batches events;
      // without this they only flushed at `onboarding_completed`, so a user who
      // abandons mid-onboarding and force-quits could lose every queued event —
      // exactly the drop-off cohort the funnel needs. (2026-06-15 audit, D1.)
      if (mounted) {
        try {
          // Silent-abandonment signal: if the guided tour is active when the
          // app backgrounds, the user left mid-tour without an explicit skip or
          // an anchor timeout. Emit BEFORE the flush so the event ships with the
          // batch this background triggers. Separate from `tour_skipped` /
          // `tour_anchor_timeout` so the three exit modes are distinguishable.
          final tour = ref.read(onboardingTourControllerProvider);
          if (tour.isActive) {
            ref.read(analyticsProvider).track(
              AnalyticsEvents.tourBackgrounded,
              properties: {
                'step_id': tour.currentStep?.id ?? 'unknown',
                'step_index': tour.index,
                AnalyticsEvents.propVariant: tour.variant.name,
              },
            );
          }
        } catch (_) {/* analytics best-effort; never block lifecycle */}
        try {
          ref.read(analyticsProvider).flush();
        } catch (_) {/* analytics best-effort; never block lifecycle */}
      }
    }
    if (state == AppLifecycleState.resumed) {
      // Retention: warm-start session signal — but ONLY for a genuine return
      // from background. We gate on `_backgroundElapsed`, which runs ONLY when
      // the app actually backgrounds (paused/detached). This is deliberate:
      //   - The callback right before `resumed` on iOS is `inactive`/`hidden`,
      //     NOT `paused`, so checking the previous state would never match.
      //   - Transient `inactive` blips (Control Center, app-switcher peek, a
      //     permission/StoreKit dialog dismissing) never start the stopwatch,
      //     so they're correctly suppressed.
      //   - Cold start never started it either, so it doesn't double-count with
      //     `app_opened`.
      // The threshold filters quick app-switches. `mounted` guard matches the
      // rest of this class (lifecycle callbacks can arrive during teardown).
      if (mounted &&
          _backgroundElapsed.isRunning &&
          _backgroundElapsed.elapsed >= AppLifecycleObserver.warmStartThreshold) {
        ref.read(analyticsProvider).track(
              AnalyticsEvents.sessionStarted,
              properties: const {'warm_start': true},
            );
      }
      // Stop + reset so a later transient resume (without a real background in
      // between) can't re-fire.
      _backgroundElapsed
        ..stop()
        ..reset();
      // Entitlement state can change while backgrounded (subscription
      // cancelled in App Store settings, billing issue resolved, etc).
      // Invalidate the premium state so the card + banner re-read on
      // next watch.
      ref.invalidate(premiumStateProvider);
      // The reverse-trial resume re-check used to hang off this branch: it
      // refreshed the app-granted `trial_premium_until` cache and emitted
      // `trial_expired` once on the Day-3 crossing. Deleted with the rest of
      // the experiment (W5 Wave A) — nothing grants that trial any more, so
      // there is no expiry transition left to observe. The RC store-trial
      // lapse is a separate surface (`LapsedTrialSheet`, off `hadTrial()`) and
      // is unaffected.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the `is_premium` super property in lockstep with the live entitlement
    // so funnels can always exclude converted users. premiumStateProvider is
    // invalidated on resume (above), sign-out, and purchase/restore — listening
    // here means every resolution refreshes the super prop without a dedicated
    // poll. Best-effort: a thrown analytics call must never break the resume
    // path. (2026-06-15 audit, is_premium refresh.)
    ref.listen<AsyncValue<PremiumState>>(premiumStateProvider, (prev, next) {
      next.whenData((state) {
        try {
          ref.read(analyticsProvider).setSuperProperties(
                {AnalyticsEvents.isPremium: state.isPremium},
              );
        } catch (_) {/* analytics best-effort; never block */}
      });
    });
    return widget.child;
  }
}
