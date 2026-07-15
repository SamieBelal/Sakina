import 'package:home_widget/home_widget.dart';

/// Widget adoption telemetry. Answers "what % of users have the widget, and
/// which sizes" — the adoption half of widget performance (the engagement half
/// is `widget_opened`, fired from `WidgetDeepLinkHandler`).
///
/// Static hook wired once in `main.dart` (null in tests), same pattern as
/// `StreakAnalytics.onAnalyticsEvent`.
void Function(String event, Map<String, dynamic> props)? widgetAnalyticsHook;

bool _installStateReported = false;

/// Report the current widget-install snapshot ONCE per app session. Uses
/// `HomeWidget.getInstalledWidgets()` (iOS 17+; empty on older iOS / no widget).
/// Best-effort — never throws into the caller.
Future<void> reportWidgetInstallState() async {
  if (_installStateReported) return;
  try {
    final installed = await HomeWidget.getInstalledWidgets();
    _installStateReported = true;
    // iOSFamily is e.g. systemSmall / systemMedium / accessoryRectangular.
    final families = installed
        .map((w) => w.iOSFamily ?? w.androidClassName ?? 'unknown')
        .toList();
    widgetAnalyticsHook?.call('widget_installed_state', {
      'installed': installed.isNotEmpty,
      'count': installed.length,
      'families': families,
      'has_small': families.contains('systemSmall'),
      'has_medium': families.contains('systemMedium'),
      'has_lock_screen': families.contains('accessoryRectangular'),
    });
  } catch (_) {
    // getInstalledWidgets is unavailable pre-iOS 17 / on Android here — skip.
  }
}

/// Test seam: reset the once-per-session guard.
void resetWidgetInstallStateGuardForTest() => _installStateReported = false;
