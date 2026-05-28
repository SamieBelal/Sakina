import 'package:flutter/widgets.dart';

/// Tracks the topmost route's `settings.name` on the root navigator so the
/// tour overlay host can decide whether to render or hide.
///
/// When a "blocking" route is on top (NameRevealOverlay, LevelUpOverlay,
/// LapsedTrialSheet, FirstStepsOverlay, DailyLaunchOverlay), the host
/// renders `SizedBox.shrink()` so the tour doesn't punch through and
/// highlight widgets behind that modal. When the blocking route pops, the
/// host's listener rebuilds and the overlay re-appears for the current
/// step.
///
/// **Singleton lifetime.** This observer is declared as a top-level `final`
/// so its tracked top-route stack survives Widget rebuilds. Re-instantiating
/// on every rebuild would clear the stack and break the route-stack guard.
class TourRouteObserver extends NavigatorObserver {
  TourRouteObserver();

  /// The route names that should hide the tour overlay while on top of the
  /// navigator. These are full-screen modals that own the user's attention.
  static const Set<String> blockingRouteNames = {
    'NameRevealOverlay',
    'LevelUpOverlay',
    'LapsedTrialSheet',
    'FirstStepsOverlay',
    'DailyLaunchOverlay',
  };

  /// Notifies listeners with the current top route's name (or null if no
  /// name available). The OverlayHost watches this.
  final ValueNotifier<String?> topRouteName = ValueNotifier<String?>(null);

  /// Optional callback fired whenever a route is popped. The OverlayHost
  /// uses this to detect the DuaDetailPage back-gesture case (step 13
  /// completion via back-swipe instead of Done button).
  void Function(Route<dynamic> route, Route<dynamic>? previousRoute)? onPop;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    topRouteName.value = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    topRouteName.value = previousRoute?.settings.name;
    onPop?.call(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    topRouteName.value = newRoute?.settings.name;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route.settings.name == topRouteName.value) {
      topRouteName.value = previousRoute?.settings.name;
    }
  }

  /// True iff the current top route is one of the blocking modals.
  bool get isBlockingRouteOnTop =>
      topRouteName.value != null &&
      blockingRouteNames.contains(topRouteName.value);

  /// Manual dispose for the ValueNotifier. NavigatorObserver itself has no
  /// dispose contract; call this only if you're sure the observer is being
  /// torn down (typically never, since it's a top-level singleton).
  void disposeNotifier() {
    topRouteName.dispose();
  }
}

/// Top-level singleton. Wire into `MaterialApp.router(navigatorObservers:
/// [tourRouteObserver])` in `main.dart`. Do NOT instantiate `TourRouteObserver()`
/// elsewhere — losing the singleton means losing the tracked top-route state.
final tourRouteObserver = TourRouteObserver();
