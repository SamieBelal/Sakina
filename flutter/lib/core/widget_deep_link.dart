import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../widgets/achievement_toast.dart' show rootNavigatorKey;

/// URL scheme the iOS widget's `.widgetURL` uses. MUST be registered in the
/// Runner `Info.plist` under `CFBundleURLTypes` → `CFBundleURLSchemes`.
const String kWidgetUrlScheme = 'sakina';

/// Pure mapping from a widget-tap [uri] to an in-app GoRouter location, or null
/// if [uri] is not a recognised widget link. Kept pure so it is unit-testable
/// without the platform channel or a live router.
///
/// Widget links look like `sakina://widget/muhasabah?homeWidget` or
/// `sakina://widget/build-dua?name_key=al-wakil&homeWidget` (the `homeWidget`
/// marker is appended by the home_widget plugin).
String? parseWidgetDeepLink(Uri? uri) {
  if (uri == null) return null;
  final isWidgetLink =
      uri.host == 'widget' || uri.queryParameters.containsKey('homeWidget');
  if (!isWidgetLink) return null;

  final target = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
  switch (target) {
    case 'muhasabah':
      return '/muhasabah';
    case 'build-dua':
      final key = uri.queryParameters['name_key'];
      // Carry the Name so the builder can seed it (DuasScreen reads
      // state.uri.queryParameters['name_key'] once seeding lands).
      return (key != null && key.isNotEmpty) ? '/duas?name_key=$key' : '/duas';
    default:
      return null;
  }
}

/// Bridges `home_widget` taps into GoRouter navigation.
///
/// Cold launch: the tap URI resolves before the router/auth are ready, so it is
/// QUEUED and replayed after the first frame. Warm taps navigate immediately.
/// The router's own redirect gates unauthenticated users to `/welcome`, so a
/// logged-out tap simply lands on the funnel — no special-casing needed. A
/// widget tap takes precedence over the daily launch overlay because it drives
/// a `.go()` to a full-screen route after first frame. Spec §10.3.
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

  /// Wire up cold-launch replay + warm-tap listening. Call once after the app
  /// is built (e.g. from the root widget's `initState`).
  Future<void> start() async {
    _sub = _clicks.listen(_handle);
    // Cold start: replay the launch URI after the first frame so the router
    // is mounted and auth has settled.
    final launch = await _initialUri();
    if (launch != null) {
      _postFrame(() => _handle(launch));
    }
  }

  void _handle(Uri? uri) {
    final location = parseWidgetDeepLink(uri);
    if (location != null) _navigate(location);
  }

  void dispose() => _sub?.cancel();

  static void _defaultNavigate(String location) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) ctx.go(location);
  }
}
