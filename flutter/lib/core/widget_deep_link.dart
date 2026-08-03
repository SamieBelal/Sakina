import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../services/analytics_events.dart';
import '../services/daily_question_analytics.dart';
import '../services/reveal_entry_source.dart';
import '../widgets/achievement_toast.dart' show rootNavigatorKey;

/// URL scheme the iOS widget's `.widgetURL` uses. MUST be registered in the
/// Runner `Info.plist` under `CFBundleURLTypes` → `CFBundleURLSchemes`.
const String kWidgetUrlScheme = 'sakina';

/// Pure mapping from a widget-tap [uri] to an in-app GoRouter location, or null
/// if [uri] is not a recognised widget link. Kept pure so it is unit-testable
/// without the platform channel or a live router.
///
/// Daily-Name widget links look like
/// `sakina://widget/muhasabah?homeWidget&source=home_widget` or
/// `sakina://widget/build-dua?homeWidget&source=home_widget`. The
/// `homeWidget` marker is appended for home_widget delivery, while `source`
/// preserves analytics attribution through iOS URL handling. Build-a-dua is
/// need-based (free text), not tied to a Name, so no `name_key` is carried.
String? parseWidgetDeepLink(Uri? uri) {
  switch (_widgetTarget(uri)) {
    case 'muhasabah':
      // `?entry=widget` so `daily_question_shown` can separate the widget path
      // from day-open (W4 Wave 7, plan §9). It has to be tagged HERE and not in
      // the handler: a widget tap lands the user in the question itself since
      // W4, and if it arrived untagged it would be counted as the app having
      // opened the question on its own.
      return '/muhasabah?$questionEntryQueryParam=$questionEntryWidget';
    case 'build-dua':
      return '/duas';
    case 'fix-location':
      // The widget can state that precise times are off but has no room to say
      // how to fix it — the small cue is one line at ~28 characters. So the
      // widget points and the app explains.
      return kFixLocationRoute;
    default:
      return null;
  }
}

/// Where a widget "precise times are off" tap lands.
const String kFixLocationRoute = '/precise-times';

/// The widget-link target segment (`muhasabah` / `build-dua`), or null if [uri]
/// is not a recognised widget link. Shared by the router mapping and the
/// `widget_opened` analytics label.
String? _widgetTarget(Uri? uri) {
  if (uri == null) return null;
  final isWidgetLink =
      uri.host == 'widget' || uri.queryParameters.containsKey('homeWidget');
  if (!isWidgetLink) return null;
  return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
}

/// Bridges `home_widget` taps into GoRouter navigation.
///
/// Cold launch: the tap URI resolves before the router/auth are ready, so it is
/// QUEUED and replayed after the first frame. Warm taps navigate immediately.
/// The router's own redirect gates unauthenticated users to `/welcome`, so a
/// logged-out tap simply lands on the funnel — no special-casing needed.
///
/// **On precedence over the daily launch overlay — corrected 2026-07-30 (W4
/// Wave 4).** This comment used to claim a widget tap simply wins "because it
/// drives a `.go()` to a full-screen route after first frame". That holds for
/// `muhasabah` → `/muhasabah`, which is a root-level route. It is **false for
/// `build-dua` → `/duas`**, which lives inside the `ShellRoute` alongside `/`:
/// going there swaps the shell's child but does not remove an opaque route
/// already pushed on the root navigator.
///
/// Both paths also genuinely race — the overlay's own gate does a network
/// reconcile before pushing, and this handler replays after the first frame —
/// so ordering was never guaranteed in either direction. The fix lives at the
/// push site (`progress_screen._maybeShowDailyLaunch`), which now checks where
/// the user actually is before presenting the day-open, rather than assuming
/// this handler got there first. Spec §10.3 / §9a.
class WidgetDeepLinkHandler {
  WidgetDeepLinkHandler({
    void Function(String location)? navigate,
    Future<Uri?> Function()? initialUri,
    Stream<Uri?>? clicks,
    void Function(VoidCallback)? postFrame,
  })  : _navigate = navigate ?? _defaultNavigate,
        _initialUri = initialUri ?? HomeWidget.initiallyLaunchedFromHomeWidget,
        _clicks = clicks ?? HomeWidget.widgetClicked,
        _postFrame = postFrame ??
            ((cb) =>
                SchedulerBinding.instance.addPostFrameCallback((_) => cb()));

  final void Function(String location) _navigate;
  final Future<Uri?> Function() _initialUri;
  final Stream<Uri?> _clicks;
  final void Function(VoidCallback) _postFrame;
  StreamSubscription<Uri?>? _sub;

  /// Static hook wired once in `main.dart` (null in tests). Lets this
  /// non-Riverpod handler emit `widget_opened` without an analytics dependency
  /// — same pattern as `StreakAnalytics.onAnalyticsEvent`.
  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  /// Wire up cold-launch replay + warm-tap listening. Call once after the app
  /// is built (e.g. from the root widget's `initState`).
  Future<void> start() async {
    _sub = _clicks.listen((uri) => _handle(uri, cold: false));
    // Cold start: replay the launch URI after the first frame so the router
    // is mounted and auth has settled.
    final launch = await _initialUri();
    if (launch != null) {
      _postFrame(() => _handle(launch, cold: true));
    }
  }

  void _handle(Uri? uri, {required bool cold}) {
    final location = parseWidgetDeepLink(uri);
    if (location == null) return;
    // Second-Name lifecycle attribution (W6 Wave B / W3 §9): only the
    // muḥāsabah target can plausibly explain a queue unseal — a build-dua tap
    // is a different surface entirely. Stamped BEFORE analytics/navigation so
    // a same-frame discoverName() (unlikely, but not this handler's job to
    // rule out) still sees it.
    if (_widgetTarget(uri) == 'muhasabah') {
      stampRevealEntrySource(AnalyticsEvents.revealSourceWidget);
    }
    // NOTE: this path only sees HOME-WIDGET taps (delivered via
    // HomeWidget.widgetClicked). A Live Activity `Link` is delivered straight to
    // GoRouter by Flutter deep-linking, NOT this stream, so its
    // `dua_live_activity_tapped` attribution lives solely in the router redirect
    // (single owner — no double-count). See lib/core/router.dart.
    onAnalyticsEvent?.call(AnalyticsEvents.widgetOpened, {
      'target': switch (_widgetTarget(uri)) {
        'build-dua' => 'build_dua',
        'fix-location' => 'fix_location',
        _ => 'muhasabah',
      },
      'launch': cold ? 'cold' : 'warm',
      // Which widget drove the tap — the duʿā-times widget tags its link
      // `source=dua_times_widget`, while the daily-Name widget tags
      // `source=home_widget`. Older links without a source still default to
      // `home_widget`. Lets the two be told apart (both can deep-link to
      // Build-a-Duʿā).
      AnalyticsEvents.propSource:
          uri?.queryParameters[AnalyticsEvents.propSource] ??
              AnalyticsEvents.widgetSourceHomeWidget,
    });
    _navigate(location);
  }

  void dispose() => _sub?.cancel();

  static void _defaultNavigate(String location) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) ctx.go(location);
  }
}
