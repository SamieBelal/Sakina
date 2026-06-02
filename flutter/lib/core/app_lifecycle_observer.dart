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

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  AppSessionNotifier? _session;
  bool? _lastAuth;
  // Set only when the app truly backgrounds (paused/detached). Used to fire
  // `session_started` on a genuine return from background, and to suppress
  // transient `inactive` resumes and the cold-start resume.
  DateTime? _backgroundedAt;

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
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      // Retention: warm-start session signal — but ONLY for a genuine return
      // from background. We gate on `_backgroundedAt`, which is set ONLY when
      // the app actually backgrounds (paused/detached). This is deliberate:
      //   - The callback right before `resumed` on iOS is `inactive`/`hidden`,
      //     NOT `paused`, so checking the previous state would never match.
      //   - Transient `inactive` blips (Control Center, app-switcher peek, a
      //     permission/StoreKit dialog dismissing) never set `_backgroundedAt`,
      //     so they're correctly suppressed.
      //   - Cold start never set it either, so it doesn't double-count with
      //     `app_opened`.
      // The 3s threshold filters quick app-switches. `mounted` guard matches
      // the rest of this class (lifecycle callbacks can arrive during teardown).
      if (mounted &&
          _backgroundedAt != null &&
          DateTime.now().difference(_backgroundedAt!) >
              const Duration(seconds: 3)) {
        ref.read(analyticsProvider).track(
              AnalyticsEvents.sessionStarted,
              properties: const {'warm_start': true},
            );
      }
      // Consume the marker so a later transient resume (without a real
      // background in between) doesn't re-fire.
      _backgroundedAt = null;
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
