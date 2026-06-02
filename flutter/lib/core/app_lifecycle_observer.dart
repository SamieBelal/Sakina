import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/daily/providers/daily_rewards_provider.dart';
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
    };

    try {
      _session = ref.read(appSessionProvider);
      _lastAuth = _session?.isAuthenticated;
      _session?.addListener(_onSessionChanged);
    } catch (_) {
      _session = null;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundElapsed
        ..reset()
        ..start();
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
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
