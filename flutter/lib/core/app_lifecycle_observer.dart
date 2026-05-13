import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/daily/providers/daily_rewards_provider.dart';
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
    if (state == AppLifecycleState.resumed) {
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
