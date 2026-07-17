import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The dua-calendar seed ships as TWO hand-synced copies:
///   * `assets/dua_calendar/dua_windows.json` — bundled into the Flutter app.
///   * `ios/SakinaWidget/dua_calendar.json`   — read by the iOS widget
///     extension (which cannot see Flutter assets).
///
/// They MUST stay byte-for-byte equivalent in *content* — a drift means the
/// in-app card and the home/lock widget would disagree about which duʿā window
/// is active. This test decodes both and asserts structural equality so any
/// edit to one without the other fails CI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dua_windows.json (asset) and dua_calendar.json (iOS widget) match', () {
    final assetFile = File('assets/dua_calendar/dua_windows.json');
    final widgetFile = File('ios/SakinaWidget/dua_calendar.json');

    expect(assetFile.existsSync(), isTrue,
        reason: 'missing ${assetFile.path}');
    expect(widgetFile.existsSync(), isTrue,
        reason: 'missing ${widgetFile.path}');

    final assetJson = jsonDecode(assetFile.readAsStringSync());
    final widgetJson = jsonDecode(widgetFile.readAsStringSync());

    expect(
      assetJson,
      equals(widgetJson),
      reason: 'dua-calendar asset drifted from the iOS widget copy — '
          're-sync ios/SakinaWidget/dua_calendar.json with '
          'assets/dua_calendar/dua_windows.json.',
    );
  });
}
